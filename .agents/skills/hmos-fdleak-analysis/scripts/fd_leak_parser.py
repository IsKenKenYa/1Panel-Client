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
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Extract stable evidence from FD leak diagnostic logs."""

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List, Optional, Tuple


LOG_NAME_PATTERNS = (
    re.compile(r"^\d+_fd_leak\.txt$", re.IGNORECASE),
    re.compile(r"^RESOURCE_OVERLIMIT_\d+_\d+\.log$", re.IGNORECASE),
)
COUNT_SECTION_MARKERS = ("Leaked fd Top 10:", "Dir Type Top 10:")
DETAIL_MARKERS = {
    "ashmem": "Process ashmem detail info:",
    "socket": "Process socket info:",
    "pipe": "Process pipe info:",
    "sync_file": "Process fence info:",
    "dmabuf": "Process dma_heap info:",
}
STACK_MARKER = "LOGGER_MEMCHECK_FD_STACK_INFO"
IGNORED_COUNT_LINES = ("FdCount", "FileDescriptor", "Sorted by")


@dataclass
class CountEntry:
    count: int
    name: str
    raw: str


@dataclass
class DetailSection:
    kind: str
    header: str
    record_count: int
    sample_rows: List[str]


@dataclass
class StackEntry:
    count: int
    frames: List[str]
    raw: str


@dataclass
class FdLeakReport:
    source: str
    time: str
    pid: str
    process: str
    leaked_fd_nums: Optional[int]
    fd_top: List[CountEntry]
    dir_top: List[CountEntry]
    details: List[DetailSection]
    stack_pid: str
    stack_time: str
    stacks: List[StackEntry]


def read_log(path: Path) -> str:
    """Read common log encodings without adding a third-party dependency."""
    data = path.read_bytes()
    for encoding in ("utf-8-sig", "utf-8", "gb18030"):
        try:
            return data.decode(encoding)
        except UnicodeDecodeError:
            continue
    return data.decode("utf-8", errors="replace")


def is_standard_log(path: Path) -> bool:
    return path.is_file() and any(pattern.match(path.name) for pattern in LOG_NAME_PATTERNS)


def discover_logs(input_path: Path, analyze_all: bool) -> List[Path]:
    if not input_path.exists():
        raise ValueError(f"输入路径不存在: {input_path}")
    if input_path.is_file():
        return [input_path]
    candidates = [path for path in input_path.rglob("*") if is_standard_log(path)]
    if not candidates:
        raise ValueError(f"目录中未找到标准 FD Leak 日志: {input_path}")
    candidates.sort(key=lambda path: (path.stat().st_mtime, str(path)), reverse=True)
    return candidates if analyze_all else candidates[:1]


def extract_field(text: str, field: str) -> str:
    pattern = re.compile(rf"^\s*{re.escape(field)}\s*:\s*(.*?)\s*$", re.MULTILINE | re.IGNORECASE)
    match = pattern.search(text)
    return match.group(1).strip() if match else ""


def parse_optional_int(value: str) -> Optional[int]:
    match = re.search(r"\d+", value)
    return int(match.group(0)) if match else None


def find_line(lines: List[str], marker: str) -> int:
    for index, line in enumerate(lines):
        if marker.lower() in line.lower():
            return index
    return -1


def is_divider(line: str) -> bool:
    stripped = line.strip()
    return not stripped or bool(re.fullmatch(r"[-=*]+", stripped))


def is_section_boundary(line: str, current_marker: str) -> bool:
    markers = list(COUNT_SECTION_MARKERS) + list(DETAIL_MARKERS.values())
    markers.extend((STACK_MARKER, "FdTrack Stack"))
    lowered = line.lower()
    return any(marker != current_marker and marker.lower() in lowered for marker in markers)


def parse_count_section(lines: List[str], marker: str) -> List[CountEntry]:
    start = find_line(lines, marker)
    if start < 0:
        return []
    entries: List[CountEntry] = []
    for line in lines[start + 1:]:
        stripped = line.strip()
        if is_section_boundary(stripped, marker):
            break
        match = re.match(r"^(\d+)\s+(.+?)\s*$", stripped)
        if match:
            entries.append(CountEntry(int(match.group(1)), match.group(2), stripped))
            continue
        if entries and stripped and not is_divider(stripped):
            break
        if any(header in stripped for header in IGNORED_COUNT_LINES):
            continue
    return entries


def looks_like_detail_header(line: str) -> bool:
    lowered = line.lower()
    return "process" in lowered and (" fd" in lowered or lowered.endswith("fd"))


def looks_like_detail_row(line: str) -> bool:
    parts = line.split()
    numeric_count = sum(1 for part in parts if part.lstrip("-").isdigit())
    return len(parts) >= 4 and numeric_count >= 2


def parse_detail_section(lines: List[str], kind: str, marker: str) -> Optional[DetailSection]:
    start = find_line(lines, marker)
    if start < 0:
        return None
    header = ""
    record_count = 0
    samples: List[str] = []
    for line in lines[start + 1:]:
        stripped = line.strip()
        if is_section_boundary(stripped, marker):
            break
        if is_divider(stripped):
            continue
        if not header and looks_like_detail_header(stripped):
            header = stripped
            continue
        if looks_like_detail_row(stripped):
            record_count += 1
            if len(samples) < 5:
                samples.append(stripped)
    return DetailSection(kind, header, record_count, samples)


def parse_details(lines: List[str]) -> List[DetailSection]:
    sections = []
    for kind, marker in DETAIL_MARKERS.items():
        section = parse_detail_section(lines, kind, marker)
        if section is not None:
            sections.append(section)
    return sections


def parse_stacks(text: str) -> List[StackEntry]:
    entries = []
    pattern = re.compile(r"^\s*num\s+(\d+)\s+bt\s+(.+?)\s*$", re.MULTILINE | re.IGNORECASE)
    for match in pattern.finditer(text):
        raw_frames = match.group(2)
        frames = [frame.strip() for frame in re.findall(r"\[([^\]]+)\]", raw_frames)]
        if frames:
            entries.append(StackEntry(int(match.group(1)), frames, match.group(0).strip()))
    entries.sort(key=lambda entry: entry.count, reverse=True)
    return entries


def parse_stack_fields(text: str) -> Tuple[str, str]:
    marker_index = text.find(STACK_MARKER)
    if marker_index < 0:
        return "", ""
    stack_text = text[marker_index:]
    return extract_field(stack_text, "pid"), extract_field(stack_text, "get stack time")


def parse_log(path: Path) -> FdLeakReport:
    text = read_log(path)
    header_text = text.split(STACK_MARKER, maxsplit=1)[0]
    lines = text.splitlines()
    stack_pid, stack_time = parse_stack_fields(text)
    return FdLeakReport(
        source=str(path.resolve()),
        time=extract_field(header_text, "time"),
        pid=extract_field(header_text, "pid"),
        process=extract_field(header_text, "process"),
        leaked_fd_nums=parse_optional_int(extract_field(header_text, "leaked fd nums")),
        fd_top=parse_count_section(lines, "Leaked fd Top 10:"),
        dir_top=parse_count_section(lines, "Dir Type Top 10:"),
        details=parse_details(lines),
        stack_pid=stack_pid,
        stack_time=stack_time,
        stacks=parse_stacks(text),
    )


def escape_table(value: object) -> str:
    return str(value).replace("|", "\\|").replace("\r", " ").replace("\n", " ")


def format_share(count: int, total: Optional[int]) -> str:
    if not total or total <= 0:
        return "-"
    return f"{count / total * 100:.2f}%"


def render_basic(report: FdLeakReport) -> List[str]:
    total = report.leaked_fd_nums if report.leaked_fd_nums is not None else "未获取"
    return [
        "## 故障基本信息",
        "",
        "| 字段 | 内容 |",
        "|---|---|",
        f"| 解析文件 | {escape_table(report.source)} |",
        f"| 故障时间 | {escape_table(report.time or '未获取')} |",
        f"| PID | {escape_table(report.pid or '未获取')} |",
        f"| 进程名 | {escape_table(report.process or '未获取')} |",
        f"| 泄漏快照数量 | {total} |",
    ]


def render_count_table(title: str, entries: List[CountEntry], total: Optional[int]) -> List[str]:
    lines = [title, ""]
    if not entries:
        return lines + ["未获取到该区段。"]
    lines.extend(("| 排名 | 数量 | 占快照比例 | 类型或路径 |", "|---:|---:|---:|---|"))
    for rank, entry in enumerate(entries, start=1):
        lines.append(
            f"| {rank} | {entry.count} | {format_share(entry.count, total)} | {escape_table(entry.name)} |"
        )
    return lines


def render_details(report: FdLeakReport) -> List[str]:
    lines = ["## 特殊句柄明细", ""]
    if not report.details:
        return lines + ["未获取到特殊句柄明细。"]
    lines.extend(("| 类型 | 记录数 | 字段头 | 样例记录（最多 5 条） |", "|---|---:|---|---|"))
    for section in report.details:
        sample = "<br>".join(escape_table(row) for row in section.sample_rows) or "未获取"
        lines.append(
            f"| {section.kind} | {section.record_count} | {escape_table(section.header or '未获取')} | {sample} |"
        )
    return lines


def render_stacks(report: FdLeakReport, stack_top: int) -> List[str]:
    lines = ["## FdTrack 申请栈热点", ""]
    lines.append(f"- 栈采集 PID：{report.stack_pid or '未获取'}")
    lines.append(f"- 栈采集时间：{report.stack_time or '未获取'}")
    lines.append("- 下表按真实调用方向展示：原始日志最右帧 -> 最左帧。")
    if not report.stacks:
        return lines + ["", "未获取到 FdTrack 栈。"]
    lines.extend(("", "| 排名 | 申请次数 | 调用链 |", "|---:|---:|---|"))
    for rank, entry in enumerate(report.stacks[:stack_top], start=1):
        call_chain = " -> ".join(reversed(entry.frames))
        lines.append(f"| {rank} | {entry.count} | {escape_table(call_chain)} |")
    return lines


def render_constraints() -> List[str]:
    return [
        "## 解析约束",
        "",
        "- `leaked fd nums` 是判定时刻的存量快照。",
        "- FdTrack 栈统计 10 分钟内全部 FD 申请，包含后来已关闭的 FD，不能单独作为泄漏实锤。",
        "- nolog 版本未开启开发者模式时可能没有栈信息。",
        "- 原始栈只有 `so+offset` 时，需要匹配符号文件完成函数和源码行反解。",
    ]


def render_markdown(report: FdLeakReport, stack_top: int) -> str:
    sections = [
        ["# FD Leak 日志解析结果"],
        render_basic(report),
        render_count_table("## 句柄类型 Top", report.fd_top, report.leaked_fd_nums),
        render_count_table("## 文件目录 Top", report.dir_top, report.leaked_fd_nums),
        render_details(report),
        render_stacks(report, stack_top),
        render_constraints(),
    ]
    return "\n\n".join("\n".join(section) for section in sections)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="解析 FD Leak 句柄泄漏日志")
    parser.add_argument("-p", "--path", required=True, help="FD Leak 日志文件或目录")
    parser.add_argument("--all", action="store_true", help="分析目录内全部标准日志")
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument("--stack-top", type=int, default=10, help="输出申请栈 Top 数量，默认 10")
    return parser


def output_reports(reports: List[FdLeakReport], output_format: str, stack_top: int) -> None:
    if output_format == "json":
        payload = {"reports": [asdict(report) for report in reports]}
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return
    rendered = [render_markdown(report, stack_top) for report in reports]
    print("\n\n---\n\n".join(rendered))


def main(argv: Optional[List[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    if args.stack_top <= 0:
        print("错误: --stack-top 必须大于 0", file=sys.stderr)
        return 2
    try:
        paths = discover_logs(Path(args.path), args.all)
        reports = [parse_log(path) for path in paths]
        output_reports(reports, args.format, args.stack_top)
    except (OSError, ValueError) as error:
        print(f"错误: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
