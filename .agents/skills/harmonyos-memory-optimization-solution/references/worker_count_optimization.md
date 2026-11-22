# Worker 数量优化指南

## 目录

1. [优化概述](#优化概述)
2. [核心修复：WorkerManager 控制数量](#核心修复workermanager-控制数量)
3. [额外优化策略（可选，需改业务逻辑）](#额外优化策略可选需改业务逻辑)
4. [常见问题排查](#常见问题排查)

---

## 优化概述

每个 worker 实例（`new worker.ThreadWorker()`，旧 API 写法 `new worker.Worker()`）对应**一条独立线程 + 一套独立 ArkTS 运行时（隔离堆）**，单个实例即有几 MB 级基线占用（线程栈 + 运行时初始化），总占用随实例数线性增长，内存账记在 `libworker.z.so`（ARKTS_HEAP/NATIVE_HEAP）。

当**同一任务**的 worker 实例数过多（经验判定线：同一任务超过 8 个）时，会表现为 `libworker.z.so` 占用增长、线程数量过多。

### 修复原则

**核心修复只控制 worker 数量，不改原始业务逻辑。** 通过 `WorkerManager` 单例统一收口 `new worker.ThreadWorker()` 的创建入口——循环、常量、`postMessage`、`onmessage` 等原始业务代码全部保留不变。数量控制规则：

- 同 key（且 script 未变）直接复用同一实例；
- 同一任务（同 script）实例数未达上限（8 个）正常新建；
- **同一任务达到上限后不再新建，在该任务已有实例中轮转复用**——同一任务的 worker 跑同一 script，实例可互换；不同任务（不同 script）之间不能复用（worker 创建时绑定脚本），各自独立计数，**不设全应用统一上限**；
- 同 key 但 script 变了 → key 命名冲突：**返回 `null`**（不重建、不返回已有实例，原实例保持不动），调用方修正命名。

| 修复层次 | 做什么 | 是否改业务逻辑 |
| --- | --- | --- |
| **核心修复（必做）** | 用 `WorkerManager.getWorker(key, script)` 替换 `new worker.ThreadWorker(script)`，控制同一任务实例数 ≤ 8（各任务独立计数） | ❌ 不改，只换创建那一行 |
| 额外优化（可选） | 同职责合并为单 worker + 消息队列 | ✅ 改消息协议 |
| 额外优化（可选） | 短生命周期任务改用 taskpool | ✅ 改并发模型 |

### 适用与不适用场景

| 场景 | 是否适用 |
| --- | --- |
| 同一任务 worker 实例数超过 8 个（如按调用次数/页面进入次数新建）导致 libworker.z.so 内存增长 | 适用 |
| 各业务点各自 new worker，实例累积 | 适用 |
| 多个不同任务（不同 script）各自使用 worker | 适用：按任务独立计数（各 ≤ 8），实例互不复用、互不挤占 |
| worker 实例总数少（不超过 8 个）且每个都有长生命周期专职用途 | 不适用 |
| 不使用 @ohos.worker（应用无 worker 线程） | 不适用 |

---

## 核心修复：WorkerManager 控制数量

### 核心原理

1. 通过 `WorkerManager` 单例统一管理 worker 的创建，全应用只有这一个入口
2. **只替换 `new worker.ThreadWorker(script)` 为 `mgr.getWorker(key, script)`**——循环、常量、`postMessage`、`onAllErrors` 等原始业务代码全部保留
3. 同 key（且 script 未变）复用同一实例；同一任务（同 script）实例数达到上限（8 个）后不再新建，在该任务已有实例中**轮转复用**（同 script 实例可互换）；不同任务之间不能复用，各自独立计数，不设全应用统一上限；同 key 不同 script（key 命名冲突）返回 `null`，不重建、不影响已有实例
4. `terminate()` 也收口到 `WorkerManager.terminateWorker(key)` / `terminateAll()`

### Step 1：新增 WorkerManager 单例

```typescript
import { worker } from '@kit.ArkTS';

// worker 实例条目：script 在创建时绑定，worker 无法更换脚本
interface WorkerEntry {
  worker: worker.ThreadWorker;
  script: string;
}

// worker 管理器（单例）：按任务（script）独立控制 worker 实例数
// - 同一任务实例数 ≤ 8，超限后在该任务已有实例中轮转复用（同 script，实例可互换）；
// - 不同任务（不同 script）之间不复用、互不挤占，各自独立计数；
// - 同 key 不同 script 视为 key 命名冲突：不重建、不返回 worker（返回 null），原实例保持不动；
// - 不设全应用统一上限（方案目标是控制单个任务的实例数，而非全应用总数）。
export class WorkerManager {
  private static instance: WorkerManager | null = null;
  // key → worker 实例
  private workerMap: Map<string, WorkerEntry> = new Map();
  // script → 该任务已创建的 key 列表（创建顺序）
  private scriptKeys: Map<string, string[]> = new Map();
  // script → 轮转游标（任务超限复用时按序取用）
  private scriptCursor: Map<string, number> = new Map();
  // 同一任务（同 script）worker 实例数上限（经验判定线：单任务超过 8 个属数量型增长）
  private readonly maxWorkerPerTask: number = 8;

  private constructor() {}

  static getInstance(): WorkerManager {
    if (WorkerManager.instance === null) {
      WorkerManager.instance = new WorkerManager();
    }
    return WorkerManager.instance;
  }

  // 获取 worker：
  // 1) 同 key 且 script 未变 → 直接复用同一实例；
  // 2) 该任务（同 script）实例数未达上限 → 新建；
  // 3) 该任务实例数达到上限 → 在该任务已有实例中轮转复用（同 script 实例可互换）；
  // 4) 同 key 但 script 变了 → key 命名冲突：不重建、不返回 worker（返回 null），原实例保持不动。
  //    不同 script 之间不复用（脚本创建时已绑定），互不影响。
  getWorker(key: string, script: string): worker.ThreadWorker | null {
    const exist: WorkerEntry | undefined = this.workerMap.get(key);
    if (exist) {
      if (exist.script === script) {
        return exist.worker;
      }
      // 同 key 但 script 变了：key 已被其他任务占用。不重建（重建须先 terminate 原任务的
      // 存活实例，属误杀）、不返回已有实例（脚本不匹配，消息会发给错误的处理逻辑）——
      // 告警并返回 null，由调用方修正 key 命名（key 需与任务一一对应）。
      console.error('WorkerManager: key [' + key + '] conflict, bound to [' + exist.script + '], requested [' + script + '], return null');
      return null;
    }
    const keys: string[] = this.scriptKeys.get(script) ?? [];
    if (keys.length >= this.maxWorkerPerTask) {
      // 该任务达到上限：轮转复用已有实例（同一 script，消息处理逻辑相同）
      const cursor: number = this.scriptCursor.get(script) ?? 0;
      const reusedKey: string = keys[cursor % keys.length];
      this.scriptCursor.set(script, cursor + 1);
      console.info('WorkerManager: task limit reached (' + this.maxWorkerPerTask + '), reuse [' + reusedKey + '] for [' + key + ']');
      return this.workerMap.get(reusedKey)!.worker;
    }
    return this.createWorker(key, script);
  }

  private createWorker(key: string, script: string): worker.ThreadWorker {
    const w: worker.ThreadWorker = new worker.ThreadWorker(script);
    const entry: WorkerEntry = { worker: w, script: script };
    this.workerMap.set(key, entry);
    const keys: string[] = this.scriptKeys.get(script) ?? [];
    keys.push(key);
    this.scriptKeys.set(script, keys);
    this.scriptCursor.set(script, this.scriptCursor.get(script) ?? 0);
    console.info('WorkerManager: create worker [' + key + '], task count: ' + keys.length);
    return w;
  }

  // 从任务的 key 列表移除（terminate 时同步账本）
  private removeFromTask(key: string, script: string): void {
    const keys: string[] | undefined = this.scriptKeys.get(script);
    if (keys === undefined) {
      return;
    }
    const idx: number = keys.indexOf(key);
    if (idx >= 0) {
      keys.splice(idx, 1);
    }
    if (keys.length === 0) {
      this.scriptKeys.delete(script);
      this.scriptCursor.delete(script);
    }
  }

  // 释放指定 key 的 worker
  terminateWorker(key: string): void {
    const entry: WorkerEntry | undefined = this.workerMap.get(key);
    if (entry) {
      entry.worker.terminate();
      this.workerMap.delete(key);
      this.removeFromTask(key, entry.script);
    }
  }

  // 释放所有 worker
  terminateAll(): void {
    this.workerMap.forEach((entry: WorkerEntry) => { entry.worker.terminate(); });
    this.workerMap.clear();
    this.scriptKeys.clear();
    this.scriptCursor.clear();
  }

  get count(): number { return this.workerMap.size; }
  // 指定任务（script）当前实例数
  getTaskCount(script: string): number { return this.scriptKeys.get(script)?.length ?? 0; }
  hasWorker(key: string): boolean { return this.workerMap.has(key); }
}
```

> **超限轮转复用的注意点**：
> 1. 第 9+ 个 key 拿到的是该任务已登记实例的**共享句柄**，不单独登记——调用方不要长期独占缓存该返回值；同任务确需更高并发时，应改用策略一（单 worker + 消息队列排队）而非继续堆实例。
> 2. 多个调用方轮转到同一实例时，`onmessage`/`onAllErrors` 以最后设置者为准，回调和响应可能串扰——需要区分调用方时在消息体携带 id，worker 回消息时带 id 路由。
> 3. `getWorker` 在**同 key 不同 script**（key 命名冲突）时返回 `null`：不重建、不返回已有实例，原任务实例保持不动。调用方需保证 key 与任务一一对应；拿到 `null` 说明 key 撞名，修正命名即可，不要判空后换 key 重试掩盖问题。

### Step 2：业务侧只换创建那一行

> **关键：循环、`WORKER_COUNT`、`postMessage`、`onAllErrors` 等全部保留不变，只把 `new worker.ThreadWorker(script)` 换成 `mgr.getWorker(key, script)`（返回值可空，加一行 null 兜底）。**

**改造前（原始代码）：**

```typescript
export class WorkerCountService {
  static readonly WORKER_COUNT: number = 8;
  static readonly WORKER_SCRIPT: string = 'entry/ets/workers/business_worker.ets';
  private static workers: worker.ThreadWorker[] = [];

  static spawn(): void {
    for (let i = 0; i < WorkerCountService.WORKER_COUNT; i++) {
      // ↓↓↓ 原始：直接 new，无上限控制
      const w: worker.ThreadWorker = new worker.ThreadWorker(WorkerCountService.WORKER_SCRIPT);
      w.onAllErrors = (err: ErrorEvent) => { console.error('worker[' + i + '] error: ' + err.message); };
      w.postMessage({ cmd: 'start', layers: 50, layerSizeKB: 256 });
      WorkerCountService.workers.push(w);
    }
  }

  static terminateAll(): void {
    for (const w of WorkerCountService.workers) { w.terminate(); }
    WorkerCountService.workers = [];
  }
}
```

**改造后（只换创建行，其余不变）：**

```typescript
import { WorkerManager } from '../common/WorkerManager';

export class WorkerCountService {
  static readonly WORKER_COUNT: number = 8;                                      // ← 不变
  static readonly WORKER_SCRIPT: string = 'entry/ets/workers/business_worker.ets'; // ← 不变
  private static readonly WORKER_KEY_PREFIX: string = 'business-';
  private static spawned: boolean = false;

  static spawn(): void {
    if (WorkerCountService.spawned) { return; }
    const mgr: WorkerManager = WorkerManager.getInstance();
    for (let i = 0; i < WorkerCountService.WORKER_COUNT; i++) {                   // ← 循环不变
      const key: string = WorkerCountService.WORKER_KEY_PREFIX + i;
      // ↓↓↓ 唯一改动：new worker.ThreadWorker(script) → mgr.getWorker(key, script) + null 兜底
      const w: worker.ThreadWorker | null = mgr.getWorker(key, WorkerCountService.WORKER_SCRIPT);
      if (w === null) { continue; } // 仅 key 命名冲突时为 null（已打日志），正常不会走到
      w.onAllErrors = (err: ErrorEvent) => { console.error('worker[' + i + '] error: ' + err.message); }; // ← 不变
      w.postMessage({ cmd: 'start', layers: 50, layerSizeKB: 256 });               // ← 不变
    }
    WorkerCountService.spawned = true;
  }

  static terminateAll(): void {
    const mgr: WorkerManager = WorkerManager.getInstance();
    for (let i = 0; i < WorkerCountService.WORKER_COUNT; i++) {
      mgr.terminateWorker(WorkerCountService.WORKER_KEY_PREFIX + i);              // terminate 也收口
    }
    WorkerCountService.spawned = false;
  }
}
```

多任务场景（不同 script 各 1 worker）同理，key 用任务名区分：

```typescript
const WORKER_KEYS: string[] = ['enterstack', 'dataparse', 'cachewarm', ...];
const WORKER_SCRIPTS: string[] = ['.../enterstack_worker.ets', '.../dataparse_worker.ets', ...];

static spawn(): void {
  const mgr: WorkerManager = WorkerManager.getInstance();
  for (let i = 0; i < WORKER_KEYS.length; i++) {
    // 唯一改动：new worker.ThreadWorker(WORKER_SCRIPTS[i]) → mgr.getWorker(WORKER_KEYS[i], WORKER_SCRIPTS[i])
    const w: worker.ThreadWorker | null = mgr.getWorker(WORKER_KEYS[i], WORKER_SCRIPTS[i]);
    if (w === null) { continue; } // 仅 key 命名冲突时为 null（已打日志）
    w.postMessage({ cmd: 'start', layers: 50, layerSizeKB: 256 });
  }
}
```

> **注意：上限按任务独立计数，不设全应用统一上限**。不同任务（不同 script）的实例之间不能复用（worker 创建时绑定脚本），也互不挤占名额——A 任务顶满 8 个不影响 B 任务创建。全应用总量为各任务实例数之和，若多任务叠加后 `libworker.z.so` 整体仍偏高，再结合额外策略（同职责合并 / taskpool）进一步收敛。

### Step 3：全局检索收口

全局检索 `new worker.ThreadWorker(` 与 `new worker.Worker(`（旧 API），把所有创建点收口到 `WorkerManager.getInstance().getWorker()`。确认无绕过管理器的裸 `new` 创建。

---

## 额外优化策略（可选，需改业务逻辑）

> 以下策略在核心修复（WorkerManager 数量控制）基础上可叠加使用，但会修改业务逻辑，属可选优化，非核心修复。

### 策略一：同职责合并为单常驻 worker + 消息队列

同一类任务（如同为解析、同为格式化）收敛为一个常驻 worker，用消息类型字段分发。**注意：此策略改变 worker 侧与调用侧的消息协议，属业务逻辑变更。**

```typescript
// 调用侧：共用一个常驻 worker，消息携带类型字段
const textWorker: worker.ThreadWorker | null = WorkerManager.getInstance().getWorker('text-task', '.../TextWorker.ets');
textWorker?.postMessage({ type: 'parse', payload: rawText });   // key 固定且唯一，正常非空
textWorker?.postMessage({ type: 'format', payload: rawText });

// worker 侧：按消息类型分发
workerPort.onmessage = (e) => {
  const { type, payload } = e.data;
  switch (type) {
    case 'parse':  workerPort.postMessage({ type: 'parse', result: doParse(payload) }); break;
    case 'format': workerPort.postMessage({ type: 'format', result: doFormat(payload) }); break;
  }
};
```

### 策略二：短生命周期任务改用 taskpool

生命周期短、用完即走的 CPU 密集任务不建 worker，改用 taskpool（系统池化调度）。**注意：此策略改变并发模型，属业务逻辑变更。**

```typescript
import taskpool from '@ohos.taskpool';

@Concurrent
function computeTask(input: string): string { return processed(input); }

async function run() {
  const result = await taskpool.execute(computeTask, input);
}
```

---

## 常见问题排查

### worker 数量超过上限仍被创建

**现象**：同一任务（同一 script）的 worker 实例数超过 8 个，libworker.z.so 占用持续增长。

**原因**：存在绕过 `WorkerManager` 的裸 `new worker.ThreadWorker()` 创建（业务点自行 new，未走统一入口）。

**解决方案**：
1. 全局检索 `new worker.ThreadWorker(` 与 `new worker.Worker(`（旧 API），把所有创建点收口到 `WorkerManager.getInstance().getWorker()`。
2. 确认 `getWorker()` 中的 `maxWorkerPerTask` 上限检查逻辑生效（用 `getTaskCount(script)` 可查各任务当前实例数）。
3. 用 `hidumper` 查看进程线程数（每个存活 worker 对应一条线程），验证收敛效果；用 `hidebug.getPss()` 观察 worker 创建前后的内存变化，每个实例为 MB 级基线。

### 同任务超限轮转复用后，回调被覆盖 / 响应串扰

**现象**：任务实例数被限制在 8 个后，第 9+ 个调用方与已有调用方共享同一实例，先设置的 `onmessage`/`onAllErrors` 被覆盖，消息响应路由错乱。

**原因**：超限轮转复用返回的是该任务已登记实例，多个调用方持有同一实例时，回调以最后设置者为准。

**解决方案**：
1. 消息体携带调用 id，worker 回消息时带 id 路由，不依赖各调用方分别设置回调。
2. 同任务大量并发诉求改用策略一：收敛为单常驻 worker + 消息队列排队，不堆实例。
3. 短生命周期任务改用 taskpool（策略二），不占用 worker 实例。

### getWorker 返回 null（key 命名冲突）

**现象**：日志出现 `key [...] conflict`，`getWorker` 返回 `null`。

**原因**：同一 key 被两个不同 script 的任务使用，key 未按任务唯一命名。

**解决方案**：
1. key 与任务一一对应（可加任务前缀，如 `dataparse-0`、`enterstack-0`），一处 key 只对应一个 script。
2. 修正命名后冲突自然消失；不要在调用侧判空后换 key 重试，掩盖命名问题。

### 合并 worker 后任务串行化卡顿（仅策略一）

**现象**：多个业务点合并到一个常驻 worker 后，任务排队执行出现卡顿。

**原因**：单 worker 内任务是串行的，长耗时任务阻塞了后续短任务。

**解决方案**：
1. 长耗时且确有并行必要的职责保留专职 worker（但仍受总数 ≤ 8 约束）。
2. 短耗时任务改用 taskpool 并行执行，不占用常驻 worker。
3. 检查消息队列中是否有重复/可合并的任务派发。

### 存量旧写法 worker.Worker

**现象**：代码中仍在使用 `new worker.Worker()`（API 6 旧写法，已废弃）。

**解决方案**：迁移为 `new worker.ThreadWorker()`（API 9+）。注意：迁移替换不改变实例数量，仍需按本指南收敛数量；旧写法与新写法实例都计入同任务上限。

---

## 核心约束

- 每个 worker 实例对应一条独立线程 + 一套独立 ArkTS 运行时（隔离堆），单实例有 MB 级基线占用，总占用随实例数线性增长，内存账记在 `libworker.z.so`（ARKTS_HEAP/NATIVE_HEAP）。
- **同一任务（同 script）同时存活的 worker 实例建议不超过 8 个，上限按任务独立计数，不设全应用统一上限**。worker 数量过多导致内存增长时，核心修复方向是**通过 WorkerManager 控制数量**，而非调整单个 worker 内部或改业务逻辑。
- **核心修复只换创建行**：`new worker.ThreadWorker(script)` → `WorkerManager.getInstance().getWorker(key, script)`；循环、常量、`postMessage`、`onAllErrors` 等原始业务代码保留不变。`terminate()` 收口到 `WorkerManager.terminateWorker(key)` / `terminateAll()`。
- **worker 实例在 `new worker.ThreadWorker(script)` 时绑定脚本，创建后无法更换**：同 key（且 script 未变）复用同一实例；不同任务（不同 script）的实例之间不能复用，各自独立计数、互不挤占。同 key 不同 script 视为 key 命名冲突：**不重建、不返回实例（返回 null）**，原实例保持不动，由调用方修正命名。
- WorkerManager 单例统一管理创建，全应用只有这一个入口；同一任务未达上限（8 个）正常新建；达到上限后在该任务已有实例中**轮转复用**（同 script 实例可互换），不再新建。
- 全局不得有绕过 WorkerManager 的裸 `new worker.ThreadWorker()` / `new worker.Worker()` 创建。
- 同职责合并（单 worker + 消息队列）、短任务改用 taskpool 属**额外可选策略**，会修改业务逻辑，非核心修复，需单独评估。
- `worker.ThreadWorker` 为当前推荐写法（API 9+）；旧写法 `worker.Worker`（API 6 起，已废弃）应迁移，且新旧写法实例都计入 8 个上限。
