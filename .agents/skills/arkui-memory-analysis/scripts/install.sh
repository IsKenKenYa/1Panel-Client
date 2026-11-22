#!/bin/bash
# arkui-memory-analysis Skill 安装脚本
# 用法: bash 02-development/arkui/arkui-memory-analysis/scripts/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="arkui-memory-analysis"

echo "=== 安装 $SKILL_NAME Skill ==="

# 1. 安装 npm 包 (arkui-dump-viewer) — tgz 在 assets/ 目录下
TARBALL=$(ls "$SKILL_DIR/assets"/*.tgz 2>/dev/null | head -1)
if [ -z "$TARBALL" ]; then
  echo "Error: 未找到 arkui-dump-viewer-*.tgz in $SKILL_DIR/assets/"
  exit 1
fi
echo "安装 npm 包: $TARBALL"
npm install -g "$TARBALL"

# 2. 将 skill 复制到 ZCode/opencode 的 skill 发现路径
SKILL_SRC="$SKILL_DIR"

SKILL_TARGETS="$HOME/.agents/skills/$SKILL_NAME $HOME/.zcode/skills/$SKILL_NAME"

INSTALLED=0
for target in $SKILL_TARGETS; do
  mkdir -p "$(dirname "$target")"
  cp -r "$SKILL_SRC" "$target"
  echo "Skill 已安装到: $target"
  INSTALLED=1
done

if [ $INSTALLED -eq 0 ]; then
  echo "Warning: 未找到 skill 安装路径，请手动复制 $SKILL_SRC 到你的 skill 目录"
fi

echo ""
echo "=== 安装完成 ==="
echo "验证: node -e \"import('arkui-dump-viewer').then(m => console.log('parser loaded:', !!m.parseDump))\""
echo ""
echo "使用方法:"
echo "  # 分析 dump 文件"
echo "  node ~/.agents/skills/$SKILL_NAME/scripts/analyze-arkui-dump.mjs <dump-file>"
echo ""
echo "  # 分析源码"
echo "  node ~/.agents/skills/$SKILL_NAME/scripts/analyze-arkui-source.mjs <file-or-dir>"
echo ""
echo "  # 生成报告"
echo "  node ~/.agents/skills/$SKILL_NAME/scripts/generate-arkui-report.mjs \\"
echo "    --dump-schema <schema.json> --output report.md"
