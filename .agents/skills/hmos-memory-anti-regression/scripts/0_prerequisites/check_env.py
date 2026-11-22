#!/usr/bin/env python3
"""Check environment prerequisites: hdc, trace_streamer, device connectivity."""

import sys

# 版本门禁：必须在 _lib import 之前（_lib 用了 3.10+ 类型注解语法，低版本 import 即崩）
if sys.version_info < (3, 10):
    print(f"[FAIL] Python {sys.version_info.major}.{sys.version_info.minor} < 3.10")
    print("请安装 Python 3.10+（推荐 3.12 LTS）：https://www.python.org/downloads/")
    sys.exit(1)

import os
import platform
import shutil
import subprocess
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
from tool_finder import find_hdc, find_trace_streamer, find_addr2line, _win_temp_dir

DEVECO_DOWNLOAD_URL = "https://developer.huawei.com/consumer/cn/deveco-studio/"
TS_DOWNLOAD_URL = "https://gitcode.com/openharmony/developtools_smartperf_host/releases/download/HiSmartPerf_20260730/trace_streamer_binary.zip"
TS_DOWNLOAD_URL_FALLBACK = "https://gitcode.com/openharmony/developtools_smartperf_host/releases"


def _run(cmd, timeout=10):
    """Run a command with UTF-8 decoding to avoid GBK UnicodeDecodeError on Windows."""
    return subprocess.run(cmd, capture_output=True, encoding="utf-8", errors="replace", timeout=timeout)


def _prompt_for_tool_path(tool_label: str, env_var: str, download_hint: str) -> str | None:
    """Interactively ask the user for a tool path when auto-detection fails.

    Returns a validated file path, or None if the user skipped / stdin is non-TTY.
    Sets the env var in-process so subsequent find_*() calls in the same run reuse it.
    Only prompts when stdin is a TTY to avoid blocking AI/CI non-interactive runs.
    """
    if not sys.stdin.isatty():
        return None
    print(f"\n[!] {tool_label} 未在默认位置自动找到。")
    print(f"    可直接提供其完整路径（本次通过 {env_var} 使用，建议永久设置同名环境变量），或回车跳过：")
    print(f"    下载指引: {download_hint}")
    while True:
        try:
            raw = input(f"  请输入 {tool_label} 路径 (回车跳过): ").strip()
        except (EOFError, KeyboardInterrupt):
            return None
        if not raw:
            return None
        raw = raw.strip().strip('"').strip("'")
        p = Path(raw)
        if p.is_file():
            os.environ[env_var] = str(p)
            print(f"    [i] 本次使用该路径; 建议永久设置环境变量 {env_var}={p}")
            return str(p)
        print(f"    [!] 文件不存在: {raw}，请重新输入或回车跳过。")


def check_hdc():
    found = find_hdc()
    if not found:
        found = _prompt_for_tool_path("hdc", "HDC_PATH", DEVECO_DOWNLOAD_URL)
    if not found:
        print("[FAIL] hdc not found in any expected location")
        return False, False
    try:
        result = _run([found, "list", "targets"])
        if result.returncode == 0 and result.stdout.strip():
            print(f"[OK] hdc connected: {result.stdout.strip()}")
            return True, True
        print("[FAIL] hdc no device connected")
        return False, True
    except Exception as e:
        print(f"[FAIL] hdc error: {e}")
        return False, True


def check_trace_streamer():
    found = find_trace_streamer()
    if not found:
        found = _prompt_for_tool_path("trace_streamer", "TRACE_STREAMER_PATH", TS_DOWNLOAD_URL)
    if not found:
        print("[FAIL] trace_streamer not found in any expected location")
        return False
    print(f"[OK] trace_streamer found: {found}")
    return True


def check_addr2line():
    """Check addr2line availability for native heap symbol resolution.

    Prefers llvm-addr2line (from DevEco Studio SDK) over system addr2line,
    because GNU binutils addr2line may not support DWARF-5 ARM64 ELF
    (errors: 'DW_FORM_line_strp' / 'invalid or unhandled FORM value: 0x23').
    """
    found = find_addr2line()
    if not found:
        found = _prompt_for_tool_path(
            "llvm-addr2line",
            "ADDR2LINE_PATH",
            "DevEco Studio SDK: <install>/sdk/default/openharmony/native/llvm/bin/"
        )
    if not found:
        print("[SKIP] addr2line not found (Step 4 native heap line resolution will be skipped)")
        return True  # non-blocking: addr2line only needed for Step 4 deep analysis
    # Check if it's llvm-addr2line (preferred) or generic addr2line
    is_llvm = "llvm" in Path(found).name.lower()
    if is_llvm:
        print(f"[OK] llvm-addr2line found: {found}")
    else:
        print(f"[WARN] addr2line found but not llvm-addr2line: {found}")
        print("       GNU binutils addr2line may not support DWARF-5 ARM64 ELF.")
        print("       If Step 4 reports 'DW_FORM_line_strp' errors, install llvm-addr2line from:")
        print("       DevEco Studio SDK: <install>/sdk/default/openharmony/native/llvm/bin/")
    return True


def check_python_version():
    if sys.version_info < (3, 10):
        print(f"[FAIL] Python {sys.version_info.major}.{sys.version_info.minor} < 3.10")
        return False
    print(f"[OK] Python {sys.version_info.major}.{sys.version_info.minor}")
    return True


def check_dependencies():
    missing = []
    for pkg in ["pandas", "openpyxl", "bs4", "markdown"]:
        try:
            __import__(pkg)
        except ImportError:
            missing.append(pkg)
    if missing:
        print(f"[FAIL] Missing packages: {missing}")
        print(f"[HINT] Run: pip install {' '.join(missing)}")
        return False
    print("[OK] All Python dependencies installed")
    return True


def check_hypium():
    """检查 hypium 是否安装（仅 --scenario 自动场景复现模式需要，手动操作模式不需要）。

    不自动安装、不阻断环境检查：仅在缺失时给出提示。
    """
    try:
        __import__("hypium")
        print("[OK] hypium installed (--scenario 自动场景复现可用)")
        return True
    except ImportError:
        print("[SKIP] hypium not installed (仅 --scenario 自动场景复现模式需要, 手动操作模式无需)")
        print("       如需使用 --scenario: pip install hypium -i https://mirrors.huaweicloud.com/repository/pypi/simple")
        return True


def print_install_guide(hdc_missing, ts_missing):
    if not hdc_missing and not ts_missing:
        return
    print()
    print("=" * 50)
    print("  Installation Guide")
    print("=" * 50)
    if hdc_missing and ts_missing:
        print()
        print("[!] Both hdc and trace_streamer are missing.")
        print("    Recommended: Install DevEco Studio, which includes hdc and other tools.")
        print(f"    Download: {DEVECO_DOWNLOAD_URL}")
        print()
        print("    trace_streamer is also searched via tool_finder (env var → DevEco → PATH).")
        print("    If not found locally, download:")
        print(f"    Download: {TS_DOWNLOAD_URL}")
        print(f"    Fallback (if link expired): {TS_DOWNLOAD_URL_FALLBACK}")
        print("    The zip contains all-platform binaries. Extract and choose by platform:")
        print("      Windows: trace_streamer_windows.exe / Linux: trace_streamer_linux / macOS: trace_streamer_mac")
        print()
        print("    Then configure environment variables:")
        print("      HDC_PATH=/path/to/hdc           (or add to PATH)")
        print("      TRACE_STREAMER_PATH=/path/to/ts  (or add to PATH)")
        print("      DEVECO_HOME=/path/to/DevEcoStudio (auto-detects toolchains)")
    elif hdc_missing:
        print()
        print("[!] hdc is missing.")
        print("    hdc comes with DevEco Studio toolchains.")
        print(f"    Download DevEco Studio: {DEVECO_DOWNLOAD_URL}")
        print()
        print("    After installation, configure environment variable:")
        print("      HDC_PATH=/path/to/hdc    (or add DevEco Studio toolchains dir to PATH)")
    elif ts_missing:
        print()
        print("[!] trace_streamer not found via tool_finder (env var → DevEco → PATH).")
        print("    If not installed locally, download:")
        print(f"    Download: {TS_DOWNLOAD_URL}")
        print(f"    Fallback (if link expired, find latest version): {TS_DOWNLOAD_URL_FALLBACK}")
        print("    The zip contains all-platform binaries. Extract and choose by platform:")
        print("      Windows: trace_streamer_windows.exe")
        print("      Linux:   trace_streamer_linux")
        print("      macOS:   trace_streamer_mac")
        print()
        print("    After download, configure environment variable:")
        print("      TRACE_STREAMER_PATH=/path/to/trace_streamer  (or add to PATH)")
    print("=" * 50)


def check_app_installed(bundle_name: str | None = None):
    if not bundle_name:
        print("[SKIP] No bundle name specified, skipping app check")
        return True
    hdc = find_hdc()
    if not hdc:
        print(f"[FAIL] hdc not found, cannot check app: {bundle_name}")
        return False
    try:
        result = _run([hdc, "shell", f"bm dump -n {bundle_name}"])
        if bundle_name in result.stdout:
            print(f"[OK] App installed: {bundle_name}")
            return True
        print(f"[FAIL] App not installed: {bundle_name}")
        return False
    except Exception as e:
        print(f"[FAIL] App check error: {e}")
        return False


def install_app(hap_path: str):
    linux_path = Path(hap_path)
    if not linux_path.exists():
        print(f"[FAIL] Install package not found: {hap_path}")
        return False
    hdc = find_hdc()
    if not hdc:
        print("[FAIL] hdc not found, cannot install app")
        return False
    win_temp = Path(_win_temp_dir())
    win_copy = win_temp / linux_path.name
    import shutil as shutil_mod
    shutil_mod.copy2(str(linux_path), str(win_copy))
    if platform.system() == "Windows":
        win_path = str(win_copy).replace("/", "\\")
    else:
        win_path = str(win_copy)
    print(f"  Installing: {win_path}")
    result = _run([hdc, "install", win_path], timeout=120)
    if "success" in result.stdout.lower() or result.returncode == 0:
        print("[OK] App installed successfully")
        print()
        print("[IMPORTANT] App has been installed. Before proceeding with data collection:")
        print("  1. Open the app on the device")
        print("  2. Complete login and any required initial setup")
        print("  3. Ensure the app is in normal usage state")
        print()
        return True
    print(f"[FAIL] Install failed: {result.stdout.strip()} {result.stderr.strip()}")
    return False


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Check environment prerequisites")
    parser.add_argument("-b", "--bundle", default=None, help="Bundle name to check installation")
    parser.add_argument("--install", default=None, help="HAP/APP path to install if app not found")
    args = parser.parse_args()

    print("=" * 50)
    print("  Environment Prerequisites Check")
    print("=" * 50)

    hdc_ok, hdc_found = check_hdc()
    ts_ok = check_trace_streamer()

    results = {
        "Python >= 3.10": check_python_version(),
        "hdc": hdc_ok,
        "trace_streamer": ts_ok,
        "addr2line": check_addr2line(),
        "Python packages": check_dependencies(),
        "hypium": check_hypium(),
    }
    if args.bundle:
        installed = check_app_installed(args.bundle)
        results[f"App: {args.bundle}"] = installed
        if not installed and args.install:
            print(f"  Attempting install from: {args.install}")
            ok = install_app(args.install)
            results["App install"] = ok
    print()
    all_ok = all(results.values())
    for name, ok in results.items():
        status = "PASS" if ok else "FAIL"
        print(f"  {name}: {status}")
    print()
    if all_ok:
        print("All checks passed!")
    else:
        print("Some checks failed. Fix before proceeding.")
        print_install_guide(not hdc_found, not ts_ok)
        sys.exit(1)


if __name__ == "__main__":
    main()
