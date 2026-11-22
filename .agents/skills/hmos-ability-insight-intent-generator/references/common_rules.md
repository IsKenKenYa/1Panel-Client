# 意图生成公共规则（所有装饰器通用）

本文档集中存放所有意图装饰器生成时必须遵守的公共规则。各子文档应通过链接引用本文档，**不得重复书写完整规则**。

---

## 1. ArkTS 严格模式核心规则（速查表）

生成所有意图代码时，**必须**遵守以下规则：

| 规则                                       | 错误示例                              | 正确要点                                             |
| ------------------------------------------ | ------------------------------------- | ---------------------------------------------------- |
| 禁止 `any`/`unknown`                       | `const params: any = ...`             | 定义接口并声明类型                                   |
| 禁止索引访问 `obj['prop']`                 | `value = params['date']`              | 使用点号 `params.date`                               |
| 类属性必须初始化                           | `songName: string;`                   | `songName: string = '';`                             |
| 禁止解构赋值                               | `const { songName } = this.params`    | `const songName = this.params.songName`              |
| 方法返回类型不能使用对象字面量             | `(): { valid: boolean } =>`           | 定义 `interface ValidResult`                         |
| `return` 不能直接返回对象字面量            | `return { code: 0 }`                  | `const result: Result = { code: 0 }; return result;` |
| `Promise.resolve` 中的对象字面量需显式类型 | `return Promise.resolve({ code: 0 })` | 先声明变量再返回                                     |
| `throw` 只能抛 `Error` 对象                | `throw error`                         | `throw new Error(JSON.stringify(error))`             |
| 禁止 `| undefined` 联合类型作为类属性      | `name: string \| undefined`           | `name: string = ''`                                  |

### 对象字面量必须有接口声明

```typescript
// ❌ 错误
const result = { code: 0, result: '播放成功' };

// ✅ 正确
interface PlayResult { code: number; result: string; }
const result: PlayResult = { code: 0, result: '播放成功' };
```

### 字符串格式参数的防御性校验

对于日期、时间、枚举值等需要特定格式的字符串参数：

```typescript
// 1. parameters 中使用 pattern 约束（JSON Schema）
'date': { 'type': 'string', 'pattern': '^\\d{4}-\\d{2}-\\d{2}$' }

// 2. onExecute 中增加正则检验
private readonly DATE_REGEX: RegExp = /^\d{4}-\d{2}-\d{2}$/;
if (!this.DATE_REGEX.test(this.date)) {
  return { code: -2, result: { resultDesc: '日期格式无效，请使用YYYY-MM-DD' } };
}

// 3. 对解析结果做 isNaN() / 范围检查
const dayId: number = Number(parts[0]) * 10000 + Number(parts[1]) * 100 + Number(parts[2]);
if (isNaN(dayId)) { /* 返回错误 */ }
```

### `insightIntent.ExecuteResult.result` 的构建方式

`result` 字段类型为 `Record<string, Object>`，不能用接口定义后赋值（接口缺少索引签名）。

❌ **错误**：

```typescript
interface MyResult { code: number; resultDesc: string; }
const data: MyResult = { code: 0, resultDesc: '成功' };
// data 不能赋值给 Record<string, Object>
```

✅ **正确**：

```typescript
const resultData: Record<string, Object> = {};
resultData['code'] = 0;
resultData['resultDesc'] = '成功';
const executeResult: insightIntent.ExecuteResult = { code: 0, result: resultData };
```

------

## 2. 返回值规范

**所有意图返回值中必须包含 `resultDesc` 字段**，用于小艺生成回复文本。

```typescript
// ✅ 正确
interface MyResult { resultDesc: string; data?: string; }

// ❌ 错误：缺少 resultDesc
interface MyResult { message: string; }
```

------

## 3. 装饰器字段命名规范

| 装饰器                | Ability 名称字段 | 执行模式字段                | 说明                                     |
| :-------------------- | :--------------- | :-------------------------- | :--------------------------------------- |
| `@InsightIntentEntry` | `abilityName`    | `executeMode`（必须是数组） |                                          |
| `@InsightIntentPage`  | `uiAbility`      | 无                          | 字段名是 `uiAbility`，不是 `abilityName` |
| `@InsightIntentLink`  | 无               | 无                          | 通过 `uri` 关联                          |

**常见错误**：

```typescript
// ❌ 错误
@InsightIntentPage({ abilityName: 'EntryAbility' })

// ✅ 正确
@InsightIntentPage({ uiAbility: 'EntryAbility' })
```

------

## 4. 冷启动时序约束

所有后台执行模式的意图（`UI_ABILITY_BACKGROUND`）冷启动时**不经过 `onWindowStageCreate`**，必须遵守以下约束：

### 4.1 关键资源初始化位置

初始化逻辑（`setContext`、`getRdbStore`、Preferences 等）**必须在 `onCreate` 中执行**，且幂等。

### 4.2 窗口恢复逻辑

`onNewWant` 和 `onForeground` 中调用 `window.getLastWindow` + `setUIContent` 恢复页面。**禁止使用 `createWindow(TYPE_MAIN)`**。

### 4.3 DB 就绪等待

意图代码必须包含 DB 就绪等待机制（`await dbUtils.ready()` / 轮询 `isInitSuccess()` / 带超时的 `initDB()`），不能直接假设 DB 可用。

### 4.4 模块顶层 `getContext(this)` 禁止

数据库/存储工具类如果在模块顶层使用 `const CONTEXT = getContext(this)`，后台冷启动时返回 `undefined`。必须改为从全局动态获取 Ability Context。

### 4.5 存储层实例级就绪检查

仅检查工具类对象是否为 `null` 不够——其内部的 `kvStore`/`rdbStore` 实例可能是异步初始化的。必须 `await` 工具类的 `waitReady()` 方法。

### 4.6 InsightIntentContext 类型约束

`InsightIntentEntryExecutor.context` 的类型是 `InsightIntentContext`，它**不继承 `Context`**，不能直接传给 `getRdbStore`、`getKVStore` 等需要 `Context` 参数的 API。

```typescript
// ❌ 编译错误：类型不兼容
const store = await relationalStore.getRdbStore(this.context, config);

// ✅ 正确：从全局存储获取 UIAbilityContext
// 前提：EntryAbility.onCreate 首行中保存了 this.context
// GlobalContext.getContext().setObject('abilityContext', this.context);
const ctx = GlobalContext.getContext().getObject('abilityContext') as Context;
const store = await relationalStore.getRdbStore(ctx, config);
```

**推荐做法**：在 `EntryAbility.onCreate` 首行将 `this.context` 存入全局存储（如 `GlobalContext`），供所有意图在需要 `UIAbilityContext` 时使用。

### 4.7 onNewWant 中单例重建警告

`onNewWant` 中如果重新实例化全局单例工具类（如 Database、Manager），旧实例的未完成异步操作（如 `getKVStore` 回调、网络请求）可能被丢弃。

```typescript
// ❌ 错误：每次 onNewWant 都 new 新实例
onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  GlobalContext.set('db', new Database()); // 旧实例的异步回调丢失
}

// ✅ 正确：复用已有实例，仅更新轻量状态
onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  const db = GlobalContext.get('db') as Database;
  if (db) { db.refreshContext(this.context); } // 轻量更新
}
```

> 详细模板请参阅 [code_exploration.md](code_exploration.md/) 第 3 节和第 5 节。

------

## 5. 热启动时序约束（@InsightIntentEntry 页面跳转型必须）

当 `@InsightIntentEntry` 通过 `windowStage.loadContent` 跳转页面时，**热启动场景下目标 URL 与当前窗口页面相同**时，页面实例可能不重建：

| 生命周期钩子    | 冷启动（首次加载） | 热启动（同 URL） |
| :-------------- | :----------------- | :--------------- |
| `aboutToAppear` | ✅ 执行             | ❌ 不执行         |
| `onPageShow`    | ✅ 执行             | ✅ 执行           |
| `onHidden`      | ✅ 执行             | ✅ 执行           |

**影响**：依赖 `aboutToAppear` 初始化的硬件（相机、传感器、播放器等）在热启动同 URL 场景下不会重新初始化。

### 5.1 硬件初始化兜底规则

**核心原则**：硬件/资源初始化必须支持幂等，且 `onPageShow` 中必须有兜底调用。

```typescript
// ❌ 危险：仅 aboutToAppear 初始化
aboutToAppear() {
  this.initCamera();  // 热启动同 URL 时不执行
}

// ✅ 正确：aboutToAppear + onPageShow 双保险
aboutToAppear() {
  this.initCamera();
}

onPageShow() {
  if (!this.isCameraReady) {  // 检查状态，幂等初始化
    this.initCamera();
  }
}
```

### 5.2 参数传递规则

- **热启动同 URL**：页面不重建，`@StorageProp` 不会重新读取值（仅创建时同步一次）
- **必须使用 `@StorageLink`**：双向同步，运行时响应 `AppStorage` 变化

```typescript
// ❌ 热启动同 URL 时不会更新
@StorageProp('intentCategory') category: string = '';

// ✅ 热启动同 URL 时正常更新
@StorageLink('intentCategory') category: string = '';
```

### 5.3 信号消费后重置

```typescript
onPageShow() {
  // 消费意图信号后立即重置，避免重复触发
  const pendingCategory = AppStorage.get<string>('intentCategory');
  if (pendingCategory) {
    this.category = pendingCategory;
    AppStorage.delete('intentCategory');  // 或 setOrCreate('intentCategory', '')
  }
}
```

### 5.4 单例工具类状态保持

热启动时单例实例保留，需确保 `release()` / `re-init` 幂等：

```typescript
// ❌ 危险：二次 init 可能导致资源泄漏
class CameraManager {
  private static instance: CameraManager;
  private camera: Camera;
  init() { this.camera = new Camera(); }  // 第二次调用会覆盖旧实例，可能未释放
}

// ✅ 正确：幂等初始化
class CameraManager {
  private static instance: CameraManager;
  private camera: Camera | null = null;
  init() {
    if (this.camera) return;  // 已初始化则跳过
    this.camera = new Camera();
  }
  release() {
    this.camera?.close();
    this.camera = null;  // 释放后允许重新 init
  }
}
```

### 5.5 页面导航场景的热启动双重保障

当 `@InsightIntentEntry` 需要通过宿主页面桥接导航时（详见 [insight_intent_entry.md#方式4](insight_intent_entry.md/#方式4)）：

| 场景 | 触发路径 | 说明 |
|------|----------|------|
| **冷启动** | `onPageShow` 中检查 AppStorage | `@Watch` 不触发初始值，需 `onPageShow` 补充 |
| **热启动（同 URL，页面不重建）** | `@StorageLink` + `@Watch` 响应式触发 | `onPageShow` 不执行，`@Watch` 是唯一响应路径 |
| **热启动（不同 URL，回宿主页）** | `onPageShow` + `consumeIntentSignal` | 回到宿主页时消费残留信号 |

**两种机制必须同时存在，缺一不可**：

```typescript
// 必须：@StorageLink + @Watch（热启动响应）
@StorageLink('intentTargetPage') @Watch('onIntentTargetChange') intentTargetPage: string = '';

onIntentTargetChange(): void {
  if (this.intentTargetPage) {
    AppStorage.setOrCreate('intentTargetPage', '');
    // router.replaceUrl(...)
  }
}

// 必须：onPageShow（冷启动兜底）
onPageShow(): void {
  const pending: string | undefined = AppStorage.get<string>('intentTargetPage');
  if (pending) {
    AppStorage.setOrCreate('intentTargetPage', '');
    // router.replaceUrl(...)
  }
}
```

### 5.6 @StorageLink 初始值不触发 @Watch

`@StorageLink` 在组件创建时从 AppStorage 读取初始值并赋值，但 **`@Watch` 不对初始值触发**（只对后续变更触发）。

**影响示例（Tabs 冷启动）**：
1. 意图执行器已写入 `AppStorage.setOrCreate('intentTargetTab', 4)`
2. TabBar 组件创建，`@StorageLink` 读到值 4，`intentTargetTab = 4`
3. `@Watch('onTargetChange')` 不触发，依赖 `@Watch` 的 `changeIndex` 被跳过
4. Tab 卡在首页，未切换到目标 Tab

**解决方案**：在 `aboutToAppear` 中消费 `@StorageLink` 的初始值：

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

## 6. aboutToAppear async 约束

ArkUI 中 `aboutToAppear()` 签名是 `(): void`。即使标记为 `async`，返回的 `Promise<void>` 被框架忽略，**不会阻塞 `build()`**。

### 影响

| 常见写法 | 实际行为 | 可能后果 |
|----------|----------|----------|
| `async aboutToAppear() { await grantPermission(...); }` | `build()` 立即执行，不等 permission | `onLoad`（build 中触发）调硬件初始化时 permission 未就绪 |
| `async aboutToAppear() { await db.init(); }` | `build()` 立即执行，不等 DB 就绪 | 页面渲染时数据为空 |

### 判断方法

```bash
Grep: async aboutToAppear → 确认内部是否 await 了 permission/DB/网络等异步操作
```

### ✅ 正确做法

```typescript
aboutToAppear() {
  this.isBackCamera = this.cameraMode === 'back';
}

onPageShow() {
  grantPermission(PERMISSIONS).then((granted: boolean) => {
    if (granted) { this.startCamera(); }
  });
}
```

------

## 7. 导入语句规范

| 装饰器类型                                                | 导入语句                                                     |
| :-------------------------------------------------------- | :----------------------------------------------------------- |
| `@InsightIntentEntry`                                     | `import { InsightIntentEntry, InsightIntentEntryExecutor, insightIntent } from '@kit.AbilityKit';` |
| `@InsightIntentPage`                                      | `import { InsightIntentPage } from '@kit.AbilityKit';`       |
| `@InsightIntentLink`                                      | `import { InsightIntentLink } from '@kit.AbilityKit';`       |
| `@InsightIntentFunction` + `@InsightIntentFunctionMethod` | `import { InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';` |
| `@InsightIntentForm`                                      | `import { InsightIntentForm } from '@kit.AbilityKit';`       |

**装饰器和基类直接使用，不使用 namespace 前缀**：

- ✅ `@InsightIntentEntry`
- ❌ `@insightIntent.InsightIntentEntry`

**枚举和类型使用 namespace 前缀**：

- ✅ `insightIntent.ExecuteMode`
- ❌ `ExecuteMode`

------

## 8. AppStorage 跨上下文可用性

`AppStorage` 是进程内全局单例，可在以下场景中正常读写：

- **UIAbility**（`onCreate`、`onWindowStageCreate`、`onNewWant` 等）
- **意图执行器**（`onExecute` 中）
- **Page/Component**（`@StorageLink`、`@StorageProp`、`AppStorage.get`）

```typescript
// ✅ 意图执行器中写入
AppStorage.setOrCreate('intentTargetPage', 'pages/DetailPage');

// ✅ 页面中读取
@StorageLink('intentTargetPage') @Watch(...) intentTargetPage: string = '';
// 或
const page = AppStorage.get<string>('intentTargetPage');
```

**使用原则**：

1. `AppStorage.setOrCreate()` 同步写入，调用后立即可通过 `get()` 读取
2. 使用后务必 `delete` 或 `setOrCreate` 为空以清除信号，防止重复触发
3. 信号命名加入前缀（如 `intentXxx`）以区分项目自有 AppStorage 键

## 相关文档

- [code_exploration.md](code_exploration.md/) - 代码探索与冷启动模板
- [arkts_strict_rules.md](arkts_strict_rules.md/) - ArkTS 严格模式详细版