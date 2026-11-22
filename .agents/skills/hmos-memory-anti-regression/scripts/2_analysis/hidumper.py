
import sys
from pathlib import Path
import re
import random

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from config import TraceType, MAX_INT
from so_field import lookup


def add_so_data(file, res):
    with open(file, encoding="utf-8") as _f:
        lines = _f.readlines()

    # Detect format: scan for a data line to check column count
    sample_cols = None
    for line in lines:
        parts = line.strip().split()
        if not parts or len(parts) < 2 or parts[-2] == 'Category':
            continue
        try:
            int(parts[2])  # Pss column must be numeric
            sample_cols = len(parts)
            break
        except (ValueError, IndexError):
            continue

    if sample_cols is not None and sample_cols < 10:
        print(f"  [警告] add_so_data: 文件 {file} 只有 {sample_cols} 列（hidumper --mem 汇总格式），"
              f"无法解析逐SO数据。--showmap 参数应传入 hidumper --mem-smaps 输出（12列格式）。"
              f"SO_SIZE/HAP/TTF 数据将缺失。")

    for line in lines:
        line = line.strip().split()
        if len(line) != 12 or line[-2] == 'Category':
            continue
        # Use Pss + Swap (line[2] + line[7]) to match meminfo.xlsx units
        size = (int(line[1]) + int(line[7])) * 1024
        category = line[-2]
        name = line[-1]
        new_name = name
        if category == '.so':
            if name.startswith("/data/storage"):
                new_name = '/proc/' + name
            response_field = lookup.find_field(new_name)
            if response_field:
                res.append({
                    'heap_size': size,
                    'type': 'SO_SIZE',
                    'callchain_id': -1 * random.randint(1, MAX_INT),
                    'field': {"response_so": response_field[3], "firstkind": response_field[0],
                              "secondkind": response_field[1], "thirdkind": response_field[2]},
                    'frames': []
                })
            else:
                res.append({
                    'heap_size': size,
                    'type': 'SO_SIZE',
                    'callchain_id': -1 * random.randint(1, MAX_INT),
                    'field': {"response_so": name, "firstkind": '系统SDK',
                              "secondkind": 'others', "thirdkind": 'others'},
                    'frames': []
                })
        elif category == '.hap':
            res.append({
                'heap_size': size,
                'type': 'HAP',
                'callchain_id': -1 * random.randint(1, MAX_INT),
                'field': {"response_so": '/.hap', "firstkind": '三方自研代码',
                          "secondkind": '.HAP', "thirdkind": '.HAP'},
                'frames': [],

            })
        elif category == '.ttf':
            res.append({
                'heap_size': size,
                'type': 'TTF',
                'callchain_id': -1 * random.randint(1, MAX_INT),
                'field': {"response_so": '/.ttf', "firstkind": '系统SDK',
                          "secondkind": 'Graphic', "thirdkind": 'Graphic'},
                'frames': [],

            })


def add_web_data(file, res):
    with open(file, encoding="utf-8") as _f:
        lines = _f.readlines()
    for line in lines:
        line = line.strip().split()
        if len(line) < 12 or line[-2] == 'Category':
            continue
        if line[-1] != "[anon:partition_alloc]":
            continue
        size = (int(line[1]) + int(line[7])) * 1024
        res.append({
            'heap_size': size,
            'type': TraceType.ANON_PAGE_OTHER.name,
            'callchain_id': -1 * random.randint(1, MAX_INT),
            'field': {
                "response_so": "partition_alloc",
                "firstkind": 'WEB',
                "secondkind": 'WEB',
                "thirdkind": 'WEB'
            },
            'frames': [],
        })


def add_native_heap_data(file, res):
    with open(file, encoding="utf-8") as _f:
        lines = _f.readlines()
    for raw_line in lines:
        raw_line = raw_line.strip()
        if not raw_line or 'Category' in raw_line:
            continue
        # Match native_heap entries by substring (Name may contain spaces)
        if '[anon:native_heap:brk]' not in raw_line \
                and '[anon:native_heap:jemalloc meta]' not in raw_line \
                and '[anon:native_heap:meta]' not in raw_line \
                and '[anon:native_heap:mmap]' not in raw_line:
            continue
        # Parse numeric fields from the beginning of the line
        parts = raw_line.split()
        try:
            rss = int(parts[1])
            swap = int(parts[7])
        except (ValueError, IndexError):
            continue
        size = (rss + swap) * 1024
        if '[anon:native_heap:brk]' in raw_line:
            res.append({
                'heap_size': size,
                'type': TraceType.NATIVE_HEAP.name,
                'callchain_id': None,
                'field': {
                    "response_so": "[anon:native_heap:brk]",
                    "firstkind": '语言运行时',
                    "secondkind": 'C运行时',
                    "thirdkind": 'C Runtime'
                },
                'frames': [],
            })
        elif '[anon:native_heap:jemalloc meta]' in raw_line:
            res.append({
                'heap_size': size,
                'type': TraceType.NATIVE_HEAP.name,
                'callchain_id': None,
                'field': {
                    "response_so": "[anon:native_heap:jemalloc meta]",
                    "firstkind": '语言运行时',
                    "secondkind": '分配器',
                    "thirdkind": 'Distributor'
                },
                'frames': [],
            })
        elif '[anon:native_heap:meta]' in raw_line:
            res.append({
                'heap_size': size,
                'type': TraceType.NATIVE_HEAP.name,
                'callchain_id': None,
                'field': {
                    "response_so": "[anon:native_heap:meta]",
                    "firstkind": '语言运行时',
                    "secondkind": 'C运行时',
                    "thirdkind": 'C Runtime'
                },
                'frames': [],
            })
        elif '[anon:native_heap:mmap]' in raw_line:
            res.append({
                'heap_size': size,
                'type': TraceType.NATIVE_HEAP.name,
                'callchain_id': None,
                'field': {
                    "response_so": "[anon:native_heap:mmap]",
                    "firstkind": '语言运行时',
                    "secondkind": 'C运行时',
                    "thirdkind": 'C Runtime'
                },
                'frames': [],
            })

def read_showmap_2_df(file_path: Path):
    lines = file_path.read_text(encoding="utf-8", errors="ignore").splitlines()
    data_lines = [line for line in lines if
                  line.strip()
                  and (not line.startswith("-"))
                  and ("Summary" not in line)
                  and ("anon_inode:dev/ashmem/hooknativesmb" not in line)]
    rows = [re.split(r"\s{2,}", line.strip()) for line in data_lines]

    header_idx = None
    for i, r in enumerate(rows):
        if any(h in r for h in ("Category", "Rss", "Swap")):
            header_idx = i
            break
    if header_idx is None:
        raise Exception(f"dynamic_showmap 文件格式不正确：{file_path.name}")

    header = rows[header_idx]
    # Skip additional header rows (e.g. "Total Clean Dirty..." / "( kB )...")
    # by advancing past rows whose 2nd element is non-numeric.
    data_start = header_idx + 1
    while data_start < len(rows):
        r = rows[data_start]
        if len(r) > 1:
            try:
                float(str(r[1]).replace(",", ""))
                break
            except (ValueError, TypeError):
                data_start += 1
        else:
            data_start += 1
    data = rows[data_start:]
    # Prepend "Category" if data rows have one more column than header
    if data and len(header) < len(data[0]):
        header = ["Category"] + header

    _df = pd.DataFrame(data, columns=header)
    return _df
