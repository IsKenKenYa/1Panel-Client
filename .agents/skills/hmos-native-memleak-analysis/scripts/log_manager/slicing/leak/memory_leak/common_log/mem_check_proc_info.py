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
from typing import List

from log_manager.slicing.leak.memory_leak.mem_check_base import MemCheckBase


class MemCheckProcInfo(MemCheckBase):

    def __init__(self):
        super().__init__()
        self.gpu_info = GpuInfo()
        self.slab_info = SlabInfo()

    def log_format(self):
        if self.reason == 'ashmem':
            self.ashmem_build(self.sub_context)
        if self.reason == 'slab':
            self.slab_build(self.sub_context)
        if self.reason == 'gpu':
            self.gpu_build(self.sub_context)
        if self.reason == 'ion':
            self.ion_build(self.sub_context)

    def log_split(self, context: List[str]):
        self.sub_context = context

    def slab_build(self, context: List[str]):
        self.slab_info.build(context)

    def gpu_build(self, context: List[str]):
        self.gpu_info.build(context)

    def ion_build(self, context: List[str]):
        self.dma_heap_info.build(context)


class SlabInfo:
    def __init__(self):
        self.slab_detail_info_list: List[SlabDetailInfo] = []
        self.mcache_info_list: List[SlabDetailInfo] = []

    def build(self, context: List[str]):
        slab_info_start_index = 0
        slab_info_end_index = 0
        mcache_info_start_index = 0
        mcache_info_end_index = 0
        for index, line in enumerate(context):
            if 'slabinfo - version' in line:
                slab_info_start_index = index + 2
            if 'mcacheinfo - version' in line:
                slab_info_end_index = index - 1
                mcache_info_start_index = index + 2
            if re.search(r'^-+', line):
                mcache_info_end_index = index - 1
                break
        slab_context = context[slab_info_start_index:slab_info_end_index]
        mcache_context = context[mcache_info_start_index:mcache_info_end_index]
        self.slab_detail_info_list_build(slab_context)
        self.mcache_info_list_build(mcache_context)

    def slab_detail_info_list_build(self, context: List[str]):
        for line in context:
            slab_detail_info = SlabDetailInfo()
            member_list = line.strip().split()
            # member_list
            if len(member_list) >= 4:
                slab_detail_info.name = member_list[0].strip()
                slab_detail_info.active_obj = int(member_list[1].strip())
                slab_detail_info.num_obj = int(member_list[2].strip())
                slab_detail_info.obj_size = int(member_list[3].strip())
                self.slab_detail_info_list.append(slab_detail_info)

    def mcache_info_list_build(self, context: List[str]):
        for line in context:
            slab_detail_info = SlabDetailInfo()
            member_list = line.strip().split()
            if len(member_list) >= 4:
                slab_detail_info.name = member_list[0].strip()
                slab_detail_info.active_obj = int(member_list[1].strip())
                slab_detail_info.num_obj = int(member_list[2].strip())
                slab_detail_info.obj_size = int(member_list[3].strip())
                self.mcache_info_list.append(slab_detail_info)


class SlabDetailInfo:
    def __init__(self):
        self.name = ''
        self.active_obj = 0
        self.num_obj = 0
        self.obj_size = 0

    def build(self):
        pass


class GpuInfo:
    def __init__(self):
        self.used_summary = ''
        self.process_name = ''
        self.pid = ''
        self.total_u_device = ''
        self.total_a_device = ''
        self.total_p_device = ''
        self.total_memory_name = ''
        self.total_summary = ''
        self.all_type_memory_dict = dict()
        self.channel_info: ChannelInfo = ChannelInfo()

    def build(self, context: List[str]):
        self.basic_info_build(context)

    def basic_info_build(self, context: List[str]):
        start_index = 0
        end_index = 0
        total_u_device_res = re.compile(r'Total U\(device\):\s+(?P<total_u_device>\d+)')
        total_a_device_res = re.compile(r'Total A \(device\):\s+(?P<total_a_device>\d+)')
        total_p_device_res = re.compile(r'Total P \(device\):\s+(?P<total_p_device>\d+)')
        for index, line in enumerate(context):
            total_u_device_match = total_u_device_res.search(line)
            if total_u_device_match:
                self.total_u_device = total_u_device_match.group('total_u_device')
                self.process_name = context[index - 1].strip()
            total_a_device_match = total_a_device_res.search(line)
            if total_a_device_match:
                self.total_a_device = total_a_device_match.group('total_a_device')
            total_p_device_match = total_p_device_res.search(line)
            if total_p_device_match:
                self.total_p_device = total_p_device_match.group('total_p_device')
            if re.search(r'C:[a-zA-Z0-9\s_]+:\s+\d+', line) and start_index == 0:
                start_index = index
            if re.search(r'C:[a-zA-Z0-9\s_]+\(Total\s+memory', line):
                end_index = index - 1
                break
        self.get_all_type_memory(context[start_index:end_index])
        self.get_channel_info(context)

    def get_all_type_memory(self, context: List[str]):
        for line in context:
            member_list = line.split(':')
            if len(member_list) > 2:
                self.all_type_memory_dict[member_list[1].strip()] = int(member_list[2].strip())

    def get_channel_info(self, context: List[str]):
        if len(self.all_type_memory_dict) == 0:
            self.exception_channel_info_build(context)
            return
        sorted_memory_list = sorted(self.all_type_memory_dict.items(), key=lambda x: x[1], reverse=True)
        total_memory_name = sorted_memory_list[0][0]
        total_summary = sorted_memory_list[0][1]
        flag = False
        channel_info_list = []
        for line in context:
            if re.search(
                    rf'{re.escape(total_memory_name)}\s+\(Total memory:\s+{total_summary}\)',
                    line):
                flag = True
                continue
            if not flag:
                continue
            match = re.search(r'(?P<channel_number>\d+):\s+(?P<channel_count>\d+)\s+/\s+(?P<total_size>\d+)', line)
            if match:
                channel_info = ChannelInfo()
                channel_info.channel_number = int(match.group('channel_number'))
                channel_info.channel_count = int(match.group('channel_count'))
                channel_info.total_size = int(match.group('total_size'))
                channel_info_list.append(channel_info)
            else:
                break
        if len(channel_info_list) == 0:
            return
        sorted_channel_info_list = sorted(channel_info_list, key=lambda x: x.total_size, reverse=True)
        self.channel_info = sorted_channel_info_list[0]
        self.channel_info.channel_name = total_memory_name
        self.total_memory_name = total_memory_name
        self.total_summary = total_summary

    def exception_channel_info_build(self, context: List[str]):
        # 获取最高的total memory
        total_memory_dict = dict()
        index_dict = dict()
        total_memory_match = re.compile(r'Total Memory:\s+(?P<total_memory>\d+)')
        pass


class ChannelInfo:
    def __init__(self):
        self.channel_name = ''
        self.channel_number = 0
        self.channel_count = 1
        self.total_size = 0

    def build(self):
        pass
