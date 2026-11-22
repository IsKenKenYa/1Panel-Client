#!/usr/bin/env python3
"""Run the full analysis pipeline: htrace db -> summary/topdown/meminfo."""

import argparse
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from config import config_data, DEFAULT_TYPES
from statistic_htrace_analysis import process_data


def main():
    parser = argparse.ArgumentParser(description="Run memory analysis pipeline")
    parser.add_argument("-p", "--trace-path", required=True, help="Path to .db directory")
    parser.add_argument("-f", "--out-path", required=True, help="Output directory for analysis results")
    parser.add_argument("--pid", type=int, default=-1, help="Target PID (-1 for auto)")
    parser.add_argument("--mm-dmabuf", default=None, help="Path to mm_dmabuf_info file")
    parser.add_argument("--showmap", default=None, help="Path to smaps/showmap file")
    args = parser.parse_args()

    config_data["type"] = DEFAULT_TYPES
    config_data["kinds"] = None
    config_data["limit"] = [10, 0, 5]
    config_data["pid"] = args.pid
    config_data["newrule"] = True
    config_data["detail"] = False
    config_data["detail_explicitly_set"] = False
    config_data["startts"] = None
    config_data["endts"] = None
    config_data["heading"] = False
    config_data["empty_service"] = 35
    config_data["hiprofiler_noise"] = 42
    config_data["arkts_empty_service"] = 10
    config_data["mm_dmabuf_file"] = args.mm_dmabuf
    config_data["showmap"] = args.showmap

    process_data(trace_path=args.trace_path, out_path=args.out_path)
    print(f"Analysis complete: {args.out_path}")


if __name__ == "__main__":
    main()
