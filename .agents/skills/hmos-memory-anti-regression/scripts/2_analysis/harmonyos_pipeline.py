#!/usr/bin/env python3
"""harmonyos_pipeline: 从收集到的 showmap/dma/gpu 等原始文件生成 meminfo.xlsx。"""
import logging
import re
from collections import defaultdict
from functools import reduce
from pathlib import Path
from numbers import Number
from typing import Optional

import pandas as pd

from base_pipeline import Layer1MaPipeline
from config import config_data
from analysis_utils import parse_harmonyos_showmap_filename, parse_harmonyos_meminfo_filename
from hidumper import read_showmap_2_df

logger = logging.getLogger(__name__)


# noinspection DuplicatedCode
def load_empty_service_name():
    lines = (Path(__file__).parent / "empty_hidumper_smaps.txt").read_text(encoding="utf-8", errors="ignore").splitlines()
    data_lines = [line.strip() for line in lines]
    rows = [re.split(r"\s{2,}", line.strip()) for line in data_lines]

    header_idx = None
    for i, r in enumerate(rows):
        if any(h in r for h in ("Category", "Pss", "SwapPss")):
            header_idx = i
            break

    header = rows[header_idx]
    data = rows[header_idx + 1:]

    _df = pd.DataFrame(data, columns=header)
    _df['Category'] = _df['Category'].str.strip()
    _df = _df[_df['Category'].isin(['.hap', '.db', '.so', '.ttf', 'dev', 'AnonPage other', 'FilePage other'])]
    return _df['Name'].tolist()


class HarmonyLayer1MaPipeline(Layer1MaPipeline):
    _EMPTY_SERVICE = load_empty_service_name()

    # 匹配格式：
    # PID  xxx(xxx in SwapPss) kB   GL kB
    pattern = re.compile(
        r'^\s*(\d+)\s+'  # PID
        r'\d+\(.*?\)\s+kB\s+'  # Total Pss
        r'(\d+)\s+kB',  # GL
        re.MULTILINE
    )

    def __init__(self,
                 test_case_dir: str,
                 out_put: str = None,
                 ):
        super().__init__(test_case_dir=test_case_dir, out_put=out_put)
        self._for_test = False

    def _group_raw_data(self):
        data, main_process_file, sub_data = self.__group_pss()
        self.main_process_files = main_process_file
        self.sub_data = sub_data
        return data

    def _add_statistics(self):
        df = self.data
        if not self._for_test:
            # df["total"] = df.select_dtypes(include="number").sum(axis=1)
            df[".so/.jar"] = (df.get(".so", 0) + df.get(".so(empty_service)", 0))
            df[".hap_"] = df.get(".hap", 0) + df.get(".hap(empty_service)", 0)
            df["native_heap_"] = df.get("native heap", 0)
            df["ark_ts_heap"] = df.get("ark ts heap", 0)
            df["dma"] = (df.get("dma_web", 0) +
                         df.get("dma_NULL", 0) +
                         df.get("dma_xcomponent", 0) +
                         df.get("dma_pixelmap", 0))
            df["stack_"] = df.get("stack", 0)
            df[".ttf_"] = df.get(".ttf", 0) + df.get(".ttf(empty_service)", 0)
            df[".db_"] = df.get(".db", 0) + df.get(".db(empty_service)", 0)
            df["gpu_"] = df.get("gpu", 0)
            df["other"] = df["total"] - df[
                [
                    ".so/.jar",
                    ".hap_",
                    "native_heap_",
                    "ark_ts_heap",
                    "dma",
                    "stack_",
                    ".ttf_",
                    ".db_",
                    "gpu_"
                ]
            ].sum(axis=1)
            df["total-GL"] = df["total"] - df["gpu_"]

        # 和测试的数据做对比
        xlsx_path = self._root / "meminfo" / "单框架动态内存占用详情.xlsx"
        if not xlsx_path.exists():
            return df
        test_df = pd.read_excel(xlsx_path, sheet_name="单应用内存占用总览")
        test_df["time"] = test_df["file_name"].str.extract(r"_(\d{8}-\d{6})_")
        test_df["app_total_mem"] /= 1024
        df = df.merge(test_df[["time", "app_total_mem"]], on="time", how="left")
        df['app_total_mem'] = df['app_total_mem'].fillna(
            0).infer_objects(copy=False)
        return df

    def _prase_file_map(self, file_map, gpu_dir, dma_dir):
        results = []
        for t, l in file_map.items():
            dfs = []
            for pid, v in l.items():
                try:
                    if not self._for_test:
                        row_df = self.__parse_smap(v[0])
                    else:
                        # 说明 showmap 不存在
                        row_df = pd.DataFrame(index=range(1))
                    gpu_file = gpu_dir / f"dynamicMem_{t}_{v[1]}"
                    row_df["gpu"] = self.__parse_gpu(gpu_file, pid)
                    # noinspection PyTypeChecker
                    dma_file = dma_dir / f"process_dmabuf_info_{t}_{v[1]}"
                    dma_map = self._read_dma(dma_file, pid)
                    for key, value in dma_map.items():
                        row_df[f"dma_{key}"] = round(value / (1024 * 1024), 2)
                    dfs.append(row_df)
                except Exception as e:
                    logger.error(f"❌ 解析失败 {pid}, {v[0]}: {e}")
                    if config_data.get("verbose"):
                        logger.exception(f"调试模式下打印异常堆栈")
            if not dfs:
                continue
            df = reduce(lambda x, y: x.add(y, fill_value=0), dfs)
            df.insert(0, "time", t)
            results.append(df)
        if results:
            return pd.concat(results, ignore_index=True, sort=False).fillna(0).sort_values(by="time").reset_index(drop=True)
        else:
            return None

    # noinspection PyBroadException,PyUnresolvedReferences
    def __group_pss(self):
        root_path_dir = self._root / "meminfo"
        output_dir = self._root
        smap_dir = root_path_dir / "dynamic_showmap"
        gpu_dir = root_path_dir / "dynamic_meminfo"
        dma_dir = root_path_dir / "dynamic_process_dmabuf_info"
        logger.debug(f"✅ smap 文件路径: {smap_dir.absolute()}")
        logger.debug(f"✅ gpu 文件路径: {gpu_dir.absolute()}")
        logger.debug(f"✅ dma 文件路径: {dma_dir.absolute()}")
        logger.debug(f"✅ 输出目录: {output_dir}")
        file_map, main_file, sub_file_map = self.__parse()
        results = self._prase_file_map(file_map, gpu_dir, dma_dir)
        sub_results = self._prase_file_map(sub_file_map, gpu_dir, dma_dir)
        return results, main_file, sub_results

    def __parse(self):
        file_map = defaultdict(lambda: defaultdict(list))
        sub_file_map = defaultdict(lambda: defaultdict(list))
        main_file = []
        
        smap_dir = self._root / "meminfo" / "dynamic_showmap"
        if smap_dir.exists():
            files = [_f for _f in smap_dir.iterdir() if _f.is_file()]
            files = list(sorted(files, key=lambda x: (len(x.name), x.name)))
            def check_lines(file_path, max_lines=10):
                """高效统计行数，避免内存溢出"""
                line_count = 0
                with open(file_path, 'rb') as f:  # 二进制模式读取更安全
                    for _ in f:  # 迭代式逐行读取，内存友好
                        line_count += 1
                        # 可选：提前终止统计（已知最小行数时）
                        if line_count >= max_lines:  
                            return True
                return False
            if config_data['heading'] and len(files) >= 2:
                main_pid = parse_harmonyos_showmap_filename(files[1].name)[1]
            else:
                main_pid = parse_harmonyos_showmap_filename(files[0].name)[1]
            for _f in files:
                process, pid, record_time, suffix = parse_harmonyos_showmap_filename(_f.name)
                # if main_pid is None and check_lines(_f):
                #     main_pid = pid
                if pid == main_pid:
                    main_file.append(_f)
                else:
                    sub_file_map[record_time][pid] = [_f, suffix]
                    continue
                file_map[record_time][pid] = [_f, suffix]

            return file_map, main_file, sub_file_map
        else:
            self._for_test = True
            # 用于测试数据（没有 showmap）
            test_xlsx = self._root / "meminfo" / "单框架动态内存占用详情.xlsx"
            df = pd.read_excel(test_xlsx, sheet_name="单应用内存占用总览")
            for _, row in df.iterrows():
                record_time, suffix = parse_harmonyos_meminfo_filename(row["file_name"])
                pid = str(row["pid"])
                file_map[record_time][pid] = [None, suffix]
            return file_map, None, sub_file_map

    # noinspection DuplicatedCode
    @classmethod
    def __parse_smap(cls, file_path: Path) -> Optional[pd.DataFrame]:
        _df = read_showmap_2_df(file_path)
        _df["Rss"] = pd.to_numeric(_df["Rss"]).fillna(0)
        _df["Swap"] = pd.to_numeric(_df["Swap"]).fillna(0)
        _df["Size"] = pd.to_numeric(_df["Size"]).fillna(0)
        anon_special_list = ['[anon:absl]', '[anon:async_stack_table]', '[anon:cfi_shadow:musl]',
                             '[anon]', '[anon:kotlin_native_heap_]', '[shmm]']

        def group_key(row):
            if row["Name"] in cls._EMPTY_SERVICE:
                return row["Category"] + "(empty_service)"
            elif row["Category"] == "FilePage other":
                if "ashmem" in row["Name"]:
                    return "FilePage other (ashmem)"
                else:
                    return "FilePage other (normal)"
            elif row["Category"] == "AnonPage other":
                if "ArkTS" in row["Name"]:
                    return "AnonPage other (ArkTS)"
                elif row["Name"] in anon_special_list:
                    return "AnonPage other (special)"
                else:
                    return "AnonPage other (normal)"
            else:
                return row["Category"]

        _df["Group"] = _df.apply(group_key, axis=1)

        def agg_func(group_name, sub):
            # group_name 就是当前分组名，不再依赖 sub["Group"]
            # if group_name.startswith("FilePage other"):
            #     return sub["Size"].sum()
            # elif group_name.startswith("AnonPage other"):
            #     return sub["Size"].sum()
            # else:
            return (sub["Rss"] + sub["Swap"]).sum()

        cols_to_use = ["Size", "Pss", "SwapPss"]
        result = (
            _df.groupby("Group")[["Size", "Rss", "Swap"]]  # 按 Group 分组
            .apply(lambda sub: agg_func(sub.name, sub))  # 只对子 DataFrame 操作
            .reset_index(name="Value")
        )
        result["Value"] = result["Value"] / 1024
        row_df = pd.DataFrame([result.set_index("Group")["Value"].to_dict()])
        return row_df

    @staticmethod
    def __parse_gpu(file_path: Path, target_pid: str) -> Optional[Number]:
        if not file_path.exists():
            return 0
        with open(file_path, encoding="utf-8", errors="ignore") as f:
            content = f.read()
        for pid, gl in HarmonyLayer1MaPipeline.pattern.findall(content):
            if pid == target_pid:
                return round(int(gl) / 1024, 2)
        return 0

    @staticmethod
    def __parse_gpu_old(file_path: Path, _pid: str) -> Number:
        if not file_path.exists():
            return 0
        lines = file_path.read_text(encoding="utf-8").splitlines()[1:]
        rows = [re.split(r"\s+", line.strip())[:5] for line in lines if line.strip()]
        _df = pd.DataFrame(rows, columns=["name", "pid", "col3", "col4", "col5"])
        _df["col5"] = pd.to_numeric(_df["col5"], errors="coerce")
        filtered = _df[_df["pid"] == _pid]
        total = filtered["col5"].sum()
        return round(total * 4 / 1024, 2)

    @staticmethod
    def _read_dma(file_path: Path, _pid: str) -> dict[str, int]:
        _dma_map = {
            'pixelmap': 0,
            'web': 0,
            'NULL': 0,
            'xcomponent': 0,
        }
        if not file_path.exists():
            return _dma_map
        with file_path.open(encoding="utf-8", errors="ignore") as _f:
            for line in _f:
                line = line.strip()
                if not line:
                    continue
                items = line.split()
                if len(items) >= 12 and _pid in items[1]:
                    type_ = items[11]
                    try:
                        size = int(items[3])
                    except ValueError:
                        continue
                    if type_ not in _dma_map:
                        print(f'非预期dma 类型{type_}')
                        continue
                    _dma_map[type_] = _dma_map.get(type_, 0) + size
        return _dma_map