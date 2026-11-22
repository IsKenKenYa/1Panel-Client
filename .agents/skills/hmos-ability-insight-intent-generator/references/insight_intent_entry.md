# 使用 @InsightIntentEntry 装饰器创建自定义意图

使用该装饰器装饰一个继承自 `InsightIntentEntryExecutor` 的类，实现意图操作并配置意图依赖的 Ability 组件，便于 AI 入口拉起依赖的 Ability 组件时，执行对应的意图操作。

------

> 📌 **公共规则**：本文档涉及的 ArkTS 严格模式规则、返回值规范、字段命名规范、导入规范等，统一收录于 **[common_rules.md](common_rules.md/)**。生成代码前请先阅读对应章节。

------

## ⚠️ 冷热启动通用规则（所有 @InsightIntentEntry 必读）

### 规则1：`onExecute` 首行必须同步设置 `intentActive` 信号

**时序风险**：`EntryAbility.onNewWant` 在热启动时可能先于 `onExecute` 执行。若 `onNewWant` 包含无条件路由（如 `router.pushUrl`），会干扰意图导航。

**解决方案**：`onExecute` 的首行（任何 `await` 之前）同步设置 `intentActive` 信号；`onNewWant` 中检测该信号跳过路由。

```typescript
async onExecute(): Promise<insightIntent.IntentResult<T>> {
  AppStorage.setOrCreate('intentActive', true);  // ← 首行同步，早于任何 await
  // ...
}
```

```typescript
// EntryAbility.onNewWant
onNewWant(want: Want): void {
  setTimeout(() => {
    const active: boolean = AppStorage.get<boolean>('intentActive') ?? false;
    if (active) { AppStorage.setOrCreate('intentActive', false); return; }
    // 非意图触发的原有路由
    router.pushUrl({ url: 'pages/Playnow' });
  }, 200);
}
```

### 规则2：模块顶层 `AppStorage.setOrCreate` 必须加守卫

**时序风险**：模块顶层代码在页面文件首次加载时执行，可能晚于 `onExecute`。无条件 `setOrCreate` 会覆盖意图已写入的信号值。

```typescript
// ❌ 错误：无条件覆盖意图信号
AppStorage.setOrCreate('intentTargetTab', -1);

// ✅ 正确：只在未设置时初始化
if (AppStorage.get<number>('intentTargetTab') === undefined) {
  AppStorage.setOrCreate('intentTargetTab', -1);
}
```

### 规则3：Tabs 条件渲染时信号必须提升到容器层

**时序风险**：`TabContent` 中使用 `if (index===N && condition)` 条件渲染时，子组件（如 `main_page`）在其他 Tab 下**不存在**，其 `aboutToAppear`/`@Watch` 无法消费信号。

**解决方案**：信号消费点必须提升到 Tabs 容器组件（`mainpage.ets` 的 `struct main`），通过 `@StorageProp` + `@Watch` 在容器层统一处理。

---

## ⚠️ 必须首先导入（编译前必读）

使用 `@InsightIntentEntry` 前必须完整导入以下三个符号：

```typescript
import { InsightIntentEntry, InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';
```

| 导入项                       | 用途                                                | 是否必须 |
| :--------------------------- | :-------------------------------------------------- | :------- |
| `InsightIntentEntry`         | 装饰器，用于修饰执行器类                            | ✅ 必须   |
| `InsightIntentEntryExecutor` | 执行器基类，需继承                                  | ✅ 必须   |
| `insightIntent`              | 命名空间，用于 `ExecuteMode`、`IntentResult` 等类型 | ✅ 必须   |

**❌ 常见错误：只导入基类和命名空间，忘记导入装饰器**

```typescript
// ❌ 错误：缺少装饰器导入
import { InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';
@InsightIntentEntry({...})  // 编译失败：Cannot find name 'InsightIntentEntry'
```

> 💡 **提示**：其他装饰器（Page、Link、Function 等）的导入模板请参阅 [common_rules.md#5](common_rules.md/#5)。

------

## Quick Start

### 快速上手（纯函数型示例）

```typescript
import { insightIntent, InsightIntentEntry, InsightIntentEntryExecutor } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG: string = 'MusicIntent';

@InsightIntentEntry({
  intentName: 'PlayMusic',
  domain: 'MusicDomain',
  intentVersion: '1.0.1',
  displayName: '播放歌曲',
  llmDescription: '播放指定的音乐文件',
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND],
  parameters: {
    'type': 'object',
    'properties': {
      'songName': {
        'type': 'string',
        'description': '歌曲名称',
        'minLength': 1
      }
    },
    'required': ['songName']
  }
})
export default class PlayMusicExecutor extends InsightIntentEntryExecutor<string> {
  songName: string = '';

  onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(0x0000, LOG_TAG, 'Playing song: %{public}s', this.songName);

    // 执行播放逻辑
    this.playMusic(this.songName);

    const intentResult: insightIntent.IntentResult<string> = {
      code: 0,
      result: '播放成功'
    };
    return Promise.resolve(intentResult);
  }

  private playMusic(songName: string): void {
    // 实现播放逻辑
  }
}
```

### 标准意图示例（带 schema 字段）

标准意图使用 `schema` 字段引用系统预定义的意图名称，参数和返回值必须与官方文档一致。

```typescript
import { InsightIntentEntry, InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG: string = 'PlayGameIntent';
const DOMAIN: number = 0x0000;

interface GameResult {
  resultDesc: string;
  entityId: string;
  gameName: string;
  status: string;
}

@InsightIntentEntry({
  intentName: 'PlayGame',
  schema: 'PlayGame',              // ← 标准意图标识，必须与官方文档一致
  domain: 'EntertainmentDomain',   // ← 从官方文档获取
  intentVersion: '1.0.1',          // ← 从官方文档获取
  displayName: '玩转游戏',
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND],
  parameters: {                    // ← 参数定义必须与官方文档一致
    'type': 'object',
    'properties': {
      'entityId': {
        'type': 'string',
        'description': '意图实体ID，长度不超过64字符',
        'minLength': 1
      }
    },
    'required': ['entityId']
  }
})
export default class PlayGameExecutor extends InsightIntentEntryExecutor<GameResult> {
  entityId: string = '';           // ← 属性名与 parameters 中 entityId 对应

  async onExecute(): Promise<insightIntent.IntentResult<GameResult>> {
    hilog.info(DOMAIN, LOG_TAG, 'PlayGame, entityId: %{public}s', this.entityId);

    try {
      // 执行游戏启动逻辑
      // ...

      const result: GameResult = {
        resultDesc: '已启动游戏',
        entityId: this.entityId,
        gameName: '2048',
        status: 'started'
      };
      const intentResult: insightIntent.IntentResult<GameResult> = {
        code: 0,
        result: result
      };
      return Promise.resolve(intentResult);
    } catch (error) {
      const errorResult: GameResult = {
        resultDesc: '启动游戏失败',
        entityId: this.entityId,
        gameName: '',
        status: 'failed'
      };
      const intentResult: insightIntent.IntentResult<GameResult> = {
        code: -1,
        result: errorResult
      };
      return Promise.resolve(intentResult);
    }
  }
}
```

**标准意图与自定义意图对比**：

| 对比项 | 自定义意图 | 标准意图 |
|--------|-----------|----------|
| `schema` 字段 | 无 | 必填，值为标准意图名称 |
| `domain` | 自定义（如 `GameDomain`） | 从官方文档获取（如 `EntertainmentDomain`） |
| `parameters` | 按需求自定义 | 与官方定义完全一致 |
| 参数名 | 自由命名 | 必须使用官方定义的参数名 |
| 返回值 | 自由定义 | 匹配官方定义的返回结构 |

> 📌 **页面跳转型意图**：如果意图功能是打开某个页面（而非执行后台逻辑），`onExecute` 中必须使用 `this.windowStage?.loadContent()` 导航，**不可使用 `router.pushUrl`**（冷启动不可用）。详见下方“页面跳转正确方式”。

**⚠️ 严禁使用 `insightIntent.ExecuteResult`**

旧版文档可能提到 `ExecuteResult`，但该类型**已废弃**且会导致编译错误。
**必须使用 `insightIntent.IntentResult<T>`**，其中 `T` 是你自定义的结果类（必须包含 `resultDesc` 字段）。

**错误示例（禁止）**：

```typescript
async onExecute(): Promise<insightIntent.ExecuteResult> { ... }   // ❌ 错误类型
```

**正确示例**：参见上方 Quick Start。

------

## ⚠️ 页面跳转正确方式

### 关键警告：`loadContent` 与 `router` 互不兼容

**`windowStage.loadContent` 与 `router.pushUrl/replaceUrl` 是两套独立的页面管理机制，不可在同一个 `onExecute` 中混用。**

| 混用方式                             | 后果                                                         |
| :----------------------------------- | :----------------------------------------------------------- |
| 先 `loadContent` 再 `router.pushUrl` | 视图栈不一致，页面闪现/混乱，或跳转被静默忽略                |
| 先 `router.pushUrl` 再 `loadContent` | 路由参数丢失，目标页的 `router.getParams()` 返回 `undefined` |

**正确做法**：

- **Navigation 架构**：只用 `loadContent` + `LocalStorage`
- **Router 架构**：使用 `loadContent` + `AppStorage`（见下方"Router 架构适配方案"）
- **Tabs 架构**：使用 `AppStorage.setOrCreate` 信号驱动

❌ **错误示例（禁止）**：

```typescript
// ❌ 危险：混用两种机制
this.windowStage?.loadContent('pages/Index', (err) => {
  router.pushUrl({ url: 'pages/Target', params: { data: 'xxx' } });
});
```

------

### windowStage 属性说明

`InsightIntentEntryExecutor` 提供以下属性用于页面跳转：

| 属性          | 类型                        | 说明           | 适用场景                     |
| :------------ | :-------------------------- | :------------- | :--------------------------- |
| `windowStage` | `window.WindowStage`        | 窗口舞台对象   | `UI_ABILITY_FOREGROUND` 模式 |
| `executeMode` | `insightIntent.ExecuteMode` | 执行模式       | 所有模式                     |
| `context`     | `InsightIntentContext`      | 意图执行上下文 | 所有模式                     |

> ⚠️ **windowStage 时序警告**：`onExecute` 执行时 `this.windowStage` **可能为 `undefined`**（框架可能在 `onWindowStageCreate` 之后才将其注入执行器）。因此 `this.windowStage?.loadContent()` 是「尽力而为」方式，**不应作为唯一的导航手段**。必须配合下方的「桥接导航模式」作为兜底，覆盖 `windowStage` 未就绪的场景。

### 正确的页面加载方式

#### 方式1：使用 windowStage.loadContent（推荐，冷热启动均可靠）

```typescript
async onExecute(): Promise<insightIntent.IntentResult<string>> {
  let storage = new LocalStorage();
  storage.setOrCreate('targetTab', 3);

  if (this.executeMode == insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
    this.windowStage?.loadContent('pages/Index', storage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, LOG_TAG, '加载失败: %{public}s', JSON.stringify(err));
      }
    });
  }

  const intentResult: insightIntent.IntentResult<string> = {
    code: 0,
    result: '成功'
  };
  return Promise.resolve(intentResult);
}
```

#### 方式2：使用 router.pushUrl（❌ 冷启动不可用）

> ⚠️ **冷启动限制**：
>
> 1. `router.pushUrl/replaceUrl` 在冷启动下路由系统未初始化，调用将静默失败（不报错但页面不跳转）
> 2. **关键细节**：冷启动时不仅跳转失败，**通过 `params` 传入的参数也不会被存储**。因此随后的 `loadContent` 加载目标页后，`router.getParams()` 返回空对象，数据丢失。
> 3. 热启动场景下参数正常存储和传递。
>
> **结论**：仅推荐用于纯热启动场景。如需冷启动支持，请使用方式1或"Router 架构适配方案"。

```typescript
// ⚠️ 此方式仅热启动可用，冷启动会导致参数丢失
async onExecute(): Promise<insightIntent.IntentResult<string>> {
  await router.pushUrl({
    url: 'pages/TargetPage',
    params: { targetTab: 3 }  // 冷启动时参数不会被存储！
  });

  const intentResult: insightIntent.IntentResult<string> = {
    code: 0,
    result: '成功'
  };
  return Promise.resolve(intentResult);
}
```

#### 方式3：Tabs 架构（AppStorage 信号驱动）

适用于应用主界面为 `Tabs` 组件，意图只需切换 Tab 的场景。

```typescript
async onExecute(): Promise<insightIntent.IntentResult<string>> {
  AppStorage.setOrCreate('intentTargetTab', 3); // 目标 Tab 索引
  // 无需 loadContent，TabBar 通过 @StorageLink @Watch 自动响应

  const intentResult: insightIntent.IntentResult<string> = {
    code: 0,
    result: '已跳转到目标标签页'
  };
  return Promise.resolve(intentResult);
}
```

**Tab 页面配套代码**：

```typescript
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

#### 方式4：桥接导航模式（推荐兜底，覆盖 windowStage 未就绪场景）

当 `onExecute` 中 `this.windowStage` 为 `undefined` 时，`loadContent` 被静默跳过。桥接模式通过 AppStorage 信号 + 宿主页面的 `@StorageLink` 响应，使导航在任何启动时序下均生效。

**原理**：
1. EntryAbility 始终 `loadContent` 加载默认页面（如 ListPage/Index）
2. 意图在 `onExecute` 中设置 AppStorage 导航信号
3. 默认页面通过 `@StorageLink` + `@Watch` 响应式捕获信号并 `router.replaceUrl` 跳转
4. `onPageShow` 作为冷启动补充检查

**意图执行器代码**：

```typescript
async onExecute(): Promise<insightIntent.IntentResult<string>> {
  // 设置导航目标和参数（AppStorage 跨上下文可靠）
  AppStorage.setOrCreate('intentTargetPage', 'pages/DetailPage');
  AppStorage.setOrCreate('intentParamKey', paramValue);

  // 同时尝试直接 loadContent（windowStage 就绪时直接生效）
  if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
    this.windowStage?.loadContent('pages/DetailPage', (err) => {
      if (err.code) { /* 静默 */ }
    });
  }

  // ... 返回结果
}
```

**宿主页面配套代码（必须）**：

```typescript
// 在默认页面的 struct 中
@StorageLink('intentTargetPage') @Watch('onIntentTargetChange') intentTargetPage: string = '';

onIntentTargetChange(): void {
  const page: string = this.intentTargetPage;
  if (page) {
    AppStorage.setOrCreate('intentTargetPage', ''); // 消费后重置
    let options: router.RouterOptions = { url: page };
    router.replaceUrl(options).catch((err: Error) => {
      hilog.error(0x0000, TAG, 'Navigate failed: %{public}s', err.message);
    });
  }
}

// 冷启动兜底：@Watch 不触发初始值，需 onPageShow 补充检查
onPageShow(): void {
  const pending: string | undefined = AppStorage.get<string>('intentTargetPage');
  if (pending) {
    AppStorage.setOrCreate('intentTargetPage', '');
    let options: router.RouterOptions = { url: pending };
    router.replaceUrl(options).catch(/*...*/);
  }
}
```

**冷热启动覆盖矩阵**：

| 场景 | 触发路径 | 说明 |
|------|----------|------|
| 冷启动 | `onPageShow` 检查 AppStorage | `@Watch` 不触发初始值 |
| 热启动（同 URL，页面不重建） | `@StorageLink` + `@Watch` 响应式触发 | 页面不重建也能响应 |
| 热启动（不同 URL，回宿主页） | `onPageShow` + `consumeIntentSignal` | 回到宿主页时消费 |

适用于应用主界面为 `Tabs` 组件，意图只需切换 Tab 的场景。

```typescript
async onExecute(): Promise<insightIntent.IntentResult<string>> {
  AppStorage.setOrCreate('intentTargetTab', 3); // 目标 Tab 索引
  // 无需 loadContent，TabBar 通过 @StorageLink @Watch 自动响应

  const intentResult: insightIntent.IntentResult<string> = {
    code: 0,
    result: '已跳转到目标标签页'
  };
  return Promise.resolve(intentResult);
}
```

**Tab 页面配套代码（注意：必须使用 `@StorageLink`，热启动页面不重建时 `@StorageProp` 不会更新）**：

```typescript
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

> ⚠️ **Tabs 条件渲染陷阱**：若 `TabContent` 内包含 `if (index===N && condition)` 条件渲染，子组件在其他 Tab 下**不存在**，其生命周期方法无法消费信号。必须将消费点提升到 Tabs 容器层 struct。

------

## Router 架构适配方案

当目标页面使用 `router.getParams()` 读取参数时，`@InsightIntentEntry` 的冷启动**无法通过 `router.pushUrl/replaceUrl` 传入参数**（路由系统未初始化，参数不会被存储）。

**⚠️ 核心约束**：`router.pushUrl/replaceUrl` 冷启动时不仅跳转静默失败，**参数也不会被存储**。因此 `router.getParams()` 在随后的 `loadContent` 中也读不到数据。此方案依赖于修改目标页面，别无他法。

### 正确做法

1. **在 `onExecute` 中使用 `AppStorage.setOrCreate` 注入数据**
2. **使用 `windowStage.loadContent` 加载目标页面**
3. **最小化修改目标页面**（1-2 行）：在 `aboutToAppear` 中优先从 `AppStorage.get` 读取，兜底 `router.getParams()`

### 完整代码示例

**意图执行器（新增文件，无需修改现有逻辑）**：

```typescript
// entry/src/main/ets/insightintents/OpenAlbumIntent.ets
import { InsightIntentEntry, InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorage } from '@kit.ArkUI';

const LOG_TAG = 'OpenAlbumIntent';
const DOMAIN = 0x0000;

interface OpenAlbumResult {
  resultDesc: string;
  success: boolean;
}

@InsightIntentEntry({
  intentName: 'OpenAlbum',
  domain: 'PhotoDomain',
  intentVersion: '1.0.1',
  displayName: '打开相册',
  llmDescription: '打开相册页面，可按分类筛选照片。当用户说"打开相册"、"看照片"、"查看相册"时调用。',
  keywords: ['相册', '照片', '打开', '查看'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND],
  parameters: {
    'type': 'object',
    'properties': {
      'categoryType': {
        'type': 'string',
        'description': '相册分类：all / favorite / video / screenshot',
        'enum': ['all', 'favorite', 'video', 'screenshot'],
        'default': 'all'
      }
    },
    'required': ['categoryType']
  }
})
export default class OpenAlbumExecutor extends InsightIntentEntryExecutor<OpenAlbumResult> {
  categoryType: string = 'all';

  async onExecute(): Promise<insightIntent.IntentResult<OpenAlbumResult>> {
    hilog.info(DOMAIN, LOG_TAG, 'OpenAlbum, categoryType: %{public}s', this.categoryType);

    try {
      // 1. 数据注入 AppStorage（冷启动唯一可靠的数据通道）
      AppStorage.setOrCreate('intentAlbumCategory', this.categoryType);

      // 2. 加载目标页面（不传 LocalStorage，因为页面用 router.getParams）
      if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
        this.windowStage?.loadContent('pages/AlbumPage', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, LOG_TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
          }
        });
      }

      const result: OpenAlbumResult = {
        resultDesc: `已打开相册，分类：${this.categoryType}`,
        success: true
      };
      return Promise.resolve({ code: 0, result: result });
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      const errorResult: OpenAlbumResult = {
        resultDesc: `打开相册失败: ${errorMsg}`,
        success: false
      };
      return Promise.resolve({ code: -1, result: errorResult });
    }
  }
}
```

**目标页面修改（最小化修改，保持后向兼容）**：

```typescript
// pages/AlbumPage.ets — 仅需增加 5 行
@Entry
@Component
struct AlbumPage {
  @State categoryType: string = 'all';

  aboutToAppear() {
    // ✅ 新增：优先从 AppStorage 读取意图传递的数据
    const intentCategory = AppStorage.get<string>('intentAlbumCategory');
    if (intentCategory) {
      this.categoryType = intentCategory;
      AppStorage.delete('intentAlbumCategory'); // 使用后清除
      return;
    }

    // ✅ 兜底：原有 router.getParams() 逻辑（热启动/普通跳转保持兼容）
    try {
      const params = router.getParams() as Record<string, string>;
      if (params?.categoryType) {
        this.categoryType = params.categoryType;
      }
    } catch (e) {
      // 无参数时使用默认值
    }
  }

  build() {
    // 原有 UI 逻辑不变
  }
}
```

> ⚠️ **热启动场景补充**：当宿主页面已在显示且不重建时（热启动同 URL），`aboutToAppear` 不执行，AppStorage 的兜底读取不会触发。此时需确保宿主页面使用 `@StorageLink`（而非 `@StorageProp`）监听意图参数的变化。详见 [common_rules.md#5.5](common_rules.md/#5.5)。

### 方案对比
| :------------- | :------------------------------------------ | :----------------------------- |
| 冷启动数据传递 | ❌ router 参数不被存储，`getParams()` 返回空 | ✅ AppStorage 可靠传递          |
| 热启动兼容     | ✅ 仅热启动可用                              | ✅ 冷热均可用                   |
| 目标页修改量   | 0                                           | 1-2 行（5 行以内）             |
| 后向兼容性     | N/A                                         | ✅ 优先 AppStorage，兜底 router |

### 适用范围

- **目标页面使用 `router.getParams()` 读取参数** → 必须使用本方案
- **目标页面使用 `@LocalStorageProp`** → 使用 `loadContent` + `LocalStorage`（Navigation 架构）
- **目标页面使用 Tabs** → 使用 `AppStorage` 信号驱动

> ⚠️ **loadContent 加载页面的字段初始化约束**
> 当使用 `loadContent` 加载目标页时，目标页的**字段初始化器不能依赖 `router.getParams()`**（因为 `loadContent` 不会触发路由参数存储，`router.getParams()` 永远返回空对象）。所有参数读取逻辑必须在 `aboutToAppear` 中完成，且字段初始值必须是安全的空值（如 `''`、`0`、`[]`），而非 `undefined`，以避免页面渲染时因字段为 `undefined` 而空白。

> ⚠️ **目标页硬件初始化时序约束**
> 如果目标页涉及硬件初始化（相机、传感器、播放器等），需额外检查：
> 1. **`aboutToAppear` 是否标记 `async`** — ArkUI 中 `aboutToAppear` 的 async Promise 被框架忽略，不会阻塞 `build()`。`onLoad`（在 build 中触发）调用的硬件初始化可能在 permission/DB 未就绪时执行。详见 [common_rules.md#6](references/common_rules.md#6)。
> 2. **`onLoad` + `onPageShow` 是否都调用了硬件初始化** — 两者同时调用可能造成资源竞态。应在 `onPageShow` 中统一处理硬件初始化，`onLoad` 仅设 surfaceId 和回调。
> 3. **工具类 `release()` 方法是否有防重入保护** — 热启动时两次调用可能互相干扰。详见 [code_exploration.md#第3层](references/code_exploration.md#第3层)。

------

### 参数传递方式对比

| 方式           | 适用场景                           | 优点                              | 缺点/注意点                                                  |
| :------------- | :--------------------------------- | :-------------------------------- | :----------------------------------------------------------- |
| LocalStorage   | Navigation 架构参数传递            | 官方推荐，不会丢失                | 依赖组件树传播，Tabs 下不可靠                                |
| AppStorage     | Tabs 架构全局信号驱动              | 跨组件响应可靠                    | 使用后需手动清除信号值                                       |
| router params  | 传统路由跳转                       | 熟悉的方式                        | 冷启动不可用，不适用于意图框架                               |
| **静态类持有** | 同进程内任意页面跳转，无需依赖框架 | 简单可靠，无需考虑 Storage 兼容性 | 需确保数据在页面加载后可用，且页面需在 `aboutToAppear` 中从静态类读取 |

### 参数传递方式补充说明

#### AppStorage 类型安全提醒

使用 `AppStorage.get<T>(key)` 时，泛型 T 应尽量使用简单类型：

```typescript
// ✅ 简单类型，类型安全
const category = AppStorage.get<string>('intentCategory');

// ✅ 简单数组，类型安全
const ids = AppStorage.get<number[]>('intentIds');

// ⚠️ 复合类型（如 Array<Resource>），先用 Object 接收再转型
const raw = AppStorage.get<Object>('intentResources');
const resources = raw as Resource[];  // 需确保写入时类型一致
```

**写入约束**：`AppStorage.setOrCreate(key, value)` 的 value 必须是 JSON 可序列化的值。Resource 类型（如 `$r('app.media.icon')`）是普通对象，可以存储。

#### loadContent 的 LocalStorage 参数适用范围

`windowStage.loadContent(url, storage)` 中的 `storage`（LocalStorage）**仅对使用 `@LocalStorageProp/@LocalStorageLink` 的页面生效**。

| 目标页面参数读取方式                      | loadContent 传 LocalStorage | 是否生效                           |
| :---------------------------------------- | :-------------------------- | :--------------------------------- |
| `@LocalStorageProp` / `@LocalStorageLink` | ✅ 传入                      | ✅ 生效                             |
| `router.getParams()`                      | ✅ 传入                      | ❌ **无效**，需使用 AppStorage 注入 |
| `AppStorage.get()`                        | 不传                        | ✅ 生效（独立于 loadContent）       |
| 无参数                                    | 不传                        | N/A                                |

**结论**：如果目标页面使用 `router.getParams()`，传给 `loadContent` 的 LocalStorage 无效，必须使用 AppStorage 注入方案（见上方"Router 架构适配方案"）。

### 跳转方式兼容性矩阵

| 跳转方式                                  | 冷启动 | 热启动 | 参数传递              | 适用架构   | 推荐度 |
| :---------------------------------------- | :----- | :----- | :-------------------- | :--------- | :----- |
| `loadContent` + LocalStorage              | ✅      | ✅      | `@LocalStorageProp`   | Navigation | ⭐⭐⭐⭐⭐  |
| `loadContent` + AppStorage（Router 适配） | ✅      | ✅      | `AppStorage.get`      | Router     | ⭐⭐⭐⭐⭐  |
| `AppStorage.setOrCreate` 信号驱动         | ✅      | ✅      | `@StorageLink/@Watch` | Tabs       | ⭐⭐⭐⭐⭐  |
| `router.pushUrl` 仅热启动                 | ❌      | ✅      | `router.getParams`    | Router     | ⭐⭐     |
| `loadContent` + `router.pushUrl` 混用     | ❌      | ❌      | 混乱/丢失             | 任何       | ⛔ 禁止 |

**决策路径**：

```text
目标页面读取参数的方式？
  ├─ @LocalStorageProp → loadContent + LocalStorage
  ├─ router.getParams() → loadContent + AppStorage（需修改目标页 1-2 行）
  ├─ 静态类持有 → loadContent + 静态类（无需修改目标页，但需确保数据在 aboutToAppear 前就绪）
  ├─ Tabs + @Watch → AppStorage.setOrCreate 信号驱动
  └─ 无参数 → loadContent 不传参
```

------

### 完整示例（Navigation 架构，遵循 ArkTS 严格模式）

```typescript
import { InsightIntentEntry, InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG: string = 'OpenMinePageIntent';
const DOMAIN: number = 0x0000;

@InsightIntentEntry({
  intentName: 'OpenMinePage',
  domain: 'MineDomain',
  intentVersion: '1.0.1',
  displayName: '我的页面',
  llmDescription: '跳转到应用的"我的"页面',
  keywords: ['我的', '个人中心'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND]
})
export default class OpenMinePageExecutor extends InsightIntentEntryExecutor<string> {
  async onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(DOMAIN, LOG_TAG, 'onExecute');

    try {
      let storage = new LocalStorage();
      storage.setOrCreate('intentTargetTab', 3);

      if (this.executeMode == insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
        this.windowStage?.loadContent('pages/Index', storage, (err) => {
          if (err.code) {
            hilog.error(DOMAIN, LOG_TAG, '加载失败: %{public}s', JSON.stringify(err));
          }
        });
      }

      const intentResult: insightIntent.IntentResult<string> = {
        code: 0,
        result: '已跳转到"我的"页面'
      };
      return Promise.resolve(intentResult);
    } catch (error) {
      hilog.error(DOMAIN, LOG_TAG, '跳转失败: %{public}s', JSON.stringify(error));
      const errorResult: insightIntent.IntentResult<string> = {
        code: -1,
        result: '跳转失败: ' + JSON.stringify(error)
      };
      return Promise.resolve(errorResult);
    }
  }
}
```

### 完整流程

1. **定义意图**：使用 `@InsightIntentEntry` 装饰器
2. **实现执行器**：继承 `InsightIntentEntryExecutor<T>`
3. **重写 onExecute**：实现业务逻辑
4. **注册意图**：在 `insight_intent.json` 中添加文件路径

------

## ⚠️ 常见错误与字段警告

### 错误1：使用错误的字段名

**编译错误**：`'mode' does not exist in type 'EntryIntentDecoratorInfo'`

| 正确字段                    | 错误字段                   | 说明                                                         |
| :-------------------------- | :------------------------- | :----------------------------------------------------------- |
| `abilityName`               | `uiAbility`                | @InsightIntentEntry 使用 `abilityName`，@InsightIntentPage 使用 `uiAbility` |
| `executeMode`               | `mode`                     | 执行模式字段名是 `executeMode`，不是 `mode`                  |
| `insightIntent.ExecuteMode` | `insightIntent.IntentMode` | 使用 `ExecuteMode` 枚举，不是 `IntentMode`                   |

**错误示例：**

```typescript
@InsightIntentEntry({
  intentName: 'QueryHistory',
  domain: 'BrowserDomain',
  intentVersion: '1.0.0',
  displayName: '查询浏览记录',
  uiAbility: 'EntryAbility',  // ❌ 错误：应该是 abilityName
  mode: insightIntent.IntentMode.UI_ABILITY_BACKGROUND,  // ❌ 错误
  parameters: { ... }
})
```

**正确示例：**

```typescript
@InsightIntentEntry({
  intentName: 'QueryHistory',
  domain: 'BrowserDomain',
  intentVersion: '1.0.0',
  displayName: '查询浏览记录',
  abilityName: 'EntryAbility',  // ✅ 正确
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_BACKGROUND],  // ✅ 正确
  parameters: { ... }
})
```

### 错误2：executeMode 不是数组

**编译错误**：`Type 'XXX' is not assignable to type 'ExecuteMode[]'`

```typescript
// ❌ 错误：不是数组
executeMode: insightIntent.ExecuteMode.UI_ABILITY_BACKGROUND

// ✅ 正确：必须是数组
executeMode: [insightIntent.ExecuteMode.UI_ABILITY_BACKGROUND]
```

### 错误3：缺少 abilityName 字段

**编译错误**：`Property 'abilityName' is missing`

**原因**：`abilityName` 是 @InsightIntentEntry 的必填字段，必须指定绑定的 Ability 名称。

**解决方案：**

1. 读取意图文件所在模块的 `module.json5`
2. 获取 `module.abilities[0].name` 的值
3. 使用该值作为 `abilityName`

### 错误4：Promise.resolve 返回值使用未声明的对象字面量

**编译错误**：`Object literal must correspond to some explicitly declared class or interface`

**原因**：ArkTS 严格模式要求所有对象字面量必须有对应的接口定义。

**错误示例：**

```typescript
async onExecute(): Promise<insightIntent.IntentResult<string>> {
  return Promise.resolve({
    code: 0,
    result: '操作成功',
    wantParams: { success: true, message: '操作成功' }
  });
}
```

**正确示例：**

```typescript
interface IntentWantParams { success: boolean; message: string; }
interface IntentResultTyped { code: number; result: string; wantParams: IntentWantParams; }

async onExecute(): Promise<insightIntent.IntentResult<string>> {
  const wantParams: IntentWantParams = { success: true, message: '操作成功' };
  const intentResult: insightIntent.IntentResult<string> = {
    code: 0,
    result: '操作成功',
    wantParams: wantParams
  };
  return Promise.resolve(intentResult);
}
```

### 错误5：throw 语句使用任意类型

**编译错误**：`"throw" statements cannot accept values of arbitrary types`

```typescript
// ❌ 错误
catch (error) { throw error; }

// ✅ 正确
catch (error) {
  throw new Error(`操作失败: ${JSON.stringify(error)}`);
}
```

### 错误6：方法返回类型使用对象字面量声明

**编译错误**：`Object literals cannot be used as type declarations`

```typescript
// ❌ 错误
private validateParams(): { valid: boolean; message: string } { ... }

// ✅ 正确
interface ValidationResult { valid: boolean; message: string; }
private validateParams(): ValidationResult { ... }
```

### 错误7：方法 return 语句直接返回对象字面量

**编译错误**：`Object literal must correspond to some explicitly declared class or interface`

typescript

```
// ❌ 错误：即使定义了接口，也不能直接返回对象字面量
private validateParams(): ValidationResult {
  return { valid: true, message: '' };
}

// ✅ 正确：先创建显式类型变量，再返回
private validateParams(): ValidationResult {
  const result: ValidationResult = { valid: true, message: '' };
  return result;
}
```

### 错误8：泛型参数与 result 字段类型不匹配

**编译错误**：`Types of property 'result' are incompatible`

**错误示例：**

```typescript
// ❌ 泛型是 ContactFullInfo，但 result 是 string
export default class QueryContactExecutor extends InsightIntentEntryExecutor<ContactFullInfo> {
  // result 字段必须是 ContactFullInfo，不能是 string
}
```

**正确示例：**

```typescript
interface ContactFullInfo { name: string; telephony?: string; }

export default class QueryContactExecutor extends InsightIntentEntryExecutor<ContactFullInfo> {
  async onExecute(): Promise<insightIntent.IntentResult<ContactFullInfo>> {
    const contactInfo: ContactFullInfo = { name: '张三', telephony: '13800000000' };
    const intentResult: insightIntent.IntentResult<ContactFullInfo> = {
      code: 0,
      result: contactInfo  // ✅ ContactFullInfo 类型
    };
    return Promise.resolve(intentResult);
  }
}
```

### 错误9：装饰器和基类错误使用 namespace 前缀

**编译错误**：`Property 'InsightIntentEntry' does not exist on type 'typeof insightIntent'`

```typescript
// ❌ 错误：使用 namespace 前缀
@insightIntent.InsightIntentEntry({...})
class MyExecutor extends insightIntent.InsightIntentEntryExecutor<string> {}

// ✅ 正确：直接使用
@InsightIntentEntry({...})
class MyExecutor extends InsightIntentEntryExecutor<string> {}
```

**规则速查**：装饰器和基类直接用，枚举和类型加前缀。

------

## 核心规则

### 代码输出要求

- ✅ 必须使用 `@InsightIntentEntry` 装饰器模式，不允许使用 `InsightIntentExecutor` 基类模式。
- ✅ 功能实现通过继承 `InsightIntentEntryExecutor` 基类实现。
- ✅ 使用 `export default` 导出继承类。
- ✅ 通过重载 `onExecute` 实现具体功能。
- ✅ 只允许在继承类上添加 `@InsightIntentEntry` 装饰器。
- ✅ 类的属性仅支持 ArkTS 语法基础类型或意图实体。
- ✅ 当类的属性是对象类型，必须使用 `@InsightIntentEntity` 装饰器定义意图实体。详见 [insight_intent_entity.md](insight_intent_entity.md/)。
- ✅ 新增文件时，在 `insight_intent.json` 的 `insightIntentsSrcEntry` 数组中添加文件路径。
- ✅ 代码生成后需要自验证，修复语法错误。
- ⚠️ **关于修改现有代码**：
  - 如果目标页面使用 **Navigation 架构**（`@LocalStorageProp`）或 **Tabs 架构**（`@StorageLink`），通常无需修改现有页面代码。
  - 如果目标页面使用 **Router 架构**（`router.getParams()`），冷启动场景下数据传递需要**最小化修改目标页面**（1-2 行），增加 `AppStorage` 兜底读取（详见"Router 架构适配方案"）。
  - 修改原则：保持后向兼容（优先 AppStorage → 兜底 router.getParams() → 最终兜底默认值），仅改动目标页面的 `aboutToAppear` 初始化逻辑，不影响其他功能。

### parameters 与类属性对应规则

> **⚠️ 核心原则**：`@InsightIntentEntry` 的 `parameters.properties` 中的属性名必须与执行器类的属性名**一一对应**！

> **⚠️ JSON Schema 类型限制**：parameters 中的 `type` 只支持 `string`、`number`、`boolean`、`array`、`object`。不支持 `integer`（使用 `number`）。
>
> ⚠️ **`boolean` 类型避坑**：部分 SDK 版本对 `type: 'boolean'` 的参数注入存在兼容性问题，`onExecute` 可能静默不执行（hilog 无输出）。**建议改用 `string` + `enum` 替代**，在 `onExecute` 内转 `boolean`：
> ```typescript
> // 装饰器 parameters 定义
> 'enable': { 'type': 'string', 'enum': ['true', 'false'] }
> // 类属性
> enable: string = 'true';
> // onExecute 中转换
> const enabled: boolean = this.enable === 'true';
> ```

#### 规则1：简单类型参数

```typescript
// ✅ 正确：属性名一致
@InsightIntentEntry({
  parameters: {
    'properties': {
      'songName': { 'type': 'string', 'description': '歌曲名称' }
    },
    'required': ['songName']
  }
})
export default class PlayMusicExecutor extends InsightIntentEntryExecutor<string> {
  songName: string = '';  // 类属性名 = parameters 属性名
}

// ❌ 错误：属性名不匹配
@InsightIntentEntry({
  parameters: { 'properties': { 'musicName': { 'type': 'string' } } }
})
export default class PlayMusicExecutor extends InsightIntentEntryExecutor<string> {
  songName: string = '';  // 无法注入
}
```

#### 规则2：类属性类型禁止联合类型

```typescript
// ❌ 错误：联合类型不匹配 string
type SourceType = 'file_manager' | 'gallery';
source: SourceType = 'file_manager';

// ✅ 正确：使用基础类型
source: string = 'file_manager';
```

### 参数默认值与必填性

`@InsightIntentEntry.parameters.required` 数组中的参数，框架在 `onExecute` 调用时保证该类属性已被赋值。但需要理解以下行为：

| 场景                             | 框架行为           | 类属性值                    |
| :------------------------------- | :----------------- | :-------------------------- |
| 大模型传参                       | 注入传入值         | `this.param = 'user_value'` |
| 大模型未传参（required 中声明）  | 不注入，保留默认值 | `this.param = ''`（默认值） |
| 大模型未传参（未在 required 中） | 不注入，保留默认值 | `this.param = ''`（默认值） |

**⚠️ 关键结论**：`required` 数组不强制校验参数是否存在，仅用于大模型理解必填性。框架不会因为参数缺失而抛出错误。

**最佳实践**：

```typescript
// ✅ 在 onExecute 中对必填参数做防御性检查
async onExecute(): Promise<insightIntent.IntentResult<MyResult>> {
  if (!this.categoryType || this.categoryType === '') {
    // 返回错误，提示用户补充参数
    const errorResult: MyResult = {
      resultDesc: '请指定相册分类（all/favorite/video/screenshot）',
      success: false
    };
    return Promise.resolve({ code: -2, result: errorResult });
  }
  // 业务逻辑...
}

// ✅ 对于可选参数，使用 ?? 提供默认值
const pageSize: number = this.pageSize ?? 20;
```

#### 检查清单

| 检查项       | 说明                                              |
| :----------- | :------------------------------------------------ |
| 属性名一致   | `parameters.properties` 的属性名 = 执行器类属性名 |
| 类型一致     | JSON Schema 类型 = 类属性类型（禁止联合类型）     |
| 嵌套定义完整 | 对象类型属性必须在 `properties` 中定义子属性      |
| 必填标记     | 必填属性在 `required` 数组中列出                  |

------

## 代码生成检查清单

### 🔴 必须检查（导致编译失败）

- 所有类属性都有初始值
- 没有使用解构赋值
- 所有变量都有显式类型声明
- 对象字面量必须对应显式声明的类或接口
- Promise 返回值使用 `resolve()` 而不是 `reject()`
- `@InsightIntentEntry` 所有必填字段已填写
- 执行器类使用 `export default` 导出
- 装饰器和基类直接使用，不使用 namespace 前缀
- 枚举和类型使用 namespace 前缀
- 方法返回类型不能使用对象字面量
- return 语句不能直接返回对象字面量
- `Promise.resolve()` 中的对象字面量使用显式类型声明

### 🟡 建议检查（可能导致运行时错误）

- 错误处理中有显式类型转换
- 可选属性访问都提供了默认值（使用 `??`）
- `onExecute()` 返回 `Promise<insightIntent.IntentResult<T>>`
- JsonSchema 中 `required` 与实际参数匹配
- **页面跳转型意图是否同时实现了 `windowStage.loadContent` + 桥接导航信号（`@StorageLink` + `onPageShow`）双重保障？**
- **桥接导航的信号名称是否与项目已有 AppStorage 键名冲突？**
- **`loadContent` 是否包裹在 `if (this.executeMode == insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND)` 条件中？**
- **`loadContent` 回调中是否处理了 `err.code` 非零的情况？**
- **目标页字段初始值是否不为 `undefined`**（尤其是使用 `loadContent` 加载的页面，字段应初始化为 `''`、`0`、`[]` 等安全空值）

### 🟡 运行时场景检查（页面跳转型）

- **冷启动**：应用未运行 → 调用意图 → 页面正确显示 + 功能正常
- **热启动（同 URL）**：应用在前台且目标页已打开 → 再次调用意图 → 硬件/功能正常（相机/传感器等）
- **热启动（不同 URL）**：应用在前台 → 调用意图跳转不同页面 → 新页面正确加载
- **参数必填性**：必填参数缺失时，意图是否返回友好错误提示（而非崩溃）
- **Router 架构适配**：若目标页使用 `router.getParams()`，是否已增加 `AppStorage` 兜底读取
- **空白页面检查**：冷启动/热启动下页面是否非空白（`aboutToAppear` 中完成数据初始化，字段初始值安全）

### 🟢 优化建议

- 没有使用 `any` 类型
- `llmDescription` 描述详细且清晰
- 使用了合适的 `domain` 和 `executeMode`
- 错误代码使用标准值（0, -1, -2, -3, -4, -5）

------

## 快速参考

### @InsightIntentEntry 必填字段

| 字段            | 类型   | 说明                                        | 示例                                                |
| :-------------- | :----- | :------------------------------------------ | :-------------------------------------------------- |
| `intentName`    | string | 英文 PascalCase，动词-名词结构              | `"PlayMusic"`                                       |
| `domain`        | string | 域标识符                                    | `"MusicDomain"`                                     |
| `intentVersion` | string | 语义化版本，三位数格式                      | `"1.0.1"`                                           |
| `displayName`   | string | 中文显示名称                                | `"播放音乐"`                                        |
| `abilityName`   | string | 绑定的 Ability 名称，从 `module.json5` 获取 | `"EntryAbility"`                                    |
| `executeMode`   | array  | 支持的执行模式，必须是数组                  | `[insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND]` |

### @InsightIntentEntry 可选字段

| 字段                 | 类型                   | 说明                           |
| :------------------- | :--------------------- | :----------------------------- |
| `displayDescription` | string                 | 详细描述                       |
| `schema`             | string                 | 标准意图 schema                |
| `icon`               | ResourceStr            | 图标资源                       |
| `llmDescription`     | string                 | LLM 理解描述（自定义意图必填） |
| `keywords`           | string[]               | 搜索关键词（自定义意图必填）   |
| `parameters`         | Record<string, Object> | 参数 JSON Schema               |
| `result`             | Record<string, Object> | 返回值 JSON Schema             |

### 执行模式（executeMode）选择指南

| 模式                        | 值   | 说明                      | 适用场景                                                |
| :-------------------------- | :--- | :------------------------ | :------------------------------------------------------ |
| `UI_ABILITY_FOREGROUND`     | 0    | 前台 UI Ability，有窗口   | **页面跳转、UI 交互**（必须使用此模式）                 |
| `UI_ABILITY_BACKGROUND`     | 1    | 后台 UI Ability，无窗口   | 数据查询、后台计算（此时 `windowStage` 为 `undefined`） |
| `UI_EXTENSION_ABILITY`      | 2    | UI Extension Ability      | 扩展 UI 场景                                            |
| `SERVICE_EXTENSION_ABILITY` | 3    | Service Extension Ability | 后台服务场景                                            |

> ⚠️ **页面跳转意图必须使用 `UI_ABILITY_FOREGROUND`**，否则 `windowStage` 为 `undefined` 无法加载页面。

### 错误代码

| 代码 | 说明       |
| :--- | :--------- |
| `0`  | 成功       |
| `-1` | 通用错误   |
| `-2` | 参数无效   |
| `-3` | 网络错误   |
| `-4` | 权限拒绝   |
| `-5` | 资源未找到 |

### 常用域

| 域                     | 说明     | 示例意图                  |
| :--------------------- | :------- | :------------------------ |
| `MusicDomain`          | 音乐功能 | PlayMusic, SearchSong     |
| `ToolsDomain`          | 通用工具 | ProcessData, DownloadFile |
| `SystemSettingsDomain` | 系统设置 | OpenSettings, ChangeTheme |
| `NavigationDomain`     | 导航     | NavigateToLocation        |
| `ChatDomain`           | 消息     | SendMessage               |
| `HealthDomain`         | 健康追踪 | LogWeight, TrackExercise  |

------

## 注意事项

1. **参数描述亲和大模型**：生成参数描述时，需要亲和大模型，更容易被大模型理解和调用。
2. **最多输出一个意图结果**：如果用户提供信息无法进行生成，提示用户补充功能描述。
3. **检查参数类型匹配**：意图必须实现所有必选参数且类型匹配。
4. **导出要求**：被 `@InsightIntentEntry` 装饰的类需要使用 `export default` 导出。

------

## 相关资源

- [InsightIntentEntry API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-insightintentdecorator#insightintententry)
- [InsightIntentEntryExecutor API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-insightintententryexecutor)
- [InsightIntentEntity API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-insightintentdecorator#insightintententity)
- [JsonSchema 规范](jsonschema_reference.md/)
- [common_rules.md](common_rules.md/) - 公共规则