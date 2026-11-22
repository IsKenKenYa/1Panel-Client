# 更新日志

## [1.4.0] - 2026-09-28

### 新增
- 新增 `references/io-blocking-analysis.md`，覆盖文件读写、同步落盘、阻塞 socket、`mkdir`/`mkdirat` 等路径创建和文件系统元数据操作，并补充 NFS/FUSE、目录锁、非阻塞模式和事件循环等待的判定边界。

### 变更
- skill版本号升级至 v1.4.0
- `SKILL.md` Step 4 新增同步 I/O / 文件系统阻塞专项路由：单次栈命中只提示风险，稳定重复调用链或采样占比满足门槛后才能匹配三级根因。
- `references/fault-mode-library.md` 扩展「阻塞 IO 操作」「IO 操作繁忙」规则，加入路径创建相关 syscall、条件性 `close` 和事件等待接口的误报防护。
- 根因确认为应用主线程同步 I/O 时，修复建议必须提示使用异步 API 或移至 worker/taskpool，并按实际实现模块判定责任领域。
- `references/fault-mode-library.md` 两处"二级：主线程繁忙"新增无采样栈默认匹配规则：所有繁忙类三级根因均依赖采样栈占比（>30%）判定，当无采样栈或采样栈不可用时默认匹配"执行耗时操作"。
- `references/fault-mode-library.md` "执行耗时操作（多任务混合）"判定规则增加无采样栈时默认匹配的场景说明。
- `SKILL.md` Step 9a 故障模式库匹配的三级根因匹配步骤新增"繁忙类无采样栈默认匹配"说明。
- `SKILL.md` Step 4 堆栈分析新增逐帧解读要求：证据链中必须对故障目标线程调用栈逐帧（或关键帧）添加行内注释，不得仅列帧而不解读。
- `SKILL.md` Step 4 堆栈分析新增字节码桩语义解读要求：栈顶位于 `stub.an` 等 ArkTS 字节码桩时，必须解读字节码指令的语义含义（如条件/循环 Isfalse 判定），据此推断应用代码执行状态。
- `SKILL.md` 输出格式模板由 ASCII 框线格式统一改为 Markdown 格式（标题、表格、列表、代码块）。
- `SKILL.md` 输出模板证据链新增专项排除段（排除 FFRT/libuv/Binder/等锁）和其他线程分析表格要求。
- `SKILL.md` 输出模板根本原因增加字节码语义解读要求，采样栈热点函数分析增加无采样栈时输出说明。
- `SKILL.md` 输出模板诊断结果增加源码行号标注要求：当日志栈帧含应用源码路径时必须在诊断句中直接标注源码文件:行号。
- `SKILL.md` 输出模板根因模块模块名称增加源码行号标注要求：当日志栈帧含应用源码路径和行列号时，模块名必须附带源码文件:行:列。

## [1.3.0] - 2026-09-01

### 新增
- 新增 `scripts/match_so.py` 脚本，用于确定 应用卡顿（Freeze）期间与日志匹配的.so文件的文件路径，实现跨平台的.so文件匹配能力。
- 新增 `scripts/llvm_addr2line.py` 脚本，用于执行 应用卡顿（Freeze）期间栈帧的地址解析，实现跨平台的栈帧地址解析能力。

### 变更
- step 4 新增 step 4a 符号解析流程，在源码可达并且需要对栈帧地址解析时执行。
- 分析报告模板中"修复建议"和"关键证据"新增：在源码可达时输出源码级的修复建议和证据。
- skill版本号升级至 v1.3.0

### 修复
- 修复分析报告模板格式问题。
- 完善修复建议，源码可达时输出源码修改的diff块。

## [1.2.0] - 2026-08-14

### 变更
- 普通 `THREAD_BLOCK_6S` 继续分析主线程；业务线程事件的阻塞/繁忙判定改为比较同一业务线程 TID 的 3s、6s 堆栈，主线程栈仅作关联上下文。
- EventHandler、Binder、等锁和 libuv 分析统一以故障目标线程为锚点，避免业务线程事件被主线程耗时栈误导。
- 更新 `SKILL.md` 文档内容，Step 1 新增输入文件有效性检查：校验用户输入的文件是否有效且包含构成指令的特殊语句，无效则再次问讯要求上传正确日志片段
- 更新 `SKILL.md` 文档内容，优化 CPU 信息数据源选择：优先使用采样栈文件 `cpuinfo-ext` 中 `#CpuFreq Usage（usage ≥ 1%）` 区域各核使用率与频率，未提供时回退至关键日志中的 CPU 信息
- 更新 `SKILL.md` 文档内容，合并分析步骤：原「Step 10 综合结论输出」并入「Step 9」（9a 故障模式库匹配 / 9b 输出内容要求），工作流由十步调整为九步
- 更新 `SKILL.md` 文档内容，统一内存、温度信息判定的加粗排版
- 调整 `SKILL.md` 分析流程，首次只读取 `overview`，再根据资源、队列、故障栈、等锁和 Binder 特征按需读取后续区段。
- 保留原有完整报告能力；未指定 `--section` 时默认使用 `full`，保持旧命令兼容。
- 区段不存在时输出简短提示并正常退出，避免无效日志进入 AI 上下文。
- 修复建议改为严格匹配责任领域：系统侧根因只输出系统服务/框架/组件修改，应用侧根因只输出应用修改；应用临时规避不得替代系统根因修复。
- FFRT、libuv 与 Binder 链路统一追踪到实际责任实现模块，不再默认归责应用业务代码。

### 修复
- 修正区段渲染器使用字典下标直接取值的问题，改为 `dict.get()` 并在渲染器未注册时抛出明确异常。
- 解析概览和故障栈新增线程角色提示，并兼容 `BUSSINESS` 历史拼写与 `BUSINESS` 标准拼写。

## [1.1.0] - 2026-07-15

### 新增
- 新增 `scripts/freeze/` 目录及 Python 脚本（代替原来的可执行文件），可供开发者针对不同的开发环境灵活修改
- 新增 `scripts/sample_stack_analyzer.py` 脚本，用于分析 应用卡顿（Freeze）期间堆栈采样数据，实现跨平台的堆栈分析能力。

### 变更
- 更新 `SKILL.md` 文档内容，加入了对python脚本的使用工作流以及各类依赖的检查

### 移除
- 移除 `scripts/`下的可执行文件

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-appfreeze-analysis` Skill
- 支持 HarmonyOS/OpenHarmony Freeze（冻屏/卡死/ANR）故障日志自动分析
- 内置十步分析工作流：环境检查 → 关键日志提取 → 整机资源评估 → EventHandler 队列分析 → 线程堆栈分析 → Binder 通信链路分析 → IPC 对端堆栈分析 → Trace 分析 → 热点函数采样分析 → 综合结论输出
- 支持故障模式库三级根因匹配（FML-001 主线程卡死超时）
- 新增跨平台二进制分析脚本：
  - `scripts/linux/reliability_analyze.run` / `sample_stack_analyzer.run`
  - `scripts/macos/reliability_analyze` / `sample_stack_analyzer`
  - `scripts/windows/reliability_analyze.exe` / `sample_stack_analyzer.exe`
- 新增参考资料 `references/fault-mode-library.md`
