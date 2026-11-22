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
"""关键日志报告渲染：FreezeLog -> 供大模型分析的文本。

报告各小节与 SKILL.md 的分析步骤一一对应：
时间一致性校验/整机资源 -> Step 2、3；EventHandler -> Step 4；
线程堆栈 -> Step 5；binder -> Step 6、7；采样栈文件 -> Step 9。
"""

from pathlib import Path
from typing import List, Optional, Tuple

from freeze.binder import (
    Node, Propagation, PropagationChain, build_propagation, node_label)
from freeze.common import diff_seconds, fmt_time, parse_time
from freeze.faultlog import FreezeLog, FreezePart
from freeze.stack import ThreadStack

_REASON_NOTES = {
    'THREAD_BLOCK_6S': '主线程卡死超时',
    'BUSSINESS_THREAD_BLOCK_6S': '业务线程卡死超时',
    'BUSINESS_THREAD_BLOCK_6S': '业务线程卡死超时',
    'APP_INPUT_BLOCK': '用户输入处理超时',
    'LIFECYCLE_TIMEOUT': '生命周期切换超时',
    'LIFECYCLE_HALF_TIMEOUT': '生命周期切换半超时',
    'APP_HICOLLIE': '业务看门狗超时',
    'SERVICE_BLOCK': '系统服务卡死',
}

SECTION_CHOICES = (
    'full',
    'overview',
    'resources',
    'event-queue',
    'fault-stack',
    'other-threads',
    'binder',
    'attachments',
)

_SECTION_TITLES = {
    'overview': '按需分析概览',
    'resources': '整机资源状态',
    'event-queue': 'EventHandler队列状态',
    'fault-stack': '故障线程堆栈',
    'other-threads': '同进程其他线程堆栈',
    'binder': 'Binder故障传播链',
    'attachments': '附件信息',
}


def _is_business_thread_freeze(freeze: FreezeLog) -> bool:
    events = [
        freeze.reason,
        freeze.warning.event_name,
        freeze.block.event_name if freeze.block else '',
    ]
    return any(
        'BUSSINESS_THREAD_BLOCK' in event or 'BUSINESS_THREAD_BLOCK' in event
        for event in events
    )


def _fault_thread_role(freeze: FreezeLog) -> str:
    if _is_business_thread_freeze(freeze):
        return '业务线程（事件上报 TID）'
    if freeze.reason in {'THREAD_BLOCK_6S', 'APP_INPUT_BLOCK'}:
        return '主线程'
    return '事件目标线程'


def render_report(freeze: FreezeLog,
                  sample_stacks: Optional[List[Path]] = None,
                  other_faultlogs: Optional[List[Path]] = None) -> str:
    sections = [
        _render_basic(freeze),
        _render_time_check(freeze),
        _render_resources(freeze),
        _render_event_queue(freeze),
        _render_fault_stacks(freeze),
        _render_other_threads(freeze),
        _render_binder(freeze),
        _render_attachments(freeze, sample_stacks or [], other_faultlogs or []),
    ]
    return '\n'.join(section for section in sections if section)


def render_section(freeze: FreezeLog, section: str = 'full',
                   sample_stacks: Optional[List[Path]] = None,
                   other_faultlogs: Optional[List[Path]] = None) -> str:
    """按需渲染单个报告区段；full 保持原有完整报告行为。"""
    if section not in SECTION_CHOICES:
        choices = ', '.join(SECTION_CHOICES)
        raise ValueError(f'不支持的报告区段: {section}，可选值: {choices}')
    if section == 'full':
        return render_report(
            freeze,
            sample_stacks=sample_stacks,
            other_faultlogs=other_faultlogs,
        )

    samples = sample_stacks or []
    faultlogs = other_faultlogs or []
    if section == 'overview':
        return _render_overview(freeze, samples, faultlogs)

    available, _ = _section_summary(freeze, section, samples, faultlogs)
    if not available:
        return _render_missing_section(section)
    if section == 'attachments':
        return _render_attachments(freeze, samples, faultlogs)

    renderers = {
        'resources': _render_resources,
        'event-queue': _render_event_queue,
        'fault-stack': _render_fault_stacks,
        'other-threads': _render_other_threads,
        'binder': _render_binder,
    }
    renderer = renderers.get(section)
    if renderer is None:
        raise ValueError(f'报告区段未注册渲染器: {section}')
    return renderer(freeze)


def _render_overview(freeze: FreezeLog, sample_stacks: List[Path],
                     other_faultlogs: List[Path]) -> str:
    """输出区段索引和故障元数据，不展开日志正文。"""
    reason = freeze.reason
    if reason in _REASON_NOTES:
        reason = f'{reason}({_REASON_NOTES[reason]})'
    fault_time = freeze.warning.msg.fault_time or freeze.warning.msg.timestamp
    lines = [
        f'【{_SECTION_TITLES["overview"]}】',
        f'选中日志：{freeze.path}',
        f'故障类型：{reason or "未获取到"}',
        f'故障进程PID：{freeze.pid or "未获取到"}',
        f'故障线程TID：{freeze.fault_tid() or "未获取到"}',
        f'故障线程角色：{_fault_thread_role(freeze)}',
        f'故障进程：{freeze.process_name or "未获取到"}',
        f'故障时间：{fault_time or "未获取到"}',
        f'上报时间：{freeze.warning.msg.start_time or "未获取到"}',
        f'抓栈时间：{freeze.warning.stack_catch_time or "未获取到"}',
    ]
    if freeze.block:
        lines.extend([
            f'二次上报事件：{freeze.block.event_name or "未获取到"}',
            f'二次上报时间：{freeze.block.msg.start_time or "未获取到"}',
            f'二次抓栈时间：{freeze.block.stack_catch_time or "未获取到"}',
        ])
    lines.extend([
        f'Binder抓取时间：{freeze.binder.catch_time or "未获取到"}',
        f'NOTE：{freeze.header.note or "未获取到"}',
        f'FFRT目标：{_ffrt_target(freeze)}',
        '区段索引：',
    ])
    for name in SECTION_CHOICES[2:]:
        available, detail = _section_summary(
            freeze, name, sample_stacks, other_faultlogs)
        state = '有' if available else '无'
        suffix = f'（{detail}）' if detail else ''
        lines.append(f'- {name}：{state}{suffix}')
    return '\n'.join(lines)


def _ffrt_target(freeze: FreezeLog) -> str:
    if not freeze.ffrt.tid:
        return '未获取到'
    queue_name = freeze.ffrt.queue_name or '未知队列'
    task_id = freeze.ffrt.task_id or '未知任务'
    return f'队列 {queue_name}，线程 {freeze.ffrt.tid}，任务 {task_id}'


def _section_summary(freeze: FreezeLog, section: str,
                     sample_stacks: List[Path],
                     other_faultlogs: List[Path]) -> Tuple[bool, str]:
    if section == 'resources':
        return _resource_summary(freeze)
    if section == 'event-queue':
        queues = [
            part.event_queue
            for part in (freeze.warning, freeze.block)
            if part and part.event_queue
        ]
        history_count = sum(len(queue.history_events) for queue in queues)
        queued_count = sum(queue.total_count for queue in queues)
        detail = (
            f'队列 {len(queues)} 个，历史事件 {history_count} 条，'
            f'排队任务 {queued_count} 个'
        )
        return bool(queues), detail
    if section == 'fault-stack':
        stack_count = sum(bool(stack) for stack in (
            freeze.fault_stack(), freeze.block_fault_stack()))
        error_count = sum(
            len(part.stack_errors)
            for part in (freeze.warning, freeze.block)
            if part
        )
        detail = f'故障栈 {stack_count} 个，抓栈异常 {error_count} 条'
        return bool(stack_count or error_count), detail
    if section == 'other-threads':
        fault_tid = freeze.fault_tid()
        count = sum(tid != fault_tid for tid in freeze.warning.stacks)
        return bool(count), f'其他线程栈 {count} 个'
    if section == 'binder':
        binder = freeze.binder
        available = bool(
            binder.catch_time or binder.trans or binder.usage_rows or binder.peers)
        detail = (
            f'调用 {len(binder.trans)} 条，资源记录 {len(binder.usage_rows)} 条，'
            f'对端进程 {len(binder.peers)} 个'
        )
        return available, detail
    if section == 'attachments':
        detail = (
            f'采样栈 {len(sample_stacks)} 个，其他 faultlog '
            f'{len(other_faultlogs)} 个'
        )
        return bool(sample_stacks or other_faultlogs), detail
    return False, ''


def _resource_summary(freeze: FreezeLog) -> Tuple[bool, str]:
    has_cpu = bool(freeze.cpu.total_line)
    has_memory = any((
        freeze.memory.mem_total_kb,
        freeze.memory.mem_free_kb,
        freeze.memory.mem_available_kb,
        freeze.memory.reclaim_avail_buffer_kb,
    ))
    has_thermal = freeze.hot_level is not None
    sample_count = len(freeze.summary.mem_series) + len(freeze.summary.cpu_series)
    available = bool(has_cpu or has_memory or has_thermal or sample_count)
    detail = (
        f'CPU {int(has_cpu)}，内存 {int(has_memory)}，温度 {int(has_thermal)}，'
        f'资源采样 {sample_count} 条'
    )
    return available, detail


def _render_missing_section(section: str) -> str:
    return f'{_title(_SECTION_TITLES[section])}\n未获取到该区段'


def _title(name: str) -> str:
    return f'\n【{name}】'


# ---------------------------------------------------------------- 基本信息
def _render_basic(freeze: FreezeLog) -> str:
    reason = freeze.reason
    if reason in _REASON_NOTES:
        reason = f'{reason}({_REASON_NOTES[reason]})'
    lines = ['【故障基本信息】',
             f'故障类型：{reason}',
             f'故障进程pid：{freeze.pid}',
             f'故障线程tid：{freeze.fault_tid()}',
             f'故障线程角色：{_fault_thread_role(freeze)}',
             f'故障发生时间：{freeze.warning.msg.fault_time or freeze.warning.msg.timestamp}',
             f'故障包名：{freeze.header.package_name or freeze.header.module_name}',
             f'故障进程：{freeze.process_name}']
    optional = [
        ('前后台状态', {'Yes': '前台', 'No': '后台'}.get(freeze.header.foreground, '')),
        ('亮灭屏状态', freeze.header.display_power),
        ('是否预安装', {'Yes': '是', 'No': '否'}.get(freeze.header.is_pre_installed, '')),
        ('构建版本', freeze.header.build_version),
        ('应用版本', freeze.header.app_version),
        ('NOTE信息', freeze.header.note),
        ('超时任务模块', freeze.warning.msg.module_name),
        ('生命周期超时信息', freeze.lifecycle_info),
        ('故障其他信息', freeze.warning.msg.msg),
    ]
    lines += [f'{label}：{value}' for label, value in optional if value]
    if freeze.header.device_memory:
        lines.append(freeze.header.device_memory)
    if freeze.header.process_memory:
        lines.append(freeze.header.process_memory)
    if freeze.header.page_history:
        lines.append('故障前页面切换历史（业务场景线索，最近的在最上）：')
        lines += [f'  {item}' for item in freeze.header.page_history]
    if freeze.ffrt.tid:
        lines.append(f'FFRT队列阻塞：队列 {freeze.ffrt.queue_name} 的工作线程 '
                     f'{freeze.ffrt.tid} 任务 {freeze.ffrt.task_id} 执行超时，'
                     f'后续堆栈分析以该线程为准')
    lines.append(f'日志文件：{freeze.path}')
    return '\n'.join(lines)


# ---------------------------------------------------------- 时间一致性校验
def _render_time_check(freeze: FreezeLog) -> str:
    """故障时间 / 上报时间 / 抓栈时间 / 抓binder时间的差值（Step 2a 的输入）。"""
    lines = [_title('时间一致性校验'),
             '说明：上报时间差>10s 或 抓栈时间差>2s 时怀疑整机异常，维测信息可能失真']
    lines += _part_time_lines(freeze.warning)
    if freeze.block:
        lines += _part_time_lines(freeze.block)
    binder_time = freeze.binder.catch_time
    fault_time = freeze.warning.msg.fault_datetime()
    if binder_time:
        delta = diff_seconds(parse_time(binder_time), fault_time)
        delta_text = f'，与故障发生时间差 {delta}s' if delta is not None else ''
        lines.append(f'binder抓取时间：{binder_time}{delta_text}')
    else:
        lines.append('binder抓取时间：未获取到')
    return '\n'.join(lines)


def _part_time_lines(part: FreezePart) -> List[str]:
    tag = part.event_name or '本次上报'
    fault_time = part.msg.fault_datetime()
    lines = []
    if not fault_time:
        lines.append(f'{tag}：未获取到故障发生时间')
        return lines
    lines.append(f'{tag} 故障发生时间：{fmt_time(fault_time)}')
    report_delta = diff_seconds(part.msg.report_datetime(), fault_time)
    if report_delta is not None:
        lines.append(f'{tag} 上报hiview时间：{part.msg.start_time}，与故障发生时间差 {report_delta}s')
    else:
        lines.append(f'{tag} 上报hiview时间：未获取到')
    catch_delta = diff_seconds(part.stack_catch_datetime(), fault_time)
    if catch_delta is not None:
        lines.append(f'{tag} 抓栈开始时间：{part.stack_catch_time}，与故障发生时间差 {catch_delta}s')
    else:
        lines.append(f'{tag} 抓栈开始时间：未获取到')
    return lines


# -------------------------------------------------------------- 整机资源
def _render_resources(freeze: FreezeLog) -> str:
    """热等级 / CPU / 内存（Step 2b、2c、3 的输入）。"""
    lines = [_title('整机资源状态')]
    # 热等级（Step 3）：按实际等级给结论
    if freeze.hot_level is not None:
        level = freeze.hot_level
        if level > 5:
            note = '，温度过高触发热限频，故障堆栈不可信'
        elif level >= 4:
            note = '，温度偏高，需追加热限频警告'
        else:
            note = '，温度正常'
        lines.append(f'热等级：{level}{note}')
    else:
        lines.append('热等级：未获取到')
    # CPU（Step 2b）：>85% 才提示高负载
    if freeze.cpu.total_line:
        lines.append(f'CPU使用率：{freeze.cpu.total_line}')
        if freeze.cpu.total_usage > 85:
            lines.append(f'  CPU总负载 {freeze.cpu.total_usage}% 超过85%，存在整机高负载')
    else:
        lines.append('CPU使用率：未获取到')
    # 内存（Step 2c）：低于800MB才判定低内存
    avail = freeze.memory.available_mb()
    if avail > 0:
        if avail < 800:
            lines.append(f'可用内存：{avail}MB —— 低于800MB阈值，'
                         f'判定低内存导致整机资源异常，故障堆栈参考价值低')
        else:
            lines.append(f'可用内存：{avail}MB（高于800MB阈值，内存水位正常）')
    else:
        lines.append('可用内存：未获取到')
    if freeze.summary.mem_series:
        lines.append('故障前后整机可用内存采样：')
        lines += [f'  {item}' for item in freeze.summary.mem_series]
    if freeze.summary.cpu_series:
        lines.append('故障前后整机CPU使用率采样：')
        lines += [f'  {item}' for item in freeze.summary.cpu_series]
    return '\n'.join(lines)


# -------------------------------------------------------- EventHandler队列
def _render_event_queue(freeze: FreezeLog) -> str:
    lines = [_title('EventHandler队列状态')]
    rendered = False
    for part in filter(None, [freeze.warning, freeze.block]):
        if not part.event_queue:
            continue
        rendered = True
        lines += _event_queue_lines(part)
    if not rendered:
        lines.append('未获取到EventHandler dump信息')
    return '\n'.join(lines)


def _event_queue_lines(part: FreezePart) -> List[str]:
    queue = part.event_queue
    tag = part.event_name or '本次上报'
    lines = [f'-- {tag} --']
    if queue.dump_begin_line:
        lines.append(queue.dump_begin_line)
    if queue.running_line:
        lines.append(queue.running_line)
    running_seconds = queue.running_seconds()
    if running_seconds is not None:
        hint = '，已超过3s，该任务阻塞了EventHandler队列' if running_seconds > 3 else ''
        lines.append(f'当前任务已执行：{running_seconds:.1f}s{hint}')
    long_events = queue.long_history_events()
    if long_events:
        lines.append('历史队列中的耗时任务（执行≥1s）：')
        for event in long_events:
            duration = event.duration_seconds()
            lines.append(f'  task name = {event.task_name}，执行 {duration:.1f}s'
                         f'（trigger {event.trigger_time} -> complete {event.complete_time}）')
    if queue.queue_counts:
        counts = '，'.join(f'{name}: {count}' for name, count in queue.queue_counts.items())
        lines.append(f'队列堆积：{counts}，总任务数: {queue.total_count}')
    return lines


# ------------------------------------------------------------ 故障线程堆栈
def _render_fault_stacks(freeze: FreezeLog) -> str:
    lines = [_title('故障线程堆栈'),
             f'分析目标：{_fault_thread_role(freeze)} TID {freeze.fault_tid()}',
             '说明：调用方向从栈底（最大编号）到栈顶（#00），栈顶为最后调用位置']
    warning_stack = freeze.fault_stack()
    block_stack = freeze.block_fault_stack()
    if warning_stack:
        lines.append(f'{freeze.warning.event_name or "warning"} 堆栈：')
        lines.append(warning_stack.brief_str())
    else:
        lines.append(f'{freeze.warning.event_name or "warning"}：未抓到故障线程堆栈')
    if freeze.block:
        if block_stack:
            lines.append(f'{freeze.block.event_name or "block"} 堆栈：')
            lines.append(block_stack.brief_str())
        else:
            lines.append(f'{freeze.block.event_name or "block"}：未抓到故障线程堆栈')
    lines += _fault_type_stack_hint(freeze)
    for part in filter(None, [freeze.warning, freeze.block]):
        for error in part.stack_errors:
            lines.append(f'抓栈异常：{error}')
    return '\n'.join(lines)


def _fault_type_stack_hint(freeze: FreezeLog) -> List[str]:
    """提示故障类型与所抓堆栈事件不一致的情况，避免误判。"""
    reason = freeze.reason or ''
    observed = [part.event_name for part in (freeze.warning, freeze.block)
                if part and part.event_name]
    observed_text = '、'.join(observed) if observed else '未知'
    hints = []
    # 6S 冻屏但只抓到更早的 3S 现场
    if reason == 'THREAD_BLOCK_6S' and not any(e == 'THREAD_BLOCK_6S' for e in observed):
        hints.append(
            f'堆栈完整性提示：故障类型为 THREAD_BLOCK_6S，但日志中未抓到 THREAD_BLOCK_6S 堆栈；'
            f'当前仅包含 {observed_text} 堆栈，请按早期抓栈现场分析，6S 时刻可能抓栈失败或日志被裁剪')
    # APP_INPUT_BLOCK 故障却采集了 THREAD_BLOCK 堆栈，避免误判为 THREAD_BLOCK_6S
    if reason == 'APP_INPUT_BLOCK' and any('THREAD_BLOCK' in e for e in observed):
        tb = '、'.join(e for e in observed if 'THREAD_BLOCK' in e)
        hints.append(
            f'故障类型提示：本故障为 APP_INPUT_BLOCK（用户输入处理超时）；'
            f'日志中虽采集了 {tb} 堆栈，但故障类型以头部 Reason=APP_INPUT_BLOCK 为准，'
            f'请勿误判为 THREAD_BLOCK_6S')
    return hints


# ---------------------------------------------------------- 其他线程堆栈
def _render_other_threads(freeze: FreezeLog) -> str:
    fault_tid = freeze.fault_tid()
    others = [stack for tid, stack in freeze.warning.stacks.items() if tid != fault_tid]
    lines = [_title('同进程其他线程堆栈'),
             '用途：故障线程等锁时，在这里寻找持有相同so且调用更深的持锁线程']
    if not others:
        lines.append('未抓到其他线程堆栈')
        return '\n'.join(lines)
    for stack in others:
        lines.append(stack.brief_str())
    return '\n'.join(lines)


# ---------------------------------------------------------------- binder
def _render_binder(freeze: FreezeLog) -> str:
    """仅输出故障线程/故障进程相关的 binder 传播链，不列全量同步调用记录。"""
    names = freeze.process_names
    tnames = _thread_names(freeze)
    prop = build_propagation(freeze.binder, freeze.pid, freeze.fault_tid())
    return '\n'.join(_propagation_lines(freeze, prop, names, tnames))


def _thread_names(freeze: FreezeLog) -> dict:
    """汇总 {(pid, tid): 线程名}：故障进程主堆栈 + binder 对端堆栈。"""
    names = {}
    items = list(freeze.warning.stacks.items())
    if freeze.block:
        items += list(freeze.block.stacks.items())
    for tid, stack in items:
        if stack.name:
            names[(freeze.pid, tid)] = stack.name
    for pid, peer in freeze.binder.peers.items():
        for tid, stack in peer.stacks.items():
            if stack.name:
                names[(pid, tid)] = stack.name
    return names


def _edge_line(edge, names: dict, tnames: dict) -> str:
    """一条 binder 调用边，两端都标进程名/线程名。"""
    src = node_label((edge.src_pid, edge.src_tid), names, tnames)
    dst = node_label((edge.dst_pid, edge.dst_tid), names, tnames)
    suffix = f' frz_state:{edge.frz_state}' if edge.frz_state else ''
    return f'{src} -> {dst} wait {edge.wait_seconds:.2f}s{suffix}'


def _propagation_lines(freeze: FreezeLog, prop: Propagation,
                       names: dict, tnames: dict) -> List[str]:
    """渲染故障传播链：只保留故障线程/故障进程相关的链。"""
    lines = [_title('Binder故障传播链')]
    if not (prop.fault_in_graph and prop.chain):
        lines += [f'提示：{note}' for note in prop.notes]
        return lines

    up, down = set(prop.upstream), set(prop.downstream)
    lines.append(f'锚点故障线程：{node_label(prop.fault_node, names, tnames)}')
    other_anchor = [n for n in prop.anchor if n != prop.fault_node]
    if other_anchor:
        lines.append('故障进程其他binder线程：'
                     + '、'.join(node_label(n, names, tnames) for n in other_anchor))
    lines.append(f'传播链涉及 {len(prop.chain.nodes)} 个线程、'
                 f'{len(prop.chain.edges)} 条binder调用')
    lines.append(_node_list_line('上游线程（直接或间接等待故障进程，被其连累）',
                                 prop.upstream, names, tnames))
    lines.append(_node_list_line('下游线程（故障进程直接或间接在等待，含最终阻塞点）',
                                 prop.downstream, names, tnames))
    lines.append('传播链调用边（按等待时长降序）：')
    for edge in prop.chain.edges:
        lines.append(f'  {_edge_line(edge, names, tnames)}')
    lines += _cycle_lines(prop.chain, names, tnames)
    lines += [f'提示：{note}' for note in prop.notes]
    lines += _chain_process_stack_lines(freeze, prop, names, tnames)
    return lines


def _chain_process_stack_lines(freeze: FreezeLog, prop: Propagation,
                               names: dict, tnames: dict) -> List[str]:
    """按进程展开传播链堆栈：对端（上下游）进程取出全部线程，而非只取端点线程。"""
    lines = ['—— 传播链各进程堆栈（对端进程展开全部线程，★为binder端点线程）——']
    up, down = set(prop.upstream), set(prop.downstream)
    fault_pid = freeze.pid
    chain_nodes = [prop.fault_node] + prop.chain.nodes
    # 按进程分组，保留出现顺序
    pids = []
    for node in chain_nodes:
        if node[0] not in pids:
            pids.append(node[0])
    for pid in pids:
        role = _process_role(pid, fault_pid, up, down)
        pname = names.get(pid, '')
        head = f'[{role} {pid}{f"({pname})" if pname else ""}]'
        endpoint_tids = {n[1] for n in chain_nodes if n[0] == pid}
        if pid == fault_pid:
            # 故障进程：列出 binder 端点线程（去重），其余线程见专门小节，避免重复
            lines.append(f'{head} binder端点线程：')
            seen = set()
            for node in [n for n in chain_nodes if n[0] == fault_pid]:
                if node in seen:
                    continue
                seen.add(node)
                lines += _node_stack_lines(
                    freeze, node, _node_role(node, prop.fault_node, up, down), names, tnames)
            lines.append('  （故障进程其余线程堆栈见【同进程其他线程堆栈】小节）')
            continue
        peer = freeze.binder.peers.get(pid)
        if not peer or not peer.stacks:
            lines.append(f'{head} 全部线程：未抓到该进程堆栈（日志未dump该进程）')
            continue
        lines.append(f'{head} 全部线程堆栈（共 {len(peer.stacks)} 个）：')
        for tid, stack in peer.stacks.items():
            tags = []
            if tid in endpoint_tids:
                tags.append('binder端点★')
            if stack.is_lock_waiting():
                tags.append('栈顶等锁')
            if tags:
                lines.append(f'  [{"/".join(tags)}]')
            lines.append(stack.brief_str())
        for error in peer.stack_errors:
            lines.append(f'  抓栈异常：{error}')
    return lines


def _node_role(node: Node, fault: Node, up: set, down: set) -> str:
    if node == fault:
        return '故障线程'
    if node[0] == fault[0]:
        return '故障进程线程'
    if node in up and node in down:
        return '上下游(环内)'
    if node in up:
        return '上游'
    if node in down:
        return '下游'
    return '链内'


def _process_role(pid: str, fault_pid: str, up: set, down: set) -> str:
    if pid == fault_pid:
        return '故障进程'
    in_up = any(node[0] == pid for node in up)
    in_down = any(node[0] == pid for node in down)
    if in_up and in_down:
        return '上下游进程(环内)'
    if in_up:
        return '上游进程'
    if in_down:
        return '下游进程'
    return '链内进程'


def _node_list_line(title: str, nodes: List[Node], names: dict, tnames: dict) -> str:
    if not nodes:
        return f'{title}：无'
    return f'{title}（{len(nodes)}个）：' + '、'.join(
        node_label(n, names, tnames) for n in nodes)


def _cycle_lines(chain: PropagationChain, names: dict, tnames: dict) -> List[str]:
    lines = []
    for cycle in chain.cycles:
        path = ' -> '.join(node_label(node, names, tnames) for node in cycle + [cycle[0]])
        lines.append(f'⚠ 检测到binder死锁环：{path}')
    return lines


def _node_stack_lines(freeze: FreezeLog, node: Node, role: str,
                      names: dict, tnames: dict) -> List[str]:
    """取出单个线程的堆栈（传播链按线程逐个展开）。"""
    label = node_label(node, names, tnames)
    stack = _resolve_stack(freeze, node)
    if not stack:
        return [f'[{role} {label}] 未抓到该线程堆栈']
    lines = [f'[{role} {label}]']
    if stack.is_lock_waiting():
        lines.append('  （栈顶呈等锁特征，需在同进程其他线程中找持锁方）')
    lines.append(stack.brief_str())
    return lines


def _resolve_stack(freeze: FreezeLog, node: Node) -> Optional[ThreadStack]:
    """按 (pid, tid) 定位线程堆栈：故障进程取主堆栈，其余取 binder 对端堆栈。"""
    pid, tid = node
    if pid == freeze.pid:
        return freeze.warning.stacks.get(tid) or (
            freeze.block.stacks.get(tid) if freeze.block else None)
    peer = freeze.binder.peers.get(pid)
    return peer.stacks.get(tid) if peer else None


# ---------------------------------------------------------------- 附件提示
def _render_attachments(freeze: FreezeLog, sample_stacks: List[Path],
                        other_faultlogs: List[Path]) -> str:
    lines = []
    if sample_stacks:
        lines.append(_title('采样栈文件'))
        for path in sample_stacks:
            lines.append(f'检测到采样栈文件：{path}')
        lines.append('采样来源可能就是当前 faultlog：内嵌 Snapshot 时直接传入完整原文件，无需手动拆分。')
        lines.append('请执行 python "scripts/sample_stack_analyzer.py" "<采样栈文件路径>" '
                     '分析热点函数；脚本自动发现配套 appfreeze/sysfreeze，'
                     '先关联事件并对齐符号，再聚类分析，无需额外命令或参数')
    if other_faultlogs:
        lines.append(_title('其他未分析的faultlog'))
        lines += [f'{path}' for path in other_faultlogs]
        lines.append('如需分析请单独指定文件路径重新运行')
    return '\n'.join(lines)
