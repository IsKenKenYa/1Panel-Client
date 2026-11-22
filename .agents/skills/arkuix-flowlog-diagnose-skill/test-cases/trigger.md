# Skill 触发条件

## 何时触发本 Skill

- 开发者报告 ArkUI-X 应用**白屏 / 卡顿 / 闪退 / 启动慢**，并提供日志片段。
- 开发者粘贴 logcat / os_log / hilog 要求"排查""定位""看看卡在哪"。
- 明确点名本 skill 或提到 flowlog / 流程日志诊断。
- 日志中包含 Ace / ArkCompiler / StageActivity tag 的 ArkUI-X 启动/运行日志。

## 不适用场景

- 纯 OHOS（非跨平台）日志（本期仅 arkuix android+ios 补点，OHOS 共享仓零改动）。
- 卡顿帧率精确定位（每帧耗时不在 logcat 通道，需 trace 工具如 SmartPerf / Profiler）。
