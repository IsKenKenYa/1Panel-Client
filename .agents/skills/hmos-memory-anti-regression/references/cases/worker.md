# Worker 劣化案例模式（libworker.z.so / worker）

> 本文档定义 Worker 维度劣化的典型案例模式，供综合报告第八章「劣化点汇总与优化建议」根因匹配使用（案例库范围与匹配规则见 `SKILL.md` 第八章）。
>
> 匹配到下列案例时：可引用案例的根因推断与修复方向，并标注出处（如「见 worker.md 一、worker 新增数量过多」）。未匹配到时：8.1 根因列写「未匹配案例库，需人工核查」，不给修改建议。
>
> **共同说明**：`libworker.z.so` 为系统运行时 so（`@ohos.worker` 线程框架），归属「系统SDK → ETS Utils Kit」，其占用属运行时堆（type_name 可含 ARKTS_HEAP 与 NATIVE_HEAP——每个 worker 线程拥有独立 ArkTS 运行时/隔离堆，非 SO_SIZE）。两版数值口径遵循 `hap.md` 头部判定口径（旧版无映射记 0，新版出现映射即视为增长）。

## 一、worker 新增数量过多

### 案例模式描述

应用使用 `@ohos.worker` 创建 worker 线程（`new worker.ThreadWorker()`，旧 API 写法 `new worker.Worker()`）。每个 worker 实例对应**一条独立线程 + 一套独立 ArkTS 运行时（隔离堆）**，单个实例即有几 MB 级基线占用（线程栈 + 运行时初始化），总占用随实例数线性增长。新版新增 worker 实例化调用、或调大既有调用点的创建数量（常量/循环上界/批量条数等），叠加用后不 `terminate` 或按次新建，worker 实例累积超过必要规模，表现为：

- `libworker.z.so` 占用增长（Top10 劣化 SO，ARKTS_HEAP/NATIVE_HEAP 明细均为正差值）；
- 源码中 worker 实例化调用点增多，或单点创建的实例数量被调大。

这类劣化本质是**worker 实例数量型增长**（同一任务/同一 script 重复创建多实例），而非单个 worker 内业务数据的合理增长，也非多任务并行（不同 script 各 1 worker）的架构选择。

### 匹配规则

> **输入**：对比报告第四章「Top10 劣化 SO」表 + A/B 两版应用源码工程（做版本 diff）。

1. **Top10 劣化 `libworker.z.so`（数据规则）**：对比报告第四章 Top10 劣化 SO 表中出现 `libworker.z.so` 行，且「差值(MB)」列 > 0（type_name 明细为 ARKTS_HEAP / NATIVE_HEAP 等运行时堆类型）。
2. **源码 diff worker 数量增加（核查规则）**：对比 A/B 两版源码 diff，新版 worker 创建数量增加即命中，以下两种形态均计入：
   - **新增实例化调用点**：新增的 `new worker.ThreadWorker()` 或 `new worker.Worker()`（旧 API，已废弃但存量代码仍在用）调用（含别名引入的短写法，如 `import worker from '@ohos.worker'` 后以 `new ThreadWorker(...)` 调用）；
   - **存量调用点创建数量调大**：实例化调用点本身未新增，但其实际创建实例数被调大——创建数量常量/配置项（如 `WORKER_COUNT`）、循环上界、批量创建条数等的版本间修改。
   检查要点：
   - diff 中逐个定位新增实例化调用点与数量调大修改点，记录 `文件:行号` 与数量变化（旧值 → 新值）；
   - 核对所在业务：是否短生命周期任务、是否用后 `terminate`、是否存在同职责重复建 worker。
   - 降级说明：仅单版源码可得、无法做版本 diff 时，本规则按「无法判定」处理，案例按未匹配降级（见 `optimization-workflow.md` 1.2）。
3. **同一任务 worker 数量 ≥ 8（核查规则）**：统计**新版同一任务实际创建的 worker 实例数**，**大于等于 8 个**即命中（阈值 8 为经验判定线：同一任务的 worker 数量建议不超过 8 个，达到该数量说明实例规模已超出常规业务需要，而非个别业务点的合理引入）。

   > ### ⚠️ 规则 3 判定前置——先区分「同一任务」还是「多任务并行」，再计数（高频误判点）
   > **真实教训**：某次分析中，源码 `WORKER_COUNT=8` + `for` 循环 `new worker.ThreadWorker(WORKER_SCRIPTS[i])`，AI 见 `WORKER_COUNT=8 ≥ 8` 直接判「命中」。但 `WORKER_SCRIPTS` 是 **8 个不同 script 路径**的数组（8 个不同任务），按下方口径 b 属「多任务并行每任务各 1 worker」，同一任务实例数 = 1 < 8，规则 3 **不通过**，案例应判「未匹配」。
   > **判定流程**：① 先查循环内 `new worker.ThreadWorker()` 传入的是**同一个 script 路径**还是**不同 script 路径**（检查 script 路径变量是否为数组/是否随循环变量变化）；② 同一个 script → 口径 a 计数；③ 不同 script → 口径 b，不累加，直接判规则 3 不通过。

   统计口径：
   - 口径 a **同一 script（同一任务）在循环/批量中创建 N 个实例**：位于循环/批量创建逻辑中的调用点按实际创建实例数计入（如循环上界/常量 `WORKER_COUNT=8`、循环内 `new worker.ThreadWorker(WORKER_SCRIPT)` —— `WORKER_SCRIPT` 是单个字符串非数组，该调用点计 8 个）；
   - 口径 b **不同 script 路径（不同任务）各 1 个 worker——多任务并行**：**不累加到"同一任务"**，属合理的架构选择，不属本案例的"实例数量型增长"（每任务仅 1 实例无数量膨胀，其内存增长归因于任务内部业务数据或 JSVM 基线，非 worker 实例数过多）。典型形态：`WORKER_SCRIPTS: string[] = [8 个不同路径]` + `for` 循环 `new worker.ThreadWorker(WORKER_SCRIPTS[i])`——虽然 `WORKER_COUNT=8` 且循环创建，但 8 个 worker 分属 8 个不同任务，同一任务实例数 = 1 < 8；
   - 新版替换写法（`worker.Worker` → `worker.ThreadWorker` 迁移）不构成「数量增加」，不计入。

三条规则同时命中即确认：劣化源于 worker 新增数量过多（实例数量型增长）。规则 2 未发现数量增加、或规则 3 同一任务实例数 < 8（含多任务并行每任务各 1 worker 的场景）、或无法做版本 diff 时，仅凭规则 1 不得下此结论（可能是单个 worker 内合理的数据增长），8.1 根因列写「未匹配案例库，需人工核查」。

### 问题代码

典型反模式（源码检查时按上列检查要点逐项核对）：

```typescript
import worker from '@ohos.worker';

// 反模式一：各业务点各自新建 worker，短任务用完不 terminate，实例随业务点/调用次数累积
const w1 = new worker.ThreadWorker('entry/ets/workers/parseWorker.ets');
const w2 = new worker.ThreadWorker('entry/ets/workers/decodeWorker.ets');
// ... 多处新增，总量超过必要规模
```

```typescript
// 反模式二：实例化调用点未新增，创建数量常量调大——单点即可使实例数成倍增长
export class WorkerCountService {
  // A 版 = 4（B 版改为 8）：diff 中调用点一行未动，仅此常量变化
  static readonly WORKER_COUNT: number = 8;

  static spawn(): void {
    for (let i = 0; i < WorkerCountService.WORKER_COUNT; i++) {
      const w = new worker.ThreadWorker(WorkerCountService.WORKER_SCRIPT); // 循环内单点
      // ...
    }
  }
}
```

- 页面每次进入都 `new worker.ThreadWorker(...)`，离开时不 `terminate`，实例跨页面累积；
- 同一职责拆成多个 worker、或本可用单 worker + 消息队列承接的任务拆散为多实例，实例数无序扩张；
- 循环/批量创建的实例数量被常量或配置调大（如 `WORKER_COUNT` 4→8），业务负载未变而实例数成倍增长。

### 非反模式（看似命中规则 3 实则不匹配——勿误判）

> **以下场景规则 3 不通过**，案例按「未匹配」处理。与上方反模式的唯一区别在于 script 路径是否相同。

```typescript
// 非反模式：WORKER_COUNT=8 + 循环创建，但 8 个 worker 分属 8 个不同 script（不同任务）
// → 口径 b「多任务并行每任务各 1 worker」，同一任务实例数 = 1 < 8，规则 3 不通过
export class WorkerMultiTaskService {
  static readonly WORKER_COUNT: number = 8;
  // ⚠️ 注意：WORKER_SCRIPTS 是数组，WORKER_SCRIPTS[i] 随循环变量 i 变化——8 个不同 script 路径
  static readonly WORKER_SCRIPTS: string[] = [
    'entry/ets/workers/enterstack_worker.ets',    // 任务0：递归栈
    'entry/ets/workers/dataparse_worker.ets',     // 任务1：JSON解析
    'entry/ets/workers/cachewarm_worker.ets',     // 任务2：缓存预热
    'entry/ets/workers/computematrix_worker.ets', // 任务3：矩阵计算
    'entry/ets/workers/logaggregate_worker.ets',  // 任务4：日志聚合
    'entry/ets/workers/datacompress_worker.ets',  // 任务5：压缩缓冲
    'entry/ets/workers/imagebuffer_worker.ets',   // 任务6：图像帧
    'entry/ets/workers/networkcache_worker.ets'   // 任务7：网络缓存
  ];

  static spawn(): void {
    for (let i = 0; i < WorkerMultiTaskService.WORKER_COUNT; i++) {
      // ⚠️ WORKER_SCRIPTS[i]——每次迭代传入不同 script，8 个不同任务各 1 worker
      const w = new worker.ThreadWorker(WorkerMultiTaskService.WORKER_SCRIPTS[i]);
    }
  }
}
// 判定：规则 1 ✅（libworker.z.so Top10 劣化）、规则 2 ✅（新增实例化调用点）、
// 规则 3 ❌（同一任务实例数 = 1 < 8，属多任务并行）→ 案例未匹配
//
// 与反模式二的区别：反模式二传 WORKER_SCRIPT（单个字符串），循环 N 次创建同一 script 的 N 个实例（同一任务 N 个 → 口径 a）；
// 本例传 WORKER_SCRIPTS[i]（数组按索引取值），循环 N 次创建 N 个不同 script 各 1 个实例（不同任务各 1 个 → 口径 b）。
// 判定时检查：循环内 new worker.ThreadWorker() 的参数是常量字符串（同一 script）还是随循环变量变化的数组元素（不同 script）。
```
