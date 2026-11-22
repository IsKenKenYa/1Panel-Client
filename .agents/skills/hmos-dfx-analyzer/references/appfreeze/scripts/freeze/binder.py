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
"""binder 区段解析与故障传播链构建。

faultlog 的 binder 区段包含三部分：
1. BinderCatcher    —— 进行中的 binder 通信记录（src -> dst, 等待时长）
2. binder 资源表    —— 各进程 binder 线程使用情况（用于判断 IPC FULL）
3. PeerBinder Stacktrace —— 对端进程的线程堆栈

把每条同步 binder 通信看作一条有向边 (src_pid:src_tid) -> (dst_pid:dst_tid)，
所有边构成一张有向图。build_propagation 从故障线程出发做双向遍历：
- 下游：故障线程在等谁（沿 src->dst 前进）；
- 上游：谁在等故障线程（沿 dst->src 回溯）；
取出故障线程所在连通分量的全部线程，形成"故障传播链"，并检测其中的死锁环。
故障线程未直连 binder 图时，其余通信链各自成链单独输出（other_chains）。
"""

import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

from freeze.common import find_section
from freeze.stack import ThreadStack, extract_stack_errors, parse_thread_stacks

# '20020:20020 to 1234:5678 code 5f475352 wait:6.5 s frz_state:3,'
_TRANS_RE = re.compile(
    r'(?P<src_pid>\d+):(?P<src_tid>\d+) to (?P<dst_pid>\d+):(?P<dst_tid>\d+) '
    r'code (?P<code>\S+) wait:(?P<wait>[\d.]+) s(?: frz_state:(?P<frz_state>\d+))?')
# binder 资源表表头与行
_USAGE_HEADER_RE = re.compile(r'pid\s+context\s+request\s+started\s+max\s+ready\s+free_async_space')
_USAGE_ROW_RE = re.compile(
    r'(?P<pid>\d+)\s+\w+\s+(?P<request>\d+)\s+(?P<started>\d+)\s+'
    r'(?P<max>\d+)\s+(?P<ready>\d+)\s+(?P<free_async_space>\d+)')
# 对端堆栈起始：'PeerBinder catcher stacktrace for pid : 1234'
_PEER_STACK_RE = re.compile(
    r'(?:catcher stacktrace for |Binder catcher stacktrace, type is \w+, )pid : (?P<pid>\d+)')


@dataclass
class BinderTrans:
    """一条 binder 通信记录。"""
    src_pid: str = ''
    src_tid: str = ''
    dst_pid: str = ''
    dst_tid: str = ''
    code: str = ''
    wait_seconds: float = 0.0
    frz_state: str = ''
    is_async: bool = False
    raw: str = ''

    def describe(self, process_names: Dict[str, str] = None) -> str:
        names = process_names or {}
        src_name = names.get(self.src_pid, '')
        dst_name = names.get(self.dst_pid, '')
        src = f'{self.src_pid}:{self.src_tid}' + (f'({src_name})' if src_name else '')
        dst = f'{self.dst_pid}:{self.dst_tid}' + (f'({dst_name})' if dst_name else '')
        suffix = f' frz_state:{self.frz_state}' if self.frz_state else ''
        return f'{src} -> {dst} wait {self.wait_seconds:.2f}s{suffix}'


@dataclass
class PeerProcess:
    """一个对端进程的堆栈信息。"""
    pid: str = ''
    process_name: str = ''
    stacks: Dict[str, ThreadStack] = field(default_factory=dict)
    stack_errors: List[str] = field(default_factory=list)


@dataclass
class BinderInfo:
    """binder 区段的全部信息。"""
    catch_time: str = ''
    trans: List[BinderTrans] = field(default_factory=list)
    usage_rows: Dict[str, dict] = field(default_factory=dict)   # {pid: 资源表行字段}
    peers: Dict[str, PeerProcess] = field(default_factory=dict)  # {pid: PeerProcess}

    def sync_trans(self) -> List[BinderTrans]:
        return [trans for trans in self.trans if not trans.is_async]

    def is_peer_ipc_full(self, pid: str) -> bool:
        """对端 binder 线程耗尽：ready 为 0（IPC FULL）。"""
        row = self.usage_rows.get(pid)
        return bool(row) and row.get('ready') == '0'


Node = Tuple[str, str]   # (pid, tid)


def node_label(node: Node, process_names: Dict[str, str],
               thread_names: Dict[Node, str] = None) -> str:
    """把 (pid, tid) 渲染成 'pid:tid(进程名/线程名)'。"""
    pid, tid = node
    process_name = process_names.get(pid, '')
    thread_name = (thread_names or {}).get(node, '')
    # 主线程名常等于进程名，相同时只显示一个
    parts = []
    for part in (process_name, thread_name):
        if part and part not in parts:
            parts.append(part)
    inner = '/'.join(parts)
    base = f'{pid}:{tid}'
    if inner:
        base += f'({inner})'
    if tid == '0':
        base += '(binder线程耗尽,IPC FULL)'
    return base


@dataclass
class PropagationChain:
    """一条 binder 传播链：一个弱连通分量内的全部线程与调用边。"""
    edges: List[BinderTrans] = field(default_factory=list)
    nodes: List[Node] = field(default_factory=list)
    cycles: List[List[Node]] = field(default_factory=list)   # 死锁环

    @property
    def has_deadlock(self) -> bool:
        return bool(self.cycles)

    def max_wait(self) -> float:
        return max((edge.wait_seconds for edge in self.edges), default=0.0)


@dataclass
class Propagation:
    """以故障线程/故障进程为锚点的传播分析结果。"""
    fault_node: Node
    anchor: List[Node] = field(default_factory=list)      # 故障线程 + 故障进程的binder线程
    fault_in_graph: bool = False
    chain: Optional[PropagationChain] = None      # 故障进程所在的传播链
    upstream: List[Node] = field(default_factory=list)    # 谁在等故障进程（传递）
    downstream: List[Node] = field(default_factory=list)  # 故障进程在等谁（传递）
    notes: List[str] = field(default_factory=list)


def parse_binder(lines: List[str]) -> BinderInfo:
    """解析 binder 区段（BinderCatcher 起，对端堆栈 end time 止）。"""
    info = BinderInfo()
    # 用 (?<!Peer) 避免被 'PeerBinderCatcher --' 行抢先匹配
    section, start_index = find_section(
        lines, r'(?<!Peer)BinderCatcher --', r'end time:|^-{5,}\s*$', include_start=True)
    if not section:
        return info
    time_match = re.search(r'BinderCatcher -- start time:\s*(.*)', section[0])
    if time_match:
        info.catch_time = time_match.group(1).strip()
    peer_start = len(section)
    for index, line in enumerate(section):
        if 'PeerBinder Stacktrace' in line or _PEER_STACK_RE.search(line):
            peer_start = index
            break
        trans_match = _TRANS_RE.search(line)
        if trans_match:
            info.trans.append(BinderTrans(
                src_pid=trans_match.group('src_pid'), src_tid=trans_match.group('src_tid'),
                dst_pid=trans_match.group('dst_pid'), dst_tid=trans_match.group('dst_tid'),
                code=trans_match.group('code'),
                wait_seconds=float(trans_match.group('wait')),
                frz_state=trans_match.group('frz_state') or '',
                is_async=line.lstrip().startswith('async'),
                raw=line.strip()))
            continue
        usage_match = _USAGE_ROW_RE.search(line)
        if usage_match and not _USAGE_HEADER_RE.search(line):
            info.usage_rows[usage_match.group('pid')] = usage_match.groupdict()
    _parse_peer_stacks(section[peer_start:], info)
    return info


def _parse_peer_stacks(lines: List[str], info: BinderInfo):
    """把对端堆栈按 'catcher stacktrace for pid : N' 拆分到各进程。"""
    starts = []  # [(行下标, pid)]
    for index, line in enumerate(lines):
        match = _PEER_STACK_RE.search(line)
        if match:
            starts.append((index, match.group('pid')))
    for order, (start, pid) in enumerate(starts):
        end = starts[order + 1][0] if order + 1 < len(starts) else len(lines)
        chunk = lines[start:end]
        peer = PeerProcess(pid=pid,
                           stacks=parse_thread_stacks(chunk),
                           stack_errors=extract_stack_errors(chunk))
        name_match = re.search(r'Process name:(.*)', ''.join(chunk))
        if name_match:
            peer.process_name = name_match.group(1).strip()
        info.peers[pid] = peer


def _src_node(trans: BinderTrans) -> Node:
    return trans.src_pid, trans.src_tid


def _dst_node(trans: BinderTrans) -> Node:
    return trans.dst_pid, trans.dst_tid


def _matches_src(trans: BinderTrans, node: Node) -> bool:
    """匹配调用方；tid 为 0 的节点表示该进程全部 binder 工作线程。"""
    if trans.src_pid != node[0]:
        return False
    return trans.src_tid == node[1] or node[1] == '0'


def _matches_dst(trans: BinderTrans, node: Node) -> bool:
    """trans 的对端是否落在 node 上；dst_tid 为 0（IPC FULL）时按进程匹配。"""
    if trans.dst_pid != node[0]:
        return False
    return trans.dst_tid == node[1] or trans.dst_tid == '0'


def _record_actual_source(trans: BinderTrans, current: Node,
                          visited: set, reached: List[Node]):
    actual_src = _src_node(trans)
    if actual_src == current or actual_src in visited:
        return
    visited.add(actual_src)
    reached.append(actual_src)


def _next_node(trans: BinderTrans, current: Node, forward: bool) -> Optional[Node]:
    if forward:
        if _matches_src(trans, current):
            return _dst_node(trans)
        return None
    if _matches_dst(trans, current):
        return _src_node(trans)
    return None


def build_propagation(binder: BinderInfo, fault_pid: str, fault_tid: str) -> Propagation:
    """以故障线程及故障进程为锚点，构建故障传播链（上游+下游+传递闭包）。

    锚点 = 故障线程 + 故障进程在 binder 中出现的所有线程；只保留与该锚点
    连通的调用链，与故障进程无关的其他通信链不纳入。
    """
    fault_node: Node = (fault_pid, fault_tid)
    sync = binder.sync_trans()
    prop = Propagation(fault_node=fault_node)

    anchor = [fault_node]
    for trans in sync:
        for node in (_src_node(trans), _dst_node(trans)):
            if node[0] == fault_pid and node not in anchor:
                anchor.append(node)
    prop.anchor = anchor

    downstream_edges, prop.downstream = _walk(sync, anchor, forward=True)
    upstream_edges, prop.upstream = _walk(sync, anchor, forward=False)
    chain_edges = _dedup_edges(downstream_edges + upstream_edges)

    if chain_edges:
        prop.fault_in_graph = True
        prop.chain = PropagationChain(
            edges=_sort_edges(chain_edges), nodes=_collect_nodes(chain_edges),
            cycles=_find_cycles(chain_edges))
        if any(edge.dst_tid == '0' for edge in chain_edges):
            prop.notes.append('传播链中存在对端tid为0的调用，对应进程binder线程耗尽（IPC FULL）')
    else:
        prop.notes.append('故障进程未参与binder同步通信，故障线程未阻塞在IPC上')
    return prop


def _walk(sync: List[BinderTrans], starts: List[Node], forward: bool):
    """从 starts 单向遍历；tid=0 作为进程 binder 工作线程通配节点。"""
    visited = set(starts)
    stack = list(starts)
    edges: List[BinderTrans] = []
    reached: List[Node] = []
    while stack:
        node = stack.pop()
        for trans in sync:
            nxt = _next_node(trans, node, forward)
            if nxt is None:
                continue
            if forward:
                _record_actual_source(trans, node, visited, reached)
            if trans not in edges:
                edges.append(trans)
            if nxt not in visited:
                visited.add(nxt)
                reached.append(nxt)
                stack.append(nxt)
    return edges, reached


def _find_cycles(edges: List[BinderTrans]) -> List[List[Node]]:
    """在有向边集合中找环（DFS 回边），用于判定 binder 死锁。"""
    adjacency: Dict[Node, List[Node]] = {}
    for edge in edges:
        adjacency.setdefault(_src_node(edge), []).append(_dst_node(edge))
    cycles: List[List[Node]] = []
    seen_signatures = set()

    def dfs(node: Node, path: List[Node], on_path: set):
        for nxt in adjacency.get(node, []):
            if nxt in on_path:
                cycle = path[path.index(nxt):]
                signature = frozenset(cycle)
                if signature not in seen_signatures:
                    seen_signatures.add(signature)
                    cycles.append(cycle)
                continue
            dfs(nxt, path + [nxt], on_path | {nxt})

    for start in list(adjacency):
        dfs(start, [start], {start})
    return cycles


def _collect_nodes(edges: List[BinderTrans]) -> List[Node]:
    nodes: List[Node] = []
    for edge in edges:
        for node in (_src_node(edge), _dst_node(edge)):
            if node not in nodes:
                nodes.append(node)
    return nodes


def _sort_edges(edges: List[BinderTrans]) -> List[BinderTrans]:
    return sorted(edges, key=lambda edge: edge.wait_seconds, reverse=True)


def _dedup_edges(edges: List[BinderTrans]) -> List[BinderTrans]:
    result: List[BinderTrans] = []
    for edge in edges:
        if edge not in result:
            result.append(edge)
    return result
