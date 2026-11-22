# 检测规则速查表

> 按需加载：根据 meminfo 占比或项目类型选择相关规则后，再用此文件查找具体搜索关键词。

## 规则-数据映射（选规则用）

| meminfo 特征 | 优先检测规则 |
|-------------|------------|
| native heap > 40% | 3(图片), 4(泄漏), 5(Web预加载), 6(多媒体), 9(QuickJS), 10/11(Flutter VMA*), 12(RN*) |
| ark ts heap > 35% | 1(cachedCount), 7(Tabs), 8(不可见组件) |
| GL/Graph 占比高 | 3(图片优化) |
| PSS 持续增长(>1MB/min) | 4(泄漏) |
| UI 树有 Web 组件 | 5, 13, 14 |
| UI 树有 Video 组件 | 6 |

> *规则 10/11 仅 Flutter 项目，规则 12 仅 RN 项目

---

## 规则 1: cachedCount 硬编码

- **级别**: Medium
- **触发条件**: 代码中 `cachedCount(N)` 为硬编码常量，无设备分档
- **Grep 关键词 (ArkTS)**: `cachedCount`, `LazyForEach`, `ForEach(`
- **Grep 关键词 (C-API)**: `NODE_CACHED_COUNT`, `OH_ArkUI_NodeAdapter`
- **方案文档**: [scheme_cache_count.md](scheme_cache_count.md)

## 规则 2: 双层 Navigation 嵌套

- **级别**: Info
- **触发条件**: UI 树中 Navigation > Navigation 嵌套
- **无需代码扫描**
- **无独立方案文档**（仅报告）

## 规则 3: 图片资源内存占比过高

- **级别**: High
- **触发条件**（需同时满足 ≥2 项）: native heap PSS > 50%、Image 组件 > 10 个、单个 Image > 屏幕 25%、未用 autoResize
- **Grep 关键词 (ArkTS)**: `Image(`, `autoResize`, `setImageCacheCount`, `PixelMap`, `ImageKnifePro`, `setCacheLimit`
- **Grep 关键词 (C-API)**: `ARKUI_NODE_IMAGE`, `setImageCacheCount`
- **方案文档**: [scheme_image_optimization.md](scheme_image_optimization.md)

## 规则 4: 资源泄漏

- **级别**: Critical
- **触发条件**: 代码中 `setInterval`/`setTimeout`/`openSync`/`ThreadWorker` 无配对清理 + PSS 持续增长
- **Grep 关键词**: `setInterval`, `setTimeout`, `openSync`, `ThreadWorker`, `alloc`, `malloc`
- **确认方式**: 检查 `aboutToDisappear` 中是否有 `clearInterval`/`clearTimeout`/`closeSync`/`terminate`/`free`
- **方案文档**: [scheme_resource_leak.md](scheme_resource_leak.md)

## 规则 5: Web 预加载策略

- **级别**: High
- **触发条件**: 代码中有 Web 组件 + 预加载 API，无设备分档
- **Grep 关键词**: `initializeWebEngine`, `prepareForPageLoad`, `Web(`, `setLazyInitializeWebEngine`, `WebCookieManager`
- **方案文档**: [scheme_web_preload.md](scheme_web_preload.md)

## 规则 6: 多媒体内容未按设备分档降级

- **级别**: High
- **触发条件**: 滚动列表含 Video/直播 + `autoPlay(true)` 无分档 + native heap > 40%
- **Grep 关键词**: `Video(`, `autoPlay`, `live://`, `rtmp://`
- **方案文档**: [scheme_media_content_tiering.md](scheme_media_content_tiering.md)

## 规则 7: Tabs 缓存未按设备分档

- **级别**: High
- **触发条件**: Tabs 组件 + TabContent > 3 + 未设 `cachedMaxCount` 或硬编码
- **Grep 关键词**: `Tabs(`, `cachedMaxCount`, `TabContent`
- **方案文档**: [scheme_tabs_cache.md](scheme_tabs_cache.md)

## 规则 8: 不可见组件未主动下树

- **级别**: Medium
- **触发条件**: `visibility(Visibility.Hidden)` 用于重型组件（List/Web/Video/Image>5）或弹窗/面板关闭后仍挂树
- **Grep 关键词**: `Visibility.Hidden`, `visibility(`
- **方案文档**: [scheme_component_detach.md](scheme_component_detach.md)

## 规则 9: QuickJS 引擎内存

- **级别**: High
- **触发条件**: `JS_NewRuntime` + 未调用 `JS_SetMemoryLimit` 或参数硬编码
- **Grep 关键词**: `JS_NewRuntime`, `JS_SetMemoryLimit`, `JS_SetGCThreshold`, `JS_NewAtom`, `napi_create_reference`, `triggerGC`, `triggerBackgroundGC`, `JS_RunGC`, `qjsc`
- **方案文档**: [scheme_quickjs_optimization.md](scheme_quickjs_optimization.md)

## 规则 10: Flutter VMA 专用内存（Flutter 专项）

- **级别**: High
- **前置条件**: 项目含 `src/flutter/` 目录或 `pubspec.yaml`
- **Grep 关键词**: `vmaCreateImage`, `vmaCreateBuffer`, `VmaAllocationCreateInfo`
- **检测文件**: `src/flutter/impeller/renderer/backend/vulkan/allocator_vk.cc`
- **方案文档**: [scheme_flutter_vma.md](scheme_flutter_vma.md)

## 规则 11: Flutter VMA 大块堆内存（Flutter 专项）

- **级别**: High
- **前置条件**: 项目含 `src/flutter/` 目录
- **Grep 关键词**: `vmaCreateAllocator`, `preferredLargeHeapBlockSize`
- **检测文件**: `allocator_vk.cc`, `flutter_skia_vma.cc`
- **方案文档**: [scheme_flutter_vma.md](scheme_flutter_vma.md)

## 规则 12: RN 内存优化（RN 专项）

- **级别**: High
- **前置条件**: 项目含 `@rnoh/react-native-openharmony` 或 `RNApp`
- **Grep 关键词 (ArkTS)**: `RNApp`, `enableBackgroundGC`, `jsvmInitOptions`, `RNAbility`
- **Grep 关键词 (JS)**: `memoryLevelChange`, `memoryWarning`, `resizeMethod`, `FlatList`
- **方案文档**: [scheme_rn_memory.md](scheme_rn_memory.md)

## 规则 13: Web 活跃状态

- **级别**: High
- **前置条件**: 代码中有 Web 组件 + `onActive()`/预渲染/预编译
- **触发条件**: `onActive()` 缺少 `onFirstMeaningfulPaint()`，或有 FMP 但缺 `onInactive()`
- **Grep 关键词**: `onActive`, `onInactive`, `onFirstMeaningfulPaint`, `precompileJavaScript`, `onControllerAttached`
- **方案文档**: [scheme_web_on_active.md](scheme_web_on_active.md)

## 规则 14: Web 离线组件过量/未复用

- **级别**: High
- **前置条件**: 代码中有 `NodeContainer`/`NodeController`/`BuilderNode`/`createNWeb`
- **Grep 关键词**: `NodeContainer`, `NodeController`, `BuilderNode`, `createNWeb`, `getNWeb`, `recycleNWeb`, `recycleNWebs`, `dispose`, `loadUrl('about:blank')`, `onBind`, `onUnbind`, `isBound`
- **方案文档**: [scheme_web_offline_reuse.md](scheme_web_offline_reuse.md)

---

## 低优先级建议规则（仅报告，不自动修改）

| 问题类型 | 检测条件 | 建议方向 |
|----------|----------|----------|
| ark ts heap 过高 | PSS 占比 > 35% | TypedArray、对象扁平化、减少闭包 |
| .so 占用过高 | PSS 占比 > 20% | 动态加载、ABI 合并 |
| 大列表 ForEach | ForEach 渲染 > 100 项 | → LazyForEach + @Reusable |
| 动画过多 | Lottie/属性动画 > 5 | 低端机关闭或降帧率 |
| 字体占用高 | .ttf PSS > 5% | 延迟加载非默认字体 |
| Worker 过多 | > 3 个 | 低端机减少或串行 |
| 页面初始渲染慢 | ark ts heap 峰值 > 2x 平均 | 按需 import 重型组件 |

## C-API 组件映射（ArkTS → C-API 搜索时用）

| ArkTS | C-API 节点 | ArkTS | C-API 节点 |
|-------|-----------|-------|-----------|
| `List()` | `ARKUI_NODE_LIST` | `Grid()` | `ARKUI_NODE_GRID` |
| `WaterFlow()` | `ARKUI_NODE_WATER_FLOW` | `Image()` | `ARKUI_NODE_IMAGE` |
| `Web()` | `ARKUI_NODE_WEB` | `Tabs()` | `ARKUI_NODE_TABS` |
| `LazyForEach` | `OH_ArkUI_NodeAdapter_Create` | `cachedCount` | `NODE_CACHED_COUNT` |
| `visibility` | `NODE_VISIBILITY` | `disposeNode` | 手动清理资源 |

## Flutter / RN 项目检测

| 项目类型 | Grep 检测方式 |
|---------|-------------|
| Flutter | Grep `src/flutter/` 或 `pubspec.yaml`（不含 `@rnoh`） |
| RN | Grep `@rnoh/react-native-openharmony` 或 `RNApp` |
