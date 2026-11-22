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
"""appfreeze 关键日志提取入口。

用法::

    python main.py -p <faultlog文件或所在目录>

流程：收集日志文件 -> 解析 faultlog -> 追踪 binder 链路 -> 输出关键日志报告。
"""

import argparse
import os
import sys
from pathlib import Path

# 保证以 `python main.py` 直接运行时能找到 freeze 包
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from freeze.collector import collect_logs
from freeze.faultlog import parse_freeze_log
from freeze.report import SECTION_CHOICES, render_section


def build_report(log_path: str, section: str = 'full') -> str:
    """对外主接口：日志路径 -> 关键日志报告文本。"""
    collected = collect_logs(log_path)
    if not collected.faultlogs:
        if Path(log_path).is_file():
            parse_freeze_log(log_path)
        raise ValueError(f'未在 {log_path} 中找到 appfreeze/sysfreeze faultlog 日志')
    target = collected.faultlogs[0]
    freeze = parse_freeze_log(target)
    return render_section(
        freeze,
        section=section,
        sample_stacks=collected.sample_stacks,
        other_faultlogs=collected.faultlogs[1:],
    )


def main():
    _configure_output_encoding()
    parser = argparse.ArgumentParser(description='appfreeze 关键日志提取')
    parser.add_argument('-p', '--path', required=True, help='faultlog文件或所在目录路径')
    parser.add_argument(
        '--section',
        choices=SECTION_CHOICES,
        default='full',
        help='仅输出指定报告区段，默认输出 full 完整报告',
    )
    args = parser.parse_args()
    try:
        print(build_report(args.path, section=args.section))
    except Exception as err:
        print(f'关键日志提取失败：{err}', file=sys.stderr)
        sys.exit(1)


def _configure_output_encoding():
    """统一正常输出、帮助和错误信息的编码。"""
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, 'reconfigure'):
            stream.reconfigure(encoding='utf-8', errors='replace')


if __name__ == '__main__':
    main()
