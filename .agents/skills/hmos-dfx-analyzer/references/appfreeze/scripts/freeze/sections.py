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
"""faultlog 各日志区段的解析。

每个区段一个 parse_xxx 函数：输入日志行列表，输出对应的 dataclass。
区段不存在时返回字段为空的对象（或 None），调用方无需感知细节。
"""

import re
from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict, List, Optional

from freeze.common import find_section, parse_time, search_fields


# ---------------------------------------------------------------- 头部信息
@dataclass
class HeaderInfo:
    """faultlog 头部（Device info / Build info / ...）。"""
    device_info: str = ''
    build_version: str = ''
    module_name: str = ''
    app_version: str = ''
    is_pre_installed: str = ''
    foreground: str = ''
    reason: str = ''
    package_name: str = ''
    process_name: str = ''
    pid: str = ''
    uid: str = ''
    note: str = ''
    process_memory: str = ''
    device_memory: str = ''
    display_power: str = ''    # 故障时亮灭屏状态（AWAKE/SLEEP）
    page_history: List[str] = field(default_factory=list)  # 故障前页面切换历史


_HEADER_FIELD_RES = {
    'device_info': r'Device info:(.*)',
    'build_version': r'Build info:(.*)',
    'module_name': r'Module name:(.*)',
    'app_version': r'Version:(.*)',
    'is_pre_installed': r'PreInstalled:(.*)',
    'foreground': r'Foreground:(.*)',
    'reason': r'Reason:(.*)',
    'package_name': r'PACKAGE_NAME:(.*)',
    'process_name': r'(?:PROCESS_NAME|Process name):(.*)',
    'pid': r'(?:PID = |Pid:|pid=)(.*)',
    'uid': r'(?:UID = |Uid:|uid=)(.*)',
    'note': r'NOTE:(.*)',
    'process_memory': r'(Process Memory\(kB\):.*)',
    'device_memory': r'(Device Memory\(kB\):.*)',
    'display_power': r'DisplayPowerInfo:powerState:(.*)',
}


def parse_header(lines: List[str]) -> HeaderInfo:
    """解析文件头部。只扫描到第一个 'start time:' 之前，避免误读 MSG 区段。"""
    end_index = len(lines)
    for index, line in enumerate(lines):
        if 'start time:' in line:
            end_index = index
            break
    header = HeaderInfo(**search_fields(lines[:end_index], _HEADER_FIELD_RES))
    header.page_history = _parse_page_history(lines[:end_index])
    return header


def _parse_page_history(lines: List[str]) -> List[str]:
    """提取 'Page switch history:' 之后的页面切换记录（缩进行）。"""
    history = []
    in_history = False
    for line in lines:
        if 'Page switch history:' in line:
            in_history = True
            continue
        if in_history:
            if line.startswith((' ', '\t')) and line.strip():
                history.append(line.strip())
            else:
                break
    return history


# ---------------------------------------------------------------- MSG 信息
@dataclass
class MsgInfo:
    """事件上报信息（start time / EVENTNAME / MSG / Fault time / ...）。"""
    start_time: str = ''       # 上报 hiview 时间
    event_name: str = ''       # THREAD_BLOCK_3S / THREAD_BLOCK_6S 等
    timestamp: str = ''
    pid: str = ''
    tid: str = ''
    uid: str = ''
    module_name: str = ''      # APP_HICOLLIE 时为超时任务模块
    process_name: str = ''
    msg: str = ''
    fault_time: str = ''       # 故障真实发生时间

    def fault_datetime(self) -> Optional[datetime]:
        """故障发生时间，缺失时依次回落到 MSG 中的英文时间、TIMESTAMP。"""
        return parse_time(self.fault_time) or parse_time(self.msg) or parse_time(self.timestamp)

    def report_datetime(self) -> Optional[datetime]:
        return parse_time(self.start_time)


_MSG_FIELD_RES = {
    'start_time': r'start time:(.*)',
    'event_name': r'EVENTNAME = (.*)',
    'timestamp': r'TIMESTAMP = (.*)',
    'pid': r'(?:PID = |Pid:|pid=)(.*)',
    'tid': r'(?:TID = |Tid:|tid=)(.*)',
    'uid': r'(?:UID = |Uid:|uid=)(.*)',
    'module_name': r'MODULE_NAME = (.*)',
    'process_name': r'(?:PROCESS_NAME = |PROCESS_NAME:)(.*)',
    'msg': r'MSG =(.*)',
    'fault_time': r'Fault time:(.*)',
}


def parse_msg(lines: List[str]) -> MsgInfo:
    """解析事件上报区段：'start time:' 到 'MSG = ' 后两行。"""
    start_index = -1
    end_index = -1
    for index, line in enumerate(lines):
        if start_index < 0 and re.search(r'start time:', line):
            start_index = index
        if re.search(r'MSG =', line):
            end_index = index + 2
            break
    if start_index < 0 or end_index < 0:
        return MsgInfo()
    return MsgInfo(**search_fields(lines[start_index:end_index], _MSG_FIELD_RES))


# ------------------------------------------------------ EventHandler 队列
@dataclass
class HistoryEvent:
    """历史队列中的一个已执行任务。"""
    task_name: str = ''
    trigger_time: str = ''
    complete_time: str = ''
    priority: str = ''
    raw: str = ''

    def duration_seconds(self) -> Optional[float]:
        trigger = parse_time(self.trigger_time)
        complete = parse_time(self.complete_time)
        if not trigger or not complete:
            return None
        return (complete - trigger).total_seconds()


@dataclass
class EventQueueInfo:
    """EventHandler dump 区段。"""
    dump_begin_line: str = ''     # 'EventHandler dump begin curTime: ...'
    running_line: str = ''        # 'Current Running: start at ...'
    dump_begin_time: str = ''
    running_start_time: str = ''
    history_events: List[HistoryEvent] = field(default_factory=list)
    queue_counts: Dict[str, int] = field(default_factory=dict)  # {VIP: 1, High: 2, ...}
    total_count: int = 0

    def running_seconds(self) -> Optional[float]:
        """当前任务已执行时长 = dump 时间 - 任务开始时间（SKILL.md 4a 规则）。"""
        begin = parse_time(self.dump_begin_time)
        running = parse_time(self.running_start_time)
        if not begin or not running:
            return None
        return (begin - running).total_seconds()

    def long_history_events(self, threshold: float = 1.0) -> List[HistoryEvent]:
        """历史队列中执行超过 threshold 秒的任务（SKILL.md 4b 规则）。"""
        return [event for event in self.history_events
                if (event.duration_seconds() or 0) >= threshold]


def parse_event_queue(lines: List[str]) -> Optional[EventQueueInfo]:
    section, _ = find_section(lines, r'EventHandler dump begin curTime:', r'Total event size')
    if not section:
        return None
    info = EventQueueInfo()
    in_history = False
    for line in section:
        begin_match = re.search(r'EventHandler dump begin curTime: (.*)', line)
        if begin_match:
            info.dump_begin_line = line.strip()
            info.dump_begin_time = begin_match.group(1).strip()
            continue
        running_match = re.search(r'Current Running: start at (\d+-\d+-\d+ \d+:\d+:\d+\.\d+)', line)
        if running_match:
            info.running_line = line.strip()
            info.running_start_time = running_match.group(1)
            continue
        if 'History event queue information:' in line:
            in_history = True
            continue
        if re.search(r'\w+ priority event queue information:', line):
            in_history = False
            continue
        count_match = re.search(r'Total size of (\w+) events : (\d+)', line)
        if count_match:
            info.queue_counts[count_match.group(1)] = int(count_match.group(2))
            continue
        if in_history and 'task name = ' in line:
            info.history_events.append(_parse_history_event(line))
    # 'Total event size : N' 是区段结束行，不在 section 内，单独提取
    for line in lines:
        total_match = re.search(r'Total event size\s*:\s*(\d+)', line)
        if total_match:
            info.total_count = int(total_match.group(1))
            break
    return info


def _parse_history_event(line: str) -> HistoryEvent:
    fields = search_fields([line], {
        'task_name': r'task name = ([^,}]*)',
        'trigger_time': r'trigger time = ([^,}]*)',
        'complete_time': r'completeTime time = ([^,}]*)',
        'priority': r'priority = (\w+)',
    })
    return HistoryEvent(raw=line.strip(), **fields)


# ---------------------------------------------------------------- CPU 信息
@dataclass
class CpuInfo:
    """CPU 使用率区段（hidumper --cpuusage）。"""
    total_line: str = ''                                  # 'Total: 91.30%; ...'
    total_usage: float = -1.0
    process_names: Dict[str, str] = field(default_factory=dict)  # {pid: 进程名}（binder 节点命名用）


_CPU_ROW_RE = re.compile(
    r'\s+(?P<pid>\d+)\s+(?P<total>\d+\.\d+)%\s+\d+\.\d+%\s+\d+\.\d+%\s+\d+\s+\d+\s+(?P<name>.*)')


def parse_cpu(lines: List[str]) -> CpuInfo:
    info = CpuInfo()
    section, _ = find_section(lines, r'--\[cpuusage\]--', r'cpuusage end time:')
    if not section:
        return info
    for line in section:
        total_match = re.search(r'Total: (\d+\.\d+)%; User Space:', line)
        if total_match:
            info.total_line = line.strip()
            info.total_usage = float(total_match.group(1))
        row_match = _CPU_ROW_RE.search(line)
        if row_match:
            pid = row_match.group('pid')
            name = row_match.group('name').strip().split('/')[-1]
            info.process_names.setdefault(pid, name)
    return info


# ---------------------------------------------------------------- 内存信息
@dataclass
class MemoryInfo:
    """内存区段（MemoryCatcher）。"""
    mem_total_kb: float = 0.0
    mem_free_kb: float = 0.0
    mem_available_kb: float = 0.0
    reclaim_avail_buffer_kb: float = 0.0

    def available_mb(self) -> float:
        """可用内存（MB），优先取 ReclaimAvailBuffer。"""
        avail_kb = self.reclaim_avail_buffer_kb or self.mem_available_kb
        return round(avail_kb / 1024, 1)


_MEMORY_FIELD_RES = {
    'mem_total_kb': r'MemTotal:\s+(\d+)',
    'mem_free_kb': r'MemFree:\s+(\d+)',
    'mem_available_kb': r'MemAvailable:\s+(\d+)',
    'reclaim_avail_buffer_kb': r'ReclaimAvailBuffer:\s+(\d+)',
}


def parse_memory(lines: List[str]) -> MemoryInfo:
    section, _ = find_section(
        lines, r'MemoryCatcher --',
        r'end collect meminfo|Get freeze memory end time:|end time:')
    fields = search_fields(section, _MEMORY_FIELD_RES)
    return MemoryInfo(**{key: float(value) for key, value in fields.items()})


# ------------------------------------------------------------ 热等级信息
def parse_thermal(lines: List[str]) -> Optional[int]:
    """解析热等级（ThermalMgrClient/ThermalLevel），未找到返回 None。"""
    section, _ = find_section(
        lines, r'start collect hotInfo|ThermalInfoCatcher',
        r'end collect hotInfo|end time')
    for line in section:
        match = re.search(r'(?:ThermalMgrClient info:|ThermalLevel info:) (\d+)', line)
        if match:
            return int(match.group(1))
    return None


# ---------------------------------------------- 整机内存/CPU 历史采样序列
@dataclass
class SummarySeries:
    """SummaryLogInfoCatcher 区段：故障前后整机内存/CPU 的时间序列。"""
    mem_series: List[str] = field(default_factory=list)  # '时间：xxx, 可用内存：xxxMB'
    cpu_series: List[str] = field(default_factory=list)  # '时间：xxx, CPU使用率：xx%'


def parse_summary(lines: List[str]) -> SummarySeries:
    series = SummarySeries()
    section, _ = find_section(
        lines, r'SummaryLogInfoCatcher -- start time:', r'SummaryLogInfoCatcher -- end time:')
    for line in section:
        mem_match = re.search(
            r'(?:time|timestamp)=(?P<time>[\d/:\- ]+), data=MemAvailable: (?P<mem>\d+)M', line)
        if mem_match:
            series.mem_series.append(
                f'时间：{mem_match.group("time")}，可用内存：{mem_match.group("mem")}MB')
        cpu_match = re.search(
            r'(?:time|timestamp)=(?P<time>[\d/:\- ]+), data=CPU Usage: (?P<cpu>\d+)%', line)
        if cpu_match:
            series.cpu_series.append(
                f'时间：{cpu_match.group("time")}，CPU使用率：{cpu_match.group("cpu")}%')
    return series


# ---------------------------------------------------------------- FFRT 队列
@dataclass
class FfrtInfo:
    """FFRT 队列信息（SERVICE_BLOCK 场景，定位队列阻塞线程）。"""
    queue_name: str = ''
    tid: str = ''
    task_id: str = ''


def parse_ffrt(lines: List[str]) -> FfrtInfo:
    info = FfrtInfo()
    section, _ = find_section(
        lines, r'FfrtCallback:|FfrtCatcher -- start time', r'FfrtCatcher -- end time')
    for line in section:
        name_match = re.search(r'tskname\[[\w]+], qname=\[(?P<name>[\w]+)]', line)
        if name_match:
            info.queue_name = name_match.group('name')
        tid_match = re.search(
            r'worker tid (?P<tid>\d+) queue task is running, task id (?P<task_id>\d+)', line)
        if tid_match:
            info.tid = tid_match.group('tid')
            info.task_id = tid_match.group('task_id')
            break
    return info


# ------------------------------------------------------------ 生命周期信息
def parse_lifecycle(lines: List[str]) -> str:
    """LIFECYCLE_TIMEOUT 场景：提取 'ability:xxx' 超时信息。"""
    for line in lines:
        if line.startswith('ability:'):
            return line.split(':', 1)[-1].strip()
        if re.search(r'Main handler dump start time:|Catche stack', line):
            break
    return ''
