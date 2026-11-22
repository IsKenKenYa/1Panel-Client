# FFRT 冻屏分析参考（FFRT Freeze Analysis）

> 适用：主线程或卡死线程阻塞在 FFRT（Function Flow Runtime）相关逻辑。
> 参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ffrt-development-guideline
> 配套故障模式库条目：`fault-mode-library.md` → 三级根因「FFRT 同步等待阻塞」。

---

## 一、识别特征（先判定是否命中 FFRT）

满足以下任一特征即进入本文档分析流程：

| 维度 | 特征 |
|------|------|
| 线程名 | 匹配 `^OS_FFRT_\d+_\d+$`（FFRT worker），或 `OS_FFRT_Monitor` / `OS_FFRT_Delay` / `OS_FFRT_IO`（辅助线程） |
| 调用栈 so | 出现 `libffrt.so` 或 `libffrt.z.so`（系统侧 `/system/lib64/chipset-sdk/libffrt.so`，NDK 侧 `/system/lib64/ndk/libffrt.so`） |
| faultlog 段 | 存在 `FfrtCatcher -- start time` ~ `FfrtCatcher -- end time` 段，或关键日志摘要中出现 `FFRT队列阻塞：队列 ... 工作线程 ... 执行超时` |
| 长任务日志 | hilog 中出现 `RecordSymbolAndBacktrace` 与 `function occupies worker for more than [N]s` |

### 1.1 FFRT worker 线程名 → QoS 映射
线程名格式 `OS_FFRT_<qos>_<序号>`，`<qos>` 对应 `ffrt_qos_*` 枚举值：

| qos 数值 | 含义 |
|----------|------|
| 0 | background（`OS_FFRT_0_*`） |
| 1 | utility（`OS_FFRT_1_*`） |
| 2 | default（`OS_FFRT_2_*`） |
| 3 | user_initiated（`OS_FFRT_3_*`） |
| 4 | deadline_request（`OS_FFRT_4_*`） |
| 5 | user_interactive（`OS_FFRT_5_*`） |

> `-1` 为 `ffrt_qos_inherit`（继承上游 QoS，不出现在线程名里）。

### 1.2 关键符号锚点（出现在 `libffrt.so` 的栈帧中）
| 符号 | 含义 |
|------|------|
| `ffrt::CPUWorker::RunTask` / `ffrt::ExecuteTask` | worker 正在执行某个任务（调度入口） |
| `ffrt::CPUEUTask::Execute` / `ffrt::UVTask::Execute` | 协程/UV 任务执行 |
| `CoYield` / `ffrt::this_task::SleepUntilImpl` / `ffrt_usleep` | 任务主动让出/睡眠 |
| `ffrt_wait` / `ffrt_wait_deps` | 同步等待任务依赖完成 |
| `ffrt_mutex_lock_wait` | 等待 FFRT 互斥锁 |
| `ffrt_cond_wait` / `ffrt_cond_timedwait` | 等待 FFRT 条件变量 |

> 出现上述符号且 so 为 `libffrt.so`，即可确认卡在 FFRT 调度/同步逻辑。

---

## 二、四类 FFRT 阻塞场景判定

按以下顺序逐项排查，命中即定界。

### 场景 1 — FFRT worker 线程池被占满
> 主线程同步提交（`ffrt::submit` / `ffrt_wait`）时，目标 QoS 的 worker 已达上限，新任务无法被调度，导致主线程长时间等待 FFRT 返回。

**容量参考（源码默认值，设备/配置可能不同）：**
- 每个 QoS 组 worker 硬上限 `DEFAULT_HARDLIMIT = 128`、`QOS_WORKER_MAXNUM = 128`
- 各 QoS 最大并发 `maxConcurrency`：user_interactive 默认 8（协程模式）或很大；其余 QoS 默认 8（协程模式）或很大
- 最小并发 `DEFAULT_MINCONCURRENCY = 4`

**判定要点：**
1. FfrtCatcher 段中某 QoS 的 `worker num` 接近/达到上限，且大量 worker 都 `is running`。
2. 主线程栈在 `libffrt.so` 的提交/等待路径（`ffrt::ExecuteTask` / `ffrt_wait`），长时间不返回。
3. 提交侧语义：队列满时 FFRT 会「退避重试（retry with backoff）」而非立即失败，表现为 submit 侧线程被持续阻塞。

**根因方向：** worker 被【长任务】或【同步等待链】占满（见场景 2/4），而非 FFRT 框架本身故障。

### 场景 2 — FFRT 任务超限（长任务占用 worker）
> 单个 FFRT 任务执行过久，占住 worker，导致后续任务排队、主线程同步等待无法返回。这是 worker 池占满（场景 1）最常见的底层原因。

**判定要点：**
1. hilog 出现 `RecordSymbolAndBacktrace`，文本含 `function occupies worker for more than [N]s`。
   - 触发节奏：任务执行 >1s 首次打印，之后约 1 分钟一次，连续 10 次后改为 10 分钟，再 10 次后固定 30 分钟。
2. 日志会打印 Worker 线程号（`OS_FFRT_*`）、占用时长、以及该任务的业务栈——**以这条业务栈作为根因栈**。
3. FfrtCatcher 段对应 worker 的 `executeTime` 异常大。

**根因方向：** 该长任务的实际实现模块（可能是应用组件，也可能是系统服务；非 FFRT 调度框架）。由该责任模块拆分或异步化长任务。

### 场景 3 — FFRT 队列任务超时（SERVICE_BLOCK 场景）
> FFRT 串行/并发队列中的任务卡住（内部等锁、等 IO、或调用了阻塞接口），队列无法推进。

**判定要点（利用脚本已提取的 FfrtCatcher 段）：**
1. 关键日志摘要出现 `FFRT队列阻塞：队列 <qname> 的工作线程 <tid> 任务 <task_id> 执行超时，后续堆栈分析以该线程为准`（由 `scripts/freeze/report.py` 生成）。
2. FfrtCatcher 段含：`tskname[<任务名>], qname=[<队列名>]` 与 `worker tid <N> ... task is running`。
   - ⚠️ 已知差异：`parse_ffrt`（`scripts/freeze/sections.py`）的第二条正则为 `worker tid (\d+) queue task is running, task id (\d+)`，而部分 dump 措辞为 `worker tid N is running, task id M`（无 `queue`、措辞不同）。若摘要未输出 FFRT 行，**应直接阅读 FfrtCatcher 段原文**，放宽匹配 `worker tid (\d+).*task.*running`。
3. 锁定卡住的 worker tid 后，取该 tid 的 warning/error 堆栈作为根因栈，按 Step 4 规则继续追踪（如内部等锁则找持锁线程）。

**根因方向：** 队列任务的实际实现模块（等锁/阻塞 IO/死循环），而非 FFRT 队列机制；按实现归属判定应用侧或系统侧责任。

### 场景 4 — FFRT 同步原语死锁
> 使用 FFRT 提供的同步原语（`ffrt::mutex` / `ffrt::recursive_mutex` / `ffrt::condition_variable` / `ffrt_rwlock`）发生锁竞争或死锁。

**判定要点：**
1. 卡死线程栈顶在 `libffrt.so` 的 `ffrt_mutex_lock_wait`（等互斥锁）或 `ffrt_cond_wait` / `ffrt_cond_timedwait`（等条件变量）。
2. 按 Step 4「等锁」规则：扫描同进程其他 `OS_FFRT_*` 线程，寻找持有相同锁（调用层次更深、处于临界区）的线程 → 持锁方。
3. 若多个线程互相等待对方持有的 FFRT 锁 → 死锁。

**根因方向：** 实际持锁模块的锁使用逻辑（锁序、未配对 unlock、在持锁回调中再次获取同一把锁）。持锁模块属于系统服务时定界为系统侧，属于应用产物时定界为应用侧。

---

## 三、faultlog 段定位

| 段 | 内容 | 用途 |
|----|------|------|
| `FfrtCatcher -- start time` ~ `FfrtCatcher -- end time` | 各 QoS ready task 数、worker 数（`worker num`）、各 worker 状态（tid/task id/name/executeTime）、阻塞依赖 | 场景 1/3 主依据 |
| `FfrtCallback:` 段 | 队列任务 dump（tskname/qname） | 场景 3 队列名/任务名 |
| hilog（`RecordSymbolAndBacktrace`） | 长任务业务栈 + 占用时长 | 场景 2 主依据 |
| 主线程 / `OS_FFRT_*` 线程 warning+error 栈 | 调用链 | 场景 4 等锁追踪 |

---

## 四、修复建议（严格匹配责任领域）

输出建议前先依据长任务栈、持锁线程、队列任务实现和模块归属判定责任领域：

- 根因在系统服务/系统组件时，只向对应系统模块提出修改，例如缩小锁粒度、修复漏解锁或锁序、禁止持锁执行同步 Binder/长 IO、为系统队列和同步接口增加超时及失败返回。不得要求应用修改来代替系统根因修复。
- 根因在应用组件时，只输出应用侧修改。确属混合责任时分别列出，系统侧根因修复优先于应用侧临时规避。
- 无法定位实际持锁方或长任务实现时，不猜测责任域；先要求补充能确定实现归属的线程栈、FfrtCatcher、符号或源码。

以下建议由**实际责任模块**实施：

1. **拆分长任务**：单任务建议 <10ms，长任务用 `ffrt::submit` 拆成任务链或用 `wait_for` 设超时，避免 worker 被独占（场景 1/2）。
2. **禁止在 worker 内同步等待自身或同组任务**：避免 `ffrt::wait` 等待会调度回自身的任务，防止 worker 被占满与死锁（场景 1/4）。
3. **用 FFRT 原生同步原语**：在责任模块的 FFRT 上下文中用 `ffrt::mutex` / `ffrt::condition_variable` 替代 `pthread_mutex` / `std::mutex`，避免协程调度被原生锁阻塞（场景 4）。
4. **合理配置并发**：通过 `ffrt_queue_attr_set_max_concurrency` 按队列实际吞吐设置并发上限；按业务优先级选择 QoS（交互型用 `user_interactive`/`user_initiated`，后台型用 `background`），避免低优任务挤占高优 worker（场景 1）。
5. **避免阻塞接口**：FFRT 任务内禁止直接调用长 IO、`sleep`、同步 Binder 等阻塞接口；IO 类用 `OS_FFRT_IO` 或异步 IO（场景 2/3）。

---

## 五、与其他步骤的衔接
- 命中本文档后，**根因模块定位到实际责任实现 so / 组件**（长任务栈或持锁方所在 so，可为应用或系统模块），而非笼统停留在 `libffrt.so`。
- Step 10a 输出三级根因时，三级填「FFRT 同步等待阻塞」，并在报告中说明细分场景（worker 占满 / 任务超限 / 队列超时 / 原语死锁）。
