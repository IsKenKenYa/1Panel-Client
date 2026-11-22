# 组件复用、结构分组与迭代 key

## 前提与机制

### 自定义组件复用规则

1. 同一父组件下的自定义组件反复移除与重新加入、频繁创建和销毁时，状态管理 V1 使用 @Reusable，状态管理 V2 使用 @ReusableV2（API 18+），复用已有实例与子树。
2. 同一复用组件在不同数据下的子树结构差异较大时，按结构类型设置不同 reuseId，让同组实例复用相同结构；V1 使用 `.reuseId('类型')`，V2 使用 `.reuse({ reuseId: () => '类型' })`。
3. 同一父组件内通过 if/else 等分支切换结构相同的复用组件，是 @Reusable 的典型场景：切换时从默认复用组取回实例，不构成“反复销毁重建”的性能问题。不因此建议去掉分支改为常驻挂载，也不建议删除 @Reusable 或 aboutToReuse 的字段同步。

这些规则同时用于滑动条目与转场中的内容页切换。先确认父组件保留、旧实例确实下树进入池、后续有再加入机会；仅隐藏仍挂载的页、首次冷创建和动画中仍在使用的实例，不直接计为可复用的空闲实例。

### 迭代 key 规则

ForEach 的缺省 key 由索引和 JSON 序列化内容生成，更新按 key 差异创建项。索引、内容变化可能改变 key，需要结合插入/重排/字段变化分析。自定义 key 要唯一并表示业务身份；业务身份稳定也不能替代数据更新逻辑。不要把这套缺省规则直接套给 Repeat.key。

同时核对 itemGenerator 的参数：若 itemGenerator 声明 index，而 keyGenerator 未声明 index，框架可能在返回的业务 key 上追加 index。不能只看到 `item.id` 就断言重排时 key 稳定；核对该版本规则与最终键值。

## 版本与路径速查

| 场景 | 路径与边界 |
|---|---|
| V1同父组件复用 | @Reusable+aboutToReuse字段同步，先有真实回收/再加入机会 |
| V2列表，API12+ | Repeat+.each(...)+.virtualScroll()合法，已有原生节点复用；不套API18门槛，也不混用V1装饰器 |
| V2非列表，API18+ | @ReusableV2；真实复用时@Param按新参数初始化、@Local按初值重置，跨记录编辑值按ID保存到父/模型，不套V1式参数搬运 |
| 跨父/跨页 | 读共享池规则，局部池不跨父共享；框架GlobalReuse按目标版本核对 |

## 检查方法

1. 找复用组件父级、创建移除场景和目标版本；跨父组件或跨页面反复创建时，按[BuilderNode 与全局复用](buildernode-and-global-reuse.md)检查池的作用范围和换父挂载路径。
2. 比较复用前后的子树。子树结构差异较大时，按结构类型设置不同 reuseId，使同组实例保持相同结构；相同结构的实例共享同组缓存。
3. 区分自动同步字段与本地派生状态。检查 aboutToReuse 是否更新需要更新的本地字段、清理上一项残留；不要一律手工再写 @Link/@ObjectLink，@Link/@ObjectLink/@Prop 等自动同步的状态变量也不要在该回调中重复赋值。嵌套子组件也要确认收到新数据。aboutToReuse 更新的是组件状态变量，写入的界面显示字段必须保持 @State 等可观测装饰器；建议把它们改成普通成员变量会导致复用后界面不更新，属于必须纠正的错误建议。
   V1/V2 复用均不会重新调用 aboutToAppear；每次进入新记录都需要的同步或任务不能只移到该回调。可复用计算按数据版本提前准备，必要的复用字段更新仍保留在 aboutToReuse，昂贵工作的处理统一见[高频重复工作](frequent-work.md)。
4. 检查异步结果是否仍属于当前数据 ID；不能让旧项结果覆盖新项。不为省时间删除必要清理。
5. 独立检查 ForEach/LazyForEach key：唯一、稳定、生成开销；稳定 key 后内容和本地状态仍须正确更新。

## 默认复用组：相同子树结构无需额外分组

V1 @Reusable 未显式设置 reuseId 时，默认按自定义组件名分组。同一父自定义组件下，同一组件中子树结构相同的实例只改变文本、颜色、对齐等数据/属性时可以使用默认组；额外增加一个固定 reuseId 通常不改变这类实例的分组能力，更不能代替 @Reusable 和真实的回收/再加入路径。

先区分父级 if 用于移除/显示组件，与复用组件内部 if/ForEach 导致子树变化。父级出现 if 不是缺少 reuseId 的证据；内部出现条件渲染也不自动意味着结构差异值得拆池。ForEach 是迭代渲染，不能混同它的 key 与复用组。

```ts
// Tile 已有 @Reusable、正确的字段同步；两个分支的子树相同。
if (this.useFirst) {
  Tile({ title: 'A', detail: 'alpha' })
} else {
  Tile({ title: 'B', detail: 'beta' })
}
```

这是省略 reuseId 的合理用法。为两个分支分别加 `reuseId('start')` / `reuseId('end')` 会隔离原本可共享的缓存；各组预热后仍可在组内复用，不能夸大为“以后全部重建”。只需要更新属性且不存在实例切换需求时，还可评估合并为一个调用；V1 @State 初始化入参不提供后续父更新同步，必须另行核对字段语义。

同一自定义组件具有有限种明显不同的子树，跨结构复用会拆建子组件时，按结构类型设置不同 reuseId（如 photo/text；写法见下文“不同子树结构组件的复用分组”）。相同结构使用同一标识，不同结构使用不同标识。性能验证分别记录首次显示和后续重复切换，比较同类型组件复用时的创建和拆建工作。

## 性能示例：实际启用相同子树结构组件复用

前提：同一父组件通过分开的交互反复移除和重新加入结构相同的复杂自定义组件，该组件需要自己的展开状态。普通 @Component 每次重新加入都创建实例；使用 @Reusable 复用实例，并在 aboutToReuse 中接收新 title/detail、按业务重置展开状态。调用处保留默认分组即可，无需新增 reuseId。相反，组件一直挂载而仅更新父数据时，增加 @Reusable 或 reuseId 都不能凭空产生复用机会。

用同样的移除/显示动作比较初次创建与真实复用次数，再比较相关阶段耗时；不能以“代码多了 reuseId”验收。确认新记录两个字段均更新，局部状态按业务初始化；不能把 aboutToAppear 次数当作复用次数，也不为减少创建而把应刷新的字段保留为旧值。

建议中说明复用后显示字段及依赖这些字段的嵌套子树均对应当前记录；局部状态按业务重置或按记录保存，并保留展开/折叠等原有交互。无需穷举示例中的每个标签或控件，不能只更新顶层文本而忽略子树和事件绑定。

## 独立边界：子树结构相同的新记录按唯一 ID 拆池

前提：同一父组件反复移除再加入下一条新记录，结构相同，记录 ID 每次不同且不再回访，不需要按记录保留独立实例或编辑状态。以下写法把可互相复用的结构拆成多个组：

### Bad case

```ts
RecordTile({ title: this.title, detail: this.detail }).reuseId(this.recordId)
```

### Good case

```ts
RecordTile({ title: this.title, detail: this.detail })
```

在这些条件下，优先评估移除多余 reuseId，采用默认组件名分组；固定结构组 `.reuseId('record')` 也是等价可选写法，不是新增收益。优化来自纠正原来的过细分组，保留 aboutToReuse 中必要的字段更新。业务身份、ForEach key 与复用组不是同一概念；不同结构的子树或确需独立状态时不能机械合池。比较相同动作下的初次创建/复用次数及相关耗时，不能仅凭增加或修改 reuseId 宣称已经加速。

## 不同子树结构组件的复用分组

先确认同一父组件中的回收、再加入顺序，以及复用前后的实际子树。例如先隐藏 InfoCard 并等待回收完成，再显示另一种结构；父组件及缓存保留时，默认组中的旧实例会被新结构复用，withChart 改变会使内部 if 切换，原有子组件被销毁并创建另一种子组件。成立条件明确时，应指出这部分可避免的拆建并给出按结构设置不同 reuseId 的具体改法，不只写“建议评估”。仅有 if、ForEach key 变化或未设置 reuseId，尚不足以单独认定这个问题。

### Bad case

```ts
// 前提：先隐藏并等待回收，再显示另一种结构；父组件与缓存保留。
// 未区分两种子树结构：旧实例按新结构更新时会拆建子组件。
if (this.showChart) {
  InfoCard({ title: '图表视图', withChart: true })
} else {
  InfoCard({ title: '摘要视图', withChart: false })
}
```

### Good case

按两种实际子树结构设置不同复用组：

```ts
if (this.showChart) {
  InfoCard({ title: '图表视图', withChart: true }).reuseId('info-chart')
} else {
  InfoCard({ title: '摘要视图', withChart: false }).reuseId('info-text')
}
```

reuseId 使用固定的结构标识，不按每条业务数据唯一 ID 设置不同组。已经按实际子树结构正确分组、且没有其他不合理条件的代码，不报告分组缺陷，也不要求删除分组；未分组且跨结构复用途径明确的代码，应给出结构分组或拆成不同自定义组件的具体方案。分组不代替 aboutToReuse 的字段同步。验证时保持相同动作、数据、预热和缓存容量，检查后续复用是否保留对应子树、减少跨结构拆建；首次创建仍然需要，不把开发者代码检查结论写成已测得耗时或帧率收益。没有相关生命周期依赖时，不虚构子组件功能故障。

规则依据：[@Reusable 装饰器：组件结构需一致](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-reusable.md#组件结构需一致)。

aboutToReuse 时机与参数约定：[aboutToReuse（V1，API 10+，携带构造参数；V2 版本 API 18+，无参数）](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-custom-component-lifecycle.md#abouttoreuse10)。官方约定用该回调更新组件状态变量，@Link/@ObjectLink/@Prop 等自动同步变量不在此重复赋值，回调内避免耗时操作。

## 正确性边界：复用字段同步

前提：同父可复用条目间 title 和 subtitle 都随业务项变化，subtitle 是本地 @State，需要明确刷新。此处先报告数据残留风险，不能把功能错误伪装为已测性能瓶颈。

### Bad case

```ts
@Reusable
@Component
struct ContactTile {
  @State title: string = '';
  @State subtitle: string = '';
  aboutToReuse(params: Record<string, string>) {
    this.title = params.title;
  }
  build() { Column() { Text(this.title); Text(this.subtitle) } }
}
```

### Good case

```ts
aboutToReuse(params: Record<string, string>) {
  this.title = params.title;
  this.subtitle = params.subtitle;
}
```

仅更新业务要求变化的字段。若某字段须保留用户编辑状态，应按业务 ID 管理而非无条件清零。

固定短列表、内容/顺序不变的默认 key 是正常反例。动态列表改用 `item.id` 时必须验证唯一性和更新：同一 id 更换内容仍需刷新，插入/删除/重排不能把旧项局部状态移到新项。

## V2 复用的性能检查

- API 18+ 的 @ReusableV2 组件频繁移除、再加入时，检查实际创建与复用次数；按子树结构设置复用组，避免按每条数据拆池或在切换前清空池。
- @Local 初始化表达式、@Computed、@Monitor 和用户复用回调可能随重置重复执行。定位其中的扫描、序列化、同步 IO 和批量状态写入，将可复用结果按依赖提前准备；自动重置不会消除这些计算。
- 分开常驻实例的参数更新、真实回收后复用、销毁后新建。V2真实复用时@Param按新参数初始化、@Local按声明初值重置；常驻实例仅更新@Param不等于发生了复用，普通字段另按业务处理。需跨记录保存的编辑值按稳定ID放在父组件/模型，经@Param和@Event同步；不能把输入丢失说成复用默认保留@Local，也不能靠禁用复用保存已销毁实例的编辑值。此类状态问题按功能语义报告。
- 检查缓存中的定时器、帧任务、外部资源和过期异步结果。池中 UI 冻结不能代替业务资源管理。复用组回调的动态返回值按版本核对：26.0.0 之前使用字符串字面量指定分组。

优先在当前组件和状态管理版本内消除重复计算与无效重建。接口依据：[@ReusableV2](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-reusableV2.md)。

## Repeat 性能检查

- 大列表需要按可见范围创建时，检查是否使用适用的虚拟滚动。Repeat 从 API 12 起支持，虚拟滚动要求状态管理 V2 和受支持的滚动容器；小且有界、需要全量显示的列表可保留全量模式。
- `.key()` 使用稳定唯一的业务身份，`.templateId()` 按有限结构分类；回调保持轻量，避免整对象序列化、全表扫描和同步 IO。多模板用于虚拟滚动模式，结构相同的条目共享模板和缓存。
- Repeat 已有原生节点复用，重点检查条目反复创建、模板过细、缓存无效或过大，以及取数/构建回调里的昂贵计算。不要为增加一层复用就给每个条目叠加 @ReusableV2；Repeat 复用也不能假定会触发子组件 aboutToReuse。
- 数据更新和事件读取保持当前 RepeatItem 的响应绑定，避免值过期后通过更换所有 key、关闭复用或反复重建来修补；回归最新数据、索引和事件对象。
- 分别观察条目创建量、复用命中、回调成本和缓存内存；滚动容器的预加载缓存与模板空闲节点池分开判断。key 回调成本用 key 回调计数 / CPU 调用栈观测（见[高频工作](frequent-work.md#打点与预期变化)的 Repeat key 回调行），不能用创建数或帧 Duration 代替；key 回调次数与节点创建数不一定减少，主要比较单次及累计 key 工作。

## 建议与验证

语义核对：用不同数据检查同结构/不同结构、删除重排、同 ID 替换数据、异步返回与本地状态保持。V2 额外检查 @Local/@Param 重置、普通字段残留；Repeat 核对条目内容、Builder、点击对象和索引始终对应当前数据，覆盖首末项、同 ID 替换和重排。相关要求在建议中说明如何保持，默认不另列功能测试步骤；输入明确要求功能测试时再展开操作。

性能比较区分创建、复用次数及各区间耗时，不凭出现复用事件就认定加速。缺父级、数据变更流程或字段归属时请求相应代码。

## 打点与预期变化

先说明减少重复创建和初始化工作的预期收益，再按条件列出日志与 Trace 验证方法，两者都适用时都写出供开发者选择。日志方法使用应用实际创建/复用回调的记录，比较 creates/reuses 的变化。Trace 方法在实际重新显示分支的状态赋值前后加入成对的 `hiTraceMeter.startTrace` / `finishTrace`；给出[定位更新帧的具体步骤](../verification.md#如何定位动作后的更新帧)：搜索业务点名称，选中并放大，以结束时刻对齐应用 UI 线程，向右找到第一个适用的 ReceiveVsync，读取完整区间的 Duration。两种方法各自说明观察目标；隐藏和重新显示分开执行、分别等待更新完成，首次创建与后续复用分别比较。

| 对应场景 | 观察对象 | 预期与限制 |
|---|---|---|
| V1 同父实例复用 | 日志方法：实际 creates/reuses 记录；Trace 方法：重新显示动作后的完整 ReceiveVsync | 日志核对后续创建增量减少、复用发生；Trace 在实际 show=true 赋值前后用 startTrace/finishTrace 标记动作，按结束时刻查找 UI 线程右侧更新帧并比较 Duration。两种适用方法并列供选择；不能把 aboutToAppear 当作复用次数 |
| 相同子树结构组件默认分组 | Tile 的默认组及相同动作的创建/复用 | 默认组已合理；加固定 reuseId 不要求出现新收益，分成 start/end 会隔离缓存，但各组预热后仍可组内命中 |
| 相同子树结构组件按业务 ID 拆池 | 记录 ID 拆组与合并后各组的创建/命中 | 纠正对相同子树结构组件的过细分组后，预期跨记录命中改善、初次创建增量减少；当前只有诊断输入，须有正式运行对照才能填实测结果 |
| 不同子树结构的复用分组 | 回收/再加入顺序、复用实例的新旧结构、子组件拆建与耗时 | 已按实际结构分组时不报告分组缺陷；未分组且跨结构复用途径明确时，指出拆建并给出分组方案。保持相同动作、预热和缓存条件验证，首次创建仍需要，不编造实测收益 |
| V2 复用与记录状态 | 参数显示、按记录保存的本地编辑值及实际移除/再加入路径 | 先区分 API 契约错误与合法代码的状态保存问题；@Local 复用重置和普通销毁重建均不能替代业务持久状态。按身份回归本地编辑值与显示，语义正确不等于测得性能收益 |
