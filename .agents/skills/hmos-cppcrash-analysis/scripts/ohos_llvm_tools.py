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

"""OHOS LLVM 工具查找与执行脚本。

根据环境变量（DEVECO_HOME / DEVECO_CLI_STUDIO_PATH / DEVECO_SDK_HOME / DEVECO_CLI_CLT_PATH / OHOS_SDK）自动搜索
llvm-addr2line 和 llvm-objdump，并执行符号解析或反汇编。

用法::

    # 地址解析
    python ohos_llvm_tools.py addr2line <so_file> <offset>

    # 反汇编
    python ohos_llvm_tools.py objdump <so_file> [output_dir]

搜索策略:
    1. {DEVECO_HOME}/sdk/default/openharmony/native/llvm/bin
    2. {DEVECO_CLI_STUDIO_PATH}/sdk/default/openharmony/native/llvm/bin
    3. {DEVECO_SDK_HOME}/default/openharmony/native/llvm/bin
    4. {DEVECO_CLI_CLT_PATH}/sdk/default/openharmony/native/llvm/bin
    5. {OHOS_SDK}/{platform}/native/llvm/bin  或  {OHOS_SDK}/native/llvm/bin
    6. 从以上各环境变量的根目录开始递归模糊搜索（优先 llvm/bin）
    7. 回退到系统 PATH（shutil.which）
"""

import argparse
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Tuple

# 用于定位 OHOS LLVM 工具的环境变量（按优先级排列）
_ENV_VARS = ('DEVECO_HOME', 'DEVECO_CLI_STUDIO_PATH', 'DEVECO_SDK_HOME', 'DEVECO_CLI_CLT_PATH', 'OHOS_SDK')

# 递归模糊搜索时跳过的目录名（大小写不敏感），避免遍历无关大目录
_SKIP_DIRS = frozenset({
    'node_modules', '.git', '.gradle', '.cxx', 'caches', 'temp',
    '.idea', '__pycache__', '.hg', '.svn', 'build-cache',
})


def _exe_suffix() -> str:
    """Windows 下可执行文件带 .exe 后缀。"""
    return '.exe' if sys.platform == 'win32' else ''


def _platform_dir() -> str:
    """返回当前系统的 OHOS SDK 平段子目录名。"""
    system = platform.system().lower()
    return {'windows': 'windows', 'linux': 'linux', 'darwin': 'darwin'}.get(system, system)


def _env_roots() -> List[Path]:
    """收集所有已设置且存在环境变量的根目录。"""
    roots = []
    for name in _ENV_VARS:
        value = os.environ.get(name, '').strip()
        if value:
            root = Path(value)
            if root.is_dir():
                roots.append(root)
    return roots


def _direct_bin_candidates() -> List[Path]:
    """根据已知目录结构构造候选 bin 目录列表。

    依次对应各 SDK 布局（按优先级）:
      - DEVECO_HOME:            <root>/sdk/default/openharmony/native/llvm/bin
      - DEVECO_CLI_STUDIO_PATH: <root>/sdk/default/openharmony/native/llvm/bin
      - DEVECO_SDK_HOME:       <root>/default/openharmony/native/llvm/bin
      - DEVECO_CLI_CLT_PATH:  <root>/sdk/default/openharmony/native/llvm/bin
      - OHOS_SDK:              <root>/<platform>/native/llvm/bin  (独立 OHOS SDK)
                              <root>/native/llvm/bin            (command-line-tools)
    """
    candidates = []
    deveco_home = os.environ.get('DEVECO_HOME', '').strip()
    if deveco_home:
        candidates.append(
            Path(deveco_home) / 'sdk' / 'default' / 'openharmony' / 'native' / 'llvm' / 'bin')
    deveco_cli_studio = os.environ.get('DEVECO_CLI_STUDIO_PATH', '').strip()
    if deveco_cli_studio:
        candidates.append(
            Path(deveco_cli_studio) / 'sdk' / 'default' / 'openharmony' / 'native' / 'llvm' / 'bin')
    deveco_sdk_home = os.environ.get('DEVECO_SDK_HOME', '').strip()
    if deveco_sdk_home:
        candidates.append(
            Path(deveco_sdk_home) / 'default' / 'openharmony' / 'native' / 'llvm' / 'bin')
    deveco_cli_clt = os.environ.get('DEVECO_CLI_CLT_PATH', '').strip()
    if deveco_cli_clt:
        candidates.append(
            Path(deveco_cli_clt) / 'sdk' / 'default' / 'openharmony' / 'native' / 'llvm' / 'bin')
    ohos_sdk = os.environ.get('OHOS_SDK', '').strip()
    if ohos_sdk:
        sdk_root = Path(ohos_sdk)
        # 独立 OHOS SDK 带平台段；command-line-tools 不带平台段，两者均需尝试
        candidates.append(sdk_root / _platform_dir() / 'native' / 'llvm' / 'bin')
        candidates.append(sdk_root / 'native' / 'llvm' / 'bin')
    return candidates


def _find_in_dir(bin_dir: Path, tool: str) -> Optional[Path]:
    """检查指定目录下是否存在目标工具（含平台后缀）。"""
    candidate = bin_dir / f'{tool}{_exe_suffix()}'
    if candidate.is_file():
        return candidate
    return None


def _collect_fuzzy_candidates(tool: str) -> List[Path]:
    """从各环境变量根目录递归模糊搜索，返回所有命中的工具路径。

    遍历根目录下所有子目录（跳过 _SKIP_DIRS 中的无关目录），收集名为
    `<tool><suffix>` 的文件。同一文件经 resolve 去重。
    """
    suffix = _exe_suffix()
    target = f'{tool}{suffix}'
    matches: List[Path] = []
    seen = set()
    for root in _env_roots():
        for current, dirnames, filenames in os.walk(root):
            # 剪枝：原地修改 dirnames 阻止 os.walk 进入无关目录
            dirnames[:] = [d for d in dirnames if d.lower() not in _SKIP_DIRS]
            if target not in filenames:
                continue
            path = (Path(current) / target).resolve()
            if path in seen:
                continue
            seen.add(path)
            matches.append(path)
    return matches


def _rank_key(path: Path) -> Tuple[int, int, str]:
    """模糊搜索结果排序键：llvm/bin 路径优先，其次路径更浅，最后按字典序。"""
    parts = [p.lower() for p in path.parent.parts]
    is_llvm_bin = 'llvm' in parts and 'bin' in parts
    return (0 if is_llvm_bin else 1, len(parts), str(path).lower())


def find_llvm_tool(tool: str) -> Optional[Path]:
    """查找 OHOS LLVM 工具。

    依次按已知路径、递归模糊搜索、系统 PATH 回退，返回首个命中的可执行文件路径。
    """
    # 1. 已知路径候选
    for bin_dir in _direct_bin_candidates():
        found = _find_in_dir(bin_dir, tool)
        if found:
            return found

    # 2. 递归模糊搜索
    fuzzy = _collect_fuzzy_candidates(tool)
    if fuzzy:
        fuzzy.sort(key=_rank_key)
        return fuzzy[0]

    # 3. 系统 PATH 回退（shutil.which 已处理平台后缀）
    which = shutil.which(tool)
    return Path(which) if which else None


def run_addr2line(so_file: Path, offset: str) -> int:
    """执行 llvm-addr2line 进行地址解析。

    命令: llvm-addr2line -pCfie <so_file> <offset>
    解析结果写入标准输出，工具查找信息写入标准错误，互不污染。
    """
    tool = find_llvm_tool('llvm-addr2line')
    if not tool:
        _error('未找到 llvm-addr2line。请设置环境变量 DEVECO_HOME / DEVECO_SDK_HOME / '
               'OHOS_SDK，或将 llvm-addr2line 加入系统 PATH。')
        return 1
    if not so_file.is_file():
        _error(f'.so 文件不存在: {so_file}')
        return 1
    _info(f'使用工具: {tool}')
    cmd = [str(tool), '-pCfie', str(so_file), offset]
    return _run(cmd)


def run_objdump(so_file: Path, output_dir: Optional[Path] = None) -> int:
    """执行 llvm-objdump 进行反汇编。

    命令: llvm-objdump -dS -l -C <so_file> > <so_name>.objdump
    反汇编结果写入 <output_dir>/<so_name>.objdump，默认输出到当前目录。
    """
    tool = find_llvm_tool('llvm-objdump')
    if not tool:
        _error('未找到 llvm-objdump。请设置环境变量 DEVECO_HOME / DEVECO_SDK_HOME / '
               'OHOS_SDK，或将 llvm-objdump 加入系统 PATH。')
        return 1
    if not so_file.is_file():
        _error(f'.so 文件不存在: {so_file}')
        return 1
    out_dir = output_dir or Path.cwd()
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f'{so_file.name}.objdump'
    print(f'使用工具: {tool}')
    print(f'输出文件: {out_file}')
    cmd = [str(tool), '-dS', '-l', '-C', str(so_file)]
    with open(out_file, 'w', encoding='utf-8', errors='replace') as stdout:
        return _run(cmd, stdout=stdout)


def _run(cmd: List[str], stdout=None) -> int:
    """运行外部命令并返回退出码；标准输出/错误直接继承当前进程。"""
    try:
        proc = subprocess.run(cmd, stdout=stdout)
    except OSError as exc:
        _error(f'执行失败: {exc}')
        return 1
    if proc.returncode != 0:
        _error(f'命令返回非零退出码 {proc.returncode}')
    return proc.returncode


def _info(msg: str) -> None:
    print(msg, file=sys.stderr)


def _error(msg: str) -> None:
    print(f'错误: {msg}', file=sys.stderr)


def _configure_output_encoding() -> None:
    """统一正常输出、帮助和错误信息的编码。"""
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, 'reconfigure'):
            stream.reconfigure(encoding='utf-8', errors='replace')


def main() -> int:
    _configure_output_encoding()
    parser = argparse.ArgumentParser(
        description='OHOS LLVM 工具查找与执行：自动搜索 llvm-addr2line / llvm-objdump 并执行。',
        formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='command', metavar='<command>')

    a2l = sub.add_parser('addr2line', help='运行 llvm-addr2line 解析地址（-pCfie）')
    a2l.add_argument('so_file', help='.so 文件路径')
    a2l.add_argument('offset', help='pc 相对偏移（十六进制，可带 0x 前缀）')

    od = sub.add_parser('objdump', help='运行 llvm-objdump 反汇编（-dS -l -C）')
    od.add_argument('so_file', help='.so 文件路径')
    od.add_argument('output_dir', nargs='?', default=None,
                    help='输出目录（默认当前目录），生成 <so文件名>.objdump')

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        return 2

    if args.command == 'addr2line':
        return run_addr2line(Path(args.so_file), args.offset)
    if args.command == 'objdump':
        out_dir = Path(args.output_dir) if args.output_dir else None
        return run_objdump(Path(args.so_file), output_dir=out_dir)
    parser.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main())
