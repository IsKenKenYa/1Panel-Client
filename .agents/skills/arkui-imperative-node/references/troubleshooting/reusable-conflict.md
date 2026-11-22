# @Reusable/@ReusableV2 冲突检查

## 检查条件

代码中 BuilderNode 的 `@Builder` 内部使用了自定义组件（即 `@Builder` 函数体内出现了 `@Component` / `@ComponentV2` / `@Reusable` / `@ReusableV2` 装饰的自定义组件调用）。凡 BuilderNode 内部嵌套自定义组件的位置，都需检查 @Reusable / @ReusableV2 装饰器使用是否符合 BuilderNode 的支持范围。

## 检查步骤

1. **检查 @Reusable（V1）装饰器**：对 BuilderNode 的 `@Builder` 内部直接子自定义组件，检查是否标记了 `@Reusable`。BuilderNode 的**直接子自定义组件**不支持 `@Reusable`，否则两套复用机制冲突会导致 JSCrash。
   - 判断"直接子"：`@Builder` 函数体顶层调用的自定义组件即为直接子；若直接子内部再嵌套 `@Reusable` 组件则不受此限制。
2. **检查 @ReusableV2（V2）装饰器**：对 BuilderNode 的 `@Builder` 内部直接子自定义组件，检查是否标记了 `@ReusableV2`。**@ReusableV2 同样不支持在 BuilderNode 直接子组件上使用，也会导致 JSCrash**，与 @Reusable（V1）行为一致。虽然 API 文档标注从 API 26 开始 BuilderNode 支持 V2 组件复用，但实测 @ReusableV2 直接子组件仍会 JSCrash，需用普通组件包裹。
   - 区分依据：`@Reusable` 装饰 `@Component`（V1）→ JSCrash；`@ReusableV2` 装饰 `@ComponentV2`（V2）→ 同样 JSCrash。两者均需用普通组件包裹。
3. **检查 @ComponentV2 使用**：BuilderNode 的 `@Builder` 内部可以使用 `@ComponentV2` 装饰的**普通**自定义组件（未标记 @ReusableV2），这是支持的。`@ComponentV2` 组件可作为 BuilderNode 内部组件正常使用，包括 @Param、@Local、@Monitor、@Computed 等 V2 状态管理能力。

## 诊断与修复

### 发现问题时

- **诊断**：BuilderNode 内部直接子自定义组件使用了 `@Reusable`（V1）或 `@ReusableV2`（V2）导致 JSCrash。
- **原因**：BuilderNode 的复用机制与 `@Reusable` / `@ReusableV2` 装饰器的复用机制相互冲突——BuilderNode 直接子节点同时走 BuilderNode 的 reuse/recycle 与 @Reusable 的复用机制，两套机制冲突导致 JSCrash。
- **修复方向**：用**未标记复用装饰器的普通自定义组件**包裹复用组件，使复用组件不直接挂在 BuilderNode 下。V1 和 V2 行为一致，均需包裹。
- **修复代码模式**：
```typescript
// 模式一：V1 @Reusable 冲突 → 普通自定义组件包裹
@Builder
function buildNode(param: Params) {
  WrapperComponent({ item: param.item }) // 未标记 @Reusable 的普通组件作为直接子
}

@Component
struct WrapperComponent {
  @Prop item: string = '';
  build() {
    ReusableChildComponent({ item: this.item }) // @Reusable 组件在普通组件内部
  }
}

// 模式二：V2 @ReusableV2 同样需要包裹（实测 V1/V2 都 JSCrash）
@Builder
function buildNode(param: Params) {
  WrapperComponentV2({ item: param.item }) // 未标记 @ReusableV2 的普通 V2 组件作为直接子
}

@ComponentV2
struct WrapperComponentV2 {
  @Param item: string = '';
  build() {
    ReusableV2Component({ item: this.item }) // @ReusableV2 组件在普通组件内部
  }
}

@ReusableV2
@ComponentV2
struct ReusableV2Component {
  @Param item: string = '';
  build() { Text(this.item) }
}
```

### 未发现问题时

BuilderNode 的直接子自定义组件未标记 `@Reusable` 或 `@ReusableV2`（复用组件被普通组件包裹在内部）。不报告。

## 规则依据

- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："BuilderNode 在子自定义组件中使用 @Reusable 装饰器"章节——直接子不支持 @Reusable；"BuilderNode 调用 reuse 和 recycle 接口实现节点复用能力"章节——手动传递复用事件。
- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：说明章节——@Reusable 不支持。API 文档标注从 API 26 开始支持 V2 组件复用，但实测 @ReusableV2 直接子组件仍会 JSCrash。
- [@ReusableV2 装饰器](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-reusableV2.md)：@ReusableV2 装饰 @ComponentV2，V2 复用装饰器。实测在 BuilderNode 直接子组件上使用会 JSCrash。
