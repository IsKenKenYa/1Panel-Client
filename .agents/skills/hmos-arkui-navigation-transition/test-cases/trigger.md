## 触发验证测试用例

> 覆盖 hmos-arkui-navigation-transition 的触发判定。正向用例验证含转场动画关键词时应触发；负向用例验证无关需求不应触发。

---

### 测试用例：TRIGGER-001

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

请协助给这个 NavDestination 页面添加系统默认转场动画

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

给 NavDestination 添加自定义转场动画

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

我要实现转场过程中可交互的动画，给 Navigation 配置 customNavContentTransition

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-004

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

请禁用这个 NavDestination 的转场动画，不要转场效果

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-005

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

页面跳转动画怎么做？我想用系统自带的转场效果

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-006

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

全局关闭转场，Navigation 的页面切换不要动画

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-007

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

systemTransition 枚举有哪些值？customTransition 的 delegate 签名是什么？

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-008

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

帮我修改按钮颜色，把背景色改成红色

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-009

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

我的列表不显示数据，帮我排查一下ForEach的渲染问题

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-010

**skill**：hmos-arkui-navigation-transition  
**类型**：trigger（触发验证）

#### 输入

怎么用 Navigation 组件做路由跳转？navPathStack 怎么 pushPath？

#### 预期输出

**应触发**：否
