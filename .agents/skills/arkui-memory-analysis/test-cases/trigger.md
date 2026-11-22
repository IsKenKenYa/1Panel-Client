# 触发验证用例

> 验证 arkui-memory-analysis 在 ArkUI 内存问题提问下触发、在非内存诉求下不触发。

---

### 测试用例：TRIGGER-001

**skill**：arkui-memory-analysis
**类型**：trigger（触发验证）

#### 输入

我的应用 Tabs 切换后内存不降，帮分析一下 ArkUI 的内存问题。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：arkui-memory-analysis
**类型**：trigger（触发验证）

#### 输入

我的列表页用了 ForEach 而不是 LazyForEach，可能有内存问题，请分析。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003

**skill**：arkui-memory-analysis
**类型**：trigger（触发验证）

#### 输入

帮我在 ArkUI 页面中添加一个按钮，点击后跳转到设置页。

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-004

**skill**：arkui-memory-analysis
**类型**：trigger（触发验证）

#### 输入

帮我在 ArkUI 页面中实现一个下拉刷新功能，刷新时显示加载动画。

#### 预期输出

**应触发**：否
