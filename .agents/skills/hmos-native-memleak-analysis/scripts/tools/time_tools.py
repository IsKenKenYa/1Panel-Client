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
import re
from datetime import datetime, timedelta
from typing import Optional

from tools.logger_manager import LogManager

logger = LogManager.create_logger()

FORMAT_STR = '%Y-%m-%d %H:%M:%S'
TIME_PATTERNS = [
    # 2025/05/21-07:55:59:553
    {
        'regex': r'^(\d{4})/(\d{2})/(\d{2})-(\d{2}):(\d{2}):(\d{2}):(\d{3})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second', 'micro')
    },
    # 2025/05/21-07:56:00
    {
        'regex': r'^(\d{4})/(\d{2})/(\d{2})-(\d{2}):(\d{2}):(\d{2})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second')
    },
    # 2025-05-20 08:04:51:754
    {
        'regex': r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}):(\d{3})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second', 'micro')
    },
    # 2025-05-20 08:04:53
    {
        'regex': r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second')
    },
    # 2025-05-19 12:35:46.610
    {
        'regex': r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}).(\d{3})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second', 'micro')
    },
    # 2025-07-01-21-46-57.509059
    {
        'regex': r'^(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2}).(\d+)$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second', 'micro')
    },
    # 20250701-214657
    {
        'regex': r'^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second', 'micro')
    },
    # 20250701214657
    {
        'regex': r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second')
    },
    # 20250701214657
    {
        'regex': r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d+)$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second', 'micro')
    },
    # 2025/05/21 07:56:00
    {
        'regex': r'^(\d{4})/(\d{2})/(\d{2}) (\d{2}):(\d{2}):(\d{2})$',
        'groups': ('year', 'month', 'day', 'hour', 'minute', 'second')
    },
]


def convert_to_datetime(date_str: str) -> Optional[datetime]:
    """
    :param date_str:str 时间字符串
    :return datetime 时间对象,未匹配到或异常时返回空值
    """
    for pattern in TIME_PATTERNS:
        match = re.fullmatch(pattern['regex'], date_str)
        if not match:
            continue
        components = {k: int(v) for k, v in zip(pattern['groups'], match.groups())}
        if 'micro' in components:
            # 确保微秒值不溢出
            microsecond = components['micro']
            if microsecond < 999:
                microsecond *= 1000
        else:
            microsecond = 0
        try:
            return datetime(
                year=components['year'],
                month=components['month'],
                day=components['day'],
                hour=components['hour'],
                minute=components['minute'],
                second=components['second'],
                microsecond=microsecond
            )
        except ValueError:
            # 时间组件非法时跳过该模式
            continue
    return None


def convert_date_to_str(date: datetime, format_str: str = FORMAT_STR) -> str:
    """将时间转为指定格式的字符串"""
    if not date:
        logger.warning('convert_date_to_str, date object is None')
        return ''
    try:
        format_str = date.strftime(format_str)
        return format_str
    except Exception as e:
        logger.warning(f'convert_date_to_str fail ,{e}')
        return ''


def format_datetime_str(date_str: str, format_str: str = FORMAT_STR):
    """将时间字符串转为指定格式的字符串"""
    date = convert_to_datetime(date_str)
    return convert_date_to_str(date, format_str)


def convert_timestamp_ms_to_date(timestamp_ms: str) -> Optional[datetime]:
    """
    将ms级时间戳转为date对象
    :param timestamp_ms: str 时间戳字符串
    :return datetime: 时间对象,未匹配到或异常时返回空值
    """
    try:
        timestamp_s = int(timestamp_ms) // 1000
        return datetime.fromtimestamp(timestamp_s)
    except ValueError:
        pass
    return None


def convert_timestamp_to_date_str(timestamp: str) -> str:
    """
    将ms级时间戳转为date对象
    :param timestamp: str 时间戳字符串
    :return str: 格式化的时间
    """
    try:
        timestamp = int(timestamp)
        date = datetime.fromtimestamp(timestamp)
        return convert_date_to_str(date)
    except ValueError:
        pass
    return ''


def convert_english_time_to_str(english_time_str: str) -> str:
    """将英文时间转为中文字符串"""
    if not english_time_str:
        return ''
    format_time = ''
    try:
        format_str = "%a %b %d %H:%M:%S %Y"  # 匹配时间戳格式
        time = datetime.strptime(english_time_str, format_str)
        format_time = convert_date_to_str(time)
    except Exception as e:
        logger.error(f'日期格式化失败{e}')
    return format_time


def add_second_to_date(date: datetime, second: int) -> Optional[datetime]:
    """
    增加或减少指定秒数
    :param date: datetime 时间对象
    :param second: int 增加的秒数
    """
    if not date:
        logger.error('add_second_to_date, date object is None')
        return None
    if second > 0:
        target_date = date + timedelta(seconds=second)
    else:
        target_date = date - timedelta(seconds=abs(second))
    return target_date


def object_format_datetime(obj):
    """
    :param obj: 输入一个对象
    :return:对目标对象所有datetime类型的属性格式化
    """
    for attr in dir(obj):
        value = getattr(obj, attr)
        if isinstance(value, datetime):
            setattr(obj, attr, value.strftime('%Y-%m-%d %H:%M:%S'))
    return obj


def list_format_datetime(lst):
    """
    :param lst: 输入一个嵌套对象的列表
    :return: 对目标列表中所有对象的datetime类型的属性格式化
    """
    for obj in lst:
        for attr in dir(obj):
            value = getattr(obj, attr)
            if isinstance(value, datetime):
                setattr(obj, attr, value.strftime('%Y-%m-%d %H:%M:%S'))
    return lst


def format_datetime_dict_list(dicts):
    """
    递归遍历嵌套字典，并将 datetime 值转换为字符串格式

    :param dicts: 输入一个嵌套字典的列表
    :return: 对目标列表中所有字典的datetime类型的属性格式化
    """
    result = []

    for item in dicts:
        new_item = {}
        for k, v in item.items():
            if isinstance(v, dict):
                # 递归遍历子字典
                new_item[k] = format_datetime_dict_list([v])[0]
            elif isinstance(v, datetime):
                # 如果值是 datetime 类型，则格式化为字符串
                new_item[k] = v.strftime('%Y-%m-%d %H:%M:%S')
            else:
                # 否则保留原始值
                new_item[k] = v
        result.append(new_item)

    return result


def get_formated_time():
    """获取格式化的时间字符串 yyyy-MM-dd HH:mm:ss:SSS"""
    now = datetime.now()
    # 获取毫秒部分
    milliseconds = now.microsecond // 1000
    # 格式化时间
    return now.strftime("%Y-%m-%d %H:%M:%S") + f":{milliseconds:03d}"
