# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Discover the memory-leak artifacts that belong to one analysis case."""

import argparse
import os
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional, Tuple

from tools.common_tools import print_table_info
from tools.memleak_file_name import parse_kernel_file_name, parse_native_file_name


NATIVE_KINDS = ("sample", "smaps", "profile")


def _prefer_native_candidate(
        current, candidate_path: str, timestamp: Optional[int], modified_time_ns: int):
    candidate_key = (timestamp if timestamp is not None else -1, modified_time_ns, candidate_path)
    if current is None or candidate_key > current["selection_key"]:
        return {
            "selection_key": candidate_key,
            "path": candidate_path,
            "timestamp": timestamp,
            "modified_time_ns": modified_time_ns,
        }
    return current


def _timestamp_to_datetime(timestamp: int):
    try:
        return datetime.strptime(str(timestamp), "%Y%m%d%H%M%S")
    except ValueError:
        return None


def _select_kernel(candidates, reference_timestamp: Optional[int] = None):
    if not candidates:
        return None
    reference_time = _timestamp_to_datetime(reference_timestamp) if reference_timestamp else None
    if reference_time:
        def proximity_key(item):
            capture_time = _timestamp_to_datetime(item["metadata"]["timestamp"])
            distance = abs((capture_time - reference_time).total_seconds()) if capture_time else float('inf')
            return (
                distance,
                -item["metadata"]["timestamp"],
                item["metadata"]["is_hiapp"],
                item["path"],
            )
        return min(candidates, key=proximity_key)["path"]

    # Capture time is authoritative. Canonical wins only when timestamp ties.
    return max(
        candidates,
        key=lambda item: (
            item["metadata"]["timestamp"],
            not item["metadata"]["is_hiapp"],
            item["path"],
        ),
    )["path"]


def _native_entry_recency(entry):
    profile = entry["files"].get("profile")
    if profile and profile["timestamp"] is not None:
        return 1, profile["timestamp"], profile["modified_time_ns"]
    latest_modified_time = max(
        candidate["modified_time_ns"] for candidate in entry["files"].values()
    )
    return 0, latest_modified_time, 0


def _collect_candidates(root: Path):
    native_candidates: Dict[Tuple[str, str], Dict[str, object]] = {}
    kernel_candidates = defaultdict(list)
    for current_root, directories, files in os.walk(root):
        directories.sort()
        for file_name in sorted(files):
            file_path = str(Path(current_root, file_name).resolve())
            modified_time_ns = Path(file_path).stat().st_mtime_ns
            native_metadata = parse_native_file_name(file_name)
            if native_metadata:
                key = (native_metadata["process_name"], native_metadata["pid"])
                entry = native_candidates.setdefault(
                    key, {"process_name": key[0], "pid": key[1], "files": {}}
                )
                kind = native_metadata["kind"]
                entry["files"][kind] = _prefer_native_candidate(
                    entry["files"].get(kind), file_path,
                    native_metadata["timestamp"], modified_time_ns,
                )
            kernel_metadata = parse_kernel_file_name(file_name)
            if kernel_metadata:
                kernel_candidates[kernel_metadata["process_name"]].append(
                    {"metadata": kernel_metadata, "path": file_path}
                )
    return native_candidates, kernel_candidates


def _select_native_result(native_candidates, kernel_candidates):
    selected = max(
        native_candidates.values(),
        key=lambda entry: (
            len(entry["files"]), _native_entry_recency(entry),
            entry["process_name"], entry["pid"],
        ),
    )
    result = {kind: None for kind in NATIVE_KINDS}
    for kind in NATIVE_KINDS:
        candidate = selected["files"].get(kind)
        result[kind] = candidate["path"] if candidate else None
    profile = selected["files"].get("profile")
    reference_timestamp = profile["timestamp"] if profile else None
    result["kernel"] = _select_kernel(
        kernel_candidates.get(selected["process_name"], []), reference_timestamp
    )
    return result


def discover_analysis_files(root_path: str) -> Dict[str, Optional[str]]:
    """Select a deterministic sample/smaps/profile/kernel set under root_path."""
    root = Path(root_path)
    if not root.is_dir():
        raise ValueError(f"输入目录不存在或不是目录: {root_path}")
    native_candidates, kernel_candidates = _collect_candidates(root)
    if native_candidates:
        return _select_native_result(native_candidates, kernel_candidates)
    result = {kind: None for kind in NATIVE_KINDS}
    all_kernel_candidates = [item for items in kernel_candidates.values() for item in items]
    result["kernel"] = _select_kernel(all_kernel_candidates)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="发现 Native 内存泄漏分析所需文件")
    parser.add_argument("-p", "--path", required=True, help="日志目录路径")
    args = parser.parse_args()
    try:
        selected = discover_analysis_files(args.path)
    except ValueError as error:
        parser.error(str(error))

    rows = [("文件类型", "文件路径")]
    if any(selected[kind] for kind in NATIVE_KINDS):
        rows.extend((kind, selected[kind]) for kind in NATIVE_KINDS)
        rows.append(("kernel", selected["kernel"]))
    elif selected["kernel"]:
        rows.append(("kernel", selected["kernel"]))
    else:
        print("未发现可分析的memleak native/kernel日志文件。", file=sys.stderr)
        return 2
    print(print_table_info(rows), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
