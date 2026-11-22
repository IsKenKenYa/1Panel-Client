# Navigation Transition Test Prompts

用于验证 `hmos-arkui-navigation-transition` 的三层测试能力（smoke / scene-functional / real-world），覆盖 SKILL.md 中 systemTransition、customTransition、customNavContentTransition、disableAnimation 四类分流场景及异常处理。

> **对应文件结构**：
> - `smoke/smoke-navigation-transition.json` — 14 个冒烟测试用例（路由验证）
> - `scene-functional/scene-functional-navigation-transition.json` — 12 个场景功能测试用例（DEV 阶段正向功能）
> - `real-world/real-world-navigation-transition.json` — 5 个真实场景边界/异常用例（边界引导 + 异常处理）

---

## 1. Smoke Prompts（14 个 — 路由验证）

> Smoke 测试目的：验证 SKILL 三级决策树能否正确命中所有 4 类分流场景及异常处理，覆盖全部 14 个实际测试用例。

### systemTransition DEV 路由 — 系统默认转场标准描述

给 NavDestination 页面添加系统默认转场动画。

**预期命中**：`systemTransition`
**覆盖用例**：`NT-SMOKE-001` → `NT-FUNC-001`

### systemTransition DEV 路由 — 口语化描述

我想用系统自带的转场效果。

**预期命中**：`systemTransition`
**覆盖用例**：`NT-SMOKE-002` → `NT-FUNC-002`

### systemTransition DEV 路由 — 指定枚举值

添加系统转场，枚举用默认值。

**预期命中**：`systemTransition`
**覆盖用例**：`NT-SMOKE-003` → `NT-FUNC-003`

### customTransition DEV 路由 — 标准需求描述

请给 NavDestination 添加自定义转场动画。

**预期命中**：`customTransition`（无交互）
**覆盖用例**：`NT-SMOKE-004` → `NT-FUNC-004`

### customTransition DEV 路由 — 缩放淡入效果

给页面加一个缩放+淡入的转场动画。

**预期命中**：`customTransition`（无交互）
**覆盖用例**：`NT-SMOKE-005` → `NT-FUNC-005`

### customTransition DEV 路由 — 排除系统描述

页面转场用自定义动画，不要系统的。

**预期命中**：`customTransition`（无交互）
**覆盖用例**：`NT-SMOKE-006` → `NT-FUNC-006`

### customNavContentTransition DEV 路由 — 标准可交互描述

我要实现转场过程中可交互的动画。

**预期命中**：`customNavContentTransition`
**覆盖用例**：`NT-SMOKE-007` → `NT-FUNC-007`

### customNavContentTransition DEV 路由 — Navigation 配置描述

给 Navigation 配置可交互转场。

**预期命中**：`customNavContentTransition`
**覆盖用例**：`NT-SMOKE-008` → `NT-FUNC-008`

### customTransition→customNavContentTransition 边界引导 — 含交互诉求

给 NavDestination 配自定义转场，转场中要能交互。

**预期命中**：`customNavContentTransition`（由 AC-3.2 引导），关键词 `'自定义'+'交互'` → 边界触发 → 引导至 customNavContentTransition
**覆盖用例**：`NT-SMOKE-009` → `NT-REAL-001`（边界引导用例）

### disableAnimation DEV 路由 — 单页禁用标准描述

请禁用这个 NavDestination 的转场动画。

**预期命中**：`disableAnimation` → 单页禁用（NavDestination）
**覆盖用例**：`NT-SMOKE-010` → `NT-FUNC-009`

### disableAnimation DEV 路由 — 单页禁用排除描述

这个 NavDestination 不要转场效果。

**预期命中**：`disableAnimation` → 单页禁用
**覆盖用例**：`NT-SMOKE-011` → `NT-FUNC-010`

### disableAnimation DEV 路由 — 全局禁用标准描述

请禁用 Navigation 的转场动画。

**预期命中**：`disableAnimation` → 全局禁用（Navigation）
**覆盖用例**：`NT-SMOKE-012` → `NT-FUNC-011`

### disableAnimation DEV 路由 — 全局关闭描述

全局关闭转场。

**预期命中**：`disableAnimation` → 全局禁用
**覆盖用例**：`NT-SMOKE-013` → `NT-FUNC-012`

### 异常路由 — 需求描述为空

（空值，未提供需求描述）

**预期命中**：`exception` → empty_description
**覆盖用例**：`NT-SMOKE-016` → `NT-REAL-004`

---

## 2. Scene-Functional Prompts（12 个 — 场景功能验证）

> Scene-Functional 测试目的：验证每类分流场景的正向功能（DEV）的开发方案可落地，输出符合 solution_contract + execution_contract 的工程代码。
> 全部 12 个用例均为 DEV 阶段。

### NT-FUNC-001 系统默认转场配置

遵循 SKILL.md systemTransition 场景要求，为 NavDestination 配置系统默认转场动画（DEFAULT 枚举），参照 references/navigation-transition-api.md 签名与 templates/systemTransition.ets 模板完成代码。

**预期命中**：`systemTransition`
**资源引用**：`references/navigation-transition-api.md#systemTransition`、`templates/systemTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-002 系统转场口语化描述

验证口语化描述「系统自带」也能正确分流到 systemTransition，输出 `.systemTransition(DEFAULT)` 配置方案。

**预期命中**：`systemTransition`
**资源引用**：`references/navigation-transition-api.md#systemTransition`、`templates/systemTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-003 系统转场指定枚举值

验证开发者指定枚举值时输出与指定值一致，输出 `.systemTransition(DEFAULT)` 配置方案。

**预期命中**：`systemTransition`
**资源引用**：`references/navigation-transition-api.md#systemTransition`、`templates/systemTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-004 自定义转场框架代码

遵循 SKILL.md customTransition 场景要求，生成返回 NavDestinationTransition 数组的框架代码，代理函数签名为 (operation, isEnter) => Array<NavDestinationTransition> | undefined。动画初始值在 customTransition 回调体内同步赋值，动画结束值在 event 闭包内直接赋值（event 已在动画上下文中，禁止调用 animateTo），参照 templates/customTransition.ets 模板完成代码。

**预期命中**：`customTransition`（无交互）
**资源引用**：`references/navigation-transition-api.md#customTransition`、`templates/customTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-005 自定义转场缩放淡入效果

验证自定义转场框架代码中体现缩放与淡入效果逻辑：初始值在 customTransition 回调体内同步赋值，结束值在 event 闭包内直接赋值（操作 scaleValue/opacityValue 状态变量），event 内禁止调用 animateTo。

**预期命中**：`customTransition`（无交互）
**资源引用**：`references/navigation-transition-api.md#customTransition`、`templates/customTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-006 自定义转场排除系统描述

验证排除系统描述也能正确分流到 customTransition，且无交互时不引导至 customNavContentTransition。

**预期命中**：`customTransition`（无交互）
**资源引用**：`references/navigation-transition-api.md#customTransition`、`templates/customTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-007 可交互转场框架代码

遵循 SKILL.md customNavContentTransition 场景要求，生成 NavigationAnimatedTransition 框架代码（含 transition 回调 + NavigationTransitionProxy），并给出全局注册或单例可访问的 transition 注册建议。

**预期命中**：`customNavContentTransition`
**资源引用**：`references/navigation-transition-api.md#customNavContentTransition`、`templates/customNavContentTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-008 可交互转场 Navigation 配置描述

验证 Navigation 配置描述也能正确分流到 customNavContentTransition，生成框架代码并给出注册建议。

**预期命中**：`customNavContentTransition`
**资源引用**：`references/navigation-transition-api.md#customNavContentTransition`、`templates/customNavContentTransition.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-009 单页禁用配置指导

遵循 SKILL.md disableAnimation 场景要求，输出 NavDestination 单页禁用配置指导（systemTransition(NONE)），明确作用域为单页。

**预期命中**：`disableAnimation` → 单页禁用
**资源引用**：`references/navigation-transition-api.md#disableAnimation`、`templates/disableAnimation.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-010 单页禁用排除描述

验证排除描述也能正确分流到单页禁用，输出配置指导。

**预期命中**：`disableAnimation` → 单页禁用
**资源引用**：`references/navigation-transition-api.md#disableAnimation`、`templates/disableAnimation.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-011 全局禁用配置指导

遵循 SKILL.md disableAnimation 场景要求，输出 Navigation 全局禁用配置指导（NavPathStack.disableAnimation(true)），明确作用域为全局。

**预期命中**：`disableAnimation` → 全局禁用
**资源引用**：`references/navigation-transition-api.md#disableAnimation`、`templates/disableAnimation.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

### NT-FUNC-012 全局禁用全局关闭描述

验证全局关闭描述也能正确分流到全局禁用，输出配置指导。

**预期命中**：`disableAnimation` → 全局禁用
**资源引用**：`references/navigation-transition-api.md#disableAnimation`、`templates/disableAnimation.ets`
**参考文件**：`scene-functional/scene-functional-navigation-transition.json`

---

## 3. Real-World Prompts（5 个 — 边界引导 + 异常处理）

> Real-World 测试目的：模拟开发者真实交互中的边界场景和异常输入，验证 SKILL 能否正确引导或拒绝处理。
> 1 个边界引导用例 + 4 个异常处理用例。

### NT-REAL-001 自定义转场含交互诉求 — 边界引导

给 NavDestination 配自定义转场，转场中要能交互。排查并引导：customTransition 是页面级转场，无法在转场过程中响应交互，需引导至 customNavContentTransition。

**根因**：customTransition 返回的 NavDestinationTransition 数组仅在转场开始时执行 event 闭包，转场过程中用户无法交互
**修复策略**：显式提示不可交互 → 引导至 customNavContentTransition → 生成 NavigationAnimatedTransition 框架代码（isInteractive: true）
**资源引用**：`references/navigation-transition-api.md#customTransition`、`references/navigation-transition-api.md#customNavContentTransition`、`templates/customNavContentTransition.ets`
**参考文件**：`real-world/real-world-navigation-transition.json`

### NT-REAL-002 异常处理 — 文件路径不存在

请添加系统转场动画。（文件 NonExistentPage.ets 不存在）Skill 应输出无法处理提示并请求补充输入。

**根因**：文件路径不存在
**修复策略**：输出提示，请求提供有效文件路径
**参考文件**：`real-world/real-world-navigation-transition.json`

### NT-REAL-003 异常处理 — 文件无目标组件

给 NavDestination 配置系统转场。（文件 EmptyPage.ets 不含 NavDestination/Navigation）Skill 应输出无法处理提示并请求补充输入。

**根因**：文件存在但不含 NavDestination/Navigation 组件
**修复策略**：输出提示，请求提供含目标组件的文件
**参考文件**：`real-world/real-world-navigation-transition.json`

### NT-REAL-004 异常处理 — 需求描述为空

（空值，未提供需求描述）Skill 应输出无法处理提示并请求补充输入。

**根因**：需求描述为空
**修复策略**：输出提示，请求提供转场需求描述
**参考文件**：`real-world/real-world-navigation-transition.json`

### NT-REAL-005 异常处理 — 需求与转场无关

帮我修改按钮颜色。Skill 应输出无法处理提示并请求补充输入。

**根因**：需求描述与转场动画无关
**修复策略**：输出提示，请求提供转场相关需求描述
**参考文件**：`real-world/real-world-navigation-transition.json`

---

## 典型验证点

### systemTransition（3 smoke + 3 scene-functional）

- 是否命中 `systemTransition`
- 是否输出 `.systemTransition(NavigationSystemTransitionType.DEFAULT)` 配置方案
- 接入位置是否在 NavDestination 组件声明上（链式调用）
- 枚举取值是否以 references/navigation-transition-api.md 的 .d.ts 枚举值为准
- 方案是否与 ArkUI 官方开发指南逐条一致
- `smoke/smoke-navigation-transition.json` 对应 `NT-SMOKE-001`~`NT-SMOKE-003`
- `scene-functional/scene-functional-navigation-transition.json` 对应 `NT-FUNC-001`~`NT-FUNC-003`

### customTransition 无交互（3 smoke + 3 scene-functional）

- 是否命中 `customTransition`（无交互）
- 是否生成返回 `NavDestinationTransition` 数组的框架代码
- 代理函数签名是否为 `(operation: NavigationOperation, isEnter: boolean) => Array<NavDestinationTransition> | undefined`
- 回调结构是否完整（event/onTransitionEnd/duration/curve）
- 是否使用 `.customTransition(delegate)` 链式调用（非 pageTransition 方法覆写）
- 动画初始值是否在 customTransition 回调体内同步赋值（返回数组前对 `@State` 变量赋初值）
- 动画结束值是否在 event 闭包内直接赋值（event 运行在动画执行上下文中）
- event 闭包内是否调用 animateTo（**应禁止**——event 已在动画执行上下文，二次包裹会破坏转场动画）
- 状态变量名是否避开通用属性保留名（scale/opacity/translate/rotate 等）
- 无交互诉求时不引导至 customNavContentTransition
- `smoke/smoke-navigation-transition.json` 对应 `NT-SMOKE-004`~`NT-SMOKE-006`
- `scene-functional/scene-functional-navigation-transition.json` 对应 `NT-FUNC-004`~`NT-FUNC-006`

### customNavContentTransition 可交互（2 smoke + 2 scene-functional + 1 real-world）

- 是否命中 `customNavContentTransition`
- 是否生成 `NavigationAnimatedTransition` 框架代码
- 是否含 `transition` 回调（接收 `NavigationTransitionProxy` 参数）
- transition 回调中是否调用 `transitionProxy.finishTransition()` 结束转场
- 是否给出 transition 注册建议（全局注册或单例可访问）
- 注册建议是否明确全局/单例二选一并说明取舍
- `smoke/smoke-navigation-transition.json` 对应 `NT-SMOKE-007`~`NT-SMOKE-009`
- `scene-functional/scene-functional-navigation-transition.json` 对应 `NT-FUNC-007`~`NT-FUNC-008`
- `real-world/real-world-navigation-transition.json` 对应 `NT-REAL-001`（边界引导）

### disableAnimation（4 smoke + 4 scene-functional）

- 是否命中 `disableAnimation`
- 单页禁用（NavDestination）是否通过 `systemTransition(NONE)` 实现
- 全局禁用（Navigation）是否通过 `NavPathStack.disableAnimation(true)` 实现
- 是否明确区分单页禁用与全局禁用的作用域
- `smoke/smoke-navigation-transition.json` 对应 `NT-SMOKE-010`~`NT-SMOKE-013`
- `scene-functional/scene-functional-navigation-transition.json` 对应 `NT-FUNC-009`~`NT-FUNC-012`

### 异常处理（1 smoke + 4 real-world）

- 文件路径不存在时是否不产出任何方案并提示
- 文件无目标组件时是否不产出任何方案并提示
- 需求描述为空时是否不产出任何方案并提示
- 需求与转场无关时是否不产出任何方案并提示
- 提示是否指向具体缺失项
- `smoke/smoke-navigation-transition.json` 对应 `NT-SMOKE-016`
- `real-world/real-world-navigation-transition.json` 对应 `NT-REAL-002`~`NT-REAL-005`

### 三层验证要求

- `smoke`：验证三级决策树路由完整性——DEV 阶段直接命中 systemTransition / customTransition / customNavContentTransition / disableAnimation 四类分流；含交互诉求时触发 AC-3.2 边界引导至 customNavContentTransition；异常输入命中 exception 分支，共 14 个用例
- `scene-functional`：验证每类分流的正向功能（DEV）的工程方案可落地，输出 `solution_contract` + `execution_contract`，共 12 个用例
- `real-world`：验证边界引导（AC-3.2）和异常处理（AC-1.2）的输出正确性——边界引导必须显式提示 customTransition 不可交互并生成 customNavContentTransition 框架；异常处理必须不产出任何方案并输出指向具体缺失项的提示，共 5 个用例
- 所有 JSON 测试用例文件位于 `test-cases/` 目录下，通过自动化校验确保格式正确
- 资源映射关系：`references/navigation-transition-api.md`（四类 API 签名/枚举/官方指南条目）、`templates/systemTransition.ets`、`templates/customTransition.ets`、`templates/customNavContentTransition.ets`、`templates/disableAnimation.ets`
- **边界引导验证**：NT-SMOKE-009 / NT-REAL-001 须验证 Skill 显式提示「customTransition 不可交互」并引导至 customNavContentTransition，不静默生成不可交互方案
- **异常处理验证**：NT-SMOKE-016 / NT-REAL-002~005 须验证 Skill 不产出任何配置方案/框架代码，输出指向具体缺失项的无法处理提示
