
import sys
from pathlib import Path
import os
from collections import defaultdict
from typing import Optional, Dict
import pandas as pd
import re

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from config import config_data, TraceType, CATEGORY_MAPPING, ANON_NAME
from tracedbs import query_native_hook
from hidumper import read_showmap_2_df
from rule import find_response_field


def hex_to_decimal(hex_range):
    start_hex, end_hex = hex_range.split('-')
    start_dec = int(start_hex, 16)
    end_dec = int(end_hex, 16)
    return start_dec, end_dec


ADDR_LINE_PATTERN = re.compile(r'^(?P<addr_range>[0-9a-fA-F]+-[0-9a-fA-F]+)\s+')


def parse_smaps_blocks(text: str):
    """
    将 smaps 文本按内存段分块，每块包含地址行 + 后续属性行，直到空行或下一个地址行。
    返回列表：每个元素是 (addr_line, properties_dict)
    """
    blocks = []
    current_block_lines = []

    # 地址行正则（用于识别新块开始）

    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        if not line:
            i += 1
            continue

        # 如果是地址行，开始新块
        if ADDR_LINE_PATTERN.match(line):
            # 保存上一个块（如果有）
            if current_block_lines:
                blocks.append('\n'.join(current_block_lines))
                current_block_lines = []
            current_block_lines.append(line)
        else:
            # 非地址行，属于当前块
            current_block_lines.append(line)
        i += 1

    # 添加最后一个块
    if current_block_lines:
        blocks.append('\n'.join(current_block_lines))

    return blocks


PROC_SMAPS_PATTERN = re.compile(r"""
    ^(?P<addr_range>[0-9a-fA-F]+-[0-9a-fA-F]+)   # 地址范围
    \s+(?P<perms>\S+)                           # 权限
    \s+(?P<offset>\S+)                          # 偏移
    \s+(?P<dev>\S+)                             # 设备号
    \s+(?P<inode>\d+)                           # inode（十进制）
    (?:\s+(?P<pathname>.+))?                    # 可选 pathname（文件路径或 [anon:…]）
    $""",
    re.VERBOSE,)

def extract_vma_info(block: str) -> Optional[Dict]:
    """
    从一个内存段 block 中提取结构化信息。
    返回 dict 或 None（如果无效）。
    """
    lines = block.splitlines()
    if not lines:
        return None

    # 解析第一行：地址范围
    addr_match = re.match(ADDR_LINE_PATTERN, lines[0])
    if not addr_match:
        return None
    address = addr_match.group("addr_range")
    name_match = re.match(PROC_SMAPS_PATTERN, lines[0])
    start_hex, end_hex = address.split('-')
    start = int(start_hex, 16)
    end = int(end_hex, 16)
    name = None
    if name_match:
        line_name = name_match.group("pathname")
        name = line_name.strip() if line_name else None

    # 初始化结果
    info = {
        'start': start,
        'end': end,
        'start_hex': start_hex,
        'end_hex': end_hex,
        'Name': name,
        'Size': None,
        'Pss': None,
        'SwapPss': None
    }

    # 解析后续行
    for line in lines[1:]:
        line = line.strip()
        if not line:
            continue

        # 匹配 Name: ...
        if line.startswith('Name:'):
            info['Name'] = line[5:].strip()
        elif line.startswith('Size:'):
            # 提取数字（忽略单位）
            val = re.search(r'(\d+)', line)
            info['Size'] = int(val.group(1)) if val else 0
        elif line.startswith('Pss:'):
            val = re.search(r'(\d+)', line)
            info['Pss'] = int(val.group(1)) if val else 0
        elif line.startswith('SwapPss:'):
            val = re.search(r'(\d+)', line)
            info['SwapPss'] = int(val.group(1)) if val else 0
        elif line.startswith('Rss'):
            val = re.search(r'(\d+)', line)
            info['Rss'] = int(val.group(1)) if val else 0

    return info


def build_vma_list(smaps_text: str):
    """构建 VMA 信息列表"""
    blocks = parse_smaps_blocks(smaps_text)
    vmas = []
    for block in blocks:
        info = extract_vma_info(block)
        if info:
            vmas.append(info)
    return vmas


def find_vma_by_address(vmas, target, offset):
    """
    输入一个十六进制地址字符串（如 "5b9b753000"），
    返回匹配的 VMA 的 Name, Size, Pss, SwapPss。
    """
    start = target
    end = target + offset
    for vma in vmas:
        if end <= vma['start'] or start >= vma['end']:
            continue
        return {
            'Name': vma['Name'],
            'Size': vma['Size'],
            'Pss': vma['Pss'],
            'Rss': vma['Rss'],
            'SwapPss': vma['SwapPss'],
            'end_hex': vma['end_hex'],
            'start_hex': vma['start_hex'],
        }
    return None

def map_smaps(smaps_file, mmap_data):
    res = []
    try:
        with open(smaps_file, encoding="utf-16") as file:
            smaps_text = file.read()
    except BaseException as e:
        with open(smaps_file) as file:
            smaps_text = file.read()
    _vmas = build_vma_list(smaps_text)
    if not _vmas:
        print(f"  [警告] smaps 文件无有效 VMA 数据，跳过混合模式: {smaps_file}")
        return mmap_data
    addr_total_heap_size = {}
    for data in mmap_data:
        addr = data["addr"]
        offset = data["heap_size"]
        result = find_vma_by_address(_vmas, addr, offset)
        if result:
            data["Name"] = result['Name'] if result['Name'] else ANON_NAME
            data["Size"] = result['Size']
            data["Pss"] = result['Pss']
            data["Rss"] = result['Rss']
            data["SwapPss"] = result['SwapPss']
            data["start_hex"] = result["start_hex"]
            data["end_hex"] = result["end_hex"]
            data["Calculated_Pss"] = min(data["heap_size"] / 1024 / data["Size"], 1) * data["Pss"]
            addr_key = (result["start_hex"], result["end_hex"])
            if addr_key not in addr_total_heap_size:
                addr_total_heap_size[addr_key] = 0
            addr_total_heap_size[addr_key] += data["heap_size"]
            res.append(data)
    for item in res:
        addr_key = (item["start_hex"], item["end_hex"])
        item["Calculated_Pss2"] = round(item["heap_size"] / addr_total_heap_size[addr_key] * item["Pss"], 2)
        item["Calculated_Rss"] = round(item["heap_size"] / addr_total_heap_size[addr_key] * item["Rss"], 2)
    return res


def is_frame_invalid(frame):
    return False


def filter_anno(anno_data):
    res = []
    for item in anno_data:
        frames = item["frames"]
        invalid = any(is_frame_invalid(frame) for frame in frames)
        if not invalid:
            res.append(item)
    return res

def add_anno_data(anno_file, callchains):
    print("添加混合模式数据")
    startts = config_data["startts"]
    endts = config_data["endts"]
    anno_data = query_native_hook(config_data["htrace_dir"], event_types=['MmapEvent'], startts=startts, endts=endts, aggregate=False)
    anno_data = filter_anno(anno_data)
    if not anno_data:
        return
    # 检查 smaps 文件是否有效（无有效 VMA 时跳过混合模式）
    try:
        with open(anno_file, encoding="utf-16") as f:
            smaps_text = f.read()
    except BaseException:
        with open(anno_file) as f:
            smaps_text = f.read()
    _vmas = build_vma_list(smaps_text)
    if not _vmas:
        print(f"  [警告] smaps 文件无有效 VMA 数据，跳过混合模式: {anno_file}")
        return
    anno_data = map_smaps(anno_file, anno_data)
    showmap_df = read_showmap_2_df(Path(config_data["showmap"]))
    showmap_df_filtered = showmap_df[~showmap_df['Category'].isin(["native heap", "ark ts heap"])]
    unique_mapping = showmap_df_filtered.drop_duplicates(subset='Name')[['Name', 'Category']]
    name_to_category = dict(zip(unique_mapping['Name'], unique_mapping['Category']))
    for item in anno_data:
        item["Category"] = name_to_category.get(item["Name"])
    anno_data = [x for x in anno_data if x["Category"] is not None]
    df = pd.DataFrame(anno_data)
    df.to_excel(os.path.join(config_data["output_path"], f"混合模式明细-{config_data['scene']}.xlsx"), index=False)

    # 将callchain_id相同的项进行聚合
    aggregated_data = defaultdict(lambda: {
        "pid": None,
        "process_name": None,
        "callchain_id": None,
        "ts": None,
        "type": None,
        "heap_size": 0,
        "frames": None,
        "apply_count": 0,
        "release_count": 0,
        "apply_size": 0,
        "release_size": 0,
        "filed": None
    })
    for item in anno_data:
        callchain_id = item["callchain_id"]
        aggregated_data[callchain_id]["heap_size"] += (item["Calculated_Rss"] * 1024)
        # aggregated_data[callchain_id]["heap_size"] += (item["SwapPss"] * 1024 if "SwapPss" in item else 0)
        if aggregated_data[callchain_id]["frames"] is None:
            aggregated_data[callchain_id]["frames"] = item["frames"]
            aggregated_data[callchain_id]["pid"] = item["pid"]
            aggregated_data[callchain_id]["process_name"] = item["process_name"]
            aggregated_data[callchain_id]["callchain_id"] = item["callchain_id"]
        if aggregated_data[callchain_id]["ts"] is None:
            aggregated_data[callchain_id]["ts"] = item["ts"]
            aggregated_data[callchain_id]["type"] = CATEGORY_MAPPING.get(item["Category"], TraceType.OTHER.name)
        else:
            aggregated_data[callchain_id]["ts"] = max(aggregated_data[callchain_id]["ts"], item["ts"])
        aggregated_data[callchain_id]["apply_count"] += 1

    for item in aggregated_data.values():
        if item["type"] == TraceType.HAP.name or item["type"] == TraceType.TTF.name or item["type"] == TraceType.SO_SIZE.name:
            continue
        response_field = find_response_field(item)
        item['field'] = {
            "response_so": response_field[3],
            "firstkind": response_field[0],
            "secondkind": response_field[1],
            "thirdkind": response_field[2]
        }
        callchains.append(item)
