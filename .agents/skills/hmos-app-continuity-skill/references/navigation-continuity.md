# 页面栈迁移方案说明

> 数据来源：HarmonyOS 官方文档（bpta-continue-cast）+ 官方示例项目（OxHornCampus）
> 最后同步：2026-09

---

## 1. Navigation 与 Router 的核心差异

| 特性 | Router 路由 | Navigation 路由 |
|------|------------|----------------|
| 页面栈自动迁移 | ✅ 系统自动恢复（仅 Router 支持） | ❌ 系统不支持 |
| 需设 `SUPPORT_CONTINUE_PAGE_STACK_KEY` | 不需要 | 必须设为 `false` |
| 目标端恢复方式 | `onCreate`/`onNewWant` 执行完成前同步调用 `restoreWindowStage`，自动恢复页面栈 | `NavStackRebuilder` 手动重建 |
| `onWindowStageRestore` 中 | 仅镜像 `onWindowStageCreate` 的初始化（如有），**不要** `loadContent` | 必须 `loadContent` 加载根页面 |
| 自定义状态 | 补充到 `wantParam` | 补充到 `wantParam` + 导航栈快照 |

**核心约束：不修改项目现有路由方式。**

---

## 2. Router 路由方案

Router 路由系统自动恢复页面栈（仅 Router 支持），开发者只需补充自定义状态，并在目标端 `onCreate()`/`onNewWant()` **执行完成前**同步调用 `restoreWindowStage()` 触发带页面栈的页面恢复。

> **真机适配（重要）**：系统页面栈恢复依赖 `restoreWindowStage()` 实际生效——该接口可抛异常（调用侧须 try/catch 兜底，失败时 `onWindowStageRestore` 中 `loadContent` 落地页，见 §2.2/§2.3 与 `references/api-reference.md` §3.2）。已有 API 18 真机反馈存在环境差异：排除时序/异常问题后仍白屏（调用未抛异常但页面未恢复）。此时按**真机优先**原则切换**手动落地页模式**：`onContinue` 设 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false`，目标端 `onWindowStageRestore` 中 `loadContent` 根页 + 业务转发栈顶（entryPage 标记 + 根页 pushUrl，模式见 §2.4），并记入完成报告已知风险。

### 2.1 源端 onContinue

```typescript
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // 系统自动迁移 Router 页面栈，无需设置 SUPPORT_CONTINUE_PAGE_STACK_KEY
  // 只补充自定义状态
  wantParam['offsetSum'] = AppStorage.get<number>('offsetSum') as number;
  wantParam['bottomTabIndex'] = AppStorage.get<number>('bottomTabIndex') as number;
  wantParam['currentZoneId'] = AppStorage.get<number>('currentZoneId') as number;
  return AbilityConstant.OnContinueResult.AGREE;
}
```

### 2.2 目标端 onCreate / onNewWant

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
    // 恢复自定义状态到 AppStorage
    AppStorage.setOrCreate<number>('offsetSum', want.parameters['offsetSum'] as number);
    AppStorage.setOrCreate<number>('bottomTabIndex', want.parameters['bottomTabIndex'] as number);
    AppStorage.setOrCreate<number>('currentZoneId', want.parameters['currentZoneId'] as number);
    AppStorage.setOrCreate<string>('isContinuation', 'true');
    // Router 路由：restoreWindowStage 触发带页面栈的页面恢复
    // ⚠️ 官方约束：必须在 onCreate()/onNewWant() 执行完成前、同步方法体中调用，
    //    放进异步回调（Promise/回调函数）会导致迁移后页面加载失败
    this.context.restoreWindowStage(new LocalStorage());
  }
}
```

### 2.3 onWindowStageRestore

是否需要重写 `onWindowStageRestore`，取决于 `onWindowStageCreate()` 中是否有启动必要的初始化——**官方口径：有初始化才需要在 `onWindowStageRestore()` 中执行同样的初始化**（镜像原则；无初始化则整段省略，最小侵入）。Router 路由页面栈已由 `restoreWindowStage` 恢复，**不要** `loadContent`（会破坏已恢复的栈）：

```typescript
onWindowStageRestore(windowStage: window.WindowStage): void {
  // Router 路由：页面栈已由 restoreWindowStage 自动恢复
  // 仅镜像 onWindowStageCreate 中的初始化（本例为全屏窗口属性设置）
  this.setFullSize(windowStage);
}
```

### 2.4 Router 按需迁移（关闭系统自动恢复）—— 手动栈重建

Router 项目因业务需要关闭系统页面栈自动恢复（`onContinue` 中设 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false`，如深层页入参不可序列化、需精确控制落地页）时，页面栈须手动重建。Router 没有 Navigation 的 `NavPathStack` 快照能力，采用 **entryPage 标记 + 根页 pushUrl** 模式：

1. **源端 `onContinue`**：导出状态 + 写入 `wantParam['entryPage']`（迁移后应落的深层页路径）+ 设 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false`
2. **目标端 `onCreate`/`onNewWant`**：`want.parameters → AppStorage` 落地（含 entryPage 标记），执行完成前同步调用 `restoreWindowStage()`（官方按需迁移示例同样先调用；须 try/catch 兜底）
3. **`onWindowStageRestore`**：`loadContent('pages/Index')` 加载根页作为落地页（镜像 `onWindowStageCreate` 初始化，如有）
4. **根页 `aboutToAppear`**：读到接续标记 + entryPage → **清除标记（防重复 push）** → `router.pushUrl` 还原第二层

自检项见 `assets/checklists/checklist-navigation.md` §四。

---

## 3. Navigation 路由方案

Navigation 路由系统**不**支持自动恢复页面栈，必须手动处理。

### 3.1 数据流

```
源端                                        目标端
─────                                       ─────
根页面持有 NavPathStack                     onCreate / onNewWant
  ↓                                           ↓
setInterception({didShow}) 单钩采集           want.parameters → AppStorage
  pathStack.getPathStack()                     navStack JSON → AppStorage
  （API 细节见 api-reference §3-B）
  序列化为 JSON                                  → 同步调用 restoreWindowStage()
  写入 AppStorage                             onWindowStageRestore()
  ↓                                             loadContent('pages/Index') 加载根页面
onContinue()                                    ↓
  设 SUPPORT_CONTINUE_PAGE_STACK_KEY=false   根页面感知快照（冷启动 aboutToAppear /
  读快照 JSON 写入 wantParam                    热启动 @StorageProp+@Watch，见 §3.6）
  返回 AGREE                                    NavStackRebuilder.rebuild()
                                                 按快照逐页 pushPathByName（全部，不跳过）
                                                 停在 currentIndex 对应层
```

### 3.2 导航栈快照数据结构

```typescript
/** 导航栈中的一个页面 */
export interface NavStackEntry {
  pageName: string;
  params: Record<string, Object | undefined>;
  stateJson: string | undefined; // 可选：该页的 PageState 快照
}

/** 一次迁移的导航栈快照 */
export interface NavStackSnapshot {
  entries: Array<NavStackEntry>;
  currentIndex: number; // 用户当前停留的层级（0 起始）
}
```

### 3.3 源端：采集快照

```typescript
// 根页面：didShow 单一钩子采集——任何页面展示（push/replace/系统返回 pop）
// 统一触发，勿在每个 push 点各改一处（漏改即丢层）
// setInterception 为 API 12+，签名见 api-reference §3-B.2
private setupSnapshotHook(): void {
  this.pathStack.setInterception({
    didShow: () => this.refreshSnapshot(),
  } as NavigationInterception);
}

private refreshSnapshot(): void {
  // getPathStack（API 名见 api-reference §3-B.1；快照不含 NavBar 根页，
  // entries[0] 即第一个真实子页）
  const infos: Array<NavPathInfo> = this.pathStack.getPathStack();
  const entries: Array<NavStackEntry> = [];
  infos.forEach((info: NavPathInfo, index: number) => {
    entries.push({
      pageName: info.name,
      params: info.param as Record<string, Object | undefined> ?? {},
      // 快照时合并实时态：只合并**顶层**（当前可见）实例的 live 状态
      // （@Watch 上报见 §4）；同页名多实例时不污染下层 entry
      stateJson: index === infos.length - 1 ? AppStorage.get<string>('live_' + info.name) : undefined,
    });
  });
  AppStorage.setOrCreate('currentNavStack',
    NavStackCodec.serialize({
      entries: entries,
      currentIndex: this.pathStack.size() - 1,
    }));
}

// Ability onContinue
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // ① 禁用系统页面栈迁移
  wantParam[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY] = false;
  // ② 写入导航栈快照（启动后从未进入子页时 entries 为空——空快照合法，
  //    目标端落根页为正确行为，见 checklist §3.1）
  const json = AppStorage.get<string>('currentNavStack');
  if (json !== undefined) {
    wantParam['navStack'] = json;
  }
  return AbilityConstant.OnContinueResult.AGREE;
}
```

### 3.4 目标端：重建导航栈

```typescript
// Ability onCreate / onNewWant（⚠️ want 只在这两个回调中可读，
// onWindowStageRestore 的入参只有 windowStage，拿不到 want。
// 冷/热启动统一在 CONTINUATION 分支暂存 AppStorage，页面侧只读 AppStorage）
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  this.restoreOnContinuation(want, launchParam);
}

onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  this.restoreOnContinuation(want, launchParam);
}

private restoreOnContinuation(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  if (launchParam.launchReason !== AbilityConstant.LaunchReason.CONTINUATION) {
    return;
  }
  const json = want.parameters?.['navStack'] as string;
  if (json !== undefined) {
    // 快照落地 AppStorage：冷启动根页 aboutToAppear 消费；
    // 热启动根页 @StorageProp+@Watch 感知（见 §3.6）
    AppStorage.setOrCreate('migratedNavStack', json);
  }
  // 官方按需迁移页面栈示例：在 onCreate/onNewWant 执行完成前同步调用
  // restoreWindowStage()；可抛异常，须 try/catch 兜底（api-reference §3.2）
  try {
    this.context.restoreWindowStage(new LocalStorage());
  } catch (err) {
    hilog.error(0x0000, 'EntryAbility', 'restoreWindowStage failed: %{public}s', JSON.stringify(err));
  }
}

// Ability onWindowStageRestore：页面栈迁移已禁用，手动加载根页面。
// （本回调仅当 onWindowStageCreate 有初始化、或需手动加载落地页时才需要）
onWindowStageRestore(windowStage: window.WindowStage): void {
  // ⚠️ Navigation 项目必须在此 loadContent 加载根页面
  windowStage.loadContent('pages/Index');
}

// 根页面 aboutToAppear：冷启动路径重建导航栈（热启动见 §3.6）
aboutToAppear(): void {
  const json = AppStorage.get<string>('migratedNavStack');
  if (json !== undefined && json !== '') {
    AppStorage.setOrCreate('migratedNavStack', ''); // 消费即清，防重复重建
    const snapshot = NavStackCodec.deserialize(json);
    if (snapshot !== undefined) {
      NavStackRebuilder.rebuild(this.pathStack, snapshot);
    }
  }
}
```

### 3.5 NavStackRebuilder 实现

```typescript
export class NavStackRebuilder {
  /**
   * 按快照重建 Navigation 导航栈。
   * ⚠️ getPathStack() 快照不含 NavBar 根页（NavPathStack 只管理 NavDestination，
   * 官方口径见 api-reference §3-B.1）：entries[0] 是第一个真实子页，而 loadContent
   * 加载的是包含 Navigation 的根页面——二者不是同一页。因此必须重建**全部**
   * entry，不跳过任何层（历史上误传 rootLoaded=true 跳过 entries[0]，导致
   * 迁移后丢失第一层子页）。
   */
  static rebuild(pathStack: NavPathStack, snapshot: NavStackSnapshot): void {
    const endIndex: number = Math.min(snapshot.currentIndex, snapshot.entries.length - 1);
    for (let i = 0; i <= endIndex; i++) {
      const entry: NavStackEntry = snapshot.entries[i];
      // 实时态随本实例入参传递（per-instance，不落共享 live key——
      // 防同页名后续实例读到旧值串染，消费端见 §4）
      const params: Record<string, Object | undefined> = entry.params;
      if (entry.stateJson !== undefined) {
        params['liveState'] = entry.stateJson;
      }
      pathStack.pushPathByName(entry.pageName, params, false);
    }
  }
}
```

**要点：**
- **快照不含根页**：`entries[0]` 是第一个真实子页而非根页——重建全部 push，不跳过任何 entry（实施前先核证本项目 entries[0] 语义）
- 重建后 Navigation 停留在 `snapshot.currentIndex` 对应层
- 每页入参通过 `NavPathInfo.param` 传入（仅限 JSON 可序列化数据）
- **绝不可**为了"简化接续"把 Navigation 改成 Router

### 3.6 热启动联动（singleton 已运行时感知快照到达）

冷启动由根页 `aboutToAppear` 消费快照；但目标端**已在运行**时（`launchType: singleton` 热启动，走 `onNewWant`）根页不会重建、`aboutToAppear` 不会再触发——Ability 落地 AppStorage 后**没有任何被动感知者**。必须用 `@StorageProp + @Watch` 打通页面联动（module.md 约定 singleton 必测热启动）：

```typescript
// 根页面 Index.ets —— 冷/热启动统一联动
@Entry
@Component
struct Index {
  pathStack: NavPathStack = new NavPathStack();
  // @StorageProp 单向同步（AppStorage → 组件）：热启动时 Ability 在
  // onNewWant 写入新快照 → 本地成员被刷新 → @Watch 触发
  @StorageProp('migratedNavStack') @Watch('onNavStackArrived') migratedNavStack: string = '';

  // 热启动联动（@Watch 不在首次初始化时触发，冷启动仍走 aboutToAppear）
  onNavStackArrived(): void {
    // ⚠️ 先捕获本地副本、再清空 AppStorage：@StorageProp 单向同步会把成员
    //    刷成空串，先清后读必翻车（读到空）。清空后成员变化会再次触发本
    //    回调，空串守卫直接返回（防重入）
    const json: string = this.migratedNavStack;
    AppStorage.setOrCreate('migratedNavStack', '');
    if (json === '') {
      return;
    }
    const snapshot = NavStackCodec.deserialize(json);
    if (snapshot !== undefined) {
      // 丢弃目标端本机会话栈属产品语义（用户接续意图优先），
      // 须在方案确认与完成报告中向用户说明（checklist §3.2）
      this.pathStack.clear();
      NavStackRebuilder.rebuild(this.pathStack, snapshot);
    }
  }

  aboutToAppear(): void {
    // 冷启动路径（见 §3.4）：消费即清
    const json = AppStorage.get<string>('migratedNavStack');
    if (json !== undefined && json !== '') {
      AppStorage.setOrCreate('migratedNavStack', '');
      const snapshot = NavStackCodec.deserialize(json);
      if (snapshot !== undefined) {
        NavStackRebuilder.rebuild(this.pathStack, snapshot);
      }
    }
  }

  build() {
    Navigation(this.pathStack) { /* 首页 UI */ }
  }
}
```

---

## 4. 每页状态恢复（与 UI/编辑/播放场景联动）

导航栈重建只还原"到了哪几层、各层入参"；**push 之后页面内的状态变更**（quantity、submitted 等不触发重新 push 的 `@State`）需要实时态链路，三段缺一不可：

### 4.1 页面侧：@Watch 实时上报 + 新实例 onReady 接管

```typescript
// 子页（NavDestination 页面）——最小可抄实现
@Component
export struct DetailPage {
  @State @Watch('onLiveChange') quantity: number = 1; // 不重 push 的实时态
  @State submitted: boolean = false;

  // ① 源端：@Watch 实时上报——页内变更即时写入 live key，
  //    由快照采集在迁移时合并（§3.3 只合并顶层实例）
  onLiveChange(): void {
    AppStorage.setOrCreate('live_Detail', JSON.stringify({
      quantity: this.quantity,
      submitted: this.submitted,
    }));
  }

  build() {
    NavDestination() { /* 页面 UI */ }
      .onReady((ctx: NavDestinationContext) => {
        // ② 目标端：新实例从**本实例入参**接管实时态（rebuild 已把
        //    stateJson 合并进 params['liveState']，§3.5）——随入参 per-instance
        //    传递、不读共享 live key，同页名多实例互不串染；一次消费
        //    取参方式按项目路由表实现（示意：getParamByName / 路由表回调参数）
        const live = this.readLiveStateFromParams(ctx);
        if (live !== undefined) {
          this.quantity = live.quantity;
          this.submitted = live.submitted;
        }
        // ③ 防串染：清掉本页名 live 残留（若目标端本地也有上报）
        AppStorage.setOrCreate('live_Detail', '');
      })
  }
}
```

### 4.2 多页面场景：PageStateRegistry 模式

多页面/懒加载 Tab 场景用注册表按页收集（模式选择见各 checklist 的"状态模型与 Ability 集成"节）：

```typescript
// NavStackEntry.stateJson 可携带该页的 PageState 快照
// 页面 aboutToAppear 中：
const json = AppStorage.get<string>('migratedPageStates');
if (json !== undefined) {
  const states = PageStateCodec.deserialize(json);
  if (states !== undefined) {
    PageStateRegistry.getInstance().restoreAll(states);
  }
}
```

**顺序保证**：状态恢复发生在导航栈重建之后（页面已进入栈才触发 `aboutToAppear` / `onReady`）。

---

## 关联资源

- 代码示例：`assets/examples/NavigationContinuity.ets`（Navigation 路由）、`assets/examples/RouterContinuity.ets`（Router 路由）
- 自检清单：`assets/checklists/checklist-navigation.md`
- API 详情：`references/api-reference.md`
