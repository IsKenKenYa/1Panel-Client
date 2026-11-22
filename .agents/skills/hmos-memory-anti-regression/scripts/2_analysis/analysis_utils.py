
import sys
from pathlib import Path
import json
import logging
import re
import threading
import time
from collections import OrderedDict
from datetime import datetime, date
from functools import wraps
import sys
try:
    import psutil
except ImportError:
    psutil = None
import os

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from config import config_data

logger = logging.getLogger(__name__)

meminfo_pattern = re.compile(r"(\d{8}-\d{6})")
showmap_pattern = re.compile(r"^(?P<process_name>.+?)_(?P<pid>\d+)_(?P<time>\d{8}-\d{6})_(?P<suffix>.+)$")


def sort(data, inner_map_key):
    sorted_data = {}

    # 先对每个 item 的 so map 排序
    for key, value in data.items():
        so_map = value.get(inner_map_key, {})
        sorted_so = dict(
            sorted(so_map.items(), key=lambda kv: kv[1].get("size", 0), reverse=True)
        )
        value[inner_map_key] = sorted_so
        sorted_data[key] = value

    # 再对最外层按 size 排序
    sorted_outer = OrderedDict(
        sorted(sorted_data.items(), key=lambda kv: kv[1].get("size", 0), reverse=True)
    )
    return sorted_outer


class OpFileUtil:
    pattern = re.compile(r'time:(\d{8}-\d{6}).*')

    @staticmethod
    def get_operation(text):
        return text.split('operation:')[-1].strip()

    @classmethod
    def get_time(cls, text):
        match = cls.pattern.search(text)
        if match:
            return match.group(1)
        return None


def parse(t):
    return datetime.strptime(t, "%Y%m%d-%H%M%S")


def setup_logger(level: str):
    # 将字符串转换成 logging 模块的级别
    numeric_level = getattr(logging, level.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError(f"Invalid log level: {level}")

    logging.basicConfig(
        level=numeric_level,
        format="%(asctime)s [%(levelname)s] %(message)s"
    )

def parse_android_meminfo_filename(filename: str):
    """
    - process_name
    - time_str
    - suffix
    """
    # 查找时间字段
    m = meminfo_pattern.search(filename)
    if not m:
        raise Exception("文件名字格式不正确： {}".format(filename))

    time_str = m.group(1)

    # 时间的起止位置
    start, end = m.span()

    suffix = filename[end + 1:]

    # 从 prefix 中提取 process_name：时间前的那个字段
    # 例如：dumpMem_tv.danmaku.bili_20251129 → prefix="dumpMem_tv.danmaku.bili_"
    first_underscore = filename.find("_")
    process_name = filename[first_underscore + 1: start]
    process_name = process_name.rstrip("_")
    return process_name, time_str, suffix


# noinspection DuplicatedCode
def parse_harmonyos_showmap_filename(filename: str):
    """
    - process_name
    - pid
    - time_str
    - suffix
    """
    m = showmap_pattern.match(filename)
    if not m:
        raise Exception("文件名字格式不正确： {}".format(filename))
    process_name = m.group("process_name")
    pid = m.group("pid")
    time = m.group("time")
    suffix = m.group("suffix")
    return process_name, pid, time, suffix


def parse_harmonyos_meminfo_filename(filename: str):
    """
    - process_name
    - time_str
    - suffix
    """
    # 查找时间字段
    m = meminfo_pattern.search(filename)
    if not m:
        raise Exception("文件名字格式不正确，不包含时间： {}".format(filename))

    time_str = m.group(1)

    # 时间的起止位置
    start, end = m.span()
    suffix = filename[end + 1:]

    return time_str, suffix


def add_test_info(df,diff_trace = False):
    _trace = str(config_data["trace"])
    if diff_trace:
        trace = _trace + '_'
    else:
        trace = _trace
    cols = list(df.columns)
    df = df.assign(
        test_version = config_data['version'],
        test_sn = config_data['sn'],
        test_date = config_data['date'],
        test_model = config_data['test_model'],
        test_scene_name = config_data["case"],
        test_scenario_info = config_data["case"],
        trace_path = trace
    )
    new_columns = ['test_version', 'test_sn', 'test_date', 'test_model', 'test_scene_name', 'test_scenario_info','trace_path'] + cols
    df = df[new_columns]
    return df


def add_heading(df):
    # 创建新行：列名作为值
    new_row = {col: col for col in df.columns}  # {'A': 'A', 'B': 'B'}
    new_df = pd.DataFrame([new_row])  # 转换为单行DataFrame
    # 插入到最前面并重置索引
    return pd.concat([new_df, df], ignore_index=True)


def dumper_rename(df):
    df.rename(columns={
        'test_version': '版本',
        'test_model': '测试模型',
        'test_date': '测试时间',
        'test_sn': '测试设备SN',
        'test_scene_name': '测试用例',
        'test_step': '测试步骤',
        'time': '时间',
    }, inplace=True)


def profiler_rename(df):
    df.rename(columns={
        'test_version': '版本',
        'test_model': '测试模型',
        'test_date': '测试时间',
        'test_sn': '测试设备SN',
        'test_scene_name': '测试用例',
        'test_step': '测试步骤',
        'first_domain': '一层领域',
        'second_domain': '二层领域',
    }, inplace=True)

def add_missing_columns(df):
    """
    将列表中不在 DataFrame 中的字段添加为新列，并填充 0。
    
    参数:
        df (pd.DataFrame): 原始 DataFrame。
    
    返回:
        pd.DataFrame: 添加新列后的 DataFrame。
    """
    column_list = ['test_version', 'test_model', 'test_date', 'test_sn', 'test_scene_name', 'test_scenario_info', 'test_step', 'time', 'db', 'hap', 'so', 'anonpage_other_arkts', 'anonpage_other_normal', 'anonpage_other_special', 'filepage_other_ashmem', 'filepage_other_normal', 'ark_ts_heap', 'dev', 'guard', 'native_heap', 'stack', 'gpu', 'ttf', 'dma_pixelmap', 'dma_web', 'dma_null', 'dma_xcomponent', 'total', 'so_jar', 'dma', 'other', 'total_gl', 'app_total_mem']
    existing_columns = set(df.columns)  # 获取现有列名集合
    for col in column_list:
        if col not in existing_columns:
            df[col] = 0  # 添加新列并填充 0
            existing_columns.add(col)  # 更新已存在列集合
    return df

def clean_string(s):
    # 匹配非字母、数字、下划线的字符，并替换为空字符串
    return s.replace('.', '').replace('(', '').replace(')', '').replace(' ', '_').replace('/', '_').replace('-', '_')


def clean_illegal_sign(s):
    pattern = re.compile(r'[^\w\u4e00-\u9fa5]+')

    # 替换为下划线
    processed_str = pattern.sub('_', s)

    return processed_str


def timing_decorator(description=None):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            result = func(*args, **kwargs)
            end_time = time.time()

            execution_time = end_time - start_time
            func_description = description if description else func.__name__
            print(f"功能: {func_description} | 执行时间: {execution_time:.6f} 秒")
            return result

        return wrapper

    return decorator


def normalize_for_excel(value):
    if isinstance(value, (int, float, str, bool)) or value is None:
        return value
    return str(value)


thread_local = threading.local()


class CustomKeyEncoder(json.JSONEncoder):
    def encode(self, obj):
        cleaned_obj = self._convert_keys(obj)
        return super().encode(cleaned_obj)

    def _convert_keys(self, obj):
        if isinstance(obj, dict):
            new_dict = {}
            for k, v in obj.items():
                new_k = self._serialize_key(k)
                new_v = self._convert_keys(v)
                new_dict[new_k] = new_v
            return new_dict
        elif isinstance(obj, (list, tuple)):
            return [self._convert_keys(item) for item in obj]
        else:
            return obj

    @staticmethod
    def _serialize_key(key):
        if isinstance(key, tuple):
            return "__tuple__" + json.dumps(key)
        elif isinstance(key, (date, datetime)):
            return "__date__" + key.isoformat()
        elif isinstance(key, bool):
            return str(key).lower()
        elif isinstance(key, (int, float)):
            return str(key)
        else:
            return str(key)


def check_memory_limit(max_memory_gb=16):
    """
    检查当前进程的内存使用是否超过指定上限（单位：GB）
    """
    if psutil is None:
        return
    process = psutil.Process(os.getpid())
    memory_usage_bytes = process.memory_info().rss  # 获取当前内存使用（字节）
    memory_usage_gb = memory_usage_bytes / (1024 ** 3)  # 转换为 GB

    if memory_usage_gb > max_memory_gb:
        print(f"[Memory Alert] 内存使用已超过 {max_memory_gb}GB！当前使用：{memory_usage_gb:.2f}GB")
        print("堆栈跟踪：")
        import traceback
        traceback.print_stack()  # 输出当前调用栈
        sys.exit(1)  # 终止程序


EXCLUDED_TYPE_NAMES = {
    "ArkTS Heap分配器碎片",
    "Native Heap分配器碎片&未覆盖",
    "Native Heap空服务",
    "Filepage Other分配器碎片",
    "AnonPage Other分配器碎片",
    "ArkTS Heap未覆盖",
    "GL分配器缓存",
    "其他",
    "(未命名)",
    "(未归因)",
    "dev分配器碎片",
    ".db分配器碎片",
    "ArkTS Heap空服务",
    "GL空服务",
    "guard空服务",
    "guard分配器碎片",
    "DMA空服务",
    "DMA分配器碎片",
    "AnonPage Other空服务",
    ".db空服务",
    "dev空服务",
    "Filepage Other空服务",
    "[anon:native_heap:brk]",
    "[anon:native_heap:meta]",
    "[anon:native_heap:jemalloc meta]",
    "[anon:native_heap:mmap]",
}


def _is_virtual_so(so_name):
    if not isinstance(so_name, str):
        return True
    return so_name in EXCLUDED_TYPE_NAMES

def _parse_mb(s):
    """Parse size string like '192.3MB' or raw float to MB float."""
    if isinstance(s, (int, float)):
        return float(s)
    if isinstance(s, str):
        m = re.search(r'([\d.]+)\s*MB', s, re.IGNORECASE)
        if m:
            return float(m.group(1))
        try:
            return float(s.replace('MB', '').strip())
        except ValueError:
            return 0.0
    return 0.0

def diff_top10_so(old_xlsx: str, new_xlsx: str, top_n: int = 10, min_delta_mb: float = 1.0) -> pd.DataFrame:
    df_old = pd.read_excel(old_xlsx)
    df_new = pd.read_excel(new_xlsx)

    so_col = "so"
    type_col = "type_name"
    size_col = "size"

    for df in (df_old, df_new):
        if so_col not in df.columns:
            for candidate in ("so", "SO", "so_name"):
                if candidate in df.columns:
                    df.rename(columns={candidate: so_col}, inplace=True)
                    break
        if type_col not in df.columns:
            for candidate in ("type_name", "typeName", "type"):
                if candidate in df.columns:
                    df.rename(columns={candidate: type_col}, inplace=True)
                    break
        if size_col not in df.columns:
            for candidate in ("size", "size_MB", "value"):
                if candidate in df.columns:
                    df.rename(columns={candidate: size_col}, inplace=True)
                    break

    # Forward-fill merged-cell NaN in 'so' column (xlsx merged cells read as NaN by pandas)
    for df in (df_old, df_new):
        df[so_col] = df[so_col].ffill()
    # Convert full paths to basename for grouping (e.g. /system/lib64/libx.so → libx.so)
    df_old[so_col] = df_old[so_col].apply(lambda x: os.path.basename(str(x)))
    df_new[so_col] = df_new[so_col].apply(lambda x: os.path.basename(str(x)))

    old_map = {}
    for _, row in df_old.iterrows():
        key = (row[so_col], row[type_col])
        old_map[key] = old_map.get(key, 0.0) + _parse_mb(row[size_col])

    new_map = {}
    for _, row in df_new.iterrows():
        key = (row[so_col], row[type_col])
        new_map[key] = new_map.get(key, 0.0) + _parse_mb(row[size_col])

    all_keys = set(old_map.keys()) | set(new_map.keys())
    rows = []
    for so, tn in all_keys:
        if _is_virtual_so(so):
            continue
        old_val = old_map.get((so, tn), 0.0)
        new_val = new_map.get((so, tn), 0.0)
        delta = new_val - old_val
        if delta == 0:
            continue
        rows.append({"so": so, "type_name": tn, "delta": delta})

    if not rows:
        return pd.DataFrame(columns=["so", "total_delta", "type_name_detail"])

    df_delta = pd.DataFrame(rows)

    so_delta_map = {}
    for _, r in df_delta.iterrows():
        so_delta_map.setdefault(r["so"], []).append((r["type_name"], r["delta"]))

    so_total = df_delta.groupby("so")["delta"].sum().reset_index()
    so_total.columns = ["so", "total_delta"]
    so_total = so_total[so_total["total_delta"] > min_delta_mb].reset_index(drop=True)

    detail_rows = []
    for so, entries in so_delta_map.items():
        detail = ", ".join(f"{tn}: {d:+.2f}" for tn, d in sorted(entries, key=lambda x: x[1], reverse=True))
        detail_rows.append({"so": so, "type_name_detail": detail})
    df_detail = pd.DataFrame(detail_rows)

    so_agg = so_total.merge(df_detail, on="so")
    so_agg = so_agg.sort_values("total_delta", ascending=False).head(top_n).reset_index(drop=True)
    so_agg.index = so_agg.index + 1
    so_agg.index.name = "rank"
    return so_agg