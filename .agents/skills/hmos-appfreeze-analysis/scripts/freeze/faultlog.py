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
"""把一个 appfreeze faultlog 文件解析成 FreezeLog 对象。

faultlog 的结构：
- 文件头部（Device info / Reason 等），以一行 '****...' 结束；
- warning 部分：第一次上报（如 THREAD_BLOCK_3S），含 MSG、EventHandler dump、
  线程堆栈、binder、CPU、内存、热等级等区段；
- 可选的 block 部分：第二次上报（如 THREAD_BLOCK_6S），以另一行 '****...' 开头，
  通常只含 MSG、EventHandler dump 和线程堆栈。

THREAD_BLOCK / APP_INPUT_BLOCK / LIFECYCLE_TIMEOUT / SERVICE_BLOCK 等类型
都符合上述结构（是否有 block 部分、是否有某个区段，按实际内容自适应），
因此这里不再按故障类型派生子类，统一走同一套解析。
"""

import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

from freeze.binder import BinderInfo, parse_binder
from freeze.common import find_section, parse_time, read_lines
from freeze.sections import (
    CpuInfo, EventQueueInfo, FfrtInfo, HeaderInfo, MemoryInfo, MsgInfo, SummarySeries,
    parse_cpu, parse_event_queue, parse_ffrt, parse_header, parse_lifecycle,
    parse_memory, parse_msg, parse_summary, parse_thermal)
from freeze.stack import ThreadStack, extract_stack_errors, parse_thread_stacks

# 头部结束 / warning 与 block 的分隔行：整行星号
_SEPARATOR_RE = re.compile(r'^\*{3,}\s*$')
# 主进程堆栈区段的结束标志（防止误把 binder 对端堆栈并进来）
_STACK_END_RE = r'Catche stack trace end time:|BinderCatcher --|PeerBinderCatcher|^-{5,}\s*$'
_FREEZE_REASON_RE = re.compile(
    r'(?:APP_FREEZE|SYS_FREEZE|APP_INPUT_BLOCK|THREAD_BLOCK|BUSINESS_THREAD_BLOCK|'
    r'BUSSINESS_THREAD_BLOCK|LIFECYCLE_(?:HALF_)?TIMEOUT|APP_HICOLLIE|SERVICE_BLOCK)'
)


@dataclass
class FreezePart:
    """一次上报抓取的内容（warning 或 block）。"""
    event_name: str = ''                 # THREAD_BLOCK_3S / THREAD_BLOCK_6S 等
    msg: MsgInfo = field(default_factory=MsgInfo)
    event_queue: Optional[EventQueueInfo] = None
    stacks: Dict[str, ThreadStack] = field(default_factory=dict)
    stack_catch_time: str = ''           # 抓栈开始时间
    stack_errors: List[str] = field(default_factory=list)

    def stack_catch_datetime(self) -> Optional[datetime]:
        return parse_time(self.stack_catch_time)


@dataclass
class FreezeLog:
    """一个 appfreeze faultlog 的全部结构化信息。"""
    path: Path = None
    reason: str = ''                     # THREAD_BLOCK_6S / APP_INPUT_BLOCK / ...
    header: HeaderInfo = field(default_factory=HeaderInfo)
    warning: FreezePart = field(default_factory=FreezePart)
    block: Optional[FreezePart] = None   # 第二次抓栈，单次抓栈类型为 None
    binder: BinderInfo = field(default_factory=BinderInfo)
    cpu: CpuInfo = field(default_factory=CpuInfo)
    memory: MemoryInfo = field(default_factory=MemoryInfo)
    summary: SummarySeries = field(default_factory=SummarySeries)
    hot_level: Optional[int] = None
    ffrt: FfrtInfo = field(default_factory=FfrtInfo)
    lifecycle_info: str = ''
    process_names: Dict[str, str] = field(default_factory=dict)  # {pid: 进程名}

    @property
    def pid(self) -> str:
        return self.warning.msg.pid or self.header.pid

    @property
    def process_name(self) -> str:
        return self.warning.msg.process_name or self.header.process_name \
            or self.header.module_name

    def fault_tid(self) -> str:
        """卡死线程 tid：默认取上报的 TID；FFRT 队列阻塞时取队列工作线程。"""
        if self.ffrt.tid:
            return self.ffrt.tid
        return self.warning.msg.tid or self.pid

    def fault_stack(self) -> Optional[ThreadStack]:
        """卡死线程的 warning 堆栈。"""
        return self.warning.stacks.get(self.fault_tid())

    def block_fault_stack(self) -> Optional[ThreadStack]:
        if not self.block:
            return None
        return self.block.stacks.get(self.fault_tid())


def parse_freeze_log(file_path) -> FreezeLog:
    """解析入口：faultlog 文件路径 -> FreezeLog。"""
    lines = read_lines(file_path)
    if not lines:
        raise ValueError(f'文件不存在或为空: {file_path}')
    assert_freeze_input(lines, file_path)
    freeze = FreezeLog(path=Path(file_path))
    freeze.header = parse_header(lines)

    warning_lines, block_lines = _split_parts(lines)
    freeze.warning = _parse_part(warning_lines)
    if block_lines:
        freeze.block = _parse_part(block_lines, len(lines) - len(block_lines) + 1)
    freeze.reason = freeze.header.reason or freeze.warning.msg.event_name

    # binder / CPU / 内存 / 热等级 / 整机采样 / ffrt 在整个文件中只出现一次，
    # 不区分 warning / block，直接在全文中定位
    freeze.binder = parse_binder(lines)
    freeze.cpu = parse_cpu(lines)
    freeze.memory = parse_memory(lines)
    freeze.hot_level = parse_thermal(lines)
    freeze.summary = parse_summary(lines)
    freeze.ffrt = parse_ffrt(lines)
    freeze.lifecycle_info = parse_lifecycle(lines)
    freeze.process_names = _build_process_names(freeze)
    return freeze


def assert_freeze_input(lines: List[str], file_path) -> None:
    """拒绝 Crash 或无法证明为 AppFreeze 的输入。"""
    log_type = _detect_log_type(lines)
    if log_type == 'APPFREEZE':
        return
    routes = {
        'CPP_CRASH': '请改用 cppcrash-analysis skill',
        'JS_CRASH': '请改用 jscrash-analysis skill',
    }
    route = routes.get(log_type, '请先确认日志类型，信息不足时补充完整故障日志')
    raise ValueError(
        f'入口断言失败：{file_path} 不是 AppFreeze 日志，识别结果为 {log_type}；{route}')


def _detect_log_type(lines: List[str]) -> str:
    header = '\n'.join(lines[:300])
    reason_match = re.search(r'^Reason:\s*(.*)$', header, re.MULTILINE)
    reason = reason_match.group(1).strip() if reason_match else ''
    if reason.startswith('Signal:') or 'Reason:GWP-ASAN' in header:
        return 'CPP_CRASH'
    if _FREEZE_REASON_RE.search(reason):
        return 'APPFREEZE'
    events = re.findall(r'EVENTNAME\s*=\s*(\S+)', header)
    if any(_FREEZE_REASON_RE.search(event) for event in events):
        return 'APPFREEZE'
    if 'Error name:' in header or 'Error message:' in header:
        return 'JS_CRASH'
    if 'Fault thread info:' in header or 'Registers:' in header:
        return 'CPP_CRASH'
    return 'UNKNOWN'


def _split_parts(lines: List[str]):
    """按星号分隔行拆出 warning / block 两部分。

    第 1 个分隔行是头部的结束；第 2 个分隔行（若有）之后是 block 部分。
    """
    separator_indexes = [index for index, line in enumerate(lines)
                         if _SEPARATOR_RE.match(line)]
    if len(separator_indexes) >= 2:
        split_at = separator_indexes[1]
        return lines[:split_at], lines[split_at:]
    return lines, []


def _parse_part(lines: List[str], start_line: int = 1) -> FreezePart:
    """解析一次上报的内容：MSG、EventHandler、线程堆栈。"""
    part = FreezePart()
    part.msg = parse_msg(lines)
    part.event_name = part.msg.event_name
    part.event_queue = parse_event_queue(lines)

    stack_lines, start_index = find_section(
        lines, r'^Tid:\d+(?:,|\s)+Name:', _STACK_END_RE)
    part.stacks = parse_thread_stacks(stack_lines, start_line + start_index)
    part.stack_errors = extract_stack_errors(stack_lines)
    # 抓栈时间在堆栈区段之前的 'Catche stack trace start time:' 或 'Timestamp:' 行
    head = lines[:start_index] if start_index > 0 else lines
    for line in reversed(head):
        time_match = re.search(r'(?:Catche stack trace start time:|Timestamp:)(.*)', line)
        if time_match:
            part.stack_catch_time = time_match.group(1).strip()
            break
    return part


def _build_process_names(freeze: FreezeLog) -> Dict[str, str]:
    """汇总 {pid: 进程名}：CPU 区段 + binder 对端 + 故障进程自身。"""
    names = dict(freeze.cpu.process_names)
    for pid, peer in freeze.binder.peers.items():
        if peer.process_name:
            names[pid] = peer.process_name.split('/')[-1]
    if freeze.pid and freeze.process_name:
        names[freeze.pid] = freeze.process_name.split('/')[-1]
    return names
