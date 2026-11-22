# 优化 SKILL 调用与主动优化执行（harmonyos-memory-optimization-solution）

> **本文档职责**：**优化 SKILL 调用规范**（自 `optimization-workflow.md` 分离，该流程不再包含 SKILL 调用内容）+ 报告生成后的**主动优化执行步骤**（SKILL.md 步骤 7 的执行依据）。
> **输入**：对比报告 + 《案例匹配报告_<旧>_vs_<新>.md》中**匹配成功**的劣化场景（案例匹配规则见 `optimization-workflow.md` 子步骤 1；未匹配/部分命中的劣化源**不得**传入）+ 应用源码工程路径。
> **输出**：优化方案（SKILL 步骤 2）→ 经用户逐项确认后执行代码优化与构建验证（SKILL 步骤 3/4/5）。

## 1. 本地 SKILL 检查

检查本地是否存在 `harmonyos-memory-optimization-solution` SKILL（路径：`.claude/skills/harmonyos-memory-optimization-solution/`，位于 skills 根目录，**不是** `skills/MemoryOptimization/` 子目录）：

- **本地存在**：加载该 SKILL，将匹配成功的劣化源及其匹配场景 + 劣化根因 / 源码位置作为输入传入，由 SKILL 按「步骤 1（定位场景）→ 步骤 2（给出优化方案）→ 步骤 3（逐一询问用户确认）→ 步骤 4（执行优化）→ 步骤 5（构建并验证）」执行。
- **本地不存在**：按下方「远程安装流程」拉取（来源 GitCode `jiangwensai/AIAgentSkill`；优先方式一 skills CLI 安装，失败回退方式二 git sparse 部分克隆——sparse 方式已于 2026-09-22 实测可用）。

### 远程安装流程

**方式一（推荐）：`skills` CLI 安装**

GitCode 源经此 CLI 安装已实测可用（extract-concurrent 即经 `npx skills add https://gitcode.com/...` 安装）。注意本仓库为「根目录 SKILL.md（AIAgentSkill 自身是技能）+ 子目录技能」结构，与单技能仓库（如 extract-concurrent）不同，**必须 `--full-depth` 才能发现子目录技能**：

```bash
# 步骤 1 · 预检（必做）：只列出仓库中被发现的技能、不安装，确认列表含 harmonyos-memory-optimization-solution
npx --yes skills add https://gitcode.com/jiangwensai/AIAgentSkill.git --full-depth -l

# 步骤 2 · 询问开发者选择目标 Agent（必做，不得跳过）：
#   预检输出的技能列表同时列出本机检测到的所有 Agent 目录。
#   AI 必须用 AskUserQuestion 询问开发者要装到哪个 Agent，常见选项：
#     - .claude/（opencode / Claude Code）
#     - .cursor/（Cursor）
#     - .windsurf/（Windsurf）
#     - .trae/（Trae）
#   开发者也可指定其他 Agent 名称或"自定义"。
#   禁止默认装到所有 Agent——冗余副本会污染工程目录且难以清理。

# 步骤 3 · 安装（--full-depth 搜索子目录；-s 只装目标技能；--copy 落真实文件；
#   -y 跳过交互确认；-a <agent> 精准指定目标 Agent，不装到其他 Agent）：
# 不加 -g：装到工程级 <项目根>/.<agent>/skills/（-g 会装到用户级，不符合运行目录约束）
npx --yes skills add https://gitcode.com/jiangwensai/AIAgentSkill.git \
  --full-depth -s harmonyos-memory-optimization-solution --copy -y -a <agent>
```

CLI 说明：

- **安装前必须询问开发者选择目标 Agent**（步骤 2 硬性要求）：`-y` 跳过交互确认后，若不加 `-a <agent>` 则默认装到**所有检测到的 Agent**（实测会落到 45 个 `.<agent>/skills/` 目录），产生大量冗余副本。必须先询问开发者、获知目标 Agent 名称后，追加 `-a <agent>` 精准安装到单一目录。Agent 名称以预检输出的 CLI 交互提示为准（如 `claude`、`cursor`、`windsurf`、`trae` 等）。
- 若开发者未指定 Agent 或选"自定义"，默认装到 `.claude/`（opencode / Claude Code 通用识别位）。
- 安装产物与方式二等价：`<项目根>/.<agent>/skills/harmonyos-memory-optimization-solution/` 一层目录（安装名取 SKILL.md 的 `name` 字段，本技能与目录名一致）。
- **安装后清理校验（必做）**：执行 `ls -d .*/skills/harmonyos-memory-optimization-solution` 确认仅保留开发者选定的 Agent 目录；若发现多余副本，用 `rm -rf .<多余agent>/skills/harmonyos-memory-optimization-solution` 逐一清理，并检查空 skills 目录与空 agent 目录是否需一并 `rmdir`。

**方式二（回退）：git sparse 部分克隆**（方式一失败时使用：无 Node/npx 环境、CLI 不支持该源、网络受限等）

```bash
rm -rf /tmp/AIAgentSkill
# 部分克隆：--filter=blob:none 按需取 blob（仓库其余目录文件不下载），--depth 1 仅最新提交
git clone --depth 1 --filter=blob:none --sparse https://gitcode.com/jiangwensai/AIAgentSkill.git /tmp/AIAgentSkill
cd /tmp/AIAgentSkill
git sparse-checkout set MemoryOptimization/harmonyos-memory-optimization-solution
# 拷入 SKILL 运行目录（不携带 .git；目标目录名 = 技能名）
cp -R /tmp/AIAgentSkill/MemoryOptimization/harmonyos-memory-optimization-solution \
   <项目根>/.claude/skills/harmonyos-memory-optimization-solution
```

安装约束：

- **安装前必须询问开发者选择目标 Agent**（硬性约束，优先级最高）：`-y` 不加 `-a` 会装到所有检测到的 Agent（实测 45 个 `.<agent>/skills/` 目录），产生大量冗余副本且部分 agent 目录（如 `.tabnine/agent/skills/`）套了多层难以清理。必须先询问开发者选哪个 Agent，再用 `-a <agent>` 精准安装，安装后执行清理校验。开发者未指定时默认 `.claude/`。
- **运行目录固定为 `.claude/skills/harmonyos-memory-optimization-solution/`**（skills 根目录下，开发者选 `.claude` 时）。技能发现按 `.<agent>/skills/<目录名>/SKILL.md` 一层结构识别，多套一层 `MemoryOptimization/` 会导致技能不被发现（本仓 `.claude/skills/AIAgentSkill/MemoryOptimization/` 下的嵌套副本即不可被发现的冗余拷贝）
- **两种方式都必须先经过本节的本地存在性检查，目录已存在时禁止安装/覆盖**：skills CLI 对已存在同名目录的覆盖行为不可控；且远程为上游基础版（截至 2026-09-22 为 v1.0.0，仅离线 Web 组件 + Image 组件场景），本地若为扩展版（v1.5.0，额外含 lazyforeach/repeat/reusable/navigation/tabs/so_size/hap_size/taskpool/worker/longlist 方案），覆盖会丢失 worker/taskpool 等场景。此时先比对再决定合并：`/usr/bin/diff -rq <本地目录> /tmp/AIAgentSkill/MemoryOptimization/harmonyos-memory-optimization-solution`（本机默认 `diff` 是 DevEco toolchains 版，`-r/-q` 报错仍 exit 0，必须用绝对路径 `/usr/bin/diff`）
- **方式一必须 `--copy`**：CLI 默认在 `.claude/skills/` 下创建指向用户级中央缓存的 symlink 而非真实目录，后续本地扩展/目录比对会波及缓存副本，并影响其他工程的同名技能
- 方式一失败先回退方式二；两种方式均失败（网络不可达、GitCode 不支持 `--filter` 等）时，向用户说明并终止本子步骤，跳过 SKILL 调用，仅基于案例匹配结果输出（见 `optimization-workflow.md` 子步骤 2 的"无匹配"处理）。

## 2. 调用方式（传入参数）

将以下内容作为 ARGUMENTS 传入 SKILL（Skill 工具）：

1. **匹配成功的劣化场景清单**（来自《案例匹配报告》第一章，仅匹配成功项）：案例出处 + 劣化源（SO/差值）+ 判定证据摘要
2. **劣化根因与源码位置**：案例匹配的根因描述 + `文件:行号`（核查规则证据）
3. **应用源码工程路径**：SKILL 步骤 1 的代码库分析仅限该路径（数据范围硬约束，见 `optimization-workflow.md`）

SKILL 覆盖的优化场景包括：离线 Web 组件预渲染停止、离开 Web 页面加载空页面复用组件、应用退后台释放并回到前台恢复、低端机不预先创建离线组件、离线组件预加载个数限制、Image 组件降采样（autoResize）、Worker 数量过多收敛（worker 实例收敛至不超过 8 个，见 `cases/worker.md`）等。仅当劣化根因涉及上述场景时，SKILL 才会输出有效方案；不涉及时 SKILL 返回无适用方案。

## 3. 主动优化执行（报告生成后步骤）

> SKILL（harmonyos-memory-optimization-solution）自身的工作流在"给出方案"之后还有**逐一确认 → 执行优化 → 构建验证**三个主动阶段。`optimization-workflow.md` 产出的匹配报告只到"匹配结果"为止（不含 SKILL 调用，也不含优化建议）；**报告生成后**（对比报告 + 案例匹配报告落盘），按本节走完主动优化闭环。

### 3.1 前置条件（何时触发）

- 对比报告与《案例匹配报告_<旧>_vs_<新>.md》已落盘（SKILL.md 步骤 2~6 完成）
- 匹配报告第一章存在**匹配成功**的劣化源（无匹配成功项时跳过本步骤，不得对未匹配场景臆测优化）

### 3.2 执行流程

1. **调用 SKILL**：按第 2 节传入参数加载 harmonyos-memory-optimization-solution SKILL
2. **SKILL 步骤 1（定位场景）**：SKILL 在传入的源码工程路径内排查其覆盖的优化场景（离线 Web 组件 / Image 组件 / Worker 等），输出定位结果（文件路径 + 行号 + 已有优化措施判断）
3. **SKILL 步骤 2（优化方案）**：按 SKILL 参考文档对每个定位到的场景给出具体方案
4. **SKILL 步骤 3（逐一确认）**：SKILL 对每个命中的优化项**逐一询问用户**（AskUserQuestion，不批量确认）——用户可选"按方案优化 / 修改后优化 / 不优化"；这是 SKILL 内置硬性要求，AI 不得代答或跳过
5. **SKILL 步骤 4（执行优化）**：仅对用户确认的优化点执行代码修改，逐项核对符合 SKILL 核心约束
6. **SKILL 步骤 5（构建验证）**：构建应用并验证优化效果。**内存占用/释放恢复类验证不得在优化 SKILL 内自行执行**（hdc 采测等），须回到 hmos-memory-anti-regression 流程：以修改后构建重新出包（新 v3.hap），按 SKILL.md 步骤 1 采集流程做 A/B 对比采集 → 步骤 2 重新生成对比报告，确认劣化源差值收敛

### 3.3 验证闭环

主动优化完成后的复测对账口径：

| 对账项 | 优化前（v1 vs v2） | 优化后（v2 vs v3） |
|---|---|---|
| 劣化源差值 | 如 libbuffer_handle.z.so +2.33MB | 应收敛至 ≈0（或波动范围内） |
| DMA 调用栈差分 | 如 ION_Alloc 存活链 +2.33MB | 存活 ION 分配链差值应归零 |
| dmabuf 快照 | 未释放 buffer N 条 | 应归还（can_reclaim=1 的 buffer 释放后消失） |

复测结果回写：《案例匹配报告》文档末尾追加「复测记录」节（v3 标签、采集时间、差值对账表）；未收敛时回到 SKILL 步骤 1 重新排查。
