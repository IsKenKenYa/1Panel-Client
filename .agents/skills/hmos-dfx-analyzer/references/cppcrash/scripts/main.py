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

"""cppcrash 关键日志提取入口。

用法::

    python main.py -p <cppcrash日志文件或所在目录>
    python main.py -p <cppcrash日志目录> --all

流程：按时间收集日志 -> 解析 Native/GWP-ASan 日志 -> 特征匹配 -> 输出关键日志报告。
"""

import argparse
import os
import sys

# 保证以 `python main.py` 或 `python scripts/main.py` 直接运行时能找到同目录模块
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from collector import collect_logs
from crash_log import parse_crash_log
from report import render_report


def build_report(log_path: str, analyze_all: bool = False) -> str:
    """对外主接口：日志路径 -> 关键日志报告文本。"""
    found = collect_logs(log_path)
    if not found:
        raise ValueError(f'未在 {log_path} 中找到 cppcrash 日志')
    selected = found if analyze_all else found[:1]
    reports = []
    for index, path in enumerate(selected, start=1):
        crash = parse_crash_log(path)
        has_gwp_asan_frames = bool(crash.gwp_asan_text) and any(
            line.strip().startswith('#') and '0x' in line
            for line in crash.gwp_asan_text.splitlines()
        )
        if not crash.fault_stack.frames and not has_gwp_asan_frames:
            raise ValueError(
                f'该日志缺少 Native 调用栈'
                f'（无 #NN pc 帧且 GWP-ASan 报告无调用栈），无法分析: {path.name}'
            )
        if analyze_all and len(selected) > 1:
            reports.append(f'【日志 {index}/{len(selected)}：{path.name}】')
        other_logs = found[1:] if not analyze_all and index == 1 else []
        reports.append(render_report(crash, other_logs=other_logs))
    return '\n\n'.join(reports)


def main():
    _configure_output_encoding()
    parser = argparse.ArgumentParser(description='cppcrash 关键日志提取')
    parser.add_argument('-p', '--path', required=True, help='cppcrash日志文件或所在目录路径')
    parser.add_argument('--all', action='store_true', help='分析目录中识别到的全部cppcrash日志')
    args = parser.parse_args()
    try:
        print(build_report(args.path, analyze_all=args.all))
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
