# ArkUI 命令式节点快速接入

`arkui-imperative-node` 是指导开发者快速接入 ArkUI 命令式节点（BuilderNode / FrameNode / RenderNode）的 Agent Skill。它按三级决策树路由——场景判断 → API 选型 → 骨架代码生成，并覆盖文件路径输入与上下文感知方案生成和常见问题排障五个能力。只读分析开发者提供的真实 ArkTS 代码或场景描述，输出场景判断结论、API 推荐与决策依据、最小可运行骨架代码或排障诊断与修复建议，不直接修改应用代码。

工作流程和约束以 [SKILL.md](../SKILL.md) 为准。

## 接入能力

### 工作过程

1. **收集输入与分流**：获取开发者的场景描述或代码。判断属于场景判断、API 选型、骨架生成、文件路径输入还是排障分支。若开发者提供了 `.ets` 文件路径，使用 Read 读取指定文件，分析组件上下文（组件类型、build 结构、已有节点树）。
2. **异常检查**：验证需求是否与命令式节点相关。不相关时提示"需求与命令式节点无关"，不臆造方案；输入不满足判定条件时请求补充（见"异常输入处理"）。
3. **读取详细规则**：必须用 Read 读取命中分支对应的 `references/` 详细规则文件，再核对成立条件；不得仅凭 SKILL.md 的一行摘要直接输出方案。
4. **输出方案**：根据分流结果输出场景判断结论+依据、API 选型推荐+决策依据、骨架代码（加载对应模板）、或排障方案+修复建议。生成代码后逐项核对自检规则清单（C-1~C-7、W-1~W-4），确保无反模式。

### 能处理的问题

| 能力 | 典型输入 | 能处理的问题 |
| --- | --- | --- |
| 场景判断 | "不确定是否需要命令式节点"、"运行时动态增删组件"、"提前预创建组件优化初始化耗时" | 判定是否建议使用命令式节点：动态挂载/预创建建议使用（BuilderNode）；build 内可用 ForEach/LazyForEach/if-else 满足时不建议使用 |
| API 选型 | "需要命令式节点，但不确定选 BuilderNode/FrameNode/RenderNode" | 按需求语义唯一路由：整体控制节点树+@Builder 声明式+状态管理 → BuilderNode；命令式控制内部树+自定义测量/布局/绘制 → FrameNode；仅渲染属性+自定义绘制+不参与布局和事件 → RenderNode |
| 骨架代码生成 | "已确定 API，生成接入代码"、"动态挂载声明式组件树"、"自定义绘制" | 加载对应模板生成骨架：包含创建、build/构造、挂载、NodeContainer 占位容器、dispose 释放四个核心结构；标注 API 版本（基础 API 12+）；自检反模式（@Reusable 冲突、build 前 getFrameNode、节点双挂、@Builder 内 Repeat、JSON 序列化等） |
| 文件路径输入与上下文感知 | "这是我的页面代码路径 `entry/.../xxx.ets`，帮我加命令式节点" | 读取代码文件，识别组件类型/build 结构/已有节点树，按 L2 选型输出修改后的完整代码，保留已有逻辑 |
| 常见问题排障 | "节点置空后内存没释放"、"BuilderNode 创建后不显示"、"与 @Reusable/@ReusableV2 联用 JSCrash"、"aboutToDisappear 没触发"、"冻结后 update 不更新"、"@Builder 内 Repeat 报错"、"JSON.stringify crash"、"复用事件不传递"、"@Link/@Consume 状态不更新" | 按 9 类排障检查项逐项分析：①@Reusable/@ReusableV2 冲突 ②节点不显示（双挂/build前getFrameNode/makeNode重复等）③dispose 释放 ④aboutToDisappear 不触发 ⑤冻结态 update 不生效 ⑥@Builder 内 Repeat ⑦JSON 序列化 ⑧reuse/recycle 复用事件未传递 ⑨@Link/@Consume 状态同步跨界 |

诊断覆盖状态管理 V1/V2 与 API 版本适用条件（BuilderNode/FrameNode/RenderNode 基础 API 12+，@ReusableV2 涉及 API 26、`BuildOptions.enableProvideConsumeCrossing` 涉及 API 20）。声明式 UI 全链路分析、声明式组件开发、完整业务逻辑实现不属于本 Skill 的处理范围；骨架代码为最小可运行模板，不含完整业务逻辑，开发者需按实际需求填充。

### 输出内容

每条方案包含以下信息，按问题规模合并表达，不机械分章节：

- **结论与依据**：场景判断或 API 选型的判断结论，附适用条件和选择理由，不仅给结论。
- **代码事实与成立条件**：引用实际代码与业务前提，推测内容单独标注，不编造 API 签名、版本号或行为事实。
- **骨架代码**：针对当前需求与 API 版本的骨架，含创建、build/构造、挂载、NodeContainer 占位容器、dispose 释放四结构，标注 API 版本要求。
- **反模式自检**：生成代码后逐项核对自检清单（C-1~C-7 Critical、W-1~W-4 Warning），违反时必须修复或建议修复。
- **排障诊断与修复建议**：问题原因分析（命中规则、因果链）和唯一明确的修复方向；对修复方向唯一且明确的问题，不额外建议其他修改，避免过度报告。
- **验证方法**：建议核对哪些点、执行什么动作、预期哪部分变化；尚未执行的验证明确标注。

## 快速开始

### 准备输入

使用前提供以下信息，以便 Agent 确定分流和验证方式：

- 场景描述或需求说明（如动态挂载组件、预创建组件、自定义绘制、节点不显示等）。
- 已确定 API 时直接说明，或描述需求维度：是否需要声明式构建内部树？是否需要自定义测量布局？是否仅需要渲染？
- 排障场景描述具体问题现象（如节点不显示、内存未释放、JSCrash 等），并粘贴相关代码片段。
- 提供工程内 `.ets` 文件路径时，Skill 会以只读方式读取并分析组件上下文；仅提供片段时建议补充最低 API 版本。

### 加载 Skill

在支持 Agent Skills 的助手中，引用 Skill 根目录的 [SKILL.md](../SKILL.md)，并保留完整目录，以便按分流结果读取 `references/` 下的详细规则与 `templates/` 下的骨架模板。

### 提示词示例

**场景判断：**

```text
使用 arkui-imperative-node Skill，判断以下需求是否需要使用命令式节点，给出结论和依据。
需求：运行时根据业务动态增删组件，需灵活挂载到不同父节点。
```

**API 选型：**

```text
使用 arkui-imperative-node Skill，推荐适合的命令式节点 API，给出决策依据。
需求：需要命令式控制内部节点树，并自定义测量/布局/绘制；不涉及声明式状态管理。
```

**骨架代码生成：**

```text
使用 arkui-imperative-node Skill，生成 BuilderNode 接入骨架代码。
需求：动态挂载声明式组件树，含创建、build、挂载、NodeContainer 占位、dispose 释放。
条件：API 12，状态管理 V1。
```

**文件路径输入与上下文感知：**

```text
使用 arkui-imperative-node Skill，读取以下文件并添加 BuilderNode 动态挂载，输出修改后的完整代码。
文件路径：entry/src/main/ets/pages/Index.ets
保留已有页面结构，新增 Dispose 按钮释放节点。
```

**排障：**

```text
使用 arkui-imperative-node Skill，只读分析以下代码，节点不显示的原因和修复建议，不修改代码。
现象：BuilderNode 创建后挂载到父节点，页面不显示。
（粘贴代码片段）
```

## 目录与参考文档

```text
arkui-imperative-node/
├── SKILL.md                              # 入口：决策树、API 选型速查、反模式、自检规则、排障检查项
├── assets/
│   └── README.md                         # 使用说明和调用示例
├── references/
│   ├── scene-judgment.md                 # 场景判断规则（R-1~R-3）
│   ├── api-selection.md                  # API 选型决策矩阵（R-4~R-6）
│   ├── builder-node-guide.md             # BuilderNode 使用指导（R-7）
│   ├── frame-node-guide.md               # FrameNode 使用指导（R-8）
│   ├── render-node-guide.md              # RenderNode 使用指导（R-9）
│   ├── builder-node-pool-guide.md        # 多节点池管理（NodePool+NodeItem）（R-10）
│   ├── code-context-analysis.md          # 文件路径输入与组件上下文分析规则
│   └── troubleshooting/
│       ├── reusable-conflict.md          # @Reusable/@ReusableV2 冲突排障
│       ├── node-not-display.md           # 节点不显示排障（双挂/build前getFrameNode等）
│       ├── dispose-memory.md             # dispose 释放排障
│       ├── about-to-disappear.md         # aboutToDisappear 不触发排障
│       ├── freeze-update.md              # 冻结态 update 不生效排障
│       ├── repeat-in-builder.md          # @Builder 内 Repeat 排障
│       ├── json-serialize-crash.md       # JSON 序列化 JSCrash 排障
│       ├── reuse-recycle-transfer.md     # reuse/recycle 复用事件未传递排障
│       └── state-sync-crossing.md        # @Link/@Consume 状态同步跨界排障
├── templates/
│   ├── builder-node-template.ets         # BuilderNode 骨架代码模板
│   ├── frame-node-template.ets           # FrameNode 骨架代码模板
│   └── render-node-template.ets          # RenderNode 骨架代码模板
└── test-cases/                           # 维护材料，不作为接入知识加载
```

| 参考文档 | 何时阅读 |
| --- | --- |
| [场景分流决策树](../SKILL.md#场景分流决策树) / [API 选型速查](../SKILL.md#api-选型速查) / [反模式警告](../SKILL.md#反模式警告buildernode-子节点禁止使用-reusable) | 入口决策与生成代码前的强制检查项 |
| [场景判断规则](../references/scene-judgment.md) | 不确定是否需要命令式节点时核对建议/不建议使用条件 |
| [API 选型决策矩阵](../references/api-selection.md) | 需求不明确、需辅助判断选哪个 API 时 |
| [BuilderNode 指导](../references/builder-node-guide.md) | 选定 BuilderNode 后核对创建/build/挂载/dispose 用法 |
| [FrameNode 指导](../references/frame-node-guide.md) | 选定 FrameNode 后核对创建/挂载/getRenderNode/dispose 用法 |
| [RenderNode 指导](../references/render-node-guide.md) | 选定 RenderNode 后核对创建/挂载/draw/dispose 用法 |
| [池管理指导](../references/builder-node-pool-guide.md) | 管理多个 BuilderNode 动态挂载/卸载/转移时 |
| [代码上下文分析规则](../references/code-context-analysis.md) | 开发者提供文件路径，需分析组件上下文输出完整代码时 |
| [dispose 排障](../references/troubleshooting/dispose-memory.md) | 节点置空后内存未释放 |
| [节点不显示排障](../references/troubleshooting/node-not-display.md) | 节点挂载后不显示（双挂、build前getFrameNode 等） |
| [@Reusable/@ReusableV2 排障](../references/troubleshooting/reusable-conflict.md) | BuilderNode 与 @Reusable/@ReusableV2 联用 JSCrash |
| [aboutToDisappear 排障](../references/troubleshooting/about-to-disappear.md) | 依赖 aboutToDisappear 做清理但未触发 |
| [冻结 update 排障](../references/troubleshooting/freeze-update.md) | 冻结态调用 update 不生效 |
| [@Builder 内 Repeat 排障](../references/troubleshooting/repeat-in-builder.md) | @Builder 内直接使用 Repeat 导致运行时 crash |
| [JSON 序列化排障](../references/troubleshooting/json-serialize-crash.md) | BuilderNode 对象 JSON.stringify 导致 JSCrash |
| [reuse/recycle 排障](../references/troubleshooting/reuse-recycle-transfer.md) | 复用事件未传递到 BuilderNode 内部 |
| [状态同步跨界排障](../references/troubleshooting/state-sync-crossing.md) | @Link/@Consume 跨 BuilderNode 状态不更新 |
| [BuilderNode 模板](../templates/builder-node-template.ets) / [FrameNode 模板](../templates/frame-node-template.ets) / [RenderNode 模板](../templates/render-node-template.ets) | 生成对应 API 的骨架代码时加载 |

## 验证与交付

- 方案只基于读到的代码事实与成立条件，不编造 API 签名、版本号或行为事实；API 事实以 OpenHarmony SDK 发布声明为准，未知条件明确标记。
- 骨架代码为最小可运行模板，包含创建、build/构造、挂载、NodeContainer 占位容器、dispose 释放四个核心结构，并标注 API 版本要求（基础 API 12+）；开发者需按实际需求填充业务逻辑。
- 生成代码后必须逐项核对自检规则清单：Critical（C-1~C-7，违反会导致编译错误或 JSCrash，必须修复）与 Warning（W-1~W-4，违反会导致功能异常，建议修复）；核对通过后不再追加防御性建议。
- 排障输出只报告命中的问题、原因与修复建议，不输出逐类或合并的未命中清单；代码已正确处理某项检查时确认正确性后不追加建议；同一根因只报告一次。
- 回归与验收材料见 [test-cases/](../test-cases/README.md)：[trigger.md](../test-cases/trigger.md)（3 例）、[smoke.md](../test-cases/smoke.md)（2 例）与 [functional.md](../test-cases/functional.md)（18 例，覆盖骨架生成、排障、池管理、预创建场景与文件输入异常处理）；流水线运行包复制后移除 `test-cases/`，被测模型只读取隔离的 SKILL.md 与 references，不接触参考答案。本仓不归档应用工程、构建记录或设备实测结果，不宣称这些输入已构建或已有功能验证结果。
