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

from log_manager.common.handler.format_unit_handler import FormatUnitHandler


class MemCheckDetialInfo(FormatUnitHandler):

    def __init__(self):
        super().__init__()
        self.total_allocated = 0
        self.total_nmalloc = 0
        self.bin_list: List[AllocatedInfo] = []
        self.large_list: List[AllocatedInfo] = []

    def log_format(self):
        bin_start = 0
        bin_end = 0
        large_start = 0
        large_end = 0
        total_match = re.compile(r'total:\s+(?P<total_allocated>\d+)\s+(?P<total_nmalloc>\d+)')
        for index, line in enumerate(self.sub_context):
            match = total_match.search(line)
            if match:
                self.total_allocated = int(match.group('total_allocated'))
                self.total_nmalloc = int(match.group('total_nmalloc'))
            if re.search(r'bins:\s+size', line):
                bin_start = index + 1
            if re.search(r'large:\s+size', line):
                bin_end = index - 1
                large_start = index + 1
            if re.search(r'extents:\s+size', line):
                large_end = index - 1
        self.bin_list_build(self.sub_context[bin_start:bin_end])
        self.large_list_build(self.sub_context[large_start:large_end])

    def log_split(self, context: List[str]):
        begin_str = 'LOGGER_MEMCHECK_DETIAL_INFO|Begin jemalloc statistics'
        end_str = '--- End jemalloc statistics ---'
        start_index = 0
        end_index = 0
        for index, line in enumerate(context):
            if re.search(begin_str, line):
                start_index = index + 1
            if re.search(end_str, line):
                end_index = index - 1
        if start_index >= end_index:
            return
        self.sub_context = context[start_index:end_index]
        del context[:end_index + 1]

    def bin_list_build(self, context: List[str]):
        for line in context:
            member_list = re.split(r'\s+', line.strip())
            allocated_info = AllocatedInfo()
            if len(member_list) > 3:
                allocated_info.size = int(member_list[0])
                allocated_info.allocated = int(member_list[2])
                self.bin_list.append(allocated_info)

    def large_list_build(self, context: List[str]):
        for line in context:
            member_list = re.split(r'\s+', line.strip())
            allocated_info = AllocatedInfo()
            if len(member_list) > 3:
                allocated_info.size = int(member_list[0])
                allocated_info.allocated = int(member_list[2])
                self.large_list.append(allocated_info)


class AllocatedInfo:

    def __init__(self):
        self.size: int = 0
        self.allocated: int = 0
