---
name: hmos-arkui-v1-v2-migration-and-mixusage
description: 分析并实施 ArkUI 状态管理 V1/V2 迁移或混用，覆盖整仓/组件迁移、V1/V2 共存、跨版本数据流、storage、渲染复用、依赖和构建验证。用于迁移规划与改造、混用方案设计、兼容边界实现或问题诊断；不用于普通的纯 V2 功能开发。
license: MIT
compatibility: 运行 scripts/inventory.mjs 需 Node.js 20+（仅使用 Node.js 内置模块，无需安装 npm 依赖或编译）
metadata:
  author: liwenzhen
  version: "1.0.0"
---

# ArkUI V1/V2 状态管理迁移和混用

先确认是整仓迁移还是指定组件迁移。整仓迁移以纯 V2 为目标；指定组件迁移时，检查与范围外 V1 代码的边界，存在边界才按混用处理。不要把所有 V1/V2 请求都默认成最终要消除 V1 的迁移任务；混用可以是受 API 版本、第三方依赖、发布节奏或架构边界约束下的目标状态。

先按任务主题读取本 Skill 对应的 reference。与工程目标及兼容 API 匹配的规则和已核实示例可以直接使用。只有具体签名缺口、版本冲突或相关编译错误才触发 SDK 查询；路径由用户提供，或由用户指定的工程/Bench 环境入口明确输出。只在该入口列出的声明目录内按具体符号查询，不自行搜索安装目录、上级目录或磁盘；同一缺口核实后不重复查询。没有明确路径或未找到声明时，查询匹配版本的官方文档。细节见 [official-doc-routing.md](references/official-doc-routing.md)。

只修改用户指定的范围，并明确记录保留的 V1/V2 连接。

修改组件字段前，先读 [component-and-data-migration.md](references/component-and-data-migration.md)。每个 `@Param` 都必须有本地默认值或同时声明 `@Require`，即使所有父组件已经传值也不能省略；`@Once` 不免除这条声明要求。保留原有合法默认值，无默认值且必须外部传入时用 `@Require @Param`。

迁移范围含 `animateTo` 时，修改前读 [animation-state-migration.md](references/animation-state-migration.md)。检查其回调中受影响的状态变量：如果在动画开始前修改了这些变量，API 22+ 将这些动画前的修改一起包进 `UIUtils.applySync`；API 12–21 使用全局 `animateToImmediately({ duration: 0 }, ...)`，然后再调用原动画。

本文中，“边界”指 V1 代码和 V2 代码直接交互的位置；“唯一数据源”指真正保存当前值、其他代码只读写它的那一份状态；“storage key”指 AppStorage/LocalStorage 中标识一项状态的键。

“数据类”指承载业务数据的 class 声明，“数据对象”指它的运行时实例；仅在明确采用视图状态或桥接投影结构时使用 ViewModel，不把所有数据类称为 ViewModel。

## 开始前：确认模式、范围和工程信息

1. 判断输入是可构建的 HarmonyOS/OpenHarmony 工程，还是独立代码片段。
2. 确认目标模式：完整V2迁移、部分V2组件迁移（混用）。
3. 找到工程根目录、目标和兼容 SDK/API 版本、模块、构建命令，以及当前 V1/V2 代码分布。对工程，在 Node.js 20+ 可用时运行 `node scripts/inventory.mjs <project-root>`，再回到源码确认关键结果；该脚本只是盘点工具，不是语法解析器或自动迁移器。
4. 如果工程可以构建，尽量先保存修改前的构建结果，用来区分原有错误和本次修改引入的错误。

确定“哪些代码必须一起改”之前，先读 [decision-and-impact-analysis.md](references/decision-and-impact-analysis.md)。

## 确认影响集合和混用边界

整仓迁移应覆盖范围内全部应用自有 ArkTS 源码和自有模块。不要因为迁移过程方便，就在最终结果中留下不必要的兼容包装。混用任务则要覆盖边界两侧的调用方、数据所有者和验证点，但不自动要求把它们都迁移到 V2。

组件级迁移只修改目标组件，以及保证它继续工作的最小范围联动代码。至少检查：

- 组件的所有创建位置、Builder、路由、弹窗/控制器和对外导出；
- 跨组件传递的输入、子组件向父组件的输出、写操作和数据类；
- 相同 alias 的 `@Provide`/`@Consume`；如果不能一起迁移，要明确建立边界适配器；
- 每个受影响 AppStorage/LocalStorage key 的所有读写，包括命令式 API 和解析后得到该 key 的常量；
- 相关的 `ForEach`/`LazyForEach`/`Repeat`、`@Reusable`、高级组件以及 HAR/HSP 导出。

不要把组件级迁移悄悄扩大为整仓迁移。如果联动代码明显超出原范围，先列出它们并征求是否扩大范围。同名 LocalStorage key 只有在同一个实例和组件树中才可能是同一状态，不能只凭字符串相同就合并。

## 选择迁移或混用方案

### 按代码证据读取迁移契约

修改代码或回答独立片段前，先读取本次输入涉及的 reference。下表用于选择路径和核对关键差异，完整约束、示例和版本以对应 reference 为准。

| 输入涉及的代码 | 修改前读取 | 必须保留的契约 |
| --- | --- | --- |
| V1/V2 复杂对象边界、保留的 V1 `@Link` | [interop.md](references/interop.md) | API 19+ 的 V1 对象在传入 V2 的创建点调用 `enableV2Compatibility`；V2 持有普通对象供 V1 `@ObjectLink` 使用时，采用 `enableV2Compatibility(makeV1Observed(value))` 的顺序。不把范围外普通类改为 `@ObservedV2`；保留的 V1 `@Link` 通过合法 V1 包装层接线。 |
| `ForEach` / `LazyForEach` | [rendering-reuse-and-advanced-components.md](references/rendering-reuse-and-advanced-components.md) | `ForEach` 迁为不调用 `virtualScroll` 的 Repeat；普通 `LazyForEach` 使用 `virtualScroll({ reusable: false })`；原有 item 复用路径使用默认复用的 `virtualScroll()`。`each` / `template` 接收 `RepeatItem<T>`；`key` / `templateId` 接收元素 `T`，两类回调不可混用。 |
| if/else 等独立组件复用 | [rendering-reuse-and-advanced-components.md](references/rendering-reuse-and-advanced-components.md) | V2 `aboutToReuse()` 无参数，`.reuseId(...)` 改为 `.reuse({ reuseId: () => ... })`；外部输入仍须建立 `@Param` 契约。 |
| 滚动内置对象、Modifier / AttributeUpdater | [component-and-data-migration.md](references/component-and-data-migration.md) | 按对象类型和目标 API 选择观察能力，保留原对象身份及原地修改；不能统一套用普通 class 的规则，或以每次重建对象代替观察。 |
| `@CustomDialog` / `CustomDialogController` | [component-and-data-migration.md](references/component-and-data-migration.md) | 迁为 `@Builder` 和 `PromptAction.openCustomDialog`，按内容实例或 id 配对关闭；不能按名字猜测 `CustomDialogV2` 等替代物。 |
| V1/V2 storage 共存、共享 key 切换 | [storage-and-application-state.md](references/storage-and-application-state.md) | 局部迁移保留唯一 V1 storage 所有者，V2 用 `@Param` / `@Event` 接线；整体迁移覆盖全部初始化和读写位置。同名 key 不会让两套存储互通。 |

- **整仓迁移：** 尽量得到纯 V2 结果。数据类及数据对象、组件 API、调用方、存储所有权、渲染逻辑和依赖要保持一致地迁移。只有确认没有 V1 使用方后，才删除 `makeV1Observed`/`enableV2Compatibility`。
- **组件级迁移：** 将目标组件改为 `@ComponentV2`，然后逐条检查输入和输出是 V1→V2 还是 V2→V1。使用适配器或目标 API 版本支持的兼容接口；V2 组件内部不能使用 V1 组件状态装饰器。
- **混用：** 明确边界、唯一数据源、允许的数据形态、读写方向、桥接所有者、API 版本约束和两侧测试。不要为了“纯 V2”扩大用户指定范围或提前改写范围外的 V1 代码。
- **V2 本地复杂对象：** `@Local` 不会让普通 class 的属性自动具备 V2 观察能力。数据类可以改为 `@ObservedV2`/`@Trace` 时，优先使用 `@ObservedV2`/`@Trace`；数据类不能改时（如 `@Sendable`），按 [interop.md](references/interop.md) 已列的 `UIUtils.makeObserved` 版本和对象支持范围处理。仅未覆盖的对象类型、版本冲突或相关编译错误才触发查询。`makeObserved` 是 V2 观察工具，不是 V1/V2 桥接工具，不要把它和 `makeV1Observed` 混淆。
- **Provide/Consume：** 能一起迁移时，保留原 alias 和跨层级共享通道，将同一 alias 连接的整组改为 `@Provider`/`@Consumer`。只有真实 V1/V2 边界或用户要求重设计时才改为显式参数链。不能一起迁移且 consumer 及完整创建链可修改时，删除相应 `@Consume`，逐层显式传值和回调；V2 节点使用 `@Param`/`@Event`，保留的 V1 节点使用 V1 合法输入和普通回调，不使用 V2 状态装饰器。仍需保留 V1 `@Consume` 或完整链不可改时，由唯一 V1 `@Provide` 所有者服务旧通道，必要时抽薄 V1 包装层，再以参数和回调连接 V2。
- **共享 storage key：** 要么迁移该 key 的全部使用位置，要么保留唯一的 V1 数据源并显式桥接。V1 AppStorage key 与 AppStorageV2 key 不会因为字符串相同而自动同步。

存在混用边界时读 [interop.md](references/interop.md)；涉及 storage 装饰器、storage API、Environment 或持久化时读 [storage-and-application-state.md](references/storage-and-application-state.md)。如果范围包含 ArkTS 卡片入口、`form_config.json`、`FormExtensionAbility`、`postCardAction`、卡片中的 `@Entry(storage)` 或 `@LocalStorageProp`，必须再读 [card-migration.md](references/card-migration.md)；卡片 V2 的 `updateForm` 接收机制不能直接套用普通页面的 LocalStorage 迁移规则。

## 按顺序修改

1. 先迁移或适配共享数据类及其继承链。
2. 修改目标组件的状态、公有契约和所有创建位置。对每个 `Child({ field: value })` 区分状态输入与事件回调：状态输入使用包含 `@Param` 的 V2 契约，不能声明成 `@Local`；修改请求回调使用 `@Event`。
3. 处理输出和双向数据流。V1 中可写的输入不能在 V2 中悄悄变成只读输入。
4. 处理对应的 Provider/Consumer 组和 storage key 使用集合。
5. 迁移渲染控制和复用，再处理高级 UI 组件的 V2 变体。`Repeat.each` 的回调参数是 `RepeatItem<T>`，取值用 `.item`；`Repeat.key` 的回调参数是元素 `T`，不要把两类回调参数互换。
6. 处理应用自有及外部 HAR/HSP 依赖。先核实实际公共导出再决定桥接；完整迁移且有适用 V2 导出时迁移调用契约，不能把归档不可修改或尚未核实当作仅有 V1。
7. 只有确认不再需要时，才删除旧 V1 import 和兼容调用。

装饰器和数据类规则见 [component-and-data-migration.md](references/component-and-data-migration.md)；卡片状态接收与跨组件共享见 [card-migration.md](references/card-migration.md)；`Repeat`、复用和系统预置 UI 组件见 [rendering-reuse-and-advanced-components.md](references/rendering-reuse-and-advanced-components.md)；HAR/HSP 与构建见 [dependencies-and-build.md](references/dependencies-and-build.md)。需要核对官方文档或 API 签名时，使用 [official-doc-routing.md](references/official-doc-routing.md)。

## 验证检查清单

宣布完成前：

- [ ] 重新运行盘点并检查 diff；
- [ ] 确认没有组件同时使用 V1 和 V2 的组件状态装饰器；
- [ ] 保留的 V1 桥接中，`@Watch('回调方法名')` 写在状态字段上，不能照搬方法上的 V2 `@Monitor('字段路径')`；验证桥接首次显示与两个方向的更新；
- [ ] 确认每个 V2 组件创建点传入的状态输入在子组件中声明为 `@Param`，每个无本地默认值的 `@Param` 都有 `@Require`，所有必填调用点都传值；只接收首次输入时再配合 `@Once`。修改请求回调声明为 `@Event`，没有用 `@Local` 接收外部传值；
- [ ] 确认每个被修改组件的调用点都符合 `@Param`/`@Event` 契约；
- [ ] 确认 Provider/Consumer alias 和 storage key 没有意外的双重所有者；
- [ ] 检查 `animateTo` 回调中受影响的状态变量，其动画前的修改是否全部包进对应版本的同步闭包，再调用原动画；
- [ ] 确认每条创建路径的实际复用机制：`Repeat(...).virtualScroll()` 未关闭复用时由 Repeat 管理 item 回收和复用，即使 item 组件带 `@ReusableV2`，该路径也不会调用组件自己的 `aboutToReuse()`；只有非 Repeat 创建路径才按独立 `@ReusableV2` 生命周期分析；
- [ ] 确认混用对象的观察与兼容顺序、Repeat 的加载/复用选择，以及内置对象的身份和原地修改符合上述已读契约；
- [ ] 自定义弹窗使用已核实的打开/关闭重载配对，没有凭后缀猜测 API；
- [ ] 搜索人工迁移标记、范围内意外残留的 V1 import、未解决的高级组件 import 和兼容接口；对明确保留的混用边界逐项核对其所有者和理由；
- [ ] 对真实工程，从工程根目录执行已识别的构建命令。修复迁移引入的错误，直到构建通过，或只剩明确的外部阻塞；
- [ ] 对独立代码片段，不虚构构建结果，只做有针对性的语法和语义检查。

## 迁移报告与交付

实际执行工程迁移或混用改造后，以本地 Markdown 报告作为正式交付物，再在对话中输出摘要和报告链接。任务部分完成或失败时，也要记录已完成的改动、当前状态和阻塞原因。仅做方案讨论、问题诊断或独立代码片段回答时，默认在对话中报告；用户要求落盘或指定交付方式时，按用户要求执行。

报告默认保存到被迁移工程根目录的 `reports/migrations/<任务标识>.md`。用户指定路径或工程已有报告目录约定时，优先遵循该约定。任务标识应能区分独立任务；同一任务续跑时更新原报告，不覆盖其他任务的报告。

报告应包含：

- **迁移结果：** 标明已完成、部分完成或失败，分别说明代码改造和验证的完成情况。要求执行的构建如果跳过或失败，不能称为“已完成验证”。
- **范围与改动：** 任务模式（迁移或混用）、目标及兼容 SDK/API 版本、涉及的模块、组件和联动文件，以及关键迁移前后映射与决策理由。
- **保留的边界：** V1/V2 连接及其所有者、storage key 及其所有权决定、依赖决定和保留理由；没有保留边界时明确说明。
- **验证结果：** 区分通过、失败和未执行的检查，记录实际执行的验证/构建命令、工作目录和结果摘要；失败或未执行时说明原因，已有日志或其他验证证据时提供路径。构建通过不能替代未执行的设备或交互验证。
- **依据与假设：** 记录实际使用的主题 reference；查询过 SDK 或官方文档时，按 [official-doc-routing.md](references/official-doc-routing.md) 记录路径来源、版本和核实内容，并列出仍未核实的假设。
- **遗留事项：** 尚未迁移的内容、风险、阻塞项和后续操作；没有遗留事项时明确说明。

写入后读取报告，确认内容与实际改动和验证结果一致。最终回复简要说明完成情况、关键变化、验证结论及需要关注的遗留问题，并提供可点击的报告文件链接，不重复粘贴全文。若报告文件写入失败，明确说明失败原因和报告尚未落盘，在对话中保留结果及阻塞信息，不能声称报告已生成。
