# ArkUI 内存热点故障树模式库

> 本文档是 ArkUI 内存防劣化分析 Skill 的核心知识库。每条模式含：故障机制、检测信号（dump 侧 / 源码侧）、严重度、修复建议。
> 来源：mem-degrade-cases 仓库的 A/B 对比实测 + ArkUI 官方文档/FAQ + HarmonyOS 内存优化专项故障模式参考。

## 热点分类总览

| 编号 | 热点类型 | 典型场景 | 严重度 | 检测方式 |
|------|----------|----------|--------|----------|
| H-01 | 不可见页面冗余加载 | 隐藏页面条件渲染 + 保留引用 | High | 静态检查 |
| H-02 | Tabs 缓存数量过多 | Tabs 多页面切换后缓存不释放，未设 cachedMaxCount | High | 静态检查 |
| H-03 | 预加载不可见 Tab 页面 | 和用户使用意图无关、尚未访问的整个页面被加载（如 preloadItems） | High | 静态检查 |
| H-04 | 冗余加载 Tabs 中间页面 | Tabs 跨页面切换时加载了中间页面（默认滑动动画） | Medium | 动态 CLI |
| H-05 | 长列表滚动不懒加载 | List/Swiper 等滚动组件未用懒加载，一次性全加载 | High | 静态检查 |
| H-06 | 滚动预加载 CachedCount 不合理 | 预加载过多远超单次下滑可见范围 | Medium | 静态检查 |
| H-07 | 布局写法冗余低效 | 过多嵌套容器组件（如数十个 Stack 嵌套） | Medium | 静态检查/动态 CLI |
| H-08 | 页面栈过深 | NavDestination 反复跳转导致数量爆炸 | High | 动态 CLI |
| H-09 | 缓存池/复用池未释放 | List 上下滚动后退台存在缓存节点未释放 | High | 动态 CLI |
| H-10 | XComponent 未释放 | nativeWindow/Surface 存在延迟释放 | Medium | 动态 CLI |
| H-11 | Image 不合理超大图 | 不知名大图/评论区图片提前渲染 | Medium | 动态 CLI |
| H-12 | 命令式节点缓存 | 应用创建并持有 BuilderNode/CAPI 等命令式节点 | Medium | 静态检查 |
| H-13 | Canvas 替代原生渐变 | 有 linearGradient 却用 Canvas 画全屏渐变 | Medium | 静态检查 |
| H-14 | ImageAnimator 帧集过量 | 过多帧/过大帧预解码常驻 | Medium | 静态检查 |
| H-15 | Video 组件常驻 | autoplay + 循环使解码器/缓冲常驻 | Low | 静态检查 |
| H-16 | ArkWeb 预渲染/预热过多 | 预渲染多个 Web 页面或预创建多个渲染进程不释放 | Medium | 静态检查 |
| H-17 | BuilderNode 销毁流程不完整 | new BuilderNode 未按 3 步销毁（NodeContainer(undefined)→update(undefined)→dispose()） | Medium/High | 静态检查 |
| H-18 | 缓存池清空使能未设置 | MemOpt/ReusableMemOpt/RepeatMemOpt 字段存在但未启用 | Medium | 动态 CLI |

---

## H-01：不可见页面冗余加载

**故障机制**：通过 `visibility(Visibility.Hidden)` + `enabled(false)` 条件渲染隐藏一个复杂页面组件。隐藏页面被构建（`aboutToAppear` 触发），其数据和组件节点常驻内存，但用户看不到。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | `VisibleAndActive: '0'` 的节点下有大量子节点 | 隐藏子树被构建但不可见 |
| Dump | 隐藏子树节点数 > 10 且总内存 > 1MB | 不可见页面内存开销 |
| 源码 | `.visibility(Visibility.Hidden)` 后跟复杂 build() | 隐藏复杂页面 |
| 源码 | `if (condition) { ComplexPage() }` 且 condition 常为 false | 条件渲染但常隐藏 |

**严重度**：High — 不可见页面内存 100% 浪费

**修复建议**：
1. 不要用 `visibility(Hidden)` 加载复杂页面；改用条件渲染 `if (visible) { Page() }`，不构建时零成本
2. 隐藏页面的数据应在 `aboutToAppear` 按需加载，而非页面构建时预加载
3. `aboutToDisappear` 释放页面持有的 PixelMap、大数组等资源

---

## H-02：Tabs 缓存不释放

**故障机制**：不设置 `Tabs.cachedMaxCount` 时，所有已访问的 `TabContent` 子组件默认全部缓存不释放。每个页签的 `aboutToAppear` 预解码的 PixelMap、组件节点树常驻内存。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | 多个 `TabContent` 子树同时存活 | 切换后旧页签未释放 |
| Dump | 已切走的页签子树 `VisibleAndActive: '0'` 但仍在树中 | 缓存不释放 |
| 源码 | `Tabs()` 无 `.cachedMaxCount(...)` | 未限制缓存数量 |
| 源码 | `cachedMaxCount` 值 ≥ 页签总数 | 等效不限制 |

**严重度**：High — 8页签各预解码2张大图 = ~133MB 常驻

**修复建议**：
1. 设置 `cachedMaxCount(1, TabsCacheMode.CACHE_BOTH_SIDE)`，当前页+两侧各1页=最多3页缓存
2. `aboutToDisappear` 释放 PixelMap（`pixelMap.release()`）
3. 使用 hilog 跟踪 APPEAR/DISAPPEAR 验证缓存释放

---

## H-03：Tabs 预加载不可见页

**故障机制**：`TabsController.preloadItems([index])` 预加载指定 `TabContent` 子节点——即使该页签未被选中、未显示，也会触发其子组件 `aboutToAppear`（被构建/加载）。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | 当前页签 index=0，但 index=2 的子树已存在 | 预加载了未访问页 |
| 源码 | `.preloadItems(` 调用 | 预加载 API 使用 |
| 源码 | `preloadItems` 在 `Tabs.onAppear` 调用 | 进入即预加载 |

**严重度**：High — 预加载8张大图 = ~66MB 常驻

**修复建议**：
1. 仅在用户有明确意图（如点击"下一页"）时预加载相邻页
2. 不要在 `Tabs.onAppear` 预加载非相邻页签
3. 如必须预加载，预加载轻量页（无大图/复杂组件）

---

## H-04：Tabs 动画滑过中间页

**故障机制**：点击 Tab 页签默认带切换滑动动画，页面从当前页滑向目标页，会把"中间页"滑过界面 → 中间页 `aboutToAppear` 触发 → 中间页被加载。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| 源码 | `animationMode` 未设或为 `CONTENT_FIRST` | 默认滑动动画 |
| 源码 | 页签数 > 2 且无 `NO_ANIMATION` | 中间页可能被滑过 |
| 源码 | 中间页含大图/复杂组件 | 滑过即加载高成本 |

**严重度**：Medium — 8张大图 ~66MB 一次性加载

**修复建议**：
1. 设置 `animationMode(AnimationMode.NO_ANIMATION)` 直跳，避免滑过中间页
2. 或将重负载页放在首位/末位，避免成为中间页

---

## H-05：List 非懒加载

**故障机制**：`List` + `ForEach` 一次性全量建好 N 项子组件，离屏不回收，内存随 N 线性增长。应使用 `LazyForEach` 仅建可见+缓冲项。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | List 子节点数远超屏幕可见行数 | 全量加载 |
| Dump | 滚动后离屏节点仍在树中 | 不回收 |
| 源码 | `List` 内用 `ForEach` 而非 `LazyForEach` | 全量构建 |
| 源码 | `ForEach` 用于长列表（N > 50） | 大量节点 |

**严重度**：High — N=200 时 ~400+ 组件节点常驻

**修复建议**：
1. 将 `ForEach` 替换为 `LazyForEach` + `IDataSource` 实现
2. `LazyForEach` 仅建可见行 + cachedCount 缓冲行，离屏自动回收
3. 如数据量小（N < 20）可保留 `ForEach`

---

## H-06：List cachedCount 过大

**故障机制**：`LazyForEach` 虽然懒加载，但 `cachedCount` 设过大仍会在可见区外预建大量非激活组件常驻内存。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | List 可见区外有大量非激活子节点 | cachedCount 过大 |
| 源码 | `.cachedCount(` 值 > 5 | 预建过多 |
| 源码 | `cachedCount` 值 >> 单次滑动可见行数 | 远超需求 |

**严重度**：Medium — cachedCount=200 时 ~400 项预建

**修复建议**：
1. `cachedCount(1)` 合理缓冲，可见区外上下各预建1行
2. 一般 `cachedCount` 设为 1-3 即可满足滑动流畅性
3. 不要用大 `cachedCount` 替代懒加载

---

## H-07：布局冗余深嵌套

**故障机制**：过多嵌套容器（Stack→Column→Row→Stack→… 20层）+ ForEach 层级不合理（三层）+ 多余 if/else 分支，导致大量冗余组件节点。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | `maxDepth` > 15 | 深度过大 |
| Dump | 同类型容器节点连续出现 > 3 层 | 无意义嵌套 |
| Dump | 总节点数 >> 实际内容项数 | 冗余节点 |
| 源码 | 连续 Stack/Column/Row 嵌套 > 5 层 | 无意义包裹 |
| 源码 | ForEach 嵌套 ForEach > 2 层 | 可拍平 |
| 源码 | `if (true) { Stack() { Stack() { ... } } }` | 恒真分支多余嵌套 |

**严重度**：Medium — 2000+ 额外节点 × ~3-5KB ≈ 6-10MB

**修复建议**：
1. 扁平化布局：用 `@Builder` 分解各区域，每区 2-4 层嵌套
2. ForEach 单层遍历，不要分组→分行→分单元格三层
3. `if` 仅用于必要条件（箭头有无），不要每个项套 if/else 两条深嵌套分支
4. 移除无内容的空容器包裹

---

## H-13：Canvas 替代原生渐变

**故障机制**：有原生 `.linearGradient()` 接口却用 `Canvas` + `createLinearGradient/fillRect` 命令式绘制静态全屏渐变背景。Canvas 会分配与组件像素尺寸成比例的 GPU/DMA surface（全屏约数十 MiB 常驻），而 `linearGradient` 走 shader 路径 O(1) 内存。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | `Canvas` 节点 frame 为全屏尺寸 | 全屏 Canvas |
| 源码 | `Canvas(` 后 `createLinearGradient` / `fillRect` | 命令式渐变 |
| 源码 | 有 `linearGradient` 可用但选了 Canvas | 反模式 |

**严重度**：Medium — 全屏 DMA surface 数十 MiB

**修复建议**：
1. 静态渐变背景用 `Column().linearGradient({ direction, colors })` 声明式接口
2. Canvas 仅用于动态绘制（图表、自定义动画），不用于静态背景
3. 用 SmartPerf 的 `gpuPss` / `graphicPss` 度量 DMA 差异

---

## H-14：ImageAnimator 帧集过量

**故障机制**：`ImageAnimator` 的 `images` 喂过多过大帧（尤其 PixelMap src 预解码），全部帧会预解码常驻 native heap，无限循环不释放。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | `ImageAnimator` 节点下有大量 Image 子节点 | 帧数过多 |
| Dump | Image `rawImageSize` 大且数量多 | 过大帧 |
| 源码 | `ImageAnimator().images(this.images)` 且 images.length > 10 | 过多帧 |
| 源码 | 预解码 PixelMap 作为帧 src 且帧尺寸 > 500×500 | 过大帧 |
| 源码 | `.iterations(-1)` 无限循环 | 不释放 |

**严重度**：Medium — 30张720×720 ≈ 59MB 常驻

**修复建议**：
1. 控制帧数（建议 ≤ 10 帧）
2. 对帧图下采样到展示尺寸（如 256×256）
3. 用 string/Resource src 让组件按需解码，而非预解码 PixelMap
4. `aboutToDisappear` 释放所有 PixelMap

---

## H-15：Video 组件常驻

**故障机制**：ArkUI `Video` 组件 autoplay + `onFinish` 循环重启，使视频解码器与缓冲常驻，native 媒体内存持续增长。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | `Video` 节点存在于非视频页 | 不该有 Video |
| 源码 | `Video({ src })` + `controller.start()` in aboutToAppear | 进入即播 |
| 源码 | `.onFinish(() => { controller.start() })` | 循环播放 |

**严重度**：Low — 媒体内存在合理使用时可接受

**修复建议**：
1. 非视频页不要放置 Video 组件
2. 页面离开时 `controller.stop()` 停止播放
3. 短动画用 ImageAnimator 替代 Video

---

## H-08：页面栈过深

**故障机制**：NavDestination 反复跳转（如腾讯新闻详情页反复点击相关新闻），页面栈中 NavDestination 数量爆炸，每个页面持有独立组件树和数据，内存持续增长不回收。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | NavDestination 节点数 > 5 | 页面栈过深 |
| Dump | 同类型 NavDestination 重复出现 | 反复跳转同类型页面 |
| 源码 | `NavPathStack` push 后无 pop | 只进不出 |
| 源码 | `NavDestination` 内含重负载组件 | 每页内存开销大 |

**严重度**：High — 每页数十 MB，10 页即数百 MB

**修复建议**：
1. 限制 NavPathStack 深度，超过阈值时移除早期页面
2. 详情页用 `replacePath` 替代 `pushPath`，避免栈增长
3. 离开页面时调用 `pop()` 释放页面栈
4. 重负载页面 `aboutToDisappear` 释放资源

---

## H-09：缓存池/复用池未释放

**故障机制**：List 上下滚动后，退台（aboutToDisappear/离屏）的 ListItem 缓存节点未释放。典型如新闻列表上下缓存 6 个列表项，上下滚动后退后台存在缓存节点未释放。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | 游离根（LazyForEach缓存/Repeat缓存）节点数过多 | 缓存未释放 |
| Dump | 离屏 ListItem 仍在树中 | 退台不释放 |
| 源码 | `List` 无 `cachedCount` 限制或值过大 | 缓存过多 |

**严重度**：High — 每缓存项含大图/复杂数据，累积不释放

**修复建议**：
1. 设置合理的 `cachedCount(1)` 限制缓存数量
2. `aboutToDisappear` 释放 ListItem 中的 PixelMap 等资源
3. 使用 `@Reusable` 组件复用而非缓存
4. 检查游离根数量，确保退台节点被回收

---

## H-10：XComponent 未释放

**故障机制**：XComponent 创建的 nativeWindow/Surface 在组件销毁后存在延迟释放。典型如剪映冷启动后点击创作前，Surface 的 nativeWindow 未及时释放。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | XComponent 节点存在但页面已离开 | 延迟释放 |
| 源码 | `XComponent` 无 `onDestroy` 释放逻辑 | 缺少清理 |
| 源码 | nativeWindow 引用未置空 | 持有引用 |

**严重度**：Medium — nativeWindow 占用 GPU 内存

**修复建议**：
1. XComponent `onDestroy` 回调中释放 nativeWindow
2. 页面离开时主动调用释放接口
3. 确保 Surface 引用置空，避免延迟 GC

---

## H-11：Image 不合理超大图

**故障机制**：不合理的大图加载——不知名大图、评论区相关图片提前渲染。典型如腾讯地图点击退出导航多了 3 张不知名大图，以及评论区相关图片提前渲染。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | Image `rawImageSize` 超大（> 1080×1920） | 不合理大图 |
| Dump | 不可见区域有 Image 节点 | 提前渲染 |
| Dump | Image 总 DMA > 20MB | 过多大图 |
| 源码 | `Image` src 指向超大资源 | 未下采样 |

**严重度**：Medium — 每张大图 DMA 数 MB

**修复建议**：
1. 对大图下采样到展示尺寸（如 `Image` 组件设 `objectFit`）
2. 非可见区域不提前加载图片
3. 使用 SVG 替代位图减少 DMA
4. 滚动列表用 LazyForEach 按需加载图片

---

## H-12：命令式节点缓存

**故障机制**：应用通过 `BuilderNode`、CAPI 等命令式 API 创建并持有节点，这些节点不参与声明式组件树管理，生命周期由开发者手动控制，容易遗漏释放。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| 源码 | `new BuilderNode()` 后无 `dispose`/释放 | 创建不释放 |
| 源码 | CAPI `ArkUI_NodeHandle` 持有不释放 | 命令式节点泄漏 |
| Dump | 命令式节点（IsCNode/IsArkTsFrameNode）游离 | 脱离声明式树 |

**严重度**：Medium — 命令式节点脱离框架管理，难追踪

**修复建议**：
1. BuilderNode 使用后调用 `dispose()` 释放
2. CAPI 节点手动管理生命周期，页面离开时释放
3. 避免在循环中创建命令式节点不释放
4. 使用声明式组件替代命令式节点（优先 @Builder/@Reusable）

---

## H-16：ArkWeb 预渲染/预热过多

**故障机制**：在 `aboutToAppear` 中通过 `createNWeb` 预渲染多个真实 Web 页面（prerender=true）或预创建多个 about:blank 渲染进程（prerender=false），每个 Web 组件含独立渲染进程和已渲染页面内容。离开页面时未调用 `destroyNWeb`/`disposeNode` 释放，Web 节点存入模块级 NodeMap 持续常驻。典型场景：预渲染 3 个 Web 页面以加速后续导航，但实际用户可能只访问 1 个。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| 源码 | `createNWeb` 调用 ≥ 3 次 | 预渲染/预热过多 |
| 源码 | `aboutToAppear` 中创建 Web 组件但 `aboutToDisappear` 无 `destroyNWeb`/`disposeNode` | 无释放逻辑 |
| Dump | `Web` 节点 ≥ 3 个（含游离 Web 节点 IsOnMainTree:0） | 多个 Web 进程常驻 |

**严重度**：Medium — 每个 Web 渲染进程 baseline 内存开销大

**修复建议**：
1. 预渲染/预热数量减少到 1 个（仅预渲染用户高概率访问的页面）
2. `aboutToDisappear` 中调用 `destroyNWeb` 释放未使用的预渲染节点
3. 按需创建而非预创建——用户实际导航时才创建 Web 组件
4. FMP 后调用 `controller.onInactive()` 停止后台渲染

---

## H-17：BuilderNode 销毁流程不完整

**故障机制**：BuilderNode 是命令式 UI 节点 API，创建后脱离声明式树管理。销毁时必须按 3 步顺序执行，否则底层资源（nativeNode、ContentSlot）无法正确释放，导致内存泄漏。

**正确销毁流程**：
1. `NodeContainer(undefined)` — 从 UI 树移除关联节点
2. `builder.update(undefined)` — 清空构建内容
3. `builder.dispose()` — 释放底层资源

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| 源码 | `new BuilderNode` 创建但缺 `dispose()` 调用 | 未释放底层资源 |
| 源码 | 有 `dispose()` 但缺 `update(undefined)` | 销毁流程不完整 |
| 源码 | 有 `dispose()` 但缺 `NodeContainer(undefined)` | 未先从 UI 树移除 |
| Dump | 命令式BuilderNode游离根未释放（dump 侧由 H-12 覆盖检测，H-17 仅源码侧） | 游离缓存残留 |

**严重度**：Medium/High — 缺 `dispose()` 为 High，缺其他步骤为 Medium

**修复建议**：
1. 按顺序执行 3 步销毁：①NodeContainer(undefined) → ②builder.update(undefined) → ③builder.dispose()
2. 优先使用声明式 @Builder/@Reusable 替代命令式 BuilderNode
3. 在 aboutToDisappear 中执行销毁流程

---

## H-04 dump 侧信号：Tab 动画未禁用（animationDuration/animationMode）

**故障机制**：Tabs 组件默认启用滑动动画，切换页签时会滑过中间页触发其构建和加载。即使 animationDuration 设为 0，动画系统仍激活，中间页仍被加载。应使用 animationMode(NO_ANIMATION) 完全禁用动画。此为 H-04 的 dump 侧检测信号，与源码侧 H-04 同根因，使用同一 hotspot_type（tabs_animation_midpage）合并去重。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | Tabs 节点 `animationDuration=0` | 动画系统仍激活（时长为 0 但系统未禁用） |
| Dump | Tabs 节点 `animationMode` 不为 `NO_ANIMATION` | 动画未禁用 |
| 源码 | `Tabs` ≥ 3 TabContent 无 `animationMode(AnimationMode.NO_ANIMATION)` | 滑动动画会触发中间页加载 |

**严重度**：Medium — 动画触发中间页冗余加载

**修复建议**：
1. 设置 `.animationMode(AnimationMode.NO_ANIMATION)` 完全禁用动画，改为直跳模式
2. 避免仅设 animationDuration(0)（动画系统仍激活）

---

## H-18：缓存池清空使能未设置

**故障机制**：MemOpt/ReusableMemOpt/RepeatMemOpt 是缓存池清空使能字段。未启用时，页面离开后缓存池不被清空，缓存节点（LazyForEach缓存/Repeat缓存/Reusable复用）持续占用内存。

**检测信号**：

| 侧 | 信号 | 说明 |
|----|------|------|
| Dump | `MemOpt` 字段存在但值为 false/0 | 通用内存优化未启用 |
| Dump | `ReusableMemOpt` 字段存在但值为 false/0 | Reusable 缓存清空未启用 |
| Dump | `RepeatMemOpt` 字段存在但值为 false/0 | Repeat 缓存清空未启用 |

**严重度**：Medium — 缓存池不释放导致内存持续占用

**修复建议**：
1. 启用缓存池清空使能（MemOpt/ReusableMemOpt/RepeatMemOpt 设为 true）
2. 确保页面离开时缓存池被清空释放
3. 在 aboutToDisappear 中主动调用缓存清空
