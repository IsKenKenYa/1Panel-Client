# Navigation/NavDestination 转场动画 API 参考

> 本文记录四类 ArkUI Public API 的精确签名、枚举值与官方指南条目。
>
> **权威源：** interface_sdk-js .d.ts（签名/枚举）+ ArkUI 官方开发指南（用法）。
>
> **来源标注：** 每条 API 标注 .d.ts 文件路径与行号。

---

## 1. systemTransition — 系统转场动画

### 方法签名

```
systemTransition(type: NavigationSystemTransitionType): NavDestinationAttribute
```

- **归属组件：** NavDestination（`NavDestinationAttribute` 方法）
- **@since：** 14
- **来源：** `interface_sdk-js/api/@internal/component/ets/nav_destination.d.ts:1145`
- **说明：** 设置 NavDestination 系统转场动画，支持分别设置系统标题栏动画和内容动画。
- **参数：**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| type | NavigationSystemTransitionType | 是 | 系统转场动画类型。默认值：NavigationSystemTransitionType.DEFAULT |

- **优先级：** 与 customTransition 同时设置时，后设置的属性生效。

### NavigationSystemTransitionType 枚举

- **@since：** 14（DEFAULT/NONE/TITLE/CONTENT），15（FADE/EXPLODE/SLIDE_RIGHT/SLIDE_BOTTOM）
- **来源：** `interface_sdk-js/api/@internal/component/ets/nav_destination.d.ts:120`

| 名称 | 值 | 说明 | @since |
|---|---|---|---|
| DEFAULT | 0 | 默认系统转场动画 | 14 |
| NONE | 1 | 无系统转场动画 | 14 |
| TITLE | 2 | 标题栏系统转场动画 | 14 |
| CONTENT | 3 | 内容区系统转场动画 | 14 |
| FADE | 4 | 渐变类型的系统转场动画 | 15 |
| EXPLODE | 5 | 中心缩放类型的系统转场动画 | 15 |
| SLIDE_RIGHT | 6 | 右侧平移类型的系统转场动画 | 15 |
| SLIDE_BOTTOM | 7 | 底部平移类型的系统转场动画 | 15 |

> **使用限制：**
> - 系统默认转场动画中只有 STANDARD 页面的 push 和 pop 动画有单独的标题栏动画。
> - 设置 NONE 或 TITLE 时没有系统转场动画；设置 CONTENT 和 DEFAULT 时默认系统转场动画。
> - TITLE 仅用于 STANDARD 模式页面的 push/pop 动画。

### 官方指南条目

- ArkUI 官方开发指南：NavDestination > systemTransition
- 使用方式：在 NavDestination 组件声明上链式调用 `.systemTransition(枚举值)`

---

## 2. customTransition — 页面级自定义转场

### 方法签名

```
customTransition(delegate: NavDestinationTransitionDelegate): NavDestinationAttribute
```

- **归属组件：** NavDestination（`NavDestinationAttribute` 方法）
- **@since：** 15
- **来源：** `interface_sdk-js/api/@internal/component/ets/nav_destination.d.ts:1274`
- **说明：** 设置 NavDestination 自定义转场动画。
- **参数：**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| delegate | NavDestinationTransitionDelegate | 是 | NavDestination 自定义动画的代理函数 |

- **优先级：** 与 systemTransition 同时设置时，后设置的属性生效。
- **限制：** 不支持在 attributeModifier 中调用。

### NavDestinationTransitionDelegate 类型

```
type NavDestinationTransitionDelegate =
    (operation: NavigationOperation, isEnter: boolean) => Array<NavDestinationTransition> | undefined;
```

- **@since：** 15
- **来源：** `interface_sdk-js/api/@internal/component/ets/nav_destination.d.ts:1503`
- **参数：**

| 参数名 | 类型 | 说明 |
|---|---|---|
| operation | NavigationOperation | 当前页面转场的操作类型 |
| isEnter | boolean | 当前页面是否为入场页面。true：入场；false：退场 |

- **返回值：** `Array<NavDestinationTransition> | undefined` — 自定义动画数组；返回 undefined 时使用默认系统动画。

### NavDestinationTransition 接口

- **@since：** 15
- **来源：** `interface_sdk-js/api/@internal/component/ets/nav_destination.d.ts:579`

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| event | Callback&lt;void&gt; | 是 | — | 闭包函数，指定转场动画。系统根据闭包内组件 UI 状态修改生成对应转场动画 |
| onTransitionEnd | Callback&lt;void&gt; | 否 | — | 转场动画结束时触发的回调 |
| duration | number | 否 | 1000 | 转场动画时长（毫秒） |
| curve | Curve | 否 | EaseInOut | 动画曲线类型 |
| delay | number | 否 | 0 | 转场动画延迟（毫秒） |

### NavigationOperation 枚举

- **@since：** 11
- **来源：** `interface_sdk-js/api/@internal/component/ets/navigation.d.ts:1651`

| 名称 | 值 | 说明 |
|---|---|---|
| PUSH | 1 | 入场转场（页面入栈） |
| POP | 2 | 退场转场（页面出栈） |
| REPLACE | 3 | 页面替换转场 |

> **不可交互说明：** customTransition 是页面级转场，无法在转场过程中响应交互（如手势返回）。如需交互，请使用 customNavContentTransition（Navigation 整体级转场）。

> **⚠️ 名称混淆防护（编译错误 `ArkTS:10505001`）：**
> `customTransition(delegate)` 与 `pageTransition()` 是两个完全不同的 API，禁止混用：
> - `customTransition` 是 **NavDestination 链式属性方法**，delegate 作为参数传入：`.customTransition(delegate)`
> - `pageTransition` 是 **CustomComponent 生命周期方法**（签名 `() => void`），已废弃
>
> 禁止在 struct 中定义名为 `pageTransition` 的方法并使用 `NavDestinationTransitionDelegate` 签名（即 `(operation, isEnter) => Array<NavDestinationTransition> | undefined`）。
> 这会触发编译错误：`Property 'pageTransition' in type 'X' is not assignable to the same property in base type 'CustomComponent'`。

> **⚠️ 通用属性名保留防护（编译错误 `ArkTS:10505001`）：**
> ArkUI 通用属性方法名（`scale`/`opacity`/`translate`/`rotate`/`position`/`offset`/`transform`/`visibility`/`zIndex` 等，完整集合见 `CommonAttribute`/`CommonMethod`）在 `@Component` struct 中保留，不可用作成员变量名。
> 在 struct 内声明 `@State scale: number` 等会触发 `Property 'scale' in type 'X' is not assignable to the same property in base type 'CustomComponent'. Type 'number' is not assignable to type '{ (value: ScaleOptions): CommonAttribute; ... }'`。
> 转场动画因频繁操作 `scale`/`opacity`/`translate`/`rotate` 尤其易踩坑，应改用带业务语义前缀的名称（如 `cardScale`/`cardOpacity`）。

### 官方指南条目

- ArkUI 官方开发指南：NavDestination > customTransition
- 代理函数按 operation（PUSH/POP）× isEnter（入场/退场）共 4 种组合返回不同动画配置

---

## 3. customNavContentTransition — Navigation 整体可交互转场

### 方法签名

```
customNavContentTransition(delegate: (from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation)
    => NavigationAnimatedTransition | undefined): NavigationAttribute
```

- **归属组件：** Navigation（`NavigationAttribute` 方法）
- **@since：** 11
- **来源：** `interface_sdk-js/api/@internal/component/ets/navigation.d.ts:2868`
- **说明：** 定义自定义转场动画的回调。回调返回 NavigationAnimatedTransition 时执行自定义转场；返回 undefined 时执行默认转场动画。
- **参数：**

| 参数名 | 类型 | 说明 |
|---|---|---|
| from | NavContentInfo | 退出的目标页信息 |
| to | NavContentInfo | 进入的目标页信息 |
| operation | NavigationOperation | 转场类型 |

- **优先级：** 同时设置 Navigation 级 customNavContentTransition 和 NavDestination 级 customTransition 时，Navigation 级优先。
- **支持 attributeModifier：** 从 API version 20 开始可在 attributeModifier 中调用。

### NavigationAnimatedTransition 接口

- **@since：** 11
- **来源：** `interface_sdk-js/api/@internal/component/ets/navigation.d.ts:3077`

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| transition | (transitionProxy: NavigationTransitionProxy) =&gt; void | 是 | — | 执行自定义转场动画的回调。proxy 含 from/to 页面信息 |
| onTransitionEnd | (success: boolean) =&gt; void | 否 | — | 转场完成时触发的回调。success 表示转场是否成功 |
| timeout | number | 否 | 非交互无默认；非交互默认 1000 | 动画超时时间（毫秒）。范围 [0, +∞) |
| isInteractive | boolean | 否 | false | 转场动画是否可交互。true：可交互；false：不可交互 |

### NavigationTransitionProxy 接口

- **@since：** 11
- **来源：** `interface_sdk-js/api/@internal/component/ets/navigation.d.ts:3148`

| 字段/方法 | 类型 | 可选 | 说明 |
|---|---|---|---|
| from | NavContentInfo | 否 | 退出页的信息 |
| to | NavContentInfo | 否 | 进入页的信息 |
| isInteractive | boolean | 否 | 转场动画是否可交互。默认 false |
| finishTransition() | void | **否** | 结束自定义转场动画。必须手动调用结束动画，否则系统在超时后结束 |
| cancelTransition?() | void | **是** | 取消交互式转场动画，恢复路由栈到页面跳转前状态（非交互式不可取消）。类型为 `(() => void) \| undefined` |
| updateTransition?(progress: number) | void | **是** | 更新交互式转场动画进度。范围 [0, 1]。类型为 `((progress: number) => void) \| undefined` |

> **关键说明：**
> - `transition` 回调接收 `NavigationTransitionProxy` 参数，proxy 的 `from`/`to` 提供 NavContentInfo 页面信息
> - `finishTransition()` 必须手动调用结束动画
> - `isInteractive: true` 时支持手势驱动交互式转场（如手势返回）
> - `updateTransition(progress)` 仅在 isInteractive 为 true 时可用

> **⚠️ possibly undefined 两层防护（编译错误 `ArkTS:10605999`）：**
> **第一层 — 类属性：** 单例中持有 `proxy: NavigationTransitionProxy | undefined` 时，`if (!this.proxy) { return }` 守卫**不会**对后续 `this.proxy` 收窄类型。必须先 `let proxy = this.proxy` 赋值局部变量，再 `if (!proxy) return`。
> **第二层 — 可选方法：** `cancelTransition` 和 `updateTransition` 是接口可选方法（签名带 `?`），类型含 `| undefined`。即使 `proxy` 已收窄，直接调用 `proxy.updateTransition(progress)` 仍报 10605999。必须用可选链 `proxy.updateTransition?.(progress)` / `proxy.cancelTransition?.()`。`finishTransition` 是必填方法，proxy 收窄后可直接 `proxy.finishTransition()`。
> 详见 SKILL.md「反模式警告：possibly undefined 不可直接调用（两层防护）」。

### NavContentInfo 接口

- **@since：** 11
- **来源：** `interface_sdk-js/api/@internal/component/ets/navigation.d.ts:3241`

| 字段 | 类型 | 说明 |
|---|---|---|
| name | string | 导航目标页名称。根视图（NavBar）时为 undefined |
| index | number | 导航目标页在路由栈中的索引。根视图时为 -1 |
| mode | NavDestinationMode | 导航目标页模式。根视图时为 undefined |
| param | Object | 导航目标页加载的参数 |
| navDestinationId | string | 导航目标页的唯一标识 |

### transition 注册建议

- **全局注册：** 在 Navigation 组件上直接配置 `customNavContentTransition` 回调，所有 NavDestination 页面共用同一套转场逻辑。适合统一转场效果。
- **单例可访问：** 用单例工具类管理各页面动画回调（`onReady` 注册、`aboutToDisappear` 注销），Navigation 级回调中按 `from`/`to` 的 `navDestinationId` 或 `name` 查找分发。适合不同页面不同动画。
- **取舍：** 全局注册代码简洁但灵活性低；单例可访问灵活但需管理注册/注销生命周期。

### 官方指南条目

- ArkUI 官方开发指南：Navigation > customNavContentTransition
- 可交互转场必须在 Navigation 上配置，NavDestination 级 customTransition 无法配合 NavigationTransitionProxy 实现手势驱动

---

## 4. disableAnimation — 禁用转场

> **注意：** 禁用转场分两种作用域，使用不同 API：
> - **单页禁用（NavDestination 级）：** 使用 `systemTransition(NavigationSystemTransitionType.NONE)`（见本文档第 1 节 systemTransition，枚举值 NONE = 1）
> - **全局禁用（NavPathStack 级）：** 使用 `NavPathStack.disableAnimation(true)`（本节下方方法签名）

### 方法签名

```
disableAnimation(value: boolean): void
```

- **归属类：** NavPathStack（`NavPathStack` 方法）
- **@since：** 11
- **来源：** `interface_sdk-js/api/@internal/component/ets/navigation.d.ts:1280`
- **说明：** 禁用或启用 Navigation 组件的转场动画。
- **参数：**

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| value | boolean | 是 | false | true：禁用转场动画；false：启用转场动画 |

- **作用域：** NavPathStack 级别，影响该 NavPathStack 关联的 Navigation 中所有页面跳转的转场动画。

### 单页禁用 vs 全局禁用

| 禁用方式 | 作用域 | API | 说明 |
|---|---|---|---|
| 单页禁用 | NavDestination | `.systemTransition(NavigationSystemTransitionType.NONE)` | 在 NavDestination 上设置系统转场类型为 NONE，仅禁用该页面的系统转场 |
| 全局禁用 | Navigation（NavPathStack） | `navPathStack.disableAnimation(true)` | 禁用后该 NavPathStack 中所有跳转无转场动画 |
| 单次禁用 | 单次跳转操作 | `pushPath(info, animated: false)` / `pop(animated: false)` | 仅影响当前跳转操作 |

> **说明：**
> - **单页禁用**使用 `systemTransition(NavigationSystemTransitionType.NONE)`（属于 NavDestination 级 API），仅禁用目标页面的系统转场动画，不影响其他页面
> - **全局禁用**使用 `NavPathStack.disableAnimation(true)`（属于 NavPathStack 级 API），禁用后该 NavPathStack 中所有跳转均无转场动画
> - 两者 API 不同、作用域不同，**不可混用**：单页禁用不得使用 `NavPathStack.disableAnimation(true)`，全局禁用不得仅在单个 NavDestination 上设置 `systemTransition(NONE)`
> - 如仅需单次跳转禁用动画，在 `pushPath`/`pop`/`replacePath` 等方法中传 `animated: false` 参数
> - `disableAnimation(false)` 可恢复转场动画

### 官方指南条目

- ArkUI 官方开发指南：NavPathStack > disableAnimation
- 禁用后如需恢复，调用 `disableAnimation(false)`

---

## API 优先级与互斥关系

| 同时设置 | 生效规则 | 来源 |
|---|---|---|
| systemTransition + customTransition | 后设置的生效 | nav_destination.d.ts:424 |
| customNavContentTransition + customTransition | Navigation 级（customNavContentTransition）优先 | navigation.d.ts 官方说明 |
| disableAnimation + 任何转场配置 | disableAnimation 为 true 时转场不执行 | navigation.d.ts:1280 |
