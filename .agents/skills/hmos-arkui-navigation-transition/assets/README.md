# ArkUI Navigation/NavDestination 转场动画

`hmos-arkui-navigation-transition` 是指导开发者为 ArkUI Navigation/NavDestination 配置转场动画的 Agent Skill。它通过三级场景分流决策树，帮助开发者从 systemTransition、customTransition、customNavContentTransition、disableAnimation 四类方案中选型并接入，同时内置反模式警告和异常输入处理。

工作流程和约束以 [SKILL.md](../SKILL.md) 为准。

## 适用场景

| 场景 | 处理目标 |
| --- | --- |
| 系统转场 | 为 NavDestination 页面配置系统预设转场动画，选取 DEFAULT/NONE/TITLE/CONTENT/FADE/EXPLODE/SLIDE_RIGHT/SLIDE_BOTTOM 枚举值 |
| 自定义转场 | 为 NavDestination 页面配置自定义转场动画，通过 delegate 返回 `NavDestinationTransition` 数组实现缩放/淡入/平移/旋转等动画组合 |
| 整体可交互转场 | 为 Navigation 配置 `customNavContentTransition`，实现转场过程中可交互（如手势驱动逐帧更新进度）的动画效果 |
| 禁用转场 | 为 NavDestination 单页或 Navigation 全局禁用转场动画，明确区分作用域和适用 API |
| 异常与边界 | 处理文件缺失、组件缺失、需求为空或与转场无关的输入，避免臆造配置方案 |

覆盖 `systemTransition` 枚举选型、`customTransition` delegate 签名与动画赋值模式、`customNavContentTransition` 三种注册方式（全局注册/单例可访问/手势驱动可交互）、`disableAnimation` 单页 vs 全局禁用区分，以及 `pageTransition` 反模式、通用属性保留名冲突、possibly undefined 两层防护等编译错误预防。普通的页面路由跳转开发不属于本 Skill 的使用范围。

## 快速开始

### 准备输入

使用前提供以下信息，能够帮助 Agent 确定分流方案和配置代码：

- 包含 NavDestination 或 Navigation 组件的 `.ets` 文件路径。
- 转场需求描述（如配置系统转场、自定义转场、禁用转场、可交互转场等）。
- 是否有交互诉求（转场过程中是否需要响应手势或用户操作）。
- 作用域是单页（NavDestination）还是全局（Navigation）。
- 工程使用的 SDK/API 版本和需要保持的现有交互行为。

### 加载 Skill

在支持 Agent Skills 的助手中，引用 Skill 根目录的 [SKILL.md](../SKILL.md)，并保留完整目录，以便按需读取 `references/` 和 `templates/`。

### 提示词示例

**系统转场：**

```text
使用 hmos-arkui-navigation-transition Skill，给 NavDestination 页面添加系统默认转场动画。
枚举值用 DEFAULT 即可，接入位置在 NavDestination 组件声明上。
```

**自定义转场：**

```text
使用 hmos-arkui-navigation-transition Skill，给 NavDestination 添加自定义转场动画。
效果是缩放+淡入，缩放从 0.8 到 1.0，透明度从 0 到 1。
请提供 delegate 框架代码并确保动画赋值模式正确。
```

**整体可交互转场：**

```text
使用 hmos-arkui-navigation-transition Skill，为 Navigation 配置 customNavContentTransition。
需要转场过程中可交互，用手势驱动进度更新。
请提供 isInteractive: true 的手势驱动方案，含 PanGesture 驱动 proxy.updateTransition。
```

**禁用转场：**

```text
使用 hmos-arkui-navigation-transition Skill，禁用这个 NavDestination 页面的转场动画。
仅禁用该页面，不要影响其他页面跳转。
```

## 目录与参考文档

```text
hmos-arkui-navigation-transition/
├── SKILL.md                              # Skill 主文件：决策树、反模式、能力调度
├── assets/
│   └── README.md                             # 使用说明和调用示例
├── references/
│   └── navigation-transition-api.md      # 四类 API 的完整签名、枚举值与官方指南条目
├── templates/
│   ├── systemTransition.ets              # .systemTransition(枚举) 配置方案模板
│   ├── customTransition.ets              # 返回 NavDestinationTransition 数组的自定义转场框架模板
│   ├── customNavContentTransition.ets    # NavigationAnimatedTransition 整体可交互转场框架模板
│   └── disableAnimation.ets              # 单页/全局 disableAnimation 配置模板
└── test-cases/
    ├── test-prompts.md                   # 三层测试提示词（smoke/scene-functional/real-world）
    ├── trigger.md                        # 触发验证测试用例（正向/负向）
    ├── functional.md                     # 功能测试用例
    ├── smoke.md                          # 冒烟测试用例描述
    ├── smoke/
    │   └── smoke-navigation-transition.json          # 15 个冒烟测试用例（路由验证）
    ├── scene-functional/
    │   └── scene-functional-navigation-transition.json  # 12 个场景功能测试用例
    ├── real-world/
    │   └── real-world-navigation-transition.json    # 5 个真实场景边界/异常用例
    └── src/                                          # 测试工程源码
```

| 参考文档 | 何时阅读 |
| --- | --- |
| [API 参考](../references/navigation-transition-api.md) | 核对 systemTransition 枚举值、customTransition delegate 签名、customNavContentTransition 回调签名、disableAnimation API 归属 |
| [systemTransition 模板](../templates/systemTransition.ets) | 需要为 NavDestination 配置系统预设转场动画 |
| [customTransition 模板](../templates/customTransition.ets) | 需要为 NavDestination 配置页面级自定义转场动画 |
| [customNavContentTransition 模板](../templates/customNavContentTransition.ets) | 需要为 Navigation 配置整体可交互转场（含全局注册/单例/手势驱动三种方式） |
| [disableAnimation 模板](../templates/disableAnimation.ets) | 需要禁用单页或全局转场动画 |

## 四类分流方案速查

| 分流类别 | 归属组件 | 对应 AC | 决策树层级 | 关键 API |
| --- | --- | --- | --- | --- |
| 页面级 systemTransition | NavDestination | AC-2.1 | L3（系统转场） | `.systemTransition(枚举值)` |
| 页面级 customTransition | NavDestination | AC-3.1 / AC-3.2 | L3（自定义转场） | `.customTransition(delegate)` |
| 整体 customNavContentTransition | Navigation | AC-4.1 | L2（整体可交互） | `customNavContentTransition` 回调 + `NavigationTransitionProxy` |
| 禁用 disableAnimation | NavDestination / Navigation | AC-5.1 / AC-5.2 | L1（禁用分支） | 单页 `.systemTransition(NONE)` / 全局 `NavPathStack.disableAnimation(true)` |

## 反模式警告

本 Skill 内置三条强制检查项，违反会导致编译错误：

1. **`pageTransition` ≠ `customTransition`** — `pageTransition()` 是已废弃的 router 页面转场方法，`customTransition(delegate)` 是 NavDestination 链式属性方法，两者签名和用途完全不同，禁止混用（触发 `ArkTS:10505001`）。
2. **通用属性名不可用作 struct 成员名** — `scale`/`opacity`/`translate`/`rotate`/`position`/`offset`/`transform`/`visibility`/`zIndex` 等 ArkUI 通用属性方法名在 `@Component` struct 中是保留的，用作 `@State` 成员名会触发 `ArkTS:10505001`（触发 `ArkTS:10505001`）。
3. **possibly undefined 不可直接调用（两层防护）** — 类属性含 `| undefined` 时 `if` 守卫不收窄类型，需赋值给局部变量；接口可选方法（`updateTransition`/`cancelTransition`）必须用可选链 `?.` 调用（触发 `ArkTS:10605999`）。

## 验证与交付

转场动画配置完成后，应检查以下项目并执行真实工程的构建命令：

- 分流类别是否与需求语义唯一匹配（决策树路由唯一性）。
- API 归属是否正确（NavDestination 级 vs Navigation 级）。
- 动画赋值模式是否正确（初始值同步赋值、结束值在 event 闭包内赋值、禁止二次 `animateTo`）。
- `isInteractive: true` 时是否由手势驱动 `proxy.updateTransition` 而非 `animateTo`。
- 同时设置 `customNavContentTransition` 和 `customTransition` 时，Navigation 级优先。
- 生成代码是否命中三条反模式检查项（`pageTransition` 方法名、通用属性保留名、possibly undefined 调用）。

交付报告应包含分流类别、配置方案、接入位置、修改文件、保留的现有交互行为，以及实际执行的验证命令与结果。构建跳过或失败时，应明确说明原因。

测试场景见 [test-cases/test-prompts.md](../test-cases/test-prompts.md) 和 [test-cases/trigger.md](../test-cases/trigger.md)。前者提供三层测试提示词（smoke / scene-functional / real-world）覆盖全部 4 类分流场景及异常处理；后者提供 10 个触发验证用例（正向 7 个 + 负向 3 个）验证 Skill 触发判定的准确性。
