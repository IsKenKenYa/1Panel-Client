#!/usr/bin/env python3
"""
对 redundant file 报表中 cost time 最高的 N 个文件做 top-level 检测。

特点:
  - 取指定 sheet (默认 Unused Files) 按 Cost Time (C 列) 降序的前 N (默认 10)
  - 输出首列「报表row」= 源表工作表行号(与 stdout 的 row 一致), 供 gen_safe_importers_report --safe-rows 使用
  - --cache 缓存带 _version(=check_toplevel.DETECTION_VERSION), 检测逻辑升级后旧缓存自动失效重查
  - 用 parse_unused_files 解析器解析 B 列, 仅对 &-style (ets 文件) 做 top-level 检测;
    .so / @ohos / @hms / @native 等标记为 非ets 跳过
  - 单进程共享 memo: 已确认 verdict 的文件全局跳过 (尤其 true 文件不再复查)
  - 可选 --cache <file> 持久化 verdict 到磁盘, 跨批次复用 (全局记录)

用法:
  python3 analyze_report.py <xlsx> [--sheet "Unused Files"] [--top 10] [--root <项目根>] [--cache cache.json]
"""

import os
import sys
import json
import argparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import openpyxl
except ImportError:
    os.system(f"{sys.executable} -m pip install openpyxl")
    import openpyxl

import parse_unused_files as p1
import check_toplevel as ct
from resolver import Resolver
from datetime import datetime


def find_false_source(path, memo, root, seen=None):
    """沿 memo 中 FALSE 的子节点找到真正 own=FALSE 的源头文件 + 首个命中。"""
    seen = seen or set()
    ap = os.path.abspath(path)
    if ap in seen:
        return None
    seen.add(ap)
    info = ct.check_file(ap)
    if info.get('error'):
        return None
    if info['own'] == 'FALSE':
        h = info['yes_hits'][0] if info['yes_hits'] else None
        return (ap, h, 0)
    for imp in info['imports']:
        if imp['kind'] not in ('relative', 'local', 'ohpm'):
            continue
        e = imp.get('entry')
        if not e:
            continue
        ce = os.path.abspath(e)
        if memo.get(ce) == 'FALSE':
            r = find_false_source(ce, memo, root, seen)
            if r:
                return (r[0], r[1], r[2] + 1)
    return None


def load_cache(path):
    """载入 verdict 缓存。缓存带 _version 字段, 与 DETECTION_VERSION 不匹配(检测逻辑已升级)
    时整体作废, 重新检测, 避免旧判定逻辑的 verdict 被复用。"""
    if not path or not os.path.isfile(path):
        return {}
    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception:
        return {}
    if not isinstance(data, dict) or data.get('_version') != ct.DETECTION_VERSION:
        if isinstance(data, dict) and data:
            print('  (缓存版本过旧(检测逻辑已升级), 忽略旧缓存重新检测)')
        return {}
    files = data.get('files')
    return files if isinstance(files, dict) else {}


def save_cache(path, cache):
    if not path:
        return
    try:
        with open(path, 'w', encoding='utf-8') as f:
            json.dump({'_version': ct.DETECTION_VERSION, 'files': cache},
                      f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"  (缓存写入失败: {e})")


def main():
    ap = argparse.ArgumentParser(description="报表 top-N 文件 top-level 检测 (脚本模式)")
    ap.add_argument('xlsx', help='redundant file xlsx 报表路径')
    ap.add_argument('--sheet', default='Unused Files', help='sheet 名 (默认 Unused Files)')
    ap.add_argument('--top', type=int, default=10, help='取 cost time 前 N (默认 10)')
    ap.add_argument('--ets-only', action='store_true', help='仅保留能解析到真实 .ets 的文件 (过滤 .so/系统/无法定位)')
    ap.add_argument('--verdict', choices=['true', 'false', 'maybe'], default=None,
                    help='仅保留该 verdict 的文件 (遍历候选凑满 N; 无则不过滤)')
    ap.add_argument('--root', default=None, help='项目根 (默认 cwd)')
    ap.add_argument('--out', default=None, help='输出 xlsx 路径 (默认 {app名}_{时间戳}.xlsx, 每次运行新快照)')
    ap.add_argument('--cache', default=None, help='verdict 磁盘缓存文件 (跨批次复用)')
    ap.add_argument('--no-side-effect-decorators', default='',
                    help='扩充装饰器副作用白名单(逗号分隔, 默认已含 @concurrent)')
    args = ap.parse_args()
    if args.no_side_effect_decorators:
        for d in args.no_side_effect_decorators.split(','):
            d = d.strip()
            if d:
                ct.NO_SIDE_EFFECT_DECORATORS.add('@' + d.lstrip('@').lower())

    if not os.path.isfile(args.xlsx):
        print(f"错误: 报表不存在: {args.xlsx}"); sys.exit(1)
    root = os.path.abspath(args.root) if args.root else os.getcwd()
    if not (os.path.isfile(os.path.join(root, 'oh-package.json5')) and os.path.isdir(os.path.join(root, 'oh_modules'))):
        print(f"警告: {root} 似乎不是项目根 (无 oh-package.json5 + oh_modules), 解析可能失败")

    # 共享 resolver (注入 check_toplevel 全局, 避免重复扫描)
    resolver = Resolver(root)
    ct._RESOLVER = resolver
    ct._RESOLVER_ROOT = root

    # 共享 memo + 磁盘缓存
    memo = load_cache(args.cache)   # {abspath: verdict}
    cache_hits = 0

    wb = openpyxl.load_workbook(args.xlsx, data_only=True)
    if args.sheet not in wb.sheetnames:
        print(f"错误: sheet 不存在: {args.sheet}; 可用: {wb.sheetnames}"); sys.exit(1)
    ws = wb[args.sheet]

    rows = []
    skipped_nonets = 0
    skipped_unresolved = 0
    metric_name = 'cost(ms)'
    def metric_of(row):
        v = ws.cell(row, 3).value
        return float(v) if v is not None else 0.0
    for r in range(2, ws.max_row + 1):
        b = ws.cell(r, 2).value
        if b is None:
            continue
        try:
            parsed = p1.parse_module_path(b)
        except Exception:
            parsed = None  # @native 等会抛错
        cost = 0.0
        try:
            cost = metric_of(r)
        except Exception:
            pass
        # 预解析 entry / status
        entry = None
        status = None
        if parsed is None:
            status = 'skip-parse'
        else:
            kind = parsed['kind']
            if kind in ('so', 'ohos', 'hms'):
                status = f'skip-{kind}'
            else:
                module = parsed['module']
                internal = parsed['value']
                prefix = module + '/'
                if internal.startswith(prefix):
                    internal = internal[len(prefix):]
                entry = resolver.resolve_report_module(module, internal)
                status = None if entry else 'unresolved'
        # --ets-only: 只保留能解析到真实 .ets 的
        if args.ets_only:
            if status is not None:
                if status.startswith('skip'):
                    skipped_nonets += 1
                elif status == 'unresolved':
                    skipped_unresolved += 1
                continue
        rows.append((cost, r, parsed, b, entry, status))

    rows.sort(key=lambda x: x[0], reverse=True)

    mode = 'ets-only' if args.ets_only else 'all'
    vfilter = args.verdict
    target_v = {'true': 'TRUE', 'false': 'FALSE', 'maybe': 'MAYBE'}.get(vfilter) if vfilter else None
    print(f"Sheet: {args.sheet} | 模式: {mode} | 排序: cost | 取前 {args.top}"
          + (f" (仅 verdict={vfilter})" if vfilter else '')
          + f" (候选 {len(rows)}, 共 {ws.max_row-1} 行)")
    if args.ets_only:
        print(f"  (ets-only 过滤: 跳过非ets {skipped_nonets}, 无法定位 {skipped_unresolved})")
    print(f"项目根: {root} | 缓存: {args.cache or '无'} (载入 {len(memo)} 条)")
    print("=" * 92)

    results = []
    checked_ets = 0
    for cost, r, parsed, raw, entry, status in rows:
        if len(results) >= args.top:
            break
        if status is not None:
            # skip/unresolved: 仅在无 verdict 过滤时计入
            if not vfilter:
                if status == 'skip-parse':
                    results.append((r, raw, cost, 'skip', '解析失败(@native 等)', None))
                elif status.startswith('skip-'):
                    results.append((r, raw, cost, 'skip', f'非ets({status[5:]})', None))
                else:
                    results.append((r, raw, cost, 'unresolved', f'无法定位 ({parsed["module"]})', None))
            continue
        ap_entry = os.path.abspath(entry)
        is_cached = ap_entry in memo
        if is_cached:
            v = memo[ap_entry]
            cache_hits += 1
        else:
            v = ct.check_recursive(ap_entry, memo, set(), 0, 50)
            memo[ap_entry] = v
        checked_ets += 1
        if target_v and v != target_v:
            continue  # 不匹配, 继续往下找
        note = ('[缓存] ' if is_cached else '') + os.path.relpath(entry, root)
        results.append((r, raw, cost, v, note, ap_entry))
    print(f"(遍历检查 {checked_ets} 个 ets 候选, 命中 {len(results)} 个"
          + (f" verdict={vfilter}" if vfilter else '') + ")")

    save_cache(args.cache, memo)

    # ---- why 计算 ----
    label = {'TRUE': 'true', 'FALSE': 'false', 'MAYBE': 'maybe', 'skip': 'skip', 'unresolved': 'unresolved'}
    has_map = {'FALSE': 'true', 'TRUE': 'false', 'MAYBE': 'maybe', 'skip': 'skip', 'unresolved': 'unresolved'}
    why_list = []
    for r, raw, cost, v, note, ap_entry in results:
        vk = v if isinstance(v, str) else 'skip'
        if vk == 'FALSE' and ap_entry:
            src = find_false_source(ap_entry, memo, root)
            if src:
                s_ap, hit, depth = src
                rels = os.path.relpath(s_ap, root)
                where = '自身' if depth == 0 else f'闭包(深度{depth})'
                why = f"{where}: {rels}"
                if hit:
                    why += f" L{hit[0]} {hit[1]}"
            else:
                why = '存在 top-level (未定位到具体行)'
        elif vk == 'MAYBE' and ap_entry:
            info = ct.check_file(ap_entry)
            dec = info.get('decorator_count', 0)
            why = f'装饰器 {dec} (maybe)' if dec else '无法解析 import (maybe)'
        elif vk == 'TRUE':
            why = '闭包内无 top-level 代码'
        else:
            why = note
        why_list.append(why)

    # ---- 控制台输出 ----
    mfmt = lambda v: f'{v:>12.3f}'
    print(f"{'row':>5} {metric_name:>12} {'verdict':<8} {'has_tl':<7} {'文件/why'}")
    print("-" * 92)
    cnt = {}
    for (r, raw, cost, v, note, ap_entry), why in zip(results, why_list):
        vk = v if isinstance(v, str) else 'skip'
        disp = label.get(vk, vk)
        has = has_map.get(vk, vk)
        cnt[disp] = cnt.get(disp, 0) + 1
        print(f"{r:>5} {mfmt(cost)} {disp:<8} {has:<7} {why}")
        print(f"{'':>5} {'':>12} {'':<8} {'':<7} B: {raw[:70]}")
    print("-" * 92)
    print(f"汇总: {cnt}  (缓存命中 {cache_hits})")

    # ---- 写报告 xlsx ----
    base = os.path.basename(args.xlsx)
    app_name = base.replace('_redundant_file_report.xlsx', '').replace('.xlsx', '') or 'report'
    ts = datetime.now().strftime('%Y%m%d_%H%M%S')
    out_path = args.out or f'{app_name}_{ts}.xlsx'
    wb_out = openpyxl.Workbook()
    ws_out = wb_out.active
    ws_out.title = args.sheet[:31]
    headers = ['报表row', 'File Path', 'Cost Time (ms)', 'Parent Modules',
               'has_toplevel', 'why']
    from openpyxl.styles import Font, PatternFill, Alignment
    hf = Font(bold=True, color='FFFFFF')
    hfill = PatternFill(start_color='4472C4', end_color='4472C4', fill_type='solid')
    for ci, h in enumerate(headers, 1):
        c = ws_out.cell(row=1, column=ci, value=h)
        c.font = hf
        c.fill = hfill
        c.alignment = Alignment(horizontal='center')
    # 源表列名→列号映射（按列名取值，兼容 4 列报表）
    src_headers = [ws.cell(1, c).value for c in range(1, ws.max_column + 1)]
    src_col = {}
    for i, h in enumerate(src_headers, 1):
        if h is not None and h not in src_col:
            src_col[h] = i
    out_cols = ['File Path', 'Cost Time (ms)', 'Parent Modules']
    for ri, ((r, raw, cost, v, note, ap_entry), why) in enumerate(zip(results, why_list), 2):
        vk = v if isinstance(v, str) else 'skip'
        # 首列写源表工作表行号(=stdout 显示的 row), 供 Phase 5 --safe-rows 精确回连
        ws_out.cell(row=ri, column=1, value=r)
        for ci, name in enumerate(out_cols, 2):
            ws_out.cell(row=ri, column=ci, value=ws.cell(r, src_col[name]).value if name in src_col else None)
        ws_out.cell(row=ri, column=5, value=has_map.get(vk, vk))
        ws_out.cell(row=ri, column=6, value=why)
    # 列宽
    for ci, w in enumerate([6, 60, 14, 80, 12, 70], 1):
        ws_out.column_dimensions[openpyxl.utils.get_column_letter(ci)].width = w
    ws_out.freeze_panes = 'A2'
    wb_out.save(out_path)
    print(f"报告已生成: {out_path}")


if __name__ == '__main__':
    main()
