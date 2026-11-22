# 触发验证测试用例

---

### 测试用例：TRIGGER-001

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

codescanner 怎么用？支持哪些参数？

#### 预期输出

**应触发**：是（usage / run-help：询问 CLI 用法与参数）

---

### 测试用例：TRIGGER-002

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

帮我用 codescanner 扫一下 D:\workspace\demo\MyApp，SDK 在 D:\sdk

#### 预期输出

**应触发**：是（run-help：请求构造扫描命令）

---

### 测试用例：TRIGGER-003

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

codescanner 扫描报错了，退出码是 1，日志在哪里看？

#### 预期输出

**应触发**：是（troubleshoot / output-info：扫描报错与日志定位）

---

### 测试用例：TRIGGER-004

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

codescanner 扫描报告里的 WindowListenerNotOff 是什么意思？怎么配置跳过它？

#### 预期输出

**应触发**：是（rule-info：询问规则含义与配置）

---

### 测试用例：TRIGGER-005

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

刚才那次扫描生成的 merged.sarif 怎么解读？

#### 预期输出

**应触发**：是（explain-result：上下文明确指向 codescanner 扫描结果，即使未含工具名）

---

### 测试用例：TRIGGER-006

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

codescanner: command not found 怎么办？command line tools 在哪里下载？

#### 预期输出

**应触发**：是（tool-availability：命令找不到与下载引导）

---

### 测试用例：TRIGGER-007

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

我装的 25.x 版本 command line tools，能跑 codescanner 扫描吗？

#### 预期输出

**应触发**：是（版本门槛：仅 26.0.1+ 支持 codescanner 扫描）

---

### 测试用例：TRIGGER-008

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

帮我用 CodeScanner 给这个鸿蒙工程做一次代码扫描

#### 预期输出

**应触发**：是（命中 code scanner 变体关键词与代码扫描场景）

---

### 测试用例：TRIGGER-009

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

帮我把应用的启动页面用 Web 组件实现，要支持预加载

#### 预期输出

**应触发**：否（普通功能开发需求，与 codescanner 命令行工具无关）

---

### 测试用例：TRIGGER-010

**skill**：deveco-studio-codescanner
**类型**：trigger（触发验证）

#### 输入

hilog 日志怎么按标签过滤？

#### 预期输出

**应触发**：否（hilog 日志工具范畴，属 deveco-studio-hilog 技能边界）
