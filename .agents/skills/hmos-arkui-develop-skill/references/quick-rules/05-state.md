# 5. 状态管理（V1 + V2 + 混用）

> 本节包含 V1 装饰器、V2 装饰器、V1/V2 混用约束三部分。选 V1 范式读 V1 节，选 V2 范式读 V2 节，涉及跨版本传值时读混用节。

---

## V1 装饰器

### @State

| 规则 | 说明 |
|------|------|
| 观察第一层 | 仅能观察到第一层的变化（赋值、数组项增删、Map/Set API 调用） |
| 嵌套对象需 @Observed/@ObjectLink | 深层属性变化无法被观察到，需要配合 @Observed 装饰类 + @ObjectLink 子组件 |
| 嵌套数组属性 push/splice 不刷新 | `project.tasks.push()` 不刷新（数组引用未变）；需数组为 `@Observed class extends Array` + 子组件 `@ObjectLink` 接收数组实例本身 |
| 聚合值不自动刷新 | 已完成数/总进度无法自动观测子项属性变化，需通过回调手动 recompute |
| 不支持 undefined/null 类型 | 用具体类型 + 真实默认值 |

### @Prop

| 规则 | 说明 |
|------|------|
| 单向同步 | 本地修改会被父组件更新覆盖 |
| 允许本地初始化 | 也可被外部初始化 |
| 拷贝数据源 | @Prop 装饰的变量在本地拷贝了数据源 |
| 本地有初始化则可选 | 初始化行为与 @State 一致；可被父组件传入覆盖 |
| 本地无初始化则必选 | 必须由父组件传入 |
| 支持父组件常规变量 | 常规变量对 @Prop 只做数值初始化，其变化不触发 UI 刷新；只有状态变量（@State 等）变化才触发刷新 |

### @Link

| 规则 | 说明 |
|------|------|
| **必须外部初始化**，禁止本地初始化 | `@Link count: number = 0` 禁止 |
| 与数据源双向同步 | |
| 只能被 V1 状态变量初始化 | |
| 初始化语法 | 推荐 `Comp({ aLink: this.aState })`，不推荐 API9 前 `Comp({ aLink: $aState })` |

### @ObjectLink

| 规则 | 说明 |
|------|------|
| **禁止本地初始化** | 必须从父组件传入 |
| **禁止整体赋值** | `this.objLink = ...` 不允许，只允许修改属性 |
| API 19 前类型必须为 `@Observed` class 实例 | 否则运行时告警且不刷新 |
| **不支持简单类型** | number/string/boolean 不能用 @ObjectLink，用 @Prop |

### @Observed

| 规则 | 说明 |
|------|------|
| 装饰 class | 嵌套场景下，非简单类型的属性也需要被 @Observed 装饰 |
| 构造函数内修改成员不刷新 | 构造时实例尚未被代理，`this` 是原始对象，赋值不触发通知。只初始化，可变逻辑移到普通方法 |

### @Provide / @Consume

| 规则 | 说明 |
|------|------|
| @Consume 不可以被外部初始化 | |
| @Provide 可被外部初始化，也可本地初始化 | |
| @Provide key 重复 | key 重复定义时框架抛运行时错误；需重复 key 用 `allowOverride` |

### @StorageLink / @StorageProp / @LocalStorageLink / @LocalStorageProp

- 不可以被外部初始化，与 AppStorage/LocalStorage 自动绑定
- V1 storage API不能和@ObservedV2装饰类的实例混用：`AppStorage.setOrCreate`/`set`、`LocalStorage` 都是 V1 观察体系，存入 @ObservedV2 装饰的类对象后会发生运行时crash。@ObservedV2 对象走 `AppStorageV2`/`PersistenceV2`（仅 @ComponentV2 内）

### @Watch

- **严格禁止**在 @Watch 回调中修改**自身被监视的变量**，否则无限循环
- @Watch 只放纯逻辑，**不在其中调 @Builder**（刷新异常）

### 装饰器通用规则

- **每个属性只能用一个装饰器**，禁止叠加（如 `@State @Watch('fn') count: number = 0` 是合法的，但 `@State @Local count: number = 0` 报错）
- 一个属性不能同时被两个状态装饰器装饰

### 类型注解必填
> 状态变量类型注解规则见 [00-arkts-syntax](00-arkts-syntax.md) Types 节（必须显式类型、禁止 any、对象字面量约束）。

### 访问限定符约束

| 装饰器 | 允许 | 禁止 |
|--------|------|------|
| @State/@Prop/@Provide/@BuilderParam/常规变量 | 默认/public/private（private 阻止外部初始化） | protected（struct 无继承） |
| @StorageLink/@StorageProp/@LocalStorageLink/@LocalStorageProp/@Consume | 默认/private | public/protected |
| @Link/@ObjectLink | 默认/public | **private**（必须外部初始化）/protected |
| @Require + @State/@Prop/@Provide/@BuilderParam | 默认/public | **private**（与 @Require 矛盾）/protected |
| 所有装饰器 | — | **protected**（struct 无继承，所有 protected 产生告警） |

---

## @Builder 参数传递

### 三种传递方式

| 方式 | 调用形式 | 状态变化刷新 | 用途 |
|------|---------|:-----------:|------|
| 按值（默认） | `builder(this.label)` 或 `builder(s: string)` | ❌ 不刷新 | 不依赖状态/仅初始渲染 |
| 按引用 | `builder({ k: this.label })`（单参数 + 对象字面量） | ✅ 刷新 | 依赖状态需刷新 |
| 按回调 (API 20+) | `builder(UIUtils.makeBinding(getter, setter))` | ✅ 刷新且可回写 | Builder 内需修改入参 |

### 关键规则

| 规则 | 说明 |
|------|------|
| 形参类型必须是已声明的 interface/class | 禁止 `$$: { x: T }` 内联对象字面量 → **10605040** |
| **两个及以上参数不触发刷新** | 多参数、按值与按引用混用均不刷新，需合并为单个对象参数 |
| **@Builder 内禁止修改入参** | 简单类型不刷新，对象类型改属性报 **140109**（API 23+） |
| Builder 内创建子组件**不要传整个对象** | 拆成简单类型属性分别传入 |
| **禁止**在 UI 语句外调用 @Builder | 赋值给变量/数组后刷新异常 |
| **禁止**在 @Watch 回调内调 @Builder | 导致 UI 刷新异常 |
| `wrapBuilder` 泛型**必须是 tuple `[T]`** | 不能是 `WrappedBuilder<T>`，漏 `[]` 报 **10505001** |
| 尾随 lambda 调用自定义组件时，该组件必须且只能有一个 @BuilderParam | 多个槽位改用普通具名参数传 Builder |

### wrapBuilder 正确用法

```ts
// WRONG - 泛型漏 []
const w: WrappedBuilder<CardData> = wrapBuilder(CardBuilder)   // ❌ 10505001

// RIGHT - 泛型写成 tuple [CardData]
const w: WrappedBuilder<[CardData]> = wrapBuilder(CardBuilder) // ✅
w.builder({ text: item })                                      // ✅ 调用 builder 方法
```

---

## @Extend / @Styles

> 完整 @Extend/@Styles 规则见 [10-style](10-style.md)（仅全局定义、省略返回类型、禁止嵌套函数、动画约束）。

---

## @Observed / @ObjectLink 不刷新排查

### 常见场景

| 场景 | 根因 | 解决 |
|------|------|------|
| 嵌套对象第二层不刷新 | @State 只代理第一层，`cousin.child.childId` 是第二层 | 内层类 @Observed + 子组件 @ObjectLink |
| @ObjectLink 整体赋值报错 | @ObjectLink 只读引用，`this.num = new Info()` 打断同步链 | 改属性；整体替换在父组件做 |
| 两层以上嵌套 | @ObjectLink 只代理直接接收的类 | N 层嵌套需要 N 个 @Observed + N 层 @ObjectLink 子组件 |
| 构造函数内修改不刷新 | 构造时实例未代理，`this` 是原始对象 | 构造函数只初始化，可变逻辑移到普通方法 |
| 嵌套数组属性 push/splice 不刷新 | 数组引用未变，@State 第一层观测不到 | 需 `@Observed class extends Array` + 子组件 @ObjectLink 接收数组实例 |
| 聚合值不刷新 | 深层属性变化父组件观测不到 | 聚合值存 @State，子项变化通过回调手动 recompute |
| LazyForEach 替换数组项不刷新 | LazyForEach 不监听 dataSource 内部变化 | 替换后调 `dataSource.notifyDataChanged(i)` |
| 同步渲染回调内改状态 |触发 "state changed during render"，刷新被忽略 | 用 `setTimeout` 异步化 |

### 排查五步法

1. **依赖是否收集**：状态变量是否在 build 中被读取（ArkUI Inspector 查依赖）
2. **值是否真变化**：打印赋值前后值
3. **赋值是否可观察**：`UIUtils.getTarget(obj) === obj`（false = 已代理可观察）；@ObservedV2 场景检查属性是否 @Trace
4. **数据源与同步对象是否关联**：ForEach/LazyForEach 替换项后是否断链（`util.getHash` 比较引用）
5. **组件更新函数是否执行**：是否在渲染回调中改了状态导致本次刷新被忽略

---

## V2 装饰器

### @ObservedV2 / @Trace

| 规则 | 说明 |
|------|------|
| @ObservedV2 装饰 class，@Trace 装饰被观察属性 | V1 装饰器不能和 @ObservedV2 一起使用 |
| 深度观察需每层 @ObservedV2 + @Trace | 每一层 class 都要装饰 |

### @Local

| 规则 | 说明 |
|------|------|
| **必须在组件内部初始化** | 不允许从外部传入初始化 |

### @Param

| 规则 | 说明 |
|------|------|
| 可从父组件传入 | 默认单向同步（父到子） |
| 配合 @Event 实现双向同步 | |
| **@Param 只读** | 禁止在组件内重新赋值（`this.x = ...` 报 `Cannot assign to 'x' because it is a read-only property`） |

### @Once

| 规则 | 说明 |
|------|------|
| 仅在组件首次创建时接收参数 | 后续父组件变化不更新 |

### @Event

| 规则 | 说明 |
|------|------|
| 配合 @Param 实现子到父的回调通知 | |

### @Provider / @Consumer (V2)

| 规则 | 说明 |
|------|------|
| @Provider 注入，@Consumer 消费 | 跨层级数据传递 |

### @Computed (V2)

| 规则 | 说明 |
|------|------|
| 计算属性装饰器，自动缓存 | 仅在依赖的 @Trace 属性变化时重新计算 |

### @Monitor (V2) / addMonitor / clearMonitor

| 规则 | 说明 | 错误码 |
|------|------|--------|
| addMonitor/clearMonitor 目标必须是 @ObservedV2 class（带 @Trace）或 @ComponentV2 实例 | **130000** |
| 回调必须是**命名函数**，不能是匿名函数 | **130002** |
| IMonitor 取值用 `mon.value<T>()?.now`，不是 `.after` | |

```ts
// ❌ WRONG -- IMonitor 没有 'after'，且漏泛型参数
@Monitor('searchKeywordValue')
onSearchKeywordChange(mon: IMonitor): void {
  let keyword: string = mon.value?.after ?? ''           // ❌
  let keyword2: string = mon.value<string>().after ?? '' // ❌
}

// ✅ RIGHT -- 属性是 now，传类型参数
@Monitor('searchKeywordValue')
onSearchKeywordChange(mon: IMonitor): void {
  let keyword: string = mon.value<string>()?.now ?? ''    // ✅
  let before: string = mon.value<string>()?.before ?? ''  // ✅
}
```

### makeObserved

| 规则 | 说明 |
|------|------|
| 将普通对象转为 V2 可观测对象 | |
| 不支持 collections 类型和 @Sendable 装饰的 class | |
| 不支持非 object 类型、undefined、null | |
| 不支持 @ObservedV2 装饰的类 | |

### applySyncUpdates / flushUpdates / flushUIUpdates

| 规则 | 说明 |
|------|------|
| 手动触发 V2 状态更新 | 在非 UI 线程修改状态后须手动调用刷新 UI |

### 普通（未装饰）成员禁止外部初始化

`@ComponentV2` 内未装饰的普通成员变量只能在内部初始化，**禁止在调用处赋值**（`MyComp({ plain: 1 })` 不刷新且可能报错）。需从父组件传入的值必须用 `@Param` 装饰。

---

## V1/V2 混用

| 规则 | 说明 | 错误码 |
|------|------|--------|
| V1 装饰器禁止与 @ObservedV2 混用 | 维持禁止 | 编译错 |
| V2 → V1 禁止用装饰器直接接收 | V1 不支持用装饰器直接接收 @ObservedV2 装饰的 class | 编译错 |
| V1 @Link 只能被 V1 状态变量初始化 | | |
| V1→V2 需调 `enableV2Compatibility` | V1 状态变量传递到 V2 组件时，需调用 `UIUtils.enableV2Compatibility()` | |
| V2→V1 需调 `makeV1Observed` | V2 中优先声明成 V1 状态变量数据，并调用 `UIUtils.enableV2Compatibility(UIUtils.makeV1Observed())` | |
| 建议在 V2 组件构造处调用 | 避免变量被整体赋值后需要再次手动调用 | |
| 禁止双重代理 | 不使用 enableV2Compatibility 和 makeV1Observed 会导致双重代理问题 | |

### 装饰器归属表

| 装饰器 | `@Component` (V1) | `@ComponentV2` (V2) |
|--------|:-----------------:|:-------------------:|
| @State/@Prop/@Link/@ObjectLink/@Provide/@Consume/@Watch | ✅ | ❌ 编译错 |
| @StorageLink/@StorageProp/@LocalStorageLink/@LocalStorageProp | ✅ | ❌ |
| @Local/@Param/@Once/@Event/@Provider/@Consumer/@Computed/@Monitor | ❌ 编译错 | ✅ |
| @ObservedV2/@Trace | ❌ | ✅ |
| @Builder/@BuilderParam/@Extend/@Styles/@Require | ✅ | ✅ |

---

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| `@State` 装饰组件入参 | @State 只能装饰内部变量，入参用 @Prop/@Param | 装饰器位置错误 |
| `@Link count: number = 0` | `@Link count: number` | @Link 禁止本地初始化 |
| `@ObjectLink info: Info = new Info()` | `@ObjectLink info: Info` | @ObjectLink 禁止本地初始化 |
| `@ObjectLink num: number` | @ObjectLink 不支持简单类型 | 用 @Prop 替代 |
| `@Consume theme: string = 'dark'` | `@Consume theme: string` | @Consume 禁止初始化 |
| `@Builder fn(s: string) { Text(s) }` 按值调用 `fn(this.label)` | 改单参数对象字面量按引用调用 | 按值不刷新 |
| `@Builder fn(a: A, b: B) { ... }` 两个参数 | 合并为单个对象参数 | 多参数不刷新 |
| Builder 内 `param.paramA = 'Yes'` | 用 MutableBinding 回调 | API 23 起报 140109 |
| `@Watch` 回调内调 `@Builder` | @Watch 只做逻辑，Builder 在 build 中调 | 刷新异常 |
| Builder 赋值给 `Array<CustomBuilder>` | 直接调用或传方法引用 | 刷新异常 |
| `@Observed 类构造函数内改 this 属性` | 构造函数只初始化，可变逻辑移到普通方法 | 实例未代理 |
| `@ComponentV2` 里用 `@State` | 用 @Local/@Param 等 V2 装饰器 | 混用编译错 |
| `@Component` 里用 `@Local` | 用 @State/@Prop 等 V1 装饰器 | 混用编译错 |
| 不调用 `enableV2Compatibility` 就跨 V1/V2 传值 | 需要兼容桥接 | 双重代理 |
| `@Local name: string` 在调用处 `<MyComp({ name: 'x' })>` | `@Param name: string` | @Local 只能内部初始化 |

## 参考

- 错误码：**10505001**（成员名与链式方法冲突）、**10605040**（内联对象字面量作类型）、**140109**（Builder 内修改入参）
- @Extend/@Styles 完整规则见 [10-style](10-style.md)
- 类型注解完整规则见 [00-arkts-syntax](00-arkts-syntax.md) Types 节