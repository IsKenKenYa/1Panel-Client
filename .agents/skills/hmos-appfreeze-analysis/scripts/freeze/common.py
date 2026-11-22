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
"""通用小工具：文件读取、时间解析、日志区段定位。"""

import re
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Tuple, Union

# faultlog 中出现过的时间格式，统一在这里识别：
#   2025-05-21 07:56:02 / 2025-05-21 07:56:02.123 / 2025-05-20 08:04:51:754
#   2025/05/21-07:55:59 / 2025/05/21-07:55:59:553 / 2025/05/21 07:56:00
#   2025-07-01-21-46-57.509059
#   20250521075602 / 20250521-075602
_TIME_RES = [
    re.compile(r'^(\d{4})[-/](\d{2})[-/](\d{2})[ \-T](\d{2}):(\d{2}):(\d{2})(?:[.:](\d{1,6}))?$'),
    re.compile(r'^(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})(?:\.(\d{1,6}))?$'),
    re.compile(r'^(\d{4})(\d{2})(\d{2})-?(\d{2})(\d{2})(\d{2})(\d{0,6})$'),
]


def read_lines(file_path: Union[str, Path], max_lines: int = None) -> List[str]:
    """按行读取文件，文件不存在时返回空列表。"""
    path = Path(file_path)
    if not path.is_file():
        return []
    lines = []
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        for index, line in enumerate(f):
            if max_lines is not None and index >= max_lines:
                break
            lines.append(line)
    return lines


def parse_time(time_str: str) -> Optional[datetime]:
    """把日志中的时间字符串解析为 datetime，无法识别时返回 None。"""
    if not time_str:
        return None
    time_str = time_str.strip()
    for regex in _TIME_RES:
        match = regex.match(time_str)
        if not match:
            continue
        year, month, day, hour, minute, second, frac = (match.groups() + ('',))[:7]
        # 小数部分右补零到 6 位作为微秒：123 -> 123000us，509059 -> 509059us
        micro = int((frac or '').ljust(6, '0')[:6] or 0)
        try:
            return datetime(int(year), int(month), int(day),
                            int(hour), int(minute), int(second), micro)
        except ValueError:
            continue
    return parse_english_time(time_str)


def parse_english_time(time_str: str) -> Optional[datetime]:
    """解析 'Thu May 21 07:55:59 2025' 这种英文时间（SERVICE_BLOCK 的 MSG 中出现）。"""
    match = re.search(r'\w{3} (\w{3}) +(\d{1,2}) (\d{2}):(\d{2}):(\d{2}) (\d{4})', time_str)
    if not match:
        return None
    try:
        return datetime.strptime(' '.join(match.groups()), '%b %d %H:%M:%S %Y')
    except ValueError:
        return None


def fmt_time(time_obj: Optional[datetime]) -> str:
    """datetime 转字符串，None 安全。"""
    if not time_obj:
        return ''
    return time_obj.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]


def diff_seconds(later: Optional[datetime], earlier: Optional[datetime]) -> Optional[float]:
    """两个时间的秒差，任一为 None 时返回 None。"""
    if not later or not earlier:
        return None
    return round((later - earlier).total_seconds(), 3)


def find_section(lines: List[str], start_re: str, end_re: str,
                 include_start: bool = True) -> Tuple[List[str], int]:
    """定位一个日志区段。

    从 lines 中找到第一个匹配 start_re 的行，再从它之后找第一个匹配 end_re 的行，
    返回 (区段行列表, 区段起始下标)。找不到起始行返回 ([], -1)；
    找不到结束行则截取到末尾。
    """
    start_index = -1
    start_pattern = re.compile(start_re)
    end_pattern = re.compile(end_re)
    for index, line in enumerate(lines):
        if start_pattern.search(line):
            start_index = index
            break
    if start_index < 0:
        return [], -1
    end_index = len(lines)
    for index in range(start_index + 1, len(lines)):
        if end_pattern.search(lines[index]):
            end_index = index
            break
    begin = start_index if include_start else start_index + 1
    return lines[begin:end_index], start_index


def search_fields(lines: List[str], field_res: dict) -> dict:
    """用 {字段名: 正则} 在多行文本中提取首个命中的捕获组 1，返回 {字段名: 值}。"""
    remaining = dict(field_res)
    result = {}
    for line in lines:
        if not remaining:
            break
        for key in list(remaining):
            match = re.search(remaining[key], line)
            if match and match.group(1).strip():
                result[key] = match.group(1).strip()
                del remaining[key]
    return result
