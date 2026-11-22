# 纯展示组件与 @Builder

## 成立条件

检查自定义组件的定义和所有相关调用点。数据由父组件持有，子组件只组合 UI，没有本地编辑/派生状态、独立生命周期工作、订阅/资源清理或必须保留的实例职责时，可评估改为 @Builder。重复创建多个轻量展示包装时，减少自定义组件实例与状态管理的开销可能有价值；单个简单组件也可以保留封装，不凭“只有 build”认定性能瓶颈。

@Builder 复用的是 UI 描述代码，不等于 @Reusable 的实例/子树缓存。已有复用组件、冻结边界、Provide/Consume、嵌套子组件的父级关系或独立更新边界时，先确认替换的语义和成本，不能为了少一个 struct 删除必要职责。自定义组件通常也不是一个额外的渲染布局节点，不能声称改 Builder 就必然减少一层 Measure/Layout。

## 检查与建议

- 无独立状态变化的固定内容，可使用全局 @Builder。
- 展示所属父组件的可变状态，可使用局部 @Builder 直接读取 `this` 上的状态。状态管理 V1 中，把 `@Prop text` 机械改成 `builder(this.text)` 的简单值传参可能失去后续刷新，不能仅凭初次显示正确验收。
- 跨组件构建函数需按状态管理版本和目标 API 核对引用传参或 Binding；API 20+ 的 makeBinding 不能用于最低 API 12 的默认方案。RepeatItem 的绑定另见[复用与 key](reuse-and-keys.md)。
- 保留原有样式、尺寸、点击对象、回调 this 和父子数据写入方向。自定义组件调用处的通用属性不能直接照搬到 Builder 调用上；应核对并施加到等价的根布局节点。

## Bad case

前提：状态管理 V1，父组件是唯一数据拥有者，Footer 只显示 text，没有编辑、生命周期或复用职责。

```ts
@Component
struct Footer {
  @Prop text: string = '';
  build() {
    Row() { Text(this.text).fontSize(12) }
      .justifyContent(FlexAlign.Center).width('100%').height(51)
  }
}
// 父 build 中：Footer({ text: this.footerText })
```

## Good case

可在原父组件内改为局部 @Builder：

```ts
@Builder
footer() {
  Row() { Text(this.footerText).fontSize(12) }
    .justifyContent(FlexAlign.Center).width('100%').height(51)
}
// 父 build 中：this.footer()
```

这里 `footerText` 仍由父状态持有；不是把它保存为 Builder 的普通值快照。一个保持挂载的子组件与多个重复创建的展示包装，潜在收益不同；给出可简化的候选建议，不把无测量的候选写成已发生的卡顿。

## 合理保留与验证

子组件管理展开/折叠、本地输入状态、计时器/订阅或独立实例状态时，保留自定义组件是正常写法，不能仅因具有展示内容就要求改为 Builder。没有生命周期不代表没有本地状态；也不为满足替换建议把全部状态无条件上移。

功能回归覆盖初始显示、父值更新、隐藏期间更新后重新显示、事件身份以及原有布局。性能比较在相同构建、数据和动作下检查创建及状态传递相关工作；保留设备/Trace 证据，未测量不承诺耗时、节点数或帧率收益。

## 打点与预期变化

整体收益是减少展示包装组件的实例创建和状态传递工作，原有 Row/Text 等 UI 节点仍然存在。适用的日志方法可在原组件初始化位置记录次数；Trace 方法在触发显示或父值更新的实际代码前后加入成对业务打点，按[定位更新帧的方法](../verification.md#如何定位动作后的更新帧)比较完整 ReceiveVsync 的 Duration。按相同数据与动作重复比较，不把包装实例减少说成原生节点必然减少。对具有本地展开状态的合理反例，保留组件即可，不要求降低构建次数。
