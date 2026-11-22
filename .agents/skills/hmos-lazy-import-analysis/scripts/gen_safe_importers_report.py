#!/usr/bin/env python3
"""
为 lazy-import 安全性分析判为 safe 的模块生成 xlsx:
  - 模块 / 模块磁盘文件 / cost(ms)
  - 每个 parentModule(D 列) 在哪里引用了它: parentModule 文件 + 引用代码行(import 或 export...from re-export) + 行号
  - 「可lazy?」列按**引用行本身**判定: `export ... from` re-export -> 暂不可(re-export)
    (lazy 对 re-export 语义未明); 普通 `import ... from` -> 可。
    不按 parentModule 文件名判 barrel——pages/Index.ets 这类 @Entry 页面是普通使用方。

行号匹配: 输入若为 Phase 2 输出(含 has_toplevel 列), 按首列「报表row」(源表行号) 回连,
与 analyze_report stdout 显示的 row 一致; 否则视为源报表, 直接按工作表行号。

输入: 报表 + safe 行号列表(模型分析产出) + 项目根
用法:
  python3 gen_safe_importers_report.py <Phase2输出.xlsx> --safe-rows "10,31,49,59,82,102" --root <项目根> [--out out.xlsx] [--sheet "Unused Files"]
"""
import os
import re
import sys
import argparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    from openpyxl.utils import get_column_letter
except ImportError:
    os.system(f"{sys.executable} -m pip install openpyxl")
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    from openpyxl.utils import get_column_letter

from resolver import Resolver
import parse_unused_files as p1

GENERIC_NAMES = {'index', 'indexets', 'constants', 'constant'}


def find_ref_lines(parent_file, internal_path, basename, module_name):
    """在 parent_file 中找 引用该模块的行 -> [(lineno, line, is_reexport)]。
    is_reexport=True 表示该行是 export...from 再导出(lazy 语义未明), 而非普通 import。"""
    if not parent_file or not os.path.isfile(parent_file):
        return []
    hits = []
    try:
        with open(parent_file, encoding='utf-8-sig', errors='replace') as f:
            lines = f.readlines()
    except Exception:
        return []
    barrel_re = re.compile(r"from\s+['\"]" + re.escape(module_name) + r"['\"]")
    # basename 须作为引号内路径的最后一段 ('./Feature' / '../utils/Feature' / 'Feature'),
    # 避免子串误命中 (如 basename=Feature 误匹配 doFeatureCommon 这类标识符)
    basename_re = re.compile(r"['\"](?:[\w./@-]*/)?" + re.escape(basename) + r"['\"]") if basename else None
    for i, ln in enumerate(lines, 1):
        s = ln.strip()
        if not s or s.startswith('//'):
            continue
        is_import = 'import' in s or 'require' in s
        is_reexport = ('export' in s and ' from' in s)   # re-export: export ... from '...'
        if not (is_import or is_reexport):
            continue
        line_is_reexport = s.startswith('export') and not s.startswith('exportdefault')
        if internal_path and internal_path in s:          # 裸名+子路径 直引/re-export
            hits.append((i, s, line_is_reexport))
        elif (basename_re is not None and basename.lower() not in GENERIC_NAMES
              and basename_re.search(s)):                 # 直接/相对, 文件名独特
            hits.append((i, s, line_is_reexport))
        elif module_name and barrel_re.search(s):          # barrel: from 'module'
            hits.append((i, s, line_is_reexport))
    return hits


def main():
    ap = argparse.ArgumentParser(description="为 safe 模块生成 parentModule 引用行报告 xlsx")
    ap.add_argument('report', help='redundant file xlsx 报表')
    ap.add_argument('--safe-rows', required=True, help='safe 行号(逗号分隔), 如 "10,31,49"')
    ap.add_argument('--root', required=True, help='项目根')
    ap.add_argument('--sheet', default='Unused Files')
    ap.add_argument('--out', default=None, help='输出 xlsx 路径 (默认 safe_importers_<time>.xlsx)')
    args = ap.parse_args()

    rows = [int(x.strip()) for x in args.safe_rows.split(',') if x.strip()]
    resolver = Resolver(args.root)

    wb = openpyxl.load_workbook(args.report, data_only=True)
    if args.sheet not in wb.sheetnames:
        print(f"错误: sheet 不存在 {args.sheet}; 可用 {wb.sheetnames}")
        sys.exit(1)
    ws = wb[args.sheet]

    out_rows = []

    # 行号匹配: Phase 2 输出(含 has_toplevel 列)按首列「报表row」(源表行号) 回连,
    # 避免过滤重跑后输出行错位; 源报表则直接按工作表行号
    src_headers = [ws.cell(1, c).value for c in range(1, ws.max_column + 1)]
    if 'has_toplevel' in [h for h in src_headers if h]:
        colA = {}
        for rr in range(2, ws.max_row + 1):
            try:
                colA[int(ws.cell(rr, 1).value)] = rr
            except (TypeError, ValueError):
                continue
        sel = []
        for r in rows:
            if r in colA:
                sel.append((r, colA[r]))
            else:
                out_rows.append([r, f'(报表row {r} 未在报告中找到, 请核对)', '', '', '', '', '', '', ''])
    else:
        sel = [(r, r) for r in rows]

    for r, rr in sel:
        b = ws.cell(rr, 2).value
        try:
            parsed = p1.parse_module_path(b)
        except Exception:
            parsed = None
        if parsed is None or parsed['kind'] in ('so', 'ohos', 'hms'):
            out_rows.append([r, b or '', '', '', '非ets/解析失败', '', '', '', ''])
            continue
        module = parsed['module']
        internal = parsed['value']
        prefix = module + '/'
        if internal.startswith(prefix):
            internal = internal[len(prefix):]
        internal_path = module + '/' + internal
        basename = internal.rsplit('/', 1)[-1]
        module_file = resolver.resolve_report_module(module, internal) or ''
        try:
            cost = float(ws.cell(rr, 3).value or 0)
        except Exception:
            cost = 0
        g = ws.cell(rr, 4).value
        parents = []
        if g and str(g).strip():
            for line in str(g).split('\n'):
                line = line.strip()
                if not line:
                    continue
                try:
                    pp = p1.parse_module_path(line)
                except Exception:
                    continue
                pmod = pp['module']
                pint = pp['value']
                ppfx = pmod + '/'
                if pint.startswith(ppfx):
                    pint = pint[len(ppfx):]
                pfile = resolver.resolve_report_module(pmod, pint)
                parents.append((pmod, pfile))
        mrel = os.path.relpath(module_file, args.root) if module_file else '(无法定位)'
        if not parents:
            out_rows.append([r, b, mrel, cost, '(无 parentModule)', '', '', '', ''])
            continue
        seen_pfile = set()
        for pmod, pfile in parents:
            if not pfile or pfile in seen_pfile:
                continue
            seen_pfile.add(pfile)
            # 规则: 按**引用行本身**判定——export...from 再导出 -> 暂不可(re-export);
            # 普通 import -> 可。不按文件名判 barrel(pages/Index.ets 是 @Entry 页面, 非转发文件)
            hits = find_ref_lines(pfile, internal_path, basename, module)
            if not hits:
                out_rows.append([r, b, mrel, cost, pmod, os.path.relpath(pfile, args.root),
                                 '(未找到 import/re-export 引用行, 请人工确认)', '', '待确认'])
            else:
                for ln, line, is_reexp in hits[:3]:
                    lazy_status = '暂不可(re-export)' if is_reexp else '可'
                    out_rows.append([r, b, mrel, cost, pmod, os.path.relpath(pfile, args.root),
                                     line[:200], ln, lazy_status])

    # 写 xlsx
    from datetime import datetime
    out_path = args.out or f"safe_importers_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
    wb_out = openpyxl.Workbook()
    wso = wb_out.active
    wso.title = 'safe importers'
    headers = ['报表row', '模块(B)', '模块文件', 'cost(ms)', 'parentModule', 'parentModule文件',
               '引用代码行', '行号', '可lazy?']
    hf = Font(bold=True, color='FFFFFF')
    hfill = PatternFill(start_color='4472C4', end_color='4472C4', fill_type='solid')
    for ci, h in enumerate(headers, 1):
        c = wso.cell(1, ci, h)
        c.font = hf
        c.fill = hfill
        c.alignment = Alignment(horizontal='center')
    for ri, row in enumerate(out_rows, 2):
        for ci, v in enumerate(row, 1):
            wso.cell(ri, ci, v)
    widths = [8, 60, 60, 12, 30, 60, 80, 6, 16]
    for ci, w in enumerate(widths, 1):
        wso.column_dimensions[get_column_letter(ci)].width = w
    wso.freeze_panes = 'A2'
    wb_out.save(out_path)

    n_reexp = sum(1 for x in out_rows if x[8] == '暂不可(re-export)')
    n_ok = sum(1 for x in out_rows if x[8] == '可')
    print(f"safe 模块 {len(sel)} 个 -> {len(out_rows)} 行 (模块xparentModule) -> {out_path}")
    print(f"  可lazy: {n_ok} 行, 暂不可(re-export): {n_reexp} 行")


if __name__ == '__main__':
    main()
