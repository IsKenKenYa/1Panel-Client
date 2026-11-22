#!/bin/sh
# arkts-check.sh — arkts-check.js 的 Unix 启动器（macOS 分支未真机验证）
#
# 作用与 arkts-check.ps1 相同：机器上没有 Node.js 时，自动改用 DevEco Studio
# 自带的 node 来运行 arkts-check.js；所有参数原样转发，退出码透传（exec）。
#
# 用法：
#   ./arkts-check.sh --project <工程根目录> <文件1.ets> [文件2.ets ...] [--json]
#
# 注意（未真机验证）：
#   - 扫描 /Applications 与 ~/Applications 下名字含 "deveco" 的 .app、
#     取其 Contents/tools/node/bin/node 作为自带 node —— 该布局按 IntelliJ
#     平台惯例推测，尚未在真实 macOS 上验证。
#   - 若自动发现失败，请安装 Node.js（>= 16），或手动用自带 node 直接运行：
#     "<DevEco Studio.app>/Contents/tools/node/bin/node" arkts-check.js ...
#   - Linux 上本启动器虽可运行，但 arkts-check.js 本身不支持 Linux
#     （DevEco Studio 无 Linux 版本，标准 LSP 引擎不存在）。

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

find_node() {
  # 1) PATH 上的 node
  if command -v node >/dev/null 2>&1; then
    command -v node
    return 0
  fi
  # 2) DevEco Studio 自带的 node（扫描应用目录；布局未真机验证）
  for dir in "/Applications" "${HOME:-}/Applications"; do
    [ -d "$dir" ] || continue
    for app in "$dir"/*[Dd]ev[Ee]co*.app; do
      [ -e "$app" ] || continue
      node_bin="$app/Contents/tools/node/bin/node"
      if [ -x "$node_bin" ]; then
        printf '%s\n' "$node_bin"
        return 0
      fi
    done
  done
  return 1
}

NODE_BIN=$(find_node) || {
  echo "ERROR: Node.js not found (not on PATH; DevEco Studio bundled node not found)." >&2
  echo "       Install Node.js (>= 16) or DevEco Studio first." >&2
  exit 2
}

exec "$NODE_BIN" "$SCRIPT_DIR/arkts-check.js" "$@"
