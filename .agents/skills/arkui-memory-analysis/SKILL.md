---
name: arkui-memory-analysis
description: 检查 ArkUI 应用源码和 inspector dump 中的 18 类内存反模式（不可见页面、Tabs 缓存/预加载/动画、长列表非懒加载、布局冗余、页面栈过深、缓存池未释放、XComponent/命令式节点未释放、Image 超大图、Canvas 渐变、ImageAnimator/Video 常驻、ArkWeb 过多、BuilderNode 销毁流程不完整、缓存池清空使能未设置）。通过关键词/正则 + 反模式匹配分析 .ets 源码，通过节点树结构分析 dump 文件，输出定性报告（Markdown）+ 标准化 schema（JSON）+ 内存测试用例构造指南。适用于内存劣化排查、不可见页面检测、缓存池泄漏诊断、组件树优化等诉求。
license: MIT
compatibility: scripts/ 下包含 Node.js ESM 脚本（.mjs），需 Node.js 18+ 环境执行
metadata:
  author: keerecles
  version: "1.0.0"
---

# ArkUI 内存热点分析

分析 ArkUI 应用源码（.ets）和/或 inspector dump 文件，识别内存反模式，输出定性报告 + 标准化 schema。

> **⚠️ 硬性规则（FAIL 级）**：使用本 Skill 时，AI 绝对不能修改 npm 工具（arkui-dump-viewer）的源代码。工具代码由维护者统一管理，AI 只能调用工具（运行脚本/CLI），不得编辑、覆盖、重命名 `src/`、`dist/`、`scripts/install.sh` 或 npm 包内的任何文件。如遇工具问题，向用户报告问题现象和建议，由用户决定是否修改。

> **目录结构例外说明**：`test-cases/` 位于 skill 根目录（而非 `assets/` 下），是因为 hmos-skill-test-runner 流水线只识别 `<skill>/test-cases/` 固定路径。此为兼容性需要，非推荐结构。详见 `assets/README.md`。

## 场景路由

```
用户输入
├─ 仅 .ets 源码 → 源码分析模式（[源码检查项](#源码检查项)）
├─ 仅 .dump/.json dump → Dump 分析模式（[Dump 检查项](#dump-检查项)）
├─ 源码 + dump → 综合分析模式（各自分析后合并）
└─ 无有效输入 → 询问用户提供 .ets 或 .dump/.json 文件
```

## 决策树

> 场景路由决定分析模式后，以下决策树处理分析过程中的细粒度判断场景。

```
综合分析模式（source + dump 同时命中）
├─ source 与 dump 信号一致（同一热点类型两侧都命中）
│  └─ 合并为 1 条 finding，location 标注「源码 + dump 双侧确认」，severity 取较高侧
├─ source 命中但 dump 未命中（代码有反模式但运行时未触发）
│  └─ 保留 source 侧 finding，severity 降一级（运行时未验证），description 注明「dump 未观察到」
├─ dump 命中但 source 未命中（运行时表现异常但源码无直接证据）
│  └─ 保留 dump 侧 finding（运行时事实优先），description 注明「源码未定位直接成因，建议结合动态 trace」
└─ source 与 dump 信号冲突（如源码用 LazyForEach 但 dump 显示非懒加载）
   └─ 以 dump 为准（运行时实际行为），source 侧标注「代码声明与运行时不符」作为补充 finding

同类发现合并/去重
├─ 同一 hotspot_type + 同一 location（节点/文件行）→ 合并为 1 条，severity 取最高
├─ 同一 hotspot_type + 不同 location → 各保留，按 severity 排序
└─ 不同 hotspot_type + 同一 location → 各保留（一个节点可能同时有多种问题）

严重度排序与人工确认阈值
├─ high（不可见页面、Tabs 缓存、长列表不懒加载等）→ 报告置顶，建议立即修复
├─ medium（Canvas 渐变、ImageAnimator、命令式节点等）→ 报告次序，建议排期修复
├─ low（Video 常驻等）→ 报告末尾，建议评估
└─ ≥3 条 high 或总 findings ≥20 → 建议人工确认是否需拆分多轮修复（避免单次改动过大）

ForEach 与 LazyForEach 并存
├─ 同一滚动容器内 ForEach 与 LazyForEach 同时存在 → 命中 H-05（非懒加载），LazyForEach 部分在 description 注明
├─ 仅 ForEach（无 LazyForEach）→ 命中 H-05
├─ 仅 LazyForEach → 不命中（合规）
└─ ForEach 在非滚动容器内（如 Column）→ 不命中 H-05，但可结合原则 4（数量比率失调）评估
```

## 工作流程

### 输入

用户提供 .ets 源码文件/目录、.dump/.json dump 文件，或两者都有。支持三种分析模式：

### 处理（AI Agent + 脚本结合）

**Step 1：脚本快速扫描（确定性检测）**

根据输入类型执行对应脚本，获取机械检测结果（秒级，标准化 schema）：
- 源码分析：`node scripts/analyze-arkui-source.mjs <文件或目录>` → 源码 schema
- Dump 分析：`node scripts/analyze-arkui-dump.mjs <dump文件>` → dump schema

**Step 2：AI Agent 深度分析（语义补充）**

AI Agent 加载本 SKILL.md 的 18 类热点规则，基于 Step 1 的脚本结果做深度分析：
- 按「[快速检测规则](#快速检测规则)」逐类匹配，补充脚本未覆盖的语义问题
- 对脚本检出的 finding，补充上下文分析（如 Service 常量间接控制、跨文件关联）
- 检测脚本未覆盖的模式：Image autoResize:false、ForEach 全局比率、语义级泄漏
- 合并脚本发现 + AI 补充发现，去重后输出完整 schema

**Step 3：生成产出**

```bash
# 方式 A：手动指定 schema + dump 文件/目录
node scripts/generate-arkui-report.mjs \
  --source-schema <源码schema> \
  --dump-schema <dump-schema> \
  --dump-file <dump文件或目录> \
  --source-dir <源码目录> \
  --output-dir arkui_memory_analysis

# 方式 B：自动遍历 dump 目录（推荐）
node scripts/generate-arkui-report.mjs \
  --source-schema <源码schema> \
  --dump-dir <dump目录> \
  --source-dir <源码目录> \
  --output-dir arkui_memory_analysis
```

`--dump-dir` 自动遍历目录下所有 .dump 文件，逐个调用 `analyze-arkui-dump.mjs` 生成 schema 并合并，同时传目录给 CLI 生成 HTML。无需手动预扫描。
`--source-dir` 传入源码目录用于从源码提取页面导航结构（@Entry/Button/NavPathStack），生成含具体页面跳转+按钮操作步骤的用例构造指南；不传则指南降级为通用版。用例构造指南仅从源码分析生成（不依赖 dump）。

### 输出

产出目录 `arkui_memory_analysis/`（生成在当前工作目录下）：

```
arkui_memory_analysis/
├── arkui-memory-report.md     # Skill 定性报告（含问题诊断/修改建议/严重度分级）
├── arkui-memory-schema.json   # Skill 标准化 JSON 数据（hotspot_type/severity/file/line/...）
├── arkui-test-guide.md        # 内存测试用例构造指南（仅源码分析生成，应用侧真机操作步骤+导航路径）
└── arkui_dump_viewer/         # 工具解析 dump 生成的所有文件
    ├── index.html             # HTML 可视化（交互式组件树+内存热力+使用指南）
    ├── *.js                   # JSON 数据文件（dataset/usecase）
    └── *.xlsx + images/       # 统计表 + SVG 图表
```

- **Markdown 报告**：给人看，含分析汇总、热点分布、详细问题诊断、优化建议
- **标准化 JSON**：给机器消费，可被下游工具（CI/CD、趋势追踪）直接解析
- **测试用例构造指南**：**仅从源码分析生成**（不依赖 dump）——源码分析→指南→开发者据指南测试获取 dump→dump 反馈 skill+可视化工具，形成数据飞轮。覆盖泄漏检测/回收验证/压力测试三类维度，含具体页面导航路径+按钮操作步骤（从源码提取 @Entry/Button/NavPathStack），不提供自动执行脚本，不生成框架用例；无源码分析时不生成指南
- **HTML 可视化**：工具解析 dump 后生成的所有文件，含交互式 SVG 组件树、JSON 数据、统计表、图表

## 快速检测规则

> **性能优先**：先按以下关键词快速匹配代码，命中即输出结论，无需逐条深度分析。未命中关键词的规则跳过。
>
> 检测方式不限——源码静态分析和 dump 动态分析均可用于任何热点类型，建议混合使用以达最佳检测效果。

| 关键词/模式 | 命中热点 | 严重度 |
|-------------|----------|--------|
| `visibility(Visibility.Hidden)` | H-01 不可见页面 | High |
| `Tabs()` 无 `cachedMaxCount` 且 TabContent ≥ 3 | H-02 Tabs 缓存过多 | High |
| `.preloadItems(` | H-03 预加载不可见 Tab 页 | High |
| `Tabs` ≥ 3 TabContent 无 `NO_ANIMATION` | H-04 冗余加载中间页 | Medium |
| 滚动容器（List/Swiper/Grid/WaterFlow 等）内 `ForEach` 非 `LazyForEach` | H-05 长列表不懒加载 | High |
| `.cachedCount(` 值 > 3 | H-06 CachedCount 不合理 | Medium |
| 连续容器组件（Stack/Column/Row/Flex/Grid/Navigation 等）> 8 层 或 三层嵌套 ForEach | H-07 布局冗余低效 | Medium |
| NavDestination 数 > 5 或只 push 无 pop | H-08 页面栈过深 | High |
| 游离缓存根节点未释放 | H-09 缓存池未释放 | High |
| `XComponent` 无 `onDestroy` 释放 | H-10 XComponent 未释放 | Medium |
| Image `rawImageSize` > 1080×1920 | H-11 不合理超大图 | Medium |
| 命令式节点 API（BuilderNode/NodeController/FrameNode/ArkUI_NodeHandle 等）无对应 dispose | H-12 命令式节点缓存 | Medium |
| `Canvas` + `createLinearGradient` | H-13 Canvas 渐变 | Medium |
| `ImageAnimator` frameCount > 10 | H-14 帧集过量 | Medium |
| `Video` + `controller.start()` + `onFinish` | H-15 Video 常驻 | Low |
| `createNWeb` ≥ 3 或 `Web` 节点 ≥ 3 | H-16 ArkWeb 过多 | Medium |
| `new BuilderNode` 未按 3 步销毁（NodeContainer(undefined)→update(undefined)→dispose()） | H-17 BuilderNode 销毁流程不完整 | Medium/High |
| dump 中 Tabs `animationDuration=0` 或 `animationMode!=NO_ANIMATION`（H-04 dump 侧信号，与源码侧同根因合并） | H-04 冗余加载 Tabs 中间页面 | Medium |
| dump 中 `MemOpt/ReusableMemOpt/RepeatMemOpt` 未启用 | H-18 缓存池清空使能未设置 | Medium |

## 源码检查项

- [ ] **H-01** `visibility(Visibility.Hidden)` 后跟复杂 build() → 不可见页面被构建
- [ ] **H-02** `Tabs()` 无 `.cachedMaxCount(...)` 且 TabContent ≥ 3 → 缓存数量过多
- [ ] **H-03** `.preloadItems(` 调用，尤其在 `onAppear` 中 → 预加载不可见 Tab 页
- [ ] **H-04** `Tabs` 有 ≥ 3 个 TabContent 且无 `NO_ANIMATION` → 冗余加载中间页
- [ ] **H-05** 滚动容器（List/Swiper/Grid/WaterFlow 等）内用 `ForEach` 而非 `LazyForEach` → 长列表不懒加载
- [ ] **H-06** `.cachedCount(` 值 > 3 → 滚动预加载不合理
- [ ] **H-07** 连续容器组件（Stack/Column/Row/Flex/Grid/Navigation 等）嵌套 > 8 层 或 三层嵌套 ForEach → 布局冗余低效
- [ ] **H-08** `NavPathStack` 只 push 无 pop 或 NavDestination 数 > 5 → 页面栈过深
- [ ] **H-09** 游离缓存根节点（LazyForEach缓存/Repeat缓存）未释放 → 缓存池未释放
- [ ] **H-10** `XComponent` 无 `onDestroy` 释放 nativeWindow → XComponent 未释放
- [ ] **H-11** `Image` src 指向超大资源（> 1080×1920）→ 不合理超大图
- [ ] **H-12** 命令式节点 API（BuilderNode/NodeController/FrameNode/ArkUI_NodeHandle 等）后无对应 dispose/release → 命令式节点缓存
- [ ] **H-13** `Canvas` + `createLinearGradient`/`fillRect` → Canvas 替代原生渐变
- [ ] **H-14** `ImageAnimator` 且 frameCount > 10 或 `iterations(-1)` → 帧集过量
- [ ] **H-15** `Video({ src })` + `controller.start()` + `onFinish` 循环 → Video 常驻
- [ ] **H-16** `createNWeb` ≥ 3 或 `Web` 节点 ≥ 3 且无 `aboutToDisappear` 释放 → ArkWeb 预渲染/预热过多
- [ ] **H-17** `new BuilderNode` 实例未按 3 步销毁流程：① NodeContainer(undefined) 下UI树 → ② builder.update(undefined) → ③ builder.dispose()，缺任一步 → BuilderNode 销毁流程不完整

## Dump 检查项

- [ ] **H-01** `VisibleAndActive: '0'` 的节点下有 > 10 个后代或 > 1MB → 不可见页面
- [ ] **H-02** 多个 `TabContent` 子树同时存活，其中 ≥ 2 个不可见 → Tabs 缓存过多
- [ ] **H-03** 当前页签外的 TabContent 已构建（有 > 5 个后代）→ 预加载不可见页
- [ ] **H-04**（dump 侧信号）Tabs 节点 `animationDuration=0` 或 `animationMode` 不为 `NO_ANIMATION` → Tab 动画未禁用（与源码侧 H-04 同根因，合并去重）
- [ ] **H-05** 滚动容器（List/Grid/Swiper/WaterFlow）子节点数 > 30 且无 LazyForEach → 长列表不懒加载
- [ ] **H-06** LazyForEach缓存/Repeat缓存 游离根节点 > 20 → CachedCount 不合理
- [ ] **H-07** `maxDepth` > 15 且容器组件（Stack/Column/Row/Flex/Grid/Navigation 等）连续嵌套 > 5 → 布局冗余低效
- [ ] **H-08** NavDestination 节点数 > 5 → 页面栈过深
- [ ] **H-09** 游离缓存根节点数 > 100 → 缓存池未释放
- [ ] **H-10** XComponent 节点在页面离开后仍存在 → XComponent 未释放
- [ ] **H-11** Image `rawImageSize` > 1080×1920 且数量 > 5 → 不合理超大图
- [ ] **H-12** 命令式节点（IsCNode/IsArkTsFrameNode/IsRootBuilderNode/IsArkTsRenderNode/NodeContainer）游离 → 命令式节点缓存
- [ ] **H-13** `Canvas` 节点 frame > 500×500 → 全屏 Canvas（DMA surface）
- [ ] **H-14** `ImageAnimator` 下 Image 子节点 > 10 → 帧集过量
- [ ] **H-15** `Video` 节点存在 → 常驻
- [ ] **H-16** `Web` 节点 ≥ 3（含游离 Web 节点）→ ArkWeb 预渲染/预热过多
- [ ] **H-18** `MemOpt`/`ReusableMemOpt`/`RepeatMemOpt` 字段存在但值为 false/0 → 缓存池清空使能未设置

## 报告格式

输出 Markdown 报告：分析汇总 → 热点分布 → 详细问题诊断（位置/描述/修复建议/严重度）→ 总体优化建议 → 标准化 schema（JSON）。

## 语义关联分析原则

> AI Agent 在 Step 2 深度分析时，不应仅做单点模式匹配，还要基于以下原则做多信号关联推理。原则是通用的，能覆盖未知的新问题。

### 原则 1：不可见 + 资源持有 = 浪费

**推理**：如果一个节点/子树不可见（`VisibleAndActive:0` 或 `visibility(Hidden)`）但持有重资源（大内存/XComponent/Canvas/nativeWindow/PixelMap/视频播放器），则该资源被浪费——构建了但用户看不到。

**信号**：不可见标记 + 内存估算大 / 含 XComponent/Canvas/Video/Web / 含大量 Image

### 原则 2：已消失但仍存在 = 泄漏

**推理**：如果节点的生命周期标志表示已结束（`IsFrameDisappear:1`、`IsOnMainTree:0`）但仍存在于 dump 树中，说明该节点未被正确回收/释放。

**信号**：IsFrameDisappear:1 + 节点仍在树中 / IsOnMainTree:0 + VisibleAndActive:1（游离但活跃）/ 节点数远超正常范围

### 原则 3：有创建无释放 = 生命周期缺失

**推理**：如果代码中创建了资源（Worker/TaskPool/Web/BuilderNode/PixelMap）但对应的 `aboutToDisappear` 中没有释放调用，则页面离开后资源泄漏。

**信号**：`aboutToAppear`/构造函数中创建 + `aboutToDisappear` 中无对应 `terminate()`/`dispose()`/`release()`/`destroy()`

### 原则 4：数量比率失调 = 系统性问题

**推理**：如果两种对立模式的数量比率严重失调（如 ForEach 远多于 LazyForEach，或 autoResize:false 远多于 true），说明不是个别疏忽而是系统性问题。

**信号**：统计全局 ForEach vs LazyForEach / autoResize:false vs true / 游离根数量 vs 正常根数量

### 原则 5：常量间接控制 = B 版劣化

**推理**：如果反模式行为由 Service 常量控制（如 `if (Service.USE_XXX)` 或三元表达式），说明 A/B 两版共用同一页面文件，B 版通过常量启用劣化路径。需追踪常量定义确认实际值。

**信号**：`Service.CONSTANT ?` 三元 / `if (Service.CONSTANT)` 条件分支 / `Service.CONSTANT === true` 判断

### 原则 6：跨文件引用 = 全局持有

**推理**：如果资源被存入模块级变量（全局 Map/Array/单例），即使页面销毁，资源仍被全局引用持有无法回收。

**信号**：`const cache = new Map()` + `.set(id, resource)` + 无 `.delete()`/`.clear()` 调用

## ArkUIDumpViewer 可视化工具

推荐使用 [ArkUIDumpViewer](https://gitcode.com/keerecles/ArkUIDumpViewer) 查看交互式组件树和内存热力：

```bash
npm run all    # 生成 memory.csv + 构建交互式 HTML
```

核心能力：树视图（按状态着色）、内存热力（native heap + DMA）、隐藏态视图、游离根开关、搜索过滤。

## 标准化 Schema

```json
{
  "schema_version": "1.0",
  "analysis_type": "dump | source",
  "findings": [
    { "hotspot_type": "...", "severity": "high|medium|low", "file": "<path>", "line": 0, "location": "...", "description": "...", "suggestion": "..." }
  ]
}
```

## 参考文档

- [ArkUI 内存热点故障树模式库](references/arkui-anti-patterns.md)
