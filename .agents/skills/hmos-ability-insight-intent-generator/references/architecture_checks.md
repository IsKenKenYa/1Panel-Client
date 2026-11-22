# 应用架构检查

在生成意图代码前，必须识别项目的页面路由架构，以便正确实现跳转和参数传递。

## 检查清单

1. **搜索以下文件/代码**：
   - `route_map.json` 或 `NavPathStack` → Navigation 架构
   - `router.pushUrl` 或 `router.push` → Router 架构
   - **`Tabs` 组件**（如 `import` 或 `Tabs()` 调用）→ **Tabs 架构**（新增）
   - **`onNewWant.*pushUrl|router\.pushUrl`** → **`onNewWant` 无条件路由**（运行时风险，需添加 `intentActive` 守卫）
   - **`if.*index.*&&`**（在 `TabContent` 附近）→ **Tabs 条件渲染**（信号必须提升到容器层消费）
   - **同时存在** → 混用架构（允许，但需分别处理）

2. **确定参数传递方式**：
   - Navigation 架构：使用 `windowStage.loadContent` + `LocalStorage` 传递参数
   - Router 架构：使用 `router.pushUrl` + `params` 传递参数
   - **Tabs 架构**：使用 `AppStorage.setOrCreate` 信号驱动 + `@StorageProp @Watch` 消费，**禁止使用 `loadContent` 重新加载页面**（Tab 内组件树对 LocalStorage 传播支持不稳定）
   - **混用时的跳转规则**：
     - 主容器/根页面使用 Navigation
     - 子页面跳转可使用 `router.pushUrl`（目标页面为独立的 `@Entry` 页面）
     - 意图页面如果是 Navigation 根容器，**必须实现防白屏机制**（见下文）

### 参数传递方式对比表（含生命周期同步）

|      方式       | 适用场景                             | 生命周期同步           | 注意点                                                       |
| :-------------: | :----------------------------------- | :--------------------- | :----------------------------------------------------------- |
| `@StorageProp`  | 仅需组件创建时读取一次 AppStorage 值 | ❌ 不同步（创建时快照） | 热启动页面不重建时读到旧值，适用于静态配置类参数             |
| `@StorageLink`  | 需运行时响应 AppStorage 变化         | ✅ 双向同步             | 消费后需手动重置信号（设为 -1 或 delete），避免重复触发      |
| `LocalStorage`  | Navigation 架构页面间参数传递        | ✅ 随页面实例传递       | 依赖组件树传播，Tabs 下不可靠                                |
| `router.params` | Router 架构传统跳转                  | ✅ 随路由传递           | 冷启动不可用（参数不被存储），仅热启动有效                   |
| **静态类持有**  | 同进程内任意页面跳转，无需依赖框架   | ✅ 随引用传递（同进程） | 适用于 Router 架构中 `loadContent` 加载页面，简单可靠，无需考虑 Storage 框架兼容性 |

**选择决策**：

- 意图参数需在页面 **运行时动态响应** → 使用 `@StorageLink`
- 意图参数仅在 **页面创建时读取一次** → 使用 `@StorageProp`（冷启动）或 `LocalStorage`（Navigation）
- **热启动同 URL 场景**（页面不重建）：必须使用 `@StorageLink`，`@StorageProp` 不会更新

## 代码模板

### Navigation 架构（推荐）

```typescript
// 在意图执行器的 onExecute 中
let storage = new LocalStorage();
storage.setOrCreate('intentTargetTab', 3);

if (this.executeMode == insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
  this.windowStage?.loadContent('pages/Index', storage);
}
```

### Router 架构

```typescript
// 在意图执行器的 onExecute 中
await router.pushUrl({
  url: 'pages/TargetPage',
  params: { targetTab: 3 }
});
```

### Tabs 架构（AppStorage 信号驱动）

```typescript
// 在意图执行器的 onExecute 中
AppStorage.setOrCreate('intentTargetTab', 3);
// 无需 loadContent，TabBar 通过 @StorageLink @Watch 自动响应
```

```typescript
// 在 Tab 页面中（注：必须为 @StorageLink，热启动页面不重建时 @StorageProp 不更新）
@StorageLink('intentTargetTab') @Watch('onTargetChange') intentTargetTab: number = -1;

aboutToAppear(): void {
  // 冷启动消费：@Watch 不触发 @StorageLink 初始值
  if (this.intentTargetTab >= 0) {
    this.currentIndex = this.intentTargetTab;
    this.tabController?.changeIndex(this.currentIndex);
    AppStorage.setOrCreate('intentTargetTab', -1);
  }
}

onTargetChange(): void {
  if (this.intentTargetTab >= 0 && this.intentTargetTab < this.tabBarArray.length) {
    this.currentIndex = this.intentTargetTab;
    this.tabController?.changeIndex(this.currentIndex);
  }
  AppStorage.setOrCreate('intentTargetTab', -1); // 信号消费后清除
}
```

> ⚠️ **Tabs 条件渲染陷阱**：若 `TabContent` 使用 `if (index===N && condition)` 条件渲染，子组件在其他 Tab 下**不存在**，其 `aboutToAppear`/`@Watch` 无法消费信号。此时必须将信号消费点提升到 Tabs 容器层（即包含 `Tabs` 的 struct），而非子组件内。

### Navigation 根容器页面的防白屏机制（强制）

如果意图页面（使用 `@InsightIntentPage` 装饰）内部使用了 `Navigation` 组件作为根容器，**必须**在页面中添加以下代码：

```typescript
@State private renderNav: boolean = false;
private firstLoad: boolean = true;

aboutToAppear(): void {
  setTimeout(() => {
    this.renderNav = true;
    this.firstLoad = false;
  }, 0);
}

onPageShow(): void {
  if (!this.firstLoad && this.renderNav) {
    this.renderNav = false;
    setTimeout(() => {
      this.renderNav = true;
    }, 0);
  }
}

build() {
  Column() {
    if (this.renderNav) {
      Navigation() {
        // 页面原有内容
      }
      // Navigation 的其他属性
    } else {
      Blank()  // 占位，用户无感知
    }
  }
}
```

**原因**：部分鸿蒙版本上，`Navigation` 组件若在根容器布局测量完成前创建，会导致高度计算为 0，页面白屏。延迟一帧创建可解决。

## 后台数据修改的 UI 刷新策略

当意图为 `UI_ABILITY_BACKGROUND` 模式且修改了持久化数据（DB/Preferences）时，已打开的前台页面不会自动刷新，需要手动触发 UI 更新。

### 检查流程

1. 搜索项目的 UI 刷新机制：`emitter.on` / `AppStorage.setOrCreate` / 自定义事件
2. 优先复用已有事件：如果页面已监听某个数据变更事件（如 `emitter.on('dataChanged', ...)`），意图在写入数据后 `emit` 同一事件
3. 无现成事件的兜底：在 `AppStorage` 中存入一个时间戳信号，页面通过 `@StorageLink` + `@Watch` 或 `onPageShow` 监听

### 代码模板

```typescript
// 意图写入数据后
if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_BACKGROUND) {
  // 方案 A：使用项目已有 emitter 事件
  // emitter.emit('dataChanged', {});
  
  // 方案 B：使用 AppStorage 时间戳信号（通用兜底）
  AppStorage.setOrCreate('intentDataRefreshTime', Date.now());
}
```

```typescript
// 页面中消费信号
@StorageLink('intentDataRefreshTime') @Watch('onDataRefresh') intentDataRefreshTime: number = 0;

onDataRefresh(): void {
  if (this.intentDataRefreshTime > 0) {
    this.loadData(); // 重新加载数据
  }
}
```

**注意**：信号命名使用 `intentXxx` 前缀以避免与项目自有键名冲突。冷启动场景无需特殊处理，应用重新启动时自然从 DB 加载最新数据。

## 常见错误

- Navigation 架构中误用 `router.pushUrl` → 应使用 `windowStage.loadContent`
- 用 `AppStorage` 传递参数（Navigation 应使用 `LocalStorage`）
- 页面加载时未处理异步完成后的参数写入（需要使用 `then` 回调）
- **Navigation 根容器页面未实现防白屏机制** → 冷启动白屏（需添加延迟渲染代码）
- **Tabs 架构中误用 `loadContent` 重载页面** → 应使用 `AppStorage.setOrCreate` 信号驱动
- **热启动同 URL 时使用 `@StorageProp` 而非 `@StorageLink`** → 页面不重建时参数不更新