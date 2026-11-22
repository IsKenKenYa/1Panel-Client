---
name: hmos-cppcrash-analysis
description: >-
  DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 CppCrash（Native 层崩溃）日志，
  基于信号、寄存器、Native 调用栈、符号和内存证据定位根因并给出修复建议。
  当输入包含 cppcrash、NativeCrash、Reason:Signal、Fault thread info、Registers、
  Memory near registers、Native .so 调用栈、SIGSEGV/SIGABRT/SIGILL/SIGBUS/SIGFPE，
  或 GWP-ASan 报告时使用。若用户只说“应用崩溃/闪退”但没有 JS 或 Native 证据，
  先识别日志类型；仅在确认是 Native Crash 后使用本技能。
metadata:
   author: Huawei Reliability Technology Lab
   version: 1.4.0
---

# CppCrash 故障分析技能

## 核心原则

1. 先提取事实，再匹配故障模式；不得用单个栈帧直接推导深层根因。
2. 关键日志报告用于导航，原始日志仍是证据源。提取结果缺失字段时必须回读原始日志。
3. 区分崩溃点、首个非运行时调用方和首个应用侧帧，不把系统运行时帧直接当作业务根因。
4. `.so` 路径只能辅助判断代码归属，不能单独证明责任归属。
5. 区分第一现场和延迟崩溃。GC、allocator、容器或运行时栈可能只是内存破坏后的触发点。
6. 使用证据等级：检测器明确报告 > 指令/寄存器联合证据 > 多项栈特征 > 单一模块特征。
7. 修复建议必须与根因责任领域一致：系统侧根因只给系统侧修改，应用侧根因只给应用侧修改；不得用应用规避方案替代系统缺陷修复。
8. 任何时候都不得要求应用提供或反解系统栈；只能要求反解离崩溃点最近的应用侧栈帧。

## 分析流程

### 步骤零：环境与输入检查

1. 确认 Python 3.8 或更高版本可用：

   ```bash
   python --version
   ```

   Windows 中没有 `python` 命令时尝试 `py -3`。脚本只使用 Python 标准库，无需安装第三方依赖。

2. 将包含本文件的目录记为 `<skill-root>`。调用脚本时使用完整路径，不依赖当前工作目录：

   ```bash
   python "<skill-root>/scripts/main.py" -p "<cppcrash文件或目录>"
   ```

3. 用户要求分析目录内全部日志时增加 `--all`：

   ```bash
   python "<skill-root>/scripts/main.py" -p "<日志目录>" --all
   ```

4. 检查输入是否存在、是否可读。若脚本未识别日志，直接检查原始文件中的 `Reason:`、
   `Fault thread info:`、`Reason:GWP-ASAN` 和 `*** GWP-ASan detected a memory error ***`。

5. 日志类型校验：脚本在收集阶段自动识别 CppCrash FaultLog——文件名以 `cppcrash-` 开头，
   或内容含 `Reason:Signal:` / `Reason:GWP-ASAN` / `*** GWP-ASan detected a memory error ***`。
   不符合上述特征的日志不在本技能范围。
   若脚本提示"未在 ... 中找到 cppcrash 日志"，停止分析并提示用户：
   "该日志不是 CppCrash 故障日志，无法使用本技能分析。请提供 Native 层崩溃（CppCrash）的 FaultLog。"

6. 堆栈信息校验：脚本在解析后检查日志是否含可分析的调用栈——`Fault thread info:` 区段下
   `#NN pc` 格式帧，或 GWP-ASan 报告中的 `#N 0xADDR` 格式帧。两者皆无时停止分析并提示用户：
   "该 CppCrash 日志缺少 Native 调用栈信息，无法定位根因。请提供包含完整调用栈的 FaultLog。"

### 步骤一：提取关键日志

完整阅读脚本输出，并在以下情况回读原始日志：

- 报告提示字段或调用栈缺失。
- 需要其他线程完整调用栈、完整 Maps、HiLog 或 GWP-ASan 三段调用栈。
- 日志包含多个故障事件或拼接内容。
- 结论依赖未被提取的上下文。

目录输入默认分析按日志时间或文件修改时间确定的最新一份日志；批量分析必须使用 `--all`。

### 步骤二：选择分析分支

#### GWP-ASan 分支

用户描述或日志内容包含以下任一特征时，读取 `references/gwp_asan.md`：

- `gwpasen`、`gwpasan`、`GWP-ASan` 或 `GWP-ASAN`
- `Reason:GWP-ASAN`
- `*** GWP-ASan detected a memory error ***`

必须保留并分析违规访问、释放和申请调用栈。普通 CppCrash 不加载该 reference。

#### 普通 Native Crash 分支

读取 `references/fault_mode.md`，从 `Reason` 中提取信号、`si_code` 和故障地址：

| 信号 | 基础语义 | 首要分析方向 |
|------|----------|--------------|
| `SIGSEGV(SEGV_MAPERR)` | 地址未映射 | 空基址偏移、悬空指针、越界地址 |
| `SIGSEGV(SEGV_ACCERR)` | 映射权限不允许当前访问 | 写只读页、执行不可执行页、映射状态变化 |
| `SIGILL` | CPU 执行了非法或不受支持的指令 | 指令损坏、错误跳转、ISA/PAC/CFI 问题 |
| `SIGBUS` | 对齐、映射文件或硬件访问异常 | 对齐、mmap 文件变化、对象访问错误 |
| `SIGABRT` | 进程主动终止 | LastFatalMessage（保留原始信息，根据信息提示定位崩溃原因）、assert、未捕获异常、检测器报告 |
| `SIGFPE` | 算术异常 | 除零、溢出或无效算术操作 |

信号只描述故障机制，不等于代码根因。

### 步骤三：按需加载知识库

只读取与关键日志匹配的 reference。允许命中多项，但不要读取无关文件。

| 日志特征 | 读取 reference |
|----------|----------------|
| `libace_compatible`、`libace_ndk`、`OHOS::Ace`、XComponent、UI 节点 | `references/arkui.md` |
| `libnative_rdb`、`libsqlite`、`libnative_appdatafwk`、`librelationalstore` | `references/arkdata.md` |
| ArkWeb、WebView、`libarkweb_engine`、crashpad、Web GPU | `references/arkweb.md` |
| `libark_jsruntime`、`libace_napi`、N-API、JS GC/OOM、`LoadJSPandaFile`、`load hsp failed`、`Crash occured on ProcessAll` | `references/jsruntime.md` |
| `RenderService`、`OHOS::Rosen`、NativeWindow、BufferQueue | `references/render_service.md` |
| `libv8_shared`、`libjsvm`、`OH_JSVM_*`、`DestroyEnv`、`HandleScope`、`openHandleScopes`、JSVM Fatal Error | `references/jsvm.md` |
| `librosen_text`、FontCollection、Paragraph 文本对象 | `references/rosen_text.md` |
| allocator/CFI/PAC/StackProtector/代码段异常等内存破坏特征 | `references/memory_corruption.md` |
| `edata_heap_remove`、`emap_update_edata_state`；或故障地址以 `0x006b` / `0x6b6b` 开头且 `#00` 为 `/system/lib64/` 系统栈 | `references/memory_corruption_second_scene.md` |

满足以下四类表现之一时额外读取 `references/multithreading.md`：

1. 日志包含 `CheckThread` 和 `ecma_vm cannot run in multi-thread`。
2. 主线程或工作线程栈同时包含业务/组件代码与 N-API、JS Runtime 或 JS 绑定调用，且故障地址为
   NULL 小偏移、连续可打印 ASCII 字符型地址或其他疑似对象损坏地址。
3. `OS_GC_Thread` 的栈只有 GC 帧，并在 `ConcurrentMarker`、`NonMovableMarker` 或
   `ProcessMarkStack` 等标记阶段访问非法地址。
4. `OS_GC_Thread` 的栈只有 GC 帧，并在 `EvacuateObject`、`FullGCRunner` 或
   `CompressGCMarker` 等搬迁阶段出现 `unreachable type` 或非法对象类型。

第 1 类是跨线程使用 `env` 的第一现场。第 2 至第 4 类通常是 JS 对象被破坏后的延迟崩溃；
优先排查跨线程 `env`，但需结合线程归属、N-API 路径或检测结果确定最终可信度。

reference 发生冲突时，以证据等级更高的规则为准。模块栈模式不得覆盖检测器报告或明确的寄存器/指令证据。

命中 `references/memory_corruption_second_scene.md` 时，只能将当前崩溃栈定界为踩内存的第2现场。
`#00` 系统模块是损坏内存的访问方或检测点，不能据此直接认定为非法踩写源；缺少第一现场证据时，
必须明确说明踩写模块尚未定位。

### 步骤四：建立证据链

#### 1. 信号、地址和寄存器

- `fault_addr` 接近 0 只表示疑似空基址加成员偏移，需结合实际访存指令、基址寄存器及
  N-API/线程归属证据判断是否为跨线程破坏后的延迟表现。
- `fault_addr` 按字节解析后包含连续可打印 ASCII 或 UTF-16 字符时，说明指针或对象字段可能被字符数据覆盖；
  这是内存破坏证据，不能脱离线程与调用链单独确认跨线程根因。
- 随机地址、allocator、GC 或容器栈只能作为内存破坏候选，除非有检测器或联合证据。
- 从 PC 附近指令确定读写方向、参与计算的寄存器和实际访问地址。
- Maps 区间采用左闭右开语义：`start <= address < end`。
- **寄存器深度分析要求**：
  - **x0/this 指针分析**：若崩溃函数为成员函数或析构函数，必须分析 x0 是否为合法堆地址。若 x0 合法但 fault_addr 非法，说明对象本体正常而成员指针被破坏，需进一步定位被破坏的成员字段。
  - **fault_addr 与相邻寄存器高位对比**：当 fault_addr 包含字符串数据时，必须将其与 x1-x15 中值相近的寄存器做高位对比。若高位相同仅低位不同，说明它们是从被破坏内存中加载的相邻指针字段，可据此推断对象内存布局和破坏范围。
  - **字符串解码**：对包含可打印字节的寄存器值（fault_addr 及其他寄存器），必须按小端字节序解码为 ASCII 或 UTF-16LE 字符串，识别覆盖源（如 "OHOS" 命名空间字符串、日志格式化字符串等），为定位踩写第一现场提供线索。
  - **填充模式识别**：x13 等寄存器中出现 `0xaaaaaaaa`、`0x6b6b`、`0xdddddddd` 等已知填充值时，必须识别其含义（jemalloc 释放/未初始化填充、释放后内存标记等）并作为内存破坏佐证。
  - **多项独立证据交叉验证**：当 fault_addr 字符串解码、相邻寄存器同源、填充模式等多类证据同时指向内存破坏时，可信度应判定为 HIGH。

#### 2. 调用栈分层

按以下层级分别记录，不得混为一个“业务首帧”：

| 层级 | 含义 |
|------|------|
| 崩溃帧 | `#00`，进程最终触发信号的位置 |
| 首个非运行时调用方 | 跳过 libc、abort、Ark Runtime、N-API 桥接层后的第一个调用模块 |
| 首个应用侧帧 | 路径或构建信息能够确认属于应用产物的第一帧 |

没有应用帧时不得伪造应用责任模块。系统栈也可能由错误入参、生命周期或回调契约触发。

#### 3. 责任领域与修复建议对齐

输出修复建议前，必须依据第一现场、违规访问/释放/申请栈、调用契约、寄存器/指令和源码证据，将责任领域判定为：应用、系统、混合或未定。

- **系统侧根因**：证据链确认缺陷位于系统服务、系统框架、系统库或系统 API 实现时，只输出对应系统模块的代码/架构修改，例如空值与边界修复、对象生命周期和并发修复、锁序调整、接口契约修正。不得要求应用修改调用方式、增加兜底或规避系统缺陷来充当根因修复。
- **应用侧根因**：证据链确认应用错误入参、生命周期、越界、跨线程或接口误用时，只输出应用侧修改。
- **混合责任**：双方都有直接缺陷时分栏输出，先写主要责任方；应用侧临时规避必须明确标注，不能替代系统侧修复。
- **责任未定**：只有系统栈、只有应用调用入口或当前仅为踩内存第2现场时，不强行给跨责任域修改方案；输出继续定界所需的符号、第一现场、源码或检测器证据。
- **内存破坏通用定界规则**：当 fault_addr 或寄存器值包含字符串数据、填充模式等内存破坏证据时，崩溃模块（`#00` 所在 so）是损坏内存的**访问方**而非**踩写源**。除非有检测器报告（GWP-ASan）或第一现场证据，否则责任领域判定为**未定**，不得因全栈为系统库或全栈为应用库而直接定界。在报告中必须明确区分"崩溃访问现场"与"踩写源第一现场"，并说明踩写源尚未定位。

`.so` 路径仅用于代码归属辅助，责任结论仍须由根因证据决定。根因位于系统侧时，即使故障进程是三方应用，也必须给系统侧修改建议。

#### 4. 符号化、反汇编和源码

仅在材料齐全时执行，不得将其写成无条件必选步骤：

**源码可达性检测（符号解析前必须执行）**：
- 在当前工作目录（及父目录）中查找以下标志文件：`build-profile.json5`、`oh-package.json5`、`AppScope/app.json5`。
- 若找到，读取 `AppScope/app.json5` 中的 `bundleName` 字段，与 faultlog 中的故障进程名（`Process name` 或 `Module name`）对比，若一致即源码可达；若不一致即源码不可达，跳过后续符号解析流程，在报告中标注"源码不可达，行号定位未执行"。
- 若未找到上述标志文件，视为源码不可达，同样跳过符号解析。

**SO 文件校验（源码可达时执行，地址解析前必须执行）**：
从 faultlog 栈帧中提取应用 SO 文件名和 BuildID，校验源码工程目录下同名 .so 是否为同一编译产物：
```bash
python "<skill-root>/scripts/match_so.py" <so_name> <build_id> -d <search_dir>
```
- 退出码 0（stdout 输出匹配路径）→ 用该路径执行下方地址解析
- 退出码非 0 → 跳过地址解析，在报告中标注"未找到与 faultlog 版本匹配的 SO 文件，行号定位不可用"

**地址解析与反汇编**（仅在 SO 文件校验通过时执行）：
`ohos_llvm_tools.py` 根据环境变量（`DEVECO_HOME` / `DEVECO_SDK_HOME` / `OHOS_SDK`）自动定位 `llvm-addr2line` 与 `llvm-objdump`；未找到时按报错提示设置上述任一环境变量或把工具加入系统 `PATH`。

1. 找到离崩溃点最近的应用侧帧，并具备与故障版本 BuildID 匹配的应用 `.so` 后运行：

   ```bash
   python "<skill-root>/scripts/ohos_llvm_tools.py" addr2line "<应用so文件>" "<pc相对偏移>"
   ```

2. 行号仍不足以判断多参数调用、虚表、函数指针或访存寄存器时运行：

   ```bash
   python "<skill-root>/scripts/ohos_llvm_tools.py" objdump "<so文件>" [输出目录]
   ```

3. 用户提供源码后，结合行号上下文检查空值、边界、所有权、线程和回调时序。
4. **源码级修复建议要求**：当符号解析已定位到源码行号且用户提供了对应源码时，【修复建议】必须给出源码级修复建议——具体到文件:行号、函数名和修改方案，不得仅停留在模块级或泛化描述。
5. 缺少符号、二进制或源码时明确列为缺失信息，不猜测函数行号或代码实现。
6. **SO 文件不可用或源码不可达时**：跳过地址解析，在报告中标注缺失信息，不猜测函数行号或代码实现。
7. `/system`、`/vendor`、`/chipset` 等系统栈只作为调用路径证据，不得要求应用提供系统符号或执行系统栈反解。没有应用帧时明确写"未找到可由应用反解的栈帧"，继续依据第一现场和系统侧证据定界。

#### 5. 符号表反解状态门禁

输出修复建议前必须判断关键责任候选栈帧是否已完成符号表反解：

- 用户明确说明已使用与故障版本 BuildID 匹配的符号文件，且提供了关键责任候选帧的函数名或源码行，才视为已反解。
- 用户未说明反解过程、未核对 BuildID，或关键责任候选帧仍仅有裸地址、`<so>+offset` 或 `unknown`，均视为未反解。
- 应用侧根因或应用侧责任候选未反解时，【修复建议】或【下一步建议】的第 1 项只要求反解离崩溃点最近的应用帧，并提供匹配 BuildID 的应用 `.so`/符号。
- 系统侧根因、只有系统栈或未找到应用帧时，不得要求应用提供或反解系统符号；在证据不足时仅说明缺少系统侧内部定界证据，不把它转化为应用动作。
- 责任未定时，只对已出现的最近应用帧提出反解要求；在反解完成前只给定界建议，不猜测具体代码修改。
- 上述要求适用于常规 CppCrash、踩内存第2现场和 GWP-ASan 场景；不得只在“是否需要进一步分析”中勾选符号文件核对而省略必要的责任模块符号化建议。

#### 6. HiLog

日志含 `HiLog:` 且需要还原崩溃前业务时运行：

```bash
python "<skill-root>/scripts/extract_hilog.py" "<faultlog文件>"
```

HiLog 仅作触发路径和时序辅助证据，不能单独作为根因。

---

## 输出格式要求

读取参考文件：`references/fault_mode.md`

根据分析结果严格选择一个模板，不得混用：

- 命中 `references/memory_corruption_second_scene.md` 时，只能使用“模板B：踩内存场景”。
- 其他 CppCrash 场景使用“模板A：常规CppCrash场景”。
- 所有模板中的【修复建议】必须服从“责任领域与修复建议对齐”规则；reference 中的场景示例不得覆盖该规则。
- 所有报告统一使用 Markdown 格式输出。
- 符号解析已定位到源码行号且用户提供了对应源码时，【修复建议】必须给出源码级修复建议（具体到文件:行号、函数名和修改方案）。
- **修复建议 diff 展示**：涉及代码修改的建议必须使用以 `diff` 为语言标记的围栏代码块（```` ```diff ````），代码块内只展示增删的行：行首 `-` 为删除行、`+` 为新增行；不展示 `---`/`+++` 文件头、`@@` 行号标注与上下文行。不得改用 `cpp`/`text` 等语言标记。未反解或源码不可达、无法落到具体代码行时，用普通文字描述修改方向，不得编造无法确认的源码 diff。
- 日志中存在 `LastFatalMessage` 字段时，必须完整保留原始信息输出，并提示开发者根据其中的信息定位崩溃原因。
- **模板判定说明**：报告中必须说明选择模板 A 或模板 B 的判定依据（是否命中 `memory_corruption_second_scene.md` 的条件）。
- **多假设保留**：当证据指向内存破坏但第一现场（踩写源）尚未定位时，【根本原因】的深层原因必须列举多种可能（如生命周期管理缺陷、相邻内存越界写、Use-After-Free），不得仅给出单一结论。
- **可信度判定指引**：当多项独立证据（如 fault_addr 字符串解码、相邻寄存器同源、填充模式、调用栈语义）交叉验证同一结论时，可信度判定为 HIGH；仅有单一证据或证据间接时为 MEDIUM。

### 模板A：常规CppCrash场景

```markdown
# CppCrash 问题综合分析报告

## 故障基本信息

- **故障时间**：<从日志提取，如 2025-04-20 10:23:45.678>
- **故障进程**：<PID / 进程名 / UID>
- **故障类型**：CPP_CRASH (NativeCrash)
- **信号类型**：<signo=SIGXXX, code=XXX_YYY>
- **崩溃地址**：<fault addr，如 0x0000000000000010>
- **崩溃函数**：<调用栈 #00 帧，如 libxxx.so!Foo::Bar(int)+0x24>
- **崩溃模块**：<so 路径，如 /data/storage/el1/.../libfoo.z.so>
- **故障原因描述**：<日志中的原始 Reason 字段>
- **LastFatalMessage**：<日志中的原始 LastFatalMessage 字段；无则写"无">

  > 请保留 LastFatalMessage 原始信息，根据其中的信息提示定位崩溃原因。

## 根因分析

- **诊断结果**：<一句话概括根因，如："空指针解引用——this 指针为 nullptr 时调用虚函数">
- **故障类别**：<空指针 / UAF / 栈溢出 / 数据竞争 / 越界访问 / 死锁 / 除零 / 对齐错误 / ...>
- **可信度**：HIGH / MEDIUM / LOW

## 三级根因定位（依据 CPP_CRASH 故障模式库）

> 模板判定：本故障 <命中/未命中> `memory_corruption_second_scene.md`（<说明判定依据，如：fault_addr 不以 0x006b/0x6b6b 开头、调用栈不含 edata_heap_remove 等>），使用模板 A。

> 根因编码规则：`1.1.1.<信号编号>.<si_code编号>`，信号编号按 POSIX 常量值（SIGSEGV=11, SIGABRT=6, SIGBUS=7, SIGILL=4, SIGFPE=8, SIGSYS=31），si_code 编号按 `si_code` 枚举值（SEGV_MAPERR=1, SEGV_ACCERR=2, BUS_ADRALN=1, BUS_OBJERR=3 等），详见 `references/fault_mode.md`。

| 层级 | 根因 | 匹配依据 |
|------|------|----------|
| 一级根因 | CPP_CRASH | <name_=CPP_CRASH 原始日志片段> |
| 二级根因 | <信号名称，如 SIGSEGV> (1.1.1.<信号编号>.0) | <signo=XXX 原始日志片段> |
| 三级根因 | <si_code 名称，如 SEGV_MAPERR> (1.1.1.<信号编号>.<si_code编号>) | <code=XXX 原始日志片段> |

## 证据链

**1. 信号与子码语义分析**

- 原始日志：
  <Reason / signal 行原始片段>
  `Fault thread info: Tid:<TID>, Name:<线程名>`
- 解读：
  <基于故障模式库对 signo + code 组合的语义说明；说明 fault_addr 是接近 0（空指针+偏移）、合法地址（权限错误）还是随机值/包含字符串数据（野指针/UAF/内存破坏）>

**2. 寄存器与故障地址分析**

- 原始日志：
  <x0-x30 / pc / lr / sp 等关键寄存器原始片段>
- 解读：
  - **x0/this 指针**：<是否为合法堆地址；若合法但 fault_addr 非法，说明成员指针被破坏>
  - **fault_addr 与相邻寄存器高位对比**：<如 fault_addr 与 x9 高位相同仅低位不同，说明从被破坏内存加载的相邻字段>
  - **字符串解码**：<fault_addr 及其他寄存器值按小端字节序解码为 ASCII/UTF-16LE 字符串，识别覆盖源>
  - **填充模式识别**：<如 x13=0xaaaaaaaa 为 jemalloc 释放/未初始化填充>
  - <综合判断：多项独立证据交叉验证时标注可信度>

**3. 调用栈关键帧**

- 原始日志：
  ```
  #00 pc 000xxxxx  /data/.../libfoo.z.so   (Foo::Bar(int)+0x24)
  #01 pc 000xxxxx  /data/.../libfoo.z.so   (Foo::Run()+0x80)
  #02 pc 000xxxxx  /system/lib64/libxxx.so (...)
  ```
- 解读：
  - **崩溃帧**：#00 <模块名>（<系统/应用>）
  - **首个非运行时调用方**：<跳过 libc/abort/Ark Runtime 后的第一帧>
  - **首个应用侧帧**：<路径属于应用产物的第一帧；无则写"无（全栈为系统模块）">
  - **调用链语义**：<从栈底到栈顶的完整调用语义>

**4. 源码行号与 BuildID（如符号可用）**

- 源码行号：<file:line 定位，如 foo.cpp:123；未反解时写"未反解">
- 关键帧 BuildID（未反解时必须列出，供后续符号反解）：
  - <so 名称>: <BuildID>
  - <so 名称>: <BuildID>

**5. Memory Near / Maps 辅助证据（如有）**

- <如 fault_addr 附近内存映射、堆/栈 /匿名页归属>

## 根本原因

- **直接原因**：<导致崩溃的直接代码/数据问题，如："Obj 析构后仍被持有的裸指针在 2 号线程继续调用 Release()">
- **深层原因**：<设计/契约/流程层面的深层原因。当证据指向内存破坏但第一现场（踩写源）尚未定位时，必须列举多种可能，如：(1) 生命周期管理缺陷 (2) 相邻内存越界写 (3) Use-After-Free，不得仅给出单一结论>
- **触发路径**：<从触发点到崩溃点的完整调用链>

## 根因模块

- **责任领域**：<应用 / 系统 / 未定>
  - 当证据指向内存破坏且第一现场未定位时，责任领域为**未定**，并说明崩溃模块是损坏内存的访问方而非踩写源
- **责任模块**：<so 路径 + 具体函数，如：/data/storage/el1/.../libfoo.z.so ! Foo::Bar(int)+0x24>
- **定界依据**：
  1. 基于故障根本原因定界：<说明根因是应用使用不当 / 系统 API 缺陷 / 内存破坏访问现场，踩写源未定位 / ...>
  2. so 路径归属：<如 /data 开头 → 应用侧；/system 开头 → 系统侧；全栈系统库但属内存破坏访问现场时不得直接定界>
  3. 死锁场景补充：<若为死锁，标注持锁线程与持锁函数；非死锁时写"非死锁">

## 修复建议（源码可达时需给出源码级修复建议）

1. <按责任领域填写：系统侧根因写对应系统模块的直接代码修复；应用侧根因写应用代码修复；责任模块未反解时先要求该责任模块的匹配符号，并列出关键帧 BuildID；应用侧候选未反解时只要求反解最近的应用帧；不得要求应用反解系统栈>
2. <针对同一责任领域深层原因的架构改进，如生命周期、锁序、边界或接口契约修复>
3. <当证据指向内存破坏但第一现场未定位时，优先建议获取 GWP-ASan 地址越界日志捕获踩写源第一现场：https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-stability-gwpasan-detection >
4. <在责任候选模块可控构建中开启 HWASan 并复现，定位越界写操作源头：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hwasan >
5. <由责任模块实施的防御性改进和回归用例；不得把另一责任域的规避措施写成根因修复>
6. <涉及代码修改的建议，每条修改使用一个 diff 代码块展示（只展示增删行），块前一行说明修改目的与位置，格式必须符合“修复建议 diff 格式示例”>

## 是否需要进一步分析

- [ ] 反汇编分析（pc 附近指令）
- [ ] HWASan / ASan 地址越界检测
- [ ] 符号文件 BuildID 核对
- [ ] Core Dump / Tombstone 深度解析
- [ ] 多次复现对比以排除随机性
```

### 模板B：踩内存场景

**⚠️ 注意：踩内存场景下，【根本原因】和【根因模块】部分字段不适用，无需填写。**
**⚠️ 注意：请不要泛化增加字段。**

严格按照以下结构输出结论：

```markdown
# CppCrash 问题综合分析报告

## 故障基本信息

- **故障时间**：<从日志提取>
- **故障进程**：<PID / 进程名 / UID>
- **故障类型**：CPP_CRASH (NativeCrash)
- **信号类型**：<signo=SIGXXX, code=XXX_YYY>
- **崩溃地址**：<fault addr>
- **崩溃函数**：<调用栈 #00 帧>
- **崩溃模块**：<so 路径>
- **故障原因描述**：<日志中的原始 Reason 字段>
- **LastFatalMessage**：<日志中的原始 LastFatalMessage 字段；无则写"无">

  > 请保留 LastFatalMessage 原始信息，根据其中的信息提示定位崩溃原因。

## 根因分析

- **诊断结果**：<一句话概括根因，如："jemalloc堆元数据被踩写损坏导致崩溃">
- **故障类别**：踩内存第2现场
- **可信度**：HIGH / MEDIUM / LOW

## 三级根因定位（依据 CPP_CRASH 故障模式库）

> 模板判定：命中 `memory_corruption_second_scene.md`，使用模板 B。

> 根因编码规则：`1.1.1.<信号编号>.<si_code编号>`，详见模板 A 说明。

| 层级 | 根因 | 匹配依据 |
|------|------|----------|
| 一级根因 | CPP_CRASH | <name_=CPP_CRASH 原始日志片段> |
| 二级根因 | <信号名称，如 SIGSEGV> (1.1.1.<信号编号>.0) | <signo=XXX 原始日志片段> |
| 三级根因 | <si_code 名称，如 SEGV_MAPERR> (1.1.1.<信号编号>.<si_code编号>) | <code=XXX 原始日志片段> |

## 证据链（⚠️ 仅限以下2项，禁止扩展）

**1. 信号与子码语义分析**

- 原始日志：
  <Reason / Fault thread info / signal 行原始片段>
- 解读：
  <基于故障模式库对 signo + code 组合的语义说明>

**2. 寄存器与故障地址分析**

- 原始日志：
  <x0-x30 / pc / lr / sp 等关键寄存器原始片段>
- 解读：
  <分析寄存器值与崩溃地址的关系>

## 根因模块

- **责任领域**：未定（当前仅为踩内存第2现场）
- **定界依据**：<参考**踩内存第2现场定界专项分析**；不得因 #00 位于 /system 或进程属于应用而提前定责>

## 下一步建议（源码可达时需给出源码级修复建议）

1. <若存在应用帧，提供与最近应用帧匹配 BuildID 的未剥离 .so/符号文件，使用 python "<skill-root>/scripts/ohos_llvm_tools.py" addr2line "<应用so文件>" "<pc相对偏移>" 反解后重新定界；只有系统栈时删除本项，不得要求应用反解系统栈>
2. 获取现网 GWP_ASan 地址越界日志或其他踩内存第1现场日志，依据第一现场确定责任领域后再输出对应侧修复
   链接：https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-stability-gwpasan-detection
3. 在责任候选模块可控构建中开启 HWASan 并复现，分析 HWASan 报告定位越界写操作源头
   链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hwasan
4. <若源码可达且分析后能给出源码级修复建议，每条修改使用一个 diff 代码块展示（只展示增删行），块前一行说明修改目的与位置，格式必须符合“修复建议 diff 格式示例”；踩写源未定位时不得编造源码修改>

## 是否需要进一步分析

- [ ] 符号文件 BuildID 核对
- [ ] 反汇编分析（pc 附近指令）
- [ ] HWASan / ASan 地址越界检测
- [ ] Core Dump / Tombstone 深度解析
```

### 修复建议 diff 格式示例

报告“修复建议”中涉及代码修改的条目按以下形式呈现（内容仅为格式示意，必须替换为基于真实证据的修改，不得照抄）：

**修改 1** — `entry/src/main/cpp/foo.cpp:123`（调用成员函数前判空，防止空指针解引用触发 SIGSEGV）

```diff
-    manager->ProcessEvent(event);
+    if (manager != nullptr) {
+        manager->ProcessEvent(event);
+    }
```