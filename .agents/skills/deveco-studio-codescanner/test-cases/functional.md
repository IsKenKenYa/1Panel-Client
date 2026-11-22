# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：deveco-studio-codescanner
**类型**：functional（功能验证）

#### 输入

帮我用 codescanner 扫 D:\workspace\demo\MyApp，C++ 和 ArkTS 都要扫，报告用 HTML

#### 预期输出

**验证标准**：

- 先执行工具可用性检查（`codescanner -v`，版本 ≥ 26.0.1），未安装/未配 PATH 时按 §4 Step 0.5 引导，不直接给命令
- 给出完整可执行命令（不使用省略号），形如 `codescanner D:/workspace/demo/MyApp -f html -o output --compileCommandsDir <含 compile_commands.json 的目录>`
- 不主动添加 `-s`（说明不传时工具用自带 sdk/ 或 DEVECO_SDK_HOME 兜底）
- 不传 `-c` 即检测全量规则（ArkTS 23 条 + C++ 27 条），并说明传 `-c` 会收窄范围
- 提示产物位置：output/merged.sarif 与 output/report.html，日志在 scanner/logs/codescanner.log
- 逐项校验 projectPath、compileCommandsDir 等路径存在性

**应包含**：codescanner、--compileCommandsDir、merged.sarif、report.html
**不应包含**：强制要求用户必须显式传 -s 的表述

---

### 测试用例：FUNC-002

**skill**：deveco-studio-codescanner
**类型**：functional（功能验证）

#### 输入

我只想检测 WindowListenerNotOff 和 NapiWrap API Not Paired 这两条规则，规则配置文件怎么写？

#### 预期输出

**验证标准**：

- 说明 `-c/--config` 为白名单语义：仅 `skip: false` 的规则被检测，未列出的自动补 `skip: true`
- 给出符合格式的 JSON 配置（rules.arkts / rules.cpp 按引擎分组，组名 ResourceLeak，含 ruleId、severity、skip 字段）
- WindowListenerNotOff 归入 arkts 段、NapiWrap API Not Paired 归入 cpp 段（规则归属正确）
- 提醒传 `-c` 后其他规则会被跳过，想全量检测则不传 `-c`

**应包含**：skip、白名单、rules
**格式**：JSON 代码块

---

### 测试用例：FUNC-003

**skill**：deveco-studio-codescanner
**类型**：functional（功能验证）

#### 输入

codescanner 提示 compile_commands.json is not valid JSON，扫描是不是失败了？

#### 预期输出

**验证标准**：

- 说明这是 compile_commands.json 三态错误之一（不存在 → not found；不可读 → not readable；非法 JSON → not valid JSON）
- 说明该错误仅跳过 C++ 检查并打印 [error]，不中断整体扫描；ArkTS 部分仍可正常完成，整体退出码可为 0
- 给出修复方向：改 CMakeLists.txt 后必须重新生成 compile_commands.json

**应包含**：跳过、重新生成、退出码
**不应包含**：判定为致命失败要求用户重装工具的表述

---

### 测试用例：FUNC-004

**skill**：deveco-studio-codescanner
**类型**：functional（功能验证）

#### 输入

扫描结束了，退出码是 1，这算成功还是失败？

#### 预期输出

**验证标准**：

- 正确解释退出码 1 = 有失败（至少一个引擎失败），与 0（全部成功）、2（启动失败）区分
- 说明部分成功时仍会合并成功引擎写出部分 merged.sarif，stdout 仍打印 Scan completed
- 引导查看 stderr 的 [toolId] ERROR: 行定位失败引擎（homeflow / cpp-agent），再到对应日志文件查细节

**应包含**：退出码、merged.sarif、[toolId] ERROR
**不应包含**：把退出码 1 解释成参数校验失败

---

### 测试用例：FUNC-005

**skill**：deveco-studio-codescanner
**类型**：functional（功能验证）

#### 输入

我在 Windows 上执行 codescanner 说命令不存在，工具还没安装

#### 预期输出

**验证标准**：

- 判定为 tool-availability 场景，不输出扫描命令
- 二选一引导：① 已有离线包 → 请用户给出 command line tools 位置，用绝对路径调用（`<工具根目录>/command-line-tools/codescanner/bin/codescanner`）；② 无工具 → 引导到官方下载页（developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos）
- 明确版本门槛：仅 26.0.1 及以上版本支持 codescanner 扫描，安装后用 `codescanner -v` 核对
- 可选给出配 PATH 指引（`...\command-line-tools\bin`）

**应包含**：command not found、26.0.1、command-line-tools-for-hmos
**不应包含**：未经可用性检查就直接给出的扫描命令

---

### 测试用例：FUNC-006

**skill**：deveco-studio-codescanner
**类型**：functional（功能验证）

#### 输入

merged.sarif 里 ruleId 是 RpcMessageSequenceNotRelease 的命中是什么问题？我的代码要怎么改？

#### 预期输出

**验证标准**：

- 从 references/rules/arkts-rules.md 给出该规则说明：@ohos.rpc MessageSequence.create → .reclaim，资源创建后未释放（NotRelease / resource 类）
- 按严重级别与规则 ID 分组解读，不展开无关规则
- 修复建议落到代码：补 release/reclaim 调用，并给出修复前/后代码对比后等用户确认

**应包含**：RpcMessageSequenceNotRelease、reclaim、NotRelease
**不应包含**：把该规则归为 C++（cpp-agent）规则的错误归属
