# 去哪里查官方文档

本 Skill 的主题 reference 是执行基线，应先按 `SKILL.md` 的路由读取。本文件只负责按需核对 SDK 和官方文档。`<DOCS_ROOT>` 只是“文档根目录”的占位符，不是使用这个 Skill 的前置条件。

## 调用契约覆盖与查询分工

按迁移范围及实际调用缺口选择资料，不以未经统计的“高频”选择接口。本 Skill 提供迁移所需的声明节选和最小示例，不是完整 SDK 手册。只读取当前场景的主题 reference，不为盘点所有 API 而加载全部 reference 或搜索全部 SDK。

| 场景/API | 调用契约所在 reference | 可以直接使用的范围 | 定向核对的缺口 |
| --- | --- | --- | --- |
| makeObserved / makeV1Observed / enableV2Compatibility | [interop.md](interop.md) | 导入、泛型/返回类型、已列对象支持范围与版本门槛 | 未列特殊对象/容器支持、版本冲突 |
| IMonitor.value 与值对 | [component-and-data-migration.md](component-and-data-migration.md) | dirty、可选 path、before/now/path、undefined 处理 | 其他监听接口及未覆盖成员 |
| applySync 与动画状态刷新 | [animation-state-migration.md](animation-state-migration.md) | animateTo 回调中受影响变量的动画前修改、高低版本同步闭包及最小示例；保留原有动画配置 | 状态刷新相关接口的版本冲突、未覆盖重载或编译错误；不因状态迁移重新查询原有动画参数 |
| PromptAction / ComponentContent 自定义弹窗 | [component-and-data-migration.md](component-and-data-migration.md) | 内容实例与 id 两组打开/关闭重载；UIContext、wrapBuilder、对象参数与最小构造示例 | 其他构造重载、完整选项、控制器重载及版本冲突 |
| AppStorageV2 / PersistenceV2 | [storage-and-application-state.md](storage-and-application-state.md) | connect 两种调用形式；AppStorageV2 的 remove/keys | 持久化专用管理/错误回调、globalConnect 等 |
| Environment / Ability 配置读取 | [storage-and-application-state.md](storage-and-application-state.md) | common 的 AbilityKit 导入；UIAbility 页面 getHostContext、config.language 与缺失值处理 | 其他宿主、未覆盖配置字段、版本冲突或相关编译错误 |
| Repeat | [rendering-reuse-and-advanced-components.md](rendering-reuse-and-advanced-components.md) | Array 数据源、each/key/template/templateId 回调、totalCount/reusable/cachedCount | 其他数据源/选项、精细懒加载能力 |
| 独立组件 reuse | [rendering-reuse-and-advanced-components.md](rendering-reuse-and-advanced-components.md) | reuseId 回调选项、无参组件复用生命周期 | 扩展复用配置或版本冲突 |
| Modifier / 滚动内置对象 / 高级组件 | component/rendering 对应主题 | 迁移决策与注意事项，不覆盖完整构造/参数 | 仅实际使用对象或组件的导出、类型、参数与版本 |
| 卡片/保留的 V1 Storage 调用 | [card-migration.md](card-migration.md)、storage/component 主题 | 字段映射及迁移语义；原有调用不变无需重新查签名 | 新增或改写调用所需的具体签名 |
| HAR/HSP 外部依赖 | [dependencies-and-build.md](dependencies-and-build.md) | 检查实际公开声明/导出的流程 | 查包自身声明或供应方文档，不到系统 SDK 猜导出 |

Local/Param/Event、Provider/Consumer、Once、Trace 等是核心装饰器语义，按组件和混用 reference 判断状态归属、读写与更新关系。SDK 声明不是观察行为的充分证据；未覆盖语义查匹配版本官方文档并做行为验证，不把全部装饰器变成待搜索的函数 API。

## 按需核对 SDK `.d.ts`

与工程目标及兼容 API 匹配的 reference 规则、版本门槛和已核实示例可以直接使用。只有具体缺口（导入、重载、返回值、成员名称）、版本冲突或相关编译错误才查询 SDK；不因示例省略 import 就重新核对所有已知语义。先写明待核对的符号和问题。

例如，已有 connect 三参数调用无需重查；选择 globalConnect 时才查该接口和直接引用类型。普通 class/Sendable 的 makeObserved 示例无需重查；特殊对象支持不明时才查该对象限制。已给出的版本门槛先与工程 target/compatible API 对照，不把“以实际 SDK 为准”解释成每次调用都重新搜索。

SDK 路径来源只接受：用户明确提供，或用户指定工程/Bench 的已有环境入口明确输出（例如该 Bench 的 `python cli.py env`）。环境入口可以解释其既有配置解析结果；迁移代理不得自行读取环境变量、反推 PATH、猜常见安装位置或搜索磁盘定位 SDK。记录入口和其输出的来源；解析失败时转到匹配版本官方文档，不扩大路径搜索。

用户只给出 SDK 根目录时，查询范围限定为以下声明目录；环境入口给出声明目录时，只查询它明确列出的存在目录：

- `<sdk>/default/openharmony/ets/api/*.d.ts` —— `@ohos.*` 系统能力与 API 版本标记
- `<sdk>/default/openharmony/ets/component/*.d.ts` —— ArkUI 组件与装饰器声明
- `<sdk>/default/openharmony/ets/kits/*.d.ts` —— Kit 公共导出（仅查询实际使用的 Kit）
- `<sdk>/default/hms/ets/api/*.d.ts` —— HMS 扩展 API
- `<sdk>/default/hms/ets/kits/*.d.ts` —— HMS Kit 公共导出

在这些目录中先按具体符号查找声明文件，再读取对应声明、相关重载及其直接引用的类型或导出。不要遍历整个 SDK/DevEco 安装目录，不整批读取无关 `.d.ts`；同一符号的同一缺口在本轮核实一次即可。目录缺失、符号不存在或无法对应版本时，停止 SDK 查询，转到下面的官方文档并记录未确认项。

本机安装的 SDK 不自动等于工程实际构建 SDK，也不自动等于设备运行版本。结合工程的 target/compatible API 和实际构建配置检查可用性；SDK 中存在某接口，不能单独证明它可用于较低兼容版本。`.d.ts` 适合核对签名、存在性和版本标记；装饰器语义、更新调度与生命周期仍以迁移文档和行为验证为依据。

reference 中的 API 版本来自标注来源的声明，不等于该低版本已实测；编译通过不等于运行行为已验证。reference 与实际工程声明冲突时，按匹配版本资料调整调用并记录差异，不擅自覆盖工程版本或忽略兼容下限。

## 如何确定 `<DOCS_ROOT>`

按下面的规则处理：

1. 用户指定了文档目录或文档仓库时，直接使用用户指定的来源。
2. 用户没有指定时，默认使用 OpenHarmony 官方文档仓库：[https://gitcode.com/openharmony/docs/tree/master/](https://gitcode.com/openharmony/docs/tree/master/)。在该仓库中查找下面表格列出的相对路径。
3. 如果指定来源无法访问，或没有匹配版本，继续按已读的主题 reference 工作并记录版本假设。涉及精确 API 签名、最低版本或编译限制时，不要凭经验猜写法；把缺少匹配资料列为外部阻塞。

找到文档后，先确认文档分支/版本与工程的目标 SDK/API 一致。不要因为目录名相似或文件存在，就默认它是匹配版本。默认仓库使用 `master`；如果用户指定了其他分支、tag 或本地版本，以用户指定的为准。

`<DOCS_ROOT>` 只在下面的路径表中使用：本地来源时，它表示用户指定的本地根目录；仓库来源时，它表示上面官方仓库的根路径。实际查阅时将表格中的相对路径拼到对应来源后面；不要把这个占位符写进命令或迁移代码。

## 按问题查文档

| 要确认的内容 | `<DOCS_ROOT>` 下的路径 |
| --- | --- |
| 迁移总览和能力矩阵 | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration.md` |
| 组件字段、输入/输出、Provider/Consumer、Watch/Monitor、computed、绑定 | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-inner-component.md` |
| 可观察类、ObjectLink、Track/Trace | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-inner-class.md` |
| LocalStorage、AppStorage、Environment、持久化 | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-application.md` |
| 内置对象、滚动状态、modifier | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-inner-object.md` |
| Repeat | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-rendering-control-repeat.md` |
| Reusable | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-reusable.md` |
| `@ReusableV2` 限制和生命周期 | `docs/zh-cn/application-dev/ui/state-management/arkts-new-reusableV2.md` |
| API 19+ 混用 | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-mixusage.md` |
| API 19 之前混用 | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-mixusage-before-api-version.md` |
| 更新调度差异 | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-update-difference.md` |
| 状态管理 API 签名、兼容接口、AppStorageV2、PersistenceV2 | `docs/zh-cn/application-dev/reference/apis-arkui/js-apis-stateManagement.md` |
| Repeat API 和 `VirtualScrollOptions` | `docs/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-rendering-control-repeat.md` |
| 系统预置 UI 组件清单 | `docs/zh-cn/application-dev/reference/apis-arkui/Readme-CN.md`，锚点 `system-preset-ui-component-library` |
| `animateTo` | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-animateTo.md` |
| 卡片 | `docs/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-card.md` |

Skill 打包后，state-management 目录可能会增加其他 `arkts-v1-v2-*` 文档。列出这些文件，并按目标代码涉及的主题补充查阅。

## 查阅时遵循这些规则

- 看清 API 的最低版本标记，例如 `<sup>19+</sup>`。
- 精确的签名和返回类型以具体 API 页为准，不要只看概述。
- 行为差异和跨文件示例以迁移指南为准。
- 高级组件要查它自己的 API 页来确认导出，不要自行给名称加 `V2` 后缀。
- 如果匹配版本的官方文档与本 Skill 冲突，以官方文档为准，并在迁移报告中说明版本差异。

在报告中写明实际使用的主题 reference、SDK `.d.ts` 和官方文档；使用 SDK 时记录路径来源、声明文件和核实的具体缺口，使用文档时记录来源和版本，没有匹配资料时列出保留的假设或阻塞项。
