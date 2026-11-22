# UI 浏览类接续方案说明

> 数据来源：HarmonyOS 官方示例项目（OxHornCampus 等）
> 最后同步：2026-09

---

## 1. 方案原理

UI 浏览类接续的核心是**轻量状态传递**：页面状态（滚动位置、Tab 索引、当前项 ID 等）通过 `want.parameters` 传递给目标端，目标端在页面加载后恢复这些状态。

**数据流：**

```
源端                                    目标端
─────                                   ─────
页面状态 → AppStorage                    onCreate / onNewWant
  ↓                                       ↓
onContinue()                             want.parameters → AppStorage
  从 AppStorage 读取                       restoreWindowStage()（同步调用，
  写入 wantParam                             触发带页面栈的页面恢复）
  返回 AGREE                               ↓
                                          页面 aboutToAppear()
                                            从 AppStorage 读取状态
                                            恢复滚动位置 / Tab 索引
```

> 图示为 Router 路由（默认系统页面栈恢复）的主路径。页面恢复按路由方式二选一：
> - **Router（默认）**：`onCreate`/`onNewWant` 执行完成前同步调用 `restoreWindowStage()`，页面栈由系统自动恢复；`onWindowStageRestore` 仅当 `onWindowStageCreate` 有启动初始化时镜像执行，**不 loadContent**
> - **Navigation / 按需迁移**（`SUPPORT_CONTINUE_PAGE_STACK_KEY = false`）：在 `onWindowStageRestore()` 中 `loadContent` 加载落地页（见 `references/navigation-continuity.md`）

**数据通道选型**：UI 浏览类状态通常 < 1KB，使用 `want.parameters` 即可。

---

## 2. 源端：onContinue 中采集状态

### 2.1 页面侧：实时维护 AppStorage

页面在用户交互时，将关键状态写入 `AppStorage`，保证 `onContinue` 触发时状态是最新的：

```typescript
@Entry
@Component
struct IntroductionPage {
  @StorageLink('offsetSum') offsetSum: number = 0;
  @StorageLink('currentZoneId') currentZoneId: number = 0;
  @StorageLink('bottomTabIndex') bottomTabIndex: number = 0;
  private scroller: Scroller = new Scroller();

  // 滚动时实时记录位置
  onScrollEvent(): void {
    this.offsetSum = this.scroller.currentOffset().yOffset;
  }
}
```

### 2.2 Ability 侧：onContinue 中写入 wantParam

```typescript
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // 从 AppStorage 读取当前状态，写入 wantParam
  wantParam['offsetSum'] = AppStorage.get<number>('offsetSum') as number;
  wantParam['currentZoneId'] = AppStorage.get<number>('currentZoneId') as number;
  wantParam['bottomTabIndex'] = AppStorage.get<number>('bottomTabIndex') as number;
  return AbilityConstant.OnContinueResult.AGREE;
}
```

**要点：**
- 使用 `scroller.currentOffset().yOffset` 采集确定性累计位置
- **不要**使用 `onDidScroll` 回调参数（可能是每帧增量而非累计位置）
- 写入 wantParam 的总量保持 < 100KB

### 2.3 页面可达性判定：可见性事件为主，勿信 Ability 作用域路由 API

`onContinue` 需要判断"当前是否在可迁移页面 / 采集哪页状态"——判定来源以**页面可见性事件**为主：

```typescript
@Entry
@Component
struct WebPage {
  // 页面可见性标记：onPageShow 置位 / onPageHide 复位
  @StorageLink('webPage_active') webPageActive: string = 'false';

  onPageShow(): void {
    AppStorage.set<string>('webPage_active', 'true');
  }

  onPageHide(): void {
    AppStorage.set<string>('webPage_active', 'false');
  }
}

// Ability 侧 onContinue：读标记决定可迁移性与采集范围
if (AppStorage.get<string>('webPage_active') !== 'true') {
  return AbilityConstant.OnContinueResult.REJECT;
}
```

- ⚠️ **不要在 UIAbility 里用 `router.getState()` 判栈顶**：真机返回不可靠且该 API 已 deprecated——迁移判定依赖它会出现"真机上时灵时不灵"（真机反馈实证，改为可见性标记后一次修好）。Ability 作用域的路由 API 仅作辅助核对，不作判定依据。

---

## 3. 目标端：恢复状态

### 3.1 Ability 侧：onCreate / onNewWant 中读取

```typescript
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  this.restoreOnContinuation(want, launchParam);
}

onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  this.restoreOnContinuation(want, launchParam);
}

private restoreOnContinuation(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION
      && want?.parameters !== undefined) {
    // 将迁移数据写入 AppStorage
    AppStorage.setOrCreate<number>('offsetSum', want.parameters['offsetSum'] as number);
    AppStorage.setOrCreate<number>('currentZoneId', want.parameters['currentZoneId'] as number);
    AppStorage.setOrCreate<number>('bottomTabIndex', want.parameters['bottomTabIndex'] as number);
    // 设置接续标记，页面据此触发恢复逻辑
    AppStorage.setOrCreate<string>('isContinuation', 'true');
    // Router 路由项目：restoreWindowStage 触发带页面栈的页面恢复
    // ⚠️ 官方约束：必须在 onCreate()/onNewWant() 执行完成前、同步调用
    //    （禁止放进异步回调，否则迁移后页面加载失败）
    // ⚠️ 可抛异常：try/catch 兜底，失败置标记由 onWindowStageRestore
    //    兜底 loadContent（完整模式见 assets/templates/EntryAbility.ets；
    //    调用成功≠栈一定恢复成功，Router 路径可加白屏兜底探测——
    //    onWindowStageRestore 禁止无条件 loadContent，api-reference §3.2）
    try {
      this.context.restoreWindowStage(new LocalStorage());
    } catch (err) {
      hilog.error(0x0000, 'EntryAbility', 'restoreWindowStage failed: %{public}s', JSON.stringify(err));
      // this.isWindowRestoreFailed = true;  // 由 onWindowStageRestore 兜底 loadContent
    }
    // Navigation 项目：改为在 onContinue 设置 SUPPORT_CONTINUE_PAGE_STACK_KEY = false，
    // 并在 onWindowStageRestore 中 loadContent（见 references/navigation-continuity.md）
  }
}
```

**要点：**
- `onWindowStageRestore` 按镜像原则使用：仅当 `onWindowStageCreate()` 中有启动必要的初始化时，才在其中执行同样的初始化；Router 默认（系统页面栈恢复）时**不要** `loadContent`，`onWindowStageCreate` 无初始化时整段省略该回调（最小侵入）

### 3.2 页面侧：aboutToAppear 中恢复

```typescript
@StorageLink('isContinuation') isContinuation: string = 'false';
@StorageLink('offsetSum') offsetSum: number = 0;

aboutToAppear(): void {
  if (this.isContinuation === 'true') {
    // 延迟到布局完成后恢复滚动位置
    setTimeout(() => {
      this.scroller.scrollTo({ xOffset: 0, yOffset: this.offsetSum });
    }, 50);
    // 恢复完成后清除标记
    AppStorage.set<string>('isContinuation', 'false');
  }
}
```

**要点：**
- 恢复滚动位置须延迟到布局完成后（`setTimeout(50)` 或 `onAreaChange`）
- `aboutToAppear` 中直接执行 `scrollTo` 时 Scroll 尚未完成布局，会被静默忽略
- 使用 `isContinuation` 标记区分正常启动和接续启动
- **标记清理须覆盖兜底分支**：恢复成功消费即清之外，白屏兜底 `loadContent`、落地非目标页、迁移取消/失败路径同样负责清理——残留标记会让下次正常导航误入接续分支（真机反馈：落地非文章页清残留标记属事后补丁，应在首次实现时写入各兜底分支）

---

## 4. Tab 页面接续

### 4.1 Tab 索引恢复

```typescript
// 源端 onContinue
wantParam['bottomTabIndex'] = AppStorage.get<number>('bottomTabIndex') as number;

// 目标端 onCreate
AppStorage.setOrCreate<number>('bottomTabIndex', want.parameters['bottomTabIndex'] as number);

// 页面侧
@StorageLink('bottomTabIndex') bottomTabIndex: number = 0;
build() {
  Tabs({ index: this.bottomTabIndex }) { ... }
}
```

### 4.2 懒加载 Tab 初始值保护

Tabs 懒加载下未访问过的 Tab 组件从未创建（handler 未注册），`exportAll()` 收集不到其状态。
若 payload 对应字段为默认值（如 `''`），目标端恢复时会覆盖组件本地初始值。

**保护措施：**
- payload 中未从 handler 获得的字段保持 `undefined`
- `restoreState()` 中仅覆盖 `!== undefined` 的字段

---

## 5. Web 组件接续

Web 组件接续与原生 UI 不同：原生侧只能传 URL + WebController 状态，H5 内部状态需 H5 侧配合。

### 5.1 源端：live URL 三管采集（持续追踪，❌ 非一次性）

⚠️ 只在 `onContinue` 里调一次 `getUrl()` **不够**：H5 内部跳转（尤其锚点 `#section`）**不触发任何加载回调**——迁移数据停留在旧地址，目标端把滚动偏移打到另一篇文档（"章节跳转让进度失效"，真机反馈实证）。页面侧必须**持续追踪**当前 URL，三管齐下：

```typescript
// ① onLoadIntercept：主框架导航即时捕获（框架级跳转）
Web({ src: this.currentUrl, controller: this.webController })
  .onLoadIntercept((event) => {
    AppStorage.set<string>('currentWebUrl', this.webController.getUrl());
    return false; // 仅观察，不拦截
  })
  // ② 滚动事件节流 getUrl()（如 500ms）：锚点跳转常伴随滚动，
  //    兜底捕获不触发加载回调的 #fragment 变化
  .onScroll((event) => {
    this.refreshUrlThrottled();   // 节流后 AppStorage.set('currentWebUrl', webController.getUrl())
  })
  // ③ onPageEnd：加载结束以 getUrl() 为准（重定向后的最终 URL 校准）
  .onPageEnd(() => {
    AppStorage.set<string>('currentWebUrl', this.webController.getUrl());
  })
```

`onContinue` 中从 AppStorage 读取 `currentWebUrl` 写入 wantParam（读取的是持续追踪的最新值）。

**滚动偏移采集（与 URL 三管采集并行）**：官方示例 continue-progress（《常见接续最佳实践》"Web 浏览进度接续"）经 `runJavaScript` 读取 H5 `scrollTop`——`onTouch`（`TouchType.Up`）手指抬起时采集、`onPageEnd` 校准，实时写入 AppStorage；`onContinue` 将 `currentWebUrl` 与 `currentWebScrollOffset` 一并写入 wantParam。❌ 只传 URL 不传偏移——目标端无从恢复滚动位置（真机反馈高频失败）。

### 5.2 目标端：带 #fragment 的 URL + 锚点定位/偏移恢复双保险

```typescript
aboutToAppear(): void {
  if (this.isContinuation === 'true' && this.migratedWebUrl !== '') {
    this.currentUrl = this.migratedWebUrl;   // 带 #fragment 的完整 URL，H5 自行锚点定位
    this.pendingScrollOffset = this.migratedWebScrollOffset;  // 记录待恢复的滚动偏移
    AppStorage.set<string>('isContinuation', 'false');
    // ❌ 此处禁止恢复滚动——页面尚未加载（loadUrl 异步生效）
  }
}
```

滚动位置恢复走官方 continue-progress 模式：`runJavaScript` 设置 H5 `scrollTop`，且在 `onPageEnd` 之后再**延时**执行：

```typescript
.onPageEnd(async () => {
  AppStorage.set<string>('currentWebUrl', this.webController.getUrl());
  if (this.pendingScrollOffset >= 0) {
    const offset: number = this.pendingScrollOffset;
    this.pendingScrollOffset = -1;
    // ⚠️ onPageEnd 只代表主文档加载完成，懒加载内容/H5 渲染高度常未就绪——
    //    立即恢复会被钳制到当前内容高度（表现为停留顶部，真机反馈高频失败）
    setTimeout(() => {
      this.webController.runJavaScript(
        'javascript:document.documentElement.scrollTop = ' + offset);
    }, 500);
  }
})
```

**要点（滚动恢复时序红线，与 §3.2 原生规则同源）：**
- **任何滚动恢复都必须在容器就绪后延时执行**：原生等布局完成（`setTimeout ≥ 50ms` / `onAreaChange`）；Web 等 `onPageEnd` 后再延时 ≥300ms
- 采集与恢复都经 `runJavaScript` 读写 H5 `scrollTop`，按实际滚动容器调整选择器（整页 `document.documentElement.scrollTop`；内层滚动容器 `getElementById(...)`，官方示例为 productList）
- ❌ `aboutToAppear`/`loadUrl` 后立即恢复（页面未加载）；`onPageEnd` 内立即恢复（内容高度未就绪被钳制）——两类写法实测均停留顶部
- 更稳模式：延时后先 `runJavaScript` 校验页面可滚高度足够再恢复，不足则短间隔重试

**限制：**
- H5 内部 JS 状态（如 SPA 路由状态）无法自动迁移
- 需要 H5 侧配合：URL 参数编码 / postMessage 协议

> 详见 `assets/examples/WebProgress.ets`（偏移采集/迁移/延时恢复完整闭环）

---

## 关联资源

- 代码示例：`assets/examples/UIProgress.ets`、`assets/examples/WebProgress.ets`
- 自检清单：`assets/checklists/checklist-ui-progress.md`
- 数据迁移选型：`references/data-migration-strategies.md`
- API 详情：`references/api-reference.md`
