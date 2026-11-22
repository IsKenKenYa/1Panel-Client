import logging
import os
from abc import ABC
from pathlib import Path

import pandas as pd

from analysis_utils import (
    add_heading,
    add_missing_columns,
    add_test_info,
    clean_illegal_sign,
    clean_string,
    parse,
    OpFileUtil,
    dumper_rename
)
from config import config_data

logger = logging.getLogger()


class Layer1MaPipeline(ABC):

    def __init__(self,
                 test_case_dir: str,
                 out_put: str = None
                 ):
        self.raw_data = None
        self.data = None
        self.sorted_scenes = None
        self.timelines = None
        self._root = Path(test_case_dir)
        out_put = test_case_dir if out_put is None else out_put
        self.raw_data_output = os.path.join(out_put, "meminfo.xlsx")
        self.output = os.path.join(out_put, "scenario_meminfo.xlsx")

    def analyze(self):
        # 1. 聚合基础数据
        self.raw_data = self._group_raw_data()
        self.data = self.raw_data.copy(deep=True)
        self.timelines = self.data["time"].tolist()
        # if not config_data['heading']:
        meminfo_df = self.data.copy(deep=True)
        if len(meminfo_df) == 1:
            meminfo_df["time"] = config_data.get("scene") or "默认场景"
        meminfo_df.to_excel(self.raw_data_output, index=False)
        # 2. 整合场景到 timeline
        self.data['total'] = self.data.select_dtypes(include="number").sum(axis=1)
        # if not Path(self._get_operation_file()).exists():
        #     logger.warning(f"⚠ {self._get_operation_file()} 不存在，跳过整合场景")
        # else:
        #     self.sorted_scenes = self._get_operation_time()
        #     self.data = self._add_scenario()

        # # 3. 生成内存随时间分布图
        # self.__generate_html()

        # 4. 添加统计数据
        self.data = self._add_statistics()
        df = self.data
        if config_data['heading']:
            self.output = os.path.join(config_data["output_path"], config_data["case"] + '_' + "scenario_meminfo.xlsx")
            df['场景'] = df['场景'].apply(clean_illegal_sign)
            df = df.drop(columns=[
                    ".hap_",
                    "native_heap_",
                    "ark_ts_heap",
                    "stack_",
                    ".ttf_",
                    ".db_",
                    "gpu_"
                ])
            # df = df.drop(columns=[col for col in df.columns if 'empty_service' in col])
            empty_cols = [col for col in df.columns if '(empty_service)' in col]
            # 遍历处理每一列
            for empty_col in empty_cols:
                # 提取基础列名（去掉(empty_service)部分）
                base_col = empty_col.replace('(empty_service)', '')
                # 检查基础列是否存在
                if base_col in df.columns:
                    # 将empty_service列的值加到基础列
                    df[base_col] += df[empty_col]
                # 删除empty_service列
                df.drop(columns=[empty_col], inplace=True)
            df.rename(columns={'场景': 'test_step'}, inplace=True)
            df.rename(columns={x: clean_string(x).lower() for x in list(df.columns)}, inplace=True)
            df['time'] = pd.to_datetime(df['time'], format='%Y%m%d-%H%M%S')
            df['time'] = df['time'].dt.strftime('%Y-%m-%d %H:%M:%S')
            df = add_test_info(df)
            df = add_missing_columns(df)
            df = df.sort_values(by="time").reset_index(drop=True)
            df = add_heading(df)
            dumper_rename(df)

        df.to_excel(self.output, index=False, sheet_name='memory_native_scenario', float_format="%.3f")
        logger.info(f"汇总结果为：{self.output}")
