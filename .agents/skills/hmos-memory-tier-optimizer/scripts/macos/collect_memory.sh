#!/usr/bin/env bash
# HarmonyOS 应用内存数据采集脚本 (macOS)
# 用法: collect_memory.sh [bundleName] [outputDir]
# 示例:
#   collect_memory.sh                       # 自动检测前台应用
#   collect_memory.sh com.ohos.mms          # 指定应用
#   collect_memory.sh com.ohos.mms ./TestData
set -euo pipefail

HDC="${HDC:-hdc}"
BUNDLE_NAME="${1:-}"
OUTPUT_DIR="${2:-./memory_data}"
FAILED_ITEMS=""

echo ""
echo "============================================"
echo "HarmonyOS 内存数据采集工具 (macOS)"
echo "============================================"

# 检查 hdc 是否可用
if ! "$HDC" list targets >/dev/null 2>&1; then
  echo "[错误] 无法连接设备，请检查 hdc 连接"
  exit 1
fi

# 未指定 bundleName 时自动检测前台应用
if [ -z "$BUNDLE_NAME" ]; then
  echo "[0/5] 自动检测前台应用..."
  BUNDLE_NAME=$("$HDC" shell "aa dump -l" 2>/dev/null | grep "bundle name" | sed -E 's/.*\[([^]]+)\].*/\1/' | head -n1 || true)
  if [ -z "$BUNDLE_NAME" ]; then
    echo "[错误] 无法检测到前台应用"
    echo "请手动指定包名: collect_memory.sh <bundleName>"
    exit 1
  fi
  echo "      检测到: $BUNDLE_NAME"
fi

mkdir -p "$OUTPUT_DIR/meminfo" "$OUTPUT_DIR/uiTree"

echo "目标应用: $BUNDLE_NAME"
echo "输出目录: $OUTPUT_DIR"
echo ""

# [1/5] 获取前台应用信息
echo "[1/5] 获取前台应用信息..."
ABILITY_NAME=$("$HDC" shell "aa dump -l" 2>/dev/null | grep "main name" | sed -E 's/.*\[([^]]+)\].*/\1/' | head -n1 || true)
echo "      Ability: ${ABILITY_NAME:-未知}"
echo ""

# [2/5] 获取 PID
echo "[2/5] 获取应用进程号..."
PID=$("$HDC" shell "ps -ef | grep $BUNDLE_NAME | grep -v grep" 2>/dev/null | awk '{print $2}' | head -n1 || true)
if [ -z "$PID" ]; then
  echo "[错误] 未找到应用进程: $BUNDLE_NAME"
  echo "请确认应用正在运行"
  exit 1
fi
echo "      PID: $PID"
echo ""

# [3/5] 采集 meminfo
echo "[3/5] 采集 meminfo..."
MEMINFO_FILE="$OUTPUT_DIR/meminfo/${BUNDLE_NAME}_${PID}.txt"
if "$HDC" shell "hidumper --mem $PID" > "$MEMINFO_FILE" 2>/dev/null; then
  echo "      已保存: $MEMINFO_FILE"
else
  echo "      [警告] meminfo 采集失败"
  FAILED_ITEMS="$FAILED_ITEMS meminfo"
fi
echo ""

# [4/5] 采集 UI 树
echo "[4/5] 采集 UI 树..."
"$HDC" shell "uitest dumpLayout -p /data/local/tmp/ui_tree.json" >/dev/null 2>&1 || true
if "$HDC" file recv /data/local/tmp/ui_tree.json "$OUTPUT_DIR/uiTree/ui_tree.json" >/dev/null 2>&1; then
  echo "      已保存: $OUTPUT_DIR/uiTree/ui_tree.json"
else
  echo "      [警告] UI 树采集失败"
  FAILED_ITEMS="$FAILED_ITEMS uiTree"
fi
echo ""

# [5/5] 采集截图
echo "[5/5] 采集截图..."
"$HDC" shell "uitest screenCap -p /data/local/tmp/screenshot.png" >/dev/null 2>&1 || true
if "$HDC" file recv /data/local/tmp/screenshot.png "$OUTPUT_DIR/screenshot.png" >/dev/null 2>&1; then
  echo "      已保存: $OUTPUT_DIR/screenshot.png"
else
  echo "      [警告] 截图采集失败"
  FAILED_ITEMS="$FAILED_ITEMS screenshot"
fi
echo ""

echo "============================================"
echo "采集完成!"
echo "============================================"
echo "输出文件:"
echo "  - $OUTPUT_DIR/meminfo/${BUNDLE_NAME}_${PID}.txt"
echo "  - $OUTPUT_DIR/uiTree/ui_tree.json"
echo "  - $OUTPUT_DIR/screenshot.png"
echo ""

# 采集失败项汇总（不静默吞错，显式提示数据完整性问题）
if [ -n "$FAILED_ITEMS" ]; then
  echo "============================================"
  echo "⚠️ 以下项采集失败，数据可能不完整:$FAILED_ITEMS"
  echo "   请检查 hdc 连接与设备状态后重新采集。"
  echo "============================================"
  echo ""
fi

echo "--------------------------------------------"
echo "内存摘要 (Total PSS):"
echo "--------------------------------------------"
if [ -f "$MEMINFO_FILE" ]; then
  grep -E "Total" "$MEMINFO_FILE" 2>/dev/null | grep -v "native heap" || echo "(无摘要数据)"
else
  echo "(meminfo 文件不存在，无法显示摘要)"
fi
echo "--------------------------------------------"

# 若有关键采集失败，以非零退出码提示数据不完整
if [ -n "$FAILED_ITEMS" ]; then
  exit 2
fi
