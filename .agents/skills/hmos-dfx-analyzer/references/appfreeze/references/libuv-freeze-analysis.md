# libuv 冻屏分析参考（libuv Freeze Analysis）

> 适用：主线程、事件明确指定的业务线程或采样栈位于 libuv（异步 I/O 事件循环库）相关逻辑。
> 在线案例参考：https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-stability-coding-standard-libuv （稳定性编码规范 · libuv 使用规范及案例）
> 配套故障模式库条目：`fault-mode-library.md` → 三级根因「libuv EventLoop 阻塞」。

---

## 一、背景：libuv 与目标线程的关系

HarmonyOS 应用主线程的 JS EventLoop（Ark/NAPI 引擎）**直接构建在 libuv loop 之上**：
- 主线程通过 `uv_run` 驱动事件循环（`ark_native_engine.cpp` 把 NAPI loop 建在 libuv loop 上）。
- 子线程/线程池通过 `uv_async_send` 唤醒主线程；异步任务通过 `uv_queue_work(_with_qos)` 投递到 libuv 内置线程池（默认 4 线程）。
- 因此主线程卡死常常表现为栈停留在 libuv 的 `uv_run` / `uv__io_poll`，或采样栈高频命中 `uv_async_send` / `uv_queue_work` 回调。

> 结论：libuv 本身是稳定的开源库，绝大多数阻塞故障源于**调用方（应用或系统组件）误用**（在线案例文档归类的典型场景），而非 libuv 框架缺陷。根因模块应定位到实际调用实现 so / 组件，并按其归属判定责任领域。

## 二、识别特征（先判定是否命中 libuv）

满足以下任一特征即进入本文档分析流程：

| 维度 | 特征 |
|------|------|
| 调用栈 so | 出现 `libuv.so`（系统侧 `/system/lib64/.../libuv.so`；非 `libuv.z.so`） |
| 主线程/卡死线程符号 | 栈帧位于 `uv_run` / `uv__io_poll` / `uv__run_idle` / `uv_async_send` / `uv_queue_work` / `uv_queue_work_with_qos` / `uv_close` / `uv__fs_work` / `uv_fs_sendfile` 等 `uv_fs_*` 同步接口 |
| 采样栈特征 | 业务回调经 libuv 异步任务入口进入：`uv_ffrt_work` / `uv_queue_done` / `uv_queue_work` / `uv_async_send`（见 cppcrash `hints.py` 已识别的异步任务特征） |
| 关联场景 | 应用使用 NAPI（napi_async_work / ThreadSafeFunction）、自定义 libuv loop、子线程与 UI 主线程通信 |

## 三、关键符号锚点（`libuv.so` 栈帧）

| 符号 | 含义 / 阻塞含义 |
|------|----------------|
| `uv_run` | 主线程正在跑 EventLoop；长时间停留说明某阶段（poll/idle/prepare/check）卡住 |
| `uv__io_poll` | epoll_wait 阻塞；超时未返回且无任务推进时，可能 fd 未正确注册或 callback 死循环 |
| `uv__run_idle` | idle 阶段；idle 任务过多/过重拖慢主线程响应 |
| `uv_async_send` | 跨线程唤醒主循环；子线程频繁发送、主线程却无响应 → 主线程卡在别处，或 async 回调过重 |
| `uv_queue_work` / `uv_queue_work_with_qos` | 提交线程池任务；主线程卡在提交处可能线程池满（默认 4 线程全被占） |
| `uv_ffrt_work` / `uv_queue_done` | libuv 异步任务在 FFRT 后端的执行/完成入口（采样栈高频出现即业务回调密集） |
| `uv_close` | 关闭 handle；调用后 close_cb 迟迟不触发 → loop 已停止或 handle 状态错误，资源/状态卡住 |
| `uv__async_io`（遍历 async_handles） | 处理 async 句柄队列；3s/6s 栈一致地停留在该函数 → 队列遍历死循环，常见为同一句柄在多个事件循环重复初始化（见场景 1 补充） |
| `uv__fs_work` / `uv_fs_sendfile` 等 `uv_fs_*` | 文件同步接口的底层实现；出现在主线程栈上说明主线程直接调用了同步文件/IO API（见场景 6） |

## 四、典型 libuv 阻塞场景判定（对照在线案例文档归类）

> 以下场景对应官方「libuv 使用规范及案例」归纳的常见误用，按栈特征逐项排查。

### 场景 1 — EventLoop 阶段卡死（uv_run / uv__io_poll 长停留）
**特征**：主线程 warning+error 栈停留在 `uv_run` 或 `uv__io_poll`，3s 与 6s 栈顶一致（阻塞语义）。
**判定**：
1. 看 `uv__io_poll` 是否被某个 fd 的回调长时间占用（回调内执行重活/死循环）→ 根因为该回调业务。
2. 若停留在 `uv__run_idle`，检查 idle 任务是否堆积。
**根因方向**：注册到 loop 上的实际回调实现模块，非 libuv 本身；回调属于系统组件时定界为系统侧。

**补充：同一句柄在多个事件循环重复初始化 → 队列死循环（在线案例文档 Freeze 案例二）**
- **特征**：栈顶停在 `uv__async_io`（遍历 `loop->async_handles` 队列）+ `uv_io_poll` + `uv_run`，3s/6s 栈完全一致——遍历中摘下的节点又被挂回队列，形成死循环。
- **根因**：同一个 `uv_async_t` 句柄在两个事件循环（如主线程 loop 与 taskpool 的 TaskWorker loop）上重复初始化，两个链表互相交织。典型写法是把 `uv_async_t` 保存在静态/单例对象中但未做 `call_once`，每次加载组件都重新 `uv_async_init`。
- **验证**：加日志打印 `uv_async_init` 的句柄地址与所在 loop/线程，确认同一句柄地址在多个 loop 初始化。
- **修法**：单例初始化必须 `call_once`；一个句柄只在一个事件循环初始化一次。注意：同一句柄在同一 loop 重复初始化还会导致先前节点丢失 → 回调不再触发；遇到多个 `napi_threadsafe_function` / `uv_async_t` 回调不执行的问题，可同样怀疑此模式。

### 场景 2 — 线程池耗尽（uv_queue_work 提交卡住）
**特征**：主线程或提交线程栈卡在 `uv_queue_work` / `uv_queue_work_with_qos`，libuv 线程池（默认 4 线程）全部被长任务占用。
**判定**：
1. 扫描进程内 libuv 线程池 worker（通常名为 `uv-threadpool` / `libuv` worker），查看其 work_cb 是否都在执行长任务。
2. work_cb（线程池执行）阻塞会导致后续任务排队；after_work_cb（主线程执行）过重则直接卡主线程。
**根因方向**：提交的 work_cb 实现模块（耗时 IO/计算未异步化），按实现归属判定系统侧或应用侧。

### 场景 3 — async 回调过重 / 滥用（采样栈高频 uv_async_send）
**特征**：采样栈高频命中 `uv_async_send` 的回调链路（占比 >30%，参照"繁忙"判定），主线程响应被持续占用。
**判定**：
1. `uv_async_send` 本身线程安全且轻量，问题在其唤醒的主线程回调里执行了重活。
2. 对照在线案例：子线程高频 `uv_async_send` + 主线程回调重逻辑 → 主线程被唤醒回调占满。
**根因方向**：async 回调的实际实现模块。

### 场景 4 — 异步任务/handle 生命周期管理不当（uv_close 不回调 / TSFN 未释放）
**特征**：栈涉及 `uv_close` 但 close_cb 长时间不触发；或 NAPI ThreadSafeFunction 未释放导致 `uv_run` 无法退出（`ark_native_engine.cpp` 注释：活跃 TSFN 会 block uv_run，间接维持引擎存活）。
**判定**：
1. 检查 `uv_close` 后 handle 是否泄漏、loop 是否仍在运行。
2. NAPI 场景：ThreadSafeFunction（TSFN）未 Acquire/Release 配对、未 Release 释放 → 阻塞 uv_run 退出。
3. cppcrash `hints.py` 已识别同源特征：`uv_work_t` / `napi_async_work` / loop 生命周期管理不当。
**根因方向**：调用方对 libuv handle / NAPI 异步资源的生命周期管理。

### 场景 5 — uv_run 重入（嵌套调用 uv_run）
**特征**：在 loop 运行中再次调用 `uv_run`（`ark_native_engine.cpp` 会报 `uv_run is not supported when loop is running`）。
**判定**：栈出现嵌套 `uv_run`，或在回调内同步驱动另一个 loop。
**根因方向**：调用方误用（libuv 不支持 uv_run 重入）。

### 场景 6 — 主线程调用 libuv 同步阻塞接口（在线案例文档 Freeze 案例一）
**特征**：主线程栈顶在 `ld-musl` 的系统调用（如 `sendfile`），其下紧跟 `libuv.so(uv__fs_work+N)` / `libuv.so(uv_fs_sendfile+N)`，再上方为 `libfs.z.so` 等模块的 Sync 接口帧（如 `CopyFile::Sync`）与 napi 调用帧。
**判定**：应用（或经 TS 同步 API 间接）在主线程直接调用了文件/IO 同步接口，底层走 libuv 同步 fs 能力，阻塞主线程产生 freeze。
**根因方向**：调用方在主线程使用同步接口，非 libuv 本身。
**修法**：同步接口不得在主线程调用，移到 worker 线程或 taskpool。

## 五、与其他步骤的衔接

- **采样栈分析（Step 8）**：libuv 阻塞常在采样栈体现（回调密集），用 `sample_stack_analyzer.py` 统计 `uv_*` 业务帧占比，按"繁忙"阈值（>30%）定性。
- **FFRT 区分**：若 libuv 启用 FFRT 后端（`libuv_use_ffrt`），栈中会同时出现 `libffrt.so` 的 `uv_ffrt_work`；此时结合 `references/ffrt-freeze-analysis.md` 判断是否 worker 占满。
- **根因模块**：定位到实际责任实现 so / 组件（回调或 work_cb 所在 so，可为应用或系统模块），除非有 libuv 自身缺陷的直接证据，**不得**笼统归责 `libuv.so`。
- **Step 9a 输出**：三级根因填「libuv EventLoop 阻塞」，并在报告中说明细分场景与证据边界。

## 六、修复建议（严格匹配责任领域）

输出建议前先确定误用或缺陷位于应用组件、系统服务/系统封装层，还是 libuv 本身：

- 根因在系统服务、系统 NAPI/封装层或系统回调实现时，只输出对应系统模块的修改建议，例如修复 handle 生命周期、避免系统主线程同步 IO、拆分系统回调重活、修复 fd 所有权或事件循环重入。不得要求应用修改来代替系统根因修复。
- 根因在应用组件时，只输出应用侧修改。确属混合责任时分别列出；应用规避只能标为临时措施，不能替代系统侧修复。
- 仅有 `libuv.so` 栈而调用方未定位时，不猜测责任领域，先补充回调、work_cb、handle/fd 所有者的符号和栈证据。

以下建议由**实际责任模块**实施：

1. **回调内禁止重活**：`uv_async_send` 的主线程回调、`uv_queue_work` 的 after_work_cb 中不得执行长 IO/计算，重逻辑放到 work_cb（线程池）或拆分。
2. **正确使用线程池**：耗时任务用 `uv_queue_work(_with_qos)` 异步化；避免 4 个线程池 worker 同时被长任务占满；可调 `UV_THREADPOOL_SIZE`。
3. **管理好 handle/异步资源生命周期**：`uv_close` 后确认 close_cb 触发再释放资源；NAPI 的 ThreadSafeFunction / napi_async_work 必须 Acquire/Release、创建/销毁配对。
4. **同步接口移出主线程**：文件等同步 API（底层为 `uv_fs_*`）不得在主线程调用，移到 worker 线程或 taskpool。
5. **句柄初始化去重**：静态/单例持有的 `uv_async_t` 等句柄用 `call_once` 保护，确保一个句柄只在一个事件循环初始化一次，避免队列交织死循环或回调丢失。
6. **不要重入 uv_run**：回调内不得再次调用 `uv_run`；跨线程通信统一用 `uv_async_send`。
7. **参考官方规范**：对照在线案例文档 https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-stability-coding-standard-libuv 核对典型误用模式。
