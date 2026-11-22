## 冒烟测试用例

> 路由型 skill 冒烟测试，验证三级决策树能否正确命中所有 4 类分流场景及异常处理分支。

---

### 测试用例：SMOKE-001

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

请协助给这个 NavDestination 页面添加系统默认转场动画

#### 预期输出

**应命中场景**：systemTransition  
**禁止命中场景**：customTransition, customNavContentTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-002

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

我想用系统自带的转场效果

#### 预期输出

**应命中场景**：systemTransition  
**禁止命中场景**：customTransition, customNavContentTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-003

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

添加系统转场，枚举用默认值

#### 预期输出

**应命中场景**：systemTransition  
**禁止命中场景**：customTransition, customNavContentTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-004

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

请给 NavDestination 添加自定义转场动画

#### 预期输出

**应命中场景**：customTransition  
**禁止命中场景**：systemTransition, customNavContentTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-005

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

给页面加一个缩放+淡入的转场动画

#### 预期输出

**应命中场景**：customTransition  
**禁止命中场景**：systemTransition, customNavContentTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-006

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

页面转场用自定义动画，不要系统的

#### 预期输出

**应命中场景**：customTransition  
**禁止命中场景**：systemTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-007

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

我要实现转场过程中可交互的动画

#### 预期输出

**应命中场景**：customNavContentTransition  
**禁止命中场景**：systemTransition, customTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-008

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

给 Navigation 配置可交互转场

#### 预期输出

**应命中场景**：customNavContentTransition  
**禁止命中场景**：systemTransition, customTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-009

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

给 NavDestination 配自定义转场，转场中要能交互

#### 预期输出

**应命中场景**：customNavContentTransition  
**禁止命中场景**：systemTransition, disableAnimation, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-010

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

请禁用这个 NavDestination 的转场动画

#### 预期输出

**应命中场景**：disableAnimation  
**禁止命中场景**：systemTransition, customTransition, customNavContentTransition, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-011

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

这个 NavDestination 不要转场效果

#### 预期输出

**应命中场景**：disableAnimation  
**禁止命中场景**：systemTransition, customTransition, customNavContentTransition, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-012

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

请禁用 Navigation 的转场动画

#### 预期输出

**应命中场景**：disableAnimation  
**禁止命中场景**：systemTransition, customTransition, customNavContentTransition, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-013

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

全局关闭转场

#### 预期输出

**应命中场景**：disableAnimation  
**禁止命中场景**：systemTransition, customTransition, customNavContentTransition, exception  
**阶段**：DEV

---

### 测试用例：SMOKE-016

**skill**：hmos-arkui-navigation-transition  
**类型**：smoke（路由验证）  
**阶段**：DEV

#### 输入

（未提供需求描述，仅提供了文件路径）

#### 预期输出

**应命中场景**：exception  
**禁止命中场景**：systemTransition, customTransition, customNavContentTransition, disableAnimation  
**阶段**：DEV
