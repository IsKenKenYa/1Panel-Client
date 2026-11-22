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
match_so.py — 校验本地 .so 文件是否与 faultlog 中的 BuildID 匹配。

用法：
  python match_so.py <so_name> <build_id> [-d <search_dir>]

示例：
  python match_so.py libexample.so f3991876654443a608c9cc71f20cf4c7
  python match_so.py libexample.so f3991876654443a608c9cc71f20cf4c7 -d /path/to/symbols

退出码：
  0 — 找到匹配文件，stdout 输出其绝对路径
  1 — 找到同名文件但 BuildID 不一致
  2 — 未找到同名 .so 文件
  3 — 无法提取 ELF BuildID（工具缺失或文件损坏）
"""

import argparse
import os
import platform
import re
import shutil
import subprocess
import sys


SDK_REL = os.path.join("sdk", "default", "openharmony", "native", "llvm", "bin")

DEVECO_PATHS = {
    "Darwin": [
        "/Applications/DevEco-Studio.app/Contents",
        os.path.expanduser("~/Applications/DevEco-Studio.app/Contents"),
    ],
    "Windows": [
        r"C:\Program Files\DevEco Studio",
        r"C:\Program Files (x86)\DevEco Studio",
    ],
}


def find_readelf():
    """查找 llvm-readelf，优先级：DEVECO_HOME > 已知安装路径 > PATH。"""
    plat = platform.system()
    name = "llvm-readelf.exe" if plat == "Windows" else "llvm-readelf"

    for base in [os.environ.get("DEVECO_HOME", "")] + DEVECO_PATHS.get(plat, []):
        if not base:
            continue
        c = os.path.join(base, SDK_REL, name)
        if os.path.isfile(c):
            return c

    return shutil.which(name)


def extract_buildid(so_path):
    """从 ELF 文件提取 BuildID（小写 hex），失败返回 None。"""
    tool = find_readelf()
    if not tool:
        return None
    try:
        out = subprocess.run(
            [tool, "-n", so_path],
            capture_output=True, text=True, timeout=30,
        ).stdout
        m = re.search(r"Build ID(?:\[sha1\])?\s*[:=]\s*([0-9a-fA-F]+)", out)
        return m.group(1).lower() if m else None
    except (subprocess.SubprocessError, OSError):
        return None


def search_so(so_name, root_dir):
    """递归搜索同名 .so，返回路径列表。"""
    results = []
    for dirpath, _, filenames in os.walk(root_dir):
        if so_name in filenames:
            results.append(os.path.join(dirpath, so_name))
    return results


def main():
    """程序入口：解析参数，查找同名 .so 并匹配 BuildID，输出匹配文件路径。"""
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[1].strip())
    parser.add_argument("so_name", help="栈帧中的 SO 文件名，如 libexample.so")
    parser.add_argument("build_id", help="栈帧中记录的 BuildID（hex）")
    parser.add_argument("-d", "--dir", default=os.getcwd(), help="搜索根目录（默认当前目录）")
    args = parser.parse_args()

    expected = args.build_id.lower()
    found = search_so(args.so_name, args.dir)

    if not found:
        sys.exit(2)

    for path in found:
        actual = extract_buildid(path)
        if actual is None:
            sys.exit(3)
        if actual == expected:
            print(path)
            sys.exit(0)

    sys.exit(1)


if __name__ == "__main__":
    main()
