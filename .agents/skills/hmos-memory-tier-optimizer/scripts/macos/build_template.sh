#!/usr/bin/env bash
# HarmonyOS Project Build Script (macOS)
# 用法: build_template.sh [projectPath]
# 可选环境变量: DEVECO_HOME, DEVECO_SDK_HOME, OHOS_SDK_HOME, HM_SDK_HOME
set -euo pipefail

PROJECT_PATH="${1:-$PWD}"

cd "$PROJECT_PATH" || { echo "[ERROR] PROJECT_PATH does not exist: $PROJECT_PATH"; exit 1; }

if [ ! -f "build-profile.json5" ] || [ ! -d "hvigor" ]; then
  echo "[ERROR] Not a HarmonyOS project root: $(pwd)"
  echo "        Expected build-profile.json5 and hvigor directory."
  exit 1
fi

# 读取 local.properties 中的 sdk.dir
SDK_FROM_LOCAL=""
if [ -f "local.properties" ]; then
  SDK_FROM_LOCAL=$(grep -E "^sdk\.dir=" local.properties 2>/dev/null | head -n1 | cut -d= -f2- || true)
fi

SDK_PATH="${DEVECO_SDK_HOME:-${OHOS_SDK_HOME:-${HM_SDK_HOME:-$SDK_FROM_LOCAL}}}"

# 推断 DEVECO_HOME（由 SDK 路径反推，需验证有效性，避免 SDK 指向非标准路径时推导错误）
if [ -z "${DEVECO_HOME:-}" ] && [ -n "$SDK_PATH" ]; then
  INFERRED_HOME="$(dirname "$SDK_PATH")"
  # 验证推导目录含关键文件，无效则放弃推导、继续走常见目录遍历
  if [ -f "$INFERRED_HOME/jbr/bin/java" ] && [ -f "$INFERRED_HOME/tools/hvigor/bin/hvigorw.js" ]; then
    DEVECO_HOME="$INFERRED_HOME"
  fi
fi

# macOS 常见安装目录遍历
if [ -z "${DEVECO_HOME:-}" ]; then
  for d in \
    "/Applications/DevEco-Studio.app/Contents" \
    "$HOME/Applications/DevEco-Studio.app/Contents" \
    "/opt/deveco-studio" \
    "$HOME/deveco-studio"; do
    if [ -f "$d/jbr/bin/java" ] && [ -f "$d/tools/node/bin/node" ] && [ -f "$d/tools/hvigor/bin/hvigorw.js" ]; then
      DEVECO_HOME="$d"
      break
    fi
  done
fi

if [ -z "${DEVECO_HOME:-}" ]; then
  echo "[ERROR] DevEco Studio not found."
  echo "        Set DEVECO_HOME or DEVECO_SDK_HOME, or configure local.properties sdk.dir."
  exit 1
fi

[ -z "$SDK_PATH" ] && SDK_PATH="$DEVECO_HOME/sdk"

JAVA_HOME="$DEVECO_HOME/jbr"
NODE_EXE="$DEVECO_HOME/tools/node/bin/node"
HVIGOR_JS="$DEVECO_HOME/tools/hvigor/bin/hvigorw.js"

for required in \
  "$JAVA_HOME/bin/java" \
  "$NODE_EXE" \
  "$HVIGOR_JS" \
  "$SDK_PATH/default/openharmony"; do
  if [ ! -e "$required" ]; then
    echo "[ERROR] Missing build dependency: $required"
    exit 1
  fi
done

export PATH="$JAVA_HOME/bin:$PATH"
export DEVECO_SDK_HOME="$SDK_PATH"

CACHE_ROOT="$PWD/.build-cache"
export HOME="$CACHE_ROOT/home"
export HVIGOR_USER_HOME="$CACHE_ROOT/hvigor"
export npm_config_cache="$CACHE_ROOT/npm"
mkdir -p "$HOME" "$HVIGOR_USER_HOME" "$npm_config_cache"

echo "============================================"
echo "HarmonyOS Build (macOS)"
echo "============================================"
echo "Project: $(pwd)"
echo "DevEco:  $DEVECO_HOME"
echo "SDK:     $DEVECO_SDK_HOME"
echo "Java:    $JAVA_HOME"
echo "Cache:   $CACHE_ROOT"
echo "============================================"

echo "Cleaning build cache..."
rm -rf build entry/build .hvigor/cache 2>/dev/null || true

echo "Building project..."
"$NODE_EXE" "$HVIGOR_JS" assembleHap --no-daemon
BUILD_EXIT=$?

if [ "$BUILD_EXIT" -eq 0 ]; then
  echo "============================================"
  echo "BUILD SUCCESSFUL"
  if [ -d "entry/build/default/outputs/default" ]; then
    ls -1 entry/build/default/outputs/default/*.hap 2>/dev/null || true
  fi
else
  echo "============================================"
  echo "BUILD FAILED: $BUILD_EXIT"
fi

exit $BUILD_EXIT
