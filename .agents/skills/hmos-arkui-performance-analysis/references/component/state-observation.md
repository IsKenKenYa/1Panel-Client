# 状态观测与更新范围

## 版本与前提

先确认使用状态管理 V1（@Component）还是状态管理 V2（@ComponentV2），再看对象定义和实际写入方式。V1 的 @Track 从 API 11 起支持属性级更新；V2 的 @ObservedV2/@Trace 从 API 12 起支持。API 26 满足这些接口的版本要求，但不代表原有 V1 数据链可以直接改用 V2。版本从所属工程构建配置确认，不能只看页面片段。

## 检查方法

1. 找状态拥有者与 UI 读取链：例如 this.profile.name，而不是仅列出 @State 数量。
2. 找变更操作：字段赋值、嵌套字段修改、对象整体替换和容器操作分别判断；读取整个对象传给其他组件也需跟进其使用方式。
3. 普通 V1 对象的某属性变动可能通知关联该对象其他属性的 UI；逐个 UI 更新绑定检查其完整读取依赖。组件的内容、enabled、颜色等属性要一起核对：即使显示未变化字段，只要另一个绑定属性读取了变化字段，该组件仍需更新。事件回调执行时的读取与 build 期间建立的 UI 依赖分别判断；只有输入确实存在可排除的无关依赖时才说明冗余更新风险。
4. @Track 模式按属性依赖更新。建议增加 @Track 时检查该类其他 UI 使用的属性；在 V1 的 UI 中读取同一类未标记属性会发生运行时报错，不能仅说“该字段无法刷新”。不要将每次对象整体替换解释为只改一个被跟踪属性。
5. V2 嵌套类需逐层核对类和属性的观测条件；不能只给外层加 @Trace 就保证所有内层字段可刷新。
6. 状态更新范围与后续 Measure/Layout/Render 范围不同。仅凭开发者代码检查不能直接证明全屏重绘、帧率下降或具体毫秒数。

## Bad case

```ts
class BadgeData { count: number = 0; caption: string = 'Unread'; }
@Component
struct Badge {
  @State data: BadgeData = new BadgeData();
  build() {
    Column() {
      Text(this.data.count.toString())
      Text(this.data.caption)
      Button('add').onClick(() => { this.data.count++; })
    }
  }
}
```

前提是普通 V1 观测：count 高频变化、caption 保持不变，两个读取同一对象。可指出 caption 相关 UI 的冗余更新风险，不能称必然严重卡顿。

## Good case

### 方案 A：保留 V1，使用 @Track

```ts
class BadgeData {
  @Track count: number = 0;
  @Track caption: string = 'Unread';
}
```

在支持 @Track 的 V1 环境、UI 读取如上且只修改 count 的条件下，可避免上述非依赖属性更新；仍要确认其他 UI 属性都满足 @Track 约束。保留原有 @Component 和 @State 数据拥有关系，这是该片段的最小改法。

### 方案 B：使用 @ObservedV2 与 @Trace

确有迁移需要时可评估 @ObservedV2 与 @Trace 的属性级观测。下面展示采用 V2 组件的局部改法；采用此路径时说明迁移影响，无需为每个 V1 问题同时给出 V2 方案。

```ts
@ObservedV2
class BadgeDataV2 {
  @Trace count: number = 0;
  @Trace caption: string = 'Unread';
}
@ComponentV2
struct BadgeV2 {
  @Local data: BadgeDataV2 = new BadgeDataV2();
  build() {
    Column() {
      Text(this.data.count.toString())
      Text(this.data.caption)
      Button('add').onClick(() => { this.data.count++; })
    }
  }
}
```

### 方案 B 的迁移与混用检查

- 提醒必须落到开发者代码：本例原来是 @Component Badge 和 @State data；上面的 V2 组件方案同时改为 @ComponentV2 和 @Local。不能只给 BadgeData 增加 @ObservedV2/@Trace，却保留 @State data 接收该对象；V1 装饰器接收 @ObservedV2 实例会编译报错。同一模型也不能混用 @Observed/@Track 与 @ObservedV2/@Trace。API 26 仍需遵守这些约束。
- 跟进该对象的父子传递、共享引用和整体替换路径。若现有接收端用 @Prop/@Link/@ObjectLink，或依赖 @Provide/@Consume、@Watch，说明哪些实际位置需要调整，并核对单向同步、双向写回及监听行为。不能机械替换装饰器；只给页面片段时指出尚需核对的边界，不虚构已有父子混用故障。边界无法确认时优先方案 A，不把方案 B 写成可直接套用。
- V1/V2 组件可以按版本支持条件共存，不要求整个应用迁移。@ObservedV2 对象也可在 @Component 中以普通字段独立使用，但普通字段自身的整体替换不受 @State 观测；仅在确认引用稳定及相关行为保持时考虑。API 19+ 的 UIUtils.enableV2Compatibility/makeV1Observed 用于受支持的 V1 对象兼容路径，不适用于将 @ObservedV2 实例包装给 V1 装饰器；仅在实际传递边界需要时评估。

接口与边界依据：[@ObservedV2 与 @Trace](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-observedV2-and-trace.md)、[V1/V2 混用指导（API 19 及之后）](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-v1-v2-mixusage.md)。

## 建议与验证

- 现有 V1 可优先评估方案 A；引用身份、父子同步和更新职责允许时，拆分独立状态也是可行路径，只读且确实不再变化的字段可保留普通成员。不能仅因未选择 @Track 判方案错误。采用方案 B 时核对迁移与混用，不只凭 API 满足就推荐迁移，也不强制同时枚举所有路径。
- 效果验证：先说明整体收益，再按公共指南选择适用方法。采用 Trace 时给出下文的更新帧耗时比较步骤，具体状态通知按需补充。日志方法仅在能直接记录目标绑定执行、且保持原组件结构与依赖关系时提供；@Watch 的状态监听次数不代表 UI 绑定更新数量。两者都适用时中性并列供选择，只有 Trace 适用时只给 Trace。组件类型、属性绑定和实例数量变化时重新推导，不沿用示例的数量或仅替换组件名。
- 只读或未参与 UI 的状态可考虑普通字段，但须核对 Watch、派生值、生命周期和跨组件依赖，不能仅凭当前 build 未读就删除状态语义。
- 缺对象定义、写入路径或子组件读取时请求对应片段；症状仍未解释按人工验证指南处理。

## 打点与预期变化

### V1 状态通知参数与后续更新验证

先确定验证对象：本次修改了哪个状态字段、哪些 UI 绑定读取它、哪些绑定只读取其他字段，以及这些绑定属于哪个组件实例。一个 UI 元素可读取多个字段，同一个字段也可被多个元素或列表实例读取，依赖元素数由这些关系确定。对象整体替换、多个写入合并到同一帧、条件分支和复用分别核对；不将属性级更新一概解释为只更新一个元素。

1. **业务打点（可选）**：按当前代码明确一次写入的前置状态和触发方式，录制覆盖该动作到后续更新。需要新增业务打点时，将实际写入语句放在成对的 `hiTraceMeter.startTrace` / `finishTrace` 之间；名称按当前业务命名，写法见[新增业务打点的写法](../verification.md#新增业务打点的写法)。
2. **整体收益**：根据当前依赖关系说明本次优化应减少哪些无关 UI 更新，预期处理这次写入的下一帧工作量及耗时减少；是否实际缩短由下一步测量确认。
3. **整体收益的观察方法**：按[定位更新帧的方法](../verification.md#如何定位动作后的更新帧)给出具体操作：搜索当前写入的业务打点，选中并放大，以结束时刻对齐应用 UI 线程，向右找到第一个适用的 `ReceiveVsync`，选中完整区间读取 Duration。比较修改前后相同动作的多次结果，评价帧总处理耗时；写入已位于帧区间内时按实际更新位置选择对应帧。
4. **具体打点（可选）**：需要核对状态范围时，搜索 `ViewPU.viewPropertyHasChanged` 并用当前类名、状态名过滤；**状态名后第一个数字，即事件名后第 3 项，是本次通知的依赖元素数量**。预期仅依赖未变化字段的绑定被排除，同时读取变化字段的绑定仍保留。需要进一步确认具体组件时，再展开目标更新帧中的 `CustomNodeUpdate` / `ExecuteJS[rerender]`，按已确认的组件事件与现场元素 ID 核对。只展开当前验证需要的字段，运行时 ID 从实际录制读取。

具体打点用于核对同一动作下，实际依赖变化字段的绑定是否保留、只依赖未变化字段的绑定是否从通知及后续更新中排除。按元素身份核对目标区间，排除首次构建、其他页面/实例和其他写入。`CustomNodeUpdate` 的原生节点 ID 与 ViewPU 实例 ID 分别识别；入口中的 create 标签也可能出现在更新路径，不能据此断言分配新节点。整体收益使用前述完整帧区间比较，按实际更新帧关联。

事件可见性依赖版本和调试/采集配置。缺事件先核对条件；替代方法需能直接观测当前指标，缺少可靠观测时说明需要补充的采集条件。方案 B 不沿用 V1 事件作为验收条件。
