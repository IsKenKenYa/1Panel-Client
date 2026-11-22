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


class MemCheckMemInfo(FormatUnitHandler):

    def __init__(self):
        super().__init__()
        self.mem_total: int = 0
        self.mem_free: int = 0
        self.ion_total_use: int = 0
        self.ion_total_use_unit = ''
        self.ion_total_use_bytes: int = 0
        self.gpu_total_used: int = 0
        self.gpu_total_used_unit = ''
        self.gpu_total_used_bytes: int = 0

    @staticmethod
    def _to_bytes(value: int, unit: str):
        normalized_unit = unit.strip().lower()
        multipliers = {
            'b': 1,
            'kb': 1024,
            'kib': 1024,
            'mb': 1024 ** 2,
            'mib': 1024 ** 2,
            'gb': 1024 ** 3,
            'gib': 1024 ** 3,
        }
        multiplier = multipliers.get(normalized_unit)
        return value * multiplier if multiplier else 0

    def log_format(self):
        patterns = {
            "mem_total": r"MemTotal\s*:\s*(?P<value>\d+)(?:\s+(?P<unit>[KMGT]?i?[bB]))?",
            "mem_free": r"MemFree\s*:\s*(?P<value>\d+)(?:\s+(?P<unit>[KMGT]?i?[bB]))?",
            "ion_total_use": r"(?:Ion|Dma)TotalUse[d]?\s*:\s*(?P<value>\d+)(?:\s+(?P<unit>[KMGT]?i?[bB]))?",
            "gpu_total_used": r"GpuTotalUse[d]?\s*:\s*(?P<value>\d+)(?:\s+(?P<unit>[KMGT]?i?[bB]))?",
        }
        for line in self.sub_context:
            for key, pattern in patterns.items():
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    self._apply_match(key, match)

    def log_split(self, context: List[str]):
        start_index = None
        end_index = len(context)
        for index, line in enumerate(context):
            if "LOGGER_MEMCHECK_MEMINFO" in line:
                start_index = index + 1
                continue
            if start_index is not None and index >= start_index and re.search(r'^\s*\*+', line):
                end_index = index
                break
        if start_index is None:
            return
        self.sub_context = context[start_index:end_index]

    def _apply_match(self, key: str, match: re.Match):
        value = int(match.group('value'))
        unit = match.group('unit') or ''
        setattr(self, key, value)
        if key == 'ion_total_use':
            self.ion_total_use_unit = unit
            self.ion_total_use_bytes = self._to_bytes(value, unit)
        elif key == 'gpu_total_used':
            self.gpu_total_used_unit = unit
            self.gpu_total_used_bytes = self._to_bytes(value, unit)
