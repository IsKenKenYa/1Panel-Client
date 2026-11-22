---
name: hmos-appfreeze-analysis
description: >
  DFX Skills，自动分析 HarmonyOS / OpenHarmony Freeze（冻屏/卡死）故障日志，定位根因并输出完整证据链。
  当用户提供完整的faultlog 文件和采样栈文件、询问应用无响应/卡死/ANR 问题的根因，
  或上传包含 APPFREEZE / INPUT_BLOCK / LIFECYCLE_TIMEOUT / THREAD_BLOCK_6S /
  BUSSINESS_THREAD_BLOCK_6S / BUSINESS_THREAD_BLOCK_6S 等关键字的日志时，必须使用此技能。
  即使用户只说"帮我分析这个 freeze 日志"、"应用卡死了是什么原因"，也应立即触发此技能。
  技能会按优先级逐步排除整机低内存、高负载、热限频等系统级异常，再深入分析线程堆栈、
  Binder 通信链路、EventHandler 队列，最终输出唯一根因模块与修复建议。
metadata:
   author: Huawei Reliability Technology Lab
   version: 1.4.0
---

# Appfreeze Analysis Skill

## 角色定位
HarmonyOS 高级开发工程师 / HarmonyOS 架构师 / 系统 DFX 工程师 / 整机稳定性专家。  
精通 OpenHarmony 代码，擅长线程管理、Binder 机制、整机状态管理、内存管理、模块解耦等。

## 分析目标
从 faultlog 中识别应用冻屏的**唯一根因**，构建完整证据链，指出责任模块，并给出修复建议。

## 约束
- 必须基于日志中**实际存在**的信息，严禁编造或随意拼接日志片段。
- 每条关键结论必须有原始日志内容作为佐证。
- 按以下 Step 顺序逐步分析，遇到可直接定性的整机异常时可提前终止并输出结论。
- 输出修复建议前必须先判定责任领域（应用 / 系统 / 混合 / 未定），修复建议必须与根因责任领域一致。
- 证据链确认根因在系统服务、系统框架或系统库时，**只输出系统侧修改建议**，并定位到具体系统模块、函数、锁、队列或接口契约；不得把应用规避方案写成根因修复，也不得要求应用为系统缺陷承担修改责任。
- 根因在应用侧时只输出应用侧修改建议；确属混合责任时分栏列出双方修改，先写主要责任方。责任未定时只列补充证据与验证方向，不跨责任域猜测修改方案。
- 仅当用户明确要求临时规避方案时，才可在系统侧根因之后单列“应用侧临时规避”；必须注明它不替代系统侧根因修复。
- 输入类型断言失败时必须立即停止 AppFreeze 分析。用户指定本技能不改变输入校验要求；Crash 日志、OOM 内存快照及非 AppFreeze 类型的输入不得用于生成 AppFreeze 诊断结论。

---

## 分析工作流

### Step 0 — 前置环境检查

在调用任何脚本前，必须先完成以下环境检查：

1. **Python 可用性检查**
   ```bash
   python --version
   ```
   - 若命令不可用，先提示用户安装 Python 3。
   - 若系统同时存在 `python3`，可使用 `python3` 替代后续命令中的 `python`。

2. **脚本路径检查**
   确认以下脚本存在：
   - `<skill-root>/scripts/freeze/main.py`
   - `<skill-root>/scripts/sample_stack_analyzer.py`
   - `<skill-root>/scripts/llvm_addr2line.py`
   - `<skill-root>/scripts/match_so.py`

3. **依赖检查**
   appfreeze Python 脚本仅使用 Python 标准库和本技能内置模块，无需安装第三方 pip 依赖。
   如脚本执行失败，优先检查：
   - `<skill-root>` 是否指向 `appfreeze-analysis` 技能根目录
   - Python 命令是否指向可用解释器
   - 输入的 faultlog / sample_stacks 文件路径是否存在

4. **输入类型断言**
   - `scripts/freeze/main.py` 会在解析前检查日志头部 `Reason` 与 Freeze 事件字段。
   - 识别为 `CPP_CRASH` 时停止并改用 `cppcrash-analysis`；识别为 `JS_CRASH` 时停止并改用 `jscrash-analysis`。
   - 无法证明属于 AppFreeze 时停止，依据日志头部确认故障类型；信息不足时请用户补充完整日志，不得跳过断言继续输出 Freeze 根因。

### Step 1 — 读取轻量概览
> 首次只读取日志元数据和区段索引：
>
> ```bash
> python "<skill-root>/scripts/freeze/main.py" -p "<file_path>" --section overview
> ```

概览仅用于确认选中日志、故障类型、PID/TID、时间、NOTE、FFRT 目标，以及各区段是否存在和数量。不得在首轮读取完整报告。

#### 故障目标线程路由（概览后必须执行）

- `THREAD_BLOCK_6S`、`APP_INPUT_BLOCK`：按对应故障模式分析主线程或事件明确指定的目标线程。
- `BUSSINESS_THREAD_BLOCK_6S` / `BUSINESS_THREAD_BLOCK_6S`：这是业务线程超时事件，其中 `BUSSINESS` 是日志中的历史拼写。必须使用事件上报的 `TID` 作为故障目标线程，并读取该 TID 对应的 3s、6s 堆栈；不得使用进程 PID 对应的主线程堆栈替代业务线程堆栈。
- 业务线程事件中，主线程与其他线程堆栈只用于分析跨线程依赖、持锁方或上下文，不参与该事件“阻塞/繁忙”的直接判定，除非证据证明目标业务线程正在同步等待这些线程。
- 事件 `TID` 缺失时，才可从 `OH_HiCollie_Report ... current tid` 或同一上报区段中的线程信息恢复目标 TID，并在结论中降低可信度；无法恢复时不得改用主线程强行定性。

按以下顺序按需读取区段：

1. `overview`：每次分析必须首先读取。
2. `resources`：概览显示存在资源信息时读取；命中明确整机异常后按现有规则提前结束。
3. `event-queue`：概览显示存在队列信息时读取。
4. `fault-stack`：未被整机异常定性时读取。
5. `other-threads`：仅当故障栈表现为等锁时读取。
6. `binder`：仅当栈包含 Binder 等待、出现 IPC FULL 特征，或前面步骤无法形成闭环时读取。
7. `attachments`：仅在需要采样栈或其他日志路径时读取。
8. `full`：仅当用户明确要求完整提取，或需要调试解析器时读取。未指定 `--section` 也会输出完整报告，以兼容旧命令。

### Step 2 — 整机资源评估（低内存 / 高负载）
概览中 `resources` 为“有”时执行：

```bash
  python "<skill-root>/scripts/freeze/main.py" -p "<file_path>" --section resources
```

结合概览与资源区段识别：
- 故障时间（Fault time）
- 上报 hiview 时间
- 抓栈开始时间
- 故障类型（APPFREEZE / INPUT_BLOCK 等）
- 故障进程 PID / TID

---

**优先级最高，若命中则直接终止后续分析。**

#### 2a. 根据NOTE信息判断整机高负载
规则：提取的关键日志中的NOTE信息出现**system's low memory and thermal throttling**，直接认定为整机高负载，而且二级根因和三级根因需要明确定为高负载。

可以列出相关信息（CPU、内存、温度信息）用来佐证整机高负载。

- 1、CPU信息
数据源优先级：**优先使用采样栈文件（cpuinfo-ext）中`#CpuFreq Usage（usage >= 1%）`区域各核使用率和频率作为参考，未提供时回退到关键日志中的 CPU 信息**。
时间校验：分析CPU信息中的时间信息，如果时间与故障时间相差**超过10s**，则该部分内容不具参考价值。
分析规则（按数据源区分）：

   >来自故障日志：取 Total 使用率，**>85%** 则结论加入 **CPU负载过高**，佐证整机高负载；
   >来自采样栈：按频率将各核聚类（频率分布相同或高度相近的归为一组），组名用核心编号范围表示（如cpu0-cpu3），不附加核心类型标签。对每组分别计算 Usage 算术平均值并独立判定，**>85%** 的组在结论加入 **{组名}负载过高**（如「cpu0-cpu3负载过高」），佐证整机高负载。
   >**严禁在报告任何位置（结论、证据链、原始日志摘录）显示CPU频点/频率分布等信息**，避免误导开发者。摘录CPU原始日志时只保留Usage数值，删除所有频点行。

- 2、内存信息
分析关键日志中的内存信息，如果时间与故障时间相差**超过2分钟**，则该部分内容不具参考价值；
分析规则：当可用内存 **<800MB**，则结论中加上**低内存**，进一步佐证整机高负载

- 3、温度信息
分析关键日志中的温度信息;
分析规则：
  >如果温度等级 **≥4**，则结论中加上**热限频**警告备选结论，
  >如果温度等级 **>5**，则结论中加上**温度过高导致热限频**，温度过高导致热限频

> **注意**：低内存 / 高负载 / 高温等整机异常会导致 DFX 维测信息失真，典型特征：
> 瞬时栈（warning 与 error 不一致）、无堆栈、堆栈获取延时、Binder 获取延时。

#### 2b. 时间差异性校验（定性）
| 检查项 | 阈值 | 结论 |
|--------|------|------|
| 故障时间 → 上报 hiview 时间差 | > 10 s | 怀疑整机异常，维测信息不可信 |
| 故障时间 → 抓栈开始时间差 | > 2 s | 堆栈内容不可信，怀疑整机异常 |

---


### Step 3 — EventHandler 任务队列分析

概览中 `event-queue` 为“有”时执行；不存在则跳过本步骤：

```bash
python "<skill-root>/scripts/freeze/main.py" -p "<file_path>" --section event-queue
```

对于 `BUSSINESS_THREAD_BLOCK_6S` / `BUSINESS_THREAD_BLOCK_6S`，只有队列所属 TID 与故障业务线程 TID 一致，或日志存在明确的跨线程同步等待关系时，EventHandler 队列才能作为根因证据。主线程队列不能直接解释业务线程超时。

#### 3a. Current Running（当前执行任务）
- 执行时间 = `EventHandler dump begin curTime` − `trigger time`（warning 与 error 取较大值）
- 执行时间 **> 3 s** → 该任务阻塞了 EventHandler 队列，需业务模块排查原因。

#### 3b. History Event Queue（历史队列）
- 执行时间 = `completeTime` − `trigger time`
- `completeTime` 为空 → 任务仍在执行，按 4a 规则处理，无需重复判断。
- 某历史任务执行时间 **> 3 s** → 说明已触发过一次 freeze 上报，需排查该任务耗时原因。

---

### Step 4 — 符号解析 & 关联线程堆栈分析
未被整机异常定性时，执行下列流程：

#### 4a. 符号解析（可追溯源码时执行，无源码追溯时跳过此步骤）
**必要依赖**：源码可达性检测
- 在当前工作目录（及父目录）中查找以下标志文件：`build-profile.json5`、`oh-package.json5`、`AppScope/app.json5`
- 若找到，读取 `AppScope/app.json5` 中的 `bundleName` 字段，与提取 faultlog 中的故障进程包名对比，若一致即源码可达；若不一致即源码不可达，直接跳过符号解析流程。

**触发条件**（满足其一即需解析）：
- 栈顶或责任调用链上的栈帧为应用 so，且只有**裸偏移地址 + BuildID**。
- 例：`#05 pc 000000000000a128 /data/storage/el1/bundle/libs/arm64/libxxx.so(f3991876654443a608c9cc71f20cf4d8caab449f)`
- 栈顶或责任调用链上的关键栈帧的符号信息为「函数名+偏移量」。

**不解析的场景**：
- 系统库帧（`libffrt.so`、`libace_compatible.z.so` 等）—— 日志已带符号名，且不在应用侧责任范围。
- 用户未提供带符号的 SO 文件路径，且当前工程没有找到对应 SO 文件。**若 SO 文件不可用**：跳过本步骤，在报告中标注"无带符号so文件，行号定位不可用"

**so 文件校验**（地址解析前必须执行）：
从 faultlog 栈帧中提取应用 SO 文件名和 BuildID，校验源码工程目录下同名 .so 是否为同一编译产物（若系统只有 `python3` 可用则替换）：
```bash
   python scripts/match_so.py {so_name} {build_id} -d {search_dir}
```
- 退出码 0（stdout 输出匹配路径）→ 用该路径执行下方地址解析
- 退出码非 0 → 跳过地址解析，在报告中标注「未找到与 faultlog 版本匹配的 SO 文件，行号定位不可用」

**地址解析**（仅在 so 文件校验通过时执行）：
通过 Python 脚本自动定位 `llvm-addr2line` 并对 BuildID 匹配的 .so 文件执行地址解析。（若系统只有 `python3` 可用，则使用 `python3` 替代 `python`）
```bash
   python scripts/llvm_addr2line.py -pCfie {matched_so_file} {offset}
```
其中 `{matched_so_file}` 为 so 文件校验输出的匹配路径。

对崩溃栈中关键帧及前后 3 帧应用帧逐一解析，根据解析结果定位源码分析根因。

- **若脚本执行失败（退出码非 0）**：说明系统中未找到 `llvm-addr2line` 工具。此时：
- 提示用户：「未找到 llvm-addr2line 地址解析工具，请安装后重试。可通过以下方式安装：」
- 提供安装指引：
- 请确保 DevEco Studio 已安装并配置了环境变量DEVECO_HOME，工具位于 `<DEVECO_HOME>/sdk/default/openharmony/native/llvm/bin/`。可设置 `DEVECO_HOME` 环境变量指向 DevEco Studio 安装目录后重试。
- 在报告中标注"符号解析工具不可用，堆栈行号定位未执行"，跳过此步骤。

#### 4b. 堆栈分析

```bash
   python "<skill-root>/scripts/freeze/main.py" -p "<file_path>" --section fault-stack
```

> 堆栈调用方向：**栈底（最大编号）→ 栈顶（#00）**，栈顶为最后被调用位置。

1. 先按 Step 1 的故障类型路由选定目标线程，再分析 warning / error 级别堆栈：普通 `THREAD_BLOCK_6S` 分析主线程，业务线程事件分析上报 `TID` 对应的业务线程。阻塞/繁忙由分析过程综合判断，脚本只负责提取原始栈，不得输出或替代根因判定。
   - 必须比较同一目标 TID 的两次完整调用链，不能只比较 `#00`。比较时排除抓栈、信号处理、调度器、运行时跳板和 libc 包装帧，定位距离栈顶最近的有效等待或执行函数，并比较该函数及其向栈底方向的调用方链。
   - 命中等锁、条件变量、Binder 同步等待、阻塞 IO、长时 GC/Dump 等明确等待特征，且调用链能够解释超时时，判为"阻塞"。
   - 两次采样虽栈顶不同，但落在同一个耗时函数、同一等待原语或同一稳定调用链中，仍判为"阻塞"，不得仅因栈顶差异判为"繁忙"。
   - 两次采样位于不同执行阶段，且不存在稳定等待点；或多份采样栈持续在同一任务的多个函数之间推进，才判为"繁忙"。
   - 只有一次有效抓栈、有效业务帧缺失、目标 TID 不一致或证据相互冲突时，判为"无法判定"，不得强行套用阻塞/繁忙三级根因。
2. **逐帧解读**：证据链中必须对故障目标线程的调用栈逐帧（或对关键帧）添加行内注释（如 `← 点击手势识别`、`← NAPI 桥接入口`），不得仅列帧而不解读。帧数 >30 时可仅对关键帧注释，但需说明省略范围。
3. **字节码桩语义解读**：当栈顶（#00）位于 `stub.an` 等 ArkTS 字节码桩时，必须解读字节码指令的语义含义（如 `BCStub_HandleCallRuntimeIsfalsePrefImm8StwCopy` 表示条件/循环的 Isfalse 判定，呈循环式活跃执行），据此推断应用代码的执行状态。
4. 若卡死线程栈顶处于**等锁**状态，则：
   ```bash
   python "<skill-root>/scripts/freeze/main.py" -p "<file_path>" --section other-threads
   ```
   - 扫描同进程其他子线程，寻找**持有相同 so、且调用层次更深**的线程 → 该线程即持锁方。
   - 依此递推，找到**最终持锁位置**。
5. **同步 I/O / 文件系统阻塞识别（命中时必做）**：若应用主线程调用栈或采样栈命中同步 I/O、路径解析或文件系统元数据操作，包括 `open` / `read` / `write` / `fsync`、socket 收发与连接，以及 `mkdir` / `mkdirat` / `open(O_CREAT)` / `mknod` / `mkfifo` / `link` / `symlink` / `rename` 等路径创建或变更接口：
   - 📖 读取 `references/io-blocking-analysis.md`，按 I/O 对象、同步/非阻塞模式、重复抓栈、采样占比和业务调用方逐项判定。
   - 单次栈命中只表示「主线程同步 I/O 风险」，不得直接定性为根因。只有同一目标 TID 的 3s、6s 栈稳定停留在同一有效调用链且能够解释超时时，才可判为「阻塞 IO 操作」；多份采样栈同一 I/O 业务链占比 **>30%** 且持续推进时，才可判为「IO 操作繁忙」。
   - `close` / `fclose` 仅在 `SO_LINGER`、同步提交或缓冲刷新等条件有证据时作为阻塞候选；`poll` / `select` / `epoll_wait` / `uv__io_poll` 位于正常事件循环空闲路径时不得作为根因。
   - 根因确认为应用主线程同步 I/O 时，必须提示该接口可能等待路径解析、目录锁、存储设备、管道或网络/用户态文件系统响应，不建议在 UI 主线程直接调用，应使用异步 API 或移至 worker/taskpool。
6. **FFRT 阻塞识别（命中时必做）**：若卡死线程（主线程或子线程）调用栈出现 `libffrt.so` / `libffrt.z.so`，或线程名匹配 `OS_FFRT_`，则判定为 FFRT 相关阻塞：
   - 若关键日志摘要已出现 `FFRT队列阻塞：队列 ... 工作线程 ... 执行超时`，直接以该工作线程作为根因分析对象。
   - 📖 读取 `references/ffrt-freeze-analysis.md`，按其中四类场景（worker 占满 / 任务超限 / 队列超时 / 原语死锁）逐项排查定位。根因模块定位到实际责任实现 so / 组件（可以是应用或系统模块）；除非有 FFRT 框架自身缺陷的直接证据，**不得**停留在 `libffrt.so`。
7. **libuv 阻塞识别（命中时必做）**：若故障目标线程调用栈或采样栈出现 `libuv.so`，或命中符号 `uv_run` / `uv__io_poll` / `uv_async_send` / `uv_queue_work` / `uv_ffrt_work` / `uv_queue_done` / `uv_close` / `uv__async_io` / `uv__fs_work` / `uv_fs_sendfile`，则进入 libuv 链路分析：
   - 对主线程，长时间停留在 `uv_run` / `uv__io_poll` 或采样栈高频命中 `uv_*` 回调时，继续追踪实际回调或 fd 所有者。
   - 📖 读取 `references/libuv-freeze-analysis.md`，按其中场景（阶段卡死 / 线程池耗尽 / async 滥用 / 生命周期不当 / uv_run 重入 / 同步阻塞调用）逐项排查。案例参考 https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-stability-coding-standard-libuv 。根因模块定位到实际责任实现 so / 组件（可以是应用或系统模块）；除非有 libuv 自身缺陷的直接证据，**不得**停留在 `libuv.so`。

---

### Step 5 — Binder 通信链路分析

仅当故障栈包含 Binder 等待、日志出现 IPC FULL 特征，或此前步骤无法形成证据闭环时执行：

```bash
   python "<skill-root>/scripts/freeze/main.py" -p "<file_path>" --section binder
```

1. 从 `binder catcher` 信息追踪 IPC 调用链，找到**最终阻塞的对端进程及线程**。
2. 若对端线程处于等锁状态 → 同 Step 5 方式找到持锁线程。
3. 若对端 binder 线程数为 0 且出现 **IPC FULL（binder 资源耗尽）**：
   - 分析所有 IPC 线程，若大量线程因锁竞争阻塞 → 按持锁追踪规则找到最终位置。
   - BinderCatcher 中目标 TID 为 `0` 表示对端尚未分配工作线程，应把该节点视为对端进程的 Binder 线程通配节点，继续追踪该进程各实际 Binder 线程发出的同步调用，不得在 `<pid>:0` 提前终止传播链。
4. **不得直接将责任模块定位为 IPC 模块**，必须追踪到实际责任实现；对端系统服务内部的锁、队列、线程池或接口实现缺陷可以定界为系统侧根因。

---

### Step 6 — IPC 对端堆栈分析
结合 Step 5 确定的对端进程，进一步分析其堆栈，明确对端阻塞的具体原因（非 IPC 框架本身），并以最终阻塞实现所在进程/模块判定责任领域。若调用方只是正常使用公开接口，而对端系统服务因内部锁竞争、死锁、线程池耗尽或无超时保护而阻塞，则定界为系统侧根因。

---

### Step 7 — Trace 信息分析（如有）
若日志包含 trace 数据，结合 trace 分析业务场景或具体调用接口，辅助定位根因。

---

### Step 8 — 热点函数采样分析（如有）

概览中 `attachments` 为“有”且需要采样栈或其他 faultlog 路径时，先执行：

```bash
   python "<skill-root>/scripts/freeze/main.py" -p "<file_path>" --section attachments
```

每一次Snapshot堆栈是一次的采样（最多采样10次），我们统计函数的次数的时候一次采样堆栈里面就算出现多次，也只统计为一次。请对采样栈通过下面的脚本进行分析：

**调用独立采样栈分析脚本**：

```bash
   python "<skill-root>/scripts/sample_stack_analyzer.py" "<cpuinfo-ext、sample_stacks或含内嵌Snapshot的faultlog路径>"
```

分析时自动发现并解析配套 appfreeze/sysfreeze，无需额外命令或参数。搜索采样文件所在目录及其子目录、父目录中直接存放的 appfreeze/sysfreeze 文件，以及同级 `faultlogger` / `faultlog` / `faultlogs` 目录，支持 `freeze_ext` 与 `faultlogger` 分目录导出。发现后先关联事件、对齐符号，再进行聚类；报告保留原始帧及来源路径/行号，结构化分析结果保留逐采样完整证据。

HiAppEvent 的 APP_FREEZE 附件可在同一文件末尾包含 `#ThreadInfos` 与 `SnapshotTime` / `Timestamp`。入口会将该文件同时列为 faultlog 和采样来源；按附件提示直接分析完整原文件，不要求用户另提供 cpuinfo 或手动拆栈。符号对齐从 `FREEZE_EXT_INFO`（无此标记时使用采样统计头）读取采样 TID、时间区间，进程身份可由外层故障头补充，不能把正文中的 `Tid:数字, Name:...` 当成采样头。仍须检查身份、时间和符号匹配条件；同一文件不豁免校验。

**采样区段边界与提交来源**：每次 Snapshot 遇到 `SubmitterStacktrace` 标题（包括 `========SubmitterStacktrace========`）时结束当前执行栈，将后续提交者帧单独保存在该 Snapshot 的 `submitter_frames` 中，保留原文、来源路径及行号。两类栈遇到下一线程头（`Tid:` / `#ThreadInfos`）、快照结束标记（`SnapshotEnd` / `EndSnapshot`）或下一区段标题时均停止读取；下一条 `SnapshotTime` / `Timestamp` 继续解析下一次采样。独立与内嵌采样均适用，不得在第一次遇到提交者标题时终止整个采样文件。提交者栈只在报告的“异步任务来源”区段展示，不参与当前执行栈的符号对齐、热点、完整栈聚类或根因占比；不得把提交来源函数当成目标线程当时执行的函数。

- **先关联事件**：核对进程名、UID、目标 TID（采样提供 PID 时也核对 PID），采样 StartTime–EndTime 必须与 faultlog 的 Fault time 区间交叠；秒精度 Fault time 按所在秒处理。有 cpuinfo 头部 TimeStamp 时，还要求与 faultlog 头部 TIMESTAMP 相差不超过 1 秒。文件名仅辅助恢复身份，不能用导出时间代替事件时间。缺少关键身份/时间或匹配到多个不同事件时不补符号，并输出原因。
- **精确对齐**：只使用关联事件进程的 warning/block 线程栈，按完整模块路径 + BuildID + 规范化十六进制 PC 精确匹配，不按 SO basename、邻近 PC 或函数范围猜测。来源唯一一致时补齐裸地址帧，或校正 cpuinfo 已有但不同的符号；来源相互冲突时保留原符号并报告 conflict。此流程不解析 minidebuginfo。
- **保留证据再聚类**：原始日志、原始帧和原始符号不变，补充符号另存并附来源。`stack_clusters` 按对齐后的完整调用栈聚类（包含系统帧、保留帧序和递归，每次 Snapshot 计一次）；业务父节点统计也使用对齐后的帧。未解析帧保留 PC，避免将同库不同地址合并。不能把补齐的符号写成 cpuinfo 原始日志已包含的内容。

重点关注业务函数分布情况，分析时给出日志实际包含或经匹配符号文件解析得到的完整函数名称、文件位置、行号和列号，缺失时明确标注不可用。如果业务统计为空，仍可查看完整栈聚类和逐采样帧。此时需要直接阅读采样栈，
若出现栈顶(#00 #01)在pthread_condition_wait上的紧接(#02)着libark_jsruntime.so，可以认为虚拟机在GC，若没有，再去阅读faultlog，判断目前整体的状态是什么。

---

### Step 9 — 综合结论输出

综合以上所有步骤信息。故障类型在现有故障模式库覆盖范围内时匹配三级根因，再输出完整分析报告。

`BUSSINESS_THREAD_BLOCK_6S` / `BUSINESS_THREAD_BLOCK_6S` 当前不纳入故障模式库，不新增或套用三级根因；直接基于事件 TID 对应业务线程的日志证据输出诊断结论。

#### 9a. 故障模式库匹配（故障类型命中时执行）

> 📖 读取 `references/fault-mode-library.md`，按以下顺序逐级匹配：
> 1. **一级**：判断故障大类（当前库覆盖：主线程卡死超时 FML-001、用户输入处理超时；其中主线程阻塞下含「阻塞 IO 操作」「FFRT 同步等待阻塞」「libuv EventLoop 阻塞」三级条目，命中时须分别引用 `references/io-blocking-analysis.md` / `references/ffrt-freeze-analysis.md` / `references/libuv-freeze-analysis.md` 给出细分场景）
> 2. **二级**：命中 Step 2 的明确整机异常时沿用整机异常结论；否则沿用 Step 4b 对同一目标 TID 的完整调用链、有效等待/执行函数及任务进展作出的"阻塞 / 繁忙 / 无法判定"结论，不重新按栈顶是否一致分类。知识库中旧的栈顶比较条件不得覆盖 Step 4b 的综合判定。
> 3. **三级**：仅在二级分类已有充分证据时，按对应分类的判定规则匹配唯一条目；优先精确匹配，无匹配时使用该分类允许的兜底条目。Step 4b 判为"无法判定"时，保留已知证据和缺失信息，不强行套用阻塞/繁忙三级根因或兜底条目。
>    - **繁忙类无采样栈默认匹配**：二级根因为"繁忙"时，所有三级根因均依赖采样栈占比（>30%）判定。当无采样栈或采样栈不可用时，所有繁忙类三级根因无法匹配，默认匹配"执行耗时操作"。

匹配完成后，在报告中以表格形式呈现三级根因定位结果（见输出模板）。

#### 9b. 输出内容要求
1. **三级根因匹配表**（仅在故障类型命中故障模式库时输出）
2. **证据链**（每条结论须附原始日志片段，严禁编造，若涉及调用链，注意调用链顺序从栈底到栈顶；CPU相关原始日志必须脱敏频点，只保留Usage数值）
3. **根本原因**（详细描述触发路径）
4. **根因模块**（具体模块名）
5. **责任领域**（应用 / 系统 / 混合 / 未定，并给出定界依据）
6. **修复建议**（无需输出验证步骤；严格面向已判定的责任领域。系统侧根因只给系统侧代码/架构修改，应用侧根因只给应用侧修改，源码可达时必须给出源码级修复建议，混合责任分开输出，未定时不强行给修改方案）

#### 修复建议质量门禁

- 每条建议必须直接对应已确认的根因函数、锁、队列、任务或接口契约，并说明要修改的对象与动作。
- 禁止输出“优化代码”“检查日志”“增加重试”“提高超时时间”“重启/重装/清缓存”等无证据或仅掩盖故障的通用建议。
- 禁止把采样栈补充、复现、抓 trace、符号化等诊断动作写成修复建议；证据不足时只能列为“待补充证据”。
- 责任未定或状态判定为“无法判定”时，不得生成代码修复建议，也不得为了填满模板编造第二条建议。
- 建议数量由有效根因决定；只有一项有效修改时只写一项，不得泛化增加字段或凑数。

---

## 输出格式模板

所有报告统一使用 Markdown 格式输出。

````markdown
# 冻屏问题综合分析报告

## 故障基本信息

| 项目 | 内容 |
|------|------|
| 故障时间 | <从日志提取> |
| 故障进程 | <PID / 进程名> |
| 故障类型 | <APPFREEZE / APP_INPUT_BLOCK / ...> |
| 故障原因描述 | <日志中的原始描述> |

## 根因分析

- **诊断结果**：<一句话概括根因，当日志栈帧含应用源码路径时必须在诊断句中直接标注源码文件:行号>
- **可信度**：HIGH / MEDIUM / LOW
- **线程状态**：<阻塞 / 繁忙 / 无法判定，依据完整调用链与等待特征综合判断>

## 三级根因定位（依据故障模式库）

| 层级 | 根因 | 匹配依据 |
|------|------|----------|
| 一级根因 | <主线程卡死超时 / 用户输入处理超时> | <原始日志片段> |
| 二级根因 | <主线程阻塞/繁忙/系统负载> | <原始日志片段> |
| 三级根因 | <具体三级根因名称> | <原始日志片段> |

## 证据链

### 1. 故障类型与目标线程路由
<故障类型、目标线程 TID/Name 确认>
原始日志：
<直接从 faultlog 中摘取的原始日志片段>

### 2. 整机状态排除（无整机异常时简述）
<设备内存、CPU、温度评估；有整机异常时详述并提前终止>
原始日志：
<直接从 faultlog 中摘取的原始日志片段>

### 3. 时间差异性校验
<故障时间→抓栈时间→上报时间，判断堆栈可信度>
原始日志：
<直接从 faultlog 中摘取的原始日志片段>

### 4. EventHandler 任务队列分析（如有）
<Current Running / History Event Queue 执行时间计算，判断是否 >3s>
原始日志：
<直接从 faultlog 中摘取的原始日志片段>

### 5. 故障目标线程堆栈分析（逐帧解读）

<调用栈全帧或关键帧展示，每帧添加行内注释>
#00 ... stub.an(BCStub_HandleCallRuntime...)  ← 字节码桩，语义解读
#01 ... 应用源码帧                              ← 应用业务代码
#02 ... 应用源码帧                              ← 应用业务代码
#03 ... libark_jsruntime.so(JSFunction::Call)  ← JS运行时调用
```

**逐帧解读：**
- `#00` <模块名>（<函数名>）：<解读>
- `#01`-`#02` <应用源码帧>：<解读>
- ...

<排除结论：主线程不在 pthread_mutex（非等锁）、不在 BinderInvoker::WaitForCompletion（非 Binder 阻塞）、不在同步 IO/文件系统元数据操作、不在 libffrt.so（非 FFRT）、不在 libuv.so（非 libuv）、不在 FullGC（非 GC）、不在 DumpHeapSnapshot（非 Dump）。未命中具体阻塞模式，默认匹配"执行耗时操作"。>

### 6. 排除同步 I/O / FFRT / libuv / Binder / 等锁（专项排除）

<主线程栈无同步 I/O/文件系统元数据操作、libffrt.so、libuv.so、pthread_mutex、BinderInvoker::WaitForCompletion；BinderCatcher 显示本进程未满，非 IPC FULL。>

原始日志：
<BinderCatcher 相关片段>

### 7. 其他线程分析（如有）

| TID | 线程名 | 栈顶 | 状态 |
|-----|--------|------|------|
| <TID> | <线程名> | <栈顶符号> | <空闲/阻塞/...> |

<结论：其他线程均为空闲等待状态，无持锁线程，无跨线程阻塞依赖。>

### 8. 符号解析结果及源码定位（源码可达时输出）
<符号解析结果及源码定位根因分析>

## 采样栈热点函数分析
| 业务函数 | 出现次数 | 累计耗时(ms) | 说明 |
|----------|----------|--------------|------|
<无采样栈时写"本 faultlog 未包含采样栈区段，无热点函数统计">

## 根本原因
<结合证据链详细说明导致冻屏的直接原因及其完整触发路径。当栈顶为字节码桩时，需结合字节码语义判断应用代码执行状态（如循环式活跃执行）。>

## 根因模块
- **模块名称**：<例如：com.example.app（应用业务代码 entry/src/main/ets/xxx.ts:行:列）/ libxxx.z.so / xxx_service。当日志栈帧含应用源码路径和行列号时，模块名必须附带源码文件:行:列>
- **责任领域**：<应用 / 系统 / 混合 / 未定>
- **定界依据**：<根因实现、调用契约与代码归属证据；不能只看路径>

## 修复建议
### `<简明标题>`<源码可达时>

**文件**：`<文件路径>`

**修改 1** — 第 `<行号>` 行（`<该修改的目的>`）
```diff
- <删除的代码>
+ <新增的代码>
<不变的代码（上下文）>
```

**修改 2** — 第 `<行号>` 行（`<该修改的目的>`）
```diff
- <删除的代码>
+ <新增的代码>
<不变的代码（上下文）>
```

**修改3...**

> **修复说明**：：`<修复原理以及影响范围>`


### `<简明标题>`<源码不可达时>
<基于根因类型的通用方向 + ArkTS 模板代码>

**建议1:**
```typescript
// 通用 ArkTS 修复模板
```
**修复说明**：：`<简要修复原理>`

**建议2:**
```typescript
// 通用 ArkTS 修复模板
```
**修复说明**：：`<简要修复原理>`

**建议3:**...
````
