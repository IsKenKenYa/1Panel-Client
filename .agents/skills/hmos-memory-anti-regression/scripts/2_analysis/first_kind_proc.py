
import sys
from pathlib import Path
import os
from openpyxl.workbook import Workbook

import pandas as pd
from openpyxl.styles import Alignment
from openpyxl.utils.dataframe import dataframe_to_rows

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from config import config_data, TraceType
from analysis_utils import add_heading, add_test_info, profiler_rename, sort, \
    normalize_for_excel

g_summary_excel = list()


# noinspection DuplicatedCode
def __export_with_merge(df, ws, is_merge = 0):
    df = df.map(normalize_for_excel)

    for r in dataframe_to_rows(df, index=False, header=True):
        ws.append(r)

    center = Alignment(horizontal="center", vertical="center")
    for row in ws.iter_rows():
        for cell in row:
            cell.alignment = center

    def merge_same_cells(col_idx, condition=False):
        start = 2  # 从第2行开始（跳过表头）
        last_value = ws.cell(row=2, column=col_idx).value

        def is_previous_column_merge_end(row):
            """检查当前行的前一列是否被合并"""
            if col_idx == 1:  # 第一列没有前一列
                return False
            prev_col = col_idx - 1
            prev_row = row - 1
            for merged_range in ws.merged_cells.ranges:
                if prev_row == merged_range.max_row and \
                        merged_range.min_col <= prev_col <= merged_range.max_col:
                    return True
            return False

        for _row in range(3, ws.max_row + 2):
            current_value = ws.cell(row=_row, column=col_idx).value

            is_pre_end = condition and is_previous_column_merge_end(_row)
            if current_value != last_value or is_pre_end:
                end = _row - 1
                if end > start:
                    ws.merge_cells(start_row=start, start_column=col_idx,
                                   end_row=end, end_column=col_idx)
                    ws.cell(row=start, column=col_idx).alignment = Alignment(vertical="center", horizontal="center")
                start = _row
                last_value = current_value

    if is_merge:
        for i in range(df.shape[1] - is_merge):
            merge_same_cells(i+1, i % 3 != 0)


def data_to_df(data, limit = None, ratio_limit = None, size_limit = None, is_format = False):
    flatten_rows = []
    for top_key, top_val in data.items():
        first_kind_size = f'{round(top_val.get("size"), 1)}MB' if is_format else round(top_val.get("size"), 3)
        first_kind_ratio = f'{round(top_val.get("ratio") * 100, 1)}%' if is_format else round(top_val.get("ratio"), 4)
        third = top_val.get("third_kind", {})
        # Track shown vs hidden sizes for adding "其他" row
        shown_third_size = 0
        for kit_index, (kit_name, kit_info) in enumerate(third.items()):
            if limit and kit_index >= limit:
                # Hidden third_kind entry - skip but account for its size
                continue
            third_kind_size_val = kit_info.get("size")
            shown_third_size += third_kind_size_val
            third_kind_size = f'{round(third_kind_size_val, 1)}MB' if is_format else round(third_kind_size_val, 3)
            third_kind_ratio = f'{round(kit_info.get("ratio") * 100, 1)}%' if is_format else round(kit_info.get("ratio"), 4)
            so_map = kit_info.get("so", {})
            shown_so_size = 0
            if so_map:
                for so_index, (so_path, so_info) in enumerate(so_map.items()):
                    if limit and so_index >= limit:
                        break
                    if ratio_limit and so_info.get("ratio") < ratio_limit/100:
                        break
                    if size_limit and so_info.get("size") < size_limit:
                        break
                    so_size_val = so_info.get("size")
                    shown_so_size += so_size_val
                    size = f'{round(so_size_val, 1)}MB' if is_format else round(so_size_val, 3)
                    ratio = f'{round(so_info.get("ratio") * 100, 1)}%' if is_format else round(so_info.get("ratio"), 4)
                    so = so_path.split('/')[-1] if so_path is not None else "(未归因)"
                    types = so_info.get("types")
                    for type_name, type_size_val in types.items():
                        type_size_fmt = f'{round(type_size_val, 1)}MB' if is_format else round(type_size_val, 3)
                        flatten_rows.append({
                            "一层领域": top_key,
                            "一层领域占用": first_kind_size,
                            "一层领域占比": first_kind_ratio,
                            "二层领域": kit_name[1],
                            "二层领域占用": third_kind_size,
                            "二层领域占比": third_kind_ratio,
                            "so": so,
                            "size": type_size_fmt,
                            "ratio": ratio,
                            "type_name" : type_name,
                            "type_size" : type_size_fmt
                        })
# Add "其他" row for hidden SOs within this third_kind
                hidden_so_size = third_kind_size_val - shown_so_size
                if hidden_so_size > 0.05:
                    hidden_size = f'{round(hidden_so_size, 1)}MB' if is_format else round(hidden_so_size, 3)
                    hidden_ratio_val = kit_info.get("ratio") - (shown_so_size / (top_val.get("size") / kit_info.get("ratio")) if kit_info.get("ratio") > 0 else 1)
                    hidden_ratio = f'{round(max(hidden_ratio_val, 0) * 100, 1)}%' if is_format else round(max(hidden_ratio_val, 0), 4)
                    flatten_rows.append({
                        "一层领域": top_key,
                        "一层领域占用": first_kind_size,
                        "一层领域占比": first_kind_ratio,
                        "二层领域": kit_name[1],
                        "二层领域占用": third_kind_size,
                        "二层领域占比": third_kind_ratio,
                        "so": "其他",
                        "size": hidden_size,
                        "ratio": hidden_ratio,
                        "type_name": "其他",
                        "type_size": hidden_size
                    })
            else:
                pass
        # Add "其他" row for hidden third_kind entries
        top_size_val = top_val.get("size")
        hidden_third_size = top_size_val - shown_third_size
        if hidden_third_size > 0.05:
            hidden_third_str = f'{round(hidden_third_size, 1)}MB' if is_format else round(hidden_third_size, 3)
            hidden_third_ratio = f'{round((hidden_third_size / top_size_val) * 100, 1)}%' if is_format else round(hidden_third_size / top_size_val, 4)
            flatten_rows.append({
                "一层领域": top_key,
                "一层领域占用": first_kind_size,
                "一层领域占比": first_kind_ratio,
                "二层领域": "其他",
                "二层领域占用": hidden_third_str,
                "二层领域占比": hidden_third_ratio,
                "so": "其他",
                "size": hidden_third_str,
                "ratio": hidden_third_ratio,
                "type_name": "其他",
                "type_size": hidden_third_str
            })
    return pd.DataFrame(flatten_rows)


# noinspection DuplicatedCode
def find_field_proportion(res):
    field_proportion = {}
    total_size = 0
    total_size_type = {}
    for item in res:
        first_kind = item['field']['firstkind']
        third_kind = item['field']['thirdkind']
        if first_kind in field_proportion:
            field_proportion[first_kind]["size"] += item['heap_size']
        else:
            field_proportion[first_kind] = {"size": item['heap_size'], "third_kind": {}}
        inner_key = (first_kind, third_kind)
        if inner_key in field_proportion[first_kind]["third_kind"]:
            field_proportion[first_kind]["third_kind"][inner_key]["size"] += item['heap_size']
        else:
            field_proportion[first_kind]["third_kind"][inner_key] = {"size": item['heap_size']}
        if item['type'] in total_size_type:
            total_size_type[item['type']] += item['heap_size']
        else:
            total_size_type[item['type']] = item['heap_size']
        total_size += item['heap_size']
    for _type, size in total_size_type.items():
        print(f'firstkind _{getattr(TraceType, _type).value}_ 存活内存:{size / (1024 * 1024)}')

    for item in field_proportion:
        field_proportion[item]["ratio"] = field_proportion[item]["size"] / total_size
        field_proportion[item]["size"] = field_proportion[item]["size"] / 1024 / 1024
        for third_kind in field_proportion[item]["third_kind"]:
            field_proportion[item]["third_kind"][third_kind]["ratio"] = (
                    field_proportion[item]["third_kind"][third_kind]["size"] / total_size)
            field_proportion[item]["third_kind"][third_kind]["size"] = (
                    field_proportion[item]["third_kind"][third_kind]["size"] / 1024 / 1024)
    field_proportion = sort(field_proportion, "third_kind")
    return field_proportion, total_size


def append_summary_data(data, sheet_name):
    """将域归因数据展平为DataFrame并追加到汇总Excel数据源"""
    df = data_to_df(data, config_data['limit'][0], config_data['limit'][1], config_data['limit'][2], True)
    df.insert(0, '场景', sheet_name)
    g_summary_excel.append(df)


def make_summary_excel():
    wb = Workbook()
    ws = wb.active  # 获取当前活动的默认sheet
    wb.remove(ws)
    ws = wb.create_sheet(title='memory_native_summary')
    df = pd.concat(g_summary_excel, ignore_index=False)
    if config_data['heading']:
        df.rename(columns={
        '一层领域': 'first_domain',
        '一层领域占用': 'first_domain_occupation',
        '一层领域占比': 'first_domain_percentage',
        '二层领域': 'second_domain',
        '二层领域占用': 'second_domain_occupation',
        '二层领域占比': 'second_domain_percentage',
        '场景':'test_step'
        }, inplace=True)
        df = add_test_info(df, True)
        df = add_heading(df)
        profiler_rename(df)
        __export_with_merge(df, ws, 0)
    else:
        __export_with_merge(df, ws, 2)
    wb.save(os.path.join(config_data["output_path"], '汇总.xlsx'))


def marge_sheet_for_update(wb):
    excel_data = pd.read_excel(wb, sheet_name=None, engine="openpyxl")

    # 创建列表存储处理后的DataFrame
    df_list = []

    # 遍历每个Sheet并添加Sheet名列
    for sheet_name, df in excel_data.items():
        df_with_sheet = df.copy()  # 避免修改原始数据
        df_with_sheet.insert(0, "场景", sheet_name)  # 插入到第一列
        df_list.append(df_with_sheet)

    # 合并所有DataFrame
    df = pd.concat(df_list, ignore_index=False)
    df.rename(columns={
        '一层领域': 'first_domain',
        '一层领域占用': 'first_domain_occupation',
        '一层领域占比': 'first_domain_percentage',
        '二层领域': 'second_domain',
        '二层领域占用': 'second_domain_occupation',
        '二层领域占比': 'second_domain_percentage',
        '场景':'test_step'
        }, inplace=True)
    df = add_test_info(df, True)
    df = add_heading(df)
    profiler_rename(df)
    new_wb = Workbook()
    ws = new_wb.active
    new_wb.remove(ws)
    ws = new_wb.create_sheet(title='memory_native_total')
    __export_with_merge(df, ws, 0)
    return new_wb
