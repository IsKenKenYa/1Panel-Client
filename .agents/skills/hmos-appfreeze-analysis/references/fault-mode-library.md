# 故障模式库（Freeze Root Cause Library）

> 适用故障类型：`APPFREEZE` / `THREAD_BLOCK_6S`  
> SysEvent: `name_: APP_FREEZE / REASON: THREAD_BLOCK_6S`  
> AppEvent: `name: APP_FREEZE / exception: name: THREAD_BLOCK_6S`

---

## 一级：主线程卡死超时

### 二级：主线程阻塞
> 判定特征：3s、6s 的栈顶完全在**相同的栈**上（去除基础栈后查看前三层）

| 三级根因 | 判定规则 |
|----------|----------|
| **等锁** | 1. 主线程调用栈位于 `pthread_mutex`；2. 通过 mutex 上下的业务栈找到对应锁位置；3. 通过应用其他线程查找持锁线程，或主线程自身死锁 |
| **同步 Binder 接口调用阻塞** | 1. 主线程调用栈位于 `OHOS::BinderInvoker::WaitForCompletion`；2. 通过 BinderCatcher 找到对应 `pid:tid`（tid == pid）的对端进程 PID |
| **对端 Binder 满** | 1. 主线程调用栈位于 `OHOS::BinderInvoker::WaitForCompletion`；2. 通过 BinderCatcher 找到对应 `pid:tid` 调用栈；3. BinderCatcher 显示等待对端未分配出 tid 号 |
| **阻塞 IO 操作** | 1. 同一主线程的 3s、6s 栈稳定停留在同一同步 I/O 或文件系统调用链，且业务调用方链能够解释超时；2. 候选包括文件/路径打开与读写、同步落盘、阻塞 socket，以及 `mkdir` / `mkdirat` / `open(O_CREAT)` / `mknod` / `mkfifo` / `link` / `symlink` / `rename` 等路径创建或变更操作；3. 单次栈命中只提示风险，不得直接定性；4. `close` 和事件等待接口必须满足条件性规则；完整判定见 `references/io-blocking-analysis.md` |
| **FFRT 同步等待阻塞** | 1. 主线程调用栈位于 `libffrt.so`（符号：`ffrt::ExecuteTask` / `ffrt::CPUWorker::RunTask` / `ffrt_wait` / `ffrt_mutex_lock_wait` / `ffrt_cond_wait`）；2. 通过 `FfrtCatcher` 段（`worker tid ... task is running`）定位卡住的 FFRT worker；3. 细分判定（worker 占满 / 任务超限 / 队列超时 / 原语死锁）见 `references/ffrt-freeze-analysis.md` |
| **libuv EventLoop 阻塞** | 1. 主线程调用栈位于 `libuv.so`（符号：`uv_run` / `uv__io_poll` / `uv__run_idle` / `uv_queue_work` / `uv_close` / `uv__fs_work` / `uv_fs_sendfile` 等 `uv_fs_*`）；2. 采样栈高频命中 `uv_async_send` / `uv_ffrt_work` / `uv_queue_done`（按繁忙阈值 >30%）；3. 细分判定（阶段卡死 / 线程池耗尽 / async 滥用 / 生命周期不当 / uv_run 重入 / 同步阻塞调用）见 `references/libuv-freeze-analysis.md` |
| **长时 GC 操作** | 栈顶(#00 #01)在pthread_condition_wait上的紧接(#02)着libark_jsruntime.so，可以认为虚拟机在GC；主线程调用栈位于 `panda::ecmascript::FullGC`（系统问题）；hilog 中存在 warning 级别 GC 进入前后的日志 |
| **长时 Dump 操作** | 主线程调用栈位于 `DumpHeapSnapshot` |
| **执行耗时操作** | 未匹配上述任何模式时，默认根因为执行耗时操作 |

---

### 二级：主线程繁忙
> 判定特征：3s、6s 的栈顶**不完全相同**（栈顶存在差异）
> **无采样栈时的默认匹配**：以上繁忙类三级根因均依赖采样栈占比（>30%）判定。当无采样栈或采样栈不可用时，所有繁忙类三级根因无法匹配，默认匹配"执行耗时操作"。

| 三级根因 | 判定规则 |
|----------|----------|
| **Binder 调用繁忙** | 1. 主线程调用栈位于 `OHOS::BinderInvoker::WaitForCompletion`；2. 采样栈同样位于该函数；3. 采样栈占比 **> 30%** |
| **IO 操作繁忙** | 1. 多份采样栈显示主线程持续位于同一同步 I/O 或文件系统业务调用链；2. 采样栈占比 **> 30%** 且没有稳定等待点；3. 函数范围、条件性接口和误报防护见 `references/io-blocking-analysis.md` |
| **UI 操作繁忙** | 1. 采样栈位于 ArkUI 某组件操作（关键字：`libace_compatible.z.so` / `OHOS::Ace::NG::`）；2. 采样栈占比 **> 30%** |
| **业务繁忙** | 1. 采样栈位于某一业务栈；2. 占比 **> 30%**（多个匹配取占比最多；占比一致取层级最高）|
| **频繁等锁** | 1. 采样栈位于等锁操作；2. 采样栈占比 **> 30%** |
| **执行耗时操作（多任务混合）** | 未匹配上述模式；或无采样栈时默认匹配。分析思路：① 检查采样栈是否位于某一业务栈；② 多份日志采样栈统一聚类 |

---

### 二级：系统高负载
> 判定特征：日志中包含 `system's low memory and thermal throttling`（内存 RAB < 500M 或热档位 ThermalLevel > 5）
| 三级根因 | 判定规则 |
|----------|----------|
| **系统高负载** | 日志包含 `system's low memory and thermal throttling`；内存 RAB < 500M 或热档位 ThermalLevel > 5（系统问题） |

---

## 一级：用户输入处理超时
> 适用故障类型：`APP_INPUT_BLOCK`
> SysEvent: `name_: APP_FREEZE / REASON: APP_INPUT_BLOCK`
> AppEvent: `name: APP_FREEZE / exception: name: APP_INPUT_BLOCK`
> 故障描述：用户输入处理超时，导致应用卡死
> （SE：曾智 责任田：占澎洪）

### 二级：主线程阻塞
> 判定特征：主线程调用栈或采样栈有一次不是 `OHOS::AppExecFwk::EventQueue::WaitUntilLocked`；或 3s、Input 的栈顶在**相同的栈**上

| 三级根因 | 判定规则 |
|----------|----------|
| **等锁** | 主线程调用栈位于 `pthread_mutex` |
| **对端 Binder 满** | 1. 主线程调用栈位于 Binder 调用：`OHOS::BinderInvoker::WaitForCompletion`；2. 通过 BinderCatcher 找到对应 `pid:tid` 的调用栈；3. BinderCatcher 信息显示等待对端未分配出 tid 号 |
| **阻塞 IO 操作** | 1. 同一主线程的 3s、Input 栈稳定停留在同一同步 I/O 或文件系统调用链，且业务调用方链能够解释超时；2. 候选包括文件/路径打开与读写、同步落盘、阻塞 socket，以及 `mkdir` / `mkdirat` / `open(O_CREAT)` / `mknod` / `mkfifo` / `link` / `symlink` / `rename` 等路径创建或变更操作；3. 单次栈命中只提示风险，不得直接定性；完整判定见 `references/io-blocking-analysis.md` |
| **FFRT 同步等待阻塞** | 1. 主线程调用栈位于 `libffrt.so`（符号：`ffrt::ExecuteTask` / `ffrt::CPUWorker::RunTask` / `ffrt_wait` / `ffrt_mutex_lock_wait` / `ffrt_cond_wait`）；2. 通过 `FfrtCatcher` 段定位卡住的 FFRT worker；3. 细分判定见 `references/ffrt-freeze-analysis.md` |
| **libuv EventLoop 阻塞** | 1. 主线程调用栈位于 `libuv.so`（符号：`uv_run` / `uv__io_poll` / `uv_queue_work` / `uv_close` / `uv__fs_work` / `uv_fs_sendfile` 等 `uv_fs_*`）；2. 采样栈高频命中 `uv_async_send` / `uv_ffrt_work` / `uv_queue_done`；3. 细分判定见 `references/libuv-freeze-analysis.md` |
| **长时 GC 操作** | 主线程调用栈位于 `panda::ecmascript::FullGC`（系统问题）；hilog 补充 warning 级别的 GC 进入前后的日志 |
| **长时 Dump 操作** | 主线程调用栈位于 heapdump：`DumpHeapSnapshot` |
| **执行耗时操作** | 未匹配上述故障时，默认根因为执行耗时操作：① 仅包含主线程栈的场景，根据多份日志聚合主线程调用栈；② 包含采样栈的场景，根据多份采样栈聚合 |

---

### 二级：主线程繁忙
> 判定特征：3s、Input 的栈顶**不完全相同**（栈顶存在差异）
> **无采样栈时的默认匹配**：以上繁忙类三级根因均依赖采样栈占比（>30%）判定。当无采样栈或采样栈不可用时，所有繁忙类三级根因无法匹配，默认匹配"执行耗时操作"。

| 三级根因 | 判定规则 |
|----------|----------|
| **Binder 调用繁忙** | 1. 主线程调用栈位于 Binder 调用：`OHOS::BinderInvoker::WaitForCompletion`；2. 检查采样栈是否位于 `OHOS::BinderInvoker::WaitForCompletion`；3. 采样栈占比 **> 30%** |
| **IO 操作繁忙** | 1. 多份采样栈显示主线程持续位于同一同步 I/O 或文件系统业务调用链；2. 采样栈占比 **> 30%** 且没有稳定等待点；3. 函数范围、条件性接口和误报防护见 `references/io-blocking-analysis.md` |
| **UI 操作繁忙** | 1. 采样栈位于 ArkUI 某组件操作（UI 关键字：`libace_compatible.z.so` / `OHOS::Ace::NG::`）；2. 采样栈占比 **> 30%** |
| **业务繁忙** | 1. 采样栈位于某一业务栈；2. 采样栈占比 **> 30%**（多个匹配取占比最多的函数；占比一致取层级最高的作为根因） |
| **频繁等锁** | 1. 采样栈位于等锁操作；2. 采样栈占比 **> 30%** |
| **执行耗时操作（多任务混合）** | 未匹配上述模式，根因为多任务混合执行；或无采样栈时默认匹配。分析思路：① 检查采样栈是否位于某一业务栈；② 多份日志采样栈统一聚类 |

---

### 二级：系统高负载
> 判定特征：日志中包含 `system's low memory and thermal throttling`

| 三级根因 | 判定规则 |
|----------|----------|
| **整机高负载** | 日志中包含 `system's low memory and thermal throttling`（系统问题） |
