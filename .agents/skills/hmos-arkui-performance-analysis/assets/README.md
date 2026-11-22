# ArkUI 性能分析

`hmos-arkui-performance-analysis` 是用于诊断 ArkUI 性能问题的 Agent Skill。它只读分析开发者提供的真实 ArkTS 代码，覆盖组件、滑动、启动、动效和转场，按[性能分析报告与交付](../references/report-contract.md)逐项呈现分析结果。

工作流程和约束以 [SKILL.md](../SKILL.md) 为准。

## 分析能力

### 分析过程

1. **工程版本确认**：读取 `build-profile.json5` 的 compatibleSdkVersion/targetSdkVersion，判定状态管理 V1/V2，核对每条规则的版本适用条件（如 @ReusableV2 需 API 18+、框架 GlobalReuse 需 API 26.0.0）。
2. **场景路由与只读检查**：按问题现象路由到组件、滑动、启动、动效或转场检查项，读取目标代码、子组件定义与调用目标，核对成立条件与合理反例；全程只读，不修改代码。
3. **报告输出**：按报告要求逐项说明成立的问题；没有成立问题时简短说明已读范围与必要限制，证据不足时不强行归因。

### 能识别的问题

| 场景 | 典型现象 | 能识别的问题 |
| --- | --- | --- |
| UI组件性能分析 | 刷新范围过大、组件反复创建、数据传递开销 | 状态观测范围过宽（缺 @Track / @ObservedV2+@Trace）；@Prop 整对象深拷贝；纯展示组件可评估改用 @Builder；同一父组件下反复创建组件，且未使用 @Reusable/@ReusableV2；reuseId 分组错误（按业务 ID 过细分池、不同子树结构未分组）；BuilderNode 参数更新误用 rebuild 触发重建；onFrame/onIdle 内重计算或同步 IO；onAreaChange 回写自身布局输入 |
| UI滑动性能分析 | 滚动、惯性滑动或拖动期间卡顿 | ForEach 全量创建（应 LazyForEach / Repeat+virtualScroll）；IDataSource 缺方法、cachedCount 不当、图片场景缺预取；onDidScroll 等高频回调内日志、计算、空监听或逐帧脏节点；布局嵌套层级冗余；Flex+flexGrow/flexShrink 二次布局 |
| UI启动性能分析 | 冷启动首帧慢、首页内容显示慢、前置页进入首页慢 | 首屏列表全量创建；初始隐藏的复杂子树用 visibility 常驻首屏；aboutToAppear 内同步重计算与 async/await 执行边界误用；大图 syncLoad 同步解码及完成后尺寸跳变；中间容器层级冗余；关键内容被非关键数据阻塞（应分阶段展示）；前置页展示期间可提前构建首页，但未执行 |
| UI动效性能分析 | 动画卡顿、掉帧、延迟 | animateTo 闭包缺失；setTimeout/setInterval/onFrame 手动逐帧动画；不可见/后台组件动画未停；动画参数无效值或不合理配置；renderGroup 缺失或误用；布局属性动画可改图形变换 |
| UI转场性能分析 | Swiper 翻页、页签切换、页面进入/返回/replace 卡顿 | 邻页未提前准备或缓存范围过大；翻页时才准备图片等资源（未用 onAnimationStart 窗口）；进入时整批提交重负载子树（业务允许时可分帧）；页签/跨页局部复用池不能共享导致重复创建；内容切换改变宿主尺寸，导致布局计算向外扩散；等非关键内容就绪才显示目标页；前置页期间未提前构建首页 |

诊断区分状态管理 V1/V2，并按工程声明的 `compatibleSdkVersion` / `targetSdkVersion` 核对规则适用条件。非 ArkUI 性能问题（运行时、网络、ArkWeb 等）和完整的状态管理 V1/V2 迁移实施不属于本 Skill 的处理范围；需要实测数据时提供采集与观察指导，不自动修改应用、不执行设备采集或 Trace 自动归因。

### 报告内容与交付

每个成立的问题保留问题位置、代码事实与条件、性能机制、修改建议、语义影响、预期收益和验证方法。代码整改默认给出最小diff或可替换代码，具体形式、适用条件及对话/文件交付方式统一见[性能分析报告与交付](../references/report-contract.md)。官方链接按需提供，不另设“未解决项”栏目。

## 快速开始

### 准备输入

使用前提供以下信息，以便 Agent 确定场景分流和验证方式：

- 目标文件/片段的工程内路径，或直接粘贴 ArkTS 代码片段。
- 问题描述与目标交互：现象（如翻页卡顿、首帧慢、滑动掉帧）、触发动作和已有证据。
- 提供工程路径时，Skill 会以只读方式读取 `build-profile.json5`，确认 API 版本；仅提供片段时建议补充最低/目标 API 版本。
- 需要实测效果时说明可用的采集条件；Skill 指导开发者执行采集，不代替执行。

### 加载 Skill

在支持 Agent Skills 的助手中，引用 Skill 根目录的 [SKILL.md](../SKILL.md)，并保留完整目录，以便根据场景路由结果，按需读取 `references/` 下的详细规则。

### 提示词示例

**组件诊断：**

```text
使用 hmos-arkui-performance-analysis Skill，只读分析以下代码的组件性能风险，给出修改建议。
（粘贴代码片段）
```

**转场性能诊断模板：**

```text
使用 hmos-arkui-performance-analysis Skill，只读分析以下转场性能风险，
给出位置、原因、修改建议和验证方法，不修改代码。
条件：{动态/静态 ArkTS}、状态管理 {V1/V2}、API {版本}；
转场类型：{Swiper 翻页 / 页签切换 / 页面进入 / 返回 / replace / 前置页进入首页}，
{页面数量、数据源与缓存配置}；
现象：{如首次翻到相邻页不流畅、进入新页等待长、切换时集中构建}。
（粘贴代码片段）
```

**转场性能诊断样例：**

```text
使用 hmos-arkui-performance-analysis Skill，只读分析以下 Swiper 翻页转场的性能风险，
给出位置、原因、修改建议和验证方法，不修改代码。
条件：动态 ArkTS/V1、API 12；共有 10 页，loop=false，一屏显示 1 页，
LazyForEach 数据源完整，cachedCount(0)。
用户从第 0 页连续向后翻页，反馈首次翻到相邻页时不流畅；本次检查下一页的构建时机。
（粘贴代码片段）
```

## 目录与参考文档

```text
hmos-arkui-performance-analysis/
├── SKILL.md                 # 入口：场景路由、检查项与边界
├── assets/
│   └── README.md            # 使用说明和调用示例
├── references/
│   ├── report-contract.md   # 性能分析报告内容与交付要求
│   ├── verification.md      # 常用验证口径
│   ├── trace-guidance.md    # 按需读取的详细采集与观察指导
│   ├── component/           # 组件专项与复用、分帧、布局边界等共享机制规则
│   ├── scroll/              # 滑动专项规则
│   ├── startup/             # 启动专项规则
│   ├── animation/           # 动效专项规则与最小对照
│   └── transition/          # 转场专项规则（Swiper 预加载）
└── test-cases/              # 维护材料，不作为诊断知识加载
```

| 参考文档 | 何时阅读 |
| --- | --- |
| [场景与机制路由](../SKILL.md#机制路由) | 按当前代码和现象选择机制，入口表链接详细规则 |
| [性能分析报告与交付](../references/report-contract.md) | 核对七项报告内容及交付方式 |
| [常用验证](../references/verification.md) | 生成当前建议的日志、打点与比较口径 |
| [Trace 指导](../references/trace-guidance.md) | 按当前验证目标查阅工具与事件说明 |
| [组件与共享机制规则](../references/component/reuse-and-keys.md)（`references/component/`） | 组件场景；或滑动/转场命中复用、分帧、布局边界等共享机制 |
| [滑动专项规则](../references/scroll/component-reuse.md)（`references/scroll/`） | 滑动场景 |
| [启动专项规则](../references/startup/list-creation.md)（`references/startup/`） | 启动场景；或转场命中生命周期、分阶段展示、提前构建等共享规则 |
| [动效专项规则](../references/animation/animateTo-patterns.md)（`references/animation/`） | 动效场景 |
| [Swiper 预加载](../references/transition/swiper-preload.md) | Swiper 翻页或页签切换转场 |

## 验证与交付

- 诊断报告只基于读到的代码事实与成立条件，不将未经实测的分析结论表述为实测耗时或收益；未解释的问题只说明相关代码范围和剩余疑点，不强行归因于 ArkUI。
- 验证方法按目标选择日志、计数、视觉观察或Trace，说明动作、观察对象、比较条件与预期；口径见[常用验证](../references/verification.md)。
- 同一代码位置、触发条件和根因只报告一次；不同场景共用机制规则时不重复报告。
- 回归与验收材料见 [test-cases/](../test-cases/README.md)：[trigger.md](../test-cases/trigger.md)（3 例）与 [functional.md](../test-cases/functional.md)（46 例，默认执行，按 component/scroll/startup/animation/transition 标注类别），用例与规格对应见 test-cases/README.md。可运行工程与 with/without 评测流程在仓外维护；历史模型行为对比评测覆盖 18 个场景（with-skill 全部通过、without-skill 11/18），不代表当前全部用例已执行。
