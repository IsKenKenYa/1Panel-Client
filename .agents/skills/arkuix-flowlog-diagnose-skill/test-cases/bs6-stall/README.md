# B-S6 验证工程：卡顿·时间戳大间隔（stall）

## 场景
首页同步构建 1200 Block×27节点（约3.2万节点），使首帧构建真实变慢 → 日志出现大间隔。

## 工程要点
- **List 是懒加载**（只渲染可视区，3000项无效果）——必须用 **Scroll+ForEach 同步全量构建**
- Index.ets：aboutToAppear 填 1200 项 → build 里 ForEach 直接铺 Block

## skill 预期（实测达成）
- 症状：启动慢/卡顿嫌疑
- 维度④：⭐ `RunPage content`(50.871) → `ArkUI requests first Vsync`(54.401) **gap 3530ms**，期间**无任何 Ace 日志**（超 25ms 基线 141 倍）
- 维度③：F1+vsync 都有但首帧迟到 3.5 秒
- 处置：查首帧构建段节点数/复杂度，拆分构建/懒加载

## 实测关键日志（2026-10 实证）
```
09:29:50.871 execute SetupRootElement task start.
09:29:50.871 execute SetupRootElement task end.
09:29:50.871 RunPage content=[...]           ← RunPage 完成
（3.53 秒无任何 Ace 日志）
09:29:54.401 ArkUI requests first Vsync.      ← 首帧 vsync 迟到 3530ms
09:29:54.411 ArkUi flush first frame messages.
```

## 复现
```powershell
ace build apk --debug
adb install -r <apk>; adb shell am start -n com.example.bs6_stall/.EntryEntryAbilityActivity
# 先执行 SKILL.md 日志限流预防，再抓 logcat
```
