# ArkUI 深浅色适配与高性能切换

`hmos-arkui-dark-light-adaptation` 是用于分析和实施 HarmonyOS/OpenHarmony ArkUI 深浅色适配的 Agent Skill。它结合工程检查、按主题组织的参考文档和只读扫描脚本，帮助选择适配方式、处理高性能切换兼容性并验证结果。

工作流程和约束以 [SKILL.md](../SKILL.md) 为准。

## 适用场景

| 场景 | 处理目标 |
| --- | --- |
| 默认能力 | 检查系统组件、系统颜色和跟随系统设置，判断现有效果是否满足深浅色需求 |
| 自定义颜色 | 通过 base/dark 同名颜色资源和 `$r` 引用实现品牌色等精确配色，处理跨 HAP/HSP 资源访问 |
| 减少资源维护 | 结合业务反色算法与已有 dark 资源，评估可精简的颜色定义并完成必要接入 |
| 局部主题 | 使用 WithTheme 为目标组件或区域设置深色、浅色或跟随系统 |
| 高性能切换 | 检查版本和属性更新链路，修复兼容性问题、启用配置并验证切换开销 |

覆盖状态管理 V1/V2 中依赖颜色模式的属性更新、Native 反色接入及颜色资源优先级。普通网站的 CSS 深浅色、图片反色处理和通用换肤系统不属于本 Skill 的使用范围。

## 快速开始

### 准备输入

使用前提供以下信息，能够帮助 Agent 确定适配范围和验证方式：

- 工程根目录，或需要检查的 ArkTS 代码片段及相关配置、颜色资源。
- 任务目标：确认现状、提供方案或修改工程，以及允许修改的模块和页面。
- 工程使用的 SDK/API 版本、目标设备和可用的构建命令。
- 需要保留的配色与交互行为；遇到问题时提供当前表现和复现步骤。
- 涉及跨 HAP/HSP 资源或 Native 反色时，提供相关模块、导出方式和已有接入代码。

### 加载 Skill

在支持 Agent Skills 的助手中，引用 Skill 根目录的 [SKILL.md](../SKILL.md)，并保留完整目录，以便按需读取 `references/` 和运行 `scripts/`。

### 提示词示例

下面的页面名和颜色值可按实际需求替换。

**检查并适配深浅色：**

使用 hmos-arkui-dark-light-adaptation Skill，帮我适配当前工程首页所有 Text 组件的深浅色。系统默认配色不符合设计要求，请将浅色模式的文本颜色设为 #203040，深色模式设为 #DFCFBF，并跟随系统切换。

**启用高性能切换：**

使用 hmos-arkui-dark-light-adaptation Skill，当前工程切换深浅色时有些卡顿，帮我开启高性能深浅色切换，保证切换后页面颜色能正常更新。

**减少颜色资源维护：**

使用 hmos-arkui-dark-light-adaptation Skill，现在每加一种颜色都要在 base 和 dark 的 color.json 里各维护一份，工作量太大。帮我通过反色减少颜色资源维护，品牌色继续保留设计稿要求的深色配色。

## 工程扫描脚本

[scripts/scan_dark_light.py](../scripts/scan_dark_light.py) 使用 Python 标准库，需要 Python 3.9 或以上版本。从本 Skill 根目录执行：

```bash
# 查看帮助
python scripts/scan_dark_light.py --help

# 扫描工程，向标准输出写 JSON
python scripts/scan_dark_light.py "path/to/project"

# 仅扫描工程内的指定模块；可重复传入 --scope
python scripts/scan_dark_light.py "path/to/project" --scope entry
```

脚本收集版本、高性能开关、颜色资源、Native 配置调用、状态字段及属性绑定候选，不修改工程。它是词法扫描助手，不是完整的 ArkTS 语法解析器，不能单凭扫描结果判定整个工程兼容；仍需结合源码核对状态变化来源和属性更新路径。

## 目录与参考文档

```text
hmos-arkui-dark-light-adaptation/
├── SKILL.md
├── assets/
│   └── README.md             # 使用说明和调用示例
├── references/              # 按适配任务读取的主题参考
├── scripts/
│   └── scan_dark_light.py   # 只读工程扫描助手
└── test-cases/
    ├── trigger.md           # 触发与不触发验证
    └── functional.md        # 功能性测试输入与验证标准
```

| 参考文档 | 何时阅读 |
| --- | --- |
| [默认与资源适配](../references/adaptation.md) | 判断默认能力、配置 base/dark 颜色或访问跨 HAP/HSP 资源 |
| [局部主题](../references/local-theme.md) | 为组件或区域设置 WithTheme 深浅色作用范围 |
| [高性能切换](../references/high-performance.md) | 接入高性能开关、理解更新机制或通过 Profiler/trace 验证收益 |
| [属性更新兼容性](../references/compatibility.md) | 检查 V1/V2 属性更新，选择保留业务判断或统一资源名的修复方式 |
| [反色能力](../references/force-dark.md) | 接入 Native 反色、确认调用时机、资源优先级和可精简范围 |
| [API 与适配依据](../references/api-facts.md) | 核对能力版本、配置条件和官方文档来源 |

## 验证与交付

修改后执行环境可用的工程构建，并在设备上覆盖冷启动深色、浅转深和深转浅。涉及局部主题时检查作用范围；涉及反色时检查算法效果和 dark 资源优先级。性能对比优先通过 DevEco Studio Profiler 采集 trace；无法使用 Profiler 或需要脚本化采集时，可采用参考文档中的 hitrace 方式。

工程任务交付“深浅色适配报告”，包含适配结论、工程检查与改动、高性能切换说明和验证结果。区分静态检查、构建与设备实测，说明影响结论的验证缺口；纯概念答疑直接回答问题。

测试用例见 [trigger.md](../test-cases/trigger.md) 和 [functional.md](../test-cases/functional.md)，分别提供 2 条触发验证和 12 条功能用例。模型用例用于检查代码分析与方案输出；工程构建、设备效果和性能收益需另行验证。
