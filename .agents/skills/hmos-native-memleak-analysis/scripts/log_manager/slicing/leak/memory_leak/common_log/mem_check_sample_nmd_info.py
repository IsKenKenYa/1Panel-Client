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
from typing import Dict, List

from log_manager.common.handler.format_unit_handler import FormatUnitHandler
from log_manager.slicing.leak.memory_leak.common_log.mem_check_detial_info import AllocatedInfo


class MemCheckSampleNmdInfo(FormatUnitHandler):

    def __init__(self):
        super().__init__()
        self.nmd_map1: Dict[int, int] = {}
        self.nmd_map2: Dict[int, int] = {}
        self.nmd_set: set = set()

    @staticmethod
    def set_allocated_info(context: List[str], start: int, end: int, nmd_map: Dict[int, int]):
        for line in context[start:end]:
            member_list = re.split(r'\s{2,}', line.strip())
            allocated_info = AllocatedInfo()
            if len(member_list) > 2:
                allocated_info.size = int(member_list[0])
                allocated_info.allocated = int(member_list[1])
                nmd_map[allocated_info.size] = allocated_info.allocated

    def log_split(self, context: List[str]):
        start_index_list = []
        end_index_list = []
        for index, line in enumerate(context):
            if re.search('LOGGER_MEMCHECK_SAMPLE_NMD_INFO', line):
                start_index_list.append(index + 2)
            if re.search(r'\*+\s+endl\s+\*+', line) and len(start_index_list) > 0:
                end_index_list.append(index)
            if len(start_index_list) == len(end_index_list) == 2:
                break
        if len(start_index_list) == 0 or len(end_index_list) == 0:
            return
        self.set_allocated_info(context, start_index_list[0], end_index_list[0], self.nmd_map1)
        self.set_allocated_info(context, start_index_list[-1], end_index_list[-1], self.nmd_map2)

    def log_format(self):
        pass
