## 触发验证测试用例

---

### 测试用例：TRIGGER-001

**skill**：harmonyos-memory-optimization-solution  
**类型**：trigger（触发验证）

#### 输入

我们的 HarmonyOS 应用里有一个预创建的离线 Web 组件，用 onFirstMeaningfulPaint 检测预渲染完成后没有做停止渲染的处理，现在预渲染的网页在后台一直渲染，手机发热、功耗高。帮我优化这个问题。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：harmonyos-memory-optimization-solution  
**类型**：trigger（触发验证）

#### 输入

应用首页是一个几百条数据的长列表，目前用 ForEach 一次性全量渲染，页面首帧很慢，滑动时内存峰值特别高。怎么优化这个列表的内存占用？

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003

**skill**：harmonyos-memory-optimization-solution  
**类型**：trigger（触发验证）

#### 输入

新版本自研 so（libs/arm64-v8a）体积比上一版涨了好几兆，smaps 对比显示 .so 映射的 Pss 也同步增长。帮我对 so 做体积和内存劣化的优化。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-004

**skill**：harmonyos-memory-optimization-solution  
**类型**：trigger（触发验证）

#### 输入

我们的业务代码里到处都是 new worker.ThreadWorker，同一个脚本文件被创建了十几个 worker 实例，用完也不 terminate，libworker.z.so 的内存占用一直在涨。这个问题怎么治理？

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-005

**skill**：harmonyos-memory-optimization-solution  
**类型**：trigger（触发验证）

#### 输入

帮我写一个 ArkTS 的自定义弹窗组件，支持标题、内容和确认/取消两个按钮，用 @CustomDialog 实现。

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-006

**skill**：harmonyos-memory-optimization-solution  
**类型**：trigger（触发验证）

#### 输入

我的应用准备上架华为应用市场，帮我梳理一下隐私声明和权限申请的合规检查清单。

#### 预期输出

**应触发**：否
