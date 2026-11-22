# B-S7 验证工程：卡顿·重复行循环

## 场景
全屏 onTouch 每次 Move 更新 @State → 重渲染；配合 adb swipe 事件风暴 → `ProcessPointerEvent` 日志高频重复。

## 工程要点
- Index.ets：TouchPad 组件 onTouch(Move) → `this.moveCount += 1`（事件-渲染循环压力）
- 触发：`adb shell input swipe 540 1500 540 600 2000`（长拖动产生密集 move）

## skill 预期（实测达成）
- 症状：卡顿嫌疑
- 维度④：⭐ `UIContentImpl::ProcessPointerEvent called` 高频重复（实测 277 次，100ms 窗口最高 7 次）
- 处置：查 onTouch Move 重入/节流，避免每次 move 触发重渲染

## 实测关键日志（2026-10 实证）
```
I/Ace: [ui_content_impl.cpp(738)] UIContentImpl::ProcessPointerEvent called   ×277
（滑动期间每 100ms 窗口最高 7 次，同一签名反复）
```

## 重要边界（skill 优化项）
- test-case 期望"同 ms 重复 30+"，但 **adb input 受触摸采样率限制（60~120Hz）达不到同 ms 30+**
- 实测可达成的是"同签名短窗口高频重复"（277 次/数秒）
- **建议 skill 维度④判定弹性化**：同签名在短窗口（如 100ms）重复 ≥N 次，或总量异常，即标"循环嫌疑"——而非死板"同 ms 30+"

## 复现
```powershell
ace build apk --debug
adb install -r <apk>; adb shell am start -n com.example.bs7_loop/.EntryEntryAbilityActivity
# 等首页出来后事件风暴：
adb shell input swipe 540 1500 540 600 2000   # 长拖动
# 抓 logcat 后 grep ProcessPointerEvent 统计
```
