# 测试用例

本技能的用例维护在以下三个文件中，流水线与人工验证共用同一份输入和预期：

| 文件 | 用途 | 用例数 |
|---|---|---|
| [trigger.md](trigger.md) | 触发验证：命令式节点诉求应触发，非命令式节点诉求不触发 | 3 |
| [smoke.md](smoke.md) | 路由验证：开发者描述需求特征，Skill 应路由到正确的 API（BuilderNode/FrameNode/RenderNode） | 2 |
| [functional.md](functional.md) | 功能验证：骨架生成、代码排障、池管理、预创建场景与文件输入异常处理 | 18 |

功能用例按类别覆盖骨架生成 3 例（BuilderNode/FrameNode/RenderNode 各一条，验证创建、build、挂载、NodeContainer 占位、dispose 释放四结构完整性）、排障 11 例（dispose 内存未释放、节点双挂不显示、@Reusable/@ReusableV2 冲突 JSCrash、aboutToDisappear 不触发、冻结态 update 不生效、@Builder 内 Repeat 编译错误、JSON 序列化循环引用 JSCrash、复用事件 reuse/recycle 传递、@Link 状态同步失败、@Consume/@Provide 跨边界隔断）、池管理 1 例（NodePool + NodeItem 架架、动态转移）、预创建场景 1 例（BuilderNode 预创建 + NodeContainer 挂载）、文件输入异常处理 2 例（文件路径不存在、文件不含 ArkUI 组件）。

排障用例区分 bench 与 functional 两种类型：FUNC-13~FUNC-19 为 bench（代码分析型，提供完整可编译代码片段），FUNC-22~FUNC-28 为 functional（功能验证型，聚焦单项反模式识别）。两类用例的验证标准一致，均要求识别问题根因并给出唯一明确的修复方向；对修复方向唯一且明确的用例（FUNC-22、FUNC-23），额外要求"不应建议任何其他修改"，避免过度报告。

## 格式与维护

按 hmos-skill-test-runner 的约定，`test-cases/` 必须保留在技能根层级。每条用例以 `### 测试用例：` 开头，用 `---` 分隔，包含 skill、类型、类别、输入与预期输出；功能用例逐项列出"验证标准"和"应包含"关键词，触发用例给出"应触发"，路由用例给出"应命中场景"。新增或修改场景直接更新对应文件，不另建提示词副本。

排障用例的业务场景与成立条件写在代码片段前的 `**业务场景与成立条件**` 段落中，为流水线判定提供语义上下文；代码片段须可独立编译，不依赖外部资源。骨架用例的输入描述需求特征与四结构要求，验证标准逐项核对创建、build、挂载、占位容器、dispose 五个核心结构。

## 执行与隔离

- 流水线每条用例独立启动被测模型，仅传入该条"输入"，对照"预期输出"逐项判定。运行包复制后移除 `test-cases/`，被测模型只读取隔离的 SKILL.md 与 references，避免接触参考答案。
- 人工验证也从上述文件提取"输入"，包含场景描述、业务条件与代码片段；"预期输出"由测试人员单独核对，不传给被测会话。
- with/without 两组使用独立会话，保持模型、输入、工具权限与采样配置一致；with 组加载 SKILL.md + references，without 组不加载，不额外提示答案。
- 有发现时只报告相关问题、建议与验证，不输出逐类或合并的未命中清单；无明确发现时简短说明已读范围和限制。

## 工程与资源条件

用例是模型诊断输入，包含页面或必要的类与调用片段，不作为已编译应用工程。需要实际运行时，按每条用例声明的 API 版本与业务前提补齐工程；页面放入 `entry/src/main/ets/pages/` 并在 `main_pages.json` 注册后实际构建与回归。

- BuilderNode/FrameNode/RenderNode 基础 API 要求 API 12+，所有骨架用例与多数排障用例适用此版本。
- `FUNC-27`（@Consume/@Provide 跨边界）涉及 API 20 引入的 `BuildOptions.enableProvideConsumeCrossing` 配置项；`FUNC-28`（@ReusableV2）涉及 API 26 的 V2 组件复用支持，实测直接子组件仍 JSCrash。
- 排障用例的代码片段使用 `@kit.ArkUI` 导入 BuilderNode/FrameNode/NodeController/UIContext，需在 OpenHarmony 工程中配置对应 SDK。

本仓不归档应用工程、构建记录或设备实测结果，不宣称这些输入已构建或已有功能验证结果。
