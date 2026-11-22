# 代码探索与复用

生成代码前，必须扫描项目现有代码，复用已有常量、数据模型、工具方法，禁止凭空创造。

---

## 0. 分层探索协议（强制替代全量扫描）

生成意图前，必须按以下顺序探索代码，**严禁无差别读取整个目录**。违反此协议将导致任务耗时从秒级变为分钟级。

### 第1层：架构探测（仅用 Grep，不读文件）

| 探测目标  | Grep 搜索词                                                  | 输出                              |
| --------- | ------------------------------------------------------------ | --------------------------------- |
| 路由架构  | `router.pushUrl|NavPathStack`                                | 匹配行，确认 Navigation/Router    |
| form 配置 | `FormExtensionAbility|form_config.json|formProvider|formBindingData` | 确认是否已有 FormExtensionAbility |
| 存储类型  | `getRdbStore|getKVStore|getPreferences`                      | 匹配行，确认存储方案              |
| UI 容器   | `Navigation|Tabs`                                            | 匹配行，确认主容器                |
| 页面注册  | `@Entry|NavDestination`                                      | 匹配行，确认页面类型              |

**操作**：执行 Grep 后，仅记录匹配结果（如"Navigation + RDB"），**不读取任何文件内容**。

### 第 2 层：关键入口阅读（仅 Read 2 个文件，指定行数）

| 文件                  | 读取范围                                              | 目的             |
| --------------------- | ----------------------------------------------------- | ---------------- |
| `EntryAbility.ets`    | `onCreate`、`onWindowStageCreate`、`onNewWant` 函数体 | 检查冷启动兼容性 |
| `build-profile.json5` | `useNormalizedOHMUrl` 和 SDK 版本字段                 | 检查项目配置     |

**操作**：使用 `Read` 时指定行号范围（如 `Read EntryAbility.ets 10-35`），不读整页。

### 第3层：公共接口提取（仅用 Grep）

| 搜索目标         | Grep 搜索词                                           | 用途                               |
| ---------------- | ----------------------------------------------------- | ---------------------------------- |
| 导出项列表       | `^export (class|interface|function|const|enum)`       | 了解模块提供的公共 API             |
| 业务方法签名     | `query\(|save\(|get\(|add\(|delete\(|update\(`        | 提取可复用的方法签名               |
| 文件写入         | `writeSync\|openSync\|readTextSync\|filesDir`         | 确认主应用数据持久化方式           |
| 硬件工具可重入性 | `releaseCamera\|close\(\)\|release\(\)\|stop\(\)`     | 确认 release/init 是否支持重入调用 |

**操作**：仅提取方法签名（参数名+类型），**禁止读取方法体内部实现**。

### 第 3.5 层：目标页健康度检查（仅当意图指向特定页面时执行）

在确定意图指向的目标页面后，必须检查该页面的核心工具类/管理器是否存在已知 Bug 注释。

| 搜索词                                                       | 检查内容                           | 搜索范围                                                     |
| :----------------------------------------------------------- | :--------------------------------- | :----------------------------------------------------------- |
| `已知.*问题\|已知.*bug\|known issue\|broken\|未测试\|测试.*绿屏\|测试.*黑屏` | 工具类文件头部注释中的已知问题声明 | 目标页导入的工具类文件（如 `CameraManager.ets`、`PlayerController.ets`） |

**操作**：
1. 用 `Grep` 在目标页导入的工具类源码目录中搜索上述关键词
2. 若发现已知问题声明，记录问题描述

**处理规则**：
- 发现已知问题 → 优先切换到同一项目中的备用/旧版页面实现（若存在）
- 无备用页面 → 在生成的意图代码注释中标注已知问题，并提示用户
- 不影响跳转逻辑的问题（如 UI 样式瑕疵）→ 标注但不阻塞生成

**示例**：

```typescript
// ⚠️ 已知问题：CameraManager 在热启动同 URL 时 close 方法可能空指针
// 详见 CameraManager.ets 第 45 行注释
// 解决方案：意图将跳转到备用页面 CameraPageV2（已修复此问题）
```

### 第 4 层：定点深度（仅当需要，Read 单方法）

**触发条件**：第 3 层无法确认返回值类型或异步状态时。

**操作**：

1. 用 `Grep` 搜索方法名获取行号
2. 用 `Read` 读取该方法的 **30-50 行**（仅函数体）

**示例**：

```typescript
// 第 3 层发现可疑方法
Grep "queryItems" → 定位到行 45

// 第 4 层仅读取该函数
Read RdbUtils.ets 40-70
```

------

## 扫描目录（仅在第 3 层使用 Grep 时参考）

- `/ets/pages/`
- `/ets/common/constants/`
- `/ets/viewmodel/`
- `/ets/database/`
- `/ets/model/`
- `/ets/formability/`
- `/ets/widget/`
- `/ets/utils/`

## 搜索关键词（仅在第 3 层使用 Grep 时参考）

| 功能      | 搜索关键词                                |
| :-------- | :---------------------------------------- |
| 添加/新增 | `save`, `add`, `insert`, `create`         |
| 查询      | `query`, `get`, `fetch`, `find`           |
| 删除      | `delete`, `remove`                        |
| 更新      | `update`, `modify`                        |
| 跳转      | `router.push`, `replaceUrl`, `Navigation` |

## 提取并复用

找到候选代码后，提取：

- 键名生成规则（如 `PREFIX + name`）
- 数据序列化方式（`JSON.stringify`）
- 存储层接口签名
- 常量导入路径
- 数据模型定义

## 决策与约束

- **存在完整实现** → 完全模仿（复用常量、模型、存储方式）
- **部分存在** → 适配现有模式
- **不存在** → 按标准规范生成

## 强制约束

- 禁止自行发明键名格式（必须用现有前缀）
- 禁止新建数据模型（优先复用）
- 禁止改变现有调用方式
- 导入路径与项目一致

------

## 1. 存储层异步初始化检查（强制）

当意图需要访问任何异步初始化的存储（RDB、Distributed KV Store、Preferences 等）时，必须执行以下检查：

### 1.1 扫描存储工具类源码

在 `/ets/database/`、`/ets/utils/` 等目录中搜索以下关键词：

- `getKVStore`
- `getRdbStore`
- `getPreferences`
- `createKVManager`
- `dataPreferences.getPreferences`

### 1.2 确认异步初始化模式

打开相关工具类，确认存储实例的赋值方式：

```typescript
// ❌ 危险模式：实例在回调中赋值，外部未等待就绪
let kvStore: SingleKVStore;
getKVStore(..., (err, store) => { kvStore = store; });

export function getValue(key: string) {
  return kvStore.get(key); // 可能 kvStore 为 undefined
}
```

```typescript
// ✅ 安全模式：内部实现了就绪等待机制
private readyPromise: Promise<void>;
constructor() { this.readyPromise = this.init(); }
private async init() { /* 等待 getKVStore 完成 */ }
public async waitReady() { await this.readyPromise; }
```

### 1.3 检查是否已提供就绪方法

如果工具类已提供 `waitReady()` / `ready()` / `isInitSuccess()`，记录该方法名供意图代码使用。
如果没有提供，**必须优先改造工具类**（添加 Promise 就绪机制），然后再生成意图代码。

### 1.4 意图代码中必须等待就绪

在意图执行存储操作前，必须 `await storage.waitReady()`。

### 1.5 禁止仅检查工具类对象是否存在

```typescript
// ❌ 错误：仅判断对象存在，其内部存储实例可能未就绪
const db = GlobalContext.get('db');
if (db) { await db.query(); }

// ✅ 正确：等待内部实例就绪
const db = GlobalContext.get('db');
if (db) { await db.waitReady(); await db.query(); }
```

**原因**：存储工具类通常在 `EntryAbility.onCreate` 中同步 `new` 出来，但其内部的 `getKVStore` / `getRdbStore` 是异步的。意图执行时工具类对象已存在，但内部实例可能仍为 `undefined`。

### 1.6 回调式 DB 类就绪机制改造模板

当数据库工具类使用回调式 API（如 `getKVStore`、`getRdbStore`）且未提供 `waitReady()` 方法时，按以下模板改造：

```typescript
// 为类添加 Promise 就绪字段
private readyPromise: Promise<void>;
private resolveReady: (() => void) | null = null;

// 构造函数中创建 Promise（在调用异步初始化之前）
constructor() {
  this.readyPromise = new Promise<void>((resolve: () => void) => {
    this.resolveReady = resolve;
  });
  this.init(); // 异步初始化
}

// 异步初始化回调成功时 resolve
private init(): void {
  getKVStore(..., (err, store) => {
    if (err) return;
    this.kvStore = store;
    if (this.resolveReady) {
      this.resolveReady();
      this.resolveReady = null;
    }
  });
}

// 暴露公共方法
async waitReady(): Promise<void> {
  await this.readyPromise;
}

// 意图代码使用
await db.waitReady();
db.save(key, value); // 此时 kvStore 已就绪
```

------

## 2. 数据库初始化检查（RDB 专项）

以下检查是"存储层异步初始化检查"在 RDB 场景下的具体化，保留作为参考。

### 2.1 确认 DB 初始化位置

读取 `EntryAbility.ets`，确认 **`onCreate`**（而非 `onWindowStageCreate` 或页面 `aboutToAppear`）中调用了数据库初始化。如果原项目仅在 `onWindowStageCreate` 或页面生命周期中初始化，需提示用户迁移到 `onCreate` 并确认。

**原因**：后台执行模式的意图（`UI_ABILITY_BACKGROUND`）执行时可能触发 Ability 后台冷启动，`onWindowStageCreate` 在此场景下不执行，只有 `onCreate` 保证执行。

### 2.2 检查数据库 API 调用模式

扫描数据库工具类（如 `RdbUtils.ets`）中所有 `query`/`insert`/`update`/`delete` 方法，确认：

- 使用 Promise 式 API（`await store.query(...)`）
- 或回调式 API 已正确包装为 Promise

### 2.3 检查异步实现是否正确（⚠️ 高频 bug）

验证查询方法的异步实现：打开数据库工具类，检查方法内部是否正确使用了 `await`。

```typescript
// ❌ 错误：标记 async 但内部 .then() 未 await
static async queryItems(date: string): Promise<Item[]> {
  let items: Item[] = [];
  getStore().then((store) => {
    store.query(sql, (err, result) => { items = result; });
  });
  return items;  // 立即返回空数组
}

// ✅ 正确：await 等待结果
static async queryItems(date: string): Promise<Item[]> {
  const store = await getStore();
  const resultSet = await store.query(sql, [date]);
  return this.parseResultSet(resultSet);
}
```

### 2.4 检查 DB 就绪等待机制

如果项目 DB 工具类提供了 `ready()` / `readyPromise` / `isInitSuccess()` 等方法，记录供意图代码使用。如果没有，意图代码中需要在查询前调用 `initDB()` 并轮询 `isInitSuccess()`（带超时），或提示用户添加 `ready()` 方法。

### 2.5 模块顶层 Context 获取检查（⚠️ 冷启动致命问题）

检查数据库工具类是否在模块顶层使用了 `getContext(this)`：

```typescript
// ❌ 危险：模块顶层 Context
const CONTEXT = getContext(this);  // 后台冷启动时返回 undefined

export class RdbUtils {
  static async getStore(): Promise<relationalStore.RdbStore> {
    return relationalStore.getRdbStore(CONTEXT, config);  // CONTEXT 为 undefined
  }
}
```

**解决方案**：

- 检查 `EntryAbility.onCreate` 是否首行保存 `this.context` 到全局（如 `GlobalContext` 或 `AppStorage`）
- 修改数据库工具类，从全局动态获取 Context，而非使用模块顶层静态值

### 2.6 异步误用检查（工具类内部 bug）

扫描数据库工具类所有 `query`/`insert`/`update` 方法，如果方法标记为 `async` 但内部使用 `.then()` 而非 `await`，则方法会提前返回 `undefined`/空结果。必须将 `.then()` 改为 `await`，或确保调用方使用 `await` 等待完整结果。

### 2.7 DB 就绪等待机制（意图代码侧）

如果项目 DB 工具类提供了 `ready()` / `readyPromise` 方法，意图中必须 `await dbUtils.ready()` 而非直接查询；如果没有，意图中必须在查询前调用 `dbUtils.initDB()` 并轮询 `isInitSuccess()`（带超时），超时未就绪则返回错误。

**超时建议**：轮询间隔 100ms，最多 50 次（5 秒）。首次 `getRdbStore` 在网络存储等重场景下可能耗时较长，5 秒是合理的兜底上限。超时后不应抛异常（避免泄露内部错误），应返回带可读消息的错误结果。

```typescript
private async waitDBReady(db: Database): Promise<boolean> {
  for (let i = 0; i < 50; i++) {
    if (db.isInitSuccess()) return true;
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  return false;
}

async onExecute(): Promise<...> {
  const ready = await this.waitDBReady(db);
  if (!ready) {
    return { code: -1, result: { resultDesc: '数据库初始化超时，请稍后重试' } };
  }
  // 继续业务操作
}
```

### 2.8 错误传播检查

扫描 DB 工具类中所有对 `store === undefined` 的处理方式：

```typescript
// ❌ 静默返回：意图层会误判为成功，数据实际未写入
insert(data: Data): void {
  if (store === undefined) { return; }
  store.insert(data);
}

// ✅ 抛异常或返回状态：意图层可通过 try-catch 或返回值感知失败
insert(data: Data): void {
  if (store === undefined) { throw new Error('DB not ready'); }
  store.insert(data);
}
```

如现有工具类采用静默返回模式，意图代码中必须在调用前额外检查 `isInitSuccess()`，不可依赖方法的静默返回来判断执行结果。

------

## 3. 冷启动窗口创建检查（用于后台模式意图）

如果意图为后台执行模式（`UI_ABILITY_BACKGROUND`），需检查 `EntryAbility.ets` 中 `onNewWant` / `onForeground` 是否有窗口未创建的兜底逻辑。`background` 冷启动不执行 `onWindowStageCreate`，后续手动启动时 singleton Ability 走 `onNewWant`，若无窗口创建逻辑则白屏/闪退。

**✅ 正确兜底代码模板：**

```typescript
// EntryAbility.ets
import window from '@ohos.window';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private windowContentReady: boolean = false;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 关键资源初始化必须放在 onCreate，冷启动时也会执行
    // 例如：播放器 setContext、数据库初始化等
    this.initCriticalResources();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowContentReady = true;
    windowStage.loadContent('pages/Index');
  }

  onWindowStageDestroy(): void {
    this.windowContentReady = false;
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleInsightIntent(want);
    if (!this.windowContentReady) {
      this.ensureWindowContent();
    }
  }

  onForeground(): void {
    if (!this.windowContentReady) {
      this.ensureWindowContent();
    }
  }

  private ensureWindowContent(): void {
    if (this.windowContentReady) return;

    // ✅ 正确：使用 getLastWindow 获取系统已创建的主窗口
    window.getLastWindow(this.context)
      .then((win: window.Window) => {
        this.initWindowContent(win);
      })
      .catch((err: Error) => {
        hilog.error(0x0000, LOG_TAG, 'getLastWindow failed: %{public}s', err.message);
        // 极少数情况（如系统异常）可降级创建窗口，但通常不需要
      });
  }

  private initWindowContent(win: window.Window): void {
    win.setUIContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, LOG_TAG, 'setUIContent failed: %{public}s', err.message);
        return;
      }
      this.windowContentReady = true;
      win.showWindow().catch((e: Error) => {
        hilog.error(0x0000, LOG_TAG, 'showWindow failed: %{public}s', e.message);
      });
    });
  }

  private handleInsightIntent(want: Want): void {
    // 解析意图参数，设置路由目标等
  }

  private initCriticalResources(): void {
    // 播放器 setContext、数据库初始化等
  }
}
```

**⚠️ 禁止使用 `createWindow` 创建主窗口**：

- `singleton` Ability 的主窗口由系统在 `onCreate` 后自动创建，应用无需也不能再次调用 `createWindow`。
- 使用 `window.createWindow(MAIN_WINDOW_NAME, window.WindowType.TYPE_MAIN, this.context)` 会导致窗口冲突，引发闪退。
- **正确做法**：使用 `window.getLastWindow(this.context)` 获取已有窗口。

**关键要点**：

- 关键资源初始化（播放器 `setContext`、数据库 `getRdbStore`、Preferences 等）**必须放在 `onCreate` 中**，不能仅在 `onWindowStageCreate` 中执行。
- `onNewWant` 和 `onForeground` 中都必须调用窗口恢复逻辑，覆盖不同启动方式。
- 窗口恢复使用 `getLastWindow` + `setUIContent` + `showWindow`，禁止 `createWindow`。
- `onNewWant` 中的 `router.pushUrl` 等路由操作应在窗口恢复后由页面自身处理，避免窗口未就绪时报错。

------

## 4. Window API 版本差异说明

| API                  | 签名                                  | 说明                                                      |
| :------------------- | :------------------------------------ | :-------------------------------------------------------- |
| `createWindow`（旧） | `createWindow(name, type, ctx)`       | 3 参数，已废弃，在 singleton Ability 上使用会导致窗口冲突 |
| `createWindow`（新） | `createWindow(config: Configuration)` | 1 参数，当前标准，但仍不推荐用于获取已有主窗口            |
| `getLastWindow`      | `getLastWindow(ctx): Promise<Window>` | **推荐**：获取最近的主窗口，适用于冷启动窗口恢复          |

**冷启动窗口恢复优先使用 `getLastWindow`，不使用 `createWindow`。**

------

## 5. EntryAbility 冷启动兼容性强制检查清单

### 适用范围

所有后台执行模式的意图（`UI_ABILITY_BACKGROUND`，包括 `@InsightIntentEntry` + `UI_ABILITY_BACKGROUND` 和 `@InsightIntentFunctionMethod`）冷启动时**不经过 `onWindowStageCreate`**，必须执行以下检查。

在生成上述意图代码前，**必须**读取 `EntryAbility.ets` 并逐项检查：

| 检查项             | 正确做法                                                     | 错误示例                                                     |
| :----------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| 关键资源初始化位置 | 初始化逻辑（`setContext`、`getRdbStore`、Preferences 等）**必须在 `onCreate` 中执行**，且幂等 | 仅在 `onWindowStageCreate` 中初始化                          |
| 窗口恢复逻辑       | `onNewWant` 和 `onForeground` 中调用 `window.getLastWindow` + `setUIContent` 恢复页面 | 无窗口恢复逻辑，或使用 `createWindow`                        |
| 路由操作时机       | `router.pushUrl` 等操作应放在窗口恢复完成后（由页面自身处理） | 在 `onNewWant` 中直接调用 `router.pushUrl`，窗口未就绪时崩溃 |

**若检查不通过，必须先改造 `EntryAbility.ets`，再生成意图代码。**

------

## 相关文档

- [architecture_checks.md](architecture_checks.md/) - 页面路由架构检查
- [common_rules.md](common_rules.md/) - 公共规则（ArkTS、冷启动约束等）
- [troubleshooting.md](troubleshooting.md/) - 常见问题排查