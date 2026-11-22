#!/usr/bin/env python3
"""Generate comparison report for two versions."""
import pandas as pd
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from analysis_utils import diff_top10_so, EXCLUDED_TYPE_NAMES

def parse_mb(s):
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

# ===================== Topdown =====================
def parse_topdown(xlsx_path):
    """Parse topdown xlsx. Layout (header=None):
    Row 0: '页面总内存 XXX.XX MB' (page total header)
    Row 1: category headers like 'arkts heap (157.95 MB)', 'native heap (256.35 MB)', ...
    Row 2: sub-item labels like '可拆解内存', '未覆盖', '空服务', '分配器碎片'
    Row 3: sub-item values like '57.61 MB', '6.4 MB', '0 MB', '93.93 MB'
    """
    df = pd.read_excel(xlsx_path, header=None)
    categories = {}
    sub_items = {}

    # Page total from row 0
    page_header = str(df.iloc[0, 0]).strip() if pd.notna(df.iloc[0, 0]) else ""
    m_page = re.search(r'([\d.]+)\s*MB', page_header)
    if m_page:
        categories["页面总内存"] = float(m_page.group(1))

    # Category headers in row 1
    for col in range(df.shape[1]):
        val = str(df.iloc[1, col]).strip() if pd.notna(df.iloc[1, col]) else ""
        if not val or val == "nan":
            continue
        m = re.match(r'(.+?)\s*\(([\d.]+)\s*MB\)', val)
        if m:
            cat_name = m.group(1).strip()
            cat_total = float(m.group(2))
            categories[cat_name] = cat_total

    # Sub-items: scan row 2 (labels) and row 3 (values) for each category
    # Sub-items are organized in groups by category - the columns are contiguous
    # We need to match each sub-item group to its category
    # Strategy: find category header columns, then collect subsequent columns until next category
    cat_cols = []
    for col in range(df.shape[1]):
        val = str(df.iloc[1, col]).strip() if pd.notna(df.iloc[1, col]) else ""
        m = re.match(r'(.+?)\s*\(([\d.]+)\s*MB\)', val)
        if m:
            cat_cols.append((col, m.group(1).strip()))

    for i, (start_col, cat_name) in enumerate(cat_cols):
        end_col = cat_cols[i + 1][0] if i + 1 < len(cat_cols) else df.shape[1]
        subs = []
        for col in range(start_col, end_col):
            label = str(df.iloc[2, col]).strip() if pd.notna(df.iloc[2, col]) else ""
            value = str(df.iloc[3, col]).strip() if pd.notna(df.iloc[3, col]) else ""
            if label and label != "nan":
                vm = re.search(r'([\d.]+)\s*MB', value)
                subs.append((label, float(vm.group(1)) if vm else 0.0))
        if subs:
            sub_items[cat_name] = subs

    return categories, sub_items


def build_topdown_comparison():
    old_cats, old_subs = parse_topdown(f"{OLD_DIR}/analysis/topdown报告-默认场景.xlsx")
    new_cats, new_subs = parse_topdown(f"{NEW_DIR}/analysis/topdown报告-默认场景.xlsx")

    all_cats = list(dict.fromkeys(list(old_cats.keys()) + list(new_cats.keys())))

    # Sort: page total first, then by absolute delta descending, virtual categories last
    virtual_cats = {"分配器碎片", "空服务", "未覆盖", "其他", "(未命名)"}

    def sort_key(c):
        if c == "页面总内存":
            return (-1, 0)
        delta = new_cats.get(c, 0) - old_cats.get(c, 0)
        is_virtual = any(v in c for v in virtual_cats)
        return (is_virtual, -abs(delta))

    all_cats_sorted = sorted(all_cats, key=sort_key)

    lines = ["## 二、Topdown 总览对比\n"]
    lines.append(f"| 分类 | {OLD_LABEL} (MB) | {NEW_LABEL} (MB) | 差值 (MB) |")
    lines.append("|---|---|---|---|")

    old_total = old_cats.get("页面总内存", 0)
    new_total = new_cats.get("页面总内存", 0)
    delta_total = new_total - old_total
    lines.append(f"| **页面总内存** | **{old_total:.2f}** | **{new_total:.2f}** | **{delta_total:+.2f}** |")

    for cat in all_cats_sorted:
        if cat == "页面总内存":
            continue
        old_v = old_cats.get(cat, 0)
        new_v = new_cats.get(cat, 0)
        delta = new_v - old_v
        bold = "**" if abs(delta) > 5 else ""
        lines.append(f"| {bold}{cat}{bold} | {old_v:.2f} | {new_v:.2f} | {delta:+.2f} |")

    lines.append("\n---\n")
    return "\n".join(lines)


# ===================== 汇总表 =====================
def read_summary(xlsx_path):
    df = pd.read_excel(xlsx_path)
    # Forward-fill merged cells
    for col in ['场景', '一层领域', '一层领域占用', '一层领域占比', '二层领域', '二层领域占用', '二层领域占比', 'so']:
        if col in df.columns:
            df[col] = df[col].ffill()
    df['size_num'] = df['size'].apply(parse_mb)
    df['type_size_num'] = df['type_size'].apply(parse_mb)
    return df


def build_summary_comparison():
    df_old = read_summary(f"{OLD_DIR}/analysis/汇总.xlsx")
    df_new = read_summary(f"{NEW_DIR}/analysis/汇总.xlsx")

    # 一层领域对比
    old_first = df_old.groupby('一层领域')['size_num'].sum().reset_index()
    old_first.columns = ['一层领域', 'old_mb']
    new_first = df_new.groupby('一层领域')['size_num'].sum().reset_index()
    new_first.columns = ['一层领域', 'new_mb']
    merged = old_first.merge(new_first, on='一层领域', how='outer').fillna(0)
    merged['delta'] = merged['new_mb'] - merged['old_mb']
    merged = merged.sort_values('delta', ascending=False)

    lines = ["## 三、汇总表一层领域对比\n"]
    lines.append(f"| 一层领域 | {OLD_LABEL} (MB) | {NEW_LABEL} (MB) | 差值 (MB) |")
    lines.append("|---|---|---|---|")
    for _, r in merged.iterrows():
        bold = "**" if abs(r['delta']) > 5 else ""
        lines.append(f"| {bold}{r['一层领域']}{bold} | {r['old_mb']:.1f} | {r['new_mb']:.1f} | {r['delta']:+.1f} |")
    lines.append("\n---\n")

    # 层级结构 (差值 > 1MB)
    lines.append("## 四、汇总表层级结构\n")
    lines.append("<table>")
    lines.append(f"<tr><th>一层领域</th><th>二层领域</th><th>so</th><th>type_name</th><th>{OLD_LABEL}(MB)</th><th>{NEW_LABEL}(MB)</th><th>差值(MB)</th></tr>")

    # Build per (一层领域, 二层领域, so, type_name) aggregation
    def build_map(df):
        m = {}
        for _, row in df.iterrows():
            key = (str(row['一层领域']).strip(), str(row['二层领域']).strip(),
                   str(row['so']).strip(), str(row['type_name']).strip())
            m[key] = m.get(key, 0.0) + row['type_size_num']
        return m

    old_map = build_map(df_old)
    new_map = build_map(df_new)
    all_keys = set(old_map.keys()) | set(new_map.keys())

    rows = []
    for key in all_keys:
        old_v = old_map.get(key, 0.0)
        new_v = new_map.get(key, 0.0)
        delta = new_v - old_v
        if abs(delta) > 1.0:
            rows.append((key[0], key[1], key[2], key[3], old_v, new_v, delta))

    # Sort by 一层领域 delta sum, then within by 二层领域 delta, then within by delta
    from collections import defaultdict
    first_delta = defaultdict(float)
    for r in rows:
        first_delta[r[0]] += r[6]
    second_delta = defaultdict(float)
    for r in rows:
        second_delta[(r[0], r[1])] += r[6]
    so_delta = defaultdict(float)
    for r in rows:
        so_delta[(r[0], r[1], r[2])] += r[6]

    virtual = {"分配器碎片", "空服务", "未覆盖", "其他", "(未命名)"}

    def sort_key_group(r):
        fk = r[0]
        sk = r[1]
        is_virtual_first = any(v in fk for v in virtual)
        return (is_virtual_first, -first_delta[fk])

    sorted_first = sorted(set(r[0] for r in rows), key=lambda fk: (any(v in fk for v in virtual), -first_delta[fk]))

    def sort_key_second(r):
        is_virtual_second = any(v in r[1] for v in virtual)
        return (is_virtual_second, -second_delta[(r[0], r[1])])

    def sort_key_so(r):
        is_virtual_so = any(v in r[2] for v in virtual)
        return (is_virtual_so, -so_delta[(r[0], r[1], r[2])])

    def sort_key_type(r):
        return -r[6]

    for fk in sorted_first:
        fk_rows = [r for r in rows if r[0] == fk]
        if not fk_rows:
            continue
        sorted_seconds = sorted(set(r[1] for r in fk_rows),
                               key=lambda sk: (any(v in sk for v in virtual), -second_delta[(fk, sk)]))
        fk_count = len(fk_rows)
        first_written = False
        for sk in sorted_seconds:
            sk_rows = [r for r in fk_rows if r[1] == sk]
            if not sk_rows:
                continue
            sorted_sos = sorted(set(r[2] for r in sk_rows),
                                key=lambda sok: (any(v in sok for v in virtual), -so_delta[(fk, sk, sok)]))
            sk_count = len(sk_rows)
            second_written = False
            for sok in sorted_sos:
                sok_rows = [r for r in sk_rows if r[2] == sok]
                if not sok_rows:
                    continue
                sok_rows.sort(key=sort_key_type)
                so_count = len(sok_rows)
                so_written = False
                for r in sok_rows:
                    fk_cell = f'<td rowspan="{fk_count}">{fk}</td>' if not first_written else ""
                    sk_cell = f'<td rowspan="{sk_count}">{sk}</td>' if not second_written else ""
                    so_cell = f'<td rowspan="{so_count}">{sok}</td>' if not so_written else ""
                    lines.append(f"<tr>{fk_cell}{sk_cell}{so_cell}<td>{r[3]}</td><td>{r[4]:.1f}</td><td>{r[5]:.1f}</td><td>{r[6]:+.1f}</td></tr>")
                    first_written = True
                    second_written = True
                    so_written = True

    lines.append("</table>")
    lines.append("\n---\n")

    return "\n".join(lines)


# ===================== Top10 劣化 SO =====================
def build_top10():
    result = diff_top10_so(
        f"{OLD_DIR}/analysis/analysis_详细数据.xlsx",
        f"{NEW_DIR}/analysis/analysis_详细数据.xlsx",
    )

    # Read 汇总表 to get 一层领域/二层领域 for each SO
    df_old = read_summary(f"{OLD_DIR}/analysis/汇总.xlsx")
    df_new = read_summary(f"{NEW_DIR}/analysis/汇总.xlsx")

    # Build SO -> (一层领域, 二层领域) map
    so_to_field = {}
    for df in [df_old, df_new]:
        for _, row in df.iterrows():
            so_name = str(row['so']).strip()
            if so_name in EXCLUDED_TYPE_NAMES:
                continue
            short = os.path.basename(so_name)
            if short not in so_to_field:
                so_to_field[short] = (str(row['一层领域']).strip(), str(row['二层领域']).strip())

    # Read 详细数据 once (forward-fill merged-cell NaN, convert path → basename)
    df_old_det = pd.read_excel(f"{OLD_DIR}/analysis/analysis_详细数据.xlsx")
    df_new_det = pd.read_excel(f"{NEW_DIR}/analysis/analysis_详细数据.xlsx")
    df_old_det['so'] = df_old_det['so'].ffill()
    df_new_det['so'] = df_new_det['so'].ffill()
    df_old_det['so_short'] = df_old_det['so'].apply(lambda x: os.path.basename(str(x)))
    df_new_det['so_short'] = df_new_det['so'].apply(lambda x: os.path.basename(str(x)))
    df_old_det['size_num'] = df_old_det['size'].apply(parse_mb)
    df_new_det['size_num'] = df_new_det['size'].apply(parse_mb)

    # Fallback: 汇总表按明细阈值截断/折叠为「其他」时，SO 在 so_to_field 中查不到，
    # 从详细数据补齐归属领域（详细数据含全部 so 行，一层/二层领域列无合并单元格 NaN）
    for df_det in [df_old_det, df_new_det]:
        for _, row in df_det.iterrows():
            short = str(row['so_short']).strip()
            if short and short not in so_to_field:
                so_to_field[short] = (str(row['一层领域']).strip(), str(row['二层领域']).strip())

    lines = ["## 五、Top10 劣化 SO\n"]
    lines.append(f"> **排名规则**：以 SO 为键（非 SO+type_name），同一 SO 的多个 type_name 差值累加得出总差值，按总差值降序取前 10；排除虚拟分类。type_name 明细列标注各 type_name 的差值。\n")
    lines.append("| # | SO | 归属领域 | type_name 明细 | {}(MB) | {}(MB) | 差值(MB) |".format(OLD_LABEL, NEW_LABEL))
    lines.append("|---|---|---|---|---|---|---|")

    for idx, row in result.iterrows():
        so = row['so']
        delta = row['total_delta']
        detail = row['type_name_detail']
        field = so_to_field.get(so, ("", ""))
        field_str = f"{field[0]}/{field[1]}" if field[1] else field[0]

        old_total = df_old_det[df_old_det['so_short'] == so]['size_num'].sum()
        new_total = df_new_det[df_new_det['so_short'] == so]['size_num'].sum()

        lines.append(f"| {idx} | {so} | {field_str} | {detail} | {old_total:.1f} | {new_total:.1f} | {delta:+.2f} |")

    lines.append("\n---\n")
    return "\n".join(lines), result, so_to_field


# ===================== DMA 对比 =====================
def _to_float(v):
    try:
        return float(v) if v is not None else 0.0
    except (ValueError, TypeError):
        return 0.0


def _norm_str(v, default="NULL"):
    s = str(v).strip() if v is not None else ""
    return default if s in ("", "nan", "None", "NaN") else s


def _read_dma_by_buf_type(xlsx_path):
    """DMA_by_buf_type sheet → {buf_type: (size_mb, count)}。keep_default_na=False 保留 'NULL' 字符串。"""
    df = pd.read_excel(xlsx_path, sheet_name="DMA_by_buf_type", keep_default_na=False)
    cols = {str(c).strip().lower(): c for c in df.columns}
    bt_col = cols.get("buf_type")
    size_col = cols.get("size_mb") or cols.get("size (mb)") or cols.get("size")
    cnt_col = cols.get("count")
    m = {}
    for _, row in df.iterrows():
        bt = _norm_str(row[bt_col], "NULL")
        sz = _to_float(row[size_col])
        cnt = int(_to_float(row[cnt_col]))
        cur = m.get(bt, (0.0, 0))
        m[bt] = (cur[0] + sz, cur[1] + cnt)
    return m


def _read_dma_by_image(xlsx_path):
    """DMA_by_image sheet → {buf_name: (size_mb, count, buf_type)}。"""
    df = pd.read_excel(xlsx_path, sheet_name="DMA_by_image", keep_default_na=False)
    cols = {str(c).strip().lower(): c for c in df.columns}
    name_col = cols.get("buf_name")
    size_col = cols.get("size_mb") or cols.get("size (mb)") or cols.get("size")
    cnt_col = cols.get("count")
    bt_col = cols.get("buf_type")
    m = {}
    for _, row in df.iterrows():
        nm = _norm_str(row[name_col], "NULL")
        sz = _to_float(row[size_col])
        cnt = int(_to_float(row[cnt_col]))
        bt = _norm_str(row[bt_col], "NULL")
        cur = m.get(nm, (0.0, 0, bt))
        m[nm] = (cur[0] + sz, cur[1] + cnt, bt)
    return m


def build_dma_comparison():
    old_dma_path = f"{OLD_DIR}/analysis/dma_detail.xlsx"
    new_dma_path = f"{NEW_DIR}/analysis/dma_detail.xlsx"
    if not Path(old_dma_path).exists() or not Path(new_dma_path).exists():
        lines = ["## 六、DMA 对比分析\n"]
        missing = []
        if not Path(old_dma_path).exists():
            missing.append(OLD_LABEL)
        if not Path(new_dma_path).exists():
            missing.append(NEW_LABEL)
        lines.append(f"> {'/'.join(missing)} 版本 `dma_detail.xlsx` 缺失（mm_dmabuf_info 无数据或采集失败），跳过 DMA 对比。\n")
        return "\n".join(lines)
    old_bt = _read_dma_by_buf_type(old_dma_path)
    new_bt = _read_dma_by_buf_type(new_dma_path)
    old_img = _read_dma_by_image(old_dma_path)
    new_img = _read_dma_by_image(new_dma_path)

    old_total = sum(v[0] for v in old_bt.values())
    new_total = sum(v[0] for v in new_bt.values())
    delta_total = new_total - old_total
    old_cnt = sum(v[1] for v in old_bt.values())
    new_cnt = sum(v[1] for v in new_bt.values())

    lines = ["## 六、DMA 对比分析\n"]
    lines.append(f"> 数据来源：两版本 `analysis/dma_detail.xlsx` 的 `DMA_by_buf_type` / `DMA_by_image` sheet。DMA 合计 = `DMA_by_buf_type` 全行求和（应与 topdown Graph 相符）。\n")

    # 总览（对账）
    lines.append("### DMA 总览（对账）\n")
    lines.append(f"| 指标 | {OLD_LABEL} | {NEW_LABEL} | 差值 |")
    lines.append("|---|---|---|---|")
    lines.append(f"| DMA 合计（dma_detail） | {old_total:.2f} MB | {new_total:.2f} MB | {delta_total:+.2f} MB |")
    lines.append(f"| 缓冲区个数 | {old_cnt} | {new_cnt} | {new_cnt - old_cnt:+d} |")
    try:
        old_cats, _ = parse_topdown(f"{OLD_DIR}/analysis/topdown报告-默认场景.xlsx")
        new_cats, _ = parse_topdown(f"{NEW_DIR}/analysis/topdown报告-默认场景.xlsx")
        og = old_cats.get("Graph")
        ng = new_cats.get("Graph")
        if og is not None and ng is not None:
            lines.append(f"| topdown Graph（对账） | {og:.2f} MB | {ng:.2f} MB | {ng - og:+.2f} MB |")
            if abs(old_total - og) > 0.5 or abs(new_total - ng) > 0.5:
                lines.append(f"\n> dma_detail 合计与 topdown Graph 不一致，需排查采集/归因。")
    except Exception:
        pass
    lines.append("")

    # 5.1 Top10 图片/资源劣化
    lines.append("### 6.1 DMA Top10 图片/资源劣化\n")
    lines.append(f"> 按 buf_name 聚合后取差值降序前 10（仅正差值劣化项）。buf_name 用 `dma_detail.xlsx` 完整形式（topdown xlsx 会截断，勿照抄）。\n")
    lines.append(f"| # | buf_name | buf_type | {OLD_LABEL} (MB) | {NEW_LABEL} (MB) | 差值 (MB) |")
    lines.append("|---|---|---|---|---|---|")
    delta_rows = []
    for nm in set(list(old_img) + list(new_img)):
        o = old_img.get(nm, (0.0, 0, ""))
        n = new_img.get(nm, (0.0, 0, ""))
        delta_rows.append((nm, n[2] or o[2], o[0], n[0], n[0] - o[0]))
    delta_rows.sort(key=lambda x: x[4], reverse=True)
    for i, (nm, bt, o, n, d) in enumerate([r for r in delta_rows if r[4] > 0][:10], 1):
        label = nm
        lines.append(f"| {i} | {label} | {bt} | {o:.2f} | {n:.2f} | {d:+.2f} |")
    lines.append("")
    lines.append("\n---\n")
    return "\n".join(lines)


# ===================== Main =====================
if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="生成两版本对比报告")
    ap.add_argument("--old-dir", required=True, help="旧版目录 (output/myapp_8.0.21)")
    ap.add_argument("--new-dir", required=True, help="新版目录 (output/myapp_8.3.4)")
    ap.add_argument("--old-label", required=True, help="旧版标签 (v8.0.21)")
    ap.add_argument("--new-label", required=True, help="新版标签 (v8.3.4)")
    ap.add_argument("-o", "--output", help="输出 md 路径 (默认 output/对比报告_<old>_vs_<new>.md)")
    args = ap.parse_args()

    global OLD_DIR, NEW_DIR, OLD_LABEL, NEW_LABEL
    OLD_DIR = args.old_dir
    NEW_DIR = args.new_dir
    OLD_LABEL = args.old_label
    NEW_LABEL = args.new_label

    topdown_md = build_topdown_comparison()
    summary_md = build_summary_comparison()
    top10_md, top10_df, so_to_field = build_top10()
    dma_md = build_dma_comparison()

    # 先计算 Top10 劣化 SO 的步骤 3/4/5 分发
    step3_sos = []
    step4_sos = []
    step5_sos = []

    dma_only_sos = []  # 纯 DMA 型（无 SO_SIZE/HAP 明细），仅由第五章 DMA 对比覆盖

    for _, row in top10_df.iterrows():
        so = row['so']
        detail = row['type_name_detail']
        has_arkts = 'ARKTS_HEAP' in detail
        has_so_size_or_hap = 'SO_SIZE' in detail or 'HAP' in detail
        # DMA/SO_SIZE/HAP 均非 native heap 运行时分配（DMA 为 gralloc/dmabuf，不经 malloc），
        # htrace .db 的 native_hook 表无对应调用栈，全为这三种类型时不分发到步骤 4，
        # 否则步骤 4 聚类必然报"无匹配调用栈"、火焰图无法生成（libhdi.z.so/libbuffer_handle.z.so 教训）
        type_names = [t.strip().split(':')[0].strip() for t in detail.split(',')]
        all_non_native_heap = all(t in ('SO_SIZE', 'HAP', 'DMA') for t in type_names)

        if has_arkts:
            step3_sos.append(so)
            step4_sos.append(so)
        elif not all_non_native_heap:
            step4_sos.append(so)
        if has_so_size_or_hap:
            step5_sos.append(so)
        elif all_non_native_heap and 'DMA' in type_names:
            dma_only_sos.append(so)

    # 一、深度分析结果（首章，含严重性定级）
    deep_md = "## 一、深度分析结果\n\n"
    deep_md += f"**步骤 3 (ArkTS Heap) 触发 SO**: {', '.join(step3_sos) if step3_sos else '无'}\n\n"
    deep_md += f"**步骤 4 (Native Heap) 触发 SO**: {', '.join(step4_sos) if step4_sos else '无'}\n\n"
    deep_md += f"**步骤 5 (SO_SIZE/HAP smaps) 触发 SO**: {', '.join(step5_sos) if step5_sos else '无'}\n\n"
    if dma_only_sos:
        report += (
            "**DMA 型劣化 SO（type_name 仅含 DMA，无 SO_SIZE/HAP 明细）**: "
            f"{', '.join(dma_only_sos)}\n\n"
            "> 这类 SO 的内存为 gralloc/dmabuf 分配，不经 malloc，native_hook 无调用栈数据，"
            "步骤 3/4/5 均无法覆盖——归因依赖第五章 DMA 对比分析（dma_detail.xlsx 按 buf_type/buf_name 拆解）。\n\n"
        )
    deep_md += "（深度分析结果将在步骤 3/4/5 执行后填充）\n"

    report = f"# 应用冷启动内存对比：{OLD_LABEL} vs {NEW_LABEL}\n\n"
    report += deep_md + "\n---\n\n"
    report += topdown_md + "\n"
    report += summary_md + "\n"
    report += top10_md + "\n"
    report += dma_md + "\n"

    out_path = args.output or f"output/对比报告_{OLD_LABEL}_vs_{NEW_LABEL}.md"
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(report)
    print(f"对比报告已生成: {out_path}")
    print(f"\n=== 触发判定 ===")
    print(f"Step 3 (ArkTS Heap): {step3_sos}")
    print(f"Step 4 (Native Heap): {step4_sos}")
    print(f"Step 5 (SO_SIZE/HAP): {step5_sos}")
