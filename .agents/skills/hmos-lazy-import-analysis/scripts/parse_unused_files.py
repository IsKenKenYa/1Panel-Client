#!/usr/bin/env python3
"""
Redundant File Report Analyzer - 行解析器
====================================================
读取 redundant file xlsx 报表中的 "Unused Files"（或 "Used Files"）sheet，逐行解析。

解析规则（适用于 B 列 File Path 整值 与 D 列 Parent Modules 的每一行）：
  规则1 (.so)   :  @normalized:Y&&&{so_name}&   →  提取 {so_name}
  规则2 (ohos)  :  以 @ohos: 开头              →  原样保留
  规则2 (hms)   :  以 @hms: 开头               →  原样保留
  规则3 (&带版本):  &{path}&{version}          →  剥离版本号，取 {path}
                    其中 path 可能以 @group/module 开头，也可能以 module 开头
  规则3变体(无版本): &{path}&                 →  取 {path}，version=None
  其余           :  报错（不跳过）

  原样保留的系统/kit 模块（规则2c/2d）：
    - @native:... (ohos native 模块)
    - com.huawei.* (华为 kit 模块，反向域名风格路径)

  数据截断（非规则问题）：单元格字符数达 Excel 上限 32767 时，该行 parentModule 列表
  被截断、末尾残片不可靠。本脚本按“单元格长度 ≥ 32767”直接判定，列出受影响行。

用法:
  python3 parse_unused_files.py <xlsx路径>
  python3 parse_unused_files.py <xlsx路径> --sheet "Used Files"
  python3 parse_unused_files.py <xlsx路径> --max 10
  python3 parse_unused_files.py <xlsx路径> --stop-on-error
"""

import re
import sys
import os
import argparse
from collections import defaultdict

try:
    import openpyxl
except ImportError:
    os.system(f"{sys.executable} -m pip install openpyxl")
    import openpyxl


# ───────────────────────── 常量 ─────────────────────────

# Excel 单元格字符上限：达到此值视为被截断（非规则问题）
EXCEL_CELL_LIMIT = 32767

# ───────────────────────── 正则定义 ─────────────────────────

# 规则1: @normalized:Y&&&{so_name}&   so_name 不含 &
SO_RE = re.compile(r'^@normalized:([A-Z])&&&([^&]+)&$')

# 规则3: &{path}&{version}   path 不含 &；version 以数字开头
AMP_VER_RE = re.compile(r'^&([^&]+)&([0-9][0-9A-Za-z.\-+]*)$')

# 规则3 变体: &{path}&  末尾带 & 但无版本号
AMP_NOVER_RE = re.compile(r'^&([^&]+)&$')


# ───────────────────────── 异常 ─────────────────────────

class ParseError(Exception):
    """解析规则未覆盖时抛出。"""

    def __init__(self, raw, reason, detail=None):
        self.raw = raw
        self.reason = reason
        self.detail = detail or {}
        super().__init__(f"{reason}: {raw!r}  detail={self.detail}")


# ───────────────────────── &-style 结果构造 ─────────────────────────

def _build_amp_result(raw, path, version):
    """根据 path 前缀区分 group_module / module，构造 &-style 解析结果。"""
    if path.startswith("@"):
        # &@group/module/... → 顶层 = @group/module
        parts = path.split("/", 2)  # ['@group', 'module', 'rest...']
        module_id = "/".join(parts[:2]) if len(parts) >= 2 else path
        kind = "group_module"
    else:
        # &module/... → 顶层 = path 第一段
        module_id = path.split("/", 1)[0]
        kind = "module"
    return {
        "raw": raw, "kind": kind, "value": path,
        "version": version, "module": module_id,
    }


# ───────────────────────── 单条路径解析 ─────────────────────────

def parse_module_path(raw):
    """解析单个模块路径字符串（B 列整值 或 D 列单行）。

    返回 dict:
      raw     : 原始字符串
      kind    : so | ohos | hms | group_module | module
      value   : 解析后的标识/路径
                 - so          → so_name (如 'libfoo.so')
                 - ohos/hms    → 原样 (如 '@ohos:web.webview')
                 - group_module → path (如 '@groupname/pkg6/.../Config')
                 - module      → path (如 'module_b/.../FooUtils')
      version : 版本号（&-style 带版本时），无版本时为 None
      module  : 顶层模块标识，便于后续聚合分析
    不符合规则时抛 ParseError（不跳过）。
    """
    s = str(raw).strip()
    if s == "":
        raise ParseError(raw, "空字符串")
    # 跨平台: 反斜杠路径归一化为正斜杠 (设备报告为正斜杠; Windows 工具二次加工的报表可能为反斜杠)
    s = s.replace("\\", "/")

    # 规则1: .so
    m = SO_RE.match(s)
    if m:
        flag, so_name = m.group(1), m.group(2)
        return {
            "raw": s, "kind": "so", "value": so_name,
            "version": None, "module": so_name, "so_flag": flag,
        }

    # 规则2a: @ohos
    if s.startswith("@ohos:"):
        return {"raw": s, "kind": "ohos", "value": s, "version": None, "module": s}

    # 规则2b: @hms
    if s.startswith("@hms:"):
        return {"raw": s, "kind": "hms", "value": s, "version": None, "module": s}

    # 规则2c: @native  (ohos native 模块，原样保留)
    if s.startswith("@native:"):
        return {"raw": s, "kind": "native", "value": s, "version": None, "module": s}

    # 规则2d: com.huawei.*  (华为 kit 模块，反向域名风格路径，原样保留)
    if s.startswith("com.huawei."):
        return {"raw": s, "kind": "huawei_kit", "value": s, "version": None, "module": s}

    # 规则3: &{path}&{version}  (带版本号)
    m = AMP_VER_RE.match(s)
    if m:
        return _build_amp_result(s, m.group(1), m.group(2))

    # 规则3 变体: &{path}&  (无版本号)
    m = AMP_NOVER_RE.match(s)
    if m:
        return _build_amp_result(s, m.group(1), None)

    # ── 以下为不符合规则的情况，报错（不跳过） ──

    # 以 & 开头但不匹配上述两种结构
    if s.startswith("&"):
        raise ParseError(
            raw, "以 & 开头但不匹配 &{path}&{version} 或 &{path}& 结构")

    # @native 等未识别的 @ 前缀（暂缓处理，保留为报错）
    if s.startswith("@"):
        m2 = re.match(r'^(@[^:/]+)', s)
        prefix = m2.group(1) if m2 else s[:20]
        raise ParseError(raw, f"未识别的 @ 前缀 {prefix!r}（暂缓）")

    raise ParseError(raw, "不符合任何解析规则")


# ───────────────────────── 整行解析 ─────────────────────────

def parse_row(row_idx, id_val, file_path, cost_time, parent_modules_raw):
    """解析一行数据。

    列1 ID: 原样保留
    列2 File Path: 按规则解析（parse_module_path）
    列3 Cost Time: 原样保留
    列4 Parent Modules: 可能多行，每行按规则解析（parse_module_path）
    遇到不符合规则的字段抛 ParseError。
    """
    fp = parse_module_path(file_path)

    parents = []
    if parent_modules_raw is not None and str(parent_modules_raw).strip() != "":
        for line in str(parent_modules_raw).split("\n"):
            line = line.strip()
            if line == "":
                continue
            parents.append(parse_module_path(line))

    return {
        "row": row_idx,
        "id": id_val,
        "file": fp,                          # parsed dict
        "cost_time_ms": cost_time,           # 列3 原样保留
        "parent_modules": parents,           # list[parsed dict]
    }


# ───────────────────────── 主流程 ─────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description="解析 redundant file xlsx 报表的 Unused/Used Files sheet（行解析）"
    )
    ap.add_argument("xlsx", help="xlsx 报表路径")
    ap.add_argument("--sheet", default="Unused Files", help="sheet 名 (默认 Unused Files)")
    ap.add_argument("--max", type=int, default=None, help="只解析前 N 行（调试）")
    ap.add_argument("--stop-on-error", action="store_true",
                    help="遇到第一个解析错误即停止（默认收集全部错误后统一报告）")
    args = ap.parse_args()

    if not os.path.exists(args.xlsx):
        print(f"错误: 文件不存在: {args.xlsx}")
        sys.exit(1)

    wb = openpyxl.load_workbook(args.xlsx, data_only=True)
    if args.sheet not in wb.sheetnames:
        print(f"错误: sheet 不存在: {args.sheet}")
        print(f"可用 sheet: {wb.sheetnames}")
        sys.exit(1)

    ws = wb[args.sheet]
    headers = [ws.cell(1, c).value for c in range(1, ws.max_column + 1)]
    # 列名 → 列号映射（1-based，首个匹配为准）
    col_map = {}
    for i, h in enumerate(headers, 1):
        if h is not None and h not in col_map:
            col_map[h] = i
    # 必需列校验
    required = ["ID", "File Path", "Parent Modules"]
    missing = [h for h in required if h not in col_map]
    if missing:
        print(f"错误: 报表缺少必需列: {missing}")
        print(f"实际表头: {headers}")
        sys.exit(1)
    # 按列名取值；可选数值列缺失则置 None（不影响解析）
    def cell(r, name):
        return ws.cell(r, col_map[name]).value if name in col_map else None

    data_rows = ws.max_row - 1
    print(f"Sheet: {args.sheet}")
    print(f"数据行数: {data_rows}, 表头: {headers}")
    print("=" * 70)

    parsed = []            # 完整解析成功
    rule_errors = []       # (row, error, col)  规则缺失
    trunc_rows = []        # (row, b, g_len, last_frag, frag_parsed, frag_reason)  数据截断
    limit = args.max

    for r in range(2, ws.max_row + 1):
        if limit is not None and (r - 1) > limit:
            break
        idv = cell(r, "ID")
        fp = cell(r, "File Path")
        ct = cell(r, "Cost Time (ms)")
        pm = cell(r, "Parent Modules")
        b_len = len(str(fp)) if fp is not None else 0
        g_len = len(str(pm)) if pm is not None else 0

        # ── 数据截断判定：单元格长度达 Excel 上限 → 该行 parent 列表被截断 ──
        if b_len >= EXCEL_CELL_LIMIT or g_len >= EXCEL_CELL_LIMIT:
            last_frag = None
            if pm is not None:
                for line in str(pm).split("\n"):
                    line = line.strip()
                    if line:
                        last_frag = line
            frag_parsed = None
            frag_reason = None
            if last_frag:
                try:
                    parse_module_path(last_frag)
                    frag_parsed = True
                except ParseError as e:
                    frag_parsed = False
                    frag_reason = e.reason
            trunc_rows.append((r, fp, max(b_len, g_len), last_frag, frag_parsed, frag_reason))
            if args.stop_on_error:
                print(f"\n[X] 第 {r} 行 数据截断 [单元格长度={max(b_len, g_len)}]")
                sys.exit(1)
            continue

        # ── 正常解析 ──
        try:
            row = parse_row(r, idv, fp, ct, pm)
            parsed.append(row)
        except ParseError as e:
            col = "B" if (fp is not None and str(e.raw).strip() == str(fp).strip()) else "D"
            rule_errors.append((r, e, col))
            if args.stop_on_error:
                print(f"\n[X] 第 {r} 行 {col} 列解析失败 [规则缺失]:")
                print(f"    原因: {e.reason}")
                print(f"    原值: {e.raw!r}")
                print(f"    详情: {e.detail}")
                sys.exit(1)

    # ── 摘要 ──
    total_issue = len(rule_errors) + len(trunc_rows)
    print(f"\n解析完成:")
    print(f"  成功: {len(parsed)} 行")
    print(f"  规则缺失: {len(rule_errors)} 处")
    print(f"  数据截断: {len(trunc_rows)} 处")

    # ── 数据截断 ──
    if trunc_rows:
        print("\n" + "=" * 70)
        print(f"[!] 数据截断 (Excel 单元格 {EXCEL_CELL_LIMIT} 字符上限, 非规则问题) -- {len(trunc_rows)} 处")
        print("  redundant_file_analyzer.py 把超大 parentModule 列表拼入单格导致截断，")
        print("  末尾残片不可靠（即使残片恰好可解析，版本/路径也可能是不完整的假数据）。")
        for r, b, clen, frag, frag_parsed, frag_reason in trunc_rows:
            tag = "✓残片可解析(但数据不完整)" if frag_parsed else f"[X]残片解析失败: {frag_reason}"
            print(f"\n  row {r}: B={b!r}  [单元格长度={clen}]")
            print(f"      末尾残片: {frag!r}")
            print(f"      {tag}")

    # ── 规则缺失 ──
    if rule_errors:
        print("\n" + "=" * 70)
        print(f"[!] 规则缺失 (需补充规则) -- {len(rule_errors)} 处")
        groups = defaultdict(list)
        for row_idx, e, col in rule_errors:
            groups[(e.reason, col)].append((row_idx, e))
        for (reason, col), items in groups.items():
            print(f"\n  [*] [{col}列] {reason}  --  共 {len(items)} 处")
            seen = {}
            for row_idx, e in items:
                seen.setdefault(e.raw, []).append(row_idx)
            for raw, rows in list(seen.items())[:8]:
                print(f"      原值: {raw!r}")
                print(f"      行号: {rows[:10]}{' ...' if len(rows) > 10 else ''}")
            if len(seen) > 8:
                print(f"      ... 另有 {len(seen) - 8} 种不同原值")

    # ── 成功样本（展示解析效果） ──
    if parsed:
        print("\n" + "=" * 70)
        print("解析样本（每种 kind 各取一条 B 列）")
        print("=" * 70)
        shown_kinds = set()
        for row in parsed:
            kind = row["file"]["kind"]
            if kind in shown_kinds:
                continue
            shown_kinds.add(kind)
            f = row["file"]
            print(f"\n[row {row['row']}] kind={kind}")
            print(f"  B 原值 : {f['raw']!r}")
            print(f"  B 解析 : value={f['value']!r}  version={f['version']!r}  module={f['module']!r}")
            if row["parent_modules"]:
                pm0 = row["parent_modules"][0]
                print(f"  G 原值 : {pm0['raw']!r}")
                print(f"  G 解析 : kind={pm0['kind']} value={pm0['value']!r} version={pm0['version']!r}")
                print(f"  G 模块数: {len(row['parent_modules'])}")
            if len(shown_kinds) >= 5:
                break

    # 非 0 退出码，便于上层感知有规则缺失/数据问题
    if total_issue:
        sys.exit(2)


if __name__ == "__main__":
    main()
