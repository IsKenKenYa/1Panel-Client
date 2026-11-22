#!/usr/bin/env python3
# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
llvm_addr2line.py
查找 llvm-addr2line 工具并执行地址解析。

用法：
   python llvm_addr2line.py                           # 只输出工具路径
   python llvm_addr2line.py -pCfie <so_file> <offset>       # 直接执行地址解析


 搜索策略：
   1. DEVECO_HOME 环境变量：{DEVECO_HOME}/sdk/default/openharmony/native/llvm/bin
   2. 各平台已知 DevEco Studio 默认安装路径
   3. 系统 PATH 中的 llvm-addr2line

 输出：工具路径（无参数）或地址解析结果（有参数）
 退出码：0 = 成功，非 0 = 失败
"""

import os
import sys
import platform
import shutil
import subprocess
from typing import Optional, Tuple


def check_path(candidate: str) -> bool:
    """检查候选路径是否可执行（Windows 下退而检查文件是否存在）。"""
    return os.path.isfile(candidate) or os.access(candidate, os.X_OK)


def find_addr2line() -> Tuple[Optional[str], int]:
    """按优先级查找 llvm-addr2line 工具，返回 (工具路径, 退出码)。"""
    plat = platform.system()
    tool_name = "llvm-addr2line.exe" if plat == "Windows" else "llvm-addr2line"
    sdk_rel_path = os.path.join("sdk", "default", "openharmony", "native", "llvm", "bin")
    deveco_home = os.environ.get("DEVECO_HOME", "")
    if deveco_home:
        candidate = os.path.join(deveco_home, sdk_rel_path, tool_name)
        if check_path(candidate):
            return candidate, 0
    deveco_paths: list[str] = []
    if plat == "Darwin":
        deveco_paths = [
            "/Applications/DevEco-Studio.app/Contents",
            os.path.expanduser("~/Applications/DevEco-Studio.app/Contents"),
        ]
    elif plat == "Windows":
        deveco_paths = [
            r"C:\Program Files\DevEco Studio",
            r"C:\Program Files (x86)\DevEco Studio",
            os.path.expandvars(r"%LOCALAPPDATA%\Programs\DevEco Studio"),
        ]

    for d in deveco_paths:
        candidate = os.path.join(d, sdk_rel_path, tool_name)
        if check_path(candidate):
            return candidate, 0
    found = shutil.which(tool_name)
    if found:
        return found, 0

    return None, 1


def main() -> None:
    """程序入口：无参数时输出工具路径，有参数时定位工具并执行地址解析。"""
    args = sys.argv[1:]

    if args:
        path, code = find_addr2line()
        if code != 0 or not path:
            print("[ERROR] 未找到 llvm-addr2line，无法执行地址解析。", file=sys.stderr)
            sys.exit(1)
        try:
            result = subprocess.run([path] + args, capture_output=True, text=True)
            if result.stdout:
                print(result.stdout, end="")
            if result.stderr:
                print(result.stderr, end="", file=sys.stderr)
            sys.exit(result.returncode)
        except OSError as e:
            print(f"[ERROR] 调用 llvm-addr2line 失败: {e}", file=sys.stderr)
            sys.exit(1)

    path, code = find_addr2line()
    if path:
        print(path)
        sys.exit(0)

    sdk_rel_path = os.path.join("sdk", "default", "openharmony", "native", "llvm", "bin")
    plat = platform.system()
    tool_name = "llvm-addr2line.exe" if plat == "Windows" else "llvm-addr2line"

    print("[ERROR] 未找到 llvm-addr2line。", file=sys.stderr)
    print("", file=sys.stderr)
    print("请确保 DevEco Studio 已安装。", file=sys.stderr)
    print(f"期望路径：<DEVECO_HOME>/{sdk_rel_path}/{tool_name}", file=sys.stderr)
    print("", file=sys.stderr)
    print("提示：可设置 DEVECO_HOME 环境变量指向 DevEco Studio 安装目录。", file=sys.stderr)
    if plat == "Darwin":
        print('  macOS 示例:  export DEVECO_HOME=/Applications/DevEco-Studio.app/Contents', file=sys.stderr)
    elif plat == "Windows":
        print(r'  Windows 示例:  set DEVECO_HOME=C:\Program Files\DevEco Studio', file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()