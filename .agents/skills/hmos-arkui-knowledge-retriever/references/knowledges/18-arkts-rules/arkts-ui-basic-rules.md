# ArkTS 自定义组件规则要求

---

## 1. 自定义组件支持跨 Ability 迁移

### 1.1 基本规则

API version 24 前，自定义组件不支持跨 Ability 迁移。自定义组件实例在跨 Ability 后，改变自定义组件的状态变量将无法触发 UI 组件刷新。在系统升级 API version 24 之前，即使在 module.json5 配置了 `"enableCustomComponentCrossAbility"` 为 `"true"`，该能力也不会生效。

API version 24 开始，可在应用工程的 module.json5 配置文件中配置 metadata 标签来使能自定义组件支持跨 Ability 迁移。具体配置方式如下：

```json
"metadata": [
  {
    "name": "enableCustomComponentCrossAbility",
    "value": "true"
  }
]
```

### 1.2 注意事项

1. **不建议在原 Ability 的 onBackground 阶段异步修改迁移组件中的状态变量**，此时状态变量可以被赋值，但无法触发关联组件的刷新。
2. **仅支持组件树上的自定义组件迁移**。对于未挂载在组件树上的自定义组件将不支持迁移。例如使用 `OH_ArkUI_GetNodeHandleFromNapiValue` 获取 `ArkUI_NodeHandle` 场景中，如果 `OH_ArkUI_GetNodeHandleFromNapiValue` 接收的参数为 `ComponentContent`，获取到的 `ArkUI_NodeHandle` 为 `ComponentContent` 下子树的第一个 `FrameNode` 节点，中间跳过的自定义组件将不会在组件树上，不支持迁移。

### 1.3 跨 Ability 组件迁移的适用场景与目标

BuilderNode 通过 `new BuilderNode(uiContext)` 创建时，**会与当前 Ability 的 UIContext 强绑定**（组件的状态驱动、刷新调度、事件分发都依赖该上下文）。一旦将该 BuilderNode 迁移到**另一个 Ability** 的 NodeContainer 下显示：

- **未开启跨 Ability 迁移时**：组件实例虽然能渲染出来，但其内部自定义组件的状态变量（`@State` / `@Link` / `@ObjectLink` 等）变化**无法触发 UI 重新渲染**。

开启 `enableCustomComponentCrossAbility` 后，迁移后的组件才能与新 Ability 的 UIContext 协同工作，状态驱动刷新恢复正常。

---

## 2. 自定义组件生命周期总览

自定义组件生命周期分为两类：

- **页面级生命周期**：仅对 `@Entry` 装饰的组件生效，包括 `onPageShow`、`onPageHide`、`onBackPress`。
- **组件级生命周期**：对 `@Component` 或 `@ComponentV2` 装饰的组件生效，包括旧版（事件驱动）和新版（状态机驱动，API version 23+）两套。

### 2.1 页面级生命周期

| 回调 | 触发时机 | 适用范围 |
| --- | --- | --- |
| onPageShow | 页面每次显示时触发一次，包括路由跳转、应用进入前台 | 仅 `@Entry` 装饰的自定义组件 |
| onPageHide | 页面每次隐藏时触发一次，包括路由跳转、应用进入后台 | 仅 `@Entry` 装饰的自定义组件 |
| onBackPress | 用户点击返回按钮时触发。返回 true 表示页面自行处理返回逻辑；返回 false 或不设置返回值表示使用默认路由返回逻辑 | 仅 `@Entry` 装饰的自定义组件 |

### 2.2 组件级新旧对照

| 旧生命周期（事件驱动） | 新生命周期（状态机驱动，API 23+） | 说明 | 推荐用法 |
| --- | --- | --- | --- |
| aboutToAppear | @ComponentAppear | 新版本受状态机约束，不会误调用 | 注册监听、获取数据、修改状态变量 |
| onDidBuild | @ComponentBuilt | build 首次执行完成后回调 | 预热后续页面数据、埋点上报 |
| aboutToDisappear | @ComponentDisappear | 新版本不会误触发对应的 Appear 回调 | 清理资源、注销监听 |
| aboutToReuse | @ComponentReuse | 新版本在非 RECYCLED 状态时不会被误调用 | 重置组件状态、接收复用参数并刷新数据 |
| aboutToRecycle | @ComponentRecycle | 新版本受状态机约束 | 释放占用的临时对象、保存现场以便复用恢复 |
| 无 | @ComponentInit | 组件即将构造完毕时执行，可注册监听和修改变量 | 注册监听、获取数据、修改状态变量 |

> **说明**：`@ComponentInit` 与 `@ComponentAppear` 均适合做注册监听、获取数据、修改状态变量等初始化操作；二者区别在于 `@ComponentInit` 在组件构造阶段执行（build 之前），`@ComponentAppear` 在组件即将出现时执行。若需要在 build 完成后执行依赖首帧结果的逻辑（如预热后续页面数据、首屏埋点），应使用 `@ComponentBuilt`。组件销毁前应统一在 `@ComponentDisappear` 中清理资源、注销监听，避免内存泄漏。

### 2.3 生命周期状态机（API 23+）

自定义组件生命周期受状态机限制，共 4 个状态：INIT、APPEARED、BUILT、RECYCLED。仅在合法状态转换时触发回调，非法转换不执行。

**状态转换与触发的回调**：

| 状态转换 | 触发回调 | 说明 |
| --- | --- | --- |
| INIT → APPEARED | `@ComponentInit → @ComponentAppear` | 组件首次出现，创建实例后、build 前执行 |
| APPEARED → BUILT | `build() → @ComponentBuilt` | 首次渲染 build 完成后回调，后续重新渲染不再触发 |
| BUILT → RECYCLED | `@ComponentRecycle` | @Reusable 组件被回收进入缓存 |
| RECYCLED → BUILT | `@ComponentReuse → build()` | @Reusable 组件从缓存复用重新加入节点树 |
| INIT → 销毁 | `@ComponentDisappear` | 组件在 INIT 状态被销毁 |
| BUILT → 销毁 | `@ComponentDisappear` | 组件在 BUILT 状态被销毁 |
| RECYCLED → 销毁 | `@ComponentDisappear` | 组件在 RECYCLED 状态被销毁 |

**完整状态机链路**：

```
创建: INIT →(@ComponentInit)→ APPEARED →(build)→ BUILT
回收: BUILT →(@ComponentRecycle)→ RECYCLED
复用: RECYCLED →(@ComponentReuse)→ build →(@ComponentBuilt)→ BUILT
销毁: INIT/APPEARED/BUILT/RECYCLED →(@ComponentDisappear)→ 销毁
```

---

## 3. 新生命周期装饰器限制条件

新的自定义组件生命周期装饰器（API version 23+）包括：`@ComponentInit`、`@ComponentAppear`、`@ComponentBuilt`、`@ComponentDisappear`、`@ComponentReuse`、`@ComponentRecycle`。

### 3.1 使用范围限制

- `@ComponentInit`、`@ComponentAppear`、`@ComponentBuilt`、`@ComponentDisappear`、`@ComponentReuse` 和 `@ComponentRecycle` **只能在 `@Component` 或者 `@ComponentV2` 装饰的 struct 中使用**，否则编译会报错。

### 3.2 入参限制

- `@ComponentInit`、`@ComponentAppear`、`@ComponentBuilt`、`@ComponentDisappear` 和 `@ComponentRecycle` 装饰的函数**不能有入参**，否则编译会报错。
- 在 `@Component` 装饰的 struct 中，`@ComponentReuse` 装饰的函数可以**没有入参或者有一个入参**，否则编译会报错。
- 在 `@ComponentV2` 装饰的 struct 中，`@ComponentReuse` 装饰的函数**不能有入参**，否则编译会报错。

### 3.3 装饰器联合使用限制

- 新增生命周期装饰器装饰方法时，自定义组件对应事件发生时会回调该方法。新增生命周期装饰器**建议单独使用，不与其他状态变量装饰器联合使用**。比如生命周期装饰器和 `@Computed` 联合使用时，生命周期装饰器不生效。

**错误用法**：
```typescript
@Computed
@ComponentAppear
get sum() {
  return 1 + 2 + 3; // 错误用法，生命周期装饰器装饰get方法不生效
}
```

### 3.4 状态查询限制

- 当自定义组件没有使用生命周期装饰器，且没有注册监听，使用 `getCurrentState` 查询自定义组件当前生命周期状态时，**返回值永远为 `CustomComponentLifecycleState.INIT`**。

---

## 4. 新旧生命周期约束要求对比

| 约束维度 | 旧生命周期（aboutToXxx） | 新生命周期（@ComponentXxx） |
| --- | --- | --- |
| 驱动方式 | 事件驱动，仅取决于事件触发 | 状态机驱动，受生命周期状态转换约束 |
| 状态机约束 | 无。回调触发不受状态限制 | 有。仅在合法状态转换时触发，非法状态转换不执行回调 |
| 误调用风险 | 有。`aboutToDisappear` 会强制触发未执行的 `aboutToAppear`；`aboutToReuse` 在组件未展开复用时可能被误调用 | 无。`@ComponentDisappear` 不会误触发 `@ComponentAppear`；`@ComponentReuse` 在非 RECYCLED 状态时不会被调用 |
| 入参限制 | `aboutToReuse` 接收 `params: Record<string, Object \| undefined \| null>` 参数 | `@ComponentInit` / `@ComponentAppear` / `@ComponentBuilt` / `@ComponentDisappear` / `@ComponentRecycle` 不能有入参；`@ComponentReuse` 在 `@Component` 中可选一个入参，在 `@ComponentV2` 中不能有入参 |
| 状态变量修改 | `aboutToAppear` 中允许修改；`aboutToDisappear` 中不允许修改（特别是 `@Link` 变量） | `@ComponentDisappear` 中不建议修改状态变量（特别是 `@Link` 变量）；`@ComponentAppear` 中允许修改 |
| 联合使用限制 | 无特殊限制 | 建议单独使用，不与 `@Computed` 等其他装饰器联合使用，否则生命周期装饰器不生效 |
| 状态查询 | 无 `getCurrentState` 支持 | 支持 `getCurrentState` 查询当前状态，未使用装饰器且未注册监听时返回 `INIT` |

---

## 5. 生命周期时序

### 5.1 新旧回调混用时的调用顺序

| 场景 | 调用链路 |
| --- | --- |
| INIT → APPEARED | `aboutToAppear → @ComponentAppear` |
| INIT / BUILT / RECYCLED → DISAPPEARED | `@ComponentDisappear → aboutToDisappear` |
| RECYCLED → BUILT（复用） | `aboutToReuse → @ComponentReuse` |
| BUILT → RECYCLED（回收） | `aboutToRecycle → @ComponentRecycle` |

### 5.2 嵌套组件创建时序


通用创建链路（Parent 包含 Child）：

新版装饰器：

自定义组件采用**懒展开**特性，即**父组件执行完 `@ComponentBuilt` 之后才会执行子组件的 `@ComponentAppear`**。
```
Parent @ComponentInit → Parent @ComponentAppear → Child @ComponentInit → Parent build → Parent @ComponentBuilt → Child @ComponentAppear → Child build → Child @ComponentBuilt
```

旧版回调：

```
Parent aboutToAppear → Parent build → Parent onDidBuild → Child aboutToAppear → Child build → Child onDidBuild
```

### 5.3 嵌套组件删除时序

自定义组件删除顺序**从父到子**。

通用删除链路（Parent 包含 Child）：

新版装饰器：

```
Parent @ComponentDisappear → Child @ComponentDisappear
```

旧版回调：

```
Parent aboutToDisappear → Child aboutToDisappear
```

### 5.4 条件渲染场景

- **子组件默认显示时（showChild=true）**：
  - 冷启动：`Parent @ComponentAppear → Parent @ComponentBuilt → Child @ComponentAppear → Child @ComponentBuilt`
  - 删除子组件：仅执行 `Child @ComponentDisappear`
  - 删除父组件（含子组件）：`Parent @ComponentDisappear → Child @ComponentDisappear`

- **子组件默认隐藏时（showChild=false）**：
  - 冷启动：`Parent @ComponentAppear → Parent @ComponentBuilt`（不触发 Child 相关回调）
  - 删除父组件：仅执行 `Parent @ComponentDisappear`
  - 动态添加子组件：`Child @ComponentAppear → Child @ComponentBuilt`

### 5.5 最小化/后台场景

- 最小化应用或者应用进入后台，当前页面未被销毁，**不会执行组件的 `@ComponentDisappear`**。

### 5.6 回收复用时序

以 Child 包含 GrandChild 的 `@Reusable` 组件为例：

**回收链路**（从父到子）：

新版装饰器：

```
Child @ComponentRecycle → GrandChild @ComponentRecycle
```

旧版回调：

```
Child aboutToRecycle → GrandChild aboutToRecycle
```

**复用链路**（`@ComponentReuse` 装饰的函数会递归遍历所有子组件）：

新版装饰器：

```
Child @ComponentReuse → GrandChild @ComponentReuse
```

旧版回调：

```
Child aboutToReuse → GrandChild aboutToReuse
```

### 5.7 误调用场景示例

`ReusableComp3` 从未创建过，但被复用时（旧版 `aboutToReuse` 误触发，新版 `@ComponentReuse` 不触发）：

```
aboutToReuse(误调用) → aboutToAppear → @ComponentAppear → @ComponentBuilt
// @ComponentReuse 没有被误调用，因为受状态机约束
```

---

## 6. 迁移建议

1. **优先使用新生命周期装饰器**（`@ComponentAppear` / `@ComponentDisappear` 等），因为受状态机约束，调用时机更可靠。
2. **避免混用新旧生命周期**。如需混用，需注意调用顺序差异（Appear 时旧先于新，Disappear 时新先于旧）。
3. **新生命周期建议单独使用**，不与其他状态变量装饰器（如 `@Computed`）联合使用。
4. 页面级生命周期（`onPageShow` / `onPageHide` / `onBackPress`）仍然使用原有函数形式，不适用新装饰器。

---

## 7. 自定义布局回调（onMeasureSize / onPlaceChildren）

自定义组件可通过 `onMeasureSize` 和 `onPlaceChildren` 两个回调实现自定义测量与放置逻辑，二者均在组件每次布局时触发，且 `onMeasureSize` 的执行时间**先于** `onPlaceChildren`。

### 7.1 onMeasureSize

- **触发时机**：组件每次布局时触发。
- **作用**：开发者可以在此回调中增加自定义组件内子组件大小的计算逻辑，并返回自定义组件的尺寸信息。
- **执行顺序**：先于 `onPlaceChildren` 执行。

### 7.2 onPlaceChildren

- **触发时机**：组件每次布局时触发。
- **作用**：开发者可以在此回调中增加放置自定义组件内子组件位置的逻辑。

### 7.3 重绘触发场景（同时作用于 onMeasureSize 与 onPlaceChildren）

以下场景会同时触发 `onMeasureSize` 与 `onPlaceChildren` 被重新调用以更新布局：

- **初次渲染**：当自定义布局组件被首次添加到界面时，回调被调用以初始化布局。
- **属性更改**：如果自定义布局的属性或状态变量发生变化（例如通过事件处理更改了某个状态变量，或 LocalStorage/AppStorage 中的属性更改导致绑定的状态变量更改其值），这些变化会被框架观察到，并触发重新渲染，包括调用 `onMeasureSize` 与 `onPlaceChildren` 进行布局更新。
- **组件结构变化**：如果自定义布局内部的组件结构发生变化（例如条件渲染的分支改变，或 ForEach 循环渲染中数组的个数改变），也会导致 `onMeasureSize` 与 `onPlaceChildren` 被重新调用以更新布局。
