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
import os

from pathlib import Path
from typing import List, Optional

from tools.logger_manager import LogManager

logger = LogManager.create_logger()


def read_file_to_list(
        file_path: Path,
        encoding='utf-8',
        read_lines: int = None,
        warnings: Optional[List[str]] = None) -> List[str]:
    """
    将文件内容读取为列表
    :param file_path:str 读取的文件路径
    :param encoding:str 编码方式，默认为utf-8
    :param read_lines:int 编码方式，默认为utf-8
    :return list 文件内容
    """
    if not os.path.exists(file_path):
        return []
    raw_data = Path(file_path).read_bytes()
    decode_encoding = 'utf-8-sig' if encoding.lower().replace('_', '-') == 'utf-8' else encoding
    try:
        text = raw_data.decode(decode_encoding)
    except UnicodeDecodeError:
        text = raw_data.decode(decode_encoding, errors='replace')
        replacement_count = text.count('\ufffd')
        warning = (
            f'文件包含 {replacement_count} 处无法按 {encoding} 解码的字节，'
            '已用替换字符保留其余结构；受影响的文本字段可能不完整。'
        )
        if warnings is not None:
            warnings.append(warning)
        else:
            logger.warning(warning)
    context = text.splitlines(keepends=True)
    if read_lines is not None:
        return context[:read_lines]
    return context
