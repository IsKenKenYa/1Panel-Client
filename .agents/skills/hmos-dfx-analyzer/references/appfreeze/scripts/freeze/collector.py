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
"""日志文件收集：在文件或目录中找出 freeze faultlog 与采样栈文件。"""

import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List

from freeze.common import read_lines

# 标准命名：appfreeze-com.xxx.app-20010043-20250521075602
_FAULTLOG_NAME_RE = re.compile(
    r'(?P<kind>appfreeze|sysfreeze)-(?P<package>[0-9a-zA-Z_.:]+)-(?P<uid>\d+)-(?P<timestamp>\d+)')
# 采样栈：freeze-cpuinfo-ext-com.xxx.app-20010043-20250521075602
_SAMPLE_NAME_RE = re.compile(
    r'freeze-cpuinfo-ext-(?P<package>[0-9a-zA-Z_.]+)-(?P<uid>\d+)-(?P<timestamp>\d+)')


@dataclass
class CollectResult:
    """收集结果：faultlogs 按分析优先级排序（appfreeze 优先，时间新者优先）。"""
    faultlogs: List[Path] = field(default_factory=list)
    sample_stacks: List[Path] = field(default_factory=list)


def collect_logs(log_path) -> CollectResult:
    """从文件或目录收集 freeze 相关日志。"""
    path = Path(log_path)
    result = CollectResult()
    if path.is_file():
        _classify(path, result)
    elif path.is_dir():
        for root, _, files in os.walk(path):
            for file_name in files:
                _classify(Path(root) / file_name, result)
    else:
        raise ValueError(f'路径不存在: {log_path}')
    result.faultlogs.sort(key=_faultlog_priority)
    return result


def _classify(path: Path, result: CollectResult):
    if _SAMPLE_NAME_RE.search(path.name):
        result.sample_stacks.append(path)
        return
    name_match = _FAULTLOG_NAME_RE.search(path.name)
    if name_match:
        result.faultlogs.append(path)
        return
    if _sniff_is_freeze_log(path):
        result.faultlogs.append(path)


def _sniff_is_freeze_log(path: Path) -> bool:
    """文件名不规范时，读文件开头判断是否为 freeze faultlog。"""
    head = read_lines(path, max_lines=200)
    for line in head:
        # crash 类日志直接排除
        if 'Error name' in line or 'Reason:Signal' in line:
            return False
        if 'eventLog_action =' in line:
            return True
    return False


def _faultlog_priority(path: Path):
    """排序：appfreeze 在 sysfreeze 之前；同类按文件名（时间戳）倒序。"""
    is_sysfreeze = 1 if path.name.startswith('sysfreeze') else 0
    return is_sysfreeze, [-ord(ch) for ch in path.name]
