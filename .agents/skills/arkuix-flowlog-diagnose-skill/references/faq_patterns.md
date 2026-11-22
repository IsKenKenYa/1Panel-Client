# FAQ 模式表（自包含，标源）

> 来源：`arkui-x/docs/zh-cn/application-dev/tutorial/faq/`（Dev-faq-11/7/26 等）。
> 本文件**自包含**提取，不依赖运行时读仓外；标源可追溯。
> skill 维度②按此 grep，命中即输出根因 + 处置 + 源 FAQ。

## A 类：可 grep 日志模式（12 条）

| # | 源 FAQ | grep 模式（日志签名） | 根因 | 处置 |
|---|--------|---------------------|------|------|
| A-1 | Dev-faq-11（闪退1） | `UnsatisfiedLinkError: No implementation found for ...`（native方法名不限定，实测可为 nativeInitAppMode / nativeAttachStageActivity 等，常伴随 `dlopen failed: library "libarkui_android.so" not found`） | ArkUI-X native 引擎库缺失/未加载，StageApplication 初始化失败 | 检查 APK lib/<abi>/ 是否含 libarkui_android.so；继承 StageApplication，或拉起前调 `StageApplicationDelegate.initApplication` |
| A-2 | Dev-faq-11 | `resolveBufferCallback get hsp buffer failed` | import 了不支持跨平台的 hsp | 参考 Dev-faq-10，改用跨平台模块 |
| A-3 | Dev-faq-11 | `Throw error: Cannot find module 'xxx', which is application Entry Point` | 漏拷贝 pkgContextinfo.json | 拷贝 pkgContextinfo.json 到 assets |
| A-4 | Dev-faq-11 | `abc file version 12.0.1.0. Maximum supported ... is 12.0.0.0` | abc 镜像与 SDK 版本不匹配 | 升级 SDK 对齐 API 版本 |
| A-5a | Dev-faq-11（白屏1） | `find requireModule @ohos:xxx failed` + `Cannot read property X of undefined`（模块加载段） | 缺 .so 或二级依赖未预置（如 libintl.so / libcrypto_openssl.so） | 预置对应的 .so 二级依赖；检查 APK lib/<abi>/ 目录 |
| A-5b | Dev-faq-11（白屏1） | `Cannot read property X of undefined` + `at aboutToAppear` + `TypeError`（页面生命周期段） | ArkTS aboutToAppear 访问 undefined 属性。**注意：ArkUI-X 框架用 panda::TryCatch 捕获该异常并静默处理（HandleUncaughtException），不直接导致白屏；仅当 abc 加载中断或 UIContent 装配失败时才白屏** | aboutToAppear 等加 try-catch / 空值保护；排查是否因 abc 不完整导致后续 UIContent 装配失败 |
| A-7 | Dev-faq-11 | `AceResourceRegister CreateResource: has exception` + `AwDataDirLock` | Android P+ WebView 多进程同目录冲突 | `setDataDirectorySuffix` 设置独立目录 |
| A-8 | Dev-faq-11（白屏4） | `bundleInfo_ is nullptr` + `module list size: 0` + `applicationInfo or bundleInfo is nullptr`；**实测补充签名**：`RunScriptBuffer failed path: entry/ets/entryability/EntryAbility.abc` + `Failed to get Ability object`（module.json 在但 modules.abc 缺失时是此签名，bundleInfo 仍可解析） | assets 目录漏拷贝跨平台模块（modules.abc/资源） | Clean Project + 用 DevEco/ACE Tools 重新构建；检查 APK assets/arkui-x/entry/ets/modules.abc 存在 |
| A-9 | Dev-faq-11 | `Load native module failed` / `ReferenceError: xxx is not defined` | 组件/API 误标跨平台（实际不支持） | 社区提 issue，确认跨平台支持范围 |
| A-10 | Dev-faq-7 | `[js_console_log.cpp(103)] ... Cannot read property X of undefined` | UIContext 未就绪即调 @ohos API | 用 UIContext.waitHardwareTask 等待就绪 |
| A-11 | Dev-faq-26 | `Symbol not found：...` | iOS SDK 版本切换致库链接失败 | `ace clean` + 删除多余 xcframework，重新构建 |
| A-12 | ~~实测补充~~ **降级为旁证** | `RenderContext::Create() return nullptr` | **非独立白屏根因**（实测：正常应用也出现，Vulkan 失败后 fallback 到其他渲染路径仍正常显示）。仅当**伴随** `didn't commit buffer within 3000ms` 且无首帧 vsync 时，才作为白屏线索之一（详见 corroborating_signals.md） | 作为旁证与其他信号联合判断；单独出现无需处置 |
| A-13 | **实测补充·非致命** | `UIContent::AddUIContent Delegator is null, delegator is not initialized`（ui_content.cpp:35） | **非白屏根因**（实测：出现在所有 ArkUI-X release 应用中，app 继续正常加载）。后续 13ms 内出现 `Succeeded in loading content`，16ms 内出现首帧 vsync，25ms 内出现 F1 首帧请求。框架通过 RSUIDirector 路径绕过 Delegator null 继续装配。 | **无需处置**。诊断时检查后续锚点（Succeeded in loading content / AttachView / RunPage / F1 / vsync）是否齐全，若齐全则确认 app 正常加载。**判定优先级：后续成功锚点 > Delegator is null**。 |

## B 类：配置类 fallback（4 条，无日志签名）

> A 类全未命中 + 症状是配置类白屏/闪退时，提示这 4 条。

| # | 源 FAQ | 触发场景 | 根因 | 处置 |
|---|--------|---------|------|------|
| B-1 | Dev-faq-17 | `useNormalizedOHMUrl=true` 配置 + 闪退/白屏 | 未拷贝 pkgContextInfo.json | 拷贝 pkgContextInfo.json / 升级 DevEco Studio 5.1.1+ |
| B-2 | Dev-faq-24 | iOS 6.1+ ArkUI 页面白屏 | 未调 addChildViewController | 加 `[parentVC addChildViewController:arkuiVC]` |
| B-3 | Dev-faq-22 | Bridge 调主线程 API | 主线程调用抛 RuntimeException | 切到非主线程调用 |
| B-4 | Dev-faq-15 | Android 输入法展开/收起界面异常 | 输入法与窗口尺寸冲突 | 调整输入法配置 / 窗口 resize 模式 |

## 使用方法

1. 对日志片段逐条 grep A-1~A-12 的"grep 模式"列。
2. 命中 → 输出根因 + 处置 + 源 FAQ。
3. A 类全未命中 + 症状是白屏/闪退且无明显异常日志 → 提示 B-1~B-4，让开发者自查配置。
4. 全未命中 → 输出"无 FAQ 命中"，建议提供更多日志或用 trace 工具。

> 注意：grep 模式中的 `X` / `xxx` 是通配占位，实际匹配时按字面前缀 + 任意内容。

## 框架异常保护机制（重要约束）

ArkUI-X 框架对所有 JS 调用都包裹了 `panda::TryCatch`（`ark_js_runtime.cpp`），异常经 `HandleUncaughtException` → `ArkNativeEngine::HandleUncaughtException` 处理。因此：

- **aboutToAppear / onPageShow 等生命周期方法里的 `throw new Error` 或 `TypeError` 不会导致应用闪退或白屏**——异常被 catch 后流程继续执行 Build + FirePageShow。
- **真正导致白屏的是**：abc 加载中断（`RunScriptBuffer failed`）、assets 缺失（`bundleInfo_ is nullptr` / `Failed to get Ability object`）。
- **`Delegator is null`（A-13）不是白屏根因**：出现在所有 release 应用中，app 继续正常加载。诊断时必须检查其后续是否出现 `Succeeded in loading content` + 首帧锚点。
- **skill 诊断时注意**：即使日志含 `aboutToAppear` + `TypeError` 或 `Delegator is null`，也不能直接判定为白屏根因——需确认后续流程是否中断（#8 UIContent 成功行 / #10 S2 AttachView / #14 RunPage / #18 F1 首帧 是否缺失）。**判定优先级：成功锚点（Succeeded in loading content / first frame）> 错误日志（Delegator is null / RenderContext null）**。

## JS 异常定位能力

正常情况下，JS 异常（jscrash）信息会由框架输出到日志。**若日志中 jscrash 信息丢失**（如 `no stack trace available`），可用 `errorManager.on` 作为协助定位手段（非必选项，实测 BadPage.ets:8:11 验证）：

| 配置 | JS栈/行号 | 定位粒度 | 日志表现 |
|------|----------|---------|---------|
| 日志含 jscrash 信息（正常） | ✅ 框架输出 | 行级 | 直接从日志读取异常消息与栈 |
| release/debug + jscrash 信息丢失 | ❌ 无栈 | 页面级（`startUrl=pages/Xxx`） | `System.err: NoClassDefFoundError ... no stack trace available` |
| debug + 注册 `errorManager.on('error')`（协助手段） | ✅ **文件+行号+列号** | **行级** | 应用回调输出 `Cannot read property X of undefined at aboutToAppear (XxxPage.ets:7)` + `at aboutToAppear entry (entry/src/main/ets/pages/XxxPage.ets:8:11)` |

**errorManager 协助定位的生效条件**（仅当日志 jscrash 信息丢失时才需要）：
1. 应用注册 `errorManager.on('error', { onUnhandledException: (errMsg: string) => { console.error(...) } })`（EntryAbility.onCreate 时机）
2. debug 包（含 `sourceMaps.map`，release 默认不打包）

**skill 处置建议**：日志有 jscrash 信息时直接用；若发现 JS 栈丢失，可建议注册 errorManager 回调 + debug 包复现作为协助手段；`GetSourceMapBufferByModuleName: no sourceMaps.map found` 是"release 无 sourcemap"的线索。
