"""Cross-platform tool finder for HarmonyOS development tools.

Searches for tools (hdc, trace_streamer, addr2line)
in the following order:
  1. Environment variable (HDC_HOME, TRACE_STREAMER_HOME, etc.)
  2. DevEco Studio installation directory (auto-detected)
  3. System PATH (shutil.which)

DevEco Studio auto-detection:
  - Windows: C:\\Program Files\\Huawei\\DevEco Studio\\
  - macOS:   /Applications/DevEco Studio.app/Contents/
  - Linux:   /opt/DevEco Studio/ or ~/DevEco Studio/

After locating DevEco Studio root, toolchains are searched under:
  <root>/sdk/default/openharmony/toolchains/
  <root>/sdk/openharmony/toolchains/
"""

import os
import platform
import shutil
import sys
from pathlib import Path
from typing import Optional


def _find_deveco_root() -> Optional[str]:
    root = os.environ.get("DEVECO_HOME")
    if root and Path(root).is_dir():
        return root

    candidates = []
    system = platform.system()

    if system == "Windows":
        candidates.extend([
            "C:/Program Files/Huawei/DevEco Studio",
            "C:/Program Files (x86)/Huawei/DevEco Studio",
        ])
    elif system == "Darwin":
        candidates.extend([
            "/Applications/DevEco Studio.app/Contents",
            os.path.expanduser("~/DevEco Studio.app/Contents"),
        ])
    elif system == "Linux":
        candidates.extend([
            "/opt/DevEco Studio",
            os.path.expanduser("~/DevEco Studio"),
        ])

    for c in candidates:
        if Path(c).is_dir():
            return c

    return None


def _toolchain_dirs() -> list[str]:
    root = _find_deveco_root()
    if not root:
        return []
    return [
        str(Path(root) / "sdk" / "default" / "openharmony" / "toolchains"),
        str(Path(root) / "sdk" / "openharmony" / "toolchains"),
    ]


def _win_temp_dir() -> str:
    system = platform.system()
    if system == "Windows":
        return os.environ.get("TEMP", os.environ.expandvars(r"%LOCALAPPDATA%\Temp"))
    return os.environ.get("TMPDIR", "/tmp")


def find_hdc() -> Optional[str]:
    env = os.environ.get("HDC_PATH")
    if env and shutil.which(env):
        return env

    names = ["hdc.exe", "hdc"] if platform.system() == "Windows" else ["hdc"]
    for d in _toolchain_dirs():
        for name in names:
            p = Path(d) / name
            if p.exists():
                return str(p)

    for name in names:
        found = shutil.which(name)
        if found:
            return found

    return None


def find_trace_streamer() -> Optional[str]:
    env = os.environ.get("TRACE_STREAMER_PATH")
    if env and shutil.which(env):
        return env

    platform_map = {
        "win32": ["trace_streamer_windows.exe", "trace_streamer.exe", "trace_streamer"],
        "linux": ["trace_streamer_linux", "trace_streamer"],
        "darwin": ["trace_streamer_mac", "trace_streamer_darwin", "trace_streamer"],
    }
    names = platform_map.get(sys.platform, ["trace_streamer"])

    search_dirs = _toolchain_dirs()
    root = _find_deveco_root()
    if root:
        search_dirs.append(str(Path(root) / "tools" / "profiler" / "dic_server"))
    for d in search_dirs:
        for name in names:
            p = Path(d) / name
            if p.exists():
                return str(p)

    for name in names:
        found = shutil.which(name)
        if found:
            return found

    return None


def find_addr2line() -> Optional[str]:
    env = os.environ.get("ADDR2LINE_PATH")
    if env and shutil.which(env):
        return env

    platform_map = {
        "win32": ["llvm-addr2line.exe", "addr2line.exe", "llvm-addr2line"],
        "linux": ["llvm-addr2line", "addr2line"],
        "darwin": ["llvm-addr2line", "addr2line"],
    }
    names = platform_map.get(sys.platform, ["addr2line"])

    # DevEco Studio's llvm-addr2line lives under native/llvm/bin/, NOT toolchains/
    # (toolchains/ has hdc but not llvm tools). Build the correct search dirs.
    search_dirs = _toolchain_dirs()  # toolchains/ (for completeness)
    root = _find_deveco_root()
    if root:
        search_dirs.extend([
            str(Path(root) / "sdk" / "default" / "openharmony" / "native" / "llvm" / "bin"),
            str(Path(root) / "sdk" / "openharmony" / "native" / "llvm" / "bin"),
        ])

    for d in search_dirs:
        for name in names:
            p = Path(d) / name
            if p.exists():
                return str(p)

    # System PATH fallback — prefer llvm-addr2line over addr2line
    # (MinGW/GNU binutils addr2line may not support DWARF-5 ARM64 ELF;
    #  llvm-addr2line from LLVM toolchain handles all DWARF versions)
    for name in names:
        found = shutil.which(name)
        if found:
            return found

    return None

def hdc_env() -> dict:
    """Return environment dict with MSYS2 path conversion disabled for hdc commands.

    On Windows (Git Bash / MSYS2), the shell auto-converts Unix-style paths starting
    with '/' to MSYS2 root paths (e.g. /data/local/tmp → C:/Program Files/Git/data/...),
    corrupting both local and remote paths in hdc commands.
    Setting MSYS_NO_PATHCONV=1 and MSYS2_ARG_CONV_EXCL="*" disables this conversion.
    """
    env = os.environ.copy()
    if sys.platform == "win32":
        env["MSYS_NO_PATHCONV"] = "1"
        env["MSYS2_ARG_CONV_EXCL"] = "*"
    return env
