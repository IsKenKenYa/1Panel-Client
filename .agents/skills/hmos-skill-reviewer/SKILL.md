---
name: hmos-skill-reviewer
description: Review and validate Agent Skills for compliance with Claude Skills specification. Use when evaluating SKILL.md files, checking naming conventions, validating content structure, or ensuring skills follow best practices. Provides comprehensive analysis of metadata format, content organization, progressive disclosure, and actionable vs knowledge-based content.
license: MIT
enable: true
publish: summary
metadata:
  author: harmonyos-dev-skills
  version: "1.1.0"
  created: "2026-03-17"
  updated: "2026-09-18"
  keywords: ["skill-review", "validation", "quality-assurance", "agent-skills"]
compatibility: Designed for Claude Code. Requires Bash and Python 3.8+ for automation scripts.
---

# Skill 审查专家

## 快速开始

本技能用于审查 Agent Skills是否符合Claude官方规范和鸿蒙应用开发skill最佳实践。

**核心能力:**
1. 格式规范性审查 - YAML frontmatter、命名、长度
2. 内容职责审查 - 区分 Skill(如何做)与知识库 (是什么)
3. 组织结构审查 - 渐进式披露、文件引用
4. 可操作性评估 - 工作流程、检查清单、决策树

---

## 输出

审查完成后只写 **JSON**，不要再写 Markdown 审查报告。
`title`、`message`、`suggestion`、`rationale` **必须用中文**（路径、枚举、字段名保持原样）。

```json
{
  "schema_version": "1.0",
  "skill": "hmos-skill-reviewer",
  "findings": [
    {
      "severity": "blocker | minor | nit",
      "file_path": "被审查 skill 的相对路径",
      "line_number": 1,
      "title": "问题标题",
      "message": "问题说明",
      "suggestion": "修复建议",
      "rationale": "判定依据"
    }
  ]
}
```

- `findings` 可为空数组（没有问题）。
- `title` / `message` / `suggestion` / `rationale` 用中文写；不要用英文句子。
- `rationale` 必填：写清对应哪条规范（或检查项），以及为什么算这个问题。
- `severity` 必须用流水线枚举，不能写 `critical` / `error` / `warning` / `info`。
- 本 skill 对应：Critical → `blocker`，Warning → `minor`，Info → `nit`。
- 不要输出通过 / 有条件通过 / 拒绝；流水线只看 `findings` 是否为空。

## 审查工作流程

### 阶段 1: 快速扫描

**步骤 1: 检查文件结构**
```bash
skill-name/
├── SKILL.md          # 必需
├── test-cases/       # 可选（有测试用例时必需，放在根目录）
├── scripts/          # 可选
├── references/       # 可选
└── assets/           # 可选（不含测试用例）
```

**检查项:**
- [ ] SKILL.md 是否存在
- [ ] 目录名与 name 字段一致
- [ ] 无深层嵌套
- [ ] test-cases/ 在根目录下（不在 assets/ 内）

**步骤 2: 提取元数据**
读取 YAML frontmatter，记录明显问题。

---

### 阶段 2: 格式规范性审查

#### name 字段审查

**规范要求:**
- 长度：1-64 字符
- 字符集：仅小写字母、数字、连字符
- 不能以 `-` 开头/结尾，无连续`--`
- 与目录名一致

**快速检查:**
```yaml
❌ Skill-Name        # 大写
❌ skill_name        # 下划线
❌ -skill            # 开头连字符
❌ skill--name       # 连续连字符
❌ my-skill-v2       # 版本号

✅ name: skill-name  # 正确
```

**判定:** 违反 → **Critical**

详细规则：[references/format-rules.md](references/format-rules.md#一 name 字段审查规则)

---

#### description 字段审查

**规范要求:**
- 长度：1-1024 字符 (推荐 150-400)
- 人称：第三人称
- 内容：what(做什么) + when(何时使用)

**优秀模板:**
```yaml
description: [动词 ing] [目标对象] for [目的]. 
Use when [场景 1], [场景 2], or [场景 3]. 
Provides [具体能力 1], [具体能力 2], and [具体能力 3].
```

**示例对比:**
```yaml
# ❌ 太简单 (15 字符)
description: Helps with PDFs.

# ✅ 优秀 (286 字符)
description: Extract text and tables from PDF files, fill forms, 
merge documents. Use when working with PDF documents or when the 
user mentions PDFs, forms, or document extraction. Provides 
structured output in JSON or Markdown format.
```

**检查项:**
- [ ] 使用第三人称
- [ ] 包含 what + when
- [ ] 长度合理
- [ ] 包含动作词

**判定:**
- 缺少 what 或 when → **Critical**
- <20 字符 → **Warning**
- >1024 字符 → **Critical**

详细规则：[references/format-rules.md](references/format-rules.md#二-description 字段审查规则)

---

#### 可选字段审查

**license (必填，必须为 MIT):**
```yaml
license: MIT
```

**检查项:**
- [ ] license 字段存在
- [ ] license 值为 `MIT`

**判定:**
- 缺少 license 字段 → **Critical**
- license 值非 `MIT` → **Critical**

**metadata (推荐):**
```yaml
metadata:
  author: your-name
  version: "1.0.0"
```

**compatibility (如有特殊要求):**
```yaml
compatibility: Designed for Claude Code. Requires Python 3.8+.
```

详细规则：[references/format-rules.md](references/format-rules.md#三 - 可选字段审查规则)

---

#### 文件大小审查

```bash
wc -l SKILL.md
```

**标准:**
- ✅ < 500 行
- ⚠️ 500-800 行
- ❌ > 800 行 (应拆分)

---

### 阶段 3: 内容职责审查

#### 核心判断框架

**问自己:**
```
这段内容是教 AI"做事"还是教"知识"?
- 教做事 (工作流程、步骤) → Skill ✅
- 教知识 (概念、理论) → 知识库 ❌
```

**快速识别知识库型内容:**
```markdown
❌ 出现以下词汇警惕:
什么是...
是指...
定义为...
...的历史
...的原理

❌ 典型句式:
## 什么是 ArkTS
ArkTS 是一种... (500 字理论)

## TypeScript 的发展历史  
TypeScript 诞生于... (300 字背景)
```

**应该移至 references/:**
- ❌ 长篇理论知识
- ❌ 完整的 API 文档
- ❌ 大量代码示例 (>10 个)
- ❌ 历史背景介绍

**应该保留在 SKILL.md:**
- ✅ 工作流程
- ✅ 检查清单
- ✅ 决策树
- ✅ 快速参考表

详细内容职责指南：[references/content-guidelines.md](references/content-guidelines.md)

---

#### 检查是否包含工作流程

**必须有清晰的步骤:**
```markdown
## Workflow

### Input
用户提供什么？

### Process
1. 第一步做什么
2. 第二步做什么
3. ...

### Output
最终交付什么？
```

**缺失工作流程 → Warning**

---

#### 检查是否包含检查清单

**示例:**
```markdown
## Checklist

### Critical (必须修复)
- [ ] 所有变量都有类型注解
- [ ] 未使用 any/unknown 类型

### Warning (建议修复)
- [ ] 热点循环已优化
- [ ] 避免了深层嵌套

### Info (可选改进)
- [ ] 命名风格统一
- [ ] 注释充分
```

**缺失检查清单 → Warning**

---

#### 检查是否包含决策树

**复杂 Skill 必须有决策树:**
```markdown
## Decision Tree

问题严重程度？
├─ 导致编译失败 → Critical
│   └─ 行动：必须修复
├─ 影响性能 → Warning
│   └─ 行动：建议修复
└─ 代码风格 → Info
    └─ 行动：可选改进
```

**复杂 Skill 无决策树 → Warning**

详细内容职责指南：[references/content-guidelines.md](references/content-guidelines.md#六 - 决策树设计模板)

---

### 阶段 4: 组织结构审查 (10-15 分钟)

#### 渐进式披露检查

**理想分布:**
```markdown
SKILL.md (<500 行)
├── 工作流程 (40%)
├── 检查清单 (25%)
├── 决策树 (15%)
├── 快速参考 (10%)
└── 参考文献引用 (10%)

references/ (按需加载)
├── concepts.md (理论知识)
├── api-reference.md (API 文档)
└── examples.md (大量示例)
```

**检查项:**
- [ ] SKILL.md < 500 行
- [ ] 详细内容在 references/
- [ ] 引用了 references/文件
- [ ] 引用只有一层深度
- [ ] 顶层目录仅包含 `SKILL.md`、`test-cases/`、`scripts/`、`references/`、`assets/`，不得有其他额外目录；`test-cases/` 是允许的顶层目录，不应报为违规

**组织错误:**
```markdown
❌ SKILL.md 包含完整 API 文档
→ 移至 references/api-reference.md

❌ SKILL.md 包含 50+ 示例
→ 精选 3-5 个，其余移走

❌ SKILL.md > 800 行
→ 必须拆分或移至 references/
```

---

#### 文件引用检查

**正确的引用:**
```markdown
详见 [类型规则](references/type-rules.md)
参考 [迁移指南](references/migration-guide.md)
```

**检查项:**
- [ ]引用的文件真实存在
- [ ] 路径正确 (相对路径)
- [ ] 避免深层嵌套 (>2 层)

---

### 阶段 5: 综合评估 (5-10 分钟)

#### 评分标准

| 维度 | 权重 | 评分 (1-5 分) |
|------|------|------------|
| 格式规范性 | 20% | ? |
| 内容职责 | 25% | ? |
| 可操作性 | 25% | ? |
| 组织结构 | 20% | ? |
| 创新性 | 10% | ? |
| **综合评分** | **100%** | **?** |

**5 分制标准:**
- 5 分：完全符合规范，可作为模板
- 4 分：基本合规，小问题
- 3 分：部分违规，需要改进
- 2 分：多处违规，需要较多改进
- 1 分：严重违规，需要重构

---

#### 审查结论判定

```markdown
✅ 通过 (可以直接合并)
条件:
- 综合评分 ≥ 4.0
- 无 Critical 问题
- Warning 问题 ≤ 3 个

⚠️ 有条件通过 (修复后可合并)
条件:
- 综合评分 3.0-3.9
- Critical 问题 ≤ 2 个
- 修复所有 Critical 问题后合并

❌ 拒绝 (需要重大重构)
条件:
- 综合评分 < 3.0
- Critical 问题 > 2 个
- 内容职责评分 ≤ 2 分
```

---

**自动化检查工具:**

### Bash 脚本 - 快速格式检查
```bash
./scripts/check-skill-format.sh skills/*/SKILL.md
```

### Python 脚本 - YAML 深度验证
```bash
python scripts/validate-frontmatter.py skills/*/SKILL.md
```

**推荐工作流:**
1. 运行自动化脚本
2. 修复发现的问题
3. 请求 AI 审查
4. 查看 JSON 结果

---

## 参考文档

### 核心规则
- [格式审查详细规则](references/format-rules.md) - 所有格式检查项详解 (537 行)
- [内容职责审查指南](references/content-guidelines.md) - Skill vs 知识库区分 (700 行)

### 案例学习
- [examples.md](assets/examples.md) - 3 类典型案例深度解析

### 自动化工具
- `./scripts/check-skill-format.sh` - Bash 快速格式检查
- `./scripts/validate-frontmatter.py` - Python YAML 深度验证

### 外部资源
- [Agent Skills Specification](https://agentskills.io/specification)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)

---

## 测试用例格式规范

Skill 的测试用例由 `hmos-skill-test-runner` 自动发现并执行。测试用例目录必须命名为 `test-cases/`，放在 skill 根目录下（与 `SKILL.md` 同级），不得放在 `assets/` 或其他子目录中。

### 目录与文件结构

```
skill-name/
├── SKILL.md
└── test-cases/
    ├── trigger.md       # 触发验证（必需）
    ├── smoke.md         # 冒烟测试 / 路由验证（可选，路由型 skill 才需要）
    └── functional.md    # 功能性测试（必需）
```

### 用例文件格式

每个文件为 Markdown 格式，多条用例之间以 `---` 分隔，每条用例以 `### 测试用例：` 开头。每条用例包含三部分：**基本信息**、**输入**、**预期输出**。

#### 触发验证（trigger.md）

验证 skill 是否在正确场景被触发。

```markdown
### 测试用例：TRIGGER-001

**skill**：{skill_name}（必填）  
**类型**：trigger（触发验证）

#### 输入

{prompt}

#### 预期输出

**应触发**：是（必填，`是` 或 `否`）

---

### 测试用例：TRIGGER-002

**skill**：{skill_name}（必填）  
**类型**：trigger（触发验证）

#### 输入

{prompt}

#### 预期输出

**应触发**：否（必填，`是` 或 `否`）
```

#### 冒烟测试（smoke.md，可选）

仅路由型 skill 需要。验证场景路由是否正确命中。

```markdown
### 测试用例：SMOKE-001

**skill**：{skill_name}（必填）  
**类型**：smoke（路由验证）  
**阶段**：{DEV/REQ/FIX}（选填）

#### 输入

{prompt}

#### 预期输出

**应命中场景**：{scene_id}（必填）  
**禁止命中场景**：{scene_id}, {scene_id}（必填，逗号分隔）  
**阶段**：{phase}（选填）
```

#### 功能性测试（functional.md）

验证 skill 的核心功能是否正确执行。

```markdown
### 测试用例：FUNC-001

**skill**：{skill_name}（必填）  
**类型**：functional（功能验证）

#### 输入

{prompt}

#### 预期输出

**验证标准**：（必填，每条一个独立检查点，逐条判定通过/失败）

- {验证点1}
- {验证点2}
- {验证点3}

**应包含**：{可选，逗号分隔}（选填）  
**不应包含**：{可选，逗号分隔}（选填）  
**格式**：{可选}（选填，markdown/json/yaml/csv）  
**应生成文件**：{可选，逗号分隔}（选填）
```

### 审查检查项

- [ ] `test-cases/` 目录位于 skill 根目录下
- [ ] `trigger.md` 文件存在
- [ ] `functional.md` 文件存在

详细模板参考：[hmos-skill-test-runner](../hmos-skill-test-runner/SKILL.md) 的 references 目录。

---

**常见反模式:**

### 反模式 1: 知识库伪装成 Skill
```markdown
❌ 表现：全是理论知识，无可操作性
✅ 修复：重写为任务导向，添加工作流程
```

### 反模式 2: 描述过于宽泛
```markdown
❌ 表现：description 太简单
✅ 修复：包含 what + when + how
```

### 反模式 3: 缺少决策逻辑
```markdown
❌ 表现：只有步骤，无判断
✅ 修复：添加决策树
```

### 反模式 4: 检查清单不可操作
```markdown
❌ 表现："代码质量好"
✅ 修复："所有变量都有类型注解"
```

### 反模式 5: ❌ 项目结构混乱 (新增!)
```markdown
❌ 错误结构:
skill-name/
├── SKILL.md
├── README.md                ← 不应该在根目录
├── examples.md              ← 不应该在根目录
├── assets/
│   └── test-cases/          ← 测试用例不应放在 assets 下
└── references/

✅ 正确结构:
skill-name/
├── SKILL.md                 ← 唯一根文件
├── test-cases/              ← 测试用例目录，放在 skill 根目录下
├── assets/                  ← 辅助资源（不含测试用例）
│   ├── README.md
│   └── examples.md
├── references/              ← 参考文档
└── scripts/                 ← 自动化脚本
```

> **注意**: 测试用例目录 `test-cases/` 必须放在 skill 的根目录下，不要放在 `assets/` 或其他子目录中。`test-cases/` 的命名和格式要求详见下方「测试用例格式规范」。

详细案例：[assets/examples.md](assets/examples.md)

---

## 总结

本技能聚焦于事实和规范，基于:
- ✅ Agent Skills开放标准
- ✅ Anthropic官方Skills 仓库
- ✅ 社区最佳实践

**审查原则:**
1. 格式规范零容忍 - 违反必须修复
2. 内容职责严把关 - 知识库不做 Skill
3. 可操作性为核心 - 必须有工作流程
4. 渐进式披露为优 - 合理组织内容

**目标:** 帮助创建高质量、可复用、易维护的 Agent Skills!
