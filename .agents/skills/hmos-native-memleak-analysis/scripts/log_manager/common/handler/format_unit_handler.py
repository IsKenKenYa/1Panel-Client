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
import abc
from abc import ABC
from typing import List

from tools.logger_manager import LogManager


class FormatUnitHandler(ABC):
    """
    日志拆分映射单元，所有拆分的故障日志类都必须继承该类
    """

    def __init__(self, next_handle: 'FormatUnitHandler' = None):
        self.next_handler = next_handle
        self.handles: List[FormatUnitHandler] = []
        self.logger = LogManager.create_logger()
        self.sub_context: List[str] = []
        self.is_build_fail = False
        self.build_error = ''

    @abc.abstractmethod
    def log_split(self, context: List[str]):
        """
        日志拆分方法，负责切割日志，供当前故障类使用
        拆分后self.sub_context 为截取后当前需要解析的日志
        """
        pass

    @abc.abstractmethod
    def log_format(self):
        """
        日志映射的方法，为每个成员变量赋值
        """
        pass

    def build(self, context: List[str]):
        self.log_split(context)
        self.log_format()
        return self

    def current_handle(self, context: List[str]):
        self.is_build_fail = False
        self.build_error = ''
        try:
            self.build(context)
        except Exception as err:
            self.is_build_fail = True
            self.build_error = f'{type(err).__name__}: {err}'
            self.logger.error(f'构建成员变量失败：{self.build_error}')
        self.sub_context = []

    def next_handle(self, handle: 'FormatUnitHandler'):
        self.next_handler = handle
        return handle

    def handle(self, context: List[str]):
        if context:
            self.current_handle(context)
        if self.next_handler:
            self.next_handler.handle(context)
