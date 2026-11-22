# 卡片状态管理迁移

当迁移范围包含 ArkTS 卡片入口、`form_config.json`、`FormExtensionAbility`、`postCardAction`、卡片中的 `@Entry(storage)` 或 `@LocalStorageProp` 时读取本文。卡片 UI 运行在卡片渲染服务中，它通过 `updateForm` 接收卡片提供方的数据；不要把普通页面的 LocalStorage 迁移规则直接套到卡片上。

## 先建立字段对应关系

1. 从 `form_config.json` 找到卡片入口源码。
2. 找到 `FormExtensionAbility` 中创建 `FormBindingData` 并调用 `updateForm` 的代码。
3. 对每个刷新字段记录：V1 `@LocalStorageProp(key)` 的 key、V1 变量名、`updateForm` 数据字段名、读取该状态的组件。
4. 判断数据只在入口组件内部使用，还是需要同步给后代组件。

V1 按 `@LocalStorageProp(key)` 的 **key** 匹配 `updateForm` 数据；V2 按被通知状态的 **变量名** 匹配。因此 V1 的 key 与变量名不同时，迁移后不能继续依赖旧 key。优先让 V2 变量名与现有 `updateForm` 字段名一致；只有业务明确要求更改数据契约时，才联动修改卡片提供方字段。

## 强制迁移规则

| V1 卡片写法/语义 | V2 迁移要求 |
| --- | --- |
| `@Entry(storage)` + `@Component` | 迁移为 `@Entry` + `@ComponentV2`。删除仅为该卡片入口创建和传入的 LocalStorage 实例。 |
| 卡片通过 LocalStorage 接收 `updateForm` 数据 | V2 卡片不再使用 LocalStorage；不要在 `@ComponentV2` 卡片中保留 `@Entry(storage)`、`LocalStorage` 或 `@LocalStorageProp`。 |
| `@LocalStorageProp(key)` 的数据只在当前组件内使用 | 迁移为 `@Local variableName`，并确保 `variableName` 与 `updateForm` 数据字段名完全一致。 |
| 同一刷新数据需要跨卡片组件共享 | 祖先组件使用 `@Provider`，后代组件使用 `@Consumer`，有效共享通道和类型必须匹配；允许省略 alias 后按字段名匹配，也允许匹配的显式 alias。相关组件一起迁为 `@ComponentV2`。 |
| `FormExtensionAbility.updateForm` 已推送正确字段 | 调用流程通常不需要修改，但每个数据字段名必须与接收它的 V2 变量名一致。 |

区分两种匹配：`updateForm` 数据按入口的状态变量名接收；Provider/Consumer 则按有效共享通道匹配，显式 alias 存在时使用 alias，否则使用字段名。alias 不会替代或重命名 `updateForm` 接收字段。卡片入口的 `@Provider` 可以先按变量名接收刷新数据，再把该状态提供给后代。

例如刷新字段为 `detail` 时，入口仍声明 `detail`；`@Provider() detail` / `@Consumer() detail` 与 `@Provider('detail') detail` / `@Consumer('detail') detail` 都使用 detail 通道。一端省略、另一端显式写 'detail' 也匹配，不能把空参数形式规定为唯一正确写法。其他显式 alias 也须两端匹配，并保留入口字段名与刷新字段的对应关系。

alias 与默认字段名的匹配规则见 [Provider/Consumer 官方说明](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-provider-and-consumer.md)；真实卡片刷新仍须按下面的验证项检查，通道匹配不能替代卡片宿主测试。

## 验证

- 卡片入口是 `@Entry @ComponentV2`，且 V2 卡片代码中没有残留 `LocalStorage`、`@Entry(storage)` 或 `@LocalStorageProp`。
- 每个 `updateForm` 数据字段都能按完全相同的 V2 变量名找到唯一接收状态。
- 仅组件内使用的数据为 `@Local`；跨组件数据的 Provider/Consumer 有效通道、类型和祖先关系一致，不能只检查装饰器是否为空参数。
- `FormExtensionAbility.updateForm` 未因机械迁移被无意义改写；如果字段名确实改变，卡片 UI 与提供方必须同时修改。
- 保留原有 `form_config.json` 入口、`postCardAction`/`onFormEvent` 事件链和业务刷新行为。
- 对完整工程执行构建；有真实卡片宿主环境时，再验证安装卡片、触发刷新以及父子组件同步。仅普通页面或 HAP 构建通过，不能单独证明卡片运行时刷新正确。

本 reference 覆盖状态接收、字段映射和迁移语义，不维护 updateForm/postCardAction 等完整 API 签名。原调用保持不变时不重复核对；新增或改写调用、未覆盖能力或版本冲突时，通过 [official-doc-routing.md](official-doc-routing.md) 定向核对匹配版本的官方卡片文档及实际接口声明。
