# 初始化配置模板（可审计、透明）

本文件提供 Skill 自身完成项目初始化所需的配置文件模板与安全规则。所有内容对用户可见、可审查，**不依赖任何外部 Shell/PowerShell 脚本**。

---

## 安全规则（必读）

**本 Skill 禁止自动执行外部初始化脚本**（`scripts/init.sh` / `scripts/init.ps1`）。理由：

- 外部脚本由 Skill 提供方控制，可能被修改以包含任意命令（删除文件、下载后门等）
- **隐蔽数据窃取风险**：自动执行的脚本有机会读取项目目录及系统环境中的敏感文件（如 SSH/GPG 私钥、云凭证、`.env`/`.npmrc`/`.netrc` 等凭证文件、环境变量），并通过网络外发，整个过程对用户不可见
- 自动执行将构成严重的系统破坏与数据窃取风险
- PowerShell 调用若使用 `-ExecutionPolicy Bypass` 会进一步降低系统防护，为上述攻击提供便利

因此初始化逻辑内嵌于 Skill：使用 Skill 自身的文件工具（如 Write）逐个、透明地创建配置文件，仅写入预定义的配置路径，不读取凭证/密钥/环境变量，用户可在每一步前审查。

### 可选脚本的手动使用指引

`scripts/init.sh` / `scripts/init.ps1` 仅作为可选的命令行便捷工具提供，**不会**被 Skill 自动调用。如用户选择手动运行，应：

1. **先审查脚本完整内容**：
   - macOS/Linux：`cat <skill_root>/scripts/init.sh`
   - Windows：`Get-Content <skill_root>\scripts\init.ps1`
2. **确认无恶意行为后**手动执行：
   - macOS/Linux：`bash <skill_root>/scripts/init.sh`
   - Windows：`pwsh <skill_root>\scripts\init.ps1`（请勿使用 `-ExecutionPolicy Bypass`，除非已审查并理解风险）
3. **推荐**优先使用下文的内嵌初始化流程替代脚本

---

## 内嵌初始化步骤

当 `.deveco-flow/rules.md` 不存在时，由 Skill 自身透明完成初始化：

1. **解析路径**：将 `<skill_root>` 解析为绝对路径（路径分隔符统一为正斜杠 `/`）
2. **读取模板**：读取本文件获取各配置文件模板
3. **替换占位符**：用解析后的绝对路径、检测到的平台列表替换模板中的 `{{SKILL_ROOT}}`、`{{PLATFORM_LINES}}`、`{{PLATFORM_STR}}`
4. **逐个创建配置文件**（使用 Write 工具，写入前向用户说明文件路径与用途）：
   - `.deveco-flow/rules.md`（单一事实源）
   - `.claude/CLAUDE.md`（Claude Code 专用）
   - `.cursor/rules/deveco-flow.mdc`（Cursor 专用）
   - `.windsurfrules`（Windsurf 专用，使用哨兵标记幂等更新）
   - `opencode.json`（OpenCode 专用；若已存在则提示用户手动添加，不覆盖）
5. **创建前确认**：写入每个文件前，简要说明即将创建的路径与用途，给予用户审查机会

---

## 占位符说明

以下模板使用占位符，由 Skill 在写入前替换为实际值：

| 占位符 | 含义 | 示例 |
|--------|------|------|
| `{{SKILL_ROOT}}` | 本 Skill 安装目录的绝对路径 | `/Users/xxx/.config/opencode/skills/deveco-native-flow` |
| `{{PLATFORM_LINES}}` | 检测到的平台列表（每行一个） | `- HarmonyOS (build-profile.json5 detected)\n- Android (Gradle build detected)` |
| `{{PLATFORM_STR}}` | 平台逗号分隔字符串 | `HarmonyOS,Android` |

> 路径分隔符：在配置文件中统一使用正斜杠 `/` 以保证 Markdown/JSON 兼容性（Windows 平台同样适用）。

---

## 模板 1: `.deveco-flow/rules.md`（单一事实源）

```markdown
=== MANDATORY: DEVECO NATIVE FLOW — MULTI-PLATFORM DEVELOPMENT ===

This project uses the deveco-native-flow skill for three-platform development
(HarmonyOS/Android/iOS). The skill is self-contained with built-in HarmonyOS
ArkTS knowledge routing.

## Detected Platforms
{{PLATFORM_LINES}}

## How to Load Skills

This project uses the deveco-native-flow skill system. To reference sub-skills:
- **Claude Code**: Read `<skill_root>/references/<name>/SKILL.md`
- **Other AI tools**: Read the file at the path shown below and follow its instructions

### Skill Paths

| Skill | Path |
|-------|------|
| deveco-native-flow (main pipeline) | `{{SKILL_ROOT}}/SKILL.md` |
| Pipeline sub-skills | `{{SKILL_ROOT}}/references/native-analyse/SKILL.md` etc. |
| HarmonyOS knowledge (lang-syntax) | `{{SKILL_ROOT}}/references/lang-syntax/SKILL.md` |
| HarmonyOS components | `{{SKILL_ROOT}}/references/component_basic_ui/SKILL.md` etc. |
| HarmonyOS Kit APIs | `{{SKILL_ROOT}}/references/kits_<name>/SKILL.md` |
| HarmonyOS build-fix | `{{SKILL_ROOT}}/references/harmony-build-fix/SKILL.md` |
| HarmonyOS verify | `{{SKILL_ROOT}}/references/harmony-verify/SKILL.md` |

## HarmonyOS Knowledge Routing

When working on HarmonyOS platform:
1. Read the routing table in the main SKILL.md to identify which sub-skill to load
2. Read the appropriate references/<name>/SKILL.md for component/Kit knowledge
3. For syntax rules, read references/lang-syntax/SKILL.md
4. For knowledge search fallback, use the harmonyos_knowledge_search MCP tool

## VERIFY — Mandatory Self-Check

Before generating HarmonyOS/ArkTS code, confirm:
- [ ] Did I read the relevant references/<name>/SKILL.md for the component/Kit I'm using?
- [ ] Am I using loaded skill knowledge, NOT just my training data?
- [ ] Am I following ArkTS syntax constraints from references/lang-syntax/SKILL.md?

===
```

---

## 模板 2: `.claude/CLAUDE.md`（Claude Code 专用，精简版）

```markdown
=== DEVECO NATIVE FLOW — MULTI-PLATFORM DEVELOPMENT ===

This project uses deveco-native-flow for three-platform development.
The skill is self-contained with built-in HarmonyOS ArkTS knowledge routing.

Detected platforms: {{PLATFORM_STR}}

### Skill Paths

| Skill | Path |
|-------|------|
| Main pipeline | `{{SKILL_ROOT}}/SKILL.md` |
| HarmonyOS knowledge | `{{SKILL_ROOT}}/references/<name>/SKILL.md` |

### HarmonyOS Development Rules

Before coding HarmonyOS/ArkTS:
1. Read the routing table in the main SKILL.md
2. Read the relevant references/<name>/SKILL.md for component/Kit knowledge
3. Follow ArkTS syntax constraints from references/lang-syntax/SKILL.md
4. Do NOT answer from training data alone for ArkTS questions

===
```

---

## 模板 3: `.cursor/rules/deveco-flow.mdc`（Cursor 专用）

```markdown
---
description: Multi-platform development routing rules (HarmonyOS/Android/iOS)
globs: ["**/*.ets", "**/*.kt", "**/*.swift"]
alwaysApply: true
---

（此处嵌入与 `.deveco-flow/rules.md` 相同的正文内容）
```

> Cursor 的 `.mdc` 文件在 YAML front matter 之后追加与 `rules.md` 完全一致的内容。

---

## 模板 4: `.windsurfrules`（Windsurf 专用）

使用哨兵标记（sentinel）包裹，便于幂等更新：

```markdown

# === DEVECO NATIVE FLOW START ===
（此处嵌入与 `.deveco-flow/rules.md` 相同的正文内容）
# === DEVECO NATIVE FLOW END ===
```

> 若文件已存在且包含哨兵块，应先删除旧块再追加新块，避免重复。

---

## 模板 5: `opencode.json`（OpenCode 专用）

```json
{
  "instructions": [".deveco-flow/rules.md"]
}
```

> 若 `opencode.json` 已存在，**不要覆盖**，而是提示用户手动将 `.deveco-flow/rules.md` 添加到 `instructions` 数组中。

---

## 写入注意事项

1. **编码**：所有文件以 UTF-8 无 BOM 写入（Windows PowerShell 5.1 兼容）
2. **目录**：写入前确保父目录存在（`.deveco-flow/`、`.claude/`、`.cursor/rules/`）
3. **幂等性**：重复执行初始化时，`rules.md` 可覆盖；`.windsurfrules` 需先删除旧哨兵块
4. **透明性**：每个文件写入前向用户说明文件路径与用途，用户可在写入前审查模板内容
