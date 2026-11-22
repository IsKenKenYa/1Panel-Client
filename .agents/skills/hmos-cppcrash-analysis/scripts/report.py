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

"""关键日志报告渲染：CppCrashLog -> 供大模型分析的文本。

报告保留信号、分层调用帧、寄存器、关键内存和专项检测器证据，
用于导航后续的 reference 匹配、符号化和源码分析。
"""

from typing import List, Optional

from crash_log import CppCrashLog
from hints import match_hints

# 信号 + code 的含义与排查方向（来自 SKILL.md 信号速查表）
_SIGNAL_NOTES = {
    ('SIGSEGV', 'SEGV_MAPERR'): '访问未映射内存，排查方向：空指针、野指针、越界',
    ('SIGSEGV', 'SEGV_ACCERR'): '访问权限不足，排查方向：写只读内存、代码段写操作',
    ('SIGSEGV', 'SI_TKILL'): '信号由其他进程/线程通过 tkill 发送，关注 Reason 中的 from 进程',
    ('SIGILL', None): '非法指令，排查方向：错误跳转、指令损坏、ISA/PAC/CFI问题',
    ('SIGBUS', 'BUS_ADRALN'): '地址未对齐，排查方向：指针强转后非对齐访问',
    ('SIGBUS', 'BUS_OBJERR'): '对象硬件错误，常见于文件映射页异常（如数据库文件被破坏）',
    ('SIGABRT', None): '进程主动终止，优先检查LastFatalMessage（保留原始信息，根据信息提示定位崩溃原因）、断言、未捕获异常和检测器报告',
    ('SIGTRAP', None): '调试陷阱指令，常见于主动检测代码触发',
    ('SIGSYS', None): '非法系统调用',
}


def render_report(crash: CppCrashLog,
                  other_logs: Optional[List] = None) -> str:
    sections = [
        _render_basic(crash),
        _render_gwp_asan(crash),
        _render_fault_stack(crash),
        _render_hints(crash),
        _render_registers(crash),
        _render_maps(crash),
        _render_other_threads(crash),
        _render_attachments(crash, other_logs or []),
    ]
    return '\n'.join(section for section in sections if section)


def _title(name: str) -> str:
    return f'\n【{name}】'


# ---------------------------------------------------------------- 基本信息
def _render_basic(crash: CppCrashLog) -> str:
    header = crash.header
    lines = ['【故障基本信息】',
             '故障类型：CPP_CRASH',
             f'故障进程pid：{header.pid}',
             f'故障线程tid：{crash.fault_stack.tid}（{crash.fault_stack.name}）',
             f'故障模块：{header.module_name or header.process_name}',
             f'故障时间：{header.timestamp}',
             f'故障原因：{header.reason}']
    lines += _signal_lines(crash)
    optional = [
        ('前后台状态', {'Yes': '前台', 'No': '后台'}.get(header.foreground, header.foreground)),
        ('是否预安装', {'Yes': '是', 'No': '否'}.get(header.is_pre_installed, header.is_pre_installed)),
        ('进程存活时长', header.process_life_time),
        ('构建版本', header.build_version),
        ('应用版本', header.app_version),
        ('LastFatalMessage', header.last_fatal_message),
    ]
    lines += [f'{label}：{value}' for label, value in optional if value]
    if header.last_fatal_message:
        lines.append('提示：请保留 LastFatalMessage 原始信息，根据其中的信息提示定位崩溃原因')
    lines.append(f'日志文件：{crash.path}')
    return '\n'.join(lines)


def _signal_lines(crash: CppCrashLog) -> List[str]:
    """信号与崩溃地址的解读（SKILL.md 步骤二、三）。"""
    signal = crash.header.signal()
    if not signal:
        return []
    code = crash.header.signal_code()
    note = _SIGNAL_NOTES.get((signal, code)) or _SIGNAL_NOTES.get((signal, None))
    lines = []
    if note:
        lines.append(f'信号解读：{signal}({code}) {note}' if code else f'信号解读：{signal} {note}')
    address = crash.header.crash_address()
    if address is not None:
        if address == 0:
            lines.append('崩溃地址解读：@0x0，疑似空基址访问，需结合访存指令和基址寄存器确认')
        elif address < 0x1000:
            lines.append(f'崩溃地址解读：@{hex(address)} 为极小值，'
                         '疑似空基址加成员偏移，需结合访存指令确认')
    lines += _stack_overflow_line(crash)
    return lines


def _stack_overflow_line(crash: CppCrashLog) -> List[str]:
    """sp 紧贴所在栈区间下界（<4KB）时提示疑似栈溢出。"""
    sp = crash.register_values.get('sp')
    region = crash.sp_region()
    if sp is None:
        return []
    if region is None and crash.maps_lines:
        return [f'栈指针异常：sp({hex(sp)}) 未落在任何内存映射区间内，'
                '疑似栈被破坏或严重栈溢出']
    if region and 'stack' in region[2] and sp - region[0] < 0x1000:
        return [f'栈溢出特征：sp({hex(sp)}) 距所在栈区间 {region[2]} '
                f'下界({hex(region[0])})不足4KB，疑似栈溢出，请排查递归调用或大块栈内存使用']
    return []


# ------------------------------------------------------------ 崩溃线程堆栈
def _render_fault_stack(crash: CppCrashLog) -> str:
    lines = [_title('崩溃线程堆栈'),
             '说明：调用方向从栈底（最大编号）到栈顶（#00）；'
             '各帧保留 pc 相对偏移；仅对最近的应用侧帧使用 '
             'python "<skill-root>/scripts/ohos_llvm_tools.py" addr2line <应用so> <偏移> 解析行号，'
             '不得要求应用反解系统栈']
    if not crash.fault_stack.frames:
        lines.append('未解析到崩溃线程堆栈')
        return '\n'.join(lines)
    lines.append(crash.fault_stack.raw_str().rstrip('\n'))
    crash_frame = crash.fault_stack.frames[0]
    lines.append(f'崩溃帧：{crash_frame.raw.strip()}')
    caller = crash.fault_stack.first_non_runtime_caller()
    if caller:
        lines.append(f'首个非运行时调用方：{caller.raw.strip()}')
    else:
        lines.append('首个非运行时调用方：未找到')
    application = crash.fault_stack.first_application_frame()
    if application:
        lines.append(f'首个应用侧帧候选：{application.raw.strip()}')
        lines.append('归属说明：/data路径仅表示产物位置，责任仍需结合入参、生命周期和源码确认')
    else:
        lines.append('首个应用侧帧候选：未找到；不得仅凭系统栈推定系统根因')
    return '\n'.join(lines)


def _render_gwp_asan(crash: CppCrashLog) -> str:
    if not crash.gwp_asan_text:
        return ''
    return '\n'.join([
        _title('GWP-ASan原始报告'),
        '说明：完整保留违规访问、释放和申请调用栈，按references/gwp_asan.md分析。',
        crash.gwp_asan_text,
    ])


# ------------------------------------------------------------ 特征匹配提示
def _render_hints(crash: CppCrashLog) -> str:
    hints = match_hints(crash)
    if not hints:
        return ''
    lines = [_title('特征匹配提示'),
             '说明：以下为常见崩溃模式的特征匹配结果，仅作分析线索，需结合证据链确认']
    lines += [f'- {hint}' for hint in hints]
    return '\n'.join(lines)


# ---------------------------------------------------------------- 寄存器
def _render_registers(crash: CppCrashLog) -> str:
    lines = [_title('寄存器信息')]
    lines.append(crash.registers_text or '未解析到寄存器信息')
    if crash.memory_near_text:
        lines.append(_title('寄存器附近内存'))
        lines.append(_bounded_text(crash.memory_near_text, 240))
    if crash.fault_stack_memory_text:
        lines.append(_title('崩溃线程栈内存(FaultStack)'))
        lines.append(_bounded_text(crash.fault_stack_memory_text, 160))
    return '\n'.join(lines)


# ---------------------------------------------------------------- maps
def _render_maps(crash: CppCrashLog) -> str:
    relevant = crash.relevant_maps()
    if not relevant:
        return ''
    lines = [_title('崩溃相关maps'),
             '说明：仅保留崩溃地址所在区间与崩溃栈涉及 so 的映射行']
    lines += relevant
    return '\n'.join(lines)


# ------------------------------------------------------------ 其他线程概览
def _render_other_threads(crash: CppCrashLog) -> str:
    if not crash.other_threads:
        return ''
    lines = [_title('其他线程摘要'),
             f'共 {len(crash.other_threads)} 个其他线程；以下保留前20个线程的前3帧：']
    for thread in crash.other_threads[:20]:
        lines.append(f'Tid:{thread.tid}, Name:{thread.name}')
        lines.extend(frame.raw.rstrip('\n') for frame in thread.frames[:3])
    if len(crash.other_threads) > 20:
        lines.append(f'其余 {len(crash.other_threads) - 20} 个线程省略')
    lines.append('涉及并发、资源耗尽或线程协同时，必须回读原始Other thread info完整区段')
    return '\n'.join(lines)


# ---------------------------------------------------------------- 附件提示
def _render_attachments(crash: CppCrashLog, other_logs: List) -> str:
    lines = []
    if crash.has_hilog:
        lines.append(_title('HiLog流水日志'))
        lines.append('日志中包含 HiLog 区段，可执行 '
                     'python "<skill-root>/scripts/extract_hilog.py" <faultlog路径> 提取业务流水')
    if other_logs:
        lines.append(_title('其他未分析的cppcrash日志'))
        lines += [f'{path}' for path in other_logs]
        lines.append('当前已按故障时间选择最新日志；分析全部日志时使用main.py --all')
    return '\n'.join(lines)


def _bounded_text(value: str, max_lines: int) -> str:
    lines = value.splitlines()
    if len(lines) <= max_lines:
        return value
    omitted = len(lines) - max_lines
    return '\n'.join(lines[:max_lines] + [f'... 已省略 {omitted} 行，请回读原始日志 ...'])
