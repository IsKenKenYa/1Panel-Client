# 循环、复用和高级组件

## 循环渲染怎么迁

迁移时要保留原来的“什么时候加载”和“是否复用 item”这两个行为：

| V1 写法 | 常见 V2 写法 | 要保留的行为 |
| --- | --- | --- |
| `ForEach` | 不启用 `virtualScroll` 的 `Repeat(...).each(...)` | 继续一次加载全部数据。item 中用 `RepeatItem.item/index`，并保留稳定的 key 函数。 |
| 没有 item 复用逻辑的 `LazyForEach` | `Repeat(...).each(...).virtualScroll({ reusable: false })` | 保留懒加载，但不要凭空加入复用回调或状态重置。`reusable` 选项为 API 18+，与 Repeat 本体版本不同。 |
| item 带 `@Reusable` 的 `LazyForEach` | 默认使用 `Repeat(...).virtualScroll(...)` | 该 Repeat 路径由 Repeat 负责懒加载和复用。item 可以迁为 `@ReusableV2`，但不要期待它的 `aboutToReuse()` 在 Repeat 复用路径执行；是否保留独立复用能力取决于其他创建位置。 |

从 `IDataSource` 迁移时，使用 V2 可观察数组或数据对象，通过直接修改代替手工通知。保留数据身份、key 唯一性、拖拽排序、总数、缓存设置和部分加载行为。不要使用随机 key。

`Repeat.each` 的回调参数是 `RepeatItem<T>`，不是元素 `T`。例如字符串列表应写 `.each((row: RepeatItem<string>) => { Text(row.item) })`；不要写 `.each((row: string) => ...)`。

### Repeat 的迁移相关调用契约

Repeat、RepeatItem 及其选项类型属于全局声明，无需 Kit 导入。来源：API 26 SDK `ets/component/repeat.d.ts`。以下为声明节选，成员均返回 RepeatAttribute<T> 支持链式调用，不是应用内定义：

```ts
// API 12+：使用普通 Array<T> 的迁移形式
each(itemGenerator: (repeatItem: RepeatItem<T>) => void): RepeatAttribute<T>;
key(keyGenerator: (item: T, index: number) => string): RepeatAttribute<T>;
virtualScroll(virtualScrollOptions?: VirtualScrollOptions): RepeatAttribute<T>;
template(type: string, itemBuilder: RepeatItemBuilder<T>,
  templateOptions?: TemplateOptions): RepeatAttribute<T>;
templateId(typedFunc: TemplateTypedFunc<T>): RepeatAttribute<T>;
```

| 类型/选项 | 已覆盖的形状 | 最低 API |
| --- | --- | --- |
| `RepeatItem<T>` | `item: T`、`index: number` | 12 |
| `RepeatItemBuilder<T>` | `(repeatItem: RepeatItem<T>) => void` | 12 |
| `TemplateTypedFunc<T>` | `(item: T, index: number) => string` | 12 |
| `VirtualScrollOptions.totalCount` | `totalCount?: number` | 12 |
| `VirtualScrollOptions.reusable` | `reusable?: boolean`，默认 true | 18 |
| `TemplateOptions.cachedCount` | `cachedCount?: number`，按模板设置缓存 | 12 |

注意两类回调不同：each/template 的 builder 接收 RepeatItem<T>；key/templateId 接收元素 T 和 index。不要把全部回调都写成 RepeatItem，也不要解构 builder 的 RepeatItem。模板缓存与 List 等容器的 cachedCount 不是同一个设置。

```ts
// 在组件 build 的 List 中；rows 为 string[]。
Repeat<string>(this.rows)
  .each((row: RepeatItem<string>) => { ListItem() { Text(row.item) } })
  .key((item: string) => item) // 仅适用于本例中字符串唯一、稳定的业务身份
  .virtualScroll({ reusable: false }) // API 18+
```

该最小形式、上表回调及选项可以直接使用；Readonly 数据源、精细懒加载/总数回调等未覆盖能力或版本冲突，才按 [official-doc-routing.md](official-doc-routing.md) 查询具体声明。API 12 的 Repeat 不代表 API 18 新增选项在 API 12 可用。

## 判断实际由谁执行复用

不要仅凭组件有没有 `@ReusableV2` 判断复用机制；要按创建路径判断：

- **Repeat 路径：** item 位于 `Repeat(data).virtualScroll(...).each(...)` 中，且没有通过目标 API 支持的选项关闭复用时，由 Repeat 管理 item 的回收和复用。即使 item 子组件带 `@ReusableV2`，该路径也不会执行组件自己的 `aboutToReuse()`。
- **非复用 Repeat 路径：** 未调用 `virtualScroll()` 时是全量加载；API 18+ 显式配置 `virtualScroll({ reusable: false })` 时只保留虚拟滚动/懒加载而关闭 item 复用。更低兼容版本不能直接使用该选项，需另行设计与验证加载/复用方案。
- **独立组件复用路径：** 组件在 if/else 等非 Repeat 场景中反复创建和销毁，并通过 `@ReusableV2`（必要时配合 `.reuse(...)`）进入独立复用池时，才会按 `@ReusableV2` 生命周期处理。
- **同一组件有多种创建位置：** 可以同时服务 Repeat 和非 Repeat 场景；Repeat 路径由 Repeat 复用，非 Repeat 路径才可能使用组件自己的复用生命周期。迁移前必须搜索全部创建点，不能从组件装饰器反推所有调用点的行为。

存在独立 `@ReusableV2` 复用路径时还要满足：

- 组件改为 `@ComponentV2`，且只作为 V2 组件的子组件；
- `aboutToReuse()` 不带参数。V2 会在复用前重置组件自有状态，但这不改变字段的输入性质；必须逐项检查旧 `params` 和全部创建点，不能只删掉参数；
- 创建点以 `Child({ label: value })` 传入的字段必须声明为 `@Param`（按语义可配合 `@Require` 或 `@Once`），不能声明为 `@Local`；`@Local` 接收外部传值会直接编译失败；
- 只有确实需要清理时才保留 `aboutToRecycle`，且不要在其中修改状态；
- `.reuseId('groupA')` 改为当前的 `.reuse({reuseId: () => 'groupA'})` 形式；
- 检查回收时的自动状态重置、computed 重算、Monitor 行为和冻结机制。

独立复用的已核实调用形式来自 API 26 SDK `ets/component/common.d.ts`，ReuseOptions 与 reuseId 回调无需导入：`.reuse(options: ReuseOptions)` 为 API 18+；选项为 `reuseId?: () => string`，返回当前组件属性类型以继续链式设置。示例：`Child({ label: this.label }).reuse({ reuseId: () => 'groupA' })`。已覆盖这一形式，不为它重新查询；其他复用池选项、生命周期扩展或版本冲突才查询。组件自定义 `aboutToReuse(): void`、`aboutToRecycle(): void` 与输入契约的行为规则见上，不因接口可编译就推断回调一定会执行。

## Repeat template 与 `@ReusableV2`

`@ReusableV2` 组件不能直接写在 `Repeat.template()` 里面，否则会编译失败；需要组合时，在 template 中放普通 `@ComponentV2`，再由它包含 `@ReusableV2` 子组件。即使存在 `@ReusableV2`，未关闭复用的 `virtualScroll()` 路径仍由 Repeat 管理复用，不要依赖子组件的 `aboutToReuse()`。

另外确认：

- `.template()` 只在懒加载/虚拟滚动模式下使用；
- 始终有 `.each()` 作为兜底，即使内容为空；
- `templateId()` 返回值与 template 类型匹配；
- 每个生成的 item 只有一个根节点；
- 缓存数量和按 template 分组的复用行为与旧逻辑一致。

## 高级/系统预置 UI 组件

以 `docs/zh-cn/application-dev/reference/apis-arkui/Readme-CN.md` 的“系统预置 UI 组件库”章节作为当前清单。SDK 会更新，下面的名称只作线索，不能代替当前文档：

- `Chip` / `ChipV2`
- `ChipGroup` / `ChipGroupV2`
- `ComposeListItem` / `ComposeListItemV2`
- `ComposeTitleBar` / `ComposeTitleBarV2`
- `EditableTitleBar` / `EditableTitleBarV2`
- `ExceptionPrompt` / `ExceptionPromptV2`
- `Popup` / `PopupV2`
- `ProgressButton` / `ProgressButtonV2`
- `SegmentButton` / `SegmentButtonV2`
- `SubHeader` / `SubHeaderV2`
- `SwipeRefresher` / `SwipeRefresherV2`
- `ToolBar` / `ToolBarV2`
- `TreeView` / `TreeViewV2`
- `advanced.Counter` / `CounterV2`

名称带 V2 后缀也不能直接替换。本 reference 不维护这些组件的完整参数签名；只对任务实际使用的组件，核对新旧 import 模块、实际导出名、构造参数、model/数据类型、回调、双向字段、最低 API 版本和嵌套的自定义组件。先用工程已有声明/对应 API 页解决缺口，需要 SDK 时按限定目录查询具体符号，不能把上面的名称清单当作必须逐一搜索的任务。完整场景迁移且已确认有适用的 V2 导出时，迁移实际组件调用与输入/事件契约；不能仅迁移外层页面。只有确认没有适用的 V2 导出，或范围/版本不允许替换时，才保留 V1 并建立混用边界；不要把未核实当作不存在，也不要虚构 V2 符号。
