# ArkTS 自定义组件冻结规则要求

---

## 1. 概述

自定义组件冻结功能专为优化复杂UI页面的性能而设计，适用于包含多个页面栈、长列表或宫格布局的场景。当状态变量绑定多个UI组件时，其变化可能触发大量UI组件刷新，导致界面卡顿和响应延迟。

**工作原理**：
1. 开发者通过设置 `freezeWhenInactive` 属性激活组件冻结机制。
2. 启用后，系统仅对处于激活状态（active）的自定义组件进行更新，UI框架将刷新范围限制在用户可见的组件内。
3. 当之前处于 inactive 状态的组件重新变为 active 时，状态管理框架对其执行必要的刷新操作。

**重要区分**：组件 active/inactive 并不等同于其可见性。不可见但未被视为 inactive 的组件不在冻结适用范围内。

---

## 2. V1 与 V2 冻结功能对比

| 维度 | V1（@Component）                            | V2（@ComponentV2）                             |
| --- |-------------------------------------------|----------------------------------------------|
| 最低 API 版本 | API 11                                    | API 12                                       |
| 装饰器写法 | `@Component({ freezeWhenInactive: true })` | `@ComponentV2({ freezeWhenInactive: true })` |
| 状态监听机制 | `@Watch` 回调                               | `@Monitor` 回调                                |
| 页面路由 | 支持                                        | 支持                                           |
| TabContent | 支持                                        | 支持                                           |
| Navigation | 支持                                        | 支持                                           |
| LazyForEach | **支持**                                    | **不支持**                                      |
| Repeat | 不推荐 V1 组件（API18+，由于仅全量加载模式支持 V1 状态变量）     | **支持**（API 18+）                              |
| 混用场景 | API 18+ 支持精细化冻结                           | API 18+ 支持精细化冻结                              |
| 组件复用冻结 | 需手动开启 `freezeWhenInactive`，解冻后触发延后刷新      | V2 自动开启组件冻结，组件解冻后**不会**触发延后刷新      |
| BuilderNode 继承冻结 | 不支持                                       | API 22+ 通过 `inheritFreezeOptions` 支持         |

---

## 3. 支持的场景

### 3.1 页面路由

- 当前栈顶页面为 active，非栈顶不可见页面为 inactive。
- 当页面A通过 `router.pushUrl()` 跳转到页面B时，页面A变为 inactive，状态变量更新不会触发页面A刷新。
- 返回页面A时，其状态由 inactive 变为 active，冻结期间积累的状态变化被刷新。

### 3.2 TabContent

- 只有当前显示的 TabContent 中的自定义组件处于 active 状态，其余为 inactive。
- 首次渲染时，Tabs 只创建当前正在显示的 TabContent。切换过全部 TabContent 后，才会被全部创建。
- 切换 TabContent 时，新显示的 TabContent 由 inactive 变为 active，触发状态监听回调。

### 3.3 Navigation

- 当前显示的 NavDestination 中的自定义组件为 active，未显示的 NavDestination 组件为 inactive。
- 当 NavDestination 不可见时，其子自定义组件被设置为非激活态，不会触发组件刷新。
- 返回该页面时，子自定义组件重新恢复为激活态，触发回调进行刷新。

**注意**：组件冻结的 active/inactive 状态与 NavDestination 的 `onActive` 和 `onInactive` 事件不同，不可混淆。

### 3.4 LazyForEach（仅 V1）

- 仅当前显示的 LazyForEach 中的自定义组件为 active，缓存节点的组件为 inactive。
- 对 LazyForEach 中缓存的自定义组件进行冻结，不会触发组件的更新。
- 缓存节点滑入可见区域后，状态由 inactive 变为 active，触发回调刷新。

**V2 不支持此场景**，需要使用 Repeat 代替。

### 3.5 Repeat（仅 V2，API 18+）

- 对 Repeat 缓存池中的自定义组件进行冻结，避免不必要的组件刷新。
- 只有当前屏上的节点中 `@Monitor` 装饰的方法被触发，缓存池中的节点不会触发。
- 配合 `virtualScroll` 和 `cachedCount` 使用。

```typescript
@ComponentV2({ freezeWhenInactive: true })
struct ChildComponent {
  @Param @Require message: string = '';
  @Param @Require bgColor: Color = Color.Pink;

  @Monitor('bgColor')
  onBgColorChange(monitor: IMonitor) {
    // 缓存池中组件不刷新，active 的组件才触发
  }

  build() {
    Text(`[a]: ${this.message}`)
      .fontSize(50)
      .backgroundColor(this.bgColor)
  }
}
```

### 3.6 组件复用（@Reusable / @ReusableV2）

组件复用与冻结紧密关联，但 V1 和 V2 的行为差异显著。

#### 3.6.1 V1 组件复用冻结（@Reusable）

- V1 的 `@Reusable` 组件在进入复用池后**仍能响应状态变量更新**，不会自动冻结。
- 开发者需要**显式设置** `freezeWhenInactive: true` 才能冻结复用池中的组件。
- 解冻后，会触发延后的刷新，即冻结期间积累的状态变化会在组件恢复 active 时一次性刷新。
  - **术语说明**：延后的刷新指的是冻结期间的变化在解冻后不会触发刷新和回调。

```typescript
// V1 复用组件需手动开启冻结
@Reusable
@Component({ freezeWhenInactive: true })
struct ReusableItem {
  @State val: string = '';

  aboutToRecycle(): void {
    // 回收时触发
  }

  aboutToReuse(params: ESObject): void {
    // 复用时触发，需手动赋值
    this.val = params.val ?? '';
  }

  build() {
    Text(`val: ${this.val}`)
  }
}
```

#### 3.6.2 V2 组件复用冻结（@ReusableV2，API 18+）

- V2 的 `@ReusableV2` 组件在回收期间**自动冻结**，无需手动设置 `freezeWhenInactive`。
- 自动冻结期间：无法触发 UI 刷新、无法触发 `@Monitor` 回调。
- **与 `freezeWhenInactive` 的关键区别**：解除冻结状态后，**不会触发延后的刷新**。
- 冻结期间包括 `aboutToRecycle` 回调阶段（`aboutToRecycle` 中的修改不会刷新到 UI 上）。
- 冻结状态持续到 `aboutToReuse` 前，`aboutToReuse` 及之后的变量更改才会正常触发 UI 刷新和 `@Monitor` 调用。

```typescript
// V2 复用组件自动冻结，无需手动设置
@ReusableV2
@ComponentV2
struct ReusableV2Item {
  @Local val: string = 'Hello World';
  @Require @Param @Once param: string;

  aboutToRecycle(): void {
    // 此阶段处于冻结状态，修改不会刷新到 UI
  }

  aboutToReuse(): void {
    // 此阶段已解冻，修改会正常触发 UI 刷新
    // @Local 已自动重置回初始值，@Param @Once 已重置为外部传入值
  }

  build() {
    Column() {
      Text(`val: ${this.val}`)
      Text(`param: ${this.param}`)
    }
  }
}
```

#### 3.6.3 V1/V2 复用组件混用冻结规则

在复杂的混用场景中，是否冻结的规则：

1. **V1 组件**：根据是否显式开启 `freezeWhenInactive` 决定。
2. **V2 组件**：自动被冻结。

---

## 4. 仅子组件开启冻结

开发者可以只在子组件设置 `freezeWhenInactive: true`，实现仅冻结特定子组件。父组件不设置冻结，子组件独立管理冻结状态。

**适用场景**：Navigation 中，父页面不需要冻结，但某个子组件需要在页面切换时冻结。

---

## 5. 混用场景

当支持组件冻结的场景彼此组合使用时（如 Navigation + TabContent），冻结行为因 API 版本不同而有差异。

### 5.1 API version 17 及以下

- 父组件解冻时，会解冻其子组件**所有**的节点（包括非当前显示的 TabContent）。

### 5.2 API version 18 及以上

- 父组件解冻时，只会解冻子组件的**屏上节点**，不会解冻非当前显示的 TabContent 等节点。
- 实现了更精细化的冻结控制，避免不必要的刷新。

### 5.3 典型混用示例：Navigation + TabContent

当 NavDestination 中包含 Tabs 组件时：
1. NavDestination 变为 inactive 时，TabsComponent 中所有 TabContent 都被冻结。
2. NavDestination 恢复 active 时：
   - API 17 及以下：所有 TabContent 标签被解冻。
   - API 18 及以上：仅当前显示的 TabContent 标签被解冻。

---

## 6. 限制条件

### 6.1 BuilderNode 中间层级问题

组件冻结强依赖父子关系来通知是否开启冻结。如果父组件使用组件冻结，且组件树的中间层级启用了 BuilderNode，则 BuilderNode 的子组件将无法被冻结。

- **API version 19 及以下**：BuilderNode 的子组件不会被冻结，即使父组件开启了 `freezeWhenInactive`。
- **API version 20+**：通过将 BuilderNode 的 `inheritFreezeOptions` 配置为 `true`，BuilderNode 的子组件可以被冻结。

#### inheritFreezeOptions 机制说明

`inheritFreezeOptions(true)` 的作用是**传递冻结策略**，使 BuilderNode 内部的子组件能够接收到父组件的冻结状态变化。它**不会**给子组件添加冻结能力。

因此，要使 BuilderNode 中的子组件正确冻结，需要**同时满足**以下条件：

1. **父组件**声明 `freezeWhenInactive: true`
2. **BuilderNode** 调用 `inheritFreezeOptions(true)` 传递冻结策略
3. **子组件自身**也必须声明 `freezeWhenInactive: true`

**常见错误**：只在父组件声明 `freezeWhenInactive: true` 并调用 `inheritFreezeOptions(true)`，但子组件未声明 `freezeWhenInactive: true` → 子组件的 `@Watch` / `@Monitor` 回调仍会正常触发，冻结不生效。

**正确示例**：

```typescript
// 父组件：开启冻结
@Component({ freezeWhenInactive: true })
struct FreezeBuildNode {
  build() {
    NodeContainer(new TextNodeController())
  }
}

// BuilderNode 管理类：传递冻结策略
class TextNodeController extends NodeController {
  makeNode(context: UIContext): FrameNode | null {
    this.textNode = new BuilderNode(context);
    this.textNode.inheritFreezeOptions(true); // 传递冻结策略
    this.textNode.build(wrapBuilder(buildText), new Params());
    return this.textNode.getFrameNode();
  }
}

// 子组件：也必须声明冻结能力
@Component({ freezeWhenInactive: true })
struct BuildNodeChild {
  @StorageProp('key') @Watch('onUpdated') message: string = '';

  onUpdated() {
    // 冻结期间不会触发
  }

  build() {
    Text(this.message)
  }
}
```

### 6.2 V2 不支持 LazyForEach

`@ComponentV2` 装饰的自定义组件不支持在 LazyForEach 场景下缓存节点组件冻结。如需此能力，应使用 Repeat 替代 LazyForEach。

### 6.3 组件冻结与组件复用混用时解冻不会触发 Watch

当子组件同时开启组件冻结（`freezeWhenInactive: true`）且被标记为组件复用（`@Reusable`）时，解冻后**不会触发 `@Watch` 回调**。

**行为流程**：

1. `if` 条件变为 `false` → 子组件下树进入复用池 → 因开启冻结，组件被冻结（inactive）
2. 冻结期间状态变量变化 → 组件不刷新、不触发 `@Watch`
3. `if` 条件变为 `true` → 子组件出复用池上树 → **不会触发 `@Watch` 回调**

**原因**：组件复用的执行逻辑早于组件解冻的执行逻辑。子组件被复用时，会先将脏节点刷新（包括冻结期间需要延迟刷新的变量绑定的系统组件），并**清空脏节点列表**。复用后组件被标记为 active，执行解冻逻辑时，由于脏节点列表已被清空，框架判断冻结期间无变量改变，因此不触发 `@Watch` 回调。在 `aboutToReuse` 中修改状态变量，解冻时同样不会触发 `@Watch`。

```typescript
@Reusable
@Component({ freezeWhenInactive: true })
struct ChildComponent {
  @Link @Watch('onChange') count: number;

  onChange() {
    // 冻结期间不会触发，解冻后也不会触发
  }

  aboutToReuse(params: Record<string, ESObject>): void {
    // 在 aboutToReuse 中改值，解冻时同样不会触发 Watch 回调
    this.count++;
  }

  aboutToRecycle(): void {}

  build() {
    Column() {
      Text(`ChildComponent count: ${this.count}`)
        .fontSize(20)
    }
  }
}

@Entry
@Component
struct Index {
  @State flag: boolean = true;
  @State count: number = 0;

  build() {
    Column() {
      Button(`change flag`)
        .onClick(() => { this.flag = !this.flag; })
      Button(`change count`)
        .onClick(() => { this.count++; })
      if (this.flag) {
        ChildComponent({ count: this.count })
      }
    }
    .height('100%')
  }
}
```
