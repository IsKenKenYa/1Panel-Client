#!/usr/bin/env python3
"""
Phase 6 修改应用: 先预览生成 diff 与计划文件, 用户选择后再按计划应用 import lazy 改写。

顺序不可绕过: 预览(只生成, 不写源码) → 用户选择 → 应用(只执行计划)。
--apply 必须携带预览产出的计划文件, 不支持"生成并一步应用"。

模式:
  预览 (默认 / --diff): 读 safe_importers 报表中「可lazy? = 可」行, 逐行校验后输出
      unified diff 与排除明细, 并把拟改写内容(文件:行号 + 改写前后内容)写入
      计划文件 lazy_apply_plan_{时间戳}.json
  --apply: 只执行计划文件内容, 不重新圈定范围; 逐行复核当前源码与计划记录一致才写

安全约束:
  - 仅处理「可lazy? = 可」行; 暂不可(re-export)/待确认/空 一律不碰
  - 预览校验: 行号未越界、行内容与报告生成时一致(前 200 字符)、是普通 import
    (非 import lazy / import type / 同行多 import); 失败的行排除在计划外并给原因
  - 应用复核: 当前行已是计划改写后内容 → 计"已应用过"; 与计划记录的原内容不符 →
    跳过并提示重新预览; 一致才写入
  - 不执行任何 git 操作

用法:
  预览: python3 apply_lazy_imports.py <safe_importers.xlsx> --root <项目根> [--rows "5,7"]
  应用: python3 apply_lazy_imports.py --apply --plan <lazy_apply_plan_*.json> --root <项目根>
"""

import os
import re
import sys
import json
import difflib
import argparse
from datetime import datetime

try:
    import openpyxl
except ImportError:
    os.system(f"{sys.executable} -m pip install openpyxl")
    import openpyxl

PLAN_VERSION = 1


def print_diff(changed_files):
    for rel, (old, new) in sorted(changed_files.items()):
        print(f'==== {rel} ====')
        sys.stdout.writelines(difflib.unified_diff(
            old, new, fromfile=f'a/{rel}', tofile=f'b/{rel}', lineterm='\n'))


def run_preview(args):
    root = os.path.abspath(args.root)
    wb = openpyxl.load_workbook(args.report, data_only=True)
    ws = wb.active
    headers = [str(ws.cell(1, c).value or '').strip() for c in range(1, ws.max_column + 1)]
    need = ['报表row', 'parentModule文件', '引用代码行', '行号', '可lazy?']
    missing = [h for h in need if h not in headers]
    if missing:
        print(f"错误: 输入不是 safe_importers 报表, 缺列: {missing}; 可用列: {headers}")
        sys.exit(1)
    idx = {h: i for i, h in enumerate(headers)}

    rows_filter = None
    if args.rows:
        rows_filter = {int(x.strip()) for x in args.rows.split(',') if x.strip()}

    # 收集目标行: {文件相对路径: [(行号, 报告中的引用代码行, 报表row), ...]}
    targets = {}
    skipped = []
    seen = set()
    for r in range(2, ws.max_row + 1):
        def cell(h):
            v = ws.cell(r, idx[h] + 1).value
            return '' if v is None else str(v).strip()
        try:
            row_id = int(float(ws.cell(r, idx['报表row'] + 1).value))
        except (TypeError, ValueError):
            continue
        if cell('可lazy?') != '可':
            continue
        if rows_filter is not None and row_id not in rows_filter:
            continue
        rel = cell('parentModule文件')
        try:
            lineno = int(float(ws.cell(r, idx['行号'] + 1).value))
        except (TypeError, ValueError):
            skipped.append((row_id, rel, cell('行号'), '行号非数字'))
            continue
        if not rel or rel.startswith('('):
            skipped.append((row_id, rel, lineno, 'parentModule文件无效'))
            continue
        key = (rel, lineno)
        if key in seen:      # 同文件同行只处理一次
            continue
        seen.add(key)
        targets.setdefault(rel, []).append((lineno, cell('引用代码行'), row_id))

    if not targets and not skipped:
        print('没有可应用的行 (可lazy? = 可 且通过 --rows 过滤)')
        sys.exit(0)

    entries = []       # 计划条目: {row, file, lineno, old, new}
    changed_files = {}  # 仅供本次预览 diff 展示
    n_planned = 0
    for rel, items in sorted(targets.items()):
        path = os.path.join(root, rel)
        if not os.path.isfile(path):
            skipped.extend((row_id, rel, '-', '文件不存在') for _, _, row_id in items)
            continue
        try:
            with open(path, encoding='utf-8') as f:   # strict: 不允许编码降级写回
                text = f.read()
        except UnicodeDecodeError:
            skipped.extend((row_id, rel, ln, '文件编码非 UTF-8, 请人工处理')
                           for ln, _, row_id in items)
            continue
        lines = text.splitlines(keepends=True)
        new_lines = list(lines)
        for lineno, expected, row_id in sorted(items, key=lambda x: x[0]):
            if lineno < 1 or lineno > len(lines):
                skipped.append((row_id, rel, lineno, '行号越界 (文件已变动?)'))
                continue
            s = new_lines[lineno - 1].strip()
            if expected and s[:200] != expected[:200]:
                skipped.append((row_id, rel, lineno, '行内容与报告不符 (报告生成后源码已变动? 请重跑 Phase 5)'))
                continue
            if re.match(r'import\s+lazy\b', s):
                skipped.append((row_id, rel, lineno, '已是 import lazy'))
                continue
            if re.match(r'import\s+type\b', s):
                skipped.append((row_id, rel, lineno, 'import type 不改写'))
                continue
            if not re.match(r'import\b', s) or 'from' not in s:
                skipped.append((row_id, rel, lineno, '不是 import ... from 语句'))
                continue
            if len(re.findall(r'\bimport\b', s)) > 1:
                skipped.append((row_id, rel, lineno, '同行多个 import, 请人工处理'))
                continue
            new_s = re.sub(r'^import\b', 'import lazy', s, count=1)
            new_lines[lineno - 1] = new_lines[lineno - 1].replace(s, new_s, 1)
            entries.append({'row': row_id, 'file': rel, 'lineno': lineno, 'old': s, 'new': new_s})
            n_planned += 1
        if any(a is not b for a, b in zip(lines, new_lines)):
            changed_files[rel] = (lines, new_lines)

    if not entries:
        print('所有目标行均校验失败, 未生成计划:')
        for row_id, rel, lineno, reason in skipped:
            print(f'  row {row_id} {rel}:{lineno} — {reason}')
        sys.exit(1)

    print_diff(changed_files)
    print('-' * 60)
    print(f'预览: 拟改写 {n_planned} 行, 排除 {len(skipped)} 行, 涉及 {len(changed_files)} 个文件')
    for row_id, rel, lineno, reason in skipped:
        print(f'  排除 row {row_id} {rel}:{lineno} — {reason}')

    ts = datetime.now().strftime('%Y%m%d_%H%M%S')
    plan_path = f'lazy_apply_plan_{ts}.json'
    with open(plan_path, 'w', encoding='utf-8') as f:
        json.dump({'_version': PLAN_VERSION, 'created': ts,
                   'report': os.path.basename(args.report), 'root': root,
                   'entries': entries, 'excluded': skipped},
                  f, ensure_ascii=False, indent=2)
    print(f'计划已生成: {plan_path} (未写任何源码文件)')
    print(f'下一步: 把 diff 呈现给用户选择是否应用; 应用命令: '
          f'{os.path.basename(__file__)} --apply --plan {plan_path} --root {root}')


def run_apply(args):
    root = os.path.abspath(args.root)
    if not os.path.isfile(args.plan):
        print(f'错误: 计划文件不存在: {args.plan}; 请重新预览生成计划')
        sys.exit(1)
    try:
        with open(args.plan, encoding='utf-8') as f:
            plan = json.load(f)
        if not isinstance(plan, dict) or plan.get('_version') != PLAN_VERSION:
            raise ValueError('版本不识别')
        entries = plan.get('entries') or []
        if not entries:
            raise ValueError('无条目')
        for e in entries:      # 触发字段校验, 缺键即视为损坏
            e['row'], e['file'], e['lineno'], e['old'], e['new']
    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        print('错误: 计划文件损坏、格式或版本不识别, 请重新预览生成计划')
        sys.exit(1)

    by_file = {}
    for e in entries:
        by_file.setdefault(e['file'], []).append(e)

    changed_files = {}
    skipped = []
    n_applied = n_already = 0
    for rel, items in sorted(by_file.items()):
        path = os.path.join(root, rel)
        if not os.path.isfile(path):
            skipped.extend((e['row'], rel, e['lineno'], '文件不存在') for e in items)
            continue
        try:
            with open(path, encoding='utf-8') as f:
                text = f.read()
        except UnicodeDecodeError:
            skipped.extend((e['row'], rel, e['lineno'], '文件编码非 UTF-8') for e in items)
            continue
        lines = text.splitlines(keepends=True)
        new_lines = list(lines)
        for e in sorted(items, key=lambda x: x['lineno']):
            ln = e['lineno']
            if ln < 1 or ln > len(lines):
                skipped.append((e['row'], rel, ln, '行号越界 (源码已变动?)'))
                continue
            s = new_lines[ln - 1].strip()
            if s == e['new']:
                n_already += 1     # 预览后可能已被应用过
                continue
            if s[:200] != e['old'][:200]:
                skipped.append((e['row'], rel, ln, '行内容与计划不符 (预览后源码已变动? 请重新预览)'))
                continue
            new_lines[ln - 1] = new_lines[ln - 1].replace(s, e['new'], 1)
            n_applied += 1
        if any(a is not b for a, b in zip(lines, new_lines)):
            changed_files[rel] = (lines, new_lines)

    if n_applied:
        print_diff(changed_files)
        print('-' * 60)
    print(f'汇总: 计划 {len(entries)} 行 -> 实际写入 {n_applied} 行, '
          f'已应用过 {n_already} 行, 跳过 {len(skipped)} 行')
    for row, rel, ln, reason in skipped:
        print(f'  跳过 row {row} {rel}:{ln} — {reason}')

    if not n_applied:
        print('未写入任何文件')
        sys.exit(1)
    for rel, (old, new) in changed_files.items():
        with open(os.path.join(root, rel), 'w', encoding='utf-8', newline='') as f:
            f.write(''.join(new))
    print(f'已按计划应用: 写入 {len(changed_files)} 个文件; '
          f'请执行 hvigorw assembleHap 构建验证, 并可用 git diff 复查')


def main():
    ap = argparse.ArgumentParser(description="Phase 6: 预览生成 diff/计划文件, 用户选择后按计划应用 import lazy 改写")
    ap.add_argument('report', nargs='?', help='safe_importers_*.xlsx (预览模式必填; --apply 模式不需要)')
    ap.add_argument('--root', required=True, help='项目根 (parentModule文件 列为相对根的路径)')
    ap.add_argument('--diff', action='store_true', help='预览模式 (默认): 只生成 diff 与计划文件, 不写源码')
    ap.add_argument('--apply', action='store_true', help='应用模式: 按计划文件执行 (需 --plan)')
    ap.add_argument('--plan', default=None, help='预览生成的计划文件 lazy_apply_plan_*.json (--apply 必填)')
    ap.add_argument('--rows', default=None, help='(仅预览) 仅纳入这些报表row 的模块 (逗号分隔; 默认全部可lazy?=可)')
    args = ap.parse_args()

    if args.diff and args.apply:
        print('错误: --diff 与 --apply 互斥')
        sys.exit(1)
    if args.apply:
        if not args.plan:
            print('错误: --apply 必须携带预览生成的计划文件 (--plan <lazy_apply_plan_*.json>);\n'
                  '请先运行预览生成 diff, 经用户选择后再应用 —— 不支持"生成并一步应用"')
            sys.exit(1)
        if args.rows:
            print('错误: --rows 仅用于预览模式, 应用范围以计划文件为准')
            sys.exit(1)
        run_apply(args)
    else:
        if args.plan:
            print('错误: --plan 仅用于 --apply 模式')
            sys.exit(1)
        if not args.report:
            print('错误: 预览模式需要 safe_importers 报表路径')
            ap.print_usage()
            sys.exit(1)
        run_preview(args)


if __name__ == '__main__':
    main()
