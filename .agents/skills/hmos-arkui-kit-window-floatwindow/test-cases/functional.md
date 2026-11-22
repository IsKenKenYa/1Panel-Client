## 功能性测试用例

> 极简问答。单点验证，不要求写代码、不要求读工程。

---

### 测试用例：FUNC-001

**skill**：hmos-arkui-kit-window-floatwindow  
**类型**：functional（功能验证）

#### 输入

不要读任何文件。一句话回答：视频播放退后台继续系统小窗，用画中画还是闪控窗？

#### 预期输出

**验证标准**：

- 回答指向画中画或 PiPWindow 或 pip

**应包含**：画中画

---

### 测试用例：FUNC-002

**skill**：hmos-arkui-kit-window-floatwindow  
**类型**：functional（功能验证）

#### 输入

不要读任何文件。一句话回答：create 成功算小窗已经显示了吗？要等什么状态？

#### 预期输出

**验证标准**：

- 说明 create 不等于已显示，需等待 STARTED（或等价表述）

**应包含**：STARTED

---

### 测试用例：FUNC-003

**skill**：hmos-arkui-kit-window-floatwindow  
**类型**：functional（功能验证）

#### 输入

不要读任何文件。一句话回答：用 createSubWindow 做悬浮小窗，本 skill 管不管？

#### 预期输出

**验证标准**：

- 明确不在范围或 out_of_scope

**应包含**：不在
