# ArkUI 基本语法与装饰器（写程序必读）

权威：[基本语法概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-basic-syntax-overview)、[UI装饰器总览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-decorator-overview)、[创建自定义组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-create-custom-components)、[TS→ArkTS 适配](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/typescript-to-arkts-migration-guide)。本页是摘要，不是官网全文。

**禁止**用 JS Lite（`.hml` + `export default { data }` + `$refs`）。本 skill 只写 Stage ArkTS `.ets`。

写程序默认 **V1**：`@Entry` + `@Component` + 需要刷新 UI 时才 `@State`。不要默认 `@ComponentV2` / `@Local`。

单装饰器细节按下面总表去读官网专章，不要把专章全文塞进本 skill。

## 页面最小组成

- **UI 装饰器**：给 struct / 变量赋含义。`@Component` = 自定义组件，`@Entry` = 该页入口，`@State` = 变化会刷 UI。
- **UI 描述**：`build()` 里声明式写组件树。
- **系统组件**：`Column` / `Row` / `Text` / `Button` 等；属性、事件链式调用（`.fontSize()` / `.onClick()`）。

```ts
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  private started: boolean = false; // 控制器/标志：普通字段
  @State label: string = 'idle';    // 只有要刷 UI 才 @State

  private async start(): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.label = 'starting';
  }

  build() {
    Column() {
      Text(this.label)
      Button('start').onClick(() => { this.start(); })
    }
    .width('100%')
    .height('100%')
  }
}
```

规则：

- 自定义组件 = `struct`，不能继承；不要与系统组件同名。
- 一个 `.ets` 页面只允许一个 `@Entry`。
- `@Entry` 的 `build()` 根节点必须唯一，且必须是容器组件（`ForEach` 不能当根）。
- `build()` 里禁止声明本地变量、禁止直接 `console.info`（放到方法里）。
- Kit 用 `import { x } from '@kit.ArkUI'` / `@kit.AbilityKit`，不要编相对路径当 Kit。
- 颜色/字号/边距按 [ui-style.md](ui-style.md)，不要裸 Button、不要 `fontSize(50)`。
- 控制器（`PiPController` 等）用普通成员，不要 `@State`。
- 回调参数写具体类型，禁止 `any` / `unknown`。
- 对象字面量按接口字段写；不能给未声明属性。
- `aboutToAppear` 在首次 `build()` 之前，**不是**主窗已 show。start 见 [stage-layout.md](stage-layout.md)。

## 写出来必须能编过（ArkTS）

写程序只抄 [assets/](../../assets/skeleton.md)，**不要**把 `js-apis-*.md` 示例当可粘贴代码。

- 会抛的 API 必须 `try/catch`，`const err = e as BusinessError`：`getWindowId`、`requestPermissionsFromUser`、`createAVPlayer`、`getRawFd`、`setVolume`、`off*`
- `getWindowId()` 是 `number | undefined`，`!== undefined` 再传；禁止 `as number`（运行时 10605999）
- 应用侧 PiP 只写 `setAutoStartEnabled`，禁止 `setAutoStart`
- 进 PipHost：`this.getUIContext().getRouter().pushUrl(...)`，不要顶层 deprecated `router.pushUrl`
- XComponent 用 `XComponent(this.options)`（`XComponentOptions`），不要旧 `{ id, type, controller }`
- Kit 用 `@kit.*`；防窥 `import { dlpAntiPeep } from '@kit.DeviceSecurityKit'`。工程没有该 DTS 则整段不生成，上屏说明缺 SDK，不要编假 API

## 通用 UI 装饰器

| 装饰器 | 说明 |
|--------|------|
| `@Entry` | 标记页面入口。一页只能有一个。 |
| `@Builder` | 自定义构建函数，封装一段 UI 描述。 |
| `@LocalBuilder` | 维持组件关系的 Builder。 |
| `@BuilderParam` | 引用 `@Builder` 函数。 |
| `@Styles` | 定义可复用样式。 |
| `@Extend` | 扩展某个系统组件的样式。 |
| `@AnimatableExtend` | 定义可动画属性。 |
| `@Require` | 校验构造传参必填。 |
| `@Env` | 环境变量。 |

## V1 状态管理（默认用这套）

| 装饰器 | 说明 |
|--------|------|
| `@Component` | 创建自定义组件。 |
| `@State` | 组件内部基础状态，变化刷 UI。 |
| `@Prop` | 父→子单向同步。 |
| `@Link` | 父子双向同步。 |
| `@ObjectLink` | 观察嵌套类对象属性。 |
| `@Provide` | 向后代双向同步。 |
| `@Consume` | 从祖先双向同步。 |
| `@Watch` | 状态变化监听。 |
| `@StorageLink` | 与 AppStorage 双向。 |
| `@StorageProp` | 与 AppStorage 单向。 |
| `@LocalStorageLink` | 与 LocalStorage 双向。 |
| `@LocalStorageProp` | 与 LocalStorage 单向。 |
| `@Observed` | 标记类可观察。 |
| `@Track` | 类属性级更新。 |
| `@Reusable` | 标记 V1 组件可复用。 |

## V2 状态管理（用户点名 V2 才用）

| 装饰器 | 说明 |
|--------|------|
| `@ComponentV2` | 创建 V2 自定义组件。 |
| `@Local` | 组件内部状态。 |
| `@Param` | 组件外部输入。 |
| `@Once` | 初始化同步一次。 |
| `@Event` | 规范组件输出。 |
| `@Provider` | 与后代双向同步。 |
| `@Consumer` | 与祖先双向同步。 |
| `@Monitor` | 状态修改异步监听。 |
| `@SyncMonitor` | 状态修改同步监听。 |
| `@Computed` | 计算属性。 |
| `@ObservedV2` | 标记类可观察。 |
| `@Trace` | 标记类属性可观察。 |
| `@Type` | 标记类属性类型。 |
| `@ReusableV2` | 标记 V2 组件可复用。 |

不要把 V1 和 V2 装饰器混在同一个组件上。
