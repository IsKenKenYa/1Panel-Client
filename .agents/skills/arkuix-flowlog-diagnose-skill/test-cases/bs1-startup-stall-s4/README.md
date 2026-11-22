# B-S1 验证工程：启动段卡顿（链断）

## 场景
页面模块顶层代码（abc 加载即执行）阻塞 10 秒 → 启动流程在 RunPage 后的页面模块执行段卡住 10 秒。

## 工程要点
- Index.ets 顶层 `while(Date.now()-t1<10000)` 纯计算（abc 加载即执行，先于生命周期）
- 实测断点位置：**S6 RunPage 之后**的页面模块执行段（非 test-case 期望的 S4）

## 重要验证发现（诚实记录）
test-case B-S1 期望"InitPiplineContext(S4) 后无 S5"（pipeline 初始化挂起）。
**应用层用例只能近似**：top-level 阻塞卡在 S6 后（页面模块执行），S4/S5 正常通过。
精确卡 S4 需 native 层手段（改框架 pipeline 初始化代码/注入），超出应用层用例能力。

skill 对本用例日志的判定：链断点=RunPage 后 10 秒无日志 + F1 延迟 10 秒 → 定位"页面模块加载阻塞"（与"查 pipeline 初始化"方向接近但不完全同）。

## 实测关键日志（2026-10 实证）
```
09:42:16.688 AceContainerSG::InitPiplineContext density: 3.312500   ← S4 正常
09:42:16.702 Setup Root Element. / task start / task end            ← S5 正常
09:42:16.702 RunPage content=[...]                                  ← S6
09:42:16.703 Succeeded in loading content
（10 秒无任何 Ace 日志 — top-level 阻塞）
09:42:26.703 BS1: top-level block done
09:42:26.705 ArkUI requests first Vsync.                            ← 首帧迟到 10 秒
```

## 复现
```powershell
ace build apk --debug
adb install -r <apk>; adb shell am start -n com.example.bs1_s4stall/.EntryEntryAbilityActivity
```
