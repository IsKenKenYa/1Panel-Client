"""Command runner utility for executing hidumper on HarmonyOS devices.

Supports two data collection approaches:
  1. hidumper commands (formatted/parsed output per official documentation)
  2. cat /proc nodes (raw kernel data for all processes, then filter by pid)

Raw /proc nodes (all-process data, useful for cross-process analysis):
  /proc/meminfo              → System memory overview (raw)
  /proc/gpu_memory           → GPU memory allocation for all processes (raw)
  /proc/process_dmabuf_info  → DMA buffer info for all processes (raw)
  /proc/<pid>/smaps_rollup   → Process memory category summary (raw)
  /proc/<pid>/smaps          → Process detailed memory mapping (raw)
  /proc/vmstat               → Virtual memory statistics (raw)
  /proc/slabinfo             → Kernel slab allocator info (raw)
  /proc/vmallocinfo          → Virtual malloc info (raw)

Hidumper commands (formatted output):
  hidumper --mem                          System memory overview
  hidumper --mem <pid>                    Process memory category summary
  hidumper --mem <pid> --show-ashmem      + ashmem details
  hidumper --mem <pid> --show-dmabuf      + DMA buffer details
  hidumper --mem <pid> --show-gpumem      + GPU memory details
  hidumper --mem-smaps <pid>              Process smaps (aggregate, requires debug app)
  hidumper --mem-smaps <pid> -v           Verbose smaps (no aggregation)
  hidumper --mem-jsheap <pid>             ArkTS JS heap snapshot
  hidumper --cpuusage                     CPU usage statistics
  hidumper --cpufreq                      CPU frequency info
  hidumper -c system                      System dump (vmstat/slab/vmalloc + mem overview)
"""

import sys
from pathlib import Path
import glob
import os
import platform
import subprocess
import logging
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
from cmd_runner import CmdRunner
from tool_finder import find_hdc

logger = logging.getLogger(__name__)


def _hdc_recv_local_path(path: str) -> str:
    """Convert local path for hdc file recv on Windows.

    In Git Bash (MSYS2), hdc file recv interprets forward-slash local paths
    (e.g. D:/out/file) as relative to CWD. Using backslash paths avoids this.
    """
    if platform.system() == "Windows":
        return str(Path(path)).replace("/", "\\")
    return path

class HidumperCmdRunner:
    DEVECO_URL = "https://developer.huawei.com/consumer/cn/download/"
    HDC_HINT = (
        "hdc (HarmonyOS Device Connector) comes with DevEco Studio toolchains.\n"
        f"  Download DevEco Studio: {DEVECO_URL}\n"
        "  Set HDC_PATH env var or add DevEco Studio toolchains to PATH."
    )

    def __init__(self, hdc: str | None = None, timeout: int = 120):
        self.hdc = hdc or find_hdc() or "hdc"
        self.timeout = timeout
        self._hdc_checked = False

    def _check_hdc(self) -> None:
        import shutil
        if self._hdc_checked:
            return
        self._hdc_checked = True
        if not shutil.which(self.hdc):
            raise FileNotFoundError(
                f"hdc not found at '{self.hdc}'.\n{self.HDC_HINT}"
            )

    def _run_hdc_shell(self, cmd: list[str],
                       timeout: Optional[int] = None) -> subprocess.CompletedProcess:
        self._check_hdc()
        hdc_cmd = [self.hdc, "shell"] + cmd
        timeout = timeout or self.timeout
        logger.info("Running: %s", " ".join(hdc_cmd))
        try:
            result = subprocess.run(
                hdc_cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            if result.returncode != 0:
                logger.error("hidumper command failed (rc=%d): %s", result.returncode, result.stderr)
            return result
        except subprocess.TimeoutExpired:
            logger.error("hidumper command timed out after %ds", timeout)
            raise
        except FileNotFoundError:
            logger.error("hdc not found: %s", self.hdc)
            raise

    def _run_hdc_recv(self, remote_path: str, local_path: str) -> subprocess.CompletedProcess:
        self._check_hdc()
        cmd = [self.hdc, "file", "recv", remote_path, _hdc_recv_local_path(local_path)]
        logger.info("Running: %s", " ".join(cmd))
        try:
            return subprocess.run(cmd, capture_output=True, text=True, timeout=self.timeout)
        except subprocess.TimeoutExpired:
            logger.error("hdc file recv timed out")
            raise

    def find_pid(self, process_name: str) -> Optional[int]:
        result = self._run_hdc_shell(["ps", "-ef"])
        if result.returncode != 0:
            return None
        for line in result.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 2 and process_name in line:
                try:
                    return int(parts[1])
                except ValueError:
                    continue
        return None

    def find_pids(self, keyword: str) -> list[int]:
        result = self._run_hdc_shell(["ps", "-ef"])
        if result.returncode != 0:
            return []
        pids = []
        for line in result.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 2 and keyword in line:
                try:
                    pids.append(int(parts[1]))
                except ValueError:
                    continue
        return pids

    def start_app(self, bundle_name: str, ability_name: str = "EntryAbility") -> subprocess.CompletedProcess:
        cmd = ["aa", "start", "-a", ability_name, "-b", bundle_name]
        return self._run_hdc_shell(cmd)

    def is_process_running(self, pid: int) -> bool:
        result = self._run_hdc_shell(["ps", "-p", str(pid)])
        if result.returncode != 0:
            return False
        lines = result.stdout.strip().splitlines()
        return len(lines) >= 2

    def ensure_process_running(self, bundle_name: str = "",
                               ability_name: str = "EntryAbility",
                               pid: Optional[int] = None,
                               process_name: Optional[str] = None,
                               wait_seconds: int = 5) -> Optional[int]:
        if pid and self.is_process_running(pid):
            logger.info("Process PID %d is running", pid)
            return pid

        search_name = process_name or bundle_name
        found_pid = self.find_pid(search_name)
        if found_pid and self.is_process_running(found_pid):
            logger.info("Found running process: PID %d (%s)", found_pid, search_name)
            return found_pid

        logger.info("Process not found, starting app: %s/%s", bundle_name, ability_name)
        result = self.start_app(bundle_name, ability_name)
        if result.returncode != 0:
            logger.error("Failed to start app: %s", result.stderr)
            return None

        import time
        time.sleep(wait_seconds)

        found_pid = self.find_pid(search_name)
        if found_pid:
            logger.info("App started successfully: PID %d", found_pid)
            return found_pid

        all_pids = self.find_pids(bundle_name)
        if all_pids:
            logger.info("App started, found PID: %d", all_pids[0])
            return all_pids[0]

        logger.error("App started but PID not found")
        return None

    def run_hidumper(self, args: list[str],
                     timeout: Optional[int] = None) -> subprocess.CompletedProcess:
        cmd = ["hidumper"] + args
        return self._run_hdc_shell(cmd, timeout=timeout)

    def mem_system(self) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--mem"])

    def mem_process(self, pid: int) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--mem", str(pid)])

    def mem_process_ashmem(self, pid: int) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--mem", str(pid), "--show-ashmem"])

    def mem_process_dmabuf(self, pid: int) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--mem", str(pid), "--show-dmabuf"])

    def mem_process_gpumem(self, pid: int) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--mem", str(pid), "--show-gpumem"])

    def mem_smaps(self, pid: int, verbose: bool = False) -> subprocess.CompletedProcess:
        args = ["--mem-smaps", str(pid)]
        if verbose:
            args.append("-v")
        return self.run_hidumper(args)

    def mem_jsheap(self, pid: int, tid: Optional[int] = None,
                    leakobj: bool = False,
                    gc: bool = False, clean: bool = False) -> subprocess.CompletedProcess:
        if tid is None:
            tid = pid  # 默认采集主线程 (主线程 tid == pid)
        args = ["--mem-jsheap", str(pid)]
        if tid is not None:
            args.extend(["-T", str(tid)])
        if leakobj:
            args.append("--leakobj")
        if gc:
            args.append("--gc")
        if clean:
            args.append("--clean")
        return self.run_hidumper(args)

    def mem_heap(self, pid: int, heap_type: str = "jsvm",
                 tid: Optional[int] = None,
                 gc: bool = False) -> subprocess.CompletedProcess:
        args = ["--mem-heap", str(pid), f"--{heap_type}"]
        if tid is not None:
            args.extend(["-T", str(tid)])
        if gc:
            args.append("--gc")
        return self.run_hidumper(args)

    def cpuusage(self) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--cpuusage"])

    def cpufreq(self) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--cpufreq"])

    def process_fd(self, pid: int) -> subprocess.CompletedProcess:
        return self.run_hidumper(["-p", str(pid), "--fd"])

    def process_thread(self, pid: int) -> subprocess.CompletedProcess:
        return self.run_hidumper(["-p", str(pid), "--thread"])

    def net(self) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--net"])

    def storage(self) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--storage"])

    def ipc(self) -> subprocess.CompletedProcess:
        return self.run_hidumper(["--ipc"])

    def system_env(self) -> subprocess.CompletedProcess:
        return self.run_hidumper(["-e"])

    def collect_and_save(self, args: list[str], output_path: str,
                         timeout: Optional[int] = None) -> str:
        result = self.run_hidumper(args, timeout=timeout)
        from file_utils import write_text, ensure_dir
        ensure_dir(str(Path(output_path).parent))
        write_text(output_path, result.stdout)
        if result.returncode != 0:
            logger.warning("hidumper returned non-zero exit code, output may be incomplete: %s", output_path)
        return output_path

    def cat_proc_and_save(self, proc_path: str, output_path: str,
                          timeout: Optional[int] = None) -> str:
        result = self._run_hdc_shell(["cat", proc_path], timeout=timeout)
        from file_utils import write_text, ensure_dir
        ensure_dir(str(Path(output_path).parent))
        if "No such file or directory" in result.stderr or "No such file" in result.stdout:
            logger.warning("proc node not found: %s", proc_path)
            write_text(output_path, result.stderr or result.stdout)
            return output_path
        write_text(output_path, result.stdout)
        logger.info("cat %s saved to %s (%d bytes)", proc_path, output_path, len(result.stdout))
        return output_path

    HEAPSNAPSHOT_REMOTE_DIR = "/data/log/reliability/resource_leak/memory_leak"

    def pull_heapsnapshot_files(self, pid: int, local_dir: str,
                                  prefix: str = "hidumper-",
                                  suffix: str = "") -> list[str]:
        """Pull heap snapshot files from device after hidumper heap commands.

        After hidumper --mem-jsheap/mem-heap, products are saved at:
          /data/log/reliability/resource_leak/memory_leak/

        File naming patterns:
          jsheap:     hidumper-jsheap-{pid}-{tid}-{timestamp}
          leakobj:    hidumper-leaklist-{pid}-{timestamp}
          jsvmheap:   hidumper-jsvmheap-{pid}-{tid}-{timestamp}
          arkweb:     hidumper-arkweb_jsheap-{pid}-{timestamp}
          kotlin:     hidumper-kotlinheap-{pid}-{timestamp}.kdump

        This method lists the directory, filters files matching pid and prefix,
        and pulls them via hdc file recv.

        Returns list of pulled file paths (may be empty).
        """
        import os
        from file_utils import ensure_dir
        ensure_dir(local_dir)

        result = self._run_hdc_shell(["ls", "-la", self.HEAPSNAPSHOT_REMOTE_DIR])
        if result.returncode != 0:
            logger.warning("Could not list heapsnapshot directory on device")
            return []

        pid_str = str(pid)
        pulled = []
        for line in result.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 7 and parts[-1] not in (".", ".."):
                filename = parts[-1]
                if prefix and not filename.startswith(prefix):
                    continue
                if pid_str and pid_str not in filename:
                    continue
                remote_path = f"{self.HEAPSNAPSHOT_REMOTE_DIR}/{filename}"
                win_local = os.path.join(local_dir, filename)
                try:
                    self._run_hdc_recv(remote_path, win_local)
                    pulled.append(win_local)
                    logger.info("Pulled heap file: %s", filename)
                except Exception as e:
                    logger.error("Failed to pull %s: %s", remote_path, e)

        return pulled
