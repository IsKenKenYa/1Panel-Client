# 触发验证测试用例

---

### 测试用例：TRIGGER-001

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：trigger（触发验证）

#### 输入

检查我的 NAPI 模块 C++ 代码，so 被 dlopen 时会执行哪些副作用代码？

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：trigger（触发验证）

#### 输入

要把 NAPI 模块接入 ArkTS lazy import，接入前需要做哪些副作用适配检查？

#### 预期输出

**应触发**：是

> 注（v2.3.0）：lazy import 时序差异不在检查模型内——skill 触发后应声明"检查基于 dlopen 即执行的默认 import 模型，不考虑 lazy import 时序差异"，并按该模型给出副作用检查结论。

---

### 测试用例：TRIGGER-003

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：trigger（触发验证）

#### 输入

应用冷启动耗时劣化，怀疑是某个 so 加载时执行了重初始化，帮我排查。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-004

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：trigger（触发验证）

#### 输入

怎么在 ArkTS 里调用 NAPI 模块导出的 C++ 函数并传递数组参数？

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-005

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：trigger（触发验证）

#### 输入

nm_register_func 注册回调里怎么用 napi_set_named_property 给 exports 挂载导出方法？

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-006

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：trigger（触发验证）

#### 输入

如何用 DevEco 定位 NAPI so 崩溃时的 C++ 堆栈信息？

#### 预期输出

**应触发**：否
