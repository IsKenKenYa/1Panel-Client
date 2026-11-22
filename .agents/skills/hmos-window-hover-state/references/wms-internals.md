# WMS 内部链路（悬停态判定与通知）

理解悬停态"何时触发、为何不触发"的依据。代码索引基于 foundation/window/window_manager master（2026-10），**只给文件 + 函数名定位，行号会漂移**。

## 1. 判定链路总览

```
折叠形态变化(传感器) ──► ScreenSessionManager(fold_screen_controller) ──► FoldStatus::HALF_FOLD
                                                                    │
窗口尺寸/布局变化(UpdateViewportConfig) ──────────────────────────┤
                                                                    ▼
LS 态变化(UpdateLSState) ──────────────────────► WindowSessionImpl::UpdateHoverState(windowRect, foldStatus)
                                                                    │
                                              foldStatus == HALF_FOLD && CheckWindowCanInHoverState(rect)?
                                                                    │ 是且状态翻转
                                                                    ▼
                                              SetHoverState(newHoverState)  // 客户端缓存
                                                                    │
                                              handler_->PostTask(异步, wptr 安全提升)
                                                                    ▼
                                              NotifyWindowHoverStateChange(hoverState)
                                                                    ▼
                                              IWindowHoverStateChangeListener::OnWindowHoverStateChange(bool)
                                                                    ▼
                                              NAPI: JS 回调 "windowPostureChange"（window 实例方法
                                              onWindowPostureModeChange 注册的 callback）
```

**悬停态在客户端（应用进程内）计算与缓存**，不走服务端 IPC 查询；每次折叠状态、LS 态、窗口布局变化都会重算。

## 2. 触发条件逐条（CheckWindowCanInHoverState）

真实实现：`wm/src/window_scene_session_impl.cpp` → `WindowSceneSessionImpl::CheckWindowCanInHoverState(const Rect& windowRect)`。全部满足才返回 true：

| # | 条件 | 代码依据 |
| --- | --- | --- |
| 1 | 目标 display 有效 | `DisplayManager().GetDisplayById(property_->GetDisplayId())` 非空 |
| 2 | 窗口为全屏尺寸 | 超级折叠屏设备（`FoldScreenStateInternel::IsSuperFoldDisplayDevice()`）：`windowRect.width_ == displayWidth && windowRect.height_ >= displayHeight`；普通设备：`IsFullScreenSizeWindow(width, height)` |
| 3 | 窗口模式为全屏 | `GetWindowMode() == WindowMode::WINDOW_MODE_FULLSCREEN`（分屏、悬浮、自由窗口均不满足） |
| 4 | 无 transform 缩放 | `transform.scaleX_ == 1 && transform.scaleY_ == 1` |
| 5 | 非 LS 态 | `!WindowSessionImpl::GetLSState()`（见第 4 节） |
| 6 | 折痕区域校验通过 | `CheckCreaseRegionCanInHoverState(windowRect)` → `display->GetLiveCreaseRegion(foldCreaseRegion)` 成功且区域校验通过 |
| 7 | 折叠状态为半折叠 | `UpdateHoverState` 中 `foldStatus == FoldStatus::HALF_FOLD`（调用方传入） |

**架构门控（关键）**：分离架构的 `WindowSessionImpl::CheckWindowCanInHoverState`（`wm/src/window_session_impl.cpp`）直接 `return false`。即**悬停态仅在合一架构（`window_manager_use_sceneboard = true`，SceneBoard/SceneSession 路径）下生效**。排查"为什么不触发"时先确认设备架构。

## 3. 状态翻转与通知（UpdateHoverState）

`wm/src/window_session_impl.cpp` → `WindowSessionImpl::UpdateHoverState(const Rect& windowRect, FoldStatus foldStatus)`：

1. 计算新状态：`HALF_FOLD && CheckWindowCanInHoverState(rect)`。
2. 与缓存状态（`GetHoverState()`，`hoverStateMutex_` 保护）比较，**相同则直接返回**（保证事件只在进出边界各发一次）。
3. `SetHoverState` 更新缓存。
4. `handler_->PostTask` 异步投递 `NotifyWindowHoverStateChange(newHoverState)`，lambda 以 `wptr` 持有窗口弱引用，promote 失败静默丢弃（窗口已销毁）。
5. `NotifyWindowHoverStateChange` 先在锁内拷贝监听器快照（`GetListeners<IWindowHoverStateChangeListener>`），再逐个回调（**锁外回调**，监听器容器为 `static std::map<int32_t /*persistentId*/, std::vector<sptr<...>>>` + `std::recursive_mutex`）。

触发重算的三个入口：

| 入口 | 时机 |
| --- | --- |
| `UpdateViewportConfig` | 窗口尺寸/布局/显示配置变化（含进入退出全屏、旋转）。旋转会使折痕 rect 在窗口坐标系中的宽高关系翻转，条件 6 重算：**横向折痕（宽 > 高）才可能满足悬停**——书本型设备横屏半折触发、竖屏半折（折痕纵向）不触发，这是悬停的方向性根因 |
| `UpdateLSState(isLSState)` | LS 态变化（`SceneSessionManager::NotifyClientToUpdateLSState` 下发） |
| 折叠状态监听回调 | `WindowSessionImpl::RegisterFoldStatusListener` 注册的 fold status 变化 |

`GetWindowHoverState()`（`isInWindowPostureMode` 的底层）：同样先做一次判定（`CheckWindowCanInHoverState(property_->GetWindowRect())`）再返回，**不是**只读缓存——所以查询结果始终反映当前窗口状态。

## 4. LS 态（悬停抑制条件）

- 服务端：`window_scene/session_manager/src/scene_session_manager.cpp` → `SceneSessionManager::UpdateAvoidAreaForLSStateChange(curState, preState)`：`curState > 0` 视为进入 LS 态（`SetLSState`），对全部可见前台 session 触发 `HandleLayoutAvoidAreaUpdate` + `NotifyClientToUpdateLSState`。入口为系统 API `sceneSessionManager.notifyLSStateChange`（SystemUI 侧调用）。
- 客户端：`WindowSessionImpl::UpdateLSState` 更新 `isLSState_` 后**主动重算悬停态**。
- 对悬停态的影响：LS 态为 true 时 `CheckWindowCanInHoverState` 返回 false——即使设备保持半折叠，悬停态也会退出。
- LS 态变化伴随 `WindowSizeChangeReason::LS_STATE_CHANGE` 的尺寸变化事件（JS 侧映射 `RectChangeReason.UNDEFINED`）。

应用侧含义：**悬停态进入/退出由系统综合判定**，应用可能收到"非用户预期"的退出（如系统进入 LS 态、旋转使折痕相对窗口由横向变纵向），适配代码必须把状态当唯一事实源，不要自己根据折叠角度或窗口方向推断后与系统状态打架。**悬停回调与窗口方向无关**：进入悬停时窗口可能是横屏（书本型设备常见），布局应由折痕坐标锚定（见 adaptation-patterns.md 第 8 节）。

## 5. 应用侧回调线程与优先级

NAPI 桥接（`js_window_listener.cpp` → `JsWindowListener::OnWindowHoverStateChange`）：`napi_send_event(env_, jsCallback, napi_eprio_high, "OnWindowHoverStateChange")`——**高优先级事件循环投递**，回调在 JS 线程执行。回调只携带一个 boolean。

## 6. 与悬停态同名的其他"hover"（勿混淆）

| 名称 | 位置 | 语义 |
| --- | --- | --- |
| `setTitleAndDockHoverShown` | window NAPI（API 14+） | PC 沉浸式：鼠标悬停热区唤出标题栏/Dock，与折叠屏悬停态无关 |
| `TRANS_ID_SET_HOVER_BLOCK_LIST` | `dmserver/include/display_manager_interface_code.h` | 显示服务内部接口，非悬停态链路 |
| `DeviceHoverStatus` / `-hoverstatus` 注入 | `screen_session_dumper.cpp` → `ScreenSession::HoverStatusChange` | 传感器悬停角度状态（相机悬停拍摄等），与窗口悬停态不同链路 |
| `SendPointerEventForHover` | `wmserver/include/zidl/window_manager_lite_interface.h` | Lite/Wear 鼠标事件注入，无关 |

## 7. 单元测试索引（改系统侧代码时回归）

| 测试 | 位置 | 覆盖 |
| --- | --- | --- |
| `UpdateHoverState` / `NotifyWindowHoverStateChange` / `GetWindowHoverState` / `UpdateLSStateAndGetLSState` | `wm/test/unittest/window_session_impl_test5.cpp` | 状态翻转、通知、查询、LS 态 |
| `CheckWindowCanInHoverState` | `wm/test/unittest/window_scene_session_impl_test5.cpp` | 判定条件矩阵 |
| `Register/UnregisterWindowHoverStateChangeListener`（null 监听器等） | `wm/test/unittest/window_session_impl_test.cpp` | 注册解注册 |
| `OnTitleAndDockHoverShowChange` | `window_scene/test/unittest/main_session_test.cpp` | PC 沉浸式 hover（勿混入本链路） |

## 8. 排查决策树（"为什么没触发"）

1. 设备是否折叠屏且处于 HALF_FOLD？（`display.getFoldStatus()` 或 hidumper，见 verification.md）
2. 构架是否合一架构？（分离架构恒不触发）
3. 窗口是否全屏模式且全屏尺寸？（分屏/悬浮不触发）
4. 是否处于 LS 态？（系统侧抑制）
5. 折痕区域校验是否通过？（`getLiveCreaseRegion` 是否返回有效区域）
6. 是否注册了正确 mode 的监听？（必须 `DESKTOP_MODE`）
7. hilog 过滤 `hoverState|PostureMode`（TAG：`WMS_ATTRIBUTE`/`DEFAULT`）看状态翻转日志。
