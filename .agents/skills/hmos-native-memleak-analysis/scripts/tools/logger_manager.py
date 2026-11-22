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
import logging
import time


class LogManager:
    """日志管理器，可生成指定模式的logger"""

    @staticmethod
    def create_logger():
        return LocalLogger().logger

    @staticmethod
    def log_module_time(module_name: str, start_time: time, end_time: time):
        LocalLogger().log_module_time(module_name, start_time, end_time)

    @staticmethod
    def get_module_times():
        return LocalLogger().module_times


class LocalLogger:
    """
    本地日志管理器，提供更加人性化的输出，支持控制台颜色打印
    """
    _instance = None
    logger = None
    module_times = []

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(LocalLogger, cls).__new__(cls)
            cls._init_logger(cls._instance)
        return cls._instance

    @staticmethod
    def _create_colored_formatter(formatter_type: str = 'console'):
        """创建带颜色的日志格式器"""
        format_str = '%(asctime)s [%(levelname)-s] [%(module)-s/%(funcName)s:%(lineno)-d]: %(message)s'
        if formatter_type != 'console':
            return logging.Formatter(format_str)
        try:
            from colorlog import ColoredFormatter
            formatter = ColoredFormatter(
                f"%(log_color)s {format_str}",
                reset=True,
                log_colors={
                    'DEBUG': 'cyan',
                    'INFO': 'green',
                    'WARNING': 'yellow',
                    'ERROR': 'red',
                    'CRITICAL': 'red,bg_white',
                }
            )
            return formatter
        except ImportError:
            # 如果colorlog不可用，使用普通格式
            return logging.Formatter(format_str)

    def log_module_time(self, module_name: str, start_time: time, end_time: time):
        diff_time = end_time - start_time
        self.logger.info(f"{module_name}耗时: {diff_time:.4f}s")
        self.module_times.append(f"模块 {module_name}耗时: {diff_time:.4f}s")

    def _init_logger(self):
        if self.logger is not None:
            return
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(self._create_colored_formatter())
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.ERROR)
        self.logger.addHandler(console_handler)
