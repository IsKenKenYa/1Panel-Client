# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：deveco-studio-codelinter
**类型**：functional（功能验证）

#### 输入

codelinter 怎么用，帮我介绍一下这个 skill 的工作流程

#### 预期输出

**验证标准**：

- 说明会先探测 DevEco Studio 安装路径
- 说明会运行 CodeLinter CLI 进行检查
- 说明会用脚本解析结果（不手动解析）

**应包含**：CodeLinter

**应包含**：detect-codelinter.js, parse-result.js

---

### 测试用例：FUNC-002

**skill**：deveco-studio-codelinter
**类型**：functional（功能验证）

#### 输入

codelinter 的检查结果怎么解析，有哪些脚本可用

#### 预期输出

**验证标准**：

- 提到 parse-result.js 用于基础解析
- 提到 analyze-results.js 用于深度分析

**应包含**：parse-result.js
