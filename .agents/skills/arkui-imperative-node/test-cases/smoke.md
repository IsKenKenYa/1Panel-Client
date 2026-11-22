# 冒烟测试用例

> 验证 API 路由正确性。开发者描述需求特征，Skill 应路由到正确的 API。

---

### 测试用例：SMOKE-001

**skill**：arkui-imperative-node  
**类型**：smoke（路由验证）

#### 输入

我需要整体控制节点树，内部用@Builder声明式构建，用状态管理。应该选 BuilderNode、FrameNode 还是 RenderNode？

#### 预期输出

**应命中场景**：BuilderNode  

---

### 测试用例：SMOKE-002

**skill**：arkui-imperative-node  
**类型**：smoke（路由验证）

#### 输入

我只需要设置渲染属性和自定义绘制，不参与布局和事件。应该选哪个 API？

#### 预期输出

**应命中场景**：RenderNode  

---
