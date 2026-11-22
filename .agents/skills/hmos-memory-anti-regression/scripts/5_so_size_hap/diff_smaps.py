#!/usr/bin/env python3
"""SO_SIZE/HAP smaps 对比分析。

对比 A/B 两个版本的 smaps 文件，提取 .so 和 .hap 映射，
按路径汇总 Pss 后计算差值，定位劣化的 SO/HAP 并给出根因分析和修复建议。

用法:
    python scripts/5_so_size_hap/diff_smaps.py \
        --smaps-a <A版本_smaps.txt> \
        --smaps-b <B版本_smaps.txt> \
        [--top 20] [--json <output.json>]
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Optional

# Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402

# smaps 地址行正则（与 hybrid_mod.py 保持一致）
ADDR_LINE_PATTERN = re.compile(
    r"^(?P<addr_range>[0-9a-fA-F]+-[0-9a-fA-F]+)"
    r"\s+(?P<perms>\S+)"
    r"\s+(?P<offset>\S+)"
    r"\s+(?P<dev>\S+)"
    r"\s+(?P<inode>\d+)"
    r"(?:\s+(?P<pathname>.+))?"
    r"$"
)

# 匹配 .so 或 .hap 文件路径
SO_HAP_PATTERN = re.compile(r"\.(so|hap)(\.\w+)?$", re.IGNORECASE)

# smaps 数值行正则（raw /proc/pid/smaps 格式）
NUM_LINE_PATTERN = re.compile(r"^(\w+):\s+(\d+)\s*kB\s*$")

# 目标 Category 值（hidumper --mem-smaps 格式）
TARGET_CATEGORIES = {".so", ".hap"}


def _is_raw_smaps(text: str) -> bool:
    """检测是否为 raw /proc/pid/smaps 格式（含地址行）。

    hidumper --mem-smaps 格式是表格，无地址行。
    """
    for line in text.splitlines():
        if line.strip() and ADDR_LINE_PATTERN.match(line):
            return True
    return False


def _parse_hidumper_smaps(text: str) -> dict[str, dict]:
    """解析 hidumper --mem-smaps 表格格式。

    每行: Size Rss Pss Shared_Clean Shared_Dirty Private_Clean Private_Dirty Swap SwapPss Counts Category Name
    值单位 KB。按 Name（文件路径）汇总。过滤 Category 为 .so 或 .hap 的行。
    """
    mappings: dict[str, dict] = {}
    for line in text.splitlines():
        line = line.rstrip()
        if not line or line.startswith("---") or line.startswith("Size "):
            continue
        # 跳过 header 续行（以空格开头且含 "Shared"/"Private"/"Category"/"Name"）
        if line.startswith(" ") and any(
            kw in line for kw in ("Shared", "Private", "Category", "Name", "Swap")
        ):
            continue

        # 分割: 前 11 列是数值/类别, 第 12 列是路径
        parts = line.split(None, 11)
        if len(parts) < 12:
            continue

        size_kb, rss_kb, pss_kb = parts[0], parts[1], parts[2]
        counts = parts[9]
        category = parts[10]
        name = parts[11].strip()

        if category not in TARGET_CATEGORIES:
            continue
        # 跳过 [anon] 等非文件路径
        if name.startswith("["):
            continue

        try:
            size_val = int(size_kb)
            rss_val = int(rss_kb)
            pss_val = int(pss_kb)
            cnt = int(counts)
        except ValueError:
            continue

        if name not in mappings:
            mappings[name] = {"pss_kb": 0, "rss_kb": 0, "size_kb": 0, "count": 0}
        mappings[name]["pss_kb"] += pss_val
        mappings[name]["rss_kb"] += rss_val
        mappings[name]["size_kb"] += size_val
        mappings[name]["count"] += cnt

    return mappings


def _parse_raw_smaps(text: str) -> dict[str, dict]:
    """解析 raw /proc/pid/smaps 格式（地址段 + 属性行）。

    每段以地址行开头，后续属性行含 Size/Rss/Pss。
    按 pathname 汇总，过滤 .so/.hap 路径。
    """
    mappings: dict[str, dict] = {}
    current_pathname: Optional[str] = None
    current_pss = 0
    current_rss = 0
    current_size = 0

    for line in text.splitlines():
        line = line.rstrip()
        if not line:
            continue

        addr_match = ADDR_LINE_PATTERN.match(line)
        if addr_match:
            if current_pathname and SO_HAP_PATTERN.search(current_pathname):
                key = current_pathname
                if key not in mappings:
                    mappings[key] = {"pss_kb": 0, "rss_kb": 0, "size_kb": 0, "count": 0}
                mappings[key]["pss_kb"] += current_pss
                mappings[key]["rss_kb"] += current_rss
                mappings[key]["size_kb"] += current_size
                mappings[key]["count"] += 1

            raw_path = addr_match.group("pathname")
            current_pathname = raw_path.strip() if raw_path else None
            current_pss = 0
            current_rss = 0
            current_size = 0
        else:
            num_match = NUM_LINE_PATTERN.match(line)
            if num_match:
                key = num_match.group(1)
                val = int(num_match.group(2))
                if key == "Pss":
                    current_pss = val
                elif key == "Rss":
                    current_rss = val
                elif key == "Size":
                    current_size = val

    if current_pathname and SO_HAP_PATTERN.search(current_pathname):
        key = current_pathname
        if key not in mappings:
            mappings[key] = {"pss_kb": 0, "rss_kb": 0, "size_kb": 0, "count": 0}
        mappings[key]["pss_kb"] += current_pss
        mappings[key]["rss_kb"] += current_rss
        mappings[key]["size_kb"] += current_size
        mappings[key]["count"] += 1

    return mappings


def parse_smaps(text: str) -> dict[str, dict]:
    """解析 smaps 文本，返回 {pathname: {pss_kb, rss_kb, size_kb, count}}。

    自动检测格式：hidumper --mem-smaps 表格格式 或 raw /proc/pid/smaps 格式。
    只提取 Category 为 .so/.hap 的映射（hidumper）或 pathname 以 .so/.hap 结尾的映射（raw）。
    """
    if _is_raw_smaps(text):
        return _parse_raw_smaps(text)
    return _parse_hidumper_smaps(text)


def diff_smaps(mappings_a: dict, mappings_b: dict, top_n: int = 20) -> list[dict]:
    """对比两个版本的 smaps 映射，按 Pss 差值降序排列。"""
    all_paths = set(mappings_a.keys()) | set(mappings_b.keys())
    results = []
    for path in all_paths:
        a = mappings_a.get(path, {"pss_kb": 0, "rss_kb": 0, "size_kb": 0, "count": 0})
        b = mappings_b.get(path, {"pss_kb": 0, "rss_kb": 0, "size_kb": 0, "count": 0})
        delta_pss = b["pss_kb"] - a["pss_kb"]
        results.append({
            "pathname": path,
            "basename": Path(path).name if path else "",
            "a_pss_mb": round(a["pss_kb"] / 1024, 2),
            "b_pss_mb": round(b["pss_kb"] / 1024, 2),
            "delta_pss_mb": round(delta_pss / 1024, 2),
            "a_rss_mb": round(a["rss_kb"] / 1024, 2),
            "b_rss_mb": round(b["rss_kb"] / 1024, 2),
            "a_size_mb": round(a["size_kb"] / 1024, 2),
            "b_size_mb": round(b["size_kb"] / 1024, 2),
            "a_segments": a["count"],
            "b_segments": b["count"],
            "is_new": path not in mappings_a,
            "is_removed": path not in mappings_b,
        })
    results.sort(key=lambda x: x["delta_pss_mb"], reverse=True)
    return results[:top_n]


def classify_pathname(pathname: str) -> str:
    """根据路径推断 SO/HAP 归属领域。"""
    p = pathname.lower()
    if ".hap" in p:
        return "HAP（应用安装包）"
    if "/arkui/" in p or "arkui" in p:
        return "ArkUI 组件"
    if "/arkts/" in p or "arkts" in p or "ecmascript" in p or "js_runtime" in p:
        return "ArkTS/JS 运行时"
    if "/ace/" in p or "ace_engine" in p:
        return "ACE 框架"
    if "flutter" in p:
        return "Flutter 运行时"
    if "react" in p or "hermes" in p:
        return "React Native 运行时"
    if "/sdk/" in p or "oh_sdk" in p:
        return "系统 SDK"
    if "graphic" in p or "render" in p or "gl_" in p or "vulkan" in p:
        return "图形/渲染"
    if "audio" in p or "media" in p or "camera" in p:
        return "音视频"
    if "network" in p or "net_" in p:
        return "网络"
    if "sqlite" in p or "rdb" in p or "preference" in p:
        return "数据库/存储"
    if "bundle" in p and "el1" in p:
        return "应用自身 SO"
    return "其他"


def analyze_root_cause(item: dict) -> tuple[str, str]:
    """根据差分结果推测根因，返回 (根因, 修复建议)。"""
    delta = item["delta_pss_mb"]
    basename = item["basename"]
    category = classify_pathname(item["pathname"])

    if item["is_new"]:
        return (
            f"新增映射：{basename} 在新版本中首次出现（{category}）",
            f"检查是否为新引入的依赖或新功能模块。如非必要，考虑延迟加载或移除。",
        )

    if item["is_removed"]:
        return (
            f"移除映射：{basename} 在新版本中已移除（{category}）",
            "移除是改善方向，无需修复。",
        )

    if delta <= 0:
        return ("内存改善", "改善方向，无需修复。")

    # 劣化分析
    a_seg = item["a_segments"]
    b_seg = item["b_segments"]
    a_size = item["a_size_mb"]
    b_size = item["b_size_mb"]
    size_delta = b_size - a_size

    if b_seg > a_seg and size_delta > 0.5:
        return (
            f"映射段数增加（{a_seg}→{b_seg}）且 Size 增长 {size_delta:.2f}MB（{category}）",
            f"二进制体积增大，检查 {basename} 是否新增了代码段或数据段。"
            "可能是新增功能、编译选项变化或链接了更多库。建议检查编译产物大小变化。",
        )

    if abs(size_delta) < 0.5 and delta > 0.5:
        return (
            f"Size 基本不变但 Pss 增长 {delta:.2f}MB（{category}）",
            f"二进制大小不变但运行时驻留内存增加，可能是运行时数据结构增大或缓存增多。"
            "建议检查 {basename} 相关模块的运行时内存分配行为。",
        )

    if size_delta > 0.5:
        return (
            f"Size 增长 {size_delta:.2f}MB + Pss 增长 {delta:.2f}MB（{category}）",
            f"二进制体积和驻留内存同时增长。{basename} 可能新增了大量代码或数据。"
            "建议对比编译产物，检查新增符号或资源。",
        )

    return (
        f"Pss 增长 {delta:.2f}MB（{category}）",
        f"检查 {basename} 的内存使用变化，结合业务场景分析是否为合理增长。",
    )


def print_report(results: list[dict], total_a: float, total_b: float):
    """打印文本报告到 stdout。"""
    delta_total = total_b - total_a
    print(f"\n{'=' * 70}")
    print(f"  SO_SIZE / HAP smaps 对比分析报告")
    print(f"{'=' * 70}")
    print(f"\n  总览：")
    print(f"    A 版本 SO/HAP Pss 合计: {total_a:.2f} MB")
    print(f"    B 版本 SO/HAP Pss 合计: {total_b:.2f} MB")
    print(f"    差值: {delta_total:+.2f} MB")
    print()

    degraded = [r for r in results if r["delta_pss_mb"] > 0]
    improved = [r for r in results if r["delta_pss_mb"] < 0]
    print(f"    劣化项: {len(degraded)} 个")
    print(f"    改善项: {len(improved)} 个")
    print()

    if not results:
        print("  无差异数据")
        return

    print(f"  Top {len(results)} 差异项（按 Pss 差值降序）：")
    print(f"  {'No':<4} {'名称':<40} {'A(MB)':>8} {'B(MB)':>8} {'差值(MB)':>10} {'状态':>6}")
    print(f"  {'-' * 4} {'-' * 40} {'-' * 8} {'-' * 8} {'-' * 10} {'-' * 6}")
    for i, r in enumerate(results, 1):
        status = "新增" if r["is_new"] else ("移除" if r["is_removed"] else ("劣化" if r["delta_pss_mb"] > 0 else "改善"))
        print(f"  {i:<4} {r['basename']:<40} {r['a_pss_mb']:>8.2f} {r['b_pss_mb']:>8.2f} {r['delta_pss_mb']:>+10.2f} {status:>6}")

    print(f"\n{'=' * 70}")
    print(f"  根因分析与修复建议")
    print(f"{'=' * 70}")
    for r in results:
        if r["delta_pss_mb"] <= 0 and not r["is_new"]:
            continue
        root_cause, suggestion = analyze_root_cause(r)
        print(f"\n  [{r['basename']}]")
        print(f"    路径: {r['pathname']}")
        print(f"    归属: {classify_pathname(r['pathname'])}")
        print(f"    A: {r['a_pss_mb']:.2f} MB → B: {r['b_pss_mb']:.2f} MB (差值: {r['delta_pss_mb']:+.2f} MB)")
        print(f"    根因: {root_cause}")
        print(f"    建议: {suggestion}")


def main():
    parser = argparse.ArgumentParser(description="SO_SIZE/HAP smaps 对比分析")
    parser.add_argument("--smaps-a", required=True, help="A 版本 smaps 文件路径")
    parser.add_argument("--smaps-b", required=True, help="B 版本 smaps 文件路径")
    parser.add_argument("--top", type=int, default=20, help="显示 Top N 差异项 (默认 20)")
    parser.add_argument("--json", default=None, help="输出 JSON 结果到指定路径")
    args = parser.parse_args()

    smaps_a_path = Path(args.smaps_a)
    smaps_b_path = Path(args.smaps_b)
    if not smaps_a_path.exists():
        print(f"Error: A 版本 smaps 文件不存在: {smaps_a_path}", file=sys.stderr)
        sys.exit(1)
    if not smaps_b_path.exists():
        print(f"Error: B 版本 smaps 文件不存在: {smaps_b_path}", file=sys.stderr)
        sys.exit(1)

    # 读取 smaps（支持 utf-8-sig/BOM、utf-16 和 utf-8）
    def read_smaps(path: Path) -> str:
        for enc in ("utf-8-sig", "utf-16", "utf-8"):
            try:
                with open(path, encoding=enc) as f:
                    return f.read()
            except (UnicodeDecodeError, UnicodeError):
                continue
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()

    text_a = read_smaps(smaps_a_path)
    text_b = read_smaps(smaps_b_path)

    mappings_a = parse_smaps(text_a)
    mappings_b = parse_smaps(text_b)

    total_a = sum(m["pss_kb"] for m in mappings_a.values()) / 1024
    total_b = sum(m["pss_kb"] for m in mappings_b.values()) / 1024

    results = diff_smaps(mappings_a, mappings_b, top_n=args.top)

    print_report(results, total_a, total_b)

    if args.json:
        output = {
            "summary": {
                "total_a_mb": round(total_a, 2),
                "total_b_mb": round(total_b, 2),
                "delta_mb": round(total_b - total_a, 2),
                "degraded_count": len([r for r in results if r["delta_pss_mb"] > 0]),
                "improved_count": len([r for r in results if r["delta_pss_mb"] < 0]),
            },
            "items": results,
        }
        # 附加根因分析
        for item in output["items"]:
            root_cause, suggestion = analyze_root_cause(item)
            item["root_cause"] = root_cause
            item["suggestion"] = suggestion
            item["category"] = classify_pathname(item["pathname"])

        Path(args.json).write_text(
            json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(f"\n  JSON 结果已保存到: {args.json}")


if __name__ == "__main__":
    main()
