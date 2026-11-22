# ArkTS 扫描规则说明（ArkTS Rules）

> 规则清单提取自 homeflow `config/checkerConfig.json`（部署版本 **26.0.1.272**，共 23 条）。
> 全部规则默认开启（`default: true`），严重级别均为 `error`。
> 归属检查器：`ResourceLeak`。`resourceType` 分两类：
> - `resource`：资源对象创建后未释放（NotRelease）
> - `listener`：监听器注册后未注销（NotOff）
> 各规则详细说明见引擎自带文档 `homeflow/document/checker/ResourceLeak/<RuleId>.md`。

## 规则运行前提

1. SDK 路径有效（`-s` 指定，或按默认顺序解析，或 `DEVECO_SDK_HOME` / `DEVECO_PATH/sdk`）。
2. `--no-arkts` 关闭 ArkTS 规则（同时不解析 SDK 路径）。
3. **不传 `-c` 即检测全量规则**（使用 homeflow 自带 `checkerConfig.json`，23 条全开）。
4. 传 `-c/--config <path>` 时为**白名单语义**：只有配置中 `skip: false` 的规则被检测，未列出的规则自动补 `skip: true`（会收窄检测范围）。格式见 `references/cli-spec.md` §3.5。
5. SDK 缺失时跳过 ArkTS 分析（sdkPath 为 undefined，不报错）。

## 已知行为要点

- ArkTS 分析由 homeflow 引擎执行（部署结构：`codescanner/homeflow/dist/cli/index.js`）。
- 引擎中间产物：`<outputDir>/homeflow.sarif`。
- 模式含义：
  - `NotRelease` = 创建/订阅了资源但未调用释放接口（如 `release` / `dispose` / `reclaim` / `unsubscribe`）。
  - `NotOff` = 注册了监听器但未调用 `off` 注销（含 `SetIntervalNotRelease` 的 `setInterval`/`clearInterval` 配对）。

## 规则清单（ResourceLeak，23 条）

### resource 类型（NotRelease，10 条）

| 规则 ID | 分配接口 → 释放接口 |
|---------|---------------------|
| RpcMessageSequenceNotRelease | `@ohos.rpc` `MessageSequence.create` → `.reclaim` |
| ComponentContentNotRelease | `@ohos.arkui.node` `ComponentContent` constructor → `.dispose` |
| AnimatorResultNotRelease | `@ohos.animator` `Animator.create` / `.createAnimator` → `AnimatorResult.finish` / `.cancel` |
| ImageSourceNotRelease | `@ohos.multimedia.image` `createImageSource` → `ImageSource.release` |
| PixelMapNotRelease | `ImageSource.createPixelMap( Sync)` / `@ohos.effectKit` `Filter.getEffectPixelMap` → `PixelMap.release` |
| AVPlayerNotRelease | `@ohos.multimedia.media` `createAVPlayer` → `AVPlayer.release` |
| BuilderNodeNotRelease | `api/arkui/BuilderNode` `BuilderNode` constructor → `.dispose` |
| CommonEventSubscriberNotRelease | `@ohos.commonEventManager` `subscribe` → `unsubscribe` |
| CommonEventSubscriberNotSetNull | `@ohos.commonEventManager` `unsubscribe` 后未将订阅对象置空（`null`） |
| SetIntervalNotRelease | 全局 `setInterval` → `clearInterval` |

### listener 类型（NotOff，13 条）

| 规则 ID | 注册接口 → 注销接口 |
|---------|---------------------|
| WindowListenerNotOff | `@ohos.window` `Window.on` → `.off` |
| WindowStageListenerNotOff | `@ohos.window` `WindowStage.on` → `.off` |
| EmitterListenerNotOff | `@ohos.events.emitter` `on` → `off` |
| EventHubListenerNotOff | `api/application/EventHub` `EventHub.on` → `.off` |
| DisplayNamespaceListenerNotOff | `@ohos.display` `on` → `off` |
| DisplayClassListenerNotOff | `@ohos.display` `Display.on` → `.off` |
| WebSocketListenerNotOff | `@ohos.net.webSocket` `WebSocket.on` → `.off` |
| SensorListenerNotOff | `@ohos.sensor` `on` → `off` |
| VibratorListenerNotOff | `@ohos.vibrator` `on` → `off` |
| ObserverListenerNotOff | `@ohos.telephony.observer` `on` → `off` |
| UIExtensionProxyListenerNotOff | `ui_extension_component` `UIExtensionProxy.on` → `.off` |
| InputConsumerListenerNotOff | `@ohos.multimodalInput.inputConsumer` `on` → `off` |
| ComponentObserverListenerNotOff | `@ohos.arkui.inspector` `ComponentObserver.on` → `.off` |

## 答疑要点

- 命中后先看资源类型：`resource` 类补释放调用；`listener` 类在页面/组件销毁（如 `aboutToDisappear`）中补 `off`。
- 常见误报：监听器已在生命周期其他位置注销（跨函数配对），需确认是否真正泄漏。
- 规则配置：若需临时关闭某条规则，在 `-c` 配置中将其 `skip` 置 true（需检测则置 false）；`default` 字段仅存在于引擎自带 checkerConfig.json，不属于 `-c` 配置文件。
