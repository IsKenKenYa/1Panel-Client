## 触发验证测试用例

---

### 测试用例：TRIGGER-001

**skill**：hmos-lazy-import-analysis  
**类型**：trigger（触发验证）

#### 输入

我从设备上导出了 redundant file 报告，应用源码在 /data/project/myapp，帮我分析下哪些模块可以改成 import lazy 懒加载。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-lazy-import-analysis  
**类型**：trigger（触发验证）

#### 输入

应用启动耗时有点长，想优化下模块加载开销，做个懒加载改造分析，包名 com.example.app。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003

**skill**：hmos-lazy-import-analysis  
**类型**：trigger（触发验证）

#### 输入

帮我写一个 ArkTS 的列表页面，用 LazyForEach 实现长列表懒加载。

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-004

**skill**：hmos-lazy-import-analysis  
**类型**：trigger（触发验证）

#### 输入

上次的 lazy-import 修改建议报告我看完了，把里面确认 safe 的那几个模块帮我应用一下。

#### 预期输出

**应触发**：是
