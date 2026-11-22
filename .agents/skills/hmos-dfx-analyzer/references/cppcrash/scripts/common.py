# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
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

"""通用小工具：文件读取、字段提取、按标记行分段。"""

import re
from pathlib import Path
from typing import Dict, List, Union


def read_lines(file_path: Union[str, Path], max_lines: int = None) -> List[str]:
    """按行读取文件，文件不存在时返回空列表。"""
    path = Path(file_path)
    if not path.is_file():
        return []
    lines = []
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for index, line in enumerate(f):
            if max_lines is not None and index >= max_lines:
                break
            lines.append(line)
    return lines


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


def split_by_markers(lines: List[str], markers: List[str]) -> Dict[str, List[str]]:
    """按一组顺序出现的标记行把日志切段。

    markers 是标记行的子串列表（按日志中的出现顺序排列）。
    返回 {标记: 该标记行(含)到下一个标记行(不含)之间的行}；
    第一个标记之前的行放在 '' 键下；缺失的标记对应空列表。
    """
    sections: Dict[str, List[str]] = {marker: [] for marker in markers}
    current = ''
    sections[current] = []
    remaining = list(markers)
    for line in lines:
        for index, marker in enumerate(remaining):
            if line.lstrip().startswith(marker):
                current = marker
                remaining = remaining[index + 1:]
                break
        sections[current].append(line)
    return sections
