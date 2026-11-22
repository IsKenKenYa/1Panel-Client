# B-S9 验证工程：正常冷启动（基线）

## 场景
正常 ArkUI-X 应用冷启动，验证全链 22 锚点可见性（SDD AC-1.1/AC-1.2 核心）。

## skill 预期
- 症状：正常
- 维度①：全链锚点齐（含 SDD 补点：#10 `AttachView begin` / #16 `DelayNotify replay`）
- 维度③：F1 有 + vsync 有 → 首帧已上屏
- 维度②：无 FAQ 命中（`RenderContext null` 可出现但为旁证，Vulkan fallback 正常）

## 实测关键日志（2026-10 实证，codespace SDK 26.0.1.105+LOGI修复版）
```
I/Ace: [ui_content_impl.cpp(241)] Create UIContentImpl successfully.
I/Ace: [ace_container_sg.cpp(666)] AceContainerSG::AttachView begin, instance=100000     ← SDD补点 AC-1.1
I/Ace: [ace_container_sg.cpp(254)] InitializeFrontend finished.
I/Ace: [ace_container_sg.cpp(264)] AceContainerSG::InitPiplineContext density: 3.312500
I/Ace: [ace_container_sg.cpp(944)] Setup Root Element.
I/Ace: [ace_container_sg.cpp(1235)] RunPage content=[...]
I/Ace: [virtual_rs_window.cpp(1328)] Window DelayNotify replay: created=0 changed=0 destroyed=0   ← SDD补点 AC-1.2
I/Ace: [jsi_declarative_engine.cpp(3071)] Update application state , state: ON_SHOW
I/Ace: [rosen_window.cpp(283)] ArkUI requests first Vsync.
I/Ace: [pipeline_context.cpp(773)] Root node request first frame.
I/Ace: [pipeline_context.cpp(1303)] ArkUi flush first frame messages.
```

## 抓取要点（日志限流预防，见 SKILL.md"日志限流预防与重置"章节）
```powershell
adb shell setprop log.tag.ArkCompiler S   # 静默ArkCompiler D级噪音(不占进程日志配额)
adb logcat -c; adb shell am start -n ...; adb logcat -d -v time
```
