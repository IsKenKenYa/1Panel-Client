# libuv 崩溃分析参考（libuv Crash Analysis）

> 适用：崩溃栈落在 `libuv.so`（系统侧 `/system/lib64/.../libuv.so`）、或故障与 libuv 异步任务 / 句柄 / 事件循环 fd 相关的 CppCrash。
> 在线案例参考：https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-stability-coding-standard-libuv （稳定性编码规范 · libuv 使用规范及案例）
> 配套自动识别：`scripts/hints.py` 中 `_is_uv_async_task` / `_is_uv_close_misuse` / `_is_fd_double_close`。

---

## 〇、定界原则

崩溃栈顶在 `libuv.so` **不等于** libuv 库缺陷。libuv 是稳定的开源库，绝大多数此类崩溃是**调用方（应用或系统组件）对 uv_work_t / uv_handle_t / fd 生命周期管理不当**，崩溃只是恰好在事件循环内部暴露。根因模块必须定位到实际调用实现 so / 组件并判定责任领域，不得直接归责 `libuv.so`。

## 一、识别特征（先判定是否命中 libuv）

| 维度 | 特征 |
|------|------|
| 调用栈 so | 栈顶或近栈顶出现 `libuv.so` |
| 异步任务符号 | `uv_ffrt_work` / `uv_queue_done` / `uv_queue_work` / `uv_async_send` → 故障模式二 |
| 事件循环符号 | `uv_run` / `uv__run_closing_handles` / `uv__finish_close` / `uv__queue_remove` / `uv_close` → 故障模式一 |
| LastFatalMessage | `errno is 9, loop addr is ..., fd is ...`（errno 9 或 22）→ 故障模式三 |
| 关联线程 | 主线程、`OS_FFRT*` 线程池线程、taskpool 的 TaskManager/TaskWorker 线程 |

## 二、核心背景知识

**uv_queue_work 执行原理（HarmonyOS）：**

1. 调用 `uv_queue_work(loop, req, work_cb, after_work_cb)`。
2. `work_cb` 封装为 `uv__queue_work`，`after_work_cb` 封装为 `uv__queue_done`。
3. 异步线程池（FFRT）执行 `work_cb`。
4. 完成后：`after_work_cb` 在主线程则按优先级插入 EventHandler 队列；在其他事件循环线程则放入 wq 队列并 `uv_async_send` 触发。

**uv_close 异步语义（关键）：**

- `uv_close` **不会**同步从事件循环移除 handle：调用后 handle 被挂到 `loop->closing_handles`，待事件循环本次迭代执行到 `uv__run_closing_handles` 时，才真正从 `handle_queue` 摘除并回调 `close_cb`。
- 因此：**调用 uv_close 之后、close_cb 执行之前，不得释放 handle 内存**。
- `uv_close` 必须在事件循环所在线程调用，否则有多线程数据竞争风险。

## 三、故障模式一：uv_close 使用不当

**栈特征**：栈顶 `libuv.so(uv_run+N)`，反编译解栈调用链为：

```
uv_run -> uv__run_closing_handles -> uv__finish_close -> uv__queue_remove
```

即崩溃在事件循环摘除 closing 节点的过程中（`uv__queue_remove` 空指针/野指针解引用）。

**典型根因**：`uv_async_t` 等 handle 作为类的普通成员变量，析构函数中调用 `uv_close(...)` 后对象随即析构释放；由于 `uv_close` 是异步操作，事件循环随后操作已释放节点 → 崩溃。

```cpp
// 错误：handle 为成员变量，析构时 uv_close 后对象立即释放
NapiTaskRunner::~NapiTaskRunner() {
    uv_close(reinterpret_cast<uv_handle_t*>(&asyncHandle), nullptr);
}   // 析构完成 asyncHandle 即释放，事件循环再访问即崩

// 正确：handle 指针化，在 close_cb 中释放
NapiTaskRunner::~NapiTaskRunner() {
    uv_close(reinterpret_cast<uv_handle_t*>(asyncHandle), [](uv_handle_t* handle) {
        delete (uv_async_t*)handle;
    });
}
```

**分析方法**：此类崩溃离问题现场较远，按 SKILL.md 步骤八开启 ASan / HWASan 复现，拿到分配栈与释放栈定位第一现场。

**修复方向**：handle 与持有它的对象分离（指针成员）；释放动作放入 `close_cb`；`uv_close` 在 loop 线程调用。

## 四、故障模式二：异步任务（uv_work_t）生命周期 UAF

异步任务崩溃按崩溃点分三种场景：

### 场景 1 — after_work_cb 执行前，函数指针已被破坏

**栈特征**：#00 帧 pc 为 `Not mapped` 的非法地址，且地址呈 **`0xdddd…dddd` 填充模式**（已释放内存的填充值），如 `SIGBUS(BUS_ADRALN)@0xddde2ddf82f7dddd`；下方便是 `libruntime.z.so` / `libeventhandler.z.so` 的事件分发帧。

**判定**：`after_work_cb` 函数指针所在内存已被释放（UAF）。`0xdddd` 与 `0x6b6b` 一样，是判断"地址来自已释放内存"的 poison 特征。

**分析方法**：异步任务崩溃离现场远，用 ASan / HWASan 复现取初次分配栈与第一次释放栈，反编译定位到提前释放 `uv_work_t` 的代码行。

**结论方向**：调用 `uv_queue_work` 系列接口时，内存释放动作必须放在 `after_work_cb` 中；自定义对象与 `uv_work_t` 分开创建、挂在 `data` 字段上各自管理。

### 场景 2 — uv__queue_done 执行期间崩溃

**栈特征**：#00 帧 `libuv.so(uv_queue_done+N)`，下方为 `libruntime.z.so` + `libeventhandler.z.so` 分发链。

**寄存器反推法（无 ASan 时的溯源手段）**：

`uv_work_s` 内存布局（`uv__queue_done` 第一个形参 `w` 在 x0）：

```
struct uv_work_s {
    UV_REQ_FIELDS
    uv_loop_t* loop;               // x0 - 24
    uv_work_cb work_cb;            // x0 - 16
    uv_after_work_cb after_work_cb;// x0 - 8
    struct uv__work work_req;      // x0
};
```

1. 结合反汇编指令确认崩溃时寄存器语义（如 `x8 = [x0 - 24]` 即取 `loop` 指针）。
2. 检查 x0 是否仍保留 `after_work_cb` 信息：`after_work_cb` 是开发者传入的函数指针，必然落在某个业务 so 的地址范围内。
3. 用 crash 文件 Maps 段中各 so 的地址范围，确定 `after_work_cb` 所属 so，减去 so 起始地址得偏移，反编译定位到具体代码行。

**uv_cancel 陷阱（该模式的常见诱因）**：`uv_cancel` **不会真正取消异步任务**，也不会阻止 `after_work_cb` 执行——它只是把 `work_cb` 置为 `uv__cancelled`，随后仍以 `status = UV_ECANCELED` 回调 `after_work_cb`。开发者调用 `uv_cancel` 后若不在回调中检查 `status == UV_ECANCELED`，清理逻辑会按预期外路径执行，导致 double free / UAF。

**结论方向**：确保在 `after_work_cb` 中释放异步任务对象的内存。

### 场景 3 — work_cb 执行前崩溃（异步线程上）

**栈特征**：线程名 `OS_FFRT*`（FFRT worker），#00 帧 pc 为 0 / `Not mapped`，#01 帧 `libuv.so(uv_ffrt_work+N)`，下方为 `libffrt.so` 的 worker 调度帧。

**判定**：提交给线程池的 `work_cb` 指针已被破坏（同为 UAF 语义），此类问题复现困难，ASan 等工具作用有限。

**结论方向**：参考场景 1，若无法确保自定义对象与 `uv_work_t` 生命周期同步，将两者分离创建、独立管理（自定义对象挂 `work->data`）。

## 五、故障模式三：fd double close（SIGABRT + LastFatalMessage）

**栈特征**：

- `Reason:Signal:SIGABRT(SI_TKILL)`，#00/#01 帧为 musl 的 `raise` / `abort`，#02 帧为 `libuv.so`（如 `uv_async_send+N`）。
- 头部存在 `LastFatalMessage`，格式为：

```
LastFatalMessage:errno is 9, loop addr is 385399404800, fd is 315 (../../../third_party/libuv/src/unix/async.c:uv_async_send:170)
```

**LastFatalMessage 字段解读**：操作的是哪个 fd、返回的 errno 是多少、该 fd 属于哪个事件循环（一个 ArkTS 线程对应一个事件循环，开发者自建的 `uv_loop_t` 也是一个事件循环）。libuv 内部对 fd 系统调用的 errno 检查不符合预期时会主动终止进程（HarmonyOS 上终止前打印该信息）。

**errno 判定**：

| errno | 含义 |
|-------|------|
| 9（EBADF） | fd 已被关闭且尚未复用 → double close |
| 22（EINVAL） | fd 已被关闭且被复用为不同类型（如原 eventfd → 新文件 fd）→ double close |

**double close 模型**：模块 A 申请 fd=100 并共享给 B；B 用完关闭 100；模块 C 申请 fd 恰好又分到 100 并正常使用；A 不知情再次 close(100) → C 使用该 fd 时崩溃。

**三种影响**：

1. fd 关闭后未复用 → 使用时 errno=9。
2. fd 被复用但类型不一致 → errno=22。
3. fd 被复用且类型相同 → **不报错但更隐蔽**：本应用触发 A 线程事件循环的回调，会被触发到持有复用 fd 的 B 线程事件循环中，表现为回调不执行/执行错乱。

**排查方法**：

1. fd 操作遵循**谁申请谁释放**；透传 fd 时明确约定透传方不得 close，确保每个 fd 仅创建一次、关闭一次。
2. fd 变量从 0 开始计数，**关闭后必须置为 -1，而不是 0**（0 是合法 fd，置 0 会导致二次关闭 stdin）。
3. ArkTS 层 TS 接口返回具体 fd 数字时同样适用上述两条。
4. 典型重复关闭案例：先通过文件管理子系统 close 接口关闭，又通过 `closeRawFd` 对同一 rawFile 描述符再次关闭。

## 六、编码规范要点（修复建议输出依据）

**Requests（uv_work_t 等短暂请求）：**

1. 内存释放必须在 `after_work_cb` 中完成；开发者不应自行管理异步任务生命周期（无法确定任务何时完成）。
2. 无法保证生命周期一致时，自定义对象与 Request 对象分开创建，自定义对象挂 `data` 字段——这样即使自定义对象管理出错，崩溃栈也落在业务逻辑上而不是系统库上，便于定位。
3. 多次相同请求可共用一个 `uv_work_t`（在 `after_work_cb` 中按需再次 `uv_queue_work`，结束时统一 delete），减少频繁申请释放。

**Handles（uv_async_t / uv_timer_t 等持久句柄）：**

1. 不使用时必须调用 `uv_close`，且在事件循环所在线程调用。
2. `uv_close` 之后到 `close_cb` 执行之前，不得释放 handle 内存（见故障模式一）。
3. 自建事件循环退出时：可 `uv_walk` 遍历 loop 上所有 handle 并在回调中 `uv_close`，再执行 `uv_run` 跑完剩余异步任务，保证事件循环正常退出、资源不泄露。
4. 同一 handle 不得在多个事件循环中初始化（会导致队列交织死循环，详见 appfreeze 技能 `references/libuv-freeze-analysis.md` 场景 1）。

**定界输出**：责任模块定位到申请/释放 uv 对象或 fd 的实际实现 so / 组件。若该实现属于系统服务、系统 NAPI/封装层或系统组件，只输出系统侧修改建议；若属于应用产物，只输出应用侧修改。责任未定时先补充对象/fd 所有者、回调和符号证据，不跨责任域猜测修复。
