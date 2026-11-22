## 功能性测试用例

> 覆盖 hmos-arkui-navigation-transition 的四类分流场景（systemTransition / customTransition / customNavContentTransition / disableAnimation）正向功能，以及边界引导与异常处理。

---

### 测试用例：FUNC-001

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

文件路径：entry/src/main/ets/pages/MyPage.ets（该文件包含 NavDestination 组件）

请协助给这个 NavDestination 页面添加系统默认转场动画

#### 预期输出

**验证标准**：

- 应命中 systemTransition 分流（关键词「系统」「默认」「NavDestination」→ L3 系统转场）
- 应输出 `.systemTransition(NavigationSystemTransitionType.DEFAULT)` 配置方案
- 接入位置应在 NavDestination 组件声明上（链式调用）
- 枚举取值应以 references/navigation-transition-api.md 的 .d.ts 枚举值为准
- 方案应与 ArkUI 官方开发指南逐条一致

**应包含**：systemTransition, DEFAULT, NavDestination  
**不应包含**：pageTransition

---

### 测试用例：FUNC-002

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

我想用系统自带的转场效果

#### 预期输出

**验证标准**：

- 应命中 systemTransition 分流（口语化描述「系统自带」也能正确路由）
- 应输出 `.systemTransition(NavigationSystemTransitionType.DEFAULT)` 配置方案
- 接入位置应在 NavDestination 组件声明上
- 不应因口语化描述而误分流到 customTransition

**应包含**：systemTransition, DEFAULT  
**不应包含**：customTransition, pageTransition

---

### 测试用例：FUNC-003

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

添加系统转场，枚举用默认值

#### 预期输出

**验证标准**：

- 应命中 systemTransition 分流
- 应输出 `.systemTransition(NavigationSystemTransitionType.DEFAULT)` 配置方案
- 枚举取值应与开发者指定的「默认值」一致（DEFAULT）
- 接入位置应在 NavDestination 组件声明上
- 不应忽略开发者指定的枚举值而使用其他枚举

**应包含**：systemTransition, DEFAULT  
**不应包含**：pageTransition

---

### 测试用例：FUNC-004

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

文件路径：entry/src/main/ets/pages/MyPage.ets（该文件包含 NavDestination 组件）

请给 NavDestination 添加自定义转场动画

#### 预期输出

**验证标准**：

- 应命中 customTransition 分流（无交互）
- 应生成返回 `NavDestinationTransition` 数组的框架代码
- 代理函数签名应为 `(operation: NavigationOperation, isEnter: boolean) => Array<NavDestinationTransition> | undefined`
- 回调结构应完整（含 event 闭包、duration、curve、onTransitionEnd）
- 应使用 `.customTransition(delegate)` 链式调用（非 pageTransition 方法覆写）
- 动画初始值应在 customTransition 回调体内同步赋值（返回数组前对 `@State` 变量赋初值）
- 动画结束值应在 event 闭包内直接赋值（event 已在动画执行上下文中）
- event 闭包内不应调用 animateTo（二次包裹会破坏系统转场动画上下文）
- 无交互诉求时不引导至 customNavContentTransition

**应包含**：customTransition, NavDestinationTransition, NavDestinationTransitionDelegate  
**不应包含**：pageTransition, animateTo

---

### 测试用例：FUNC-005

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

文件路径：entry/src/main/ets/pages/MyPage.ets（该文件包含 NavDestination 组件）

给页面加一个缩放+淡入的转场动画

#### 预期输出

**验证标准**：

- 应命中 customTransition 分流（无交互）
- 应生成返回 `NavDestinationTransition` 数组的框架代码，体现缩放与淡入效果逻辑
- 动画初始值应在 customTransition 回调体内同步赋值
- 动画结束值应在 event 闭包内直接赋值（操作 scaleValue/opacityValue 等状态变量）
- 状态变量名应使用业务语义前缀（如 scaleValue/opacityValue），避免通用属性保留名
- 回调结构应完整
- 应使用 `.customTransition(delegate)` 链式调用
- event 闭包内不应调用 animateTo

**应包含**：customTransition, NavDestinationTransition  
**不应包含**：@State scale, @State opacity, animateTo

---

### 测试用例：FUNC-006

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

页面转场用自定义动画，不要系统的

#### 预期输出

**验证标准**：

- 应命中 customTransition 分流（无交互，排除系统描述变体）
- 应生成返回 `NavDestinationTransition` 数组的框架代码
- 回调结构应完整
- 应使用 `.customTransition(delegate)` 链式调用
- 动画初始值应在回调体内同步赋值，结束值在 event 闭包内直接赋值
- 无交互诉求时不引导至 customNavContentTransition
- 不应因「不要系统的」描述而误分流到 disableAnimation

**应包含**：customTransition, NavDestinationTransition  
**不应包含**：systemTransition(NONE), animateTo

---

### 测试用例：FUNC-007

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

文件路径：entry/src/main/ets/pages/MyPage.ets（该文件包含 Navigation 组件）

我要实现转场过程中可交互的动画

#### 预期输出

**验证标准**：

- 应命中 customNavContentTransition 分流（关键词「可交互」→ L2 整体可交互）
- 应生成 `NavigationAnimatedTransition` 框架代码
- 应含 `transition` 回调（接收 `NavigationTransitionProxy` 参数，proxy 含 from/to 页面信息）
- transition 回调中应调用 `transitionProxy.finishTransition()` 结束转场
- 应给出 transition 注册建议（全局注册或单例可访问）
- 注册建议应明确全局/单例二选一并说明取舍

**应包含**：customNavContentTransition, NavigationAnimatedTransition, NavigationTransitionProxy, finishTransition  
**不应包含**：onTransitionFrom, onTransitionTo

---

### 测试用例：FUNC-008

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

给 Navigation 配置可交互转场

#### 预期输出

**验证标准**：

- 应命中 customNavContentTransition 分流（Navigation 配置描述变体）
- 应生成 `NavigationAnimatedTransition` 框架代码
- 应含 `transition` 回调（接收 `NavigationTransitionProxy` 参数）
- 应给出 transition 注册建议
- 注册建议应明确全局/单例二选一并说明取舍
- 不应将 customNavContentTransition 配置在 NavDestination 上而非 Navigation 上

**应包含**：customNavContentTransition, Navigation, NavigationTransitionProxy  
**不应包含**：onTransitionFrom, onTransitionTo

---

### 测试用例：FUNC-009

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

请禁用这个 NavDestination 的转场动画

#### 预期输出

**验证标准**：

- 应命中 disableAnimation 分流 → 单页禁用（NavDestination）
- 应输出 NavDestination 单页禁用配置指导
- 单页禁用应通过 `systemTransition(NavigationSystemTransitionType.NONE)` 实现
- 应明确作用域为单页（NavDestination），与全局禁用明确区分
- 不应在单页禁用时使用 `NavPathStack.disableAnimation(true)`（那是全局禁用）

**应包含**：disableAnimation, systemTransition, NONE, 单页  
**不应包含**：NavPathStack.disableAnimation

---

### 测试用例：FUNC-010

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

这个 NavDestination 不要转场效果

#### 预期输出

**验证标准**：

- 应命中 disableAnimation 分流 → 单页禁用（排除描述变体）
- 应输出 NavDestination 单页禁用配置指导
- 应明确作用域为单页（NavDestination）
- 应与全局禁用明确区分
- 不应因「不要转场」描述而误分流到 systemTransition(NONE) 以外的方案

**应包含**：disableAnimation, 单页, NavDestination  
**不应包含**：NavPathStack.disableAnimation

---

### 测试用例：FUNC-011

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

请禁用 Navigation 的转场动画

#### 预期输出

**验证标准**：

- 应命中 disableAnimation 分流 → 全局禁用（Navigation）
- 应输出 Navigation 全局禁用配置指导
- 全局禁用应通过 `NavPathStack.disableAnimation(true)` 实现
- 应明确作用域为全局（Navigation），影响所有页面跳转
- 应与单页禁用（NavDestination）明确区分
- 不应在全局禁用时仅在单个 NavDestination 上设置 systemTransition(NONE)

**应包含**：disableAnimation, NavPathStack, 全局  
**不应包含**：systemTransition(NONE)

---

### 测试用例：FUNC-012

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

全局关闭转场

#### 预期输出

**验证标准**：

- 应命中 disableAnimation 分流 → 全局禁用（全局关闭描述变体）
- 应输出 Navigation 全局禁用配置指导
- 应明确作用域为全局（Navigation）
- 应与单页禁用明确区分
- 不应因「全局关闭」描述而误分流到单页禁用

**应包含**：disableAnimation, 全局  
**不应包含**：systemTransition(NONE)

---

### 测试用例：FUNC-013

**skill**：hmos-arkui-navigation-transition  
**类型**：functional（功能验证）

#### 输入

给 NavDestination 配自定义转场，转场中要能交互

#### 预期输出

**验证标准**：

- 应触发 AC-3.2 边界引导：customTransition 含交互诉求 → 引导至 customNavContentTransition
- 应显式提示「customTransition 不可交互，customTransition 是页面级转场，无法在转场过程中响应交互」
- 应引导开发者使用整体可交互转场接口 customNavContentTransition（指向 AC-4.1 路径）
- 不应静默生成不可交互方案
- 应生成 `NavigationAnimatedTransition` 框架代码（含 transition 回调 + NavigationTransitionProxy）
- 应给出 transition 注册建议（全局注册或单例可访问）

**应包含**：不可交互, customNavContentTransition, NavigationAnimatedTransition  
**不应包含**：pageTransition
