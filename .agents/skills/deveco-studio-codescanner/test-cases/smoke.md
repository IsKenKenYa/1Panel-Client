# 冒烟测试用例（Intent 路由）

---

### 测试用例：SMOKE-001

**skill**：deveco-studio-codescanner
**类型**：smoke（路由冒烟）
**阶段**：usage

#### 输入

codescanner 有哪些命令行参数？默认输出到哪里？

#### 预期输出

**应命中场景**：usage → 加载 references/cli-spec.md，按参数表逐项说明（含默认值 output/、scanner/logs/、sarif）
**禁止命中场景**：错误排查 / 工具可用性 / 规则含义路由

---

### 测试用例：SMOKE-002

**skill**：deveco-studio-codescanner
**类型**：smoke（路由冒烟）
**阶段**：run-help

#### 输入

帮我用 codescanner 扫 D:\workspace\demo\MyApp，要扫 C++ 和 ArkTS

#### 预期输出

**应命中场景**：run-help → 加载 references/cli-spec.md，先确认 command line tools 可用（codescanner -v），再组装完整命令并逐项校验路径存在性（--compileCommandsDir 指向含 compile_commands.json 的目录）
**禁止命中场景**：不校验工具可用性直接给命令；跳过路径校验

---

### 测试用例：SMOKE-003

**skill**：deveco-studio-codescanner
**类型**：smoke（路由冒烟）
**阶段**：troubleshoot

#### 输入

codescanner 报了 compile_commands.json is not readable，怎么处理？

#### 预期输出

**应命中场景**：troubleshoot → 加载 references/error-troubleshooting.md，按错误分类优先级（权限 > 路径 > JSON 格式 > 引擎）给出修复步骤（检查 ACL/icacls 授权）
**禁止命中场景**：把它当成 JSON 格式错误处理（不可读优先级更高）

---

### 测试用例：SMOKE-004

**skill**：deveco-studio-codescanner
**类型**：smoke（路由冒烟）
**阶段**：rule-info

#### 输入

NapiWrap API Not Paired 这条规则是什么意思？

#### 预期输出

**应命中场景**：rule-info → 加载 references/rules/index.md，再进 references/rules/cpp-rules.md 给出 API 配对（napi_wrap → napi_remove_wrap）与检查器说明
**禁止命中场景**：路由到 ArkTS 规则文档或 CLI 参数文档

---

### 测试用例：SMOKE-005

**skill**：deveco-studio-codescanner
**类型**：smoke（路由冒烟）
**阶段**：output-info

#### 输入

codescanner 的退出码 0、1、2 分别代表什么？

#### 预期输出

**应命中场景**：output-info → 加载 references/exit-codes.md（0 全成功 / 1 有失败 / 2 启动失败）
**禁止命中场景**：路由到规则文档或错误分类表

---

### 测试用例：SMOKE-006

**skill**：deveco-studio-codescanner
**类型**：smoke（路由冒烟）
**阶段**：tool-availability

#### 输入

codescanner 命令找不到，我没有配 PATH

#### 预期输出

**应命中场景**：tool-availability → 走 SKILL.md §4 Step 0.5：二选一引导（给出 command line tools 位置 → 绝对路径调用；或引导官方下载），并核版本门槛 26.0.1+ → error-troubleshooting.md §2.6
**禁止命中场景**：直接给出扫描命令；路由到普通参数问答

---

### 测试用例：SMOKE-007

**skill**：deveco-studio-codescanner
**类型**：smoke（路由冒烟）
**阶段**：explain-result

#### 输入

扫描结果 report.html 里一堆 error 级别的命中，帮我解读一下

#### 预期输出

**应命中场景**：explain-result → 按 SARIF 结构解读 merged.sarif / report.html（ruleId 聚合、严重级别分组），规则含义查 references/rules/index.md
**禁止命中场景**：当成报错排查（troubleshoot）处理
