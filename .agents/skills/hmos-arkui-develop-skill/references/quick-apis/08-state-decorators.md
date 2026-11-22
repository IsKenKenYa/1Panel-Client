## 8. 状态管理装饰器


> **组件索引**：`V1 装饰器`、`V1 全局状态 API`、`V2 装饰器 (API 12+)`、`V2 全局状态 API`

### V1 装饰器

| 装饰器 | 适用场景 | 装饰变量类型 | 说明 |
|--------|---------|-------------|------|
| **@State** | 组件内状态 | Object/class/string/number/boolean | 观察第一层属性变化，触发 UI 刷新 |
| **@Prop** | 父→子单向 | 同 @State | 父组件单向传递，子组件本地副本 |
| **@Link** | 父↔子双向 | 同 @State | 双向同步，需用 `$变量` 传递 |
| **@Observed** | 类装饰器 | class | 观察类实例的嵌套属性变化 |
| **@ObjectLink** | 嵌套对象 | @Observed 装饰的类实例 | 配合 @Observed 实现嵌套观测 |
| **@Provide / @Consume** | 跨层级 | 同 @State | 祖先提供，后代消费 |
| **@Watch** | 变量监听 | 追加在其他装饰器后 | `@Watch('onChanged')` 变化时回调 |
| **@Builder** | UI 复用 | 函数 | 声明式 UI 描述函数。参数传递方式决定是否刷新（见下表） |
| **@BuilderParam** | UI 插槽 | @Builder 函数 | 接收外部传入的 UI，类型必须与传入的 @Builder 匹配 |
| **@LocalBuilder** | 本地 UI | 函数 | 不追踪外部依赖变化；@ComponentV2 中优先用 @LocalBuilder 替代 @Builder |

**@Builder 参数传递方式速查**（完整错误用法对照见 `quick-rules/05-state.md`）：

| 传递方式 | 调用形式 | 状态变量变化是否刷新 | 限制 |
|---------|---------|-------------------|------|
| 按值传递（默认） | `builder(this.label)` 或 `builder(label: string)` | ❌ 不刷新 | 简单类型参数默认按值 |
| 按引用传递 | `builder({ paramA1: this.label })` 单参数对象字面量 | ✅ 刷新 | 仅 1 个参数且为对象字面量才生效；多参数不刷新 |
| 按回调传递（API 20+） | `builder(UIUtils.makeBinding(() => this.x, setter))` | ✅ 刷新且可在 Builder 内修改 | 需传 SetterCallback 才能回写 |

> ⚠️ 高频坑：按值传状态变量不刷新 / 两个及以上参数不刷新 / @Builder 内改入参报 140109 / @Builder 内建组件传整个对象不刷新。
| **@Extend** | 样式扩展 | 组件类型 | `@Extend(Text) function myStyle() {}` |
| **@Styles** | 通用样式 | 无参 | `@Styles function myStyles() {}` |
| **@StateStyles** | 多态样式 | — | {normal, pressed, disabled, focused, selected} |
| **@AnimatableExtend** | 动画扩展 | 可动画属性 | 自定义可动画扩展 |
| **@Reusable** | 组件复用 | @Component | 实现 `aboutToReuse` |
| **@Require** | 必填参数 | 变量 | 标记参数为必填 |

### V1 全局状态 API

| API | 签名/用法 | 说明 |
|-----|----------|------|
| **AppStorage** | `.setOrCreate(key, value)` `.get(key)` `.set(key)` `.delete(key)` | 应用级全局状态 |
| **@StorageLink** | `@StorageLink('key') var: type` | 与 AppStorage 双向同步 |
| **@StorageProp** | `@StorageProp('key') var: type` | 与 AppStorage 单向同步 |
| **LocalStorage** | `new LocalStorage()` `.setOrCreate()` `.get()` | 页面/模块级状态 |
| **@LocalStorageLink** | `@LocalStorageLink('key') var: type` | 与 LocalStorage 双向同步 |
| **@LocalStorageProp** | `@LocalStorageProp('key') var: type` | 与 LocalStorage 单向同步 |
| **PersistentStorage** | `.persistProp('key', default)` `.deleteProp()` | 持久化存储 |
| **Environment** | `.envProp('key', value)` | 环境变量 |

### V2 装饰器 (API 12+)

| 装饰器 | 适用场景 | 说明 |
|--------|---------|------|
| **@Local** | 组件内状态 | 替代 @State |
| **@Param** | 父→子传递 | 替代 @Prop/@Link |
| **@Once** | 追加 @Param | 仅初始化同步一次 |
| **@Event** | 子→父回调 | `@Event onValueChange: (val) => void` |
| **@Provider / @Consumer** | 跨层级 | V2 版 |
| **@Monitor** | 属性监听 | `@Monitor('p1','p2') onPChange(mon: IMonitor) {}` |
| **@SyncMonitor** | 同步监听 | 同步版本 |
| **@Computed** | 计算属性 | `@Computed get name(): string {}` |
| **@ObservedV2** | 类装饰器 | V2 版深度观测 |
| **@Trace** | 属性追踪 | `@Trace name: string = ''` |
| **@Type** | 类型标记 | 序列化类型 |
| **@ReusableV2** | 组件复用 | V2 版 |
| **@Binding** | 双向绑定 | V2 版双向绑定 |

### V2 全局状态 API

| API | 签名 | 说明 |
|-----|------|------|
| **AppStorageV2** | `.connect(this, 'key', type?)` | V2 应用级状态 |
| **PersistenceV2** | `.connect(this, 'key', type?)` | V2 持久化 |
| **makeObserved** | `makeObserved(target)` | 将对象变为可观测 |
| **canBeObserved** | `canBeObserved(target)` | 判断是否可观测 |
| **getTarget** | `getTarget(proxy)` | 获取 Proxy 原始对象 |
| **addMonitor / clearMonitor** | `addMonitor(obj, prop, cb)` / `clearMonitor(id)` | 动态监听 |

### 典型用法

#### @Builder 参数传递方式

| 方式 | 调用形式 | 状态变化是否刷新 | 限制 |
|---------|---------|-------------------|------|
| 按值传递（默认） | `builder(this.label)` 或 `builder(label: string)` | ❌ 不刷新 | 简单类型参数默认按值 |
| 按引用传递 | `builder({ paramA1: this.label })` 单参数对象字面量 | ✅ 刷新 | 仅 1 个参数且为对象字面量才生效；多参数不刷新 |
| 按回调传递（API 20+） | `builder(UIUtils.makeBinding(() => this.x, setter))` | ✅ 刷新且可在 Builder 内修改 | 需传 SetterCallback 才能回写 |

```ts
// 按引用传递（单参数 + 对象字面量，刷新）
class Tmp { label: string = '' }
@Builder overBuilder($$: Tmp) { Text($$.label) }
overBuilder({ label: this.label })

// 按值传递（不刷新）
@Builder overBuilder(label: string) { Text(label) }
overBuilder(this.label)   // label 变化不刷新
```

> **⚠️ @Builder 参数类型声明坑：** 参数类型必须使用显式声明的 class 或 interface，**不能使用内联对象字面量类型**：
> ```typescript
> // ❌ 编译错误：内联对象字面量不能用作类型声明
> @Builder DynamicContent($$: { text: string; value: number }) { ... }
>
> // ✅ 正确：使用显式声明的 class 或 interface
> interface DynamicContentConfig { text: string; value: number }
> @Builder DynamicContent($$: DynamicContentConfig) { ... }
> ```

#### @Monitor 正确用法

```ts
@Monitor('searchKeywordValue')
onSearchKeywordChange(mon: IMonitor): void {
  let keyword: string = mon.value<string>()?.now ?? ''    // ✅ 属性是 now，非 after
  let before: string = mon.value<string>()?.before ?? ''
}
```

---
