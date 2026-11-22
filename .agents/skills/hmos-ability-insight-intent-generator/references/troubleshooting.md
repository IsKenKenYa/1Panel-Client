# 常见问题与解决方案

## 一、编译错误

### Q1: 编译错误 "Cannot find module '@kit.CoreGraphicsKit' or its corresponding type declarations"

**原因**：使用了错误的导入路径，`insightIntent.IntentResult` 应该从 `@kit.AbilityKit` 导入，而不是 `@kit.CoreGraphicsKit`。

**解决方案**：
```typescript
// ❌ 错误：错误的导入路径
import { insightIntent } from '@kit.CoreGraphicsKit';
import { InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';

// ✅ 正确：所有意图相关导入都从 @kit.AbilityKit
import { insightIntent, InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';
```

**⚠️ 重要规则**：

- `insightIntent` 命名空间及其类型（如 `insightIntent.IntentResult`、`insightIntent.IntentEntity`、`insightIntent.ExecuteMode`）必须从 `@kit.AbilityKit` 导入。
- `@kit.CoreGraphicsKit` 不包含意图相关的类型定义。

### Q2: 编译错误 "Cannot find name 'InsightIntentEntry'"

**错误示例**：`error: Cannot find name 'InsightIntentEntry'. Did you mean 'insightIntent'?`

**原因**：导入语句中缺少装饰器本身（只导入了基类或命名空间）。

**解决方案**：

```typescript
// ❌ 错误：只导入基类和命名空间
import { InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';
@InsightIntentEntry({...})  // 编译失败

// ✅ 正确：完整导入装饰器、基类、命名空间
import { InsightIntentEntry, InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';
```

**类似错误及正确导入**：

| 装饰器                                                    | 完整导入语句                                                 |
| :-------------------------------------------------------- | :----------------------------------------------------------- |
| `@InsightIntentPage`                                      | `import { InsightIntentPage } from '@kit.AbilityKit';`       |
| `@InsightIntentLink`                                      | `import { InsightIntentLink } from '@kit.AbilityKit';`       |
| `@InsightIntentFunction` + `@InsightIntentFunctionMethod` | `import { InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';` |

### Q3: 编译错误 "Argument of type '{ name: string; ... }' is not assignable to parameter of type 'FunctionIntentDecoratorInfo'"

**原因**：`@InsightIntentFunctionMethod` 装饰器参数中使用了不存在的 `name` 字段，或缺少必需字段。

**解决方案**：

```typescript
// ❌ 错误：使用了不存在的 'name' 字段，缺少必需字段
@InsightIntentFunctionMethod({
  name: 'queryGameList',  // ❌ 'name' 字段不存在
  llmDescription: '查询游戏列表',
  keywords: ['游戏', '列表'],
  result: {...}
})

// ✅ 正确：使用正确的字段名，包含所有必需字段
@InsightIntentFunctionMethod({
  intentName: 'QueryGameList',        // ✅ 必需：意图名称
  domain: 'GameDomain',                // ✅ 必需：意图垂域
  intentVersion: '1.0.0',              // ✅ 必需：版本号
  displayName: '查询游戏列表',         // ✅ 必需：显示名称
  displayDescription: '查询应用支持的所有小游戏',
  icon: $r('app.media.app_icon'),
  llmDescription: '查询游戏列表',
  keywords: ['游戏', '列表'],
  result: {...}
})
```

**@InsightIntentFunctionMethod 必需字段清单**：

| 字段            | 类型   | 必需 | 说明                       | 示例                           |
| :-------------- | :----- | :--- | :------------------------- | :----------------------------- |
| `intentName`    | string | ✅    | 意图名称（英文PascalCase） | `"QueryGameList"`              |
| `domain`        | string | ✅    | 意图垂域                   | `"GameDomain"`, `"LifeDomain"` |
| `intentVersion` | string | ✅    | 版本号                     | `"1.0.0"`                      |
| `displayName`   | string | ✅    | 中文显示名称               | `"查询游戏列表"`               |

**常见错误对照表**：

| 错误字段      | 正确字段                                 | 说明             |
| :------------ | :--------------------------------------- | :--------------- |
| `name`        | `intentName`                             | 意图名称字段     |
| `description` | `llmDescription` 或 `displayDescription` | 描述字段区分用途 |

### Q4: 编译错误 "Property 'xxx' has no initializer"

**原因**：ArkTS 要求所有类属性必须初始化。

**解决方案**：

```typescript
// ❌ 错误
export default class MyExecutor extends InsightIntentEntryExecutor<string> {
  songName: string;
}

// ✅ 正确
export default class MyExecutor extends InsightIntentEntryExecutor<string> {
  songName: string = '';
}
```

### Q5: 编译错误 "Object literal must correspond to some explicitly declared class or interface"

**原因**：ArkTS 不允许使用未声明的对象字面量。

**解决方案**：

```typescript
// ❌ 错误
const result = { code: 0, result: '播放成功' };

// ✅ 正确：定义接口并使用显式类型
interface PlayMusicResult {
  code: number;
  result?: string;
}
const result: PlayMusicResult = { code: 0, result: '播放成功' };
```

**常见场景及解决方案**：

#### 场景1：router.pushUrl 调用

```typescript
// ❌ 错误：内联对象字面量
await router.pushUrl({ url: 'pages/Playnow', params: { playindex: playIndex } });

// ✅ 正确：定义接口
interface RouterParams { playindex: number; }
interface RouterOptions { url: string; params: RouterParams; }
const routerOptions: RouterOptions = { url: 'pages/Playnow', params: { playindex: playIndex } };
await router.pushUrl(routerOptions);
```

#### 场景2：Promise.resolve 返回值

```typescript
// ❌ 错误
return Promise.resolve({ code: 0, result: '播放成功' });

// ✅ 正确
interface IntentResult { code: number; result: string; }
const successResult: IntentResult = { code: 0, result: '播放成功' };
return Promise.resolve(successResult);
```

#### 场景3：嵌套对象字面量

```typescript
// ❌ 错误
emitter.emit('event', { data: { name: 'test', value: 1 } });

// ✅ 正确
interface EventData { name: string; value: number; }
interface EmitPayload { data: EventData; }
const eventData: EventData = { name: 'test', value: 1 };
const emitPayload: EmitPayload = { data: eventData };
emitter.emit('event', emitPayload);
```

### Q6: 编译错误 "Destructuring variable declarations are not supported"

**原因**：ArkTS 不支持解构赋值语法（包括对象解构和数组解构）。

**解决方案**：

#### 对象解构

```typescript
// ❌ 错误
const { songName, artistName } = this.params;
const { songlist } = await import('../data/music');

// ✅ 正确
const songName: string = this.params.songName || '';
const artistName: string = this.params.artistName || '';
const musicModule = await import('../data/music');
const songlist = musicModule.songlist;
```

#### 数组解构

```typescript
// ❌ 错误
const [wA, hA] = resolution.split('x').map(Number);
const [first, second] = items;

// ✅ 正确
const parts: string[] = resolution.split('x');
const wA: number = Number(parts[0]);
const hA: number = Number(parts[1]);
// 或
const nums: number[] = resolution.split('x').map(Number);
const wA: number = nums[0];
const hA: number = nums[1];
```

### Q7: 编译错误 "Property 'xxx' does not exist on type"

**原因**：调用了不存在的静态方法或属性。

**解决方案**：

```typescript
// ❌ 错误：假设 avplayerClass 有 seturl 方法
avplayerClass.seturl(song.url);

// ✅ 正确：使用实际存在的方法
avplayerClass.singplay(song);
```

### Q8: 编译错误 "The field type of the class property does not match the JSON Schema"

**原因**：类属性类型使用了联合类型，与 JSON Schema 定义的基础类型不匹配。

**解决方案**：

```typescript
// ❌ 错误：类属性使用联合类型
type SourceType = 'file_manager' | 'gallery';
@InsightIntentEntry({ parameters: { properties: { source: { type: 'string', enum: ['file_manager', 'gallery'] } } } })
export default class PlayExecutor extends InsightIntentEntryExecutor<Result> {
  source: SourceType = 'file_manager';  // ❌ 联合类型不匹配
}

// ✅ 正确：类属性使用基础类型
export default class PlayExecutor extends InsightIntentEntryExecutor<Result> {
  source: string = 'file_manager';  // ✅ string 类型匹配
}
```

**类型对应表**：

| JSON Schema type | 类属性类型 | 禁止使用                |
| :--------------- | :--------- | :---------------------- |
| `string`         | `string`   | `'a' | 'b'` 联合类型    |
| `number`         | `number`   | `1 | 2` 联合类型        |
| `boolean`        | `boolean`  | `true | false` 联合类型 |

### Q9: 编译错误 "Failed to generate standard OHMUrl"

**原因**：使用意图装饰器前，未在项目配置中启用 `useNormalizedOHMUrl`。

**解决方案**：在项目根目录的 `build-profile.json5` 中添加配置：

```json5
{
  "app": {
    "products": [{
      "buildOption": {
        "strictMode": {
          "useNormalizedOHMUrl": true
        }
      }
    }]
  }
}
```

### Q10: 编译错误 "Namespaces cannot be used as objects"

**原因**：动态导入后使用模块命名空间作为对象类型。

**解决方案**：

```typescript
// ❌ 错误：动态导入后使用模块命名空间
import('@kit.BasicServicesKit').then((module) => {
  const emitterModule = module.emitter;
  const eventData: emitterModule.EventData = { data: {} };  // ❌
});

// ✅ 正确：使用静态导入
import { emitter } from '@kit.BasicServicesKit';
const eventData: emitter.EventData = { data: {} };
```

### Q11: 编译错误 "throw statements cannot accept values of arbitrary types"

**原因**：ArkTS 严格模式下，`throw` 只能抛出 `Error` 类型，不能抛出任意类型。

**解决方案**：

```typescript
// ❌ 错误
catch (error) {
  throw error;
}

// ✅ 正确
catch (error) {
  throw new Error(`Failed: ${JSON.stringify(error)}`);
}
```

### Q12: 编译错误 "Type 'undefined' is not assignable to type 'XXX'"

**原因**：ArkTS 严格类型检查，变量类型不包含 `undefined`。

**解决方案**：

```typescript
// ❌ 错误
private obj: SomeType = undefined;

// ✅ 正确：使用联合类型
private obj: SomeType | undefined = undefined;
```

### Q13: 编译错误 "Object literals cannot be used as type declarations"

**原因**：ArkTS 要求对象字面量必须有显式类型声明，不允许使用内联类型定义。

**解决方案**：

```typescript
// ❌ 错误
type FileInfo = { prefix: string; suffix: string; };

// ✅ 正确：定义接口
interface FileInfo { prefix: string; suffix: string; }
```

### Q14: 编译错误 "Importing ArkTS files in JS and TS files is forbidden"

**原因**：`.ts` 文件不能导入 `.ets` 文件（ArkTS 编译限制）。

**解决方案**：

```typescript
// ❌ 错误：.ts 文件导入 .ets 文件
// PhotoModel.ts
import { GlobalContext } from './GlobalContext.ets';

// ✅ 正确方案 1：将 GlobalContext 改为 .ts 文件
import { GlobalContext } from './GlobalContext';

// ✅ 正确方案 2：将 PhotoModel 改为 .ets 文件
// PhotoModel.ets
import { GlobalContext } from './GlobalContext.ets';
```

### Q15: 编译错误 "Using 'this' inside stand-alone functions is not supported"

**原因**：ArkTS 不支持在静态方法中使用 `this` 访问静态成员，必须使用类名。

**解决方案**：

```typescript
// ❌ 错误
public static getInstance(): MyClass {
  if (this.instance === undefined) { ... }
  return this.instance;
}

// ✅ 正确
public static getInstance(): MyClass {
  if (MyClass.instance === undefined) { ... }
  return MyClass.instance;
}
```

------

## 二、运行时错误

### Q16: 运行时错误 "Cannot read property 'xxx' of undefined"

**原因**：访问可选属性时未提供默认值。

**解决方案**：

```typescript
// ❌ 错误
const name: string = this.params.name;

// ✅ 正确
const name: string = this.params.name || '';
// 或使用空值合并运算符
const name: string = this.params.name ?? '';
```

### Q17: 运行时错误 16000001 "指定的Ability名称不存在"

**原因**：`abilityName` 配置值与意图文件所在模块的 `module.json5` 中定义的 Ability 名称不一致。

**解决方案**：

1. 根据意图文件的路径确定所在模块（如 `entry`、`feature` 等）。
2. 读取该模块的 `module.json5` 文件。
3. 找到 `module.abilities[0].name` 的值。
4. 使用该值作为 `abilityName`。

```typescript
// ❌ 错误：使用默认值
@InsightIntentEntry({ abilityName: 'EntryAbility', ... })

// ✅ 正确：使用 module.json5 中定义的名称
@InsightIntentEntry({ abilityName: 'MainAbility', ... })
```

**常见错误对照表**：

| module.json5 中的 name | 错误的 abilityName | 正确的 abilityName |
| :--------------------- | :----------------- | :----------------- |
| MainAbility            | EntryAbility       | MainAbility        |
| EntryAbility           | MainAbility        | EntryAbility       |
| VideoPlayAbility       | EntryAbility       | VideoPlayAbility   |

### Q18: 运行时错误 冷启动后手动打开应用白屏（@InsightIntentFunctionMethod 特有）

**现象**：通过 `@InsightIntentFunctionMethod` 意图冷启动应用后，用户手动点击图标打开应用，出现白屏或空白页面。

**原因**：

- `@InsightIntentFunctionMethod` 意图以 `background` 模式执行时，Ability 冷启动**不执行 `onWindowStageCreate`**，因此窗口未创建。
- 关键资源初始化（如播放器 `setContext`、数据库初始化）可能仅在 `onWindowStageCreate` 中执行，冷启动后缺失。
- 后续用户手动启动应用（`singleton` Ability 已存在），系统调用 `onNewWant` 而非 `onWindowStageCreate`，但应用没有窗口恢复逻辑，导致白屏。

**解决方案**：
必须同步改造 `EntryAbility.ets`，确保：

1. 关键资源初始化放在 `onCreate` 中（幂等）。
2. `onNewWant` / `onForeground` 中使用 `window.getLastWindow` 恢复窗口内容（**禁止使用 `createWindow`**）。
3. 路由操作在窗口就绪后执行。

**✅ 正确兜底代码模板：**

```typescript
// EntryAbility.ets
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import window from '@ohos.window';

const LOG_TAG = 'EntryAbility';
const MAIN_PAGE = 'pages/Index';

export default class EntryAbility extends UIAbility {
  private windowContentReady: boolean = false;
  private pendingIntent?: Want;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // ✅ 改造1：关键资源初始化放在 onCreate
    this.initCriticalResources();
    this.handleInsightIntent(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowContentReady = true;
    windowStage.loadContent(MAIN_PAGE, (err) => {
      if (!err.code && this.pendingIntent) {
        this.handleNavigation(this.pendingIntent);
        this.pendingIntent = undefined;
      }
    });
  }

  onWindowStageDestroy(): void {
    this.windowContentReady = false;
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleInsightIntent(want);
    if (!this.windowContentReady) {
      this.pendingIntent = want;
      this.ensureWindowContent();
    } else {
      this.handleNavigation(want);
    }
  }

  onForeground(): void {
    if (!this.windowContentReady) {
      this.ensureWindowContent();
    }
  }

  // ✅ 改造2：使用 getLastWindow 恢复窗口，禁止 createWindow
  private ensureWindowContent(): void {
    if (this.windowContentReady) return;

    window.getLastWindow(this.context)
      .then((win: window.Window) => {
        this.initWindowContent(win);
      })
      .catch((err: Error) => {
        hilog.error(0x0000, LOG_TAG, 'getLastWindow failed: %{public}s', err.message);
      });
  }

  private initWindowContent(win: window.Window): void {
    win.setUIContent(MAIN_PAGE, (err) => {
      if (err.code) {
        hilog.error(0x0000, LOG_TAG, 'setUIContent failed: %{public}s', err.message);
        return;
      }
      this.windowContentReady = true;
      win.showWindow().catch((e: Error) => {
        hilog.error(0x0000, LOG_TAG, 'showWindow failed: %{public}s', e.message);
      });
      if (this.pendingIntent) {
        this.handleNavigation(this.pendingIntent);
        this.pendingIntent = undefined;
      }
    });
  }

  private handleInsightIntent(want: Want): void {
    // 解析意图参数，设置路由目标（不执行跳转）
  }

  private handleNavigation(want: Want): void {
    // 窗口已就绪，执行页面跳转（如 router.pushUrl 或 AppStorage 信号）
  }

  private initCriticalResources(): void {
    // 播放器 setContext、数据库初始化等（幂等）
  }
}
```

**⚠️ 禁止事项**：

- ❌ 禁止使用 `window.createWindow(MAIN_WINDOW_NAME, window.WindowType.TYPE_MAIN, this.context)` — singleton Ability 的主窗口由系统自动创建，再次创建会导致窗口冲突闪退。
- ❌ 禁止将关键资源初始化仅放在 `onWindowStageCreate` 中。

**相关检查**：详见 [code_exploration.md](code_exploration.md/) 第 3 节和第 5 节。

------

## 三、意图未生效

### Q19: 意图未生效

**原因**：未在 `insight_intent.json` 中注册（仅适用于新增意图文件）。

**解决方案**：

```json
{
  "insightIntentsSrcEntry": [
    { "srcEntry": "./ets/insightintents/myIntentImpl.ets" }
  ]
}
```

**注意**：配置格式必须是对象数组，每个对象包含 `srcEntry` 字段：

```json
// ❌ 错误：直接使用字符串
{ "insightIntentsSrcEntry": [ "./ets/insightintents/myIntentImpl.ets" ] }

// ✅ 正确：使用 srcEntry 对象
{ "insightIntentsSrcEntry": [ { "srcEntry": "./ets/insightintents/myIntentImpl.ets" } ] }
```

### Q20: LLM 无法正确调用意图

**原因**：`llmDescription` 描述不够详细。

**解决方案**：

```typescript
// ❌ 过于简单
llmDescription: '搜索音乐'

// ✅ 详细描述
llmDescription: '根据关键词搜索音乐库中的歌曲。支持按歌曲名称、歌手名称进行模糊搜索。返回匹配的歌曲列表，包含歌曲ID、名称、歌手和URL信息。'
```

### Q36: 冷启动后 Tab 不切换（@InsightIntentEntry + Tabs 架构）

**现象**：意图触发后应用打开，但 Tab 停留在首页，未切换到目标 Tab。

**原因**：`@StorageLink` 的 `@Watch` 不触发初始值。冷启动时序：
① 意图写入 AppStorage → ② 组件创建时 `@StorageLink` 读到初始值 → ③ `@Watch` 不触发 → ④ `changeIndex` 未执行。

**解决方案**：在组件的 `aboutToAppear` 中增加冷启动消费：

```typescript
aboutToAppear(): void {
  if (this.intentTargetTab >= 0) {
    this.currentIndex = this.intentTargetTab;
    this.tabController?.changeIndex(this.currentIndex);
    AppStorage.setOrCreate('intentTargetTab', -1);
  }
}
```

------

## 四、配置错误

### Q21: 编译错误 "PagePath in @InsightIntentPage does not match the actual page path"

**原因**：`pagePath` 路径格式不正确，使用了 `main_pages.json` 的路径格式而非 `@InsightIntentPage` 要求的格式。

**解决方案**：

| 配置项                        | 错误格式                           | 正确格式                    |
| :---------------------------- | :--------------------------------- | :-------------------------- |
| `@InsightIntentPage.pagePath` | `'pages/ColorBlocks'`              | `'./ets/pages/ColorBlocks'` |
| `@InsightIntentPage.pagePath` | `'src/main/ets/pages/ColorBlocks'` | `'./ets/pages/ColorBlocks'` |
| `@InsightIntentPage.pagePath` | `'./ets/pages/ColorBlocks.ets'`    | `'./ets/pages/ColorBlocks'` |

**路径转换规则**：在 `main_pages.json` 路径前添加 `./ets/` 前缀，去掉 `.ets` 后缀。

### Q22: 装饰器使用错误的字段名（@InsightIntentEntry）

**编译错误**：`'mode' does not exist in type 'EntryIntentDecoratorInfo'`

**错误代码**：

```typescript
@InsightIntentEntry({
  mode: insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND,  // ❌
  parameters: { ... }
})
```

**正确代码**：

```typescript
@InsightIntentEntry({
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND],  // ✅ 必须是数组
  parameters: { ... }
})
```

### Q23: executeMode 不是数组

**编译错误**：`Type 'ExecuteMode' is not assignable to type 'ExecuteMode[]'`

**解决方案**：

```typescript
// ❌ 错误
executeMode: insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND

// ✅ 正确
executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND]
```

------

## 五、EntryAbility 中 URI 处理的常见错误

### Q24: 使用索引访问参数

**错误代码**：

```typescript
const page = want.parameters['page'];
```

**正确代码**：

```typescript
interface WantParams { page?: string; }
const params: WantParams = want.parameters as WantParams;
const page = params.page;
```

### Q25: router.pushUrl 使用内联对象字面量

**错误代码**：

```typescript
router.pushUrl({ url: url, params: params });
```

**正确代码**：

```typescript
interface RouterOptions { url: string; params?: RouterParams; }
const options: RouterOptions = { url: url, params: params };
router.pushUrl(options);
```

------

## 六、@InsightIntentPage 装饰器误用

### Q26: @InsightIntentPage 只能用于 struct

**编译错误**：

```text
ERROR: The '@InsightIntentPage' decorator can only be used with 'struct'.
ERROR: @InsightIntentPage must be applied to a struct page.
```

**错误示例**：创建单独的意图类文件。

**正确示例**：直接在页面 struct 上添加装饰器。

```typescript
@InsightIntentPage({ ... })
@Entry
@Component
struct Index { ... }
```

**关键要点**：

- @InsightIntentPage 必须用在已存在的页面 struct 上
- 装饰器顺序：`@InsightIntentPage` → `@Entry` → `@Component` → `struct`
- 不创建单独的意图文件，不需要在 insight_intent.json 中配置

------

## 七、参数多参数定义问题

### Q27: 多参数时如何定义

**原因**：参数数量 ≥ 2 时建议使用 `@InsightIntentEntity`。

**解决方案**：

```typescript
@InsightIntentEntity({
  entityCategory: 'params category',
  parameters: { type: 'object', properties: { param1: { type: 'string' }, param2: { type: 'number' } }, required: ['param1', 'param2'] }
})
export class MyParams implements insightIntent.IntentEntity {
  entityId: string = '0x01';
  param1: string = '';
  param2: number = 0;
}

@InsightIntentEntry({
  parameters: {
    type: 'object',
    properties: {
      params: { type: 'object', properties: { param1: { type: 'string' }, param2: { type: 'number' } }, required: ['param1', 'param2'] }
    },
    required: ['params']
  }
})
export default class MyExecutor extends InsightIntentEntryExecutor<string> {
  params: MyParams = new MyParams();
}
```

------

## 八、其他常见错误

### Q28: onExecute 返回值对象字面量未声明类型

**错误代码**：

```typescript
async onExecute(): Promise<insightIntent.IntentResult<string>> {
  return Promise.resolve({ code: 0, result: '成功', wantParams: { success: true } });
}
```

**正确代码**：

```typescript
interface IntentWantParams { success: boolean; }
interface IntentResultTyped { code: number; result: string; wantParams: IntentWantParams; }

const wantParams: IntentWantParams = { success: true };
const result: IntentResultTyped = { code: 0, result: '成功', wantParams: wantParams };
return Promise.resolve(result as insightIntent.IntentResult<string>);
```

### Q29: 多参数时类属性使用联合类型导致类型不匹配

已在 Q8 中覆盖。

### Q30: abilityName 与 module.json5 不匹配导致 16000001

已在 Q17 中覆盖。

### Q31: @InsightIntentForm 卡片一直显示初始值/空数据

**原因**：`AppStorage`/模块静态变量在 UIAbility 和 FormExtensionAbility 之间不共享。
`onAddForm` 同步返回时读到的是默认值。

**解决方案**：
1. 新建 `DataProvider.ets`，使用 `fs.openSync + fs.writeSync + fs.readTextSync + fs.closeSync` 同步文件读写
2. 主应用在数据变化时调用 `saveXxx()` 写入文件 + `FormRegistry.getAll()` + `formProvider.updateForm()` 推送
3. FormAbility 的 `onAddForm` 调用 `loadXxx()` 同步读文件；启动 `setTimeout` 轮询（200ms×15次）兜底

### Q32: 卡片显示乱码/中文字符异常

**原因**：手动用 `String.fromCharCode()` 逐字节转换 UTF-8 编码的文件内容，
多字节中文字符（如"起风了"=9字节）被拆散。

**解决方案**：使用 `fs.readTextSync(path)` 替代手动字节转换，其内置 UTF-8 解码。

### Q33: 编译错误 onAddForm 不能返回 Promise

**错误信息**：
Property 'onAddForm' in type 'XxxFormAbility' is not assignable to the same property in base type.
  Type '(want: Want) => Promise<FormBindingData>' is not assignable to type '(want: Want) => FormBindingData'.

**原因**：`FormExtensionAbility` 基类定义 `onAddForm(want: Want): FormBindingData`（同步），
子类不能通过 `async` 改为返回 `Promise<FormBindingData>`。

**解决方案**：`onAddForm` 保持同步。异步逻辑通过 `setTimeout` 轮询链 + `formProvider.updateForm()` 实现。

### Q34: 热启动同 URL 时相机/传感器不工作（@InsightIntentEntry 页面跳转型）

**现象**：通过意图打开页面（如相册），冷启动正常，但应用已在前台且处于同一页面时再次调用意图，相机/扫描/传感器等功能不工作。

**原因**：`windowStage.loadContent` 热启动同 URL 时，页面实例不重建，`aboutToAppear` 不执行。依赖 `aboutToAppear` 初始化的硬件未被重新初始化。

**解决方案**：

1. 将硬件初始化逻辑从 `aboutToAppear` 提取到独立方法
2. 在 `onPageShow` 中增加幂等兜底调用
3. 使用状态标志避免重复初始化

```typescript
@Entry
@Component
struct CameraPage {
  @State isCameraReady: boolean = false;

  aboutToAppear() {
    this.initCamera();
  }

  onPageShow() {
    // 热启动同 URL 时，aboutToAppear 不执行，此处兜底
    if (!this.isCameraReady) {
      this.initCamera();
    }
  }

  private initCamera(): void {
    if (this.isCameraReady) return;  // 幂等
    // 初始化相机
    this.isCameraReady = true;
  }
}
```

### Q35: onPageShow 中调用 openCamera 后还是黑屏

**现象**：已在 `onPageShow` 中添加相机初始化兜底，但热启动后依然黑屏。

**原因**：`onPageShow` 在页面显示时触发，但相机初始化可能是异步的，未等待完成就开始预览。或者 `openCamera` 内部有防重复调用机制（如 `if (this.camera) return`），但 `this.camera` 指向已释放的实例。

**解决方案**：

```typescript
private async initCamera(): Promise<void> {
  // 1. 先释放旧实例（确保幂等）
  if (this.camera) {
    await this.camera.close();
    this.camera = null;
  }
  // 2. 重新创建
  this.camera = await Camera.create();
  // 3. 开始预览
  await this.camera.startPreview();
}

onPageShow() {
  // 不依赖状态标志，每次都重新初始化（但内部幂等）
  this.initCamera();
}
```

或使用 `onHidden` 明确释放资源：

```typescript
onHidden() {
  // 页面被隐藏时释放相机，确保下次显示时重新初始化
  this.releaseCamera();
}
```
