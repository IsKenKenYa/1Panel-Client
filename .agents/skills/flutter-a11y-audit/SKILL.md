---
name: flutter-a11y-audit
description: 对 Flutter 页面执行三类无障碍检查：交互组件语义标签、48dp 触控目标、对比度与焦点指示器。用于模块走查、新页面验收与无障碍回归，与 AGENTS.md「语义一致性检查清单」的无障碍条目配套。
metadata:
  scope: android,ios,ipados,macos,web
---

# Flutter 无障碍三类检查

来源：Flutter 官方 a11y agent 的检查项（docs.flutter.dev/ai/tools），在该 agent 仅限
Google Antigravity 可用时，按本技能在任意会话中手工执行同类检查。

## 检查一：交互组件语义标签

- 逐个检查页面上的可交互组件（`IconButton`、`InkWell`、`GestureDetector`、
  `FloatingActionButton`、自定义点击区域）。
- `IconButton` 必须有 `tooltip` 或外层 `Semantics(label:)`；`InkWell`/`GestureDetector`
  必须包裹 `Semantics` 并给出动作名称。纯图标按钮没有可见文字，语义标签是唯一名称来源。
- 走查验证：`adb shell uiautomator dump` 的 `content-desc` 不为空的组件才可被读屏服务
  定位；空 `content-desc` 的图标按钮即缺陷。

## 检查二：触控目标 ≥ 48x48 逻辑像素

- 所有可点击区域（按钮、列表行操作、卡片操作按钮、底部弹层条目）最小 48x48 逻辑像素；
  视觉尺寸更小的图标按钮必须用 `IconButton` 的默认约束或 `minimumSize`/`tapTargetSize`
  补足命中区。
- 走查验证：uiautomator dump 中可点击节点的 bounds 换算逻辑像素（物理像素 ÷
  devicePixelRatio），宽或高小于 48 即缺陷。

## 检查三：对比度与焦点指示器

- 文本对比度 ≥ 4.5:1（大字号 ≥ 3:1），图形与图标 ≥ 3:1；深浅主题分别检查。
- 键盘可达的组件必须有可见焦点指示器（Material 3 默认 `FocusRing`；自定义组件用
  `FocusableActionDetector` 或 `focusNode` + 描边）。
- 禁止仅用颜色传达状态（配图标或文字）。

## 执行方式

- 模块走查时按页面逐项核对，结果写入批次条目；发现缺陷按仓库常规缺陷流程修复并补回归。
- 语义树检查可直接读 `flutter semantics`（`SemanticsDebugger`）或模拟器无障碍 dump；
  桌面端用键盘 Tab 遍历验证焦点指示器。
