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

import dill

from common.enum.common_enum import NativeMemoryType
from tools.common_tools import print_table_info


def _parse_bin(native_leak):
    details = native_leak.mem_check_detial_info
    sorted_items = sorted(details.bin_list + details.large_list, key=lambda item: item.allocated, reverse=True)
    if not sorted_items:
        return ''
    rows = [('size(B)', 'allocated(B)', 'rate')]
    for info in sorted_items[:3]:
        rate = '{:.2f}%'.format(float(info.allocated) * 100 / details.total_allocated)
        rows.append((info.size, info.allocated, rate))
        native_leak.nmd_set.add(info.size)
    return print_table_info(rows)


def _parse_top_nmd_use(native_leak):
    allocated_map = native_leak.mem_check_nmd_info.nmd_map2
    top_items = sorted(allocated_map.items(), key=lambda item: item[1], reverse=True)[:3]
    total_size = sum(allocated_map.values())
    rows = [('size(B)', 'allocated(B)', 'rate')]
    for size, allocated in top_items:
        rate = '{:.2f}%'.format((float(allocated) / total_size) * 100)
        rows.append((size, allocated, rate))
        native_leak.nmd_set.add(size)
    return print_table_info(rows)


def _parse_top_nmd_change(native_leak):
    before = native_leak.mem_check_nmd_info.nmd_map1
    after = native_leak.mem_check_nmd_info.nmd_map2
    if not before or not after:
        return ''
    changes = {size: allocated - before.get(size, 0) for size, allocated in after.items()}
    top_items = sorted(changes.items(), key=lambda item: item[1], reverse=True)[:3]
    rows = [('size(B)', 'allocated(B)', '增长内存')]
    for size, change in top_items:
        rows.append((f'{size}', f'{after[size]}', f'{change}'))
        native_leak.nmd_set.add(size)
    return print_table_info(rows)


def get_jemalloc_leak_info(native_leak):
    top3_nmd_use = _parse_top_nmd_use(native_leak)
    top3_nmd_change = _parse_top_nmd_change(native_leak)
    bin_str = _parse_bin(native_leak)
    nmd_info = ''
    if top3_nmd_use:
        nmd_info += f'堆内存快照占用Top3 size：\n' + top3_nmd_use
    if top3_nmd_change:
        nmd_info += f'堆内存增长Top3 size：\n' + top3_nmd_change
    if bin_str:
        nmd_info += '堆内存快照占用Top3 size：\n' + bin_str
    return nmd_info


def get_ashmem_leak_info(native_leak):
    pss = native_leak.rate_dict[NativeMemoryType.ASHMEM_LEAK]['pss']
    ashmem_list = native_leak.rate_dict[NativeMemoryType.ASHMEM_LEAK]['swap_list']
    sorted_ashmem_list = sorted(ashmem_list, key=lambda x: x.pss + x.swap_pss, reverse=True)
    info = ''
    total_rate = 0
    for swap_info in sorted_ashmem_list:
        rate = ((swap_info.pss + swap_info.swap_pss) / pss)
        handle_name = swap_info.name.split(':')[-1]
        info += f'ashmem内存块：{handle_name} 占比：{rate :.2f}%\n'
        total_rate += rate
        if total_rate >= 0.5:
            break
    return info


def get_arkts_leak_info():
    return '抓取heapsnapshot进一步分析arkts内存占用'


def get_anon_leak_info():
    return ''


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True, help="文件路径")
    parser.add_argument("-t", "--type", required=True, help="泄漏类型")
    args = parser.parse_args()
    native_path = args.path.replace('.txt', '.pkl')
    sample_path = native_path.replace('smaps', 'sample')
    with open(native_path, 'rb') as f:
        native_obj_ = dill.load(f)
    with open(sample_path, 'rb') as f:
        sample_obj_ = dill.load(f)
    if args.type == 'jemalloc':
        info_ = get_jemalloc_leak_info(native_obj_)
    elif args.type == 'ashmem':
        info_ = get_ashmem_leak_info(native_obj_)
    elif args.type == 'arkts':
        info_ = get_arkts_leak_info()
    elif args.type == 'anon':
        info_ = get_anon_leak_info()
    else:
        info_ = '未知的泄漏类型'
    with open(native_path, 'wb') as f:
        dill.dump(native_obj_, f)
    print(info_)
