"""Command runner utility for executing hiprofiler_cmd and trace_streamer.

Uses the official config-driven approach:
  hiprofiler_cmd -c - -o <path> -t <duration> -s -k <<CONFIG ... CONFIG

See: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiprofiler
"""


import subprocess
import logging
import os
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tool_finder import find_hdc, find_trace_streamer, hdc_env

logger = logging.getLogger(__name__)


DEVECO_DOWNLOAD_URL = "https://developer.huawei.com/consumer/cn/deveco-studio/"

TRACE_STREAMER_DOWNLOAD_URL = (
    "https://gitcode.com/openharmony/developtools_smartperf_host/releases/download/"
    "HiSmartPerf_20260730/trace_streamer_binary.zip"
)
TRACE_STREAMER_DOWNLOAD_FALLBACK = (
    "https://gitcode.com/openharmony/developtools_smartperf_host/releases"
)

TOOL_HINTS = {
    "hdc": "hdc (HarmonyOS Device Connector) comes with DevEco Studio toolchains.\n"
           f"  Download DevEco Studio: {DEVECO_DOWNLOAD_URL}\n"
           "  Set HDC_PATH env var or add DevEco Studio toolchains to PATH.",
    "trace_streamer": "trace_streamer multi-platform binary for htrace→SQLite conversion.\n"
                      "  Searched via tool_finder (TRACE_STREAMER_PATH → DevEco → PATH).\n"
                      "  If not found locally, download:\n"
                      f"  Download: {TRACE_STREAMER_DOWNLOAD_URL}\n"
                      f"  Fallback (find latest if link expired): {TRACE_STREAMER_DOWNLOAD_FALLBACK}\n"
                      "  The zip contains all-platform binaries. Extract and choose by platform:\n"
                      "    Windows: trace_streamer_windows.exe / Linux: trace_streamer_linux / macOS: trace_streamer_mac\n"
                      "  Set TRACE_STREAMER_PATH env var or add to PATH.",
    "hiprofiler_cmd": "hiprofiler_cmd runs on the HarmonyOS device (not locally).\n"
                       "  No local install needed — it is invoked via 'hdc shell hiprofiler_cmd'.",
}


class CmdRunner:
    def __init__(self, hiprofiler_cmd: str = "hiprofiler_cmd",
                 trace_streamer: str | None = None,
                 timeout: int = 300,
                 hdc: Optional[str] = None):
        self.hiprofiler_cmd = hiprofiler_cmd
        self._hiprofiler_cmd_found = True
        self.trace_streamer, self._trace_streamer_found = self._resolve_tool(
            trace_streamer or find_trace_streamer() or "trace_streamer", "trace_streamer")
        self.timeout = timeout
        self.hdc = hdc or find_hdc()
        self._hdc_found = bool(self.hdc and shutil.which(self.hdc))

    @staticmethod
    def _resolve_tool(path: str, name: str) -> tuple[str, bool]:
        if shutil.which(path):
            return path, True
        resolved = shutil.which(name)
        if resolved:
            return resolved, True
        logger.warning("Tool '%s' not found in PATH, using '%s' as fallback", name, path)
        return path, False

    def check_prerequisites(self, require_hdc: bool = False,
                            require_trace_streamer: bool = False,
                            require_hiprofiler_cmd: bool = False) -> list[str]:
        missing = []
        if require_hdc and not self._hdc_found:
            missing.append(f"hdc not found: {self.hdc}\n{TOOL_HINTS['hdc']}")
        if require_trace_streamer and not self._trace_streamer_found:
            missing.append(f"trace_streamer not found: {self.trace_streamer}\n{TOOL_HINTS['trace_streamer']}")
        if require_hiprofiler_cmd and not self._hiprofiler_cmd_found:
            missing.append(f"hiprofiler_cmd not found: {self.hiprofiler_cmd}\n{TOOL_HINTS['hiprofiler_cmd']}")
        return missing

    def run(self, cmd: list[str], cwd: Optional[str] = None,
            timeout: Optional[int] = None, stdin_data: Optional[str] = None,
            env: Optional[dict] = None) -> subprocess.CompletedProcess:
        timeout = timeout or self.timeout
        logger.info("Running: %s", " ".join(cmd))
        try:
            result = subprocess.run(
                cmd,
                input=stdin_data,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                cwd=cwd,
                timeout=timeout,
                env=env,
            )
            if result.returncode != 0:
                logger.error("Command failed (rc=%d): %s", result.returncode, result.stderr)
            return result
        except subprocess.TimeoutExpired:
            logger.error("Command timed out after %ds: %s", timeout, " ".join(cmd))
            raise
        except FileNotFoundError as e:
            tool_name = cmd[0] if cmd else "unknown"
            hint = TOOL_HINTS.get(tool_name)
            if hint:
                logger.error("Tool '%s' not found.\n%s", tool_name, hint)
            else:
                logger.error("Command not found: %s", tool_name)
            raise FileNotFoundError(f"'{tool_name}' not found.\n{hint or ''}") from e

    def run_on_device(self, cmd: list[str], stdin_data: Optional[str] = None,
                      timeout: Optional[int] = None) -> subprocess.CompletedProcess:
        if not self.hdc:
            raise RuntimeError("hdc tool not configured for device execution")
        hdc_cmd = [self.hdc, "shell"] + cmd
        return self.run(hdc_cmd, timeout=timeout, stdin_data=stdin_data, env=hdc_env())

    @staticmethod
    def _has_non_ascii(path: str) -> bool:
        """Check if path contains non-ASCII characters (e.g. Chinese)."""
        try:
            path.encode("ascii")
            return False
        except UnicodeEncodeError:
            return True

    def _staging_path_for_hdc(self, local_path: str) -> tuple[str, bool]:
        """Return a hdc-compatible local path and whether staging was needed.

        hdc.exe on Windows cannot handle non-ASCII characters in local paths.
        When detected, return an ASCII-only staging path under %TEMP%/hdc_tmp/
        and set needs_move=True so the caller can move the file afterward.
        """
        if sys.platform != "win32" or not self._has_non_ascii(local_path):
            return local_path, False
        # Generate ASCII-only staging path
        staging_dir = Path(tempfile.gettempdir()) / "hdc_tmp"
        staging_dir.mkdir(parents=True, exist_ok=True)
        staging_path = staging_dir / Path(local_path).name
        logger.info("Non-ASCII local path detected, using staging: %s -> %s", local_path, staging_path)
        return str(staging_path), True

    def push_to_device(self, local_path: str, remote_path: str) -> subprocess.CompletedProcess:
        if not self.hdc:
            raise RuntimeError("hdc tool not configured for device execution")
        # hdc.exe cannot handle non-ASCII local paths on Windows
        effective_local, needs_copy = self._staging_path_for_hdc(local_path)
        if needs_copy:
            shutil.copy2(local_path, effective_local)
        cmd = [self.hdc, "file", "send", effective_local, remote_path]
        result = self.run(cmd, env=hdc_env())
        if needs_copy:
            Path(effective_local).unlink(missing_ok=True)
        return result

    def pull_from_device(self, remote_path: str, local_path: str) -> subprocess.CompletedProcess:
        if not self.hdc:
            raise RuntimeError("hdc tool not configured for device execution")
        # hdc.exe cannot handle non-ASCII local paths on Windows
        effective_local, needs_move = self._staging_path_for_hdc(local_path)
        cmd = [self.hdc, "file", "recv", remote_path, effective_local]
        result = self.run(cmd, env=hdc_env())
        if result.returncode == 0 and needs_move:
            shutil.move(effective_local, local_path)
        elif needs_move and result.returncode != 0:
            # Clean up staging file on failure
            Path(effective_local).unlink(missing_ok=True)
        return result

    def run_hiprofiler_config_file(self, config_text: str,
                                   output_path: str,
                                   duration: int,
                                   remote_config_dir: str = "/data/local/tmp",
                                   start_service: bool = True,
                                   kill_service: bool = True) -> subprocess.CompletedProcess:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False, encoding="utf-8") as f:
            f.write(config_text)
            config_local_path = f.name

        config_remote_path = f"{remote_config_dir}/htrace_config.txt"
        self.push_to_device(config_local_path, config_remote_path)

        cmd = [self.hdc, "shell", self.hiprofiler_cmd,
               "-c", config_remote_path,
               "-o", output_path,
               "-t", str(duration)]
        if start_service:
            cmd.append("-s")
        if kill_service:
            cmd.append("-k")

        result = self.run(cmd)
        return result

    def stop_hiprofiler(self, on_device: bool = False) -> subprocess.CompletedProcess:
        cmd = [self.hiprofiler_cmd, "stop"]
        if on_device and self.hdc:
            return self.run_on_device(cmd)
        return self.run(cmd)

    def kill_hiprofiler_service(self, on_device: bool = False) -> subprocess.CompletedProcess:
        cmd = [self.hiprofiler_cmd, "-k"]
        if on_device and self.hdc:
            return self.run_on_device(cmd)
        return self.run(cmd)

    def convert_htrace_to_sqlite(self, htrace_path: str, db_path: str) -> subprocess.CompletedProcess:
        cmd = [
            self.trace_streamer,
            htrace_path,
            "-e", db_path,
        ]
        return self.run(cmd)
