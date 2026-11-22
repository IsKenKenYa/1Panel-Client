# 触发验证用例

> 验证 arkui-ndk-ui-node-skill 在 CAPI 混合开发 / 跨语言 UI 节点接入诉求下触发，在无关需求下不触发。

---

### 测试用例：TRIGGER-001

**skill**：arkui-ndk-ui-node-skill
**类型**：trigger（触发验证）

#### 输入

我在 ArkTS 页面里用 NodeContent 做了个占位，想在 C 侧挂 Native 节点树上去，怎么接入？

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：arkui-ndk-ui-node-skill
**类型**：trigger（触发验证）

#### 输入

我有一个 Native 创建的父节点，想把 ArkTS 的 ComponentContent 挂到它下面作为 child，用 OH_ArkUI_GetNodeHandleFromNapiValue 转 handle 后 addChild 不生效。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003

**skill**：arkui-ndk-ui-node-skill
**类型**：trigger（触发验证）

#### 输入

我要做 CAPI 混合开发，ArkTS 和 Native 混用 UI 节点，ContentSlot 那块怎么搞？

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-004

**skill**：arkui-ndk-ui-node-skill
**类型**：trigger（触发验证）

#### 输入

帮我在 ArkUI 页面中添加一个按钮，点击后跳转到设置页。

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-005

**skill**：arkui-ndk-ui-node-skill
**类型**：trigger（触发验证）

#### 输入

帮我把 ArkTS 的 List 换成 LazyForEach 来优化长列表滑动性能。

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-006

**skill**：arkui-ndk-ui-node-skill
**类型**：trigger（触发验证）

#### 输入

我的 napi_property_descriptor 注册的方法运行时报 "mountNativeNodes is not callable, mountNativeNodes is undefined"，帮排查一下。

#### 预期输出

**应触发**：是
