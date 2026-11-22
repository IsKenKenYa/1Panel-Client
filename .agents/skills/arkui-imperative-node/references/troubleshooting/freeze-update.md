# 冻结态检查

## 检查条件

代码中 BuilderNode 调用了 `update(arg)` 方法更新节点内容，但页面未发生变化。典型场景：BuilderNode 所在的 NavDestination 被覆盖、Tab 页未选中、LazyForEach 条目滑出可视区域、router 页面被隐藏等不活跃状态时调用 `update()`。凡调用 `update()` 后内容未更新的位置，都需检查 BuilderNode 是否处于冻结态。

## 检查步骤

1. **检查冻结链是否成立**：对调用了 `update()` 的 BuilderNode，冻结需同时满足以下三个条件，缺一则不会冻结：
   - **宿主冻结开关**：从 BuilderNode 节点向上查找的第一个自定义组件（即 NodeContainer 所在的宿主自定义组件）设置了 `freezeWhenInactive: true`；
   - **BuilderNode 继承**：BuilderNode 调用了 `inheritFreezeOptions(true)`（API 20+，仅当父组件为自定义组件、BuilderNode、ComponentContent、ReactiveBuilderNode 或 ReactiveComponentContent 时生效）；
   - **宿主处于不活跃状态**：不活跃仅在以下场景成立——所在 NavDestination 被其他页面覆盖、TabContent 未选中、LazyForEach 条目离开可视区域进入缓存、router 页面被新页面隐藏。**注意：Navigation 首页不是 NavDestination，被 NavDestination 覆盖时其内容不会变为不活跃状态，挂在首页的 BuilderNode 冻结链不成立**。
2. **检查 update 调用时机**：判断 `update()` 是否在 BuilderNode 处于冻结态时被调用。冻结态下 `update()` 不会触发节点刷新，数据被缓存。
3. **边界条件**：
   - `inheritFreezeOptions(true)` 仅当父组件为自定义组件、BuilderNode、ComponentContent、ReactiveBuilderNode 或 ReactiveComponentContent 时生效；
   - 当子组件为自定义组件时，BuilderNode 的冻结策略不会传递给子组件（内部组件自身的 `freezeWhenInactive` 独立生效，若内部组件自身开启且不活跃，也会自行冻结）；
   - 冻结态是 ArkUI 的性能优化机制，冻结的组件不参与 UI 更新，这是设计行为（规格），非缺陷；
   - 组件重新变为活跃状态（返回该 NavDestination、Tab 切换回、滚动回可视区域）时会自动解冻，并使用缓存的数据更新节点。

## 诊断与修复

### 发现问题时

- **诊断**：BuilderNode 调用了 `update()` 但页面内容未更新，原因是 BuilderNode 处于冻结态（冻结链三条件同时满足且宿主不活跃）。
- **原因**：冻结态是 ArkUI 的性能优化机制，当组件处于不活跃状态时，系统冻结该组件的状态更新，避免不活跃组件的无效刷新。宿主设置了 `freezeWhenInactive: true` + BuilderNode 调用了 `inheritFreezeOptions(true)`，两者同时开启后，宿主不活跃时 BuilderNode 被冻结，`update()` 不触发刷新，数据被缓存。这是设计行为（规格），非缺陷。宿主重新活跃时系统自动解冻并使用缓存的数据更新节点，无需手动重放。
- **修复方向**（仅在开发者需要冻结期间也能更新时才需要改，否则无需修改——解冻后系统自动应用缓存数据）：
  - **方案一（推荐，最简单）**：去掉宿主的 `freezeWhenInactive: true`，宿主不冻结，BuilderNode 继承不到冻结策略，update 正常生效。
  - **方案二**：保留宿主 `freezeWhenInactive: true`（页面级冻结优化），仅将 BuilderNode 的 `inheritFreezeOptions` 改为 `false`，BuilderNode 不继承宿主冻结策略，update 正常生效。
  - 注意：若 BuilderNode **内部**的自定义组件也设置了 `freezeWhenInactive: true`，它自身不活跃时仍会自行冻结（BuilderNode 的冻结策略不会传递给子组件，但内部组件自身的冻结开关独立生效），此时需一并去掉内部组件的冻结开关，update 才能生效。
- **修复代码模式**：
```typescript
// 方案一：去掉宿主的 freezeWhenInactive（推荐）
// 原代码：@Component({ freezeWhenInactive: true }) struct FrozenHost { ... }
// 修复后：
@Component  // 宿主去掉 freezeWhenInactive，冻结链断裂，update 正常生效
struct FrozenHost {
  build() {
    Column() {
      NodeContainer(controller)  // BuilderNode 的 inheritFreezeOptions(true) 继承不到冻结
    }
  }
}

// 方案二：保留宿主冻结，仅 BuilderNode 不继承
makeNode(context: UIContext): FrameNode | null {
  this.builderNode = new BuilderNode(context);
  this.builderNode.inheritFreezeOptions(false);  // 不继承宿主冻结策略，update 正常生效
  this.builderNode.build(wrapBuilder(buildFn), params);
  return this.builderNode.getFrameNode();
}
```

### 未发现问题时

BuilderNode 处于活跃状态时调用 `update()` 内容正常更新；或冻结链三条件未同时满足（宿主无 `freezeWhenInactive` / BuilderNode 未继承冻结 / 宿主处于活跃状态）；或开发者已通过方案一/方案二关闭了 BuilderNode 冻结。不报告。

## 规则依据

- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："设置BuilderNode继承冻结能力"章节——inheritFreezeOptions 继承父自定义组件（向上第一个自定义组件）的冻结策略；被冻结时调用 update 不触发更新，解冻时再更新节点。
- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：update() 方法说明、inheritFreezeOptions(enabled) 接口（API 20+）及生效条件。
- [自定义组件冻结（V1）](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-custom-components-freeze.md)：组件冻结仅适用于 router 隐藏页面、Tabs 未选中、LazyForEach 缓存、Navigation 未显示的 NavDestination 四类场景；Navigation 首页不在此列。
