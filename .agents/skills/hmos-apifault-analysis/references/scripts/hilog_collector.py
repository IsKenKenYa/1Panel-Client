#
#  Copyright (c) 2026 Huawei Device Co., Ltd.
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# 

#!/usr/bin/env python3
"""
Hilog Log Collector for 

Pulls hilog files from a connected device via hdc, parses binary logs using
hilogtool (or falls back to gzip decompression), and outputs a list of
readable text files for downstream analysis.

Designed to run inside a tool with a hard ~30s wall-clock budget (e.g.
CodeGenie's builtin_execute_command). The collector is:
  - time-boxed: a global deadline (default 25s) caps the whole run and every
    hdc call inside it, so it always finishes within budget;
  - bounded: caps the number/size of pulled files (newest first);
  - parallel: pulls .gz files concurrently;
  - cache-friendly: skips files already pulled (re-runs are fast);
  - resilient: ALWAYS prints exactly one JSON object, even on partial
    collection, timeouts, or uncaught exceptions.

Usage:
    python hilog_collector.py --output-dir diagnosis [--hilogtool PATH] --time-window 10

Output (stdout): JSON with status, parsed_files list, and metadata.
Requires Python 3.7+.
"""

from __future__ import annotations

import argparse
import gzip
import json
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DEFAULT_COLLECT_TIMEOUT = 25.0   # overall wall-clock budget (s), under the 30s tool cap
HDC_CMD_TIMEOUT = 8              # generic small hdc command ceiling (also run_cmd default)
HDC_LIST_TIMEOUT = 8             # ls / echo
HDC_RECV_TIMEOUT = 20            # per-file recv ceiling (clamped by remaining budget)
HILOGTOOL_CMD_TIMEOUT = 20       # hilogtool parse ceiling (clamped by remaining budget)
DEVICE_HILOG_DIR = "/data/log/hilog/"
TIMESTAMP_PATTERN = re.compile(r"(\d{8}-\d{6})")


# ---------------------------------------------------------------------------
# Deadline / time budget
# ---------------------------------------------------------------------------

class Deadline:
    """Monotonic wall-clock budget. Read-only checks are safe across threads."""

    def __init__(self, budget_s: float):
        self._start = time.monotonic()
        self._budget = budget_s

    def elapsed(self) -> float:
        return time.monotonic() - self._start

    def remaining(self) -> float:
        return max(0.0, self._budget - self.elapsed())

    def expired(self) -> bool:
        return self.remaining() <= 0.0


def _cmd_timeout(dl: Deadline, ceiling: float, min_floor: float = 1.0) -> float:
    """Per-command timeout clamped to the deadline. Returns 0.0 when the
    deadline is exhausted (caller must skip the call)."""
    if dl is None:
        return ceiling
    if dl.expired():
        return 0.0
    return max(min_floor, min(ceiling, dl.remaining()))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def run_cmd(cmd: list, timeout: float = HDC_CMD_TIMEOUT) -> tuple[int, str]:
    """Run a command and return (returncode, stdout+stderr).

    timeout<=0 short-circuits to a skip code without launching a subprocess,
    so callers can treat an exhausted deadline uniformly."""
    if timeout is not None and timeout <= 0:
        return -3, "skipped: deadline exhausted"
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding="utf-8",
            errors="replace",
        )
        output = result.stdout + result.stderr
        return result.returncode, output.strip()
    except subprocess.TimeoutExpired:
        return -1, f"Command timed out after {timeout}s: {' '.join(cmd)}"
    except FileNotFoundError:
        return -2, f"Command not found: {cmd[0]}"


def parse_filename_timestamp(filename: str) -> datetime | None:
    """Extract timestamp from hilog filename like hilog.305.20260524-152948.gz."""
    m = TIMESTAMP_PATTERN.search(filename)
    if not m:
        return None
    try:
        return datetime.strptime(m.group(1), "%Y%m%d-%H%M%S")
    except ValueError:
        return None


def output_json(data: dict) -> None:
    """Write one JSON object to stdout."""
    print(json.dumps(data, ensure_ascii=False, indent=2))


def safe_read_text(path: Path, max_bytes: int = 128) -> bool:
    """Check if a file looks like readable text by reading first chunk."""
    try:
        with open(path, "rb") as f:
            chunk = f.read(max_bytes)
        try:
            chunk.decode("utf-8")
            return True
        except UnicodeDecodeError:
            return False
    except OSError:
        return False


def _wipe_dir(d: Path) -> None:
    """Delete all files in a directory (non-recursive)."""
    for f in d.iterdir():
        if f.is_file() or f.is_symlink():
            try:
                f.unlink()
            except OSError:
                pass


def _is_cached(local_path: Path, remote_size: int | None) -> bool:
    """True if a local copy already matches the remote file. When the remote
    size is unknown, trust a same-named local file."""
    if not local_path.exists():
        return False
    if remote_size is None:
        return True
    try:
        return local_path.stat().st_size == remote_size
    except OSError:
        return False


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------

def check_device(dl: Deadline) -> tuple[bool, str]:
    """Check if a device is connected via hdc. Returns (connected, output)."""
    to = _cmd_timeout(dl, HDC_LIST_TIMEOUT)
    if to <= 0:
        return False, "deadline exhausted before device check"
    rc, out = run_cmd(["hdc", "shell", "echo", "ok"], timeout=to)
    if rc == -2:
        return False, "hdc command not found"
    if rc != 0:
        return False, out or "hdc failed to connect to device"
    return True, out


def list_device_files_with_size(dl: Deadline) -> tuple[bool, list[str], dict[str, int]]:
    """List device hilog dir newest-first, parsing sizes from `ls -lt`.

    Returns (success, names_newest_first, size_by_name). Falls back to a plain
    `ls -t` (no sizes) if `ls -lt` output cannot be parsed."""
    to = _cmd_timeout(dl, HDC_LIST_TIMEOUT)
    if to <= 0:
        return False, [], {}
    rc, out = run_cmd(["hdc", "shell", "ls", "-lt", DEVICE_HILOG_DIR], timeout=to)
    if rc != 0:
        to2 = _cmd_timeout(dl, HDC_LIST_TIMEOUT)
        if to2 <= 0:
            return False, [], {}
        rc2, out2 = run_cmd(["hdc", "shell", "ls", "-t", DEVICE_HILOG_DIR], timeout=to2)
        if rc2 != 0:
            return False, [], {}
        names = [f.strip() for f in out2.splitlines() if f.strip()]
        return True, names, {}

    names: list[str] = []
    size_by_name: dict[str, int] = {}
    for line in out.splitlines():
        line = line.strip()
        if not line or line.startswith("total"):
            continue
        parts = line.split()
        if len(parts) < 6:
            continue
        name = parts[-1]              # filename is the last token (no spaces in hilog names)
        names.append(name)
        try:
            size_by_name[name] = int(parts[4])   # size is the 5th field of `ls -l`
        except (ValueError, IndexError):
            pass
    return True, names, size_by_name


def find_dict_files(device_files: list[str]) -> list[str]:
    """Identify dictionary files (hilog_dict*) from device file list."""
    return [f for f in device_files if f.startswith("hilog_dict")]


def filter_gz_files(device_files: list[str], time_window: int,
                    include_untimestamped: bool = False) -> list[tuple[str, datetime]]:
    """Filter .gz log files within time_window minutes, sorted newest first.

    By default only timestamped files inside the window are kept; files without
    a parseable filename timestamp are skipped unless include_untimestamped=True
    (they used to be pulled unconditionally, which could grow without bound)."""
    cutoff = datetime.now() - timedelta(minutes=time_window)
    results: list[tuple[str, datetime]] = []
    for f in device_files:
        if not f.endswith(".gz"):
            continue
        ts = parse_filename_timestamp(f)
        if ts is not None:
            if ts >= cutoff:
                results.append((f, ts))
        elif include_untimestamped:
            results.append((f, datetime.min))
    results.sort(key=lambda x: x[1], reverse=True)   # newest first
    return results


def _pull_one(name: str, raw_dir: Path, dl: Deadline) -> tuple[str, bool, int]:
    """Pull one file with a deadline-clamped timeout. Returns (name, ok, size)."""
    local = raw_dir / name
    to = _cmd_timeout(dl, HDC_RECV_TIMEOUT, min_floor=2.0)
    if to <= 0:
        return name, False, 0
    rc, _ = run_cmd(["hdc", "file", "recv", DEVICE_HILOG_DIR + name, str(local)], timeout=to)
    if rc != 0:
        try:
            if local.exists():
                local.unlink()      # drop partial file
        except OSError:
            pass
        return name, False, 0
    try:
        size = local.stat().st_size if local.exists() else 0
    except OSError:
        size = 0
    return name, True, size


def pull_batch(file_specs: list[tuple[str, int | None]], raw_dir: Path, dl: Deadline,
               workers: int, max_bytes_total: int, max_bytes_per_file: int
               ) -> tuple[list[str], list[str], list[str], int]:
    """Pull a set of files in parallel waves, respecting the deadline and caps.

    file_specs: [(name, remote_size_or_None)] in priority order.
    Returns (ok_names, failed_names, cached_names, bytes_pulled)."""
    workers = max(1, min(workers, 8))
    ok_names: list[str] = []
    failed_names: list[str] = []
    cached_names: list[str] = []
    bytes_acc = 0

    # Classify: cache hits / oversized files are resolved without pulling;
    # stop accumulating once the total-byte budget would be exceeded.
    pending: list[tuple[str, int | None]] = []
    for name, rsize in file_specs:
        if _is_cached(raw_dir / name, rsize):
            cached_names.append(name)
            continue
        if max_bytes_per_file and rsize and rsize > max_bytes_per_file * 1024 * 1024:
            failed_names.append(name)                 # too big: skip deterministically
            continue
        if max_bytes_total and rsize and bytes_acc + rsize > max_bytes_total:
            failed_names.append(name)                 # would bust the total budget
            continue
        pending.append((name, rsize))

    # Submit in waves so the deadline can be re-checked between them.
    i = 0
    while i < len(pending):
        if dl.expired():
            failed_names.extend(name for name, _ in pending[i:])
            break
        wave = pending[i:i + workers]
        i += len(wave)
        with ThreadPoolExecutor(max_workers=min(len(wave), workers)) as ex:
            futs = {ex.submit(_pull_one, name, raw_dir, dl): name for name, _ in wave}
            for fut in as_completed(futs):
                name, ok, size = fut.result()
                if ok:
                    ok_names.append(name)
                    bytes_acc += size
                else:
                    failed_names.append(name)

    return ok_names, failed_names, cached_names, bytes_acc


def parse_with_hilogtool(hilogtool_path: str, raw_dir: Path, parsed_dir: Path,
                         *, timeout: float = HILOGTOOL_CMD_TIMEOUT) -> tuple[bool, str]:
    """Parse binary hilog files using hilogtool. Returns (success, dict_file_name)."""
    dict_files = sorted(raw_dir.glob("hilog_dict*"))
    if not dict_files:
        return False, "no dictionary file found"
    dict_file = dict_files[-1]

    files_before = set(raw_dir.iterdir())
    rc, out = run_cmd(
        [hilogtool_path, "parse", "-i", str(raw_dir), "-d", str(dict_file)],
        timeout=max(1.0, timeout),
    )
    if rc != 0:
        return False, f"hilogtool failed: {out}"

    new_files = set(raw_dir.iterdir()) - files_before
    for f in new_files:
        if f.is_file() and safe_read_text(f):
            shutil.move(str(f), str(parsed_dir / f.name))
    return True, str(dict_file.name)


def parse_with_gzip(raw_dir: Path, parsed_dir: Path) -> None:
    """Fallback: decompress .gz files and copy others."""
    for f in raw_dir.iterdir():
        if not f.is_file():
            continue
        if f.name.endswith(".gz"):
            out_name = f.stem + ".log"
            try:
                with gzip.open(f, "rb") as gz_in:
                    content = gz_in.read()
                with open(parsed_dir / out_name, "wb") as out_f:
                    out_f.write(content)
            except Exception:
                shutil.copy2(str(f), str(parsed_dir / f.name))   # gzip failed -> copy raw
        elif f.name.startswith("hilog_dict"):
            continue
        else:
            shutil.copy2(str(f), str(parsed_dir / f.name))


def collect_files(directory: Path) -> list[str]:
    """List files in a directory sorted by filename timestamp (oldest first)."""
    files: list[tuple[Path, datetime]] = []
    for f in directory.iterdir():
        if f.is_file():
            files.append((f, parse_filename_timestamp(f.name) or datetime.min))
    files.sort(key=lambda x: x[1])
    return [str(p) for p, _ in files]


def collect_parsed_files(parsed_dir: Path) -> list[str]:
    """Backward-compatible wrapper around collect_files."""
    return collect_files(parsed_dir)


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def emit(status: str, parsed_dir: Path | None, parsed_files: list[str] | None = None,
         files_pulled: int = 0, hilogtool_used: bool = False, message: str = "",
         partial: bool = False, failed_files: list[str] | None = None,
         cached_files: list[str] | None = None, reason: str = "",
         timed_out: bool = False, elapsed: float = 0.0) -> None:
    """Emit one JSON object with the full (additive) schema. Keeps every status
    site emitting the same superset of keys so downstream can index uniformly."""
    output_json({
        "status": status,
        "output_dir": str(parsed_dir) if parsed_dir is not None else "",
        "parsed_files": parsed_files or [],
        "files_pulled": files_pulled,
        "hilogtool_used": hilogtool_used,
        "message": message,
        "partial": partial,
        "failed_files": failed_files or [],
        "cached_files": cached_files or [],
        "reason": reason,
        "timed_out": timed_out,
        "elapsed_s": round(elapsed, 2),
    })


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Hilog log collector for ")
    parser.add_argument("--output-dir", default="diagnosis", help="Output base directory (default: diagnosis)")
    parser.add_argument("--hilogtool", default=None, help="Path to hilogtool.exe")
    parser.add_argument("--time-window", type=int, default=30, help="Pull files created within N minutes (default: 30)")
    parser.add_argument("--collect-timeout", type=float, default=DEFAULT_COLLECT_TIMEOUT,
                        help=f"Overall wall-clock budget in seconds (default: {DEFAULT_COLLECT_TIMEOUT:.0f})")
    parser.add_argument("--max-files", type=int, default=6,
                        help="Max timestamped .gz files to pull, newest first (dict/persisterInfo excluded; default: 6)")
    parser.add_argument("--max-bytes", type=int, default=0,
                        help="Max total bytes to pull, 0 = unlimited (default: 0)")
    parser.add_argument("--max-bytes-per-file", type=int, default=6,
                        help="Skip a .gz whose remote size exceeds this many MiB (default: 6)")
    parser.add_argument("--workers", type=int, default=4,
                        help="Parallel hdc file recv workers, clamped 1..8 (default: 4)")
    parser.add_argument("--fresh", action="store_true",
                        help="Wipe hilog_raw before collecting (disable pull cache)")
    parser.add_argument("--include-untimestamped-gz", action="store_true",
                        help="Pull .gz files that lack a filename timestamp (off by default)")
    args = parser.parse_args()

    dl = Deadline(args.collect_timeout)

    base_dir = Path(args.output_dir)
    raw_dir = base_dir / "hilog_raw"
    parsed_dir = base_dir / "hilog_parsed"
    raw_dir.mkdir(parents=True, exist_ok=True)
    parsed_dir.mkdir(parents=True, exist_ok=True)

    # raw_dir holds the expensive network pulls -> cache it unless --fresh.
    # parsed_dir is cheap to regenerate locally -> always clear before parsing.
    if args.fresh:
        _wipe_dir(raw_dir)

    # 1. Check device
    if dl.remaining() < 2.0:
        emit("error", parsed_dir, message="deadline exhausted before device check",
             reason="deadline exhausted", elapsed=dl.elapsed())
        return
    connected, msg = check_device(dl)
    if not connected:
        emit("no_device", parsed_dir, message=f"Device not available: {msg}",
             elapsed=dl.elapsed())
        return

    # 2. List device files (newest first, with sizes)
    ok_list, names, size_by_name = list_device_files_with_size(dl)
    if not ok_list or not names:
        emit("no_logs", parsed_dir, message="No files found in " + DEVICE_HILOG_DIR,
             elapsed=dl.elapsed())
        return

    # Drop metadata files except .persisterInfo_1
    names = [f for f in names if not f.startswith(".persisterInfo") or f == ".persisterInfo_1"]

    failed_files: list[str] = []
    cached_files: list[str] = []
    files_pulled = 0

    # 3. Pull dictionary files (small, serial, cache-aware)
    for name in find_dict_files(names):
        if dl.expired():
            failed_files.append(name)
            continue
        rsize = size_by_name.get(name)
        if _is_cached(raw_dir / name, rsize):
            cached_files.append(name)
            continue
        _, ok, _ = _pull_one(name, raw_dir, dl)
        if ok:
            files_pulled += 1
        else:
            failed_files.append(name)

    # 4. Pull active buffer (.persisterInfo_1)
    if ".persisterInfo_1" in names:
        if dl.expired():
            failed_files.append(".persisterInfo_1")
        else:
            rsize = size_by_name.get(".persisterInfo_1")
            if _is_cached(raw_dir / ".persisterInfo_1", rsize):
                cached_files.append(".persisterInfo_1")
            else:
                _, ok, _ = _pull_one(".persisterInfo_1", raw_dir, dl)
                if ok:
                    files_pulled += 1
                else:
                    failed_files.append(".persisterInfo_1")

    # 5. Pull .gz files (parallel, bounded, cache-aware, newest first)
    filtered_gz = filter_gz_files(names, args.time_window,
                                  include_untimestamped=args.include_untimestamped_gz)
    intended_gz = len(filtered_gz)
    max_files = max(1, args.max_files)
    gz_specs = [(name, size_by_name.get(name)) for name, _ in filtered_gz]
    gz_to_pull = gz_specs[:max_files]
    gz_capped = len(gz_to_pull) < intended_gz

    ok_gz, failed_gz, cached_gz, _ = pull_batch(
        gz_to_pull, raw_dir, dl, args.workers, args.max_bytes, args.max_bytes_per_file)
    files_pulled += len(ok_gz)
    cached_files.extend(cached_gz)
    failed_files.extend(failed_gz)

    got = files_pulled + len(cached_files)
    if got == 0:
        emit("no_logs", parsed_dir, message="No log files could be pulled",
             failed_files=failed_files, elapsed=dl.elapsed())
        return

    # 6. Parse (budget-aware). parsed_dir is always regenerated locally.
    _wipe_dir(parsed_dir)
    hilogtool_used = False
    parse_skipped = False
    use_hilogtool = bool(args.hilogtool) and Path(args.hilogtool).exists()
    if use_hilogtool:
        remaining = dl.remaining()
        if remaining < 3.0:
            parse_skipped = True        # not enough time for the external binary
        else:
            ok, _ = parse_with_hilogtool(args.hilogtool, raw_dir, parsed_dir,
                                         timeout=min(remaining - 1.0, HILOGTOOL_CMD_TIMEOUT))
            if ok:
                hilogtool_used = True
    if not hilogtool_used:
        parse_with_gzip(raw_dir, parsed_dir)   # gzip is fast; always produces output

    # 7. Decide status
    timed_out = dl.expired()
    reasons: list[str] = []
    if timed_out:
        reasons.append("collection deadline reached")
    if gz_capped:
        reasons.append(f"gz capped to {len(gz_to_pull)} of {intended_gz}")
    if parse_skipped:
        reasons.append("hilogtool skipped (deadline); gzip fallback used")
    if failed_files:
        reasons.append(f"{len(failed_files)} file(s) failed/skipped")
    reason = "; ".join(reasons)
    partial = bool(reasons)

    parsed_files = collect_parsed_files(parsed_dir)
    status = "partial" if partial else "success"
    emit(status, parsed_dir, parsed_files, files_pulled=files_pulled,
         hilogtool_used=hilogtool_used, message=reason if partial else "",
         partial=partial, failed_files=failed_files, cached_files=cached_files,
         reason=reason, timed_out=timed_out, elapsed=dl.elapsed())


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as exc:        # noqa: BLE001 - last-resort JSON safety net
        try:
            emit("error", None, message=f"Unhandled error: {type(exc).__name__}: {exc}",
                 reason="exception", elapsed=0.0)
        except Exception:
            pass
        sys.exit(1)
