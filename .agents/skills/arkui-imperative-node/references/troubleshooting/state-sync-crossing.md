# @Link/@Consume 状态同步跨界检查

## 检查条件

代码中 BuilderNode 内部的自定义组件使用了 `@Link`、`@Consume`、`@Provide` 等状态同步装饰器，试图与 BuilderNode 外部的组件建立双向同步或跨层传递。凡 BuilderNode 内部组件使用状态同步装饰器的位置，都需检查是否跨 BuilderNode 边界。

## 检查步骤

1. **检查 @Link 是否跨 BuilderNode 边界**：对 BuilderNode 内部自定义组件（@Component）使用的 `@Link` 装饰器，检查其同步源是否在 BuilderNode 外部。BuilderNode **不支持** `@Link` 跨越 BuilderNode 同步外界数据和状态（V1/V2 均不支持）。BuilderNode 隔断声明式状态树的父子双向同步链路，`@Link` 找不到父组件的同步源。
2. **检查 @Consume/@Provide 是否跨 BuilderNode 边界**：对 BuilderNode 内部自定义组件使用的 `@Consume`，检查其数据源 `@Provide` 是否在 BuilderNode 外部。默认情况下 BuilderNode 隔断 `@Consume`/`@Provide` 跨边界传递。从 **API 20** 开始，可通过配置 `BuildOptions.enableProvideConsumeCrossing = true` 开启跨 BuilderNode 边界的 `@Consume`/`@Provide` 传递（V1 `@Consume`/`@Provide` 需 API 20+；V2 `@Consumer`/`@Provider` 需 API 23+）。
3. **检查 @Consume 变量是否设置了默认值（关键，实测确认）**：跨界连接是**延迟建立**的——build() 在 BuilderNode 挂到组件树**之前**执行，此时外部 @Provide 尚不可达；BuilderNode 挂树之后 @Consume 才重新解析并连接外部 @Provide。因此 `@Consume` 变量**必须设置默认值**（如 `@Consume('themeColor') themeColor: number = 0xFF0000FF;`）。API 20 起 @Consume 支持默认值：无默认值且找不到 @Provide 时会直接抛异常 140112（`Fail to resolve @Consume`），根本等不到挂树后的重连。官方示例中 @Consume 均带本地默认值。
4. **检查支持的替代方案**：`@Prop`（V1）/ `@Param`（V2）是 BuilderNode 内部组件**支持**的单向数据传递方式。通过 `builderNode.update(new Params(...))` 传入新参数，`@Prop`/`@Param` 装饰的变量会同步更新。

## 诊断与修复

### 发现问题时

- **诊断**：BuilderNode 内部组件使用 @Link/@Consume 试图与外界同步数据，但状态不更新。
- **原因**：
  - @Link 隔断：BuilderNode 隔断声明式组件树的父子双向同步链路，@Link 依赖的父子同步关系在 BuilderNode 边界失效。
  - @Consume/@Provide 隔断：默认情况下 BuilderNode 隔断跨层同步，@Consume 找不到外部的 @Provide。
- **修复方向**：
  - **@Link**：移除 @Link，改用 @Prop（V1）/ @Param（V2）单向传递，通过 `update()` 接口传值。
  - **@Consume/@Provide**：需同时满足两点（缺一不可）：
    1. build 时配置 `BuildOptions { enableProvideConsumeCrossing: true }`（API 20+）；
    2. **@Consume 变量设置默认值**（挂树前找不到外部 @Provide，无默认值会抛 140112 异常；挂树后自动重连外部 @Provide 实现双向同步）。
    未配置或 API < 20 时，改用 @Prop/@Param 参数传递。
- **修复代码模式**：
```typescript
// ❌ @Link 跨 BuilderNode 不生效
@Component
struct ChildComponent {
  @Link count: number;  // 找不到 BuilderNode 外的同步源
  build() { Text(`${this.count}`) }
}

// ✅ 改用 @Prop + update 传值
@Component
struct ChildComponent {
  @Prop count: number = 0;  // 单向传递，通过 update 刷新
  build() { Text(`${this.count}`) }
}

// ✅ @Consume 跨界（API 20+，两处改动缺一不可）
@Component
struct InnerComponent {
  // ② 必须设置默认值：build 时（挂树前）外部 @Provide 不可达，
  //    无默认值会抛 140112；挂树后重连外部 @Provide
  @Consume('themeColor') themeColor: number = 0xFF0000FF;
  build() { Text('color').fontColor(this.themeColor) }
}

class ConsumeFailController extends NodeController {
  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    // ① 开启跨 BuilderNode 边界的 @Consume/@Provide 同步
    const options: BuildOptions = { enableProvideConsumeCrossing: true };
    this.builderNode.build(wrapBuilder(buildContent), new Params(), options);
    return this.builderNode.getFrameNode();
  }
}
```

### 未发现问题时

BuilderNode 内部组件未使用 @Link/@Consume，或已改用 @Prop/@Param 单向传递，或已配置 enableProvideConsumeCrossing=true（API 20+）。不报告。

## 规则依据

- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：说明章节——"@Prop 支持使用、@Link 不支持"；"从API version 20开始，通过配置BuildOptions，内部自定义组件的@Consume支持接收所在页面的@Provide数据"；BuildOptions.enableProvideConsumeCrossing 字段说明；示例5中 @Consume 带本地默认值。
- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："设置BuilderNode支持内部@Consume接收外部的@Provide数据（状态管理V1）"章节。
- [@Provider/@Consumer 文档](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-provider-and-consumer.md)："在BuilderNode挂载到自定义组件节点树之后，@Consumer会重新获取最近的@Provider数据"（跨界连接延迟建立）；V1/V2 对比表——"从API version 20开始，@Consume支持设置默认值，如果没有设置默认值，且找不到对应@Provide时，会抛出异常"（实测确认：无默认值时 makeNode 内 build 即抛 140112）。
