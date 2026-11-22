# TaskPool 劣化案例模式（libtaskpool.z.so / taskpool）

> 本文档定义 TaskPool 维度劣化的典型案例模式，供综合报告第八章「劣化点汇总与优化建议」根因匹配使用（案例库范围与匹配规则见 `SKILL.md` 第八章）。
>
> 匹配到下列案例时：可引用案例的根因推断与修复方向，并标注出处（如「见 taskpool.md 一、taskpool 跨线程序列化传输大量数据」）。未匹配到时：8.1 根因列写「未匹配案例库，需人工核查」，不给修改建议。
>
> **共同说明**：`libtaskpool.z.so` 为系统运行时 so（taskpool 并发框架），归属「系统SDK → ETS Utils Kit」，其占用属运行时堆（type_name 多为 ARKTS_HEAP，也可能含 NATIVE_HEAP，非 SO_SIZE）。三个案例的规则 1 均以「对比报告第四章 Top10 劣化 SO 中 `libtaskpool.z.so` 差值为正」为入口；两版数值口径遵循 `hap.md` 头部判定口径（旧版无映射记 0，新版出现映射即视为增长）。taskpool 任务跨线程传输走结构化克隆序列化（native 侧 `napi_serialize`/`napi_deserialize` 重建对象），序列化拷贝是 libtaskpool.z.so 堆增长的主要来源。

## 一、taskpool 跨线程序列化传输大量数据

### 案例模式描述

应用使用 taskpool（`@ohos.taskpool`）派发并发任务，任务传参与返回值跨线程传输走**结构化克隆深拷贝**（接收侧经 `napi_deserialize` 反序列化重建对象）。当任务传参或返回值携带大对象（大数组、大字符串、ArrayBuffer、图片像素数据、整个类实例等）时，序列化/反序列化过程在 native 侧分配大量 buffer 并随任务与引用驻留，表现为：

- `libtaskpool.z.so` 占用增长（Top10 劣化 SO）；
- native heap 调用栈中 `napi_deserialize` 帧下挂内存增长。

这类劣化本质是**跨线程序列化传输数据量过大**，属序列化拷贝型增长，而非并发计算本身的合理开销。

### 匹配规则

> **输入**：对比报告第四章「Top10 劣化 SO」表 + 步骤 4 native heap 深度分析产物（`flame_compare/libtaskpool.z.so_compare_flame.html` 前后对比火焰图、差分树 `libtaskpool.z.so_diff.json`）+ 应用源码工程。

1. **Top10 劣化 `libtaskpool.z.so`（数据规则）**：对比报告第四章 Top10 劣化 SO 表中出现 `libtaskpool.z.so` 行，且「差值(MB)」列 > 0（type_name 明细为 ARKTS_HEAP 等运行时堆类型）。
2. **火焰图 `napi_deserialize` 占用增加（数据规则）**：对比 A/B 两版火焰图，调用栈中含 `napi_deserialize` 关键帧（NAPI 结构化克隆反序列化入口；匹配时对帧名模糊匹配）的子树内存 B 版大于 A 版——差分树中 name 含 `napi_deserialize` 的节点 `delta_mb > 0`（`b_value_mb` 高于 `a_value_mb`），即反序列化路径分配增长。
3. **源码核查 taskpool 传参大对象（核查规则）**：扫描源码中 `taskpool.Task` / `taskpool.execute` 的调用点（含别名引入的短写法，如 `task.Task` / `task.execute`），逐点核对任务函数的**传参与返回值**是否携带大对象。检查要点：
   - `new taskpool.Task(func, ...args)` / `taskpool.execute(func, ...args)` 的实参 args 是否直接传入大数组、大字符串、ArrayBuffer、图片/像素数据、整对象图；
   - 任务函数的 return 是否返回大对象，回传主线程后又被长期持有（序列化副本与业务引用并存）；
   - 传参是否可替换为索引/路径/ID 等轻量引用（由任务体内自行读取原始数据）。

三条规则同时命中即确认：劣化源于 taskpool 跨线程序列化传输大量数据。规则 3 未发现大对象传参时，仅凭规则 1/2 不得下此结论（可能是合理的并发计算增长），8.1 根因列写「未匹配案例库，需人工核查」。

### 问题代码

典型反模式（源码检查时按上列检查要点逐项核对）：

- `taskpool.execute(parseTask, bigArray)` 直接把大数组作为实参传入任务，结构化克隆深拷贝使 native 侧占用成倍增长；
- 图片/文件处理任务把整个 ArrayBuffer/大字符串作为参数或返回值跨线程来回传输；
- 任务返回大结果对象后主线程长期持有，序列化副本与原对象并存不释放。

## 二、taskpool 新增调用 http 任务

### 案例模式描述

新版应用代码**新增**把 http 通信等 IO 型操作封装进 taskpool 并发任务的调用——新增 `taskpool.Task` / `taskpool.execute` 派发 http 任务，或新增 `@Concurrent` 装饰函数承载网络请求——任务对象、序列化参数/回执随请求量线性累积，`libtaskpool.z.so` 占用增加。http 请求本身是异步 IO（`@ohos.net.http` 原生异步回调/Promise），任务化不会缩短等待，反而引入序列化与任务调度开销，本质是**不合理任务派发的规模性新增**，需逐点评估必要性。

### 匹配规则

> **输入**：对比报告第四章「Top10 劣化 SO」表 + A/B 两版应用源码工程（做版本 diff，定位新增调用）。

1. **Top10 劣化 `libtaskpool.z.so`（数据规则）**：同案例一规则 1——Top10 劣化 SO 表中 `libtaskpool.z.so` 行差值(MB) > 0。
2. **源码 diff 新增 taskpool http 任务调用（核查规则）**：对比 A/B 两版源码 diff，**新版新增** taskpool 承载 http 通信的调用即命中，以下形态均计入：
   - 新增 `@Concurrent` 装饰函数或 `new taskpool.Task(...)`（含 `task.Task` 等别名短写）的任务函数体，且函数体内调用 `@ohos.net.http`（`http.createHttp`/`request`）或 `fetch` 等 http 通信 API；
   - 新增 `taskpool.execute(...)` 派发 http 任务函数的调用点。
   检查要点：
   - diff 中逐个定位新增调用点，记录 `文件:行号`；
   - 核对网络响应/回调是否作为任务返回值或序列化对象跨线程回传；
   - 存量口径：两版均存在、版本间无新增的 taskpool http 任务**不命中**本案例（「新增」为必要条件）；
   - 降级说明：仅单版源码可得、无法做版本 diff 时，本规则按「无法判定」处理，案例按未匹配降级（见 `optimization-workflow.md` 1.2）。

两条规则同时命中即确认：劣化源于新版新增的 http 通信任务被不合理地放入 taskpool。

### 问题代码

典型反模式：

```typescript
import http from '@ohos.net.http';

@Concurrent
function fetchTask(url: string) {
  // 反模式：http 为异步 IO，任务化徒增序列化与调度开销，响应对象还要跨线程序列化回传
  const req = http.createHttp();
  return req.request(url);
}
// 业务侧：taskpool.execute(fetchTask, url)，每次请求新建任务
```

- 在任务函数内做轮询/重试 http 请求，任务长期驻留线程池队列，任务对象随请求量累积不释放。

## 三、taskpool 多点新增 @Concurrent 任务

### 案例模式描述

旧版本未使用 taskpool（`libtaskpool.z.so` 无占用），新版在多个业务点引入并发任务——`@Concurrent` 装饰函数分散新增在多个不同源码文件中。taskpool 运行时随首批任务初始化并常驻，任务对象与序列化 buffer 从 0 开始累积，`libtaskpool.z.so` 从无到有增长。本质是**并发任务规模性新增**，需逐点评估必要性。

### 匹配规则

> **输入**：对比报告第四章「Top10 劣化 SO」表（或两版 `analysis/analysis_详细数据.xlsx`）+ A/B 两版应用源码工程。

1. **`libtaskpool.z.so` 从无到有（数据规则）**：Top10 劣化 SO 表中 `libtaskpool.z.so` 行差值(MB) > 0，且「旧版(MB)」= 0（两版 xlsx 中旧版无该 so 行时，按 `hap.md` 头部口径旧版记 0，新版出现映射即视为增长）——即旧版本完全没有该 so 占用。
2. **新增 `@Concurrent` 分布在不同文件（核查规则）**：对比 A/B 两版源码（A 版源码不可得时按「无法判定」降级），新增的 `@Concurrent` 装饰函数出现在**多个不同文件**中，而非单文件单点。检查要点：
   - 逐文件统计新增 `@Concurrent` 的位置（`文件:行号`），确认涉及 ≥ 2 个不同文件；
   - 抽查各新增任务内容：是否 CPU 密集、任务化收益是否大于序列化开销。

两条规则同时命中即确认：劣化源于 taskpool 多点新增 @Concurrent 任务。

### 问题代码

典型反模式：

- 多个业务模块各自新增 `@Concurrent` 轻量小任务（格式化、轻量计算、日志拼装等）并 `taskpool.execute` 派发，任务开销小于序列化开销；
- 每次调用都 `new taskpool.Task(...)` 新建任务对象且不复用，任务对象随调用量持续累积。
