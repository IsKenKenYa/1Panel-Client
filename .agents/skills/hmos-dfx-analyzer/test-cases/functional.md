# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：hmos-dfx-analyzer
**类型**：functional（功能验证）

#### 输入

帮我分析这个崩溃日志（faultlog 内容如下）：
Reason:Signal SIGSEGV(SEGV_MAPERR)@0x006bcc0c4890755c
Registers:
x8:0000006b6bcc0c4890753c
Tid:3717, Name:RenderThread
#00 pc 00000000000c60e0 /data/storage/el1/bundle/libs/arm64/libimsdk.so(ECSConnection::unRefRequest+60)
#01 pc 000000000038633c /data/storage/el1/bundle/libs/arm64/libimsdk.so
#02 pc 000000000027edfc /data/storage/el1/bundle/libs/arm64/libimsdk.so

#### 预期输出

**验证标准**：

- 先运行 identify_fault_log.py 完成确定性分诊，不得按文件名或口述预设类型
- 分诊判为 cpp_crash 后仅加载 cppcrash analyzer
- 会话内只输出简洁摘要（分诊结论、根因 1~3 句、修复方向、报告路径），不输出报告正文
- 完整报告经 export_report.py 写入 dfx-reports/ 下的 HTML，摘要中的报告路径为绝对路径

**应包含**：分诊结论, dfx-reports

**评测环境适配**（仅限无脚本执行能力的隔离评测沙箱）：按「降级场景例外」依据结构特征
（Signal 形态 Reason + Registers 段 + 3 帧 Native 栈帧）给出带受限标注的 cpp_crash 分诊结论
+ 路由声明收尾；不得渲染完整 Analyzer 章节、不穷举读取 references，保持会话简洁。

---

### 测试用例：FUNC-002

**skill**：hmos-dfx-analyzer
**类型**：functional（功能验证）

#### 输入

这是 jscrash 日志片段：
Reason: TypeError
at loadUserConfig (entry/src/main/ets/view/Setting.ets:34:42)
at buildSettingPage (entry/src/main/ets/view/Setting.ets:52:10)
帮我分析

#### 预期输出

**验证标准**：

- 片段输入经 --stdin 走同一套分诊判别
- 分诊为 js_crash 后加载 jscrash analyzer，按故障模式库匹配三级根因
- 分析结论置信度不高于分诊置信度（片段通常为 medium 及以下），摘要中显式标注

**应包含**：js_crash, 置信度

---

### 测试用例：FUNC-003

**skill**：hmos-dfx-analyzer
**类型**：functional（功能验证）

#### 输入

请修复当前 HarmonyOS 应用在运行时发生的崩溃（JSCrash），并完成编译。

#### 预期输出

**验证标准**：

- 诊断与修复分工：子会话只产出诊断报告，不直接修改业务源码
- 会话摘要按「修复意图与后续承接」钉板输出规定措辞：`诊断状态`、`源码修改状态：未执行，由主 Agent 承接`，并以固定承接语句 `是否需要按照上面的诊断结论修改并验证？` 收尾——不得改用自由表述替代钉板措辞
- 不得声称修复已经开始或完成

**应包含**：主 Agent 承接, 源码修改状态, 是否需要按照上面的诊断结论修改并验证

**评测环境适配**（仅限无脚本执行能力的隔离评测沙箱）：无日志且无设备采集能力时，跳过
日志检索直接以以下**三句原样输出**收尾即视为达标（逐句输出、一句不漏、措辞不改）：

```
诊断状态：无法判定（无日志且无法采集）
源码修改状态：未执行，由主 Agent 承接
是否需要按照上面的诊断结论修改并验证？
```

**不得**以"请把日志发我""拿到崩溃日志后我会立即执行"等自由表述替代上述钉板措辞，
不得穷举检索工程源码/日志路径做深度分析，保持会话简洁。

---

### 测试用例：FUNC-004

**skill**：hmos-dfx-analyzer
**类型**：functional（功能验证）

#### 输入

批量分析这两份日志（第一份）：
Reason: TypeError
at loadUserConfig (entry/src/main/ets/view/Setting.ets:34:42)
at buildSettingPage (entry/src/main/ets/view/Setting.ets:52:10)

（第二份）：
Reason:ReferenceError
Error name:ReferenceError
Error message:xxx is not defined
Timestamp:2026-09-18 09:41:21.841
Module:com.example.demo
at onClick (entry/src/main/ets/pages/Index.ets:57:79)
全部逐份分析，出一份合并报告。

#### 预期输出

**验证标准**：

- 批量两份日志逐份分诊，每份独立走决策表
- 合并报告每份日志以 `### 日志 N：<文件名或序号>` 起节，分节首行为该份的分诊结论行
- 每份分节完整遵循对应 Analyzer 输出格式章节，不得自创压缩结构
- 分诊摘要表逐份携带 类型 / 输入完整度 / 置信度 三字段
- HTML 报告中文正文无乱码（批量合并走多次 `--input` 直传，禁止 shell 拼接合并分节正文）

**评测环境适配**（仅限无脚本执行能力的隔离评测环境，如仅 Read 工具的沙箱）：真实环境中完整 Analyzer
章节与 HTML 报告由脚本落盘；评测沙箱内无 bash 时，**只输出**逐份三字段（类型 / 输入完整度 / 置信度）
的「分诊摘要」表 + `### 日志 N：<文件名或序号>` 分节声明 + 合并路径声明（多次 `--input` 直传 /
禁止 shell 合并）三件收尾即视为达标——**除此之外不得输出任何其他内容**（尤其禁止逐份渲染完整
Analyzer 章节、禁止输出根因分析与证据链正文），确保在评测预算内收尾。

**应包含**：分诊摘要, 日志 1

---

### 测试用例：FUNC-005

**skill**：hmos-dfx-analyzer
**类型**：functional（功能验证）

#### 输入

工程能构建也不会崩溃，但冷启动一直白屏，应用没退出，不要先复现，直接定位并修复。

#### 预期输出

**验证标准**：

- 白屏存活判定后直接 source-first 分析，不索要日志、不要求连接设备
- 按聚焦检视顺序检查 main_pages.json / EntryAbility.loadContent / 入口页 Navigation / hideNavBar / navDestination
- 修复遵循最小改动约束；报告按三档验证契约区分根因匹配 / 构建验证 / 运行时间验证

**应包含**：loadContent, 白屏

**评测环境适配**（仅限无脚本执行能力、无工程源码的隔离评测沙箱）：**先做环境判定**——
对工程路径尝试读取，若不可读或不存在（沙箱内通常如此），**立即**停止一切文件读取与检索，
以白屏存活判定 + source-first 检视顺序聚焦清单（main_pages.json / loadContent / Navigation /
hideNavBar / navDestination）+ 各聚焦项的检视要点收尾即视为达标；**不得**对同一/相近路径
反复重试或变换路径穷举试读，不得在会话内渲染完整报告章节，保持会话简洁。
