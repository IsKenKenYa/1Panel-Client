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

"""日志文件收集：在文件或目录中找出 cppcrash 日志。"""

import os
import re
from datetime import datetime
from pathlib import Path
from typing import List

from common import read_lines

# 标准命名：cppcrash-com.xxx.app-20010099-20250610120000
# temp 命名：cppcrash-4321-1749528000000
_NAME_RE = re.compile(r'cppcrash-[0-9a-zA-Z_.:]+-\d+')


def collect_logs(log_path) -> List[Path]:
    """从文件或目录收集 cppcrash 日志，按故障时间倒序。"""
    path = Path(log_path)
    if path.is_file():
        found = [path] if _is_cppcrash_log(path) else []
    elif path.is_dir():
        found = _collect_directory_logs(path)
    else:
        raise ValueError(f'路径不存在: {log_path}')
    found.sort(key=_log_sort_key, reverse=True)
    return found


def _collect_directory_logs(path: Path) -> List[Path]:
    found = []
    for root, _, files in os.walk(path):
        for file_name in files:
            file_path = Path(root) / file_name
            if _is_cppcrash_log(file_path):
                found.append(file_path)
    return found


def _is_cppcrash_log(path: Path) -> bool:
    if _NAME_RE.search(path.name):
        return True
    # 文件名不规范时读文件开头嗅探
    head = read_lines(path, max_lines=200)
    for line in head:
        if ('Reason:Signal:' in line or 'Reason:GWP-ASAN' in line or
                '*** GWP-ASan detected a memory error ***' in line):
            return True
        # freeze / jscrash 日志直接排除
        if 'eventLog_action =' in line or 'Error name:' in line:
            return False
    return False


def _log_sort_key(path: Path):
    """优先使用文件名时间戳，无法解析时回退到文件修改时间。"""
    match = re.search(r'(\d{13,17})(?:\D*)$', path.name)
    if match:
        parsed = _parse_timestamp(match.group(1))
        if parsed is not None:
            return parsed, path.name
    try:
        return path.stat().st_mtime, path.name
    except OSError:
        return 0.0, path.name


def _parse_timestamp(value: str):
    if len(value) >= 14 and value.startswith(('19', '20')):
        try:
            base = datetime.strptime(value[:14], '%Y%m%d%H%M%S').timestamp()
            fraction = value[14:17]
            return base + (int(fraction) / (10 ** len(fraction)) if fraction else 0)
        except ValueError:
            return None
    if len(value) == 13:
        try:
            return int(value) / 1000
        except ValueError:
            return None
    return None
