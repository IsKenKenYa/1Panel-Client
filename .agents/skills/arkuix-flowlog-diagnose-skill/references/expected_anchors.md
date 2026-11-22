# 全链期望锚点（Expected Anchors）

> ArkUI-X 启动→首帧全链 22 个日志锚点，跨 Java/JNI/native/共享四层。
> skill 维度①按此逐个 grep，链断点 = 卡点阶段。
> 行号为实测（2026-09 基准，android）；ios 同构行号见备注。**master 演进会偏移，grep 用文案 + 文件名，行号仅辅助。**
> ★ = 本期已补 LOGI（TASK-S2-LOGI / TASK-Q24-REPLAY-LOGI 已落地，release 可见）。

## 日志级别要求（诊断前提）

> **22 锚点中 18 个为 LOGI 级别**。若 `log.tag.Ace` 设为 `E` 或更高，这些锚点全部不可见，无法诊断。
> 必须配置 `adb shell setprop log.tag.Ace V` 才能完整覆盖。详见 SKILL.md"日志配置要求"章节。

| 日志级别 | 锚点数量 | 说明 |
|---------|---------|------|
| LOGI | 18 个 | #8~#20（除 #5/#6/#7 外全部）、★S2 AttachView、★Q-24 DelayNotify、F1 首帧、vsync 等 |
| LOGE | 4 个 | #7 Ability 生命周期（APP: onCreate/onWindowStageCreate/onForeground）、应用自定义 console.error |
| Java I | 4 个 | #1 AceEnv、#5 StageActivity、#6 Dispatch（Java/JNI tag，不受 log.tag.Ace 影响）|

## 锚点表

| # | 段 | 层 | 期望日志文案 | 文件:行号（android / ios） | 状态 |
|---|----|----|------------|--------------------------|------|
| 1 | 进程/lib 加载 | Java | `AceEnv init start` / `Load ace lib` | `AceEnv.java:41` / `LibraryLoader.java:45,71` | 已有 |
| 2 | JNI_OnLoad | JNI | `Current ArkUI-X version` / `JNI Onload success` | `jni_load.cpp:46,65` | 已有 |
| 3 | 框架初始化 | JNI | `Attach Stage Application` / `backtrace handler installed` | `stage_application_delegate_jni.cpp:430` / `backtrace_handler.cpp:653` | 已有 |
| 4 | App launch | JNI | `Launch application` → `Launch application success` | `stage_application_delegate_jni.cpp:259,624` | 已有 |
| 5 | Activity | Java | `StageActivity onCreate` / `callActivityOnCreate` | `StageActivity.java:181` | 已有 |
| 6 | Dispatch | JNI | `JNI DispatchOnCreate/Foreground/SetWindowView` | `stage_activity_delegate_jni.cpp:124,155,199` | 已有 |
| 7 | Ability | 共享+JNI | `LaunchAbility instanceId:1` / `OnCreate begin` / `OnWindowStageCreated` / `onForeground` | 共享 capability runtime | 已有 |
| 8 | UIContent 创建 | arkuix | `Create UIContentImpl successfully` | `ui_content_impl.cpp:240` | 已有 |
| 9 | S1 CommonInitialize | arkuix | `Initialize UIContentImpl start` / `isModelJson` / `instanceId_:100000` | `ui_content_impl.cpp:542,325,387` | 已有 |
| 10 | **S2 AttachView** | arkuix | ★`AceContainerSG::AttachView begin, instance=` | `ace_container_sg.cpp:666` / ios `:658` | **★已补 LOGI** |
| 11 | S3 InitializeFrontend | arkuix | `Create engine` → `InitializeFrontend finished` | `ace_container_sg.cpp:235,257` | 已有 |
| 12 | S4 InitPiplineContext | arkuix | `InitPiplineContext density` | `ace_container_sg.cpp:267` | 已有 |
| 13 | S5 SetupRootElement | arkuix | `Setup Root Element` → `task start/end` | `ace_container_sg.cpp:963,967,973` | 已有 |
| 14 | S6 RunPage | arkuix | `RunPage content` / `RunPage done` | `ace_container_sg.cpp:1254` / `ui_content_impl.cpp:268` | 已有 |
| 15 | S7 NotifySurfaceCreated | arkuix | `NotifySurfaceCreated called` | `ui_content_impl.cpp:1034` | 已有 |
| 16 | **Q-24 回放** | arkuix | **新版本 SDK（已补 LOGI）**：★`Window DelayNotify replay: created=.. changed=.. destroyed=..` (ios 含 `focus=`)；或 `Window Delay Notify uiContent_ Surface Created (replay)` / `Surface Changed (replay)` / `Surface Destroyed (replay)` | `virtual_rs_window.cpp:1327` / ios `.mm:1317` | **★已补 LOGI** |
| | | | **老版本 SDK（未补，LOGD release 不可见）**：`Window Delay Notify uiContent_ Surface Created/Changed/Destroyed`（LOGD，仅 debug 包可见）；或间接证据 `NotifySurfaceCreated called`（`ui_content_impl.cpp:1034`，LOGI release 可见，但回放与新投递都会打，无法精确区分） | 同函数 | 老版本兼容 |
| 17 | S8 OnShow | 共享 | `ON_SHOW` / `Window get focus` | `jsi_declarative_engine.cpp:3073` / `pipeline_context.cpp:5690` | 已有 |
| 18 | F1 首帧请求 | 共享 | `Root node request first frame` | `pipeline_context.cpp:751` | 已有 |
| 19 | F3 首帧刷新 | 共享 | `ArkUi flush first frame messages` | `pipeline_context.cpp:1273` | 已有 |
| 20 | 首帧 vsync | arkuix | `ArkUI requests first Vsync` | `rosen_window.cpp:281` | 已有 |
| 21 | fgbg 四态 | 共享 | `ON_SHOW/ON_ACTIVE/ON_INACTIVE/ON_HIDE` | `jsi_declarative_engine.cpp:3073` | 已有 |
| 22 | surface 销毁 | arkuix | `NotifySurfaceDestroyed called` | `ui_content_impl.cpp:1048` | 已有 |

## 链断点判定规则

1. 从 #1 开始逐个 grep，记录每个锚点"存在/缺失"。
2. **最后一个存在的锚点** = 流程走到的阶段。
3. **第一个缺失的锚点** = 链断点（卡点阶段）。
4. 输出格式：`流程走到 #N <阶段名>，链断点：#N+1 <阶段名> 缺失`。

## 特殊判定

- **#10 S2 缺失**：容器装配未开始。查 #7 Ability 是否 OnWindowStageCreated、#8 UIContent 是否创建。若 #8 无 → UIContent 创建失败。
- **#16 Q-24 缺失 + 有 delay notify 暂存**：延迟通知未回放（RC-1.1）。疑 UIContent 创建失败或时序错乱——surface/focus 通知在 UIContent 创建前投递，框架暂存但未回放。这是冷启动白屏的关键竞态点。
  - **新版本 SDK**（已补 LOGI）：grep `DelayNotify replay` 或 `Surface Created (replay)` 确认回放。
  - **老版本 SDK**（未补，LOGD release 不可见）：release 包无法直接确认回放——需看间接证据：有 `NotifySurfaceCreated called`（#15 锚点，LOGI release 可见）说明 surface 通知被消费（但回放与新投递都会打此日志，无法精确区分）；debug 包可看 `Window Delay Notify uiContent_ Surface Created`（LOGD）确认回放。
  - **老版本 SDK release 包**：若 #15 `NotifySurfaceCreated called` 有但无 #16 回放日志 → 标"延迟通知可能已回放（间接证据），建议用 debug 包或升级 SDK 精确确认"。
- **#18 F1 缺失**：首帧未请求。查 #13 S5 / #14 S6 RunPage 是否走完（RunPage 失败则不请求首帧）。
- **#20 vsync 缺失 + #18 F1 有**：首帧请求了未上屏。查 JS 异常（aboutToAppear）/ abc 执行慢 / Vulkan `RenderContext::Create() return nullptr`。
- **#22 surface 销毁缺失 + 销毁段**：销毁流程不完整，可能 UAF（use-after-free）。

## 平台差异

- **Android**：logcat，tag `Ace`（native）/ `ArkUI`/`StageActivity`（Java）。
- **iOS**：os_log / `log stream`，tag 同上。#16 Q-24 ios 多 `focus=` 标志。
- **OHOS**：hilog。本期未改 OHOS（共享仓零改动），#10 S2 / #16 Q-24 在 OHOS 可能不可见（OHOS 无 AttachView/DelayNotify 方法）。
