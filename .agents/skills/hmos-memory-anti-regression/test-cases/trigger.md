## 触发验证测试用例

---

### 测试用例：TRIGGER-001

**skill**：hmos-memory-anti-regression  
**类型**：trigger（触发验证）

#### 输入

帮我对新旧版本做个内存对比，看看有没有劣化。应用包名是 com.example.myapp，旧版 14.8.10，新版 14.8.30，设备已连接。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-memory-anti-regression  
**类型**：trigger（触发验证）

#### 输入

帮我写一个 ArkTS 的状态管理组件，用 @State 和 @Prop 实现父子组件数据传递

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-003

**skill**：hmos-memory-anti-regression  
**类型**：trigger（触发验证）

#### 输入

两个版本的 topdown 对比已经出来了，帮我分析 Top10 劣化 SO 的 type_name 分发逻辑

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-004

**skill**：hmos-memory-anti-regression  
**类型**：trigger（触发验证）

#### 输入

我在环境里找不到 trace_streamer，htrace 转 db 还能做吗？有没有办法解决这个工具缺失的问题？

#### 预期输出

**应触发**：是
