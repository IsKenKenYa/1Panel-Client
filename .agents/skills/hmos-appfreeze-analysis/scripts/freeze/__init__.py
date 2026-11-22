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
"""appfreeze 关键日志提取工具。

把 OpenHarmony 的 appfreeze faultlog 解析成结构化数据，
并渲染成供大模型分析的"关键日志"文本报告。

处理流程是一条直线管道::

    main.py        CLI 入口，串起下面四步
      |
      v
    collector.py   在文件/目录中找出 faultlog 与采样栈文件
      |
      v
    freeze.py      把一个 faultlog 文件解析成 FreezeLog 对象
      |              |- sections.py  头部/MSG/EventHandler/CPU/内存/热等级等区段解析
      |              |- stack.py     线程堆栈解析
      |              `- binder.py    binder 区段解析
      v
    binder.py      从故障线程出发追踪 binder 调用链
      |
      v
    report.py      渲染关键日志报告

公共小工具（读文件、时间解析、区段定位）在 common.py。
"""
