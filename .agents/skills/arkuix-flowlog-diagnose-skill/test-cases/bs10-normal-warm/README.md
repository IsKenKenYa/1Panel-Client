# B-S10 验证：正常 warm 前后台（fgbg 四态）

## 场景
正常应用反复 HOME（后台）→ 重新拉起（warm 前台），验证 fgbg 四态 + Q-24 回放在 warm 场景可见。

## 验证方式（无需独立工程）
用任一正常 test-case 工程（如 bs8）：
```powershell
adb shell am start -n com.example.bs8_uaf/.EntryEntryAbilityActivity  # 冷启
adb shell input keyevent 3                                            # HOME后台
adb shell am start -n com.example.bs8_uaf/.EntryEntryAbilityActivity  # warm回前台（重复2轮）
```

## skill 预期（实测达成）
- 症状：正常
- 维度①：fgbg 四态齐（ON_SHOW/ON_ACTIVE/ON_INACTIVE/ON_HIDE）+ foreground/background/focus + surface created/destroyed
- **Q-24 DelayNotify replay 在 warm 恢复时同样可见**（SDD 补点 warm 场景生效）

## 实测关键日志（2026-10 实证）
```
—— warm 回前台 ——
I/StageActivityDelegate: DispatchOnForeground called
I/Ace: OnForeground begin. / JsAbility::CallObjectMethod: onForeground
I/Ace: [virtual_rs_window.cpp(1328)] Window DelayNotify replay: created=0 changed=0 destroyed=0   ← Q-24(SDD补点)
I/Ace: [jsi_declarative_engine.cpp(3071)] Update application state , state: ON_SHOW
I/Ace: UIContentImpl: window focus
I/Ace: Window Notify uiContent_ Surface Destroyed → Surface Created
I/Ace: Update application state , state: ON_ACTIVE
—— 转后台 ——
I/Ace: Update application state , state: ON_INACTIVE
I/Ace: Window Notify uiContent_ Surface Destroyed
I/StageActivityDelegate: DispatchOnBackground called
（ON_HIDE）
```
