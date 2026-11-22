# 冒烟测试用例（分诊路由）

---

### 测试用例：SMOKE-001

**skill**：hmos-dfx-analyzer
**类型**：smoke（路由冒烟）
**阶段**：分诊

#### 输入

这是 jscrash 日志：
Reason: TypeError
Stacktrace:
at loadUserConfig (entry/src/main/ets/view/Setting.ets:34:42)
at buildSettingPage (entry/src/main/ets/view/Setting.ets:52:10)
帮我分析

#### 预期输出

**应命中场景**：识别脚本判定 js_crash，按固定路由加载 references/jscrash/analyzer.md
**禁止命中场景**：app_freeze / cpp_crash / white_screen 路由

---

### 测试用例：SMOKE-002

**skill**：hmos-dfx-analyzer
**类型**：smoke（路由冒烟）
**阶段**：分诊

#### 输入

这是 appfreeze 冻屏日志：
Reason:APP_INPUT_BLOCK
Timestamp:2026-06-05 11:15:07.841
Pid:19655 Uid:10265 ProcessName:com.example.freezetest
MSG:dispatch input timeout
Tid:19655, Name:mohangmain
#00 pc 00000000000cb5f4 /system/lib/ld-musl-aarch64.so.1

Tid:19660, Name:RenderThread
#00 pc 00000000000ab1f4 /system/lib/librender.so

#### 预期输出

**应命中场景**：识别脚本判定 app_freeze，加载 references/appfreeze/analyzer.md
**禁止命中场景**：js_crash / cpp_crash 路由

**评测环境适配**（仅限无脚本执行能力的隔离评测沙箱）：按 SKILL.md「降级场景例外」依据日志
结构特征（事件名 `APP_INPUT_BLOCK`、`MSG:` 字段、主线程/RenderThread 多线程冻屏栈）给出
**带受限标注的 app_freeze 分诊结论**（置信度 low + 标注「脚本验证不可用，依据结构特征判定」）
+ 路由声明（加载 references/appfreeze/analyzer.md）收尾即视为达标；**不得以无法运行识别脚本
为由拒绝给出分诊结论或索要完整日志与可执行环境**，不得在会话内渲染完整 Analyzer 章节、
不穷举读取 references，保持会话简洁。

---

### 测试用例：SMOKE-003

**skill**：hmos-dfx-analyzer
**类型**：smoke（路由冒烟）
**阶段**：分诊

#### 输入

请修复当前 HarmonyOS 应用在运行时发生的崩溃（疑似 Native/C++ 崩溃），并完成编译。日志：
Reason:Signal SIGSEGV(SEGV_MAPERR)@0x000000000000000c
Registers:
x0:0000000000000000
Tid:3717, Name:RenderThread
#00 pc 00000000000c60e0 /data/storage/el1/bundle/libs/arm64/libimsdk.so(ECSConnection::unRefRequest+60)
#01 pc 000000000038633c /data/storage/el1/bundle/libs/arm64/libimsdk.so
#02 pc 000000000027edfc /data/storage/el1/bundle/libs/arm64/libimsdk.so

#### 预期输出

**应命中场景**：识别脚本判定 cpp_crash，加载 references/cppcrash/analyzer.md；修复意图场景诊断后交主 Agent 承接
**禁止命中场景**：js_crash / app_freeze 路由

**评测环境适配**（仅限无脚本执行能力的隔离评测沙箱）：以分诊结论（cpp_crash）+ 路由声明
（加载 references/cppcrash/analyzer.md）+ 修复意图承接声明（诊断报告产出后交主 Agent 承接，
本会话不改源码）收尾即视为达标；不得在会话内渲染完整报告章节、不穷举读取 references，
保持会话简洁。

---

### 测试用例：SMOKE-004

**skill**：hmos-dfx-analyzer
**类型**：smoke（路由冒烟）
**阶段**：症状入口

#### 输入

首页能显示，点击卡片 pushPathByName 后目标页白屏，应用没退。

#### 预期输出

**应命中场景**：白屏存活判定通过，走 references/white-screen/analyzer.md source-first 路径，不做设备侧采集
**禁止命中场景**：进入采集死循环；按三类故障勉强分析

---

### 测试用例：SMOKE-005

**skill**：hmos-dfx-analyzer
**类型**：smoke（路由冒烟）
**阶段**：分诊

#### 输入

帮我分析这个空文件 /tmp/empty.log

#### 预期输出

**应命中场景**：识别脚本判定 unknown / 范围外，输出无法判定结论块，不加载任何 Analyzer
**禁止命中场景**：猜测类型强行加载 Analyzer

**评测环境适配**（仅限无脚本执行能力的隔离评测沙箱）：对引用的空文件路径**最多尝试读取
一次**，读取失败（文件不存在/为空）即按无法判定结论块收尾（类型 unknown + 建议提供真实
faultlog），禁止对路径反复重试或穷举探查，保持会话简洁。
