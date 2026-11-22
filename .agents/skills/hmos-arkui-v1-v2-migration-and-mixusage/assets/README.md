# ArkUI 状态管理 V1/V2 迁移和混用

`hmos-arkui-v1-v2-migration-and-mixusage` 是用于分析和实施 ArkUI 状态管理 V1/V2 迁移和混用的 Agent Skill。它结合工程盘点、按主题组织的参考文档和测试提示词，帮助在保留原有行为的前提下确定改造范围、处理兼容边界并验证结果。

工作流程和约束以 [SKILL.md](../SKILL.md) 为准。

## 适用场景

| 场景 | 处理目标 |
| --- | --- |
| 整仓迁移 | 将范围内应用自有 ArkTS 源码和模块迁移到状态管理 V2，保持组件契约、数据所有权和依赖一致 |
| 指定组件迁移 | 将目标组件迁移到状态管理 V2，并修改保证其正常工作的最小联动代码，明确与范围外状态管理 V1 代码的连接 |
| 状态管理 V1/V2 混用 | 明确状态管理 V1/V2 的交互边界，确认唯一数据源、读写方向、桥接所有者和 API 版本约束 |

覆盖组件装饰器和数据类、Provider/Consumer、应用级状态和持久化、ArkTS 卡片、动画时序、列表与复用、高级 UI 组件及 HAR/HSP 依赖。普通的状态管理 V2 功能开发不属于本 Skill 的使用范围。

## 快速开始

### 准备输入

使用前提供以下信息，能够帮助 Agent 确定改造范围和验证方式：

- 工程根目录，或需要处理的独立 ArkTS 代码片段。
- 任务模式：整仓迁移、指定组件迁移或混用方案设计。
- 允许修改的模块、文件和组件，以及必须保留的状态管理 V1 代码或公共契约。
- 工程使用的 SDK/API 版本、构建命令和需要保持的交互行为。
- 涉及外部 HAR/HSP 时，提供依赖及可用的公共导出信息。

### 加载 Skill

在支持 Agent Skills 的助手中，引用 Skill 根目录的 [SKILL.md](../SKILL.md)，并保留完整目录，以便按需读取 `references/` 和运行 `scripts/`。

### 提示词示例

**整仓迁移：**

```text
使用 hmos-arkui-v1-v2-migration-and-mixusage Skill，将当前工程的应用自有代码迁移到状态管理 V2。
范围包括 entry 和自有 library 模块，保持公共导出和现有交互行为。
请先盘点影响范围，再实施迁移，并执行工程现有的构建命令，报告结果。
```

**指定组件迁移：**

```text
使用 hmos-arkui-v1-v2-migration-and-mixusage Skill，只迁移 Child 组件到状态管理 V2。
Parent 保持状态管理 V1。保持点击 Child 后 Parent 与 Child 显示同步更新。
检查所有创建点和双向数据流，仅修改目标组件及必要的联动代码。
```

## 工程盘点脚本

[scripts/inventory.mjs](../scripts/inventory.mjs) 仅使用 Node.js 内置模块，需要 Node.js 20 或以上版本，无需安装 npm 依赖或编译。从本 Skill 根目录执行：

```bash
# 查看帮助
node scripts/inventory.mjs --help

# 输出工程迁移候选项清单，默认为 Markdown
node scripts/inventory.mjs "path/to/project"

# 同时列出指定组件的创建和引用候选位置，输出 JSON
node scripts/inventory.mjs "path/to/project" --component Child --format json
```

脚本在不修改工程的前提下，收集组件与装饰器、Provider/Consumer alias、storage key 证据、兼容 API、渲染结构和依赖候选项。它是词法盘点工具，不是 ArkTS 语法解析器或自动迁移器；修改源码前仍需确认扫描结果。

## 目录与参考文档

```text
hmos-arkui-v1-v2-migration-and-mixusage/
├── SKILL.md
├── assets/
│   └── README.md            # 使用说明和调用示例
├── references/              # 按任务主题读取的迁移和混用规则
├── scripts/
│   └── inventory.mjs        # 工程盘点工具
└── test-cases/
    ├── trigger.md           # 触发与不触发验证
    └── functional.md        # 功能性测试输入与验证标准
```

| 参考文档 | 何时阅读 |
| --- | --- |
| [决策与影响分析](../references/decision-and-impact-analysis.md) | 确定迁移模式、范围和需要一起修改的代码 |
| [组件与数据迁移](../references/component-and-data-migration.md) | 修改组件字段、输入输出契约、装饰器和数据类 |
| [状态管理 V1/V2 互操作](../references/interop.md) | 存在状态管理 V1/V2 数据或组件交互边界 |
| [应用级状态与存储](../references/storage-and-application-state.md) | 涉及 storage、Environment 或持久化 |
| [卡片迁移](../references/card-migration.md) | 涉及 ArkTS 卡片入口、刷新接收与共享状态 |
| [动画状态迁移](../references/animation-state-migration.md) | 涉及 `animateTo` 及动画前的状态更新 |
| [渲染、复用与高级组件](../references/rendering-reuse-and-advanced-components.md) | 修改列表渲染、复用机制或系统预置 UI 组件 |
| [依赖与构建](../references/dependencies-and-build.md) | 核对 HAR/HSP 导出、依赖适配和工程构建 |
| [官方文档查询路由](../references/official-doc-routing.md) | 已有规则不足以解决具体签名缺口、版本冲突或相关编译错误 |

## 验证与交付

迁移或混用改造后，应检查组件创建点、输入输出契约、数据所有权、状态管理 V1/V2 之间的双向更新、storage key 和依赖决定，并执行真实工程的构建命令。独立代码片段只报告实际完成的语法和语义检查。

实际执行工程迁移或混用改造后，默认在被迁移工程根目录生成 `reports/migrations/<任务标识>.md`，作为正式交付物，对话中仅输出摘要与报告链接；报告结构、留档与失败说明等完整契约见 [SKILL.md 的“迁移报告与交付”](../SKILL.md#迁移报告与交付)。仅讨论方案、诊断问题或回答独立代码片段时，默认在对话中报告；用户另有要求时按要求执行。

测试用例见 [trigger.md](../test-cases/trigger.md) 和 [functional.md](../test-cases/functional.md)，分别提供触发验证及功能性测试的输入与预期输出。功能测试采用独立代码片段和静态语义检查；完整工程的编译与设备行为验证由外部 Bench 承担。
