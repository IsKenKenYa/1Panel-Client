# B-S2 验证工程：首帧未上屏（请求了未上屏）

## 场景
Text 组件 onAppear（vsync 请求已发出后、首帧 flush 前的回调）里执行 8 秒纯计算阻塞 → 首帧请求已发出但上屏被延迟 8 秒 → 用户视角白屏 8 秒。

## 工程要点（v1 踩坑）
- **v1 失败**：阻塞 aboutToAppear——它在 F1 之前执行，F1/vsync 会一起延迟（变成 B-S6 模式）
- **v2 正解**：阻塞 onAppear——此时 `ArkUI requests first Vsync` 已发出，阻塞造成"请求了未上屏"窗口

## skill 预期（实测达成）
- 症状：白屏（8 秒后恢复）
- 维度③：vsync 请求已发出(22.814) ↔ 首帧 flush(30.817) **延迟 8 秒** → "请求了未上屏"
- 维度④：22.815→30.815 之间 8 秒无 Ace 日志（大间隔）
- 处置方向：查 JS 回调（onAppear/约首帧期）长任务阻塞渲染管线

## 实测关键日志（2026-10 实证）
```
09:40:22.812 RunPage content=[...]
09:40:22.814 ArkUI requests first Vsync.        ← vsync请求已发出
09:40:22.815 BS2: onAppear fired, block 8s now   ← 阻塞开始
（8 秒无任何 Ace 日志）
09:40:30.815 BS2: block done
09:40:30.817 ArkUi flush first frame messages.   ← 首帧flush迟到8秒
09:40:30.851 Root node request first frame.
```

## 复现
```powershell
ace build apk --debug
adb install -r <apk>; adb shell am start -n com.example.bs2_ffblock/.EntryEntryAbilityActivity
```
