### 测试用例：SMOKE-001

**skill**：hmos-window-immersive（必填）
**类型**：smoke（路由验证）

#### 输入

我想了解鸿蒙应用有几种沉浸式方案，各自适用于什么场景

#### 预期输出

**应命中场景**：IMM-01
**禁止命中场景**：IMM-02, IMM-03, IMM-04, IMM-05

---

### 测试用例：SMOKE-002

**skill**：hmos-window-immersive（必填）
**类型**：smoke（路由验证）

#### 输入

帮我在页面中用 expandSafeArea 实现顶部背景延伸到状态栏

#### 预期输出

**应命中场景**：IMM-02
**禁止命中场景**：IMM-01, IMM-03, IMM-04, IMM-05

---

### 测试用例：SMOKE-003

**skill**：hmos-window-immersive（必填）
**类型**：smoke（路由验证）

#### 输入

需要用 setWindowLayoutFullScreen 设置沉浸式布局并避让导航条

#### 预期输出

**应命中场景**：IMM-03
**禁止命中场景**：IMM-01, IMM-02, IMM-04, IMM-05

---

### 测试用例：SMOKE-004

**skill**：hmos-window-immersive（必填）
**类型**：smoke（路由验证）

#### 输入

如何获取 avoidArea 并监听避让区变化，做挖孔避让处理

#### 预期输出

**应命中场景**：IMM-04
**禁止命中场景**：IMM-01, IMM-02, IMM-03, IMM-05

---

### 测试用例：SMOKE-005

**skill**：hmos-window-immersive（必填）
**类型**：smoke（路由验证）

#### 输入

我的滚动列表页面想做沉浸式效果，背景延伸到状态栏和导航条

#### 预期输出

**应命中场景**：IMM-05
**禁止命中场景**：IMM-01, IMM-02, IMM-03, IMM-04
