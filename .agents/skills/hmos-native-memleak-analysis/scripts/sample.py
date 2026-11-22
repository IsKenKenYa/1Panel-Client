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
import argparse
import re
from datetime import datetime
from typing import List, Optional

import dill

from tools.common_tools import print_table_info
from tools.time_tools import convert_to_datetime


class SampleInfo:
    """sample文件对象实体类映射"""

    def __init__(self):
        self.leak_type = []
        self.pid = ''
        self.process_name = ''
        self.soft_threshold: float = 0.0
        self.fault_time: Optional[datetime] = None
        self.mem_list = []
        self.rate_dict = {}
        self.total_pss: float = 0.0
        self.total_memory: float = 0.0

    def __str__(self):
        flag = False
        count = 0
        title = [('PSS(KB)', 'SwapPSS(KB)', 'TotalPSS(KB)', 'ION(KB)', 'GPU(KB)', 'TotalMem(KB)', 'Realtime')]
        leak_list = []
        for mem in self.mem_list[::-1]:
            if mem.is_leak_time:
                flag = True
                leak_list.append(
                    (mem.pss, mem.swap_pss, mem.total_pss, mem.ion, mem.gpu, mem.total_mem, '*' + mem.realtime))
                count += 1
            if flag and not mem.is_leak_time:
                leak_list.append((mem.pss, mem.swap_pss, mem.total_pss, mem.ion, mem.gpu, mem.total_mem, mem.realtime))
                count += 1
            if count >= 15:
                break
        title.extend(leak_list[::-1])
        leak_type_rate = [('类型', '内存（KB）', '占比')]
        for key, value in self.rate_dict.items():
            leak_type_rate.append((f'{key}', f'{value[1]:.0f}', f'{value[0] * 100:.2f}%'))
        return 'Sample信息如下：\n' + print_table_info(title) + '\n' + f'泄露类型占比：\n' + print_table_info(
            leak_type_rate)

    def build(self, context: List[str]):
        for index, line in enumerate(context):
            self.basic_info_build(line)
        self.sample_info_build(context)
        self.get_total_pss()

    def basic_info_build(self, line: str):
        pid_match = re.search(r'pid:\s+(?P<pid>\d+)', line)
        if pid_match:
            self.pid = pid_match.group('pid')
        process_name_match = re.search(r'processName:\s+(?P<process_name>[0-9A-Za-z_.]+)', line)
        if process_name_match:
            self.process_name = process_name_match.group('process_name')
        soft_threshold_match = re.search(r'SoftThreshold:\s+(?P<soft_threshold>\d+)\((?P<unit>\w+)\)', line)
        if soft_threshold_match:
            soft_threshold = float(soft_threshold_match.group('soft_threshold'))
            if soft_threshold_match.group('unit') == 'MB':
                self.soft_threshold = soft_threshold * 1024
            else:
                self.soft_threshold = soft_threshold

    def get_total_pss(self):
        if not self.mem_list:
            pass
        for mem_info in self.mem_list[::-1]:
            if mem_info.is_leak_time:
                self.fault_time = convert_to_datetime(mem_info.realtime)
                if mem_info.total_mem:
                    self.total_memory = float(mem_info.total_mem) if mem_info.total_mem else float(mem_info.total_pss)
                    self.total_pss = float(mem_info.total_pss)
                    self.rate_dict['pss'] = (float(mem_info.total_pss) / float(mem_info.total_mem),
                                             float(mem_info.total_pss))
                    if mem_info.ion.isdigit():
                        self.rate_dict['ion'] = (float(mem_info.ion) / float(mem_info.total_mem), float(mem_info.ion))
                    if mem_info.gpu.isdigit():
                        self.rate_dict['gpu'] = (float(mem_info.gpu) / float(mem_info.total_mem), float(mem_info.gpu))
                    break
                else:
                    self.total_memory = float(mem_info.total_pss)
                    self.total_pss = float(mem_info.total_pss)
                    self.rate_dict['pss'] = (1.0, float(mem_info.total_pss))
        if not self.fault_time:
            raise Exception('未在sample文件中找到泄露时间点')
        sorted_rate = sorted(self.rate_dict.items(), key=lambda item: item[1][0], reverse=True)
        rate_ = len(sorted_rate) * 2
        # 获取所有大于1/2n的泄露类型，n为采样内存的个数
        sorted_rate_ = sorted_rate
        self.leak_type = [rate[0] for rate in sorted_rate_ if rate[1][0] * rate_ > 1]

    def sample_info_build(self, context: List[str]):
        start_index = 0
        for index, line in enumerate(context):
            if re.search(r'Index\s+RSS\(KB\)', line):
                start_index = index
                break
        index_line = context[start_index].replace('Running Time', 'RunningTime')
        member_str_list = index_line.split()
        member_index_dict = dict()
        sample_info_dict = {'Index': 'index',
                            'RSS(KB)': 'rss',
                            'Offset(KB)': 'offset',
                            'PSS(KB)': 'pss',
                            'SwapPSS(KB)': 'swap_pss',
                            'TotalPSS(KB)': 'total_pss',
                            'MediaMem(KB)': 'media_mem',
                            'AvcMem(KB)': 'avc_mem',
                            'ION(KB)': 'ion',
                            'GPU(KB)': 'gpu',
                            'TotalMem(KB)': 'total_mem',
                            'Level': 'level',
                            'RunningTime(s)': 'running_time',
                            'Realtime': 'realtime'}
        for index, member_str in enumerate(member_str_list):
            if member_str in sample_info_dict:
                member_index_dict[sample_info_dict[member_str]] = index
        for line in context[start_index + 1:]:
            member_list = re.split(r'\s{3,}', line.strip())
            mem_info = MemInfo()
            for member in member_index_dict.keys():
                index = member_index_dict[member]
                if member == 'realtime':
                    if '*' in member_list[index]:
                        setattr(mem_info, 'is_leak_time', True)
                    setattr(mem_info, member, member_list[index].replace('*', ''))
                else:
                    setattr(mem_info, member, member_list[index])
            self.mem_list.append(mem_info)


class MemInfo:
    def __init__(self):
        self.rss = ''
        self.offset = ''
        self.pss = ''
        self.swap_pss = ''
        self.total_pss = ''
        self.media_mem = ''
        self.avc_mem = ''
        self.ion = ''
        self.gpu = ''
        self.total_mem = ''
        self.level = ''
        self.running_time = ''
        self.realtime = ''
        self.is_leak_time = False


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True, help="文件路径")
    args = parser.parse_args()
    with open(args.path, 'r', encoding='utf-8', errors='ignore') as file:
        context_ = file.readlines()
        sample_info = SampleInfo()
        sample_info.build(context_)
        print(sample_info.__str__())
        # 存储对象
        sample_obj_path = args.path.replace('.txt', '.pkl')
        with open(sample_obj_path, 'wb') as f:
            dill.dump(sample_info, f)
