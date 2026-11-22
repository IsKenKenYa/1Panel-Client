# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
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

"""把一个 cppcrash faultlog 文件解析成 CppCrashLog 对象。

cppcrash 日志的固定结构（按顺序）：
头部（Device info / Reason / LastFatalMessage ...）
'Fault thread info:'      崩溃线程堆栈
'Registers:'              寄存器
'Other thread info:'      其他线程堆栈（可选）
'Memory near registers:'  寄存器附近内存
'Maps:'                   进程内存映射
'OpenFiles:'              打开的文件（可选）
'HiLog:'                  崩溃前流水日志（可选）

GWP-ASan 日志没有上述标准区段时，仍保留从检测标记到报告结束标记的完整原文。
"""

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

from common import read_lines, search_fields, split_by_markers

_THREAD_HEADER_RE = re.compile(r'^\s*Tid:(?P<tid>\d+)(?:,|\s)+Name:(?P<name>.*)')
_FRAME_RE = re.compile(r'^\s*#\d+ pc (?P<offset>[0-9a-fA-F]+) (?P<location>.*)')
_REASON_RE = re.compile(
    r'Signal:(?P<signal>\w+)(?:\((?P<code>[\w-]+)\))?'
    r'(?:@(?P<address>0x[0-9a-fA-F]+))?')
_MAPS_RE = re.compile(
    r'^(?P<start>[0-9a-fA-F]+)-(?P<end>[0-9a-fA-F]+)\s+'
    r'(?P<perms>\S+)\s+[0-9a-fA-F]+\s+(?P<rest>.*)')

# 识别调用方时跳过的低层运行时与桥接帧。崩溃帧始终单独保留，不会被丢弃。
_RUNTIME_FRAME_RE = re.compile(
    r'libc\.so|libc\+\+|ld-musl-|libsec_shared|libutils|__cfi_check|stub\.an|'
    r'Not mapped|Not\(mapped\)|Unknown|libark_jsruntime\.so|libace_napi\.z\.so|'
    r'ArkNativeReference|ArkNativeFunction|panda::JSNApi|panda::JSValueRef')


@dataclass
class StackFrame:
    """单个栈帧（保留原始文本，llvm-addr2line 需要其中的 pc 偏移）。"""
    raw: str
    offset: str = ''      # pc 相对偏移
    so_path: str = ''     # so 完整路径
    file_name: str = ''   # so 文件名
    function_name: str = ''

    @staticmethod
    def build(line: str) -> 'StackFrame':
        frame = StackFrame(raw=line)
        match = _FRAME_RE.search(line)
        if not match:
            return frame
        frame.offset = match.group('offset')
        location = re.sub(r'\([\da-fA-F]{16,}\)\s*$', '', match.group('location')).strip()
        frame.so_path = location.split('(')[0].strip()
        frame.file_name = frame.so_path.split('/')[-1]
        func_split = re.split(r'[(<\[]', location)
        if len(func_split) > 1:
            frame.function_name = func_split[1].split('+')[0].strip()
        return frame


@dataclass
class ThreadStack:
    tid: str = ''
    name: str = ''
    frames: List[StackFrame] = field(default_factory=list)

    def raw_str(self) -> str:
        header = f'Tid:{self.tid}, Name:{self.name}\n'
        return header + ''.join(frame.raw for frame in self.frames)

    def first_non_runtime_caller(self) -> Optional[StackFrame]:
        """返回跳过低层运行时和桥接层后的第一个调用方。"""
        for frame in self.frames:
            if frame.offset and not _RUNTIME_FRAME_RE.search(frame.raw):
                return frame
        return None

    def first_application_frame(self) -> Optional[StackFrame]:
        """返回路径能够明确识别为应用产物的第一帧。"""
        for frame in self.frames:
            if frame.offset and frame.so_path.startswith('/data/'):
                return frame
        return None


@dataclass
class CrashHeader:
    """cppcrash 日志头部。"""
    device_info: str = ''
    build_version: str = ''
    module_name: str = ''
    app_version: str = ''
    is_pre_installed: str = ''
    foreground: str = ''
    pid: str = ''
    uid: str = ''
    process_name: str = ''
    process_life_time: str = ''
    timestamp: str = ''
    reason: str = ''
    last_fatal_message: str = ''

    def signal(self) -> str:
        match = _REASON_RE.search(self.reason)
        return match.group('signal') if match else ''

    def signal_code(self) -> str:
        match = _REASON_RE.search(self.reason)
        return (match.group('code') or '') if match else ''

    def crash_address(self) -> Optional[int]:
        """崩溃地址（int），Reason 中无地址时返回 None。"""
        match = _REASON_RE.search(self.reason)
        if not match or not match.group('address'):
            return None
        try:
            return int(match.group('address'), 16)
        except ValueError:
            return None


_HEADER_FIELD_RES = {
    'device_info': r'Device info:(.*)',
    'build_version': r'Build info:(.*)',
    'module_name': r'Module name:(.*)',
    'app_version': r'Version:(.*)',
    'is_pre_installed': r'PreInstalled:(.*)',
    'foreground': r'Foreground:(.*)',
    'pid': r'Pid:(.*)',
    'uid': r'Uid:(.*)',
    'process_name': r'Process name:(.*)',
    'process_life_time': r'Process life time:(.*)',
    'timestamp': r'Timestamp:(.*)',
    'reason': r'Reason:(.*)',
    'last_fatal_message': r'LastFatalMessage:(.*)',
}


@dataclass
class CppCrashLog:
    """一个 cppcrash faultlog 的全部结构化信息。"""
    path: Path = None
    header: CrashHeader = field(default_factory=CrashHeader)
    fault_stack: ThreadStack = field(default_factory=ThreadStack)
    other_threads: List[ThreadStack] = field(default_factory=list)
    registers_text: str = ''                  # 寄存器区段原文
    register_values: Dict[str, int] = field(default_factory=dict)  # {寄存器名: 值}
    memory_near_text: str = ''                # 寄存器附近内存区段原文
    fault_stack_memory_text: str = ''         # FaultStack 栈内存区段原文
    maps_lines: List[str] = field(default_factory=list)
    has_hilog: bool = False
    gwp_asan_text: str = ''

    def relevant_maps(self) -> List[str]:
        """与崩溃相关的 maps 行：崩溃地址所在区间 + 崩溃栈涉及的 so。"""
        fault_so_names = {frame.file_name for frame in self.fault_stack.frames if frame.file_name}
        address = self.header.crash_address()
        relevant = []
        for line in self.maps_lines:
            match = _MAPS_RE.search(line)
            if not match:
                continue
            pathname = _maps_pathname(match)
            in_range = address is not None and \
                int(match.group('start'), 16) <= address < int(match.group('end'), 16)
            if in_range or pathname.split('/')[-1] in fault_so_names:
                relevant.append(line.rstrip('\n'))
        return relevant

    def sp_region(self) -> Optional[tuple]:
        """sp 所在的 maps 区间 (start, end, pathname)，用于栈溢出判断。

        注意子线程栈在 [anon:stack:tid] 匿名区间，主线程栈
        也未必标记为 [stack]，因此按 sp 落点查找而不是按区间名查找。
        """
        sp = self.register_values.get('sp')
        if sp is None:
            return None
        for line in self.maps_lines:
            match = _MAPS_RE.search(line)
            if not match:
                continue
            start, end = int(match.group('start'), 16), int(match.group('end'), 16)
            if start <= sp < end:
                return start, end, _maps_pathname(match)
        return None


def _maps_pathname(match) -> str:
    """从 maps 行的剩余部分取路径，兼容 Linux 格式多出的 'dev inode' 两列。"""
    rest = match.group('rest').strip()
    return re.sub(r'^\S+:\S+\s+\d+\s*', '', rest)


def parse_crash_log(file_path) -> CppCrashLog:
    """解析入口：cppcrash faultlog 文件路径 -> CppCrashLog。"""
    lines = read_lines(file_path)
    if not lines:
        raise ValueError(f'文件不存在或为空: {file_path}')
    crash = CppCrashLog(path=Path(file_path))
    sections = split_by_markers(lines, [
        'Fault thread info:', 'Registers:', 'Other thread info:',
        'Memory near registers:', 'FaultStack:', 'Maps:', 'OpenFiles:', 'HiLog:'])

    crash.header = CrashHeader(**search_fields(sections[''], _HEADER_FIELD_RES))
    threads = _parse_threads(sections['Fault thread info:'])
    if threads:
        crash.fault_stack = threads[0]
    crash.other_threads = _parse_threads(sections['Other thread info:'])
    crash.registers_text = ''.join(sections['Registers:'][1:]).rstrip('\n')
    crash.register_values = _parse_registers(sections['Registers:'])
    crash.memory_near_text = ''.join(sections['Memory near registers:'][1:]).rstrip('\n')
    crash.fault_stack_memory_text = ''.join(sections['FaultStack:'][1:]).rstrip('\n')
    crash.maps_lines = sections['Maps:'][1:]
    crash.has_hilog = bool(sections['HiLog:'])
    crash.gwp_asan_text = _extract_gwp_asan(lines)
    return crash


def _parse_threads(lines: List[str]) -> List[ThreadStack]:
    threads = []
    current = None
    for line in lines:
        header_match = _THREAD_HEADER_RE.search(line)
        if header_match:
            current = ThreadStack(tid=header_match.group('tid'),
                                  name=header_match.group('name').strip())
            threads.append(current)
            continue
        if current and _FRAME_RE.search(line):
            current.frames.append(StackFrame.build(line))
    return threads


def _parse_registers(lines: List[str]) -> Dict[str, int]:
    values = {}
    for line in lines:
        for match in re.finditer(r'(\w+):(?:0x)?([0-9a-fA-F]{1,16})\b', line):
            try:
                values[match.group(1)] = int(match.group(2), 16)
            except ValueError:
                continue
    return values


def _extract_gwp_asan(lines: List[str]) -> str:
    start = None
    for index, line in enumerate(lines):
        if '*** GWP-ASan detected a memory error ***' in line:
            start = index
            break
    if start is None:
        return ''
    end = len(lines)
    for index in range(start, len(lines)):
        if '* End GWP-ASan report *' in lines[index]:
            end = index + 1
            break
    return ''.join(lines[start:end]).rstrip('\n')
