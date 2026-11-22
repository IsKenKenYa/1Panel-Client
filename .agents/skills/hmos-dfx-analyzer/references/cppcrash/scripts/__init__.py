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

"""cppcrash 关键日志提取工具。

把 OpenHarmony 的 cppcrash faultlog 解析成结构化数据，
并渲染成供大模型分析的"关键日志"文本报告。本包完全独立，不依赖其他故障目录。

处理流程是一条直线管道::

    main.py        CLI 入口
      |
      v
    collector.py   在文件/目录中找出 cppcrash 日志
      |
      v
    crash_log.py   按 'Fault thread info:' / 'Registers:' / 'Maps:' 等标记
      |            把日志切段，解析成 CppCrashLog 对象
      v
    hints.py       基于堆栈/LastFatalMessage 的常见崩溃特征匹配
      |
      v
    report.py      渲染关键日志报告（信号、分层调用帧、GWP-ASan原文、精简maps）

公共小工具（读文件、字段提取、分段）在 common.py。
"""
