#!/usr/bin/env python3
"""Convert htrace files to sqlite db using trace_streamer."""

import argparse
import platform
import shutil
import subprocess
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
from tool_finder import find_trace_streamer, _win_temp_dir

TS_DOWNLOAD_URL = (
    "https://gitcode.com/openharmony/developtools_smartperf_host/releases/download/"
    "HiSmartPerf_20260730/trace_streamer_binary.zip"
)
TS_DOWNLOAD_FALLBACK = "https://gitcode.com/openharmony/developtools_smartperf_host/releases"


def win_path(linux_path: str) -> str:
    p = str(Path(linux_path))
    if platform.system() == "Windows":
        return p.replace("/", "\\")
    return p


def _ts_not_found_error():
    print("[ERROR] trace_streamer not found via tool_finder.", file=sys.stderr)
    print("  Searched: TRACE_STREAMER_PATH env → DevEco Studio → system PATH.", file=sys.stderr)
    print("", file=sys.stderr)
    print("  If not installed locally, download:", file=sys.stderr)
    print(f"  Download: {TS_DOWNLOAD_URL}", file=sys.stderr)
    print(f"  Fallback (if link expired, find latest version): {TS_DOWNLOAD_FALLBACK}", file=sys.stderr)
    print("  The zip contains all-platform binaries. Extract and choose by platform:", file=sys.stderr)
    print("    Windows: trace_streamer_windows.exe", file=sys.stderr)
    print("    Linux:   trace_streamer_linux", file=sys.stderr)
    print("    macOS:   trace_streamer_mac", file=sys.stderr)
    print("", file=sys.stderr)
    print("  Then set TRACE_STREAMER_PATH env var or add to PATH.", file=sys.stderr)
    print("  Or pass the path directly: --ts /path/to/trace_streamer", file=sys.stderr)


def main():
    default_ts = find_trace_streamer() or "trace_streamer"
    default_temp = _win_temp_dir()

    parser = argparse.ArgumentParser(description="Convert htrace to sqlite db")
    parser.add_argument("htrace_path", help="Path to .htrace file")
    parser.add_argument("-o", "--output", help="Output .db path (default: same dir, same name)")
    parser.add_argument("--ts", default=default_ts, help="trace_streamer path")
    parser.add_argument("--win-temp", default=default_temp, help="Windows temp dir")
    args = parser.parse_args()

    htrace = Path(args.htrace_path)
    if not htrace.exists():
        print(f"Error: {htrace} not found")
        sys.exit(1)

    if args.output:
        db_path = Path(args.output)
    else:
        db_path = htrace.with_suffix(".db")

    htrace_win = win_path(str(htrace))
    db_win = win_path(str(db_path))

    ts_path = args.ts
    if not shutil.which(ts_path) and not Path(ts_path).is_file():
        _ts_not_found_error()
        sys.exit(1)

    print(f"Converting: {htrace_win} -> {db_win}")
    result = subprocess.run([ts_path, htrace_win, "-e", db_win], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)

    print(f"Done: {db_path}")


if __name__ == "__main__":
    main()
