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
from typing import List, Tuple

from tools.logger_manager import LogManager

logger = LogManager.create_logger()


def print_table_info(target_list: List[Tuple]):
    """输出表格形式的信息"""
    target_info = ''
    max_length_list = []
    for index, target_obj in enumerate(target_list[0]):
        max_length = max(len(str(row[index])) for row in target_list)
        max_length_list.append(max_length)
    for index, size_obj in enumerate(target_list):
        if index == 1:
            target_info += "-" * (sum(max_length_list) + 4) + '\n'
        for index_, max_length in enumerate(max_length_list):
            target_info += f'{str(size_obj[index_]).ljust(max_length)}'
            if index_ != len(max_length_list) - 1:
                target_info += ' |'
        target_info += '\n'
    return target_info
