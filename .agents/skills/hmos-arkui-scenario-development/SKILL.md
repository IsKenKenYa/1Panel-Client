---
name: hmos-arkui-scenario-development
description: HarmonyOS/鸿蒙 ArkUI 场景化开发技能，用于实现、排查或验证 ArkUI(.ets) 功能，并按需求(REQ)/开发(DEV)/修复(FIX)/验证(VAL)四阶段路由到4个一级场景：ARKUI-01 ArkUI基础语法（声明式UI、条件渲染、自定义组件、Builder/BuilderParam、AttributeModifier、组件复用）;ARKUI-02 基于UI框架构建基础代码逻辑（手势/键盘交互、路由导航、组件页面、弹窗菜单、动画转场、焦点走焦、综合应用页面骨架、自定义组件FrameNode/Modifier、弹窗进阶、布局组件、图形图像、滚动列表、文本组件）;ARKUI-03 状态管理（组件状态同步，V1/V2使用、V1/V2混用、状态变量相关扩展能力）;ARKUI-04 编译与运行时（编译构建失败、ANR、AppFreeze异常卡死、白屏、崩溃闪退，长列表卡顿丢帧、不跟手、资源加载慢等问题）。不适用：与 ArkUI 无关的原生开发、非 HarmonyOS 平台、CI/CD。
metadata:
  version: 1.0.0
  keywords:
    - ArkUI
    - HarmonyOS
    - 鸿蒙
    - ArkTS
    - ".ets"
    - 声明式UI
    - 场景化开发
    - REQ
    - DEV
    - FIX
    - VAL
    - 条件渲染
    - 状态管理V1版本
    - 状态管理V2版本
    - 组件间状态同步
    - "@State"
    - "@Link"
    - "@Local"
    - "@Param"
    - "@Monitor"
    - "@Watch"
    - 状态管理V1V2混用
    - 显隐切换
    - 展开收起
    - 自定义组件
    - "@Builder"
    - "@BuilderParam"
    - AttributeModifier
    - "@Reusable"
    - LazyForEach
    - Repeat
    - 组件复用
    - 手势
    - 手势冲突
    - 嵌套滚动
    - 拖拽
    - 捏合缩放
    - PanGesture
    - PinchGesture
    - responseRegion
    - hitTestBehavior
    - 状态管理
    - 组件状态同步
    - "@State"
    - "@Link"
    - "@Local"
    - "@Param"
    - "@Monitor"
    - "@Computed"
    - V1V2混用
    - 路由导航
    - 页面跳转
    - Navigation
    - NavDestination
    - 路由拦截
    - 分栏
    - 编译错误
    - 构建失败
    - 运行时异常
    - 闪退
    - 白屏
    - ArkTS限制
    - 页面搭建
    - Column
    - Tabs
    - WaterFlow
    - 弹窗
    - bindSheet
    - CustomDialog
    - Toast
    - 半模态
    - 动画
    - 转场
    - animateTo
    - TransitionEffect
    - geometryTransition
    - 共享元素动画
    - 帧动画
    - 焦点
    - 走焦
    - focusable
    - requestFocus
    - focusBox
    - nextFocus
    - 循环走焦
    - 垂类App骨架
    - 响应式布局
    - 断点响应
    - 地图导航
    - FrameNode
    - DrawModifier
    - ContentModifier
    - BuilderNode
    - XComponent
    - 自定义绘制
    - 弹窗进阶
    - levelOrder
    - ComponentContent
    - 布局选型
    - RelativeContainer
    - GridRow
    - 图片展示
    - ImageAnimator
    - 序列帧
    - 滚动列表
    - 瀑布流
    - ArcList
    - 分组吸顶
    - 九宫格
    - 富文本
    - 图文混排
    - RichEditor
    - SymbolGlyph
---

# ArkUI 场景化开发

## 技能定义

| 字段 | 内容 |
| --- | --- |
| `skill_id` | `arkui-scenario-development` |
| `skill_name` | `ArkUI场景化开发` |
| `one_line_purpose` | 覆盖ArkUI基础语法、基于UI框架构建基础代码逻辑、状态管理、编译与运行时四个一级场景，并通过 ROUTE 文档承接交互、焦点、路由导航、组件页面、状态变量V1和V2版本使用，组件状态同步，弹窗菜单、动画转场、综合骨架、自定义组件、布局、图像、滚动列表、文本等二级能力。 |
| `not_in_scope` | `与ArkUI无关的原生开发、非HarmonyOS平台开发、CI/CD流水线配置` |
| `primary_outputs` | `primary_scene`、`implementation_notes`、`code_touchpoints`、`verification_matrix` |

## 核心约束

- 本技能只处理 ArkUI / ArkTS `.ets` 页面、组件、交互、状态、路由、弹窗、动画、布局、图像、列表、文本、编译与运行时相关任务。
- 本技能不处理与 ArkUI 无关的原生系统能力、后端接口、数据库、CI/CD、工程发布流程或非 HarmonyOS 平台开发；若任务只涉及这些内容，应判定为 `not_in_scope`。
- 命中 `ARKUI-02` 或 `ARKUI-03` 时，必须继续读取对应 ROUTE 文档完成二级路由；同一问题命中多个二级子场景时，必须全部记录并读取对应叶子资源。
- 输出方案或代码前，必须先给出路由结果、阶段判断、命中场景和将读取的资源路径；不得跳过路由直接给出实现。
- 生成方案或代码时，应基于已命中的资源文档提取 API、组件结构、回调、生命周期和验证重点；资源未覆盖的边界必须显式说明。

## 执行步骤（严格按序，不可跳过）

每次命中 ArkUI 场景时，必须严格按以下步骤执行。不允许跳过任何步骤直接写代码。

### Step 1: 路由判断

根据用户请求，按场景决策树完成以下判定并**输出路由结果**：

```
active_phases: [REQ / DEV / FIX / VAL]
primary_phase: 主阶段
primary_scene: 主场景 ID（如 ARKUI-02）
secondary_scenes: [关联场景 ID 列表]（如 [ARKUI-01, ARKUI-03]）
route_reason: 路由依据简述
next_scene_refs: 需要读取的资源文件路径列表（主场景 + 所有关联场景）
```

**关键规则**：
- `secondary_scenes` 中每个场景对应的 `resource_refs` 都必须纳入 `next_scene_refs`，不得遗漏。
- 一级资源路径通过"场景索引"中命中场景的 `resource_refs` 字段查找。
- 二级 ROUTE 文档中的资源路径通过命中"场景索引"场景块内的 `resource_ref` / `resource_refs` / `resource_files` 查找。

### Step 2: 读取所有场景参考文档

**必须使用 Read 工具逐个读取 `next_scene_refs` 中的每个文件**。不允许凭经验猜测文件内容。

读取顺序：
1. **主场景参考文档** — `primary_scene` 对应的 `resource_refs`
2. **关联场景参考文档** — `secondary_scenes` 中每个场景对应的 `resource_refs`
3. **级联路由文档** — 如果读取的参考文档本身是路由入口文件（如 `ROUTE.md`），必须按其"场景索引"命中场景中的 `resource_ref` / `resource_refs` / `resource_files` 继续读取，直到所有叶子文档都被读取

**禁止行为**：
- 禁止跳过任何已命中的 `resource_refs` 不读
- 禁止看到文件名就假设其内容为空
- 禁止用经验知识替代文档中的具体 API 用法和参数

### Step 3: 输出路由确认

在读取完所有文档后、开始实现之前，向用户输出确认信息：

```
## 路由确认

**路由结果**：
- primary_phase: ...
- primary_scene: ...
- secondary_scenes: [...]

**已读取文档列表**：
1. [文件路径] — [一句话概述内容]
2. [文件路径] — [一句话概述内容]
...

**实现方案要点**（基于文档内容）：
- ...（从文档中提取的关键 API、模式、约束）
```

### Step 4: 进入实现

基于已读取的场景文件和参考文档中的约束、API 用法、配置格式进行实现。

**必须遵守**：
- 采用文档中的 API 调用模式，不得替换为未在文档中出现的方式
- 文档中提供了完整代码案例时，以该案例为骨架进行适配，不得从零重写
- 如果文档中有多个场景案例，选择与用户需求最匹配的那一个

## 阶段标签

| 标签 | 阶段 | 当前模块关注点 |
| --- | --- | --- |
| `REQ` | 需求分析设计 | 场景识别、交互设计、状态管理方案选型、动画方案选型、页面流设计 |
| `DEV` | 开发 | ArkUI代码实现、组件使用、状态管理、手势事件处理、动画API调用、路由配置 |
| `FIX` | 问题修复 | 编译错误、运行时异常、动画不生效、状态不同步、路由跳转异常、交互事件失效 |
| `VAL` | 功能验证 | UI渲染验证、交互事件验证、状态管理验证、动画效果验证、页面流转验证 |

## 统一输出字段

- `REQ`：`device_constraints`、`capability_boundary`、`acceptance_focus`
- `DEV`：`code_touchpoints`、`reuse_resources`、`implementation_notes`、`integration_risks`
- `FIX`：`problem_profile`、`root_cause_hypothesis`、`fix_plan`、`regression_watchlist`
- `VAL`：`verification_matrix`、`evidence_requirements`、`pass_criteria`、`residual_risks`

## 字段释义

- `device_constraints`：指由设备类型、屏幕尺寸、系统版本等带来的适配约束。
- `capability_boundary`：指当前方案在哪些API版本、设备类型或系统状态下有效，哪些场景需要回退或额外处理。
- `acceptance_focus`：指需求阶段验收时必须重点确认的UI表现、交互行为和动画效果。
- 统一输出字段中每个阶段列出的字段表示"命中对应场景后，该阶段必须输出这些字段"，由阶段决定输出内容，不再由场景单独定义。

## 场景决策树

```
用户提出ArkUI开发相关问题
│
├── Step 1: 阶段判断（primary_phase）
│   │
│   │  判断原则: 用户是否在描述已有代码/页面上出现的不正确结果
│   │
│   ├── FIX: 满足以下任一条件
│   │   ├── 用户描述了已有实现运行后的异常结果
│   │   │   强信号: "不生效"、"报错"、"崩溃"、"闪退"、"白屏"、"动画不播放"
│   │   │   中信号: "状态不同步"、"路由失败"、"手势无响应"、"弹窗不显示"
│   │   ├── 用户明确要求排查/修复已有问题
│   │   │   关键词: "排查原因"、"修复"、"为什么不生效"、"请排查"
│   │   └── prompt 同时包含 API/代码片段 + 异常结果（双重确认）
│   │
│   ├── DEV: 描述全新功能需求，无已有异常
│   │   关键词: "需要实现"、"请给出开发方案"、"请给出完整方案"、"帮我实现"
│   │   注意: "不能被遮挡"（设计约束）≠ "被遮挡"（已有问题）
│   │
│   └── REQ: 描述需求并要求分析/评估
│       关键词: "请给出需求分析"、"请分析"、"评估"、"方案选型"
│
└── Step 2: 一级场景字段化决策（multi-label）
    │   不在决策树中维护场景描述；所有具体场景描述以下方"场景索引"为准。
    │   对场景索引中的全部一级场景做并行匹配，可同时命中多个场景。
    │
    ├── 2.1 关键词粗筛
    │   ├── 先用 metadata.keywords 判断是否属于 ArkUI 技能范围
    │   ├── 再用每个场景块的 intent_signals 匹配用户提示词、代码、报错、截图和上下文
    │   └── API 名、装饰器、组件名、报错现象等强信号优先于泛化词；泛化词只作为辅助证据
    │
    ├── 2.2 适用边界校准
    │   ├── 对候选场景逐条检查 applies_when，确认该场景是否覆盖用户真实诉求
    │   ├── 对候选场景逐条检查 not_applies_when，发现排除条件时转向对应场景或降级为 secondary_scenes
    │   └── 仅命中 intent_signals 但无法满足 applies_when 的场景，不得作为 primary_scene
    │
    ├── 2.3 主辅场景排序
    │   ├── primary_scene：同时满足强关键词、applies_when 和当前 primary_phase 的核心场景
    │   ├── secondary_scenes：与主诉求存在依赖、联动、排查前置或验证补充关系的场景
    │   └── 场景之间不互斥；多个 applies_when 同时成立时全部保留，并在 route_reason 说明关系
    │
    ├── 2.4 阶段动作决策
    │   ├── 根据 primary_phase 读取命中场景 decisions 下对应的 REQ / DEV / FIX / VAL 条目
    │   ├── REQ 用于明确需求边界和验收重点；DEV 用于确定实现路径和代码骨架
    │   ├── FIX 用于定位异常检查点和回归关注项；VAL 用于生成验证矩阵和证据要求
    │   └── 当 decisions 与用户诉求不完全匹配时，保留已命中场景并显式说明资源未覆盖边界
    │
    └── 2.5 资源读取决策
        ├── 将 primary_scene 和 secondary_scenes 中的 resource_refs 全部写入 next_scene_refs
        ├── 如果 resource_refs 指向 ROUTE 文档，继续按该 ROUTE 的字段化决策树命中二级场景
        └── matched_scenes 为空时判定 not_in_scope；不得跳过字段判断直接实现
```

## 场景索引

#### `ARKUI-01` ArkUI基础语法

```yaml
scene_id: ARKUI-01
scene_name: ArkUI基础语法
resource_refs:
  - ./references/arkui-basic/ROUTE.md
intent_signals:
  - 声明式UI / 条件渲染 / 显隐切换 / 展开收起
  - 自定义组件 / @Component / @ComponentV2 / @Builder / @LocalBuilder / @BuilderParam
  - AttributeModifier / @Reusable / @ReusableV2 / LazyForEach / Repeat / virtualScroll / UI插槽 / 样式复用 / 组件复用
applies_when:
  - 需要了解 ArkUI 声明式开发范式、组件定义、build()、装饰器与基础语法
  - 涉及 if 条件渲染、动态显隐、展开/收起、登录态切换等基础渲染逻辑
  - 涉及 @Builder、@BuilderParam、@LocalBuilder、AttributeModifier 等基础复用和样式抽取能力
  - 涉及 @Reusable / @ReusableV2、LazyForEach / Repeat、reuseId / reuse 等基础复用能力
not_applies_when:
  - 核心需求是页面结构、布局、路由、交互、弹窗、动画、图像、列表或文本组件（属于ARKUI-02）
  - 核心需求是状态传递、状态同步、状态监听或 V1/V2 混用（属于ARKUI-03）
  - 核心需求是编译错误、运行时异常、白屏、闪退或 SDK 兼容（属于ARKUI-04）
decisions:
  REQ:
    - 确定基础语法类型：声明式组件 / 条件渲染 / Builder 插槽 / AttributeModifier / 复用能力
    - 确定组件装饰器版本、复用边界、插槽兜底策略和是否涉及条件挂载/卸载
  DEV:
    - 按资源文档实现组件骨架、Builder/BuilderParam、AttributeModifier、条件渲染和复用声明
    - 对复用类需求继续读取 arkui-basic ROUTE 指向的基础 UI / 扩展 / 复用文档
  FIX:
    - 检查装饰器版本、Builder 声明位置、BuilderParam 类型签名、AttributeModifier 泛型和复用池分组
    - 检查 if 条件渲染、展开收起、LazyForEach/Repeat 刷新与复用状态是否一致
  VAL:
    - 验证基础渲染、插槽覆盖、样式复用、组件复用、滚动复用和动态显隐切换效果
```

#### `ARKUI-02` 基于UI框架构建基础代码逻辑

```yaml
scene_id: ARKUI-02
scene_name: 基于UI框架构建基础代码逻辑
resource_refs:
  - ./references/arkui-02-route.md
intent_signals:
  - 手势 / 键盘 / 触摸 / 手写笔交互 / 焦点 / focusable / requestFocus / nextFocus / 焦点框
  - 路由导航 / Navigation / Router / 页面栈 / 弹窗 / 菜单 / Toast / Popup / Sheet / Dialog / 动画 / 转场 / animateTo / TransitionEffect / geometryTransition
  - Column / Row / Stack / Flex / RelativeContainer / GridRow / Tabs / List / Grid / WaterFlow / ArcList / Scroll / Swiper / 综合应用页面骨架 / 响应式布局 / 断点适配 / FrameNode / Modifier / RenderNode / BuilderNode / XComponent / Image / ImageAnimator / Text / TextInput / RichEditor / SymbolGlyph
applies_when:
  - 需要基于 ArkUI 组件和 UI 框架能力搭建页面、操作流、交互、临时界面或动效
  - 需要处理路由导航、手势事件、焦点走焦、弹窗菜单、动画转场等页面行为
  - 需要选型或实现布局、图像、滚动列表、文本组件、自定义节点或综合页面骨架
  - 需要从 UI 框架能力角度组织 ArkTS 页面代码逻辑，并读取二级 ROUTE 定位具体资源
not_applies_when:
  - 只是在确认 ArkUI 基础语法、条件渲染、Builder 或复用基础概念（属于ARKUI-01）
  - 主要问题是状态管理装饰器、状态同步或 V1/V2 混用（属于ARKUI-03）
  - 主要问题是编译/运行时错误而非 UI 逻辑选型或实现（属于ARKUI-04）
decisions:
  REQ:
    - 先读取 ./references/arkui-02-route.md，确定命中的二级子场景及其优先级
    - 明确页面结构、交互对象、导航关系、临时 UI、动效、焦点、布局、图像、列表或文本验收重点
  DEV:
    - 根据 ROUTE 命中的子场景读取全部叶子资源，采用其中的 API、组件结构、回调与代码骨架
    - 多个二级子场景并存时，先实现页面骨架和数据/路由关系，再接入交互、弹窗、焦点与动画
  FIX:
    - 先用 ROUTE 定位异常所属二级子场景，再检查对应 API 参数、生命周期、事件链路和资源约束
    - UI 行为互相影响时，将相关二级子场景全部列入 secondary_sub_scenes 并逐项回归
  VAL:
    - 按命中的二级子场景分别验证渲染、导航、交互、弹窗、动画、焦点、布局、图像、列表和文本表现
    - 验证多子场景联动时的边界行为、回退路径和设备差异
```

#### `ARKUI-03` 状态管理

```yaml
scene_id: ARKUI-03
scene_name: 状态管理
resource_refs:
  - ./references/arkui-03-route.md
intent_signals:
  - @State / @Prop / @Link / @Provide / @Consume / @Watch / @Track / @ObjectLink / @Observe /
  - @Local / @Param / @Event / @Monitor / @Provider / @Consumer / @Computed / @ObservedV2 / @Trace /
  - AppStorage / AppStorageV2 / 状态管理 / 组件状态同步 / 应用状态管理 / V1V2混用
applies_when:
  - 需要在组件间传递和共享状态数据
  - 需要使用V1状态管理（@State/@Prop/@Link/@Provide/@Consume/@Watch等）
  - 需要使用V2状态管理（@Local/@Param/@Event/@Monitor/@Computed等）
  - 需要监听状态变化并执行回调
  - 需要增强状态管理能力，将不可观测数据变为可观测数据，或进行同步刷新
  - 需要使用双向绑定语法糖
  - 需要使用animateTo实现属性动画
  - 需要实现组件复用
  - 需要实现组件冻结
  - 需要实现循环渲染
  - 状态管理V1V2版本混用
  - V1中使用V2的自定义组件
  - V2中使用V1的自定义组件
not_applies_when:
  - 只是组件布局、路由导航、交互、弹窗、动画、焦点、图像、列表或文本 UI 逻辑（属于ARKUI-02）
  - 只是 ArkUI 基础语法、Builder、条件渲染或基础复用概念（属于ARKUI-01）
  - 主要表现为编译/运行时异常且根因尚未指向状态管理（可先命中ARKUI-04）
decisions:
  REQ:
    - 先读取 ./references/arkui-03-route.md，判断是基础 V1/V2 使用、混用，还是状态相关扩展能力
    - 明确状态来源、数据流向、同步边界、监听/计算需求、持久化需求和迁移范围
  DEV:
    - 按 ROUTE 命中的资源选择 V1/V2 装饰器、组件间传值、跨层级共享、应用级状态或混用桥接方案
    - 避免在同一组件内无依据地混用 V1/V2 装饰器；混用需求必须有明确的用户要求，禁止自我决策使用混用方案
  FIX:
    - 检查装饰器版本、状态变量可观测性、父子/跨层级传递链路、监听清理和状态刷新时机
    - 混用场景重点检查跨版本数据桥接、双重代理、组件边界
  VAL:
    - 验证父子同步、跨层级同步、监听回调、计算属性、持久化恢复、混用桥接前后行为一致性
```

#### `ARKUI-04` 编译与运行时

```yaml
scene_id: ARKUI-04
scene_name: 编译与运行时
resource_refs:
  - ./references/compilation-runtime-scenario-development.md
intent_signals:
  - 编译错误 / 构建失败 / ArkTS类型错误 / import / export / 模块路径
  - 运行时异常 / 白屏 / 闪退 / 崩溃 / 生命周期异常 / 资源加载失败
  - hvigor / oh-package.json5 / module.json5 / SDK版本兼容 / API版本兼容
applies_when:
  - 需要排查 ArkTS 编译错误、构建失败、依赖配置、模块配置或 SDK/API 兼容问题
  - 需要排查页面运行时异常、白屏、闪退、崩溃、生命周期异常或资源加载失败
  - 需要确认某个 ArkUI 写法是否受语言规则、编译规则、运行时限制或版本边界影响
not_applies_when:
  - 已明确是 UI 页面逻辑、交互、路由、弹窗、动画、焦点、布局、图像、列表或文本实现问题（属于ARKUI-02）
  - 已明确是状态装饰器、状态同步或 V1/V2 混用问题（属于ARKUI-03）
  - 只是 ArkUI 基础语法学习或基础复用能力确认（属于ARKUI-01）
decisions:
  REQ:
    - 确定问题属于编译期、构建期、启动期、页面运行期还是版本兼容边界
    - 明确目标 SDK/API、模块配置、依赖来源、复现入口和期望运行环境
  DEV:
    - 按编译与运行时参考文档检查 ArkTS 语法限制、模块配置、依赖声明、生命周期和资源引用
    - 对新实现预先规避高风险写法和版本不兼容 API
  FIX:
    - 收集错误码、堆栈、构建日志、白屏/闪退时机和最小复现路径，定位配置、语法、生命周期或资源根因
    - 如果根因落到 UI 或状态能力，补充命中 ARKUI-02 或 ARKUI-03 并读取对应资源
  VAL:
    - 验证构建通过、页面可启动、异常不再复现、日志无新增高风险错误，并覆盖相关版本/设备边界
```
