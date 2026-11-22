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
"""Compatibility view of per-process DMA buffer records."""

from typing import List

from log_manager.common.handler.format_unit_handler import FormatUnitHandler
from log_manager.slicing.leak.memory_leak.mem_check_base import DmaHeapInfo


class ProcessDmaBuf(FormatUnitHandler):

    def __init__(self):
        super().__init__()
        self.process_dma_buf_info_list: List[ProcessDmaBufInfo] = []
        self.warnings = []

    def log_split(self, context: List[str]):
        # DmaHeapInfo already performs marker/header discovery for both 5.x and
        # 6.x formats. Keep the full context so both parsers share one schema.
        self.sub_context = context

    def log_format(self):
        self.process_dma_buf_info_list = []
        dma_heap_info = DmaHeapInfo()
        dma_heap_info.dma_build(self.sub_context)
        self.warnings = list(dma_heap_info.warnings)
        for heap in dma_heap_info.dma_heap_list:
            info = ProcessDmaBufInfo()
            info.process_name = heap.process_name
            info.pid = heap.pid
            info.fd = heap.fd
            info.size_bytes = getattr(heap, 'raw_size', '') or heap.size
            info.ino = heap.magic
            info.exp_pid = heap.exp_pid
            info.exp_task_comm = heap.exp_task_comm
            info.buf_name = heap.buf_name
            info.exp_name = heap.exp_name
            info.buf_type = heap.buf_type
            info.can_reclaim = heap.can_reclaim
            info.is_reclaim = heap.is_reclaim
            info.leak_type = heap.leak_type
            self.process_dma_buf_info_list.append(info)


class ProcessDmaBufInfo:

    def __init__(self):
        self.process_name = ''
        self.pid = ''
        self.fd = ''
        self.size_bytes = ''
        self.ino = ''
        self.exp_pid = ''
        self.exp_task_comm = ''
        self.buf_name = ''
        self.exp_name = ''
        self.can_reclaim = ''
        self.is_reclaim = ''
        self.buf_type = ''
        self.leak_type = ''

    def build(self):
        pass
