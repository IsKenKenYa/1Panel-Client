# -*- coding: utf-8 -*-
"""B25 门禁：宿主 C# 中 L10n.T / 导航映射引用的 arb 键必须存在于 app_en.arb。

用法：python scripts/check_l10n_keys.py
退出码 0=全部存在；1=存在缺失键（静默回落英文的隐患）。
"""
import io
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOST_DIR = ROOT / "windows" / "runner" / "native_host" / "OnePanelNativeHost"
ARB = ROOT / "lib" / "l10n" / "app_en.arb"

# L10n.T("key", ...) 的首个字面量参数。
T_PATTERN = re.compile(r'L10n\.T\(\s*"((?:[^"\\]|\\.)*)"')
# MainWindow.NavLabelKeys 的 { "Tag", ("key", "English") } 元组（仅主窗口扫描）。
NAV_PATTERN = re.compile(r'\{\s*"[^"]+",\s*\(\s*"((?:[^"\\]|\\.)*)",\s*"')


def main() -> int:
    keys = set(json.load(io.open(ARB, encoding="utf-8")))
    total = 0
    missing = []
    for cs in sorted(HOST_DIR.rglob("*.cs")):
        text = io.open(cs, encoding="utf-8").read()
        patterns = [T_PATTERN]
        if cs.name == "MainWindow.xaml.cs":
            patterns.append(NAV_PATTERN)
        for pattern in patterns:
            for match in pattern.finditer(text):
                total += 1
                key = match.group(1)
                if key not in keys:
                    rel = cs.relative_to(ROOT)
                    missing.append(f"MISSING {rel}: {key}")

    print(f"referenced l10n keys: {total}")
    if missing:
        for line in missing:
            print(line)
        print(f"FAIL: {len(missing)} missing keys")
        return 1
    print("OK: all referenced keys exist in app_en.arb")
    return 0


if __name__ == "__main__":
    sys.exit(main())
