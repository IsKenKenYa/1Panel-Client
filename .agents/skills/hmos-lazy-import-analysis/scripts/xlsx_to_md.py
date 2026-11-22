#!/usr/bin/env python3
"""
把 xlsx 的一个 sheet 原样转成 markdown 表格输出到 stdout, 供嵌入最终建议报告
(lazy_import_suggestions_*.md):
  - 单元格内换行 -> <br>, '|' 转义为 '\\|'
  - 超长单元格截断 (--max-cell, 默认 200 字符), 截断时表后自动附注
  - --match 列名=值 按列精确过滤 (可重复), 如 --match "报表row=10"
    取某模块在 safe_importers 表中的全部引用行

用法:
  python3 xlsx_to_md.py <xlsx> [--sheet "Unused Files"] [--match 列名=值 ...] [--max-cell 200]
"""

import os
import sys
import argparse

try:
    import openpyxl
except ImportError:
    os.system(f"{sys.executable} -m pip install openpyxl")
    import openpyxl


def fmt(v):
    """单元格值 -> 干净字符串 (10.0 -> '10', 12.345 -> '12.345')。"""
    if v is None:
        return ''
    if isinstance(v, float):
        return f'{v:g}'
    return str(v).strip()


def md_cell(s, max_cell):
    """单元格 -> markdown 安全文本; 返回 (文本, 是否截断)。"""
    s = s.replace('\r\n', '\n').replace('\r', '\n')
    s = s.replace('|', '\\|')
    s = s.replace('\n', '<br>')
    if len(s) > max_cell:
        return s[:max_cell] + ' …(截断)', True
    return s, False


def main():
    ap = argparse.ArgumentParser(description="xlsx sheet -> markdown 表格 (stdout), 供原样嵌入最终报告")
    ap.add_argument('xlsx', help='xlsx 文件路径')
    ap.add_argument('--sheet', default=None, help='sheet 名 (默认第一个 sheet)')
    ap.add_argument('--match', action='append', default=[], metavar='列名=值',
                    help='按列精确过滤 (可重复), 如 --match "报表row=10"')
    ap.add_argument('--max-cell', type=int, default=200, help='单元格截断上限字符数 (默认 200)')
    args = ap.parse_args()

    if not os.path.isfile(args.xlsx):
        print(f"错误: 文件不存在: {args.xlsx}")
        sys.exit(1)
    wb = openpyxl.load_workbook(args.xlsx, data_only=True)
    if args.sheet:
        if args.sheet not in wb.sheetnames:
            print(f"错误: sheet 不存在: {args.sheet}; 可用: {wb.sheetnames}")
            sys.exit(1)
        ws = wb[args.sheet]
    else:
        ws = wb.active

    headers = [fmt(ws.cell(1, c).value) for c in range(1, ws.max_column + 1)]
    while headers and headers[-1] == '':  # 去掉尾部空列
        headers.pop()
    if not any(headers):
        print("错误: sheet 无表头行")
        sys.exit(1)

    filters = []
    for m in args.match:
        if '=' not in m:
            print(f"错误: --match 应为 列名=值 形式: {m}")
            sys.exit(1)
        name, val = m.split('=', 1)
        name, val = name.strip(), val.strip()
        if name not in headers:
            print(f"错误: 列不存在: {name}; 可用列: {headers}")
            sys.exit(1)
        filters.append((headers.index(name), val))

    n_rows = 0
    n_trunc = 0
    print('| ' + ' | '.join(md_cell(h, args.max_cell)[0] for h in headers) + ' |')
    print('|' + '|'.join(['---'] * len(headers)) + '|')
    for r in range(2, ws.max_row + 1):
        vals = [fmt(ws.cell(r, c).value) for c in range(1, len(headers) + 1)]
        if not any(vals):
            continue
        if any(vals[i] != v for i, v in filters):
            continue
        cells = []
        for s in vals:
            cs, trunc = md_cell(s, args.max_cell)
            n_trunc += int(trunc)
            cells.append(cs)
        print('| ' + ' | '.join(cells) + ' |')
        n_rows += 1

    if n_rows == 0:
        print('')
        print('（无匹配行——请检查 --match 的列名/取值）')
    if n_trunc:
        print('')
        print(f'> 注：{n_trunc} 个超长单元格已截断至 {args.max_cell} 字符，'
              f'完整数据见源文件 {os.path.basename(args.xlsx)}')


if __name__ == '__main__':
    main()
