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
import re
from collections import defaultdict
from copy import deepcopy

from typing import List, Dict

from log_manager.common.handler.format_unit_handler import FormatUnitHandler

low_priority_process = [
    'surfaceflinger',
    'composer@2.1-se', 'anco_service_br', 'render_service', 'composer_host', 'mhcserver',
    'CameraDaemon', 'hiaiserver', 'av_codec_servic', 'media_service', 'codec_host', 'allocator_host',
    'mediaswcodec', 'media_analysis_', 'app.hiai.vision', 'camera_service', 'large_model_eng',
    'video_processin', 'mhcserv', 'CameraDaemon', 'face_auth_host',
    'stat', 'sh', 'ping', 'mount', 'process_dump', 'pm', 'getprop', 'wm', 'cmd', 'cat', 'am'
]
priority_dict = {
    'surfaceflinger': ['surfaceflinger', 'composer@2.1-se', 'anco_service_br', 'render_service', 'composer_host',
                       'mhcserver', 'allocator_host'],
    'CameraDaemon1': ['CameraDaemon', 'face_auth_host', 'hiaiserver', 'allocator_host'],
    'av_codec_servic1': ['av_codec_servic', 'media_service', 'render_service', 'allocator_host'],
    'codec_host': ['codec_host', 'allocator_host'],
    'mediaswcodec': ['mediaswcodec', 'allocator_host'],
    'CameraDaemon2': ['CameraDaemon', 'camera_service', 'av_codec_servic', 'render_service', 'allocator_host'],
    'large_model_eng': ['large_model_eng', 'hiaiserver', 'allocator_host'],
    'av_codec_servic2': ['av_codec_servic', 'media_analysis_', 'app.hiai.vision', 'video_processin', 'mhcserver',
                         'hiaiserver', 'allocator_host'],
    'CameraDaemon3': ['CameraDaemon', 'face_auth_host', 'allocator_host'],
}
buf_type_set = {
    'xcomponent', 'pixelmap', 'web', 'last_buffer', 'hpae_memory_hdrhetero',
    'asynscaling_hpae_memory', 'asynscaling_hape_memory'
}
special_leak_type_aliases = {
    'hpae_memory_hdrhetero': 'hpae_memory_hdrhetero',
    'asynscaling_hpae_memory': 'asynscaling_hpae_memory',
    'asynscaling_hape_memory': 'asynscaling_hpae_memory',
}


class ProcessAshmemOverviewInfo:

    def __init__(self):
        self.process_name = ''
        self.virtual_size = 0
        self.physical_size = 0

    def build(self):
        pass


class ProcessAshmemDetailInfo:

    def __init__(self):
        self.process_name = ''
        self.pid = ''
        self.fd = ''
        self.cnode_index = ''
        self.applicant_pid = ''
        self.ashmem_name = ''
        self.handle_name = ''
        self.virtual_size = ''
        self.physical_size = ''
        self.magic = ''

    def build(self):
        pass


class DmaHeap:
    def __init__(self):
        self.source_format = ''
        # Keep the parsed row immutable for raw-reference accounting.  The
        # canonical, inode-level record may later choose a different size when
        # duplicate references disagree.
        self.raw_size = ''
        self.metadata_conflicts = {}
        self.unique_key = ''
        self.process_name = ''
        self.pid = ''
        self.fd = ''
        self.size = ''
        self.magic = ''
        self.exp_pid = ''
        self.exp_task_comm = ''
        self.buf_to_pid = ''
        self.buf_to_task_comm = ''
        self.buf_name = ''
        self.exp_name = ''
        self.buf_type = ''
        self.leak_type = ''
        self.can_reclaim = ''
        self.is_reclaim = ''

    def build(self):
        pass


class DmaHeapInfo:
    def __init__(self):
        self.dma_heap_list: List[DmaHeap] = []
        self.process_to_total_ion = dict()
        self.ion_to_process_dict: Dict[str, DmaHeap] = dict()
        self.magic_to_dma_heap: Dict[str, DmaHeap] = dict()
        self.magic_dma_dict: Dict[str, List[DmaHeap]] = defaultdict(list)
        self.pid_dma_dict: Dict[str, List[DmaHeap]] = defaultdict(list)
        self.pid_magic_dict: Dict[str, Dict[str, DmaHeap]] = defaultdict(dict)
        self.pid_to_dma_in_ddr = {}
        self.pid_to_dma_in_ufs = {}
        self.pid_to_dma_unknown = {}
        self.pid_to_dma_private = {}
        self.pid_to_dma_shared = {}
        self.dma_in_ddr_type_dict = {}
        self.pid_names = {}
        self.magic_to_pids = {}
        self.reference_to_heap = {}
        self.magic_to_owners = {}
        self.pid_owned_magic_dict = defaultdict(dict)
        self.pid_owned_magic_size = defaultdict(dict)
        self.warnings = []
        self.invalid_row_count = 0

    @staticmethod
    def add_to_dict(dictionary, key, value):
        if key in dictionary:
            dictionary[key] += value
        else:
            dictionary[key] = value

    @staticmethod
    def dma_heap_tables_build(context: List[str]):
        new_pattern, legacy_pattern = DmaHeapInfo._header_patterns()
        tables = []
        for start_index, line in enumerate(context):
            is_new_format = bool(new_pattern.search(line))
            if not is_new_format and not legacy_pattern.search(line):
                continue
            members, delimiter = DmaHeapInfo._parse_dma_header(line, is_new_format)
            field_map, source_format = DmaHeapInfo._dma_field_map(is_new_format)
            member_index_dict = {
                field_map[member.strip().lower()]: index
                for index, member in enumerate(members)
                if member.strip().lower() in field_map
            }
            tables.append((member_index_dict, start_index, delimiter, source_format))
        return tables

    @staticmethod
    def _split_dma_row(line: str, delimiter: str):
        if delimiter == 'tab':
            return line.rstrip('\r\n').split('\t')
        if delimiter == 'double-space':
            return re.split(r'\s{2,}', line.strip())
        return line.strip().split()

    @staticmethod
    def _is_missing_metadata(value):
        return str(value).strip().lower() in {'', 'null', 'none', 'n/a', '-'}

    @staticmethod
    def _reclaim_state(value: str):
        normalized = str(value).strip().lower()
        if normalized in {'1', 'true', 'yes'}:
            return 'reclaim'
        if normalized in {'0', 'false', 'no'}:
            return 'ddr'
        return 'unknown'

    @staticmethod
    def _header_patterns():
        new_pattern = re.compile(
            r'^\s*Process\s+pid\s+fd\s+size_bytes\s+ino(?:\s|$)', re.IGNORECASE
        )
        legacy_pattern = re.compile(
            r'^\s*Process\s+name\s+Process\s+ID\s+fd\s+size\s+magic(?:\s|$)', re.IGNORECASE
        )
        return new_pattern, legacy_pattern

    @staticmethod
    def _parse_dma_header(line: str, is_new_format: bool):
        header = line.rstrip('\r\n')
        if '\t' in header:
            return header.split('\t'), 'tab'
        if is_new_format:
            return header.split(), 'whitespace'
        return re.split(r'\s{2,}', header.strip()), 'double-space'

    @staticmethod
    def _dma_field_map(is_new_format: bool):
        if is_new_format:
            return {
                'process': 'process_name', 'pid': 'pid', 'fd': 'fd',
                'size_bytes': 'size', 'ino': 'magic', 'exp_pid': 'exp_pid',
                'exp_task_comm': 'exp_task_comm', 'buf_name': 'buf_name',
                'exp_name': 'exp_name', 'buf_type': 'buf_type',
                'can_reclaim': 'can_reclaim', 'is_reclaim': 'is_reclaim',
                'leak_type': 'leak_type',
            }, '6.x'
        return {
            'process name': 'process_name', 'process id': 'pid', 'fd': 'fd',
            'size': 'size', 'magic': 'magic', 'buf->pid': 'buf_to_pid',
            'buf->task_comm': 'buf_to_task_comm',
        }, '5.x'

    @staticmethod
    def _is_dma_table_boundary(line: str) -> bool:
        if re.search(r'^\s*(?:\*{5,}|-{5,})', line):
            return True
        new_pattern, legacy_pattern = DmaHeapInfo._header_patterns()
        return bool(new_pattern.search(line) or legacy_pattern.search(line))

    @classmethod
    def dma_heap_index_build(cls, context: List[str]):
        """Return the last table for callers of the historical helper API."""
        tables = cls.dma_heap_tables_build(context)
        if not tables:
            return {}, -1, ''
        member_index_dict, start_index, delimiter, _ = tables[-1]
        return member_index_dict, start_index, delimiter

    def build(self, context: List[str]):
        # A parser instance may be reused by callers or loaded from a pickle.
        # Reinitialize all derived collections before each build.
        self.__init__()
        self.dma_build(context)
        self.ion_deduplicate()

    def dma_build(self, context: List[str]):
        tables = self.dma_heap_tables_build(context)
        if not tables:
            return
        preferred_format = '6.x' if any(table[3] == '6.x' for table in tables) else '5.x'
        preferred_tables = [table for table in tables if table[3] == preferred_format]
        if any(table[3] != preferred_format for table in tables):
            self._add_warning(
                '日志同时包含5.x与6.x DMA表；对象明细采用字段更完整的6.x表，'
                '物理总量以系统MemInfo为准。'
            )
        if len(preferred_tables) > 1:
            self._add_warning(
                f'日志包含{len(preferred_tables)}个{preferred_format} DMA表；'
                '对象明细采用最后一个表，避免跨快照重复累计。'
            )

        member_index_dict, start_index, delimiter, source_format = preferred_tables[-1]
        required_members = {'process_name', 'pid', 'fd', 'size', 'magic'}
        missing_members = required_members - set(member_index_dict)
        if missing_members:
            self._add_warning(
                f'{source_format} DMA表头缺少必要字段: {", ".join(sorted(missing_members))}'
            )
            return
        self.dma_buf_list_build(
            start_index, member_index_dict, delimiter, source_format, context
        )
        self._report_metadata_conflicts()

    def dma_buf_list_build(
            self,
            start_index: int,
            member_index_dict: Dict[str, int],
            delimiter: str,
            source_format: str,
            context: List[str]):
        required_column_count = max(member_index_dict.values()) + 1
        for line in context[start_index + 1:]:
            if self._is_dma_table_boundary(line):
                break
            if not line.strip():
                continue
            member_list = self._split_dma_row(line, delimiter)
            if member_list and member_list[0].strip().lower() == 'total':
                continue
            if len(member_list) < required_column_count:
                self.invalid_row_count += 1
                self._add_warning(
                    f'DMA数据列不足，已跳过: 需要{required_column_count}列，实际{len(member_list)}列'
                )
                continue
            dma_heap = self._parse_dma_heap(member_list, member_index_dict, source_format)
            if dma_heap:
                self._store_dma_heap(dma_heap)

    def dma_heap_list_build(self, context: List[str]):
        """Backward-compatible entry point for the unified 5.x/6.x parser."""
        self.dma_build(context)

    def ion_deduplicate(self):
        for magic, heap in self.magic_to_dma_heap.items():
            owners = self._select_owners(heap)
            if not owners:
                self._add_warning(f'DMA buffer {magic} 无法确定归属进程。')
                continue
            owners = sorted(set(owners), key=lambda pid: (int(pid) if pid.isdigit() else 0, pid))
            self.magic_to_owners[magic] = owners
            size = int(heap.size) if heap.size else 0
            quotient, remainder = divmod(size, len(owners))
            reclaim_state = self._reclaim_state(heap.is_reclaim)
            buf_type = special_leak_type_aliases.get(heap.buf_type, heap.buf_type)
            if buf_type not in buf_type_set:
                buf_type = 'NULL'

            for index, pid in enumerate(owners):
                allocated_size = quotient + (1 if index < remainder else 0)
                self.pid_owned_magic_dict[pid][magic] = heap
                self.pid_owned_magic_size[pid][magic] = allocated_size
                if len(self.magic_to_pids.get(magic, [])) == 1:
                    self.add_to_dict(self.pid_to_dma_private, pid, allocated_size)
                else:
                    self.add_to_dict(self.pid_to_dma_shared, pid, allocated_size)

                if reclaim_state == 'reclaim':
                    self.add_to_dict(self.pid_to_dma_in_ufs, pid, allocated_size)
                elif reclaim_state == 'ddr':
                    self.add_to_dict(self.pid_to_dma_in_ddr, pid, allocated_size)
                    if pid not in self.dma_in_ddr_type_dict:
                        self.dma_in_ddr_type_dict[pid] = {}
                    self.add_to_dict(self.dma_in_ddr_type_dict[pid], buf_type, allocated_size)
                else:
                    self.add_to_dict(self.pid_to_dma_unknown, pid, allocated_size)

    def _add_warning(self, warning: str):
        if warning in self.warnings:
            return
        if len(self.warnings) < 20:
            self.warnings.append(warning)
        elif len(self.warnings) == 20:
            self.warnings.append('其余DMA行解析告警已省略。')

    def _parse_dma_heap(self, member_list, member_index_dict, source_format):
        dma_heap = DmaHeap()
        dma_heap.source_format = source_format
        for member, index in member_index_dict.items():
            member_value = member_list[index].strip()
            if member == 'buf_type' and not member_value:
                member_value = 'NULL'
            setattr(dma_heap, member, member_value)
        special_type = special_leak_type_aliases.get(dma_heap.leak_type.lower())
        if special_type:
            dma_heap.buf_type = special_type
        try:
            size = int(dma_heap.size)
            if size < 0:
                raise ValueError
        except (TypeError, ValueError):
            self.invalid_row_count += 1
            self._add_warning(f'DMA size_bytes非法，已跳过: {dma_heap.size!r}')
            return None
        dma_heap.raw_size = str(size)
        if not dma_heap.pid or not dma_heap.magic:
            self.invalid_row_count += 1
            self._add_warning('DMA数据缺少pid或ino/magic，已跳过。')
            return None
        return dma_heap

    def _store_dma_heap(self, dma_heap: DmaHeap):
        reference_key = (dma_heap.pid, dma_heap.fd, dma_heap.magic)
        existing_reference = self.reference_to_heap.get(reference_key)
        if existing_reference:
            self._merge_heap(self.magic_to_dma_heap[dma_heap.magic], dma_heap)
            self.pid_magic_dict[dma_heap.pid][dma_heap.magic] = existing_reference
            return
        self.reference_to_heap[reference_key] = dma_heap
        self.pid_names.setdefault(dma_heap.pid, dma_heap.process_name)
        pids = self.magic_to_pids.setdefault(dma_heap.magic, [])
        if dma_heap.pid not in pids:
            pids.append(dma_heap.pid)
        if dma_heap.magic not in self.magic_to_dma_heap:
            self.magic_to_dma_heap[dma_heap.magic] = deepcopy(dma_heap)
        else:
            self._merge_heap(self.magic_to_dma_heap[dma_heap.magic], dma_heap)
        self.dma_heap_list.append(dma_heap)
        self.magic_dma_dict[dma_heap.magic].append(dma_heap)
        self.pid_magic_dict[dma_heap.pid][dma_heap.magic] = dma_heap
        self.pid_dma_dict[dma_heap.pid].append(dma_heap)

    def _merge_heap(self, target: DmaHeap, incoming: DmaHeap):
        """Merge two references to one inode without depending on row order."""
        target_size = int(target.size)
        incoming_size = int(incoming.size)
        if target_size != incoming_size:
            smaller, larger = sorted((target_size, incoming_size))
            self._add_warning(
                f'DMA buffer {target.magic}在不同引用中size不一致：{smaller} vs {larger}；'
                '去重总量按较大值计算。'
            )
            target.size = str(larger)
        self._merge_reclaim_state(target, incoming)
        metadata_fields = (
            'exp_pid', 'exp_task_comm', 'buf_name', 'exp_name', 'buf_type',
            'leak_type', 'can_reclaim', 'buf_to_pid', 'buf_to_task_comm',
        )
        for field_name in metadata_fields:
            self._merge_metadata_field(target, incoming, field_name)
        if target.source_format != '6.x' and incoming.source_format == '6.x':
            target.source_format = incoming.source_format

    def _merge_reclaim_state(self, target: DmaHeap, incoming: DmaHeap):
        target_reclaim = self._reclaim_state(target.is_reclaim)
        incoming_reclaim = self._reclaim_state(incoming.is_reclaim)
        if str(target.is_reclaim).strip().lower() == 'conflict':
            return
        if target_reclaim == 'unknown' and incoming_reclaim != 'unknown':
            target.is_reclaim = incoming.is_reclaim
            return
        if (target_reclaim != 'unknown' and incoming_reclaim != 'unknown' and
                target_reclaim != incoming_reclaim):
            self._add_warning(
                f'DMA buffer {target.magic}的is_reclaim状态冲突：'
                f'{target.is_reclaim!r} vs {incoming.is_reclaim!r}；按未知处理。'
            )
            target.is_reclaim = 'conflict'

    def _merge_metadata_field(self, target: DmaHeap, incoming: DmaHeap, field_name: str):
        current_value = getattr(target, field_name)
        incoming_value = getattr(incoming, field_name)
        values = set(target.metadata_conflicts.get(field_name, []))
        values.update(incoming.metadata_conflicts.get(field_name, []))
        if not values and not self._is_missing_metadata(current_value):
            values.add(str(current_value))
        if not self._is_missing_metadata(incoming_value):
            values.add(str(incoming_value))
        if not values:
            return
        if len(values) == 1:
            target.metadata_conflicts.pop(field_name, None)
            setattr(target, field_name, next(iter(values)))
            return
        sorted_values = sorted(values)
        target.metadata_conflicts[field_name] = sorted_values
        if field_name in {'buf_type', 'leak_type', 'can_reclaim'}:
            setattr(target, field_name, 'CONFLICT')
        else:
            setattr(target, field_name, f'CONFLICT[{"|".join(sorted_values)}]')

    def _report_metadata_conflicts(self):
        """Expose inode metadata conflicts without selecting a row-order winner."""
        for magic in sorted(self.magic_to_dma_heap):
            heap = self.magic_to_dma_heap[magic]
            for field_name in sorted(heap.metadata_conflicts):
                values = ', '.join(heap.metadata_conflicts[field_name])
                self._add_warning(
                    f'DMA buffer {magic}的{field_name}元数据冲突：{values}；'
                    '已标记为CONFLICT。'
                )

    def _select_owners(self, heap: DmaHeap):
        pids = list(self.magic_to_pids.get(heap.magic, []))
        if len(pids) <= 1:
            return pids

        process_names = {pid: self.pid_names.get(pid, '') for pid in pids}
        high_priority_pids = [
            pid for pid in pids if process_names[pid] not in low_priority_process
        ]
        if high_priority_pids:
            return high_priority_pids

        # Some historical hiaiserver records store the actual owner PID in
        # leak_type. Accept it only when it is also one of the observed PIDs.
        if 'hiaiserver' in process_names.values() and str(heap.leak_type).isdigit():
            explicit_pid = str(heap.leak_type)
            if explicit_pid in pids:
                return [explicit_pid]

        candidate_names = set(process_names.values())
        applicable_priority_lists = [
            priority_list for priority_list in priority_dict.values()
            if candidate_names.issubset(set(priority_list))
        ]
        if not applicable_priority_lists:
            return pids

        winner_names = {
            min(candidate_names, key=priority_list.index)
            for priority_list in applicable_priority_lists
        }
        if len(winner_names) != 1:
            return pids
        winner_name = next(iter(winner_names))
        return [pid for pid in pids if process_names[pid] == winner_name] or pids


class MemCheckBase(FormatUnitHandler):
    def __init__(self):
        super().__init__()
        self.process_ashmem_overview_list: List[ProcessAshmemOverviewInfo] = []
        self.process_ashmem_detail_list: List[ProcessAshmemDetailInfo] = []
        self.dma_heap_info = DmaHeapInfo()
        self.reason = ''

    def ashmem_build(self, context: List[str]):
        overview_start_index = 0
        overview_end_index = 0
        detail_start_index = 0
        detail_end_index = 0
        for index, line in enumerate(context):
            if re.search('Process_name Virtual_size Physical_size', line):
                overview_start_index = index + 1
            if re.search(r'Process_name\s+Process_ID\s+Fd\s+', line):
                overview_end_index = index - 1
                detail_start_index = index
            if re.search('^-+', line) and detail_start_index != 0 and index - detail_start_index > 2:
                detail_end_index = index - 1
                break
        self.process_ashmem_overview_list_build(context[overview_start_index:overview_end_index])
        self.process_ashmem_detail_list_build(context[detail_start_index:detail_end_index])

    def process_ashmem_overview_list_build(self, context: List[str]):
        overview_match = re.compile(r'Total\s+ashmem\s+of\s+\[(?P<process_name>[a-zA-Z0-9_.]+)]\s+virtual\s+size\s+is'
                                    r'\s+(?P<virtual_size>\d+),\s+physical\s+size\s+is\s+(?P<physical_size>\d+)')
        for line in context:
            match = overview_match.search(line)
            if match:
                process_ashmem_overview = ProcessAshmemOverviewInfo()
                process_ashmem_overview.process_name = match.group('process_name')
                process_ashmem_overview.process_name = self.truncate_process_name(process_ashmem_overview.process_name)
                process_ashmem_overview.virtual_size = match.group('virtual_size')
                process_ashmem_overview.physical_size = match.group('physical_size')
                self.process_ashmem_overview_list.append(process_ashmem_overview)

    def process_ashmem_detail_list_build(self, context: List[str]):
        ashmem_detail_member_dict = {'Process_name': 'process_name',
                                     'Process_ID': 'pid',
                                     'Fd': 'fd',
                                     'Cnode_idx': 'cnode_index',
                                     'Applicant_Pid': 'applicant_pid',
                                     'Ashmem_name': 'ashmem_name',
                                     'Virtual_size': 'virtual_size',
                                     'Physical_size': 'physical_size',
                                     'Magic': 'magic'
                                     }
        member_str_list = re.split(r'\s+', context[0].strip())
        member_index_dict = dict()
        for index, member_str in enumerate(member_str_list):
            if member_str in ashmem_detail_member_dict.keys():
                member_index_dict[ashmem_detail_member_dict[member_str]] = index
        for line in context[1:]:
            process_ashmem_detail = ProcessAshmemDetailInfo()
            member_list = re.split(r'\s+', line.strip())
            for member in member_index_dict.keys():
                index = member_index_dict[member]
                member_value = member_list[index]
                setattr(process_ashmem_detail, member, member_value)
            process_name = member_list[member_index_dict.get('process_name', 0)]
            process_name = self.truncate_process_name(process_name)
            process_ashmem_detail.process_name = process_name
            process_ashmem_detail.handle_name = re.sub(r'\d+$', 'xxx', process_ashmem_detail.ashmem_name)
            if len(member_list) > len(member_str_list):
                ashmem_name = member_list[member_index_dict.get('ashmem_name', 0)]
                process_ashmem_detail.handle_name = \
                    ashmem_name + " " + member_list[member_index_dict.get('ashmem_name', 0) + 1]
                process_ashmem_detail.virtual_size = \
                    member_list[member_index_dict.get('virtual_size', 0) + 1]
                process_ashmem_detail.physical_size = \
                    member_list[member_index_dict.get('physical_size', 0) + 1]
                process_ashmem_detail.magic = \
                    member_list[member_index_dict.get('magic', 0) + 1]
            self.process_ashmem_detail_list.append(process_ashmem_detail)

    def truncate_process_name(self, process_name: str) -> str:
        if process_name.startswith('com'):
            if len(process_name) >= 15:
                return process_name[-15:]
            else:
                return process_name
        else:
            if len(process_name) >= 15:
                return process_name[:15]
            else:
                return process_name

    def log_format(self):
        pass

    def log_split(self, context: List[str]):
        pass
