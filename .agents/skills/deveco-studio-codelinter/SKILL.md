---
name: deveco-studio-codelinter
description: 对 HarmonyOS（鸿蒙）项目运行 DevEco Studio CodeLinter 静态代码检查，解读检查结果并提供修复建议。支持 ArkTS、TS、JS 文件，涵盖性能、安全、代码规范、正确性、跨设备适配、API 兼容性等规则集。当用户提到 codelinter、code linting、鸿蒙代码检查、鸿蒙应用质量、HarmonyOS 代码质量检查、静态代码分析、规范扫描、性能检查、安全扫描、代码审查、规则检查、规则集、lint 报告时使用。
license: MIT
compatibility: Requires Node.js and DevEco Studio. Runs on Windows, macOS, and Linux; inspects HarmonyOS/ArkTS projects. Step 0b schema 提取需 adm-zip（npm 包）或 JDK jar 命令或 PowerShell 三者之一（脚本自动降级尝试）。
metadata:
  author: harmonyos-dev-skills
  version: "1.0.0"
---

# HarmonyOS CodeLinter 代码检查

> **强制规则**：当用户首次询问规则集、规则列表、规则数等信息时，**必须先执行 Step 0a + 0b 的脚本**，读取当前版本的实际 JSON 和 schema 数据，与 skill 文档对比后再回答。**禁止直接从文档中抄录表格回答**，因为不同 DevEco Studio 版本的规则集可能有差异。只有在脚本执行失败且用户无法提供 DevEco 路径时，才退化为使用文档中的数据，并明确告知用户"以下数据来自 skill 文档，未经当前版本验证"。
>
> **例外**：如果当前会话中已执行过 Step 0a + 0b 且结果与文档无差异，后续可直接引用文档数据，无需重复执行脚本。

## 工作流程

> **脚本速查**：本 skill 提供 6 个脚本，贯穿以下流程步骤：
> - `scripts/detect-codelinter.js` — Step 0a：探测 DevEco Studio 安装路径
> - `scripts/extract-schema.js` — Step 0b：提取当前版本规则集和规则数
> - `scripts/validate-config.js` — Step 2c：校验配置文件（规则集/规则名/路径）
> - `scripts/parse-result.js` — Step 4：基础解析（汇总 + 按文件分组 + 高频规则）
> - `scripts/analyze-results.js` — Step 4：深度分析（规则集分布 + 热点文件 + 修复优先级）
> - `scripts/extract-fixable.js` — Step 5a：从 HTML 报告提取可自动修复规则

### Step 0: 探测 DevEco Studio 并提取版本规则信息

**这一步必须在询问用户规则集之前完成**，以便展示当前版本实际可用的规则集和规则数。

#### 0a. 自动探测 DevEco Studio 安装路径

运行探测脚本[scripts/detect-codelinter.js](scripts/detect-codelinter.js)，找到后记录 `CODELINTER` 路径和 `DEVECO_HOME`：

```bash
# JSON 格式输出（便于脚本集成）
node scripts/detect-codelinter.js --json

# 指定自定义 DevEco 安装目录
node scripts/detect-codelinter.js --custom "D:/Tools/DevEco Studio"
```

探测脚本会依次检查（按优先级）：
1. `--custom` 参数指定的路径
2. `DEVECO_STUDIO_HOME` 环境变量
3. 平台标准安装位置（macOS `/Applications/`、Windows `%LOCALAPPDATA%\Huawei\`、`C:\Program Files\Huawei\` 等）
4. 在已知父目录中**递归搜索**（深度 3 层），匹配含 `deveco` 关键词的目录名
5. 全盘浅层搜索（仅 Windows，枚举 C~Z 盘符根目录，深度 2 层）

**支持的目录命名模式**：`DevEco Studio`、`DevEco-Studio`、`DevEco Studio865`、`deveco-studio-26.0.1.272`、`deveco-studio-26.0.1.272(.win)` 等所有含 "deveco" 关键词的变体。

**探测失败时**：
1. 脚本输出已搜索路径列表并退出（退出码 1）
2. 调用方（AI）使用 `question` 工具向用户索要 DevEco Studio 安装目录
3. 拿到路径后用 `--custom` 参数重新探测，或直接拼接 `<安装目录>/plugins/codelinter/run/index.js`

#### 0b. 提取当前版本的规则信息（版本特化适配）

探测成功后，运行[scripts/extract-schema.js](scripts/extract-schema.js)提取该版本实际支持的规则集和规则数：

```bash
# 输出当前版本的规则集统计和可用规则
node scripts/extract-schema.js "<DevEco安装目录>" --json
```

脚本读取三个数据源并合并为统一的规则视图：

| 数据源 | 路径 | 作用 |
|--------|------|------|
| ruleSet.json | `<DevEco>/plugins/codelinter/arkPerfCheck/ruleSet.json` | 各预设（recommended/all）包含的规则及级别 |
| code_linter_schema.json | `<DevEco>/plugins/openharmony/lib/ohos-resource-*.jar` 内 | 所有可在 `rules` 字段中使用的规则 |
| tsauditrules.json | `<DevEco>/plugins/codelinter/performanceAgent/tsauditrules.json` | 工具自动加载的规则，不区分 recommended/all，选了该规则集的任意预设就全部运行 |

脚本将以上数据源合并去重后按规则前缀（`@performance`、`@security` 等）归一输出，AI 据此向用户呈现统一的规则集总览，输出的表格第一行为“规则集前缀”、“检查内容”、“recommended”、“all”、“全部规则”、“典型使用场景”。

> **禁止向用户暴露内部实现细节**：不得在用户可见的回答中出现 "homecheck"、"HP Audit"、"HPAudit"、"ESLint 引擎"、"performanceAgent"、"eslintAgent"、"tsauditrules.json"、"两套引擎"、"引擎" 等术语。所有规则统一作为 "CodeLinter 规则集" 呈现，不区分来源。如需解释某规则为何自动生效，只说"该规则由工具自动加载"，不提引擎名或模块名。

**对比逻辑**：将脚本提取的当前版本规则数与 skill 的 `references/rules/*.md` 文档中的规则数对比：
- **一致**：正常展示，无需额外说明
- **不一致**：提醒用户当前版本的差异，例如"当前 DevEco 版本的 `@correctness/all` 有 X 条，skill 文档收录 Y 条，缺少 `<规则名>`，该规则在当前版本不可用"

---

### Step 1: 确定配置文件来源

> **用户指定单个文件时**：直接将该文件路径作为 `[dir]` 传入 Step 3 的命令，**不要**传项目根目录。codelinter 会自动定位文件所属工程并读取工程根的 `code-linter.json5`，但只扫描该文件而非整个项目。配置文件来源（Step 1）、规则集选择（Step 2）仍按下方流程进行；若用户未要求自定义规则，直接用项目配置即可，跳到 Step 3 传文件路径运行。

检查目标项目根目录下是否存在 `code-linter.json5`，根据情况走不同分支：

#### 情况 A：项目中已有 `code-linter.json5`

**使用 `question` 工具询问用户**：

```
question:
  questions:
    - question: "检测到项目中已有 code-linter.json5 配置文件。是否使用该配置文件进行检查？"
      header: "配置文件"
      options:
        - label: "使用项目配置 (推荐)"
          description: "直接使用项目根目录下的 code-linter.json5，其中已定义 ruleSet 和 rules。"
        - label: "自定义规则集"
          description: "忽略项目配置，重新选择规则集和规则。将生成临时配置文件，不修改项目原有文件。"
```

- 用户选择"使用项目配置" → **跳过 Step 2**，直接进入 Step 3，命令中使用默认配置文件路径
- 用户选择"自定义规则集" → 进入 **Step 2** 选择规则

#### 情况 B：项目中没有 `code-linter.json5`

直接进入 **Step 2** 选择规则。

---

### Step 2: 选择规则集并生成配置

#### 2a. 询问用户需要检查哪些规则集（可多选）

**先展示 skill 规则全集**作为参考（以下规则数同步自 [规则集索引](references/rules/index.md)，更新以该文件为准，实际以 Step 0b 脚本输出为准）：

| 规则集前缀 | 检查内容 | recommended | all | 全部规则 | 典型使用场景 |
|-----------|---------|:-:|:-:|:----:|------------|
| `@typescript-eslint` | ArkTS/TS 语法与类型安全 | 15 | 15 | 113  | 所有项目必选 |
| `@hw-stylistic` | 代码风格（缩进、命名、行长等） | 18 | 18 |  18  | 代码规范审查 |
| `@performance` | 性能优化（懒加载、状态变量、渲染优化等） | 15 | 35 |  74  | 性能调优 |
| `@security` | 加密算法安全（AES/RSA/Hash/SM 等） | 1 | 8 |  21  | 安全审计 |
| `@correctness` | 行为正确性（音频、无障碍、网络等） | — | 14 |  19  | 功能正确性验证 |
| `@cross-device-app-dev` | 跨设备适配（布局、字体、断点等） | 8 | 10 |  12  | 多设备支持 |
| `@compatibility` | API 兼容性（版本兼容、废弃 API 检查） | — | 1 |  2   | SDK 版本升级 |
| `@previewer` | Previewer 组件装饰器规则 | 3 | 3 |  3   | UI 预览调试 |

> 上表为 skill 规则全集（跨所有版本）。如 Step 0b 发现当前版本与上表有差异，**已在 0b 中提醒用户**。
>
> **`@private` 规则集不向用户展示**，涉及隐私合规内部策略，不在用户可选规则集中。
>
> **展示规则集表格时，对用户只使用"全部规则"这一列名**。禁止在用户可见的回答中出现 "schema"、"code_linter_schema.json"、"schema 全部规则" 等内部实现术语。该列含义为：当前可经 `rules` 字段逐条启用的规则总数（含预设内的），如需向用户解释，只用"全部规则 = 可经 rules 字段启用的规则总数（含预设内的）"表述，不提 schema。

每个规则集可选粒度：
- **`recommended`**：推荐规则子集，告警量适中，适合日常开发
- **`all`**：全量规则，适合严格审查（告警量较大）
- **预设外规则**：标注在"全部规则"列中超过 `all` 数量的规则，可通过 `rules` 字段逐条启用

> - `@typescript-eslint`：rec 与 all 相同（15 条），另有 98 条可经 `rules` 启用（含 `eqeqeq`、`prefer-const`）。
> - `@correctness`/`@compatibility` 无 recommended，仅 all。`@performance` 含 `hp-arkui-*`/`hp-arkts-*`/`hp-performance-*`/`hp-ffrt-*` 前缀规则，统一在 `@performance/` 下。
> - 部分安全规则（`no-unsafe-aes`、`no-unsafe-3des`、`no-cycle` 等）不在预设中，可通过 `rules` 单独启用。

#### 2b. 生成临时配置文件

**不要修改项目原有的 `code-linter.json5`**。将临时配置文件生成到临时目录：

```
<临时目录>/code-linter-temp.json5
```

> Windows: `C:\Users\<user>\AppData\Local\Temp\opencode\code-linter-temp.json5`
> macOS/Linux: `/tmp/code-linter-temp.json5`

配置文件内容示例：

```json
{
  "files": ["**/*.ets", "**/*.ts", "**/*.js"],
  "ignore": ["**/oh_modules/**", "**/build/**", "**/.preview/**", "**/node_modules/**"],
  "ruleSet": [
    "plugin:@typescript-eslint/recommended",
    "plugin:@performance/recommended"
  ],
  "rules": {}
}
```

**关键字段说明**：
- `files`：检查范围，使用 glob 模式
- `ignore`：排除目录，`oh_modules` 和 `build` 必须排除
- `ruleSet`：选中的规则集列表
- `rules`：在规则集基础上覆盖或新增单条规则（可选）
- `overrides`：对特定路径使用不同规则（可选，见 [配置示例](references/config-reference.md)）

> 完整配置字段与规则列表见 [配置示例](references/config-reference.md)

**后续命令中使用 `-c` 参数指向临时配置文件**，而非项目根目录的默认文件。

#### 2c. 校验配置（强制，不可跳过）

校验失败时停止执行，告知用户错误，不得继续运行 CodeLinter。生成配置后、运行 CLI 前必须校验：

```bash
node scripts/validate-config.js <配置文件> <工程根目录> <DevEco安装目录>
```

校验三项：规则集是否存在、规则名是否存在、工程目录是否存在。通过（退出码 0）→ 进入 Step 3；失败（退出码 1）→ 停止，修正后重新校验。

> CodeLinter 遇到不存在的规则集会静默通过（0 告警），导致用户误判代码无问题。

---

### Step 3: 运行 CodeLinter

命令格式：`node <codelinter入口> [options] [dir]`，`dir` 为待检查的**文件或目录**。传目录时扫描整个工程（受配置文件 `files`/`ignore` 约束）；传单个文件路径时仅扫描该文件，但 codelinter 仍会自动定位其所属工程并读取工程根的 `code-linter.json5` 作为规则来源。不指定时默认为当前目录。

Step 0a 已探测到 `CODELINTER` 路径，直接使用。根据 Step 1 的配置来源选择命令：

```bash
# 使用项目配置或临时配置（-c 指定配置文件，不指定则读取工程根目录 code-linter.json5）
node <CODELINTER> -c <配置文件路径> -f json -o <临时目录>/lint-result.json /path/to/project

# 仅检查 Git 增量文件（CI 场景常用）
node <CODELINTER> -i -f json -o <临时目录>/lint-result.json /path/to/project

# 检查并自动执行 QuickFix
node <CODELINTER> --fix /path/to/project

# 多 product 工程，指定 product
node <CODELINTER> -p default /path/to/project

# 仅检查单个文件（直接传文件路径，codelinter 自动定位所属工程并读取其 code-linter.json5）
node <CODELINTER> -f json -o <临时目录>/lint-result.json /path/to/project/entry/src/main/ets/pages/Index.ets
```

> **结果文件位置**：JSON/HTML 结果一律输出到**临时目录**（`<临时目录>/lint-result.json`/`lint-result.html`/`fixable-rules.json`），**不得写入用户工程目录**，避免污染仓库。后续解析脚本均读取临时目录中的文件。

**完整命令行参数与 `--exit-on` 退出码对照**：详见 [CLI 规范](references/cli-spec.md)。常用参数：`-c` 配置文件、`-f` 输出格式、`-o` 输出路径、`-i` 增量检查、`-p` 指定 product、`-e` 退出码级别、`--fix` 自动修复。

---

### Step 4: 解读 JSON 输出

> 向用户展示结果时必须使用 Markdown 表格，各环节表格列定义详见 [输出格式规范](references/output-format.md)。

CLI 的 `-f json` 输出为数组，按文件分组，每个文件含 `messages` 列表（字段：`filePath`/`line`/`column`/`severity`/`message`/`rule`）。severity 取 `error`/`warn`/`suggestion`，分别对应必须修复/强烈建议/可选优化。完整 JSON 结构与 severity 映射详见 [CLI 规范](references/cli-spec.md)。

#### 4a. 使用脚本解析结果（强制）

**禁止手动用 PowerShell/正则等方式解析 JSON 结果**。必须使用 skill 自带的脚本，确保解析逻辑统一、完整。

**`parse-result.js`** — 基础解析，生成可读报告：

```bash
# 文本报告（默认，按文件分组 + 高频规则 TOP 10）
node scripts/parse-result.js <临时目录>/lint-result.json --format text

# 仅汇总
node scripts/parse-result.js <临时目录>/lint-result.json --format summary

# JSON 结构化（供程序读取）
node scripts/parse-result.js <临时目录>/lint-result.json --format json
```

**`analyze-results.js`** — 深度分析，在 `parse-result.js` 基础上增加规则集分布、热点文件、修复优先级分类：

```bash
# 文本报告（默认，含修复优先级 + 规则集分布 + 热点文件）
node scripts/analyze-results.js <临时目录>/lint-result.json --format text

# Markdown 报告（含完整表格，适合展示）
node scripts/analyze-results.js <临时目录>/lint-result.json --format markdown

# JSON 结构化（供程序读取）
node scripts/analyze-results.js <临时目录>/lint-result.json --format json
```

**两个脚本的关系**：

| 脚本 | 用途 | 输出内容 |
|------|------|---------|
| `parse-result.js` | 基础解析 | 汇总 + 按文件分组的告警明细 + 高频规则 TOP 10 |
| `analyze-results.js` | 深度分析 | 汇总 + 修复优先级（紧急手动/手动） + 按规则集分布 + 热点文件 TOP 10 + 高频规则 TOP 10 + 紧急修复列表 |

> **关于可自动修复（QuickFix）的判断**：`analyze-results.js` **不再**通过内置静态名单判断规则是否可 `--fix` 自动修复。CLI 的 `-f json` 输出仅含 5 个核心字段（`line`/`column`/`severity`/`message`/`rule`），不含 `fixable` 标识；静态名单无法覆盖 DevEco 版本差异和 `.ets` 文件的实际 QuickFix 行为（实测 `@hw-stylistic/quotes` 在 `.ets` 上 `fixable=false`，而 `@performance/foreach-args-check` `fixable=true`，与直觉相反）。可自动修复项的判断由 **Step 5a 的 HTML 提取法**完成（`extract-fixable.js` 脚本）。

**脚本执行失败时的降级方案**：仅当脚本因 Node 版本或路径问题无法执行时，才允许 AI 手动解析 JSON，但必须在报告中注明"结果为手动解析，未经脚本验证"。

---

### Step 5: 提供修复建议

检查完成并汇总报告后，**必须先用 `extract-fixable.js` 从 HTML 报告提取 fixable 信息**，再向用户呈现**基于实际提取结果**的修复方案。

#### Step 5a：从 HTML 报告提取 fixable 信息（强制前置，不可跳过）

> 禁止跳过。未完成本步骤不得进入 Step 5b。

CLI 的 `-f json` 输出仅含 5 个核心字段（`line`/`column`/`severity`/`message`/`rule`），**不含 `fixable`**。`-f html` 报告内嵌完整 defect 对象（含 `fixable`/`fixKey` 等），是判断 QuickFix 的唯一数据源。在呈现修复方案前，**必须**执行：

1. 运行一次 HTML 格式的检查（**与 Step 4 的 json 检查同时或紧接进行，避免重复扫描**）：

```bash
node <CODELINTER> -c <配置文件> -f html -o <临时目录>/lint-result.html <工程目录>
```

2. 用 `extract-fixable.js` 提取 fixable 信息：

```bash
# 输出可修复规则 ID 列表（JSON 数组，供 analyze-results.js --fixable-rules 使用）
node scripts/extract-fixable.js <临时目录>/lint-result.html --format rules -o <临时目录>/fixable-rules.json

# 输出汇总（可修复/不可修复计数 + 规则列表）
node scripts/extract-fixable.js <临时目录>/lint-result.html --format summary

# 输出完整 defect 列表（含每条告警的 fixable 字段）
node scripts/extract-fixable.js <临时目录>/lint-result.html --format full
```

3. （可选）将 fixable-rules.json 注入 `analyze-results.js` 生成带 fixable 标记的深度报告：

```bash
node scripts/analyze-results.js <临时目录>/lint-result.json --fixable-rules <临时目录>/fixable-rules.json --format text
```

4. 据此向用户报告：

```
🔧 QuickFix 提取结果
━━━━━━━━━━━━━━━━━━━━
✅ 可自动修复：X 条
   - @performance/foreach-args-check（1 条）
🔧 需手动处理：Y 条
   - @hw-stylistic/quotes（3 条）
```

> `--fix` 对比法不可靠（实测 `--fix` 返回空数组但文件未修改），HTML 的 `fixable` 字段来自规则元数据，是准确数据源。HTML 报告约 390KB 但 `extract-fixable.js` 只提取末尾 JSON，性能不受影响。

#### Step 5b：呈现修复方案（强制调用 question 工具，不可跳过）

> **必须调用 `question` 工具呈现修复选项**。禁止用纯文本或其他方式呈现，禁止跳过。调用前必须已完成 Step 5a，拿到可修复条数 X 和需手动条数 Y。

根据 X、Y 选择对应情况调用 `question` 工具：

**调用 `question` 工具，question 字段必须引用实际探测结果（可修复 X 条 / 需手动 Y 条 + 具体规则名）：**

根据 X、Y 值选择选项组合：
- **X > 0 且 Y > 0**：选项含"--fix 自动修复 X 条，再手动处理剩余 Y 条（推荐）"、"仅 --fix 修复 X 条"、"全部 AI 辅助逐条修复"、"暂不修复"
- **X > 0 且 Y = 0**：选项含"--fix 自动修复（推荐）"、"AI 辅助逐条修复"、"暂不修复"
- **X = 0**：跳过 --fix 选项，选项含"AI 辅助逐条修复"、"暂不修复"

#### 方案 A：`--fix` 自动修复（QuickFix）

对 Step 5a 探测确认可自动修复的规则，追加 `--fix` 参数修复：

```bash
node <CODELINTER> -c <配置文件> --fix <工程目录>
```

- **优点**：快速、批量、无需人工干预
- **缺点**：并非所有规则都支持 QuickFix；复杂的重构类问题（如 LazyForEach 改造、状态变量优化等）无法自动修复，仍需手动处理
- **适用场景**：Step 5a 探测确认可修复的规则

#### 方案 B：AI 辅助逐条修复

对每条告警逐一处理，流程如下：

1. 按 🔴 error → 🟡 warn → 🔵 suggestion 优先级排序
2. 逐条读取对应文件的相关代码行
3. 给出**修复前/修复后代码对比**并说明原因
4. **等待用户确认后再写入文件**
5. 每条修复完成后，可重新运行检查验证该条已消除

```
// 修复前
ForEach(this.dataList, (item) => {
  ListItem() { ... }
})

// 修复后（使用 LazyForEach 实现按需加载）
LazyForEach(this.dataSource, (item) => {
  ListItem() { ... }
})
```

- **优点**：精确控制、可逐条验证、适合复杂重构
- **缺点**：耗时较长，需逐条确认
- **适用场景**：性能优化重构、安全算法替换、逻辑正确性修复等无法 QuickFix 的问题
- 可按**单条规则**批量修复，或按**单个文件**逐一修复，根据用户偏好决定

> **注意**：即使用户选择 `--fix` 自动修复，也应在修复完成后重新运行检查，确认剩余未修复的问题，并询问是否需要 AI 辅助处理剩余项。

---

## 检查清单

- [ ] 已探测 DevEco Studio 安装路径（Step 0a）
- [ ] 已提取当前版本 schema 和 ruleSet（Step 0b）
- [ ] 已检查项目根目录是否存在 `code-linter.json5`
- [ ] 如存在，已用 `question` 工具询问用户是否使用项目配置
- [ ] 如用户选择自定义规则集，已展示当前版本实际规则数并询问用户需要的规则集和粒度
- [ ] 如使用自定义规则集，已在临时目录生成配置文件（不修改项目原有文件）
- [ ] 配置文件已包含 `oh_modules` 和 `build` 排除路径
- [ ] 已用 `validate-config.js` 校验配置（规则集/规则名/路径），校验通过后才运行 CLI
- [ ] 已运行 CLI 并获取结果
- [ ] 已使用 `parse-result.js` 或 `analyze-results.js` 脚本解析结果（禁止手动解析 JSON）
- [ ] 已按优先级（error → warn → suggestion）汇总问题
- [ ] 向用户展示时已使用表格（表 2 汇总 + 表 3 问题清单），未用纯文本罗列
- [ ] 已用 `extract-fixable.js` 从 HTML 报告提取 fixable 信息（Step 5a）
- [ ] 已用表格展示 QuickFix 探测结果（表 4，含可修复/需手动两行）
- [ ] 已基于提取结果（可修复 X 条 / 需手动 Y 条 + 具体规则名）用 `question` 工具呈现修复方案
- [ ] 已与用户确认修复方式并执行
- [ ] 修复后重新运行检查验证问题已消除
- [ ] 已用表格展示修复前后对比（表 6，含全部三个级别行），新增告警已说明

---

## 决策树

整体流程的三条主线集中呈现如下，便于快速判断走哪条分支：

```
用户请求
  │
  ├─ 单文件？ ──是──→ 直接传文件路径作为 [dir]
  │                    ├─ 用项目配置 → 跳过 Step 2
  │                    ├─ 用户要求自定义规则 → 进入 Step 2 选择规则集
  │                    └─ 文件被 ignore 匹配？ → 用临时配置覆盖 ignore
  │
  └─ 整个项目？ ──→ Step 1 配置来源决策
                      │
                      ├─ 情况 A：项目有 code-linter.json5
                      │   └─ question 询问：使用项目配置 / 自定义规则集
                      │       ├─ 使用项目配置 → 跳到 Step 3（不传 -c）
                      │       └─ 自定义规则集 → Step 2 规则集选择
                      │
                      └─ 情况 B：项目无 code-linter.json5 → Step 2 规则集选择
                          │
                          Step 2 规则集粒度决策
                          ├─ recommended → 日常开发（告警适中）
                          ├─ all → 严格审查（告警量大）
                          └─ 预设外规则 → rules 字段逐条启用
                              └─ 生成临时配置到临时目录（不修改项目文件）→ Step 3

Step 3 运行 CLI（-f json + -o 输出到临时目录；需要 fixable 信息时额外 -f html）
  │
Step 4 解析结果（强制用脚本，禁止手动解析）
  ├─ parse-result.js → 基础汇总 + 按文件分组 + 高频规则 TOP 10
  └─ analyze-results.js → 深度分析（规则集分布 + 热点文件 + 紧急修复列表）
  │
Step 5 修复方式决策（基于 extract-fixable.js 从 HTML 报告探测的实际结果）
  ├─ 可修复 X > 0 且需手动 Y > 0 → question：--fix 修复 X 条 + 手动 Y 条 / 仅 --fix / 全手动 / 暂不修
  ├─ 可修复 X > 0 且 Y = 0 → question：--fix 自动修复 / 全手动 / 暂不修
  └─ 可修复 X = 0 → question：AI 辅助逐条修复 / 暂不修
```

---

## 常见问题

- **告警过多？** 用 `recommended` 而非 `all`；可在 `rules` 中将低优先级规则设为 `"off"` 或 `"suggestion"`。
- **只查特定目录？** 在 `files` 中指定路径，如 `["entry/src/main/ets/**/*.ets"]`。
- **不同模块不同规则？** 使用 `overrides` 字段，见 [配置示例](references/config-reference.md)。
- **CI/CD 门禁？** `--incremental` + `--exit-on error`，详见 [CLI 参数说明](references/cli-spec.md)。

---

## 参考文档

- [规则集详细说明](references/rules/index.md)
- [配置示例](references/config-reference.md)
- [输出格式规范](references/output-format.md)
- [CLI 规范](references/cli-spec.md)
- [测试用例](test-cases/functional.md)
- [HarmonyOS CodeLinter 官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-code-linter)
