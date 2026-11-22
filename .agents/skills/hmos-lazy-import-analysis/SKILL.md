---
name: hmos-lazy-import-analysis
description: 分析鸿蒙/OpenHarmony 应用源码与 redundant file 报告，识别可安全 import lazy 懒加载的模块，产出带完整证据链的修改建议，经 diff 预览确认后可机械应用改写。Use when 用户提供鸿蒙/OpenHarmony 应用源码和 redundant file 报告（hdc 从设备导出或本地 txt），要求识别哪些模块可以改为 import lazy 懒加载、分析模块顶层副作用、索取 lazy-import 修改建议、或在确认后应用这些修改。触发词：lazy import、lazy-import、模块懒加载、redundant file、冗余文件分析、启动耗时优化、模块加载开销、内存优化、应用 lazy 修改。
license: MIT
metadata:
  author: jiaoyusen
  version: "1.0.0"
  created: "2026-11-14"
  updated: "2026-11-16"
  keywords: ["lazy-import", "import-lazy", "redundant-file", "startup-optimization", "module-loading", "memory-optimization", "harmonyos", "hdc"]
compatibility: 需 python3 与 openpyxl（脚本缺库时自动 pip 安装）。设备拉取模式需 hdc（可用时自动扫描常见 SDK 位置）与 USB 连接的 HarmonyOS/OpenHarmony 设备；本地 txt 报告模式无额外设备依赖。改写语法 import lazy 需 SDK 版本支持（默认导入/命名空间导入随 SDK 版本而异，一律列为跳过+人工确认）。
---

# hmos-lazy-import-analysis：应用 import lazy 懒加载分析

## 概述

输入应用源码 + redundant file 报告，识别可安全懒加载的模块：脚本解析报表并做顶层代码检测，agent 读源码预判副作用，与用户批量确认后产出修改建议。**默认只产出建议；应用修改是可选的 Phase 6：向用户展示 diff，经确认后才把 `import lazy` 改写写入源码（治理重构仍人工实施）。**

## 前置依赖

- `python3` + `openpyxl`（脚本缺库时自动 pip 安装）
- `hdc`（仅设备拉取模式需要；不在 PATH 时脚本自动扫描常见 SDK 位置，如 DevEco Studio 安装目录）
- 应用源码根目录（含 `oh-package.json5` 的工程根，resolver 依赖它定位模块；HAP 型模块如 `entry`（`"main": ""`）已支持）

## 流程总览

```
Phase 0 输入收集 → Phase 1 报表生成(脚本) → Phase 2 候选识别(脚本)
→ Phase 3 副作用预判(agent读码) → Phase 4 批量确认(交互)
→ Phase 5 引用定位+建议报告(脚本+agent) → Phase 6 修改应用(可选, diff确认后脚本执行)
```

`{skill_dir}` 指本 skill 目录绝对路径。

## Phase 0：输入收集

向用户确认两项输入（一次问齐）：

1. **应用源码根目录**（resolver 定位模块必需）
2. **redundant file 来源**，二选一：
   - **设备拉取**：用户提供 app_name（如 `com.example.app`）。拉取由 Phase 1 脚本自动完成，无需手动执行 hdc；脚本失败（无设备/hdc 不可用）时会打印手动命令，届时再请用户处理
   - **本地文件**：用户提供 txt 路径

## Phase 1：报表生成（脚本）

```bash
python3 {skill_dir}/scripts/redundant_file_analyzer.py {app_name}        # 拉取模式(本地缺 txt 时自动发现 hdc 并拉取)
python3 {skill_dir}/scripts/redundant_file_analyzer.py --file {txt路径}   # 本地模式
```

产出 `{名称}_redundant_file_report.xlsx`（含 `Summary` / `Used Files` / `Unused Files` 三个 sheet）。向用户展示 Summary（总文件数、总耗时）与输出路径。

## Phase 2：候选识别（脚本）

先问用户两个参数（附默认值，用户可直接回车采纳）：

| 参数 | 默认 | 说明 |
|------|------|------|
| sheet | `Unused Files` | 也可选 `Used Files` |
| top N | `10` | 取耗时最高的前 N 个模块 |

```bash
python3 {skill_dir}/scripts/analyze_report.py {xlsx} --sheet "Unused Files" --top 10 --root {源码根} --cache {源码根}/lazy_cache.json
```

产出 `{app}_{time}.xlsx`（首列 `报表row`（=源表工作表行号，与 stdout 显示的 row 一致）+ `File Path`/`Cost Time`/`Parent Modules` + `has_toplevel` + `why`），stdout 有逐行 verdict 汇总。默认每次运行生成带时间戳的新快照（重跑不覆盖）；需固定文件名时加 `--out {路径}`。`报表row` 即 Phase 5 `--safe-rows` 应传入的行号。该表将经 `scripts/xlsx_to_md.py` 原样嵌入最终报告的「候选模块总表」。

**关键语义**（`has_toplevel` 列，与脚本 stdout 的 verdict **相反**，规则详见 `references/toplevel_rules.md`）：

| has_toplevel | 含义 | 去向 |
|--------------|------|------|
| `false` | 无顶层代码 | 天然可 lazy，直接进 safe 候选 |
| `true` | 有顶层代码 | 进 Phase 3 副作用预判 |
| `maybe` | 存疑（装饰器/不可解析包） | 进 Phase 3，按 `references/lazy_safety_rules.md` 细化 |
| `skip` / `unresolved` | .so / 系统模块 / 无法定位 | 跳过，报告中说明 |

> `--cache` 复用已判定 verdict，跨批次不重查；`--verdict`/`--ets-only` 可过滤重跑。

## Phase 3：副作用预判（agent 读码）

对 `has_toplevel=true/maybe` 的模块，**不调用任何脚本**，用 grep/read 直接读码：

1. 从 `why` 列拿到源头（源文件+行+片段），read 该文件核对
2. 追读被调函数/构造函数的实现
3. 按 `references/lazy_safety_rules.md` 判 **safe / critical / unknown**，每模块记录 `{模块, row, cost, 预判, 源头, 顶层代码片段, 被调实现, 命中规则, 依据}`。critical 对应官方副作用场景（C1 写 globalThis / C2 改 AppStorage 等应用级状态 / C3 全局注册订阅 / C4 改原型链内置对象 / C5 执行时机被他人依赖）；循环依赖 → 保守 unknown

**证据要求**（Phase 5 报告的「为什么可以/不可以 lazy + 证据」块直接引用本记录，必须当场取证、不得事后凭记忆补写）：

- `源头` = `{源文件}:{行号}`，`顶层代码片段` = read 核对后的**原文**（非转述）
- `被调实现` = 被调函数/构造函数的 `{文件}:{行号}` + 关键实现片段（或"空构造/纯返回值"等明确结论）；unknown 项写明不可达点（如仅 `.d.ets` 声明可见、循环依赖边）
- `命中规则` = safe 条款 / C1–C5 编号 / unknown 条目（对照 `references/lazy_safety_rules.md`）
- `has_toplevel=false` 的模块无需读码：证据记为"脚本闭包检测无顶层代码"，直接标 safe

**约束**：候选 > 20 个时先警告 token 消耗，用户确认后继续；可分批。

## Phase 4：批量确认（交互）

把全部候选整理成一张汇总表，通过 question 工具一次性呈现：

```
| row | 模块 | cost(ms) | has_toplevel | 预判 | 依据摘要 |
```

交互要点：

- **safe 项**：默认纳入建议，用户可剔除
- **critical / unknown 项**：默认排除，用户可强制纳入（记录其风险提示）
- 用户纠正预判时以用户为准，在最终报告中标注"用户判定"
- 汇总确认后得到最终 safe 行号清单

## Phase 5：引用定位 + 建议报告

**1. 定位引用点（脚本）**——对最终确认的 safe 行：

```bash
python3 {skill_dir}/scripts/gen_safe_importers_report.py {Phase2的xlsx} --safe-rows "{行号,逗号分隔}" --root {源码根}
```

产出 `safe_importers_*.xlsx`：每个 safe 模块 × 每个引用它的 parentModule 一行，含引用代码行、行号、`可lazy?`（按**引用行本身**判定：`export ... from` re-export → `暂不可(re-export)`；普通 `import ... from` → `可`。不按 parentModule 文件名判 barrel——`pages/Index.ets` 这类 `@Entry` 页面是普通使用方，其 import 可 lazy）。行号按 Phase 2 输出首列 `报表row` 回连，直接传 Phase 2 stdout 显示的 row 号即可。

**2. 导出脚本中间表为 markdown（脚本）**——最终报告要原样嵌入两张脚本中间表，**禁止手工转写**（防抄错行/列）：

```bash
python3 {skill_dir}/scripts/xlsx_to_md.py {Phase2的xlsx}                                  # 候选模块总表（全部行）
python3 {skill_dir}/scripts/xlsx_to_md.py {safe_importers的xlsx} --match "报表row={row}"   # 某模块的引用定位行（逐模块执行）
```

`--match 列名=值` 按列精确过滤（可重复）；超长单元格自动截断并在表后附注，完整数据以 xlsx 为准。

**3. 生成建议报告（agent）**——写 `lazy_import_suggestions_{date}.md` 到当前目录。章节沿用原格式，仅增补：概要后新增「候选模块总表」；逐模块小节增加「为什么可以 lazy + 证据 + 引用定位行」；排除模块逐个给出「为什么不可以 lazy + 完整证据」；原 `引用文件|行号|现语句|建议改为` 简化表删除（改写语法以文字说明保留）：

````markdown
# lazy-import 修改建议
## 概要：候选 N 个，确认 safe X 个，排除 Y 个（critical a / unknown b / 用户剔除 c）
## 候选模块总表（Phase 2 中间表）
| 报表row | File Path | Cost Time (ms) | Parent Modules | has_toplevel | why |
|---------|-----------|----------------|----------------|--------------|-----|
| {xlsx_to_md.py 输出原样粘贴；含 skip/unresolved 行；超长单元格截断处见表后附注} |
## 逐模块建议
### {模块名}（row {报表row}，cost Xms，判定：safe/用户判定，依据：一句话摘要）
**为什么可以 lazy**：{详细理由——has_toplevel=false → 脚本闭包检测无顶层代码；has_toplevel=true/maybe → 逐条说明顶层代码为何良性（纯分配/空构造/读设备信息…），对应 safe 条款}
**证据**：
- 源头：`{源文件}:{行号}`

  ```ets
  {顶层代码片段原文（read 核对）}
  ```

- 被调实现：`{文件}:{行号}`——{关键实现片段，或"空构造/纯返回值"等明确结论}
- 规则依据：{references/lazy_safety_rules.md 的 safe 条款}
**引用定位**（该模块在 Phase 5 中间表中的行，`--match "报表row={row}"` 输出原样粘贴）：
| 报表row | 模块(B) | 模块文件 | cost(ms) | parentModule | parentModule文件 | 引用代码行 | 行号 | 可lazy? |
|---------|---------|----------|----------|--------------|------------------|------------|------|--------|
| {…} |
（仅对「可lazy? = 可」的行给出改写；改写语法：`import { A, B } from 'mod'` → `import lazy { A, B } from 'mod'`）
## 排除模块的治理建议
### {模块名}（row {报表row}，cost Xms，判定：critical/unknown/用户剔除）
**为什么不可以 lazy**：{命中 C1–C5 哪一条、全局写入点在哪 / unknown 的不可达点 / 用户理由}
**完整证据**（不可 lazy 的模块必须给全，缺一不可）：
- 报表 why（Phase 2 `why` 列原文）：{…}
- 源头：`{源文件}:{行号}`

  ```ets
  {顶层代码片段原文（read 核对）}
  ```

- 被调实现：`{文件}:{行号}`——{被调函数/构造函数实现片段}
- 规则依据：{C1–C5 编号及描述，如 C2=修改应用级 ArkUI 状态}
**治理建议**：{官方替代模式：顶层副作用代码移入导出的 initialize() 函数、使用方显式调用；见 references/lazy_safety_rules.md「官方治理模式」}
## 跳过项及原因（barrel Index / 默认导入 / namespace / 已是 lazy 或 type / 非ets / 无法定位）
（Phase 2 表的 skip/unresolved 行 + Phase 5 表的 `暂不可(re-export)`/`待确认` 行，逐项列原因）
## 验证建议：改完后执行 hvigorw assembleHap 并观察启动耗时/模块加载
````

**4. 收尾与中间文件清理**：

- 告知用户 4 个最终产出物路径；提醒此刻尚未改任何源码——用户可选择按报告人工修改，或进入 Phase 6 经 diff 确认后由脚本应用
- Phase 2/5 重跑会产生带时间戳的旧快照（`{app}_*.xlsx`、`safe_importers_*.xlsx`）。列出本轮工作目录中全部此类文件，标记最终采用的各 1 份，**询问用户是否删除其余过期快照**（默认建议删除）；`lazy_cache.json` 一律保留（跨批次复用 verdict）

## Phase 6：修改应用（可选，先生成 diff → 用户选择 → 按计划应用）

**进入条件**：Phase 5 报告交付后，用户明确要求应用修改（agent 亦可主动询问是否应用）。**顺序不可绕过：先生成 diff（预览，不写源码），用户选择后再按计划应用；不存在"生成并一步应用"**——脚本 `--apply` 必须携带预览产出的计划文件，否则拒绝执行。

**范围**：仅 `可lazy? = 可` 行的机械改写（`import { A, B } from 'mod'` → `import lazy { A, B } from 'mod'`）。critical/unknown 的治理重构（initialize() 模式）属结构性代码变更，**不自动应用**，仍由用户按报告人工实施；跳过项同样不碰。

**1. 生成 diff 预览（脚本，默认模式）**——只生成、不写源码，产出 diff + 计划文件：

```bash
python3 {skill_dir}/scripts/apply_lazy_imports.py {最终采用的safe_importers的xlsx} --root {源码根} [--rows "{仅预览这些报表row}"]
```

脚本逐行校验：行号未越界、行内容与报告生成时一致（前 200 字符）、是普通 import（非 `import lazy` / `import type` / 同行多 import）；校验失败的行**排除在计划外并列出原因**——报告生成后源码若有变动，对应行不会盲改，提示重跑 Phase 5。输出：完整 unified diff、排除明细、计划文件 `lazy_apply_plan_{time}.json` 路径（记录拟改写的 文件:行号 与改写前后内容）。

**2. 用户选择（agent，交互）**——把 diff、排除明细与计划文件路径呈现给用户，通过 question 工具让用户**在看到 diff 之后**选择：

- **应用该计划**：进入第 3 步
- **调整范围后重新预览**：用 `--rows` 增删模块，重新生成 diff 与新计划文件，再回到第 2 步
- **不应用**：保留计划文件与报告，源码保持未改

**3. 按计划应用（脚本）**——只执行计划文件内容，不重新圈定范围：

```bash
python3 {skill_dir}/scripts/apply_lazy_imports.py --apply --plan {计划文件} --root {源码根}
```

脚本载入计划后逐行复核当前源码：与计划记录的原内容一致才写入；已等于改写后内容的行计"已应用过"；不一致的行跳过并提示重新预览。输出实际写入的 diff 与汇总。**无计划文件时 `--apply` 直接拒绝执行**，保证顺序不可绕过。

**4. 应用后验证与收尾**：

- grep 已应用文件确认 `import lazy` 已就位；对照脚本输出的"实际写入 N 行"逐文件核对
- 提醒用户执行 hvigorw assembleHap 构建验证并观察启动耗时；建议用 `git diff` 复查变更
- 计划文件保留可作应用记录，或经用户确认后删除；本 skill 不做任何 git 操作（不 add / commit / push）

## 交付前检查清单

产出建议报告（Phase 5）或应用修改（Phase 6）后，逐项自检：

- [ ] 4 个产出物路径已全部告知用户（Phase 1 报表 / Phase 2 中间表 / Phase 5 引用定位表 / 建议报告；若执行 Phase 6，另附 diff、排除明细与计划文件路径）
- [ ] 「候选模块总表」与逐模块「引用定位」均由 `xlsx_to_md.py` 原样嵌入，无手工转写
- [ ] 每个 safe 模块均含「为什么可以 lazy + 证据 + 引用定位行」
- [ ] 每个 critical / unknown 排除模块均附完整证据链（报表 why → 源头 `文件:行号` → 顶层代码原文 → 被调实现 → C1–C5 条目）
- [ ] 跳过项（skip / unresolved / re-export / 待确认）在报告中逐项列明原因
- [ ] has_toplevel 与脚本 verdict 语义未混淆（false = 无顶层代码、天然可 lazy；以 Phase 2 语义表为准）
- [ ] 未绕过 Phase 6 顺序：先 diff 预览 + 用户选择，再 `--apply --plan`；且仅改写「可lazy? = 可」行
- [ ] 过期时间戳快照（`{app}_*.xlsx` / `safe_importers_*.xlsx`）已列出并询问用户是否清理；`lazy_cache.json` 已保留
- [ ] 若已应用修改：grep 核对 `import lazy` 已就位，并已提醒用户执行 hvigorw assembleHap 构建验证

## 输出物

| 文件 | 来源 | 内容 |
|------|------|------|
| `{app}_redundant_file_report.xlsx` | Phase 1 | 结构化原始报表 |
| `{app}_{time}.xlsx` | Phase 2 | top-N + has_toplevel/why |
| `safe_importers_*.xlsx` | Phase 5 | 引用定位明细 |
| `lazy_import_suggestions_{date}.md` | Phase 5 | **最终交付：修改建议报告（逐模块为什么可/不可 + 完整证据 + 原样嵌入的 Phase 2/5 中间表）** |

## 常见错误

| 错误 | 后果/规避 |
|------|-----------|
| 混淆 has_toplevel 与脚本 verdict 语义（两者相反） | 误把"有顶层代码"当 safe。以本文件 Phase 2 的语义表为准 |
| `--root` 未指向应用源码根 | resolver 无法定位模块，大量 `unresolved`，候选全漏 |
| 误把文件名为 `Index.ets` 的 parentModule 当 barrel 而漏给建议 | 判据是**引用行**是否 `export ... from` re-export（脚本输出 `暂不可(re-export)`）；`pages/Index.ets` 这类 `@Entry` 页面内的普通 import 可 lazy |
| Phase 3 调用脚本"复核" | 脚本只判有无顶层，不判副作用，调用无意义且浪费；必须 agent 读被调实现 |
| 漏看 `why` 列直接凭模块名臆断 | 预判必须落到源头代码行与被调函数实现，有据可查 |
| 手工转写脚本表内容进报告 | 抄错行/列且无从核对；中间表必须用 `xlsx_to_md.py` 原样嵌入（模块行用 `--match "报表row={row}"`） |
| 不可 lazy 只给结论不给证据 | 报告不可复核；critical/unknown 必须附完整证据链（报表 why → 源头 `文件:行号` → 顶层代码原文 → 被调实现 → C1–C5 条目） |
| 未经预览与用户选择就改源码 | 越权；必须走 Phase 6：预览生成 diff+计划文件 → question 选择 → `--apply --plan`（无计划文件直接拒绝），且仅限 `可lazy?=可` 行 |
| 报告生成后源码已变动仍直接应用 | 行号漂移导致错改；预览按报告校验、应用按计划复核，内容不一致即排除/跳过，不得绕过 |
| 把 critical 治理重构（initialize() 模式）也自动应用 | 结构性代码变更超出机械改写范围，仅人工按报告实施 |

## 已知限制

- Phase 1 报表把 parentModule 列表拼入单单元格，超 Excel 32767 字符被截断（barrel Index 文件），引用定位可能不全
- 预编译 HAR 包（无 .ets 源码）→ 闭包层面 maybe / unknown，无法进一步判定
- 顶层检测为启发式（多行 const/let/var 初始化器已按括号配平累积整体分类；其余多行语句/嵌套表达式仍可能偏差）；存疑文件由 agent 按 `references/toplevel_rules.md` 复核
- 磁盘缓存 `lazy_cache.json` 带 `_version`（= `check_toplevel.DETECTION_VERSION`）：检测逻辑升级后旧缓存自动失效重查，跨版本不会复用过期 verdict
- 默认导入/命名空间导入的 lazy 语法支持随 SDK 版本而异，一律列入"跳过+人工确认"
- 嵌入报告的中间表超长单元格（如 barrel 文件的 Parent Modules 列）按 `--max-cell`（默认 200 字符）截断并附注，完整数据以 xlsx 为准
- 多行 import 语句（语句跨行书写）Phase 5 单行匹配不收录，Phase 6 亦不会应用，需人工处理
