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


class KernelHeader(FormatUnitHandler):

    def __init__(self):
        super().__init__()
        self.memory_name = ''
        self.soft_threshold: int = 0
        self.hard_threshold: int = 0
        self.app_hard_threshold: int = 0
        self.top_memory: int = 0

    def log_split(self, context: List[str]):
        start_index = None
        end_index = len(context)
        for index, line in enumerate(context):
            if ('LOGGER_MEMCHECK_GERNAL_INFO' in line or
                    'LOGGER_MEMCHECK_GENERAL_INFO' in line):
                start_index = index + 1
                continue
            if start_index is not None and index >= start_index and re.search(r'^\s*\*+', line):
                end_index = index
                break
        self.sub_context = context[start_index:end_index] if start_index is not None else []

    def log_format(self):
        for line in self.sub_context:
            self.basic_info_build(line)

    def basic_info_build(self, line):
        memory_name_match = re.search(r'memoryName\s*:\s*(?P<memory_name>[\w-]+)', line, re.IGNORECASE)
        if memory_name_match:
            self.memory_name = memory_name_match.group('memory_name')
        soft_threshold_match = re.search(r'softThreshold:(?P<soft_threshold>\d+)\((?P<unit>\w+)\)', line)
        if soft_threshold_match:
            soft_threshold = soft_threshold_match.group('soft_threshold')
            if soft_threshold_match.group('unit') == 'MB':
                self.soft_threshold = int(soft_threshold) * 1024
            else:
                self.soft_threshold = int(soft_threshold)
        hard_threshold_match = re.search(r'hardThreshold:(?P<hard_threshold>\d+)\((?P<unit>\w+)\)', line)
        if hard_threshold_match:
            hard_threshold = hard_threshold_match.group('hard_threshold')
            if hard_threshold_match.group('unit') == 'MB':
                self.hard_threshold = int(hard_threshold) * 1024
            else:
                self.hard_threshold = int(hard_threshold)
        app_hard_threshold_match = re.search(r'appHardThreshold:(?P<app_hard_threshold>\d+)\((?P<unit>\w+)\)', line)
        if app_hard_threshold_match:
            app_hard_threshold = app_hard_threshold_match.group('app_hard_threshold')
            if app_hard_threshold_match.group('unit') == 'MB':
                self.app_hard_threshold = int(app_hard_threshold) * 1024
            else:
                self.app_hard_threshold = int(app_hard_threshold)
        top_memory_match = re.search(r'topMemory:(?P<top_memory>\d+)\((?P<unit>\w+)\)', line)
        if top_memory_match:
            top_memory = top_memory_match.group('top_memory')
            if top_memory_match.group('unit') == 'MB':
                self.top_memory = int(top_memory) * 1024
            else:
                self.top_memory = int(top_memory)
