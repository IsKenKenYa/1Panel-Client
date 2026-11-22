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


class MemCheckSmapsInfo(FormatUnitHandler):
    def __init__(self):
        super().__init__()
        self.swap_info_list: List[SwapInfo] = []
        self.realtime = ''
        self.summary = 0
        self.member_dict = {'Size': 'size',
                            'Rss': 'rss',
                            'Pss': 'pss',
                            'Swap': 'swap',
                            'SwapPss': 'swap_pss',
                            'Counts': 'counts',
                            'Name': 'name'}

    def log_split(self, context: List[str]):
        begin_str = 'LOGGER_MEMCHECK_SMAPS_INFO'
        begin_index = -1
        end_index = -1
        for index, line in enumerate(context):
            if begin_str in line:
                begin_index = index + 1
            if begin_index != -1 and re.search(r'^\*+', line):
                end_index = index - 1
                break
        if begin_index == -1:
            return
        if end_index == -1:
            end_index = len(context) - 1
        self.sub_context = context[begin_index:end_index + 1]

    def log_format(self):
        if not self.sub_context:
            return
        target_index = 0
        for index, line in enumerate(self.sub_context):
            if re.search(r'Size\s+Rss\s+Pss\s+Clean\s+', line):
                target_index = index
                break
        member_str_list = re.split(r'\s{2,}', self.sub_context[target_index].strip())
        member_index_dict = dict()
        for index, member_str in enumerate(member_str_list):
            if member_str in self.member_dict.keys():
                member_index_dict[self.member_dict[member_str]] = index
        for line in self.sub_context[target_index + 1:]:
            swap_info = SwapInfo()
            if not re.search(r'\d+\s+\d+\s+\d+\s+', line):
                continue
            member_list = re.split(r'\s{2,}', line.strip())
            if 'Summary' in line:
                self.summary = int(member_list[0])
            for member in member_index_dict.keys():
                if len(member_list) < len(member_str_list):
                    break
                index = member_index_dict[member]
                if index >= len(member_list):
                    continue
                if member == 'name':
                    setattr(swap_info, member, member_list[-1])
                else:
                    setattr(swap_info, member, int(member_list[index]))
            self.swap_info_list.append(swap_info)


class SwapInfo:

    def __init__(self):
        self.size = 0
        self.rss = 0
        self.pss = 0
        self.shared_clean = 0
        self.shared_dirty = 0
        self.private_clean = 0
        self.private_dirty = 0
        self.swap = 0
        self.swap_pss = 0
        self.count = 0
        self.name = ''
