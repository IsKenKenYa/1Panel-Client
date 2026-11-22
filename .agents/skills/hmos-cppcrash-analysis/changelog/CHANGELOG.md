# 更新日志

## [1.4.0] - 2026-09-28

### 新增
- `references/memory_corruption_second_scene.md` 新增 jemalloc 安全检查类踩内存第 2 现场规则：`cache_bin_dalloc_safety_checks`（double free）、`je_arena_dalloc_small`（SIGTRAP=double free / SIGSEGV=踩内存）、`je_tcache_bin_flush_small`（tcache 刷新异常）、`tcache_bin_flush_stashed`（tcache stash 元数据被踩写）、`cache_bin_uaf_safety_check`（UAF）、`tss_get` + `je_free`（TSS 被踩写）。
- `references/memory_corruption_second_scene.md` 新增 raise/crash_brk 变体规则：`#00=raise` 且 `#01` 为 je 安全检查函数判定为 double free；`SIGTRAP(TRAP_BRKPT)` 时栈顶为 je 安全检查函数同样判定为 double free。
- `references/memory_corruption_second_scene.md` 新增 `Signal:DEBUG SIGNAL(JEMALLOC)` + `#01=save_debug_message` 规则：按 je 函数所在流程区分 UAF 与 double free。
- `references/memory_corruption_second_scene.md` 新增「通用判定规则」段：枚举七类栈顶模式，给出「栈顶落在 ld-musl jemalloc 内部符号即视为踩内存第 2 现场」的核心原则与排查方向。
- `references/arkui.md` 新增「九、可以认为是踩内存的堆栈」：栈顶 `libace_compatible.z.so` 连续三帧析构或栈顶为 `~RefPtr()` 时判定为踩内存（成员被踩）。
- `references/arkui.md` 新增「十、可以认为是踩内存的堆栈」：栈顶挂在 `JSPanRecognizer::Destructor` 等 js 绑定 native 对象的 Destructor 回调中时，大概率为踩内存问题。
- `SKILL.md` 输出格式要求新增"修复建议 diff 展示"规则：涉及代码修改的建议必须使用以 `diff` 为语言标记的围栏代码块，只展示增删行。
- `SKILL.md` 模板A【修复建议】新增第 6 项、模板B【下一步建议】新增第 4 项：每条代码修改使用一个 diff 代码块展示。
- `SKILL.md` 新增"修复建议 diff 格式示例"小节，给出 C++ 源码修改的 diff 展示格式示意。
- 新增 `scripts/match_so.py` 脚本，用于校验本地 .so 文件与 faultlog 中 BuildID 是否匹配，实现跨平台的 .so 文件匹配能力。
- 新增 `scripts/ohos_llvm_tools.py`：按环境变量优先级链自动定位并执行 `llvm-addr2line` 和 `llvm-objdump`，替代直接调用裸命令。
- 新增步骤零输入校验：`scripts/main.py` `build_report` 解析后检查堆栈帧，两者皆空时拒绝分析并提示用户提供完整调用栈。

### 变更
- skill版本号升级至 v1.4.0
- `SKILL.md` 步骤四§1 寄存器分析新增深度分析要求：x0/this 指针合法性分析、fault_addr 与相邻寄存器高位对比、字符串解码、填充模式识别、多项独立证据交叉验证判定 HIGH 可信度。
- `SKILL.md` 步骤四§3 责任领域新增内存破坏通用定界规则：崩溃模块是损坏内存访问方而非踩写源，无第一现场证据时责任领域判定为未定。
- `SKILL.md` 步骤四§4 新增源码可达性检测和 SO 文件校验流程（match_so.py）。
- `SKILL.md` 输出格式要求新增模板判定说明、多假设保留、可信度判定指引三条规则。
- `SKILL.md` 模板A 三级根因定位编码由占位符 `X/Y` 改为实际信号编号 `1.1.1.<信号编号>.<si_code编号>`，并增加模板判定说明和编码规则说明。
- `SKILL.md` 模板A 证据链新增：信号分析包含 Tid/线程名、寄存器分析包含多项分项、调用栈分析包含三层分层、源码行号与 BuildID 合并。
- `SKILL.md` 模板A 根本原因深层原因增加多假设保留要求；根因模块责任领域增加"未定"选项和内存破坏访问方/踩写源区分说明；修复建议增加 GWP-ASan/HWASan 文档链接。
- `SKILL.md` 模板B 三级根因编码同步改为实际信号编号，增加模板判定说明。
- `references/fault_mode.md` 信号分类速查表新增"信号编号"列和三级根因编码规则说明。
- `SKILL.md` 输出格式模板A和模板B由 ASCII 框线格式统一改为 Markdown 格式。
- `SKILL.md` 模板A和模板B的故障基本信息新增 LastFatalMessage 字段，标注保留原始信息并根据信息提示定位崩溃原因。
- `SKILL.md` 信号速查表 SIGABRT 行的 LastFatalMessage 引导增加"保留原始信息，根据信息提示定位崩溃原因"。
- `scripts/report.py` `_render_basic` 中 LastFatalMessage 输出后新增提示语；`_SIGNAL_NOTES` SIGABRT 说明同步更新。
- `scripts/hints.py` 涉及 LastFatalMessage 的特征匹配提示增加"保留 LastFatalMessage 原始信息"引导。
- `SKILL.md` 步骤四、`scripts/report.py` 堆栈提示与 `references/gwp_asan.md` 缺失信息表中的 `llvm-addr2line`/`llvm-objdump` 裸命令改为调用 `ohos_llvm_tools.py`。
- `SKILL.md` 步骤零新增 items 5-6：描述脚本日志类型识别与堆栈校验逻辑，以及脚本报错后停止分析并提示用户的沟通策略。

## [1.3.0] - 2026-09-01

### 变更
- skill版本号升级至 v1.3.0

## [1.2.0] - 2026-08-14

### 新增
- 新增 HSP 加载失败定界规则，支持识别 `[LoadJSPandaFile] load hsp failed`、提取 `hsp name` 和 `errorMsg`。
- 新增 NAPI `ProcessAll` 回调崩溃定界规则，支持将十进制回调地址转换为十六进制并通过 `Maps` 定位所属模块。
- 新增符号表反解状态门禁，统一判断 BuildID、裸地址、`so+offset` 和 `unknown` 栈帧的反解状态。

### 变更
- 重写 NAPI 浅栈定界规则，区分 `libace_napi.z.so` 直接崩溃和经 `libark_jsruntime.so` 调用的场景，并将跳过运行时后的第一帧作为首个分析对象。
- 补充 `env`、`napi_value`、`napi_ref`、`napi_async_work` 和 `napi_threadsafe_function` 的生命周期、跨线程及内存破坏排查方向。
- 常规 CppCrash、踩内存第2现场和 GWP-ASan 在未完成符号表反解时，【修复建议】或【下一步建议】第 1 项优先要求使用匹配 BuildID 的符号文件反解后重新分析。
- README 中的 CppCrash 命令路径适配 `01-fault-analysis/cppcrash-analysis/` 新目录结构。
- 新增责任领域与修复建议对齐规则：系统侧根因只输出系统模块修改，应用侧根因只输出应用修改，混合责任分开输出，责任未定时只给继续定界建议。
- 符号表门禁、GWP-ASan 和 libuv 专项规则改为面向实际责任候选模块，不再默认要求应用承担系统侧根因的修改。

### 修复
- 补充 `_first_frame()` 辅助函数，修复生成提示时 `first frame is not defined` 的解析异常。


## [1.1.0] - 2026-07-15

### 新增
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-cppcrash-analysis` Skill
- 支持 HarmonyOS/OpenHarmony Native 层（C/C++）崩溃故障分析
- 支持 SIGSEGV/SIGABRT/SIGILL/SIGBUS 等信号分类与寄存器分析
- 内置八步分析流程：关键日志提取 → 信号分类 → 崩溃地址分析 → Hilog 流水日志 → 调用栈解析 → 反汇编分析 → 业务代码分析 → 地址越界专项分析
- 新增分析工具：
  - `scripts/windows/llvm-addr2line.exe`：地址到函数名/行号解析
  - `scripts/windows/llvm-objdump.exe`：SO 文件反汇编
  - `scripts/windows/reliability_analyze.exe`：关键日志提取
  - `scripts/windows/extract_hilog.exe`：流水日志提取
- 新增参考资料：
  - `references/fault_mode.md`：CPP_CRASH 故障模式库
  - `references/arkui.md` / `arkdata.md` / `arkweb.md` / `jsruntime.md` / `render_service.md` / `jsvm.md` / `rosen_text.md`：各模块参考文档
- 内置 9 种常见崩溃类型速查（空指针、UAF、栈溢出、数据竞争、越界访问、死锁、除零、对齐错误、二进制不匹配）
