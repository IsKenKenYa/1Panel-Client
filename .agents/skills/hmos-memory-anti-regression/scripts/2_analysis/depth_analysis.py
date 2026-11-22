#!/usr/bin/env python3
"""HarmonyOS 内存防劣化分析流水线

根据归因 top10 SO 的 type_name 判断是否触发步骤 3 (ArkTS Heap)、步骤 4 (Native Heap) 和步骤 5 (SO_SIZE/HAP smaps)：
  - top10 SO 的 type_name 包含 ARKTS_HEAP → 触发步骤 3 + 步骤 4
  - top10 SO 的 type_name 不全是 SO_SIZE/HAP（不含 ARKTS_HEAP）→ 仅触发步骤 4
  - top10 SO 的 type_name 全是 SO_SIZE/HAP → 不触发步骤 3/4
  - top10 SO 的 type_name 包含 SO_SIZE 或 HAP → 触发步骤 5（与步骤 3/4 独立，可同时触发）

用法:
    python3 depth_analysis.py --new-summary <新版汇总.xlsx> [--old-summary <旧版汇总.xlsx>]
    python3 depth_analysis.py --new-dir <新版分析目录> [--old-dir <旧版分析目录>]
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from topdown import _parse_mm_dmabuf

ARKTS_HEAP_TYPE = "ARKTS_HEAP"
NO_TRIGGER_TYPES = {"SO_SIZE", "HAP"}
TOP_N_SO = 10
TOP_CHECK_SO = 5

VIRTUAL_CATEGORIES = {
    "其他", "ArkTS Heap分配器碎片", "ArkTS Heap未覆盖", "ArkTS Heap空服务",
    "Native Heap分配器碎片&未覆盖", "Native Heap空服务", "GL空服务", "GL分配器缓存",
    "DMA空服务", "DMA分配器碎片", "guard空服务", "guard分配器碎片",
    "AnonPage Other空服务", "AnonPage Other分配器碎片",
    ".db空服务", ".db分配器碎片", "dev空服务", "dev分配器碎片",
    "Filepage Other空服务", "Filepage Other分配器碎片",
}


def _find_summary_xlsx(directory: str) -> str | None:
    d = Path(directory)
    if not d.is_dir():
        return None
    for name in ["汇总.xlsx", "memory_native_summary.xlsx"]:
        p = d / name
        if p.exists():
            return str(p)
    for p in sorted(d.glob("*.xlsx")):
        if "汇总" in p.name or "summary" in p.name.lower():
            return str(p)
    return None


def load_summary(path: str) -> pd.DataFrame:
    df = pd.read_excel(path)
    col_map = {}
    for col in df.columns:
        cl = col.strip().lower()
        if cl in ("so", "so_path", "so_name"):
            col_map[col] = "so"
        elif cl in ("type_name", "type"):
            col_map[col] = "type_name"
        elif cl == "size":
            col_map[col] = "size"
        elif cl == "type_size":
            col_map[col] = "type_size"
    if col_map:
        df = df.rename(columns=col_map)
    return df


def extract_top_sos(df: pd.DataFrame, top_n: int = TOP_N_SO) -> list[dict]:
    size_col = None
    for c in ["size", "type_size"]:
        if c in df.columns:
            size_col = c
            break
    if size_col is None:
        for c in df.columns:
            if "size" in c.lower() and "ratio" not in c.lower():
                size_col = c
                break
    if size_col is None:
        return []

    df = df.copy()
    df[size_col] = pd.to_numeric(df[size_col], errors="coerce").fillna(0)
    so_col = "so" if "so" in df.columns else df.columns[0]
    type_col = "type_name" if "type_name" in df.columns else None

    so_agg = df.groupby(so_col).agg(
        total_size=(size_col, "sum"),
        type_names=(type_col, lambda x: list(x.dropna().unique()) if type_col and x.notna().any() else []),
    ).reset_index()

    so_agg = so_agg[~so_agg[so_col].isin(VIRTUAL_CATEGORIES)]
    so_agg = so_agg.sort_values("total_size", ascending=False).head(top_n)

    results = []
    for _, row in so_agg.iterrows():
        results.append({
            "so": row[so_col],
            "total_size_mb": round(row["total_size"], 2),
            "type_names": row["type_names"],
        })
    return results


def check_arkts_heap_in_top(top_sos: list[dict], top_check: int = TOP_CHECK_SO) -> dict:
    has_arkts = False
    arkts_sos = []
    all_no_trigger = True  # all type_names are SO_SIZE/HAP
    has_so_size_hap = False
    for so_info in top_sos[:top_check]:
        type_names = so_info["type_names"]
        if ARKTS_HEAP_TYPE in type_names:
            has_arkts = True
            arkts_sos.append(so_info["so"])
        for tn in type_names:
            if tn not in NO_TRIGGER_TYPES:
                all_no_trigger = False
            else:
                has_so_size_hap = True

    trigger_step3 = has_arkts
    trigger_step4 = not all_no_trigger
    trigger_step5 = has_so_size_hap

    if trigger_step3 and trigger_step4:
        decision = "trigger_step3_and_step4"
    elif trigger_step4:
        decision = "trigger_step4_only"
    else:
        decision = "no_deep_analysis"

    if trigger_step5:
        decision += "+step5"

    return {
        "has_arkts_heap": has_arkts,
        "arkts_heap_sos": arkts_sos,
        "all_so_size_hap": all_no_trigger,
        "has_so_size_hap": has_so_size_hap,
        "trigger_step3": trigger_step3,
        "trigger_step4": trigger_step4,
        "trigger_step5": trigger_step5,
        "decision": decision,
    }


def compare_summaries(old_df: pd.DataFrame, new_df: pd.DataFrame) -> pd.DataFrame:
    size_col = None
    for c in ["size", "type_size"]:
        if c in new_df.columns and c in old_df.columns:
            size_col = c
            break
    if size_col is None:
        return new_df

    so_col = "so" if "so" in new_df.columns else new_df.columns[0]
    type_col = "type_name" if "type_name" in new_df.columns else None

    new_df = new_df.copy()
    old_df = old_df.copy()
    new_df[size_col] = pd.to_numeric(new_df[size_col].astype(str).str.replace(r'\s*[Mm][Bb]$', '', regex=True), errors="coerce").fillna(0)
    old_df[size_col] = pd.to_numeric(old_df[size_col].astype(str).str.replace(r'\s*[Mm][Bb]$', '', regex=True), errors="coerce").fillna(0)

    new_agg = new_df.groupby([so_col] + ([type_col] if type_col else [])).agg(
        new_size=(size_col, "sum"),
    ).reset_index()
    old_agg = old_df.groupby([so_col] + ([type_col] if type_col else [])).agg(
        old_size=(size_col, "sum"),
    ).reset_index()

    merge_keys = [so_col] + ([type_col] if type_col else [])
    merged = new_agg.merge(old_agg, on=merge_keys, how="outer")
    merged["old_size"] = merged["old_size"].fillna(0)
    merged["new_size"] = merged["new_size"].fillna(0)
    merged["delta"] = merged["new_size"] - merged["old_size"]
    if so_col in merged.columns:
        merged = merged[~merged[so_col].isin(VIRTUAL_CATEGORIES)]
    merged = merged.sort_values("delta", ascending=False)
    return merged


def compare_dma(old_dmabuf: str, new_dmabuf: str, top_n: int = 20) -> pd.DataFrame:
    """对比两版本 DMA 数据，按 buf_type 和 buf_name 分别计算差值。"""
    old_df = _parse_mm_dmabuf(old_dmabuf)
    new_df = _parse_mm_dmabuf(new_dmabuf)
    if old_df is None or new_df is None:
        return pd.DataFrame()

    # 按 buf_type 对比
    old_by_type = old_df.groupby("buf_type")["size_mb"].sum().reset_index()
    new_by_type = new_df.groupby("buf_type")["size_mb"].sum().reset_index()
    old_by_type.columns = ["buf_type", "old_size_mb"]
    new_by_type.columns = ["buf_type", "new_size_mb"]
    type_merged = new_by_type.merge(old_by_type, on="buf_type", how="outer").fillna(0)
    type_merged["delta_mb"] = (type_merged["new_size_mb"] - type_merged["old_size_mb"]).round(2)
    type_merged = type_merged.sort_values("delta_mb", ascending=False)

    # 按 buf_name 对比
    old_by_name = old_df.groupby("buf_name")["size_mb"].sum().reset_index()
    new_by_name = new_df.groupby("buf_name")["size_mb"].sum().reset_index()
    old_by_name.columns = ["buf_name", "old_size_mb"]
    new_by_name.columns = ["buf_name", "new_size_mb"]
    name_merged = new_by_name.merge(old_by_name, on="buf_name", how="outer").fillna(0)
    name_merged["delta_mb"] = (name_merged["new_size_mb"] - name_merged["old_size_mb"]).round(2)
    name_merged = name_merged.sort_values("delta_mb", ascending=False)
    # 补充 buf_type
    buf_type_map = pd.concat([old_df, new_df]).groupby("buf_name")["buf_type"].apply(
        lambda x: x.value_counts().idxmax() if len(x) > 0 else ""
    ).to_dict()
    name_merged["buf_type"] = name_merged["buf_name"].map(buf_type_map)
    name_merged = name_merged.head(top_n)

    return type_merged, name_merged


def run_step3_arkts_heap(snapshot_a: str, snapshot_b: str, output_dir: str,
                         source_map: str = None, threshold_kb: float = 0.1):
    print("\n" + "=" * 60)
    print("  步骤 3: ArkTS Heap 深度分析")
    print("=" * 60)

    scripts_dir = Path(__file__).resolve().parent / ".." / "3_arkts_heap"
    shortest_path_script = scripts_dir / "shortest-path.mjs"
    compare_script = scripts_dir / "compare_diff.py"
    resolve_script = scripts_dir / "resolve-lines.py"

    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    sp_a = out / f"{Path(snapshot_a).stem}.shortest-path.json"
    sp_b = out / f"{Path(snapshot_b).stem}.shortest-path.json"

    print(f"  [3.1] 计算 A 版本 shortest-path: {snapshot_a}")
    subprocess.run(
        ["node", str(shortest_path_script), snapshot_a, "--all", "--merge", "--json"],
        cwd=str(out), check=True,
    )

    print(f"  [3.2] 计算 B 版本 shortest-path: {snapshot_b}")
    subprocess.run(
        ["node", str(shortest_path_script), snapshot_b, "--all", "--merge", "--json"],
        cwd=str(out), check=True,
    )

    compare_json = out / "arkts_compare.json"
    print(f"  [3.3] 对比差异: {sp_a} vs {sp_b}")
    subprocess.run(
        [sys.executable, str(compare_script), str(sp_a), str(sp_b),
         str(threshold_kb), "--json", str(compare_json), "--html"],
        check=True,
    )

    if source_map and Path(source_map).exists():
        resolved_json = out / "arkts_compare.resolved.json"
        print(f"  [3.4] 解析源码行号: {source_map}")
        subprocess.run(
            [sys.executable, str(resolve_script), str(compare_json), source_map,
             "--out", str(resolved_json)],
            check=True,
        )
    else:
        print("  [3.4] 跳过源码行号解析（未提供 sourceMap）")

    print("  步骤 3 完成")


def run_step4_native_heap(db_a: str, db_b: str, output_dir: str,
                          so_dir_a: str = None, so_dir_b: str = None,
                          addr2line: str = None, top_n: int = 20):
    print("\n" + "=" * 60)
    print("  步骤 4: Native Heap 深度分析")
    print("=" * 60)

    scripts_dir = Path(__file__).resolve().parent / ".." / "4_native_heap"
    diff_script = scripts_dir / "diff_htrace_db.py"
    resolve_script = scripts_dir / "resolve_diff_symbols.py"
    diagnose_script = scripts_dir / "diagnose_free_side.py"

    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    diff_json = out / "htrace_diff.json"
    print(f"  [4.1] A/B 版本差分: {db_a} vs {db_b}")
    cmd = [sys.executable, str(diff_script),
           "--db-a", db_a, "--db-b", db_b,
           "--top", str(top_n),
           "--output", str(diff_json)]
    if so_dir_a:
        cmd += ["--so-dir-a", so_dir_a]
    if so_dir_b:
        cmd += ["--so-dir-b", so_dir_b]
    subprocess.run(cmd, check=True)

    if (so_dir_a or so_dir_b) and addr2line:
        print(f"  [4.2] 解析源码行号")
        resolve_cmd = [sys.executable, str(resolve_script),
                       "--diff", str(diff_json),
                       "--top", str(top_n)]
        if so_dir_a:
            resolve_cmd += ["--so-dir-a", so_dir_a]
        if so_dir_b:
            resolve_cmd += ["--so-dir-b", so_dir_b]
        if addr2line:
            resolve_cmd += ["--addr2line", addr2line]
        subprocess.run(resolve_cmd, check=True)
    else:
        print("  [4.2] 跳过源码行号解析（缺少 SO 目录或 addr2line）")

    if diff_json.exists():
        with open(diff_json, encoding="utf-8") as f:
            diff_data = json.load(f)
        for d in diff_data.get("chain_diffs", [])[:top_n]:
            a_alloc = d.get("delta_total_alloc_MB", 0)
            b_unfreed = d.get("delta_unfreed_MB", 0)
            if abs(a_alloc) < 0.5 and b_unfreed > 1:
                b_cc_id = d.get("version_b", {}).get("callchain_id")
                a_cc_id = d.get("version_a", {}).get("callchain_id")
                if b_cc_id and db_b:
                    print(f"  [4.3] 释放端劣化诊断: callchain_id={b_cc_id}")
                    diag_cmd = [sys.executable, str(diagnose_script),
                                "--db", db_b,
                                "--callchain-id", str(b_cc_id)]
                    if a_cc_id and db_a:
                        diag_cmd += ["--db-a", db_a, "--callchain-id-a", str(a_cc_id)]
                    subprocess.run(diag_cmd, check=True)

    print("  步骤 4 完成")


def run_step5_so_size_hap(smaps_a: str, smaps_b: str, output_dir: str, top_n: int = 20):
    print("\n" + "=" * 60)
    print("  步骤 5: SO_SIZE/HAP smaps 对比分析")
    print("=" * 60)

    scripts_dir = Path(__file__).resolve().parent / ".." / "5_so_size_hap"
    diff_script = scripts_dir / "diff_smaps.py"

    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    diff_json = out / "smaps_diff.json"
    print(f"  [5.1] A/B smaps 对比: {smaps_a} vs {smaps_b}")
    cmd = [sys.executable, str(diff_script),
           "--smaps-a", smaps_a, "--smaps-b", smaps_b,
           "--top", str(top_n),
           "--json", str(diff_json)]
    subprocess.run(cmd, check=True)

    print("  步骤 5 完成")


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

def main():
    parser = argparse.ArgumentParser(
        description="HarmonyOS 内存防劣化分析流水线",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 仅判断触发决策（基于汇总表）
  python3 depth_analysis.py --new-summary output/new/analysis/汇总.xlsx

  # 基于两个版本的汇总表判断
  python3 depth_analysis.py --new-summary output/new/analysis/汇总.xlsx --old-summary output/old/analysis/汇总.xlsx

  # 自动发现目录下的汇总表并执行
  python3 depth_analysis.py --new-dir output/new/analysis --old-dir output/old/analysis

  # 判断 + 执行步骤 3/4/5
  python3 depth_analysis.py --new-dir output/new/analysis --old-dir output/old/analysis \\
      --snapshot-a old.heapsnapshot --snapshot-b new.heapsnapshot \\
      --db-a old.db --db-b new.db --output-dir output/pipeline \\
      --smaps-a old_smaps.txt --smaps-b new_smaps.txt
        """,
    )
    parser.add_argument("--new-summary", type=str, help="新版本汇总.xlsx 路径")
    parser.add_argument("--old-summary", type=str, help="旧版本汇总.xlsx 路径")
    parser.add_argument("--new-dir", type=str, help="新版本分析输出目录（自动查找汇总.xlsx）")
    parser.add_argument("--old-dir", type=str, help="旧版本分析输出目录（自动查找汇总.xlsx）")
    parser.add_argument("--top-n", type=int, default=TOP_N_SO, help=f"取 top N SO（默认 {TOP_N_SO}）")
    parser.add_argument("--top-check", type=int, default=TOP_CHECK_SO, help=f"检查前 N 个 SO 的 type_name（默认 {TOP_CHECK_SO}）")
    parser.add_argument("--output-dir", type=str, help="流水线输出目录")
    parser.add_argument("--json", type=str, help="输出决策 JSON 路径")

    step3_group = parser.add_argument_group("步骤 3 (ArkTS Heap)")
    step3_group.add_argument("--snapshot-a", type=str, help="旧版 heapsnapshot 文件")
    step3_group.add_argument("--snapshot-b", type=str, help="新版 heapsnapshot 文件")
    step3_group.add_argument("--source-map", type=str, help="sourceMap 文件路径")
    step3_group.add_argument("--threshold-kb", type=float, default=0.1, help="retained 增量阈值 KB（默认 0.1）")

    step4_group = parser.add_argument_group("步骤 4 (Native Heap)")
    step4_group.add_argument("--db-a", type=str, help="旧版 htrace .db 文件")
    step4_group.add_argument("--db-b", type=str, help="新版 htrace .db 文件")
    step4_group.add_argument("--so-dir-a", type=str, help="旧版 debug SO 目录")
    step4_group.add_argument("--so-dir-b", type=str, help="新版 debug SO 目录")
    step4_group.add_argument("--addr2line", type=str, help="addr2line 路径")
    step4_group.add_argument("--diff-top", type=int, default=20, help="Native Heap 差分 Top N（默认 20）")

    step5_group = parser.add_argument_group("步骤 5 (SO_SIZE/HAP smaps)")
    step5_group.add_argument("--smaps-a", type=str, help="旧版 smaps 文件")
    step5_group.add_argument("--smaps-b", type=str, help="新版 smaps 文件")

    dma_group = parser.add_argument_group("DMA 对比")
    dma_group.add_argument("--old-dmabuf", type=str, help="旧版 mm_dmabuf_info 文件路径")
    dma_group.add_argument("--new-dmabuf", type=str, help="新版 mm_dmabuf_info 文件路径")
    dma_group.add_argument("--dma-top", type=int, default=20, help="DMA 对比 Top N（默认 20）")

    parser.add_argument("--dry-run", action="store_true", help="仅输出决策，不执行步骤")
    args = parser.parse_args()

    new_summary_path = args.new_summary
    old_summary_path = args.old_summary

    if not new_summary_path and args.new_dir:
        new_summary_path = _find_summary_xlsx(args.new_dir)
        if not new_summary_path:
            print(f"错误: 在 {args.new_dir} 中未找到汇总.xlsx", file=sys.stderr)
            sys.exit(1)

    if not old_summary_path and args.old_dir:
        old_summary_path = _find_summary_xlsx(args.old_dir)

    if not new_summary_path:
        print("错误: 请通过 --new-summary 或 --new-dir 指定新版本汇总表", file=sys.stderr)
        sys.exit(1)

    if not Path(new_summary_path).exists():
        print(f"错误: 文件不存在: {new_summary_path}", file=sys.stderr)
        sys.exit(1)

    print(f"新版本汇总表: {new_summary_path}")
    new_df = load_summary(new_summary_path)

    if old_summary_path and Path(old_summary_path).exists():
        print(f"旧版本汇总表: {old_summary_path}")
        old_df = load_summary(old_summary_path)
        delta_df = compare_summaries(old_df, new_df)
        print(f"\n两版本 SO 差值 (Top {args.top_n} 增长):")
        print(delta_df.head(args.top_n).to_string(index=False))
    else:
        print("未提供旧版本汇总表，仅基于新版本归因结果判断")

    top_sos = extract_top_sos(new_df, top_n=args.top_n)
    if not top_sos:
        print("错误: 无法从汇总表中提取 SO 信息", file=sys.stderr)
        sys.exit(1)

    print(f"\nTop {args.top_n} SO (按内存占用排序):")
    print(f"  {'#':>3}  {'SO':<50}  {'Size(MB)':>10}  {'类型明细'}")
    print("  " + "-" * 100)
    for i, so_info in enumerate(top_sos):
        types_str = ", ".join(so_info["type_names"]) if so_info["type_names"] else "-"
        print(f"  {i+1:>3}  {so_info['so']:<50}  {so_info['total_size_mb']:>10.2f}  {types_str}")

    decision = check_arkts_heap_in_top(top_sos, top_check=args.top_check)

    print(f"\n{'=' * 60}")
    print(f"  决策结果")
    print(f"{'=' * 60}")
    print(f"  Top {args.top_check} SO 中 ARKTS_HEAP 类型: {'是' if decision['has_arkts_heap'] else '否'}")
    if decision["arkts_heap_sos"]:
        print(f"  包含 ARKTS_HEAP 的 SO: {', '.join(decision['arkts_heap_sos'])}")
    print(f"  触发步骤 3 (ArkTS Heap): {'是' if decision['trigger_step3'] else '否'}")
    print(f"  触发步骤 4 (Native Heap): {'是' if decision['trigger_step4'] else '否'}")
    print(f"  触发步骤 5 (SO_SIZE/HAP smaps): {'是' if decision['trigger_step5'] else '否'}")
    print(f"  决策: {decision['decision']}")

    if args.json:
        output = {
            "decision": decision,
            "top_sos": top_sos,
            "new_summary": str(new_summary_path),
            "old_summary": str(old_summary_path) if old_summary_path else None,
        }
        Path(args.json).write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"\n决策结果已保存到: {args.json}")

    # DMA 对比
    if args.old_dmabuf and args.new_dmabuf:
        if Path(args.old_dmabuf).exists() and Path(args.new_dmabuf).exists():
            print(f"\n{'=' * 60}")
            print(f"  DMA 对比分析")
            print(f"{'=' * 60}")
            type_diff, name_diff = compare_dma(args.old_dmabuf, args.new_dmabuf, top_n=args.dma_top)
            if not type_diff.empty:
                print(f"\n  DMA buf_type 差值:")
                print(type_diff.to_string(index=False))
            if not name_diff.empty:
                print(f"\n  DMA Top {args.dma_top} 图片/资源劣化:")
                print(name_diff.to_string(index=False))
        else:
            missing = []
            if not Path(args.old_dmabuf).exists():
                missing.append(args.old_dmabuf)
            if not Path(args.new_dmabuf).exists():
                missing.append(args.new_dmabuf)
            print(f"\nDMA 对比跳过: 文件不存在 {', '.join(missing)}")
    elif args.old_dmabuf or args.new_dmabuf:
        print("\nDMA 对比跳过: 需要同时提供 --old-dmabuf 和 --new-dmabuf")

    if args.dry_run:
        print("\n[dry-run] 仅输出决策，不执行步骤")
        return

    output_dir = args.output_dir
    if not output_dir:
        output_dir = str(Path(new_summary_path).parent / "pipeline_output")

    if decision["trigger_step3"]:
        if args.snapshot_a and args.snapshot_b:
            run_step3_arkts_heap(
                snapshot_a=args.snapshot_a,
                snapshot_b=args.snapshot_b,
                output_dir=output_dir,
                source_map=args.source_map,
                threshold_kb=args.threshold_kb,
            )
        else:
            print("\n步骤 3 需要触发，但未提供 --snapshot-a/--snapshot-b")
            print("  请手动执行:")
            print(f"    node scripts/3_arkts_heap/shortest-path.mjs <A.heapsnapshot> --all --merge --json")
            print(f"    node scripts/3_arkts_heap/shortest-path.mjs <B.heapsnapshot> --all --merge --json")
            print(f"    python3 scripts/3_arkts_heap/compare_diff.py A.shortest-path.json B.shortest-path.json --html --json")

    if decision["trigger_step4"]:
        if args.db_a and args.db_b:
            run_step4_native_heap(
                db_a=args.db_a,
                db_b=args.db_b,
                output_dir=output_dir,
                so_dir_a=args.so_dir_a,
                so_dir_b=args.so_dir_b,
                addr2line=args.addr2line,
                top_n=args.diff_top,
            )
        else:
            print("\n步骤 4 需要触发，但未提供 --db-a/--db-b")
            print("  请手动执行:")
            print(f"    python3 scripts/4_native_heap/diff_htrace_db.py --db-a <A.db> --db-b <B.db> --top 20 --output htrace_diff.json")
            print(f"    python3 scripts/4_native_heap/resolve_diff_symbols.py --diff htrace_diff.json --so-dir-a <A_SO> --so-dir-b <B_SO>")

    if decision["trigger_step5"]:
        if args.smaps_a and args.smaps_b:
            run_step5_so_size_hap(
                smaps_a=args.smaps_a,
                smaps_b=args.smaps_b,
                output_dir=output_dir,
                top_n=args.diff_top,
            )
        else:
            print("\n步骤 5 需要触发，但未提供 --smaps-a/--smaps-b")
            print("  请手动执行:")
            print(f"    python3 scripts/5_so_size_hap/diff_smaps.py --smaps-a <A_smaps> --smaps-b <B_smaps> --top 20 --json smaps_diff.json")

    print(f"\n流水线执行完成，输出目录: {output_dir}")


if __name__ == "__main__":
    main()
