#!/usr/bin/env python3
"""采集产物完整性校验 (纯本地检查, 无设备 I/O)。

校验产物集: htrace / meminfo(hidumper --mem) / showmap(hidumper --mem-smaps) /
dma(cat /proc/<pid>/mm_dmabuf_info) / heapsnapshot(hidumper --mem-jsheap)。
退出码: 0 必需产物齐全; 1 缺失; 2 用法错误。

用法: python scripts/1_collection/verify_collection.py <版本目录>
"""
import sys
from pathlib import Path

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8")
    except Exception:
        pass

PRODUCTS = [
    ("htrace",       "*.htrace", True,  10 * 1024 * 1024),
    ("meminfo",      "meminfo/dynamic_meminfo/dynamicMem_*.txt", False, 1),
    ("showmap",      "meminfo/dynamic_showmap/*.txt", False, 1),
    ("dma",          "meminfo/dynamic_process_dmabuf_info/process_dmabuf_info_*.txt", False, 1),
    ("heapsnapshot", "heapsnapshot/hidumper-jsheap-*", False, 1),
]

# 可选产物: 缺失不阻断核心分析，但会影响 ArkWeb 案例匹配规则 2/3 判定
OPTIONAL_PRODUCTS = [
    ("hilog",        "meminfo/hilog/hilog_*.txt", False, 1),
    ("window_dump",  "meminfo/window_dump/window_*.txt", False, 1),
]


def verify_products(version_dir: Path) -> tuple[bool, list[dict]]:
    """校验产物完整性, 返回 (是否全部通过, 各产物详情列表)。

    每个详情 dict: {name, ok, count, size_bytes, detail}
    """
    results = []
    all_ok = True
    for name, pattern, recursive, min_bytes in PRODUCTS:
        files = list(version_dir.rglob(pattern) if recursive else version_dir.glob(pattern))
        valid = [f for f in files if f.is_file() and f.stat().st_size >= min_bytes]
        if valid:
            total = sum(f.stat().st_size for f in valid)
            results.append({"name": name, "ok": True, "count": len(valid),
                            "size_bytes": total, "detail": f"{len(valid)} 个文件, {total / 1048576:.1f}MB"})
        else:
            all_ok = False
            if files:
                bad = sum(f.stat().st_size for f in files)
                results.append({"name": name, "ok": False, "count": 0,
                                "size_bytes": bad,
                                "detail": f"文件存在但大小不足 ({bad} bytes, 需 >= {min_bytes})"})
            else:
                results.append({"name": name, "ok": False, "count": 0,
                                "size_bytes": 0, "detail": "文件不存在"})
    return all_ok, results


def main() -> int:
    if len(sys.argv) != 2:
        print("用法: python scripts/1_collection/verify_collection.py <版本目录>", file=sys.stderr)
        return 2
    vd = Path(sys.argv[1]).resolve()
    if not vd.is_dir():
        print(f"[错误] 目录不存在: {vd}", file=sys.stderr)
        return 2

    print(f"  采集产物完整性校验: {vd}")
    ok, results = verify_products(vd)
    for r in results:
        status = "✅" if r["ok"] else "❌"
        print(f"  {status} {r['name']:14s} {r['detail']}")

    if ok:
        print("  [通过] 必需产物齐全, 可继续后续分析。")
    else:
        print(f"  [缺失] 必需产物不完整, 建议删除目录后重新采集:\n    rm -rf {vd}")
        return 1

    # 可选产物检查 (缺失不阻断, 仅警告)
    for name, pattern, recursive, min_bytes in OPTIONAL_PRODUCTS:
        files = list(vd.rglob(pattern) if recursive else vd.glob(pattern))
        valid = [f for f in files if f.is_file() and f.stat().st_size >= min_bytes]
        if valid:
            print(f"  ✅ {name:14s} {len(valid)} 个文件 (可选)")
        else:
            print(f"  ⚠️ {name:14s} 缺失 (可选, ArkWeb 案例匹配规则 2/3 将降级为「无法判定」)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
