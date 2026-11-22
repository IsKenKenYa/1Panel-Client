---
name: deveco-studio-codescanner
description: 指导使用 codescanner 命令行工具扫描 HarmonyOS 工程（ArkTS 23 条 + C++ 27 条资源泄漏规则），覆盖参数用法、SDK 解析、规则配置（-c 白名单）、输出产物与退出码，解读 SARIF/HTML 扫描结果，并按权限/路径/JSON/引擎分类排查扫描问题。当用户提到 codescanner、code-scanner、code scanner、代码扫描，询问如何运行扫描或指定 SDK/输出/格式/规则配置，报告扫描报错、日志或退出码问题，询问结果解读或规则含义（如 WindowListenerNotOff、NapiWrap API Not Paired），或 codescanner 命令找不到、command line tools 在哪下载（tool-availability：仅 26.0.1+ 支持 codescanner 扫描）时使用。
license: MIT
metadata:
  author: harmonyos-dev-skills
  version: "1.0.0"
---

# Code Scanner Agent CLI Skill

> 本文档是 Skill 入口。知识库位于 `references/`，辅助脚本位于 `scripts/`，评测集位于 `test-cases/`。
> Skill 的目标不是代用户执行扫描，而是正确指导用户使用 CLI、解读结果、排查问题。

## 1. Skill 定位

| 能力 | 说明 |
|------|------|
| CLI 专业知识 | 参数、默认值、SDK 解析顺序、输出产物、退出码 |
| 结果解读 | SARIF 2.1.0 结构、C++/ArkTS 规则含义、HTML 报告 |
| 问题排查 | 日志定位、错误分类、权限/路径/JSON 三类高频失败 |

适用边界：
- 只回答与 **code-scanner / codescanner 命令行工具** 相关的问题。
- 不涉及 DevEco Studio 插件 UI 内部逻辑（除非需要定位插件调用 CLI 的问题）。
- 不代跑扫描：把命令交给用户执行，或按用户环境给出精确命令。

## 2. 术语与缩写

| 术语 | 说明 |
|------|------|
| SARIF | Static Analysis Results Interchange Format，静态分析结果交换格式（2.1.0） |
| ArkTS | HarmonyOS 应用开发语言，对应 homeflow 引擎 |
| C++ | C++ 源码扫描，对应 cpp-agent（codescanner-cpp）引擎 |
| compile_commands.json | 编译数据库，cpp-agent 的 `--scope` 输入 |

## 3. Trigger 与 Intent

### 3.1 Trigger（触发条件）

**权威定义在 frontmatter `description`**（大部分 agent 的激活/匹配只读 description；改触发逻辑时同步改 description 与本节，二者保持一致）。触发模式总览：

- 命中关键词：`codescanner` / `code-scanner` / `code scanner` / `代码扫描`（上下文明确指向 CLI）
- 意图触发：见 §3.2 Intent 表——任一 Intent 对应的提问模式命中即激活
- 兜底：提问未含工具名但上下文明确指向 codescanner 命令行工具（如正在讨论某次扫描报错）

激活后按 §4 工作流路由到对应知识库/脚本。

### 3.2 Intent（用户意图）

| Intent | 说明 | 核心动作 |
|--------|------|----------|
| `usage` | 询问如何使用 CLI | 给出参数/示例，见 `references/cli-spec.md` |
| `run-help` | 帮助用户构造扫描命令 | 收集 Slot → 组装命令 → 校验路径 |
| `explain-result` | 解读扫描结果 | 按 SARIF 结构解读 merged.sarif / report.html，规则含义查 `references/rules/index.md` |
| `troubleshoot` | 排查扫描报错 | 分类错误 → 查 `references/error-troubleshooting.md` |
| `rule-info` | 询问规则含义/配置 | 查 `references/rules/index.md` |
| `output-info` | 询问输出产物/格式/退出码 | 查 `references/exit-codes.md`、`references/cli-spec.md` |
| `tool-availability` | 工具缺失/未入 PATH/需要下载引导 | 见 `references/error-troubleshooting.md` §工具可用性 |

### 3.3 Slot（槽位）

| Slot | 说明 | 来源 |
|------|------|------|
| `projectPath` | 工程根目录（位置参数或 `-s` 之外的首个路径） | 用户输入 |
| `sdkPath` | SDK 目录（`-s/--sdkPath`） | 用户输入或默认解析 |
| `outputDir` | 输出目录（`-o/--output`，默认 `output`） | 用户输入或默认值 |
| `logDir` | 日志目录（`-l/--logPath`，默认 `scanner/logs`） | 用户输入或默认值 |
| `format` | 输出格式（`-f/--format`，`sarif`/`html`，默认 `sarif`） | 用户输入或默认值 |
| `ruleConfig` | 规则配置文件（`-c/--config`） | 用户输入 |
| `compileCommandsDir` | 含 compile_commands.json 的目录（`--compileCommandsDir`） | 用户输入 |
| `noCpp` | 关闭 C++ 检查（`--no-cpp`） | 用户输入 |
| `noArkts` | 关闭 ArkTS 检查（`--no-arkts`） | 用户输入 |

## 4. 工作流（Workflow）

按 Intent 路由，通用顺序：**确认环境 → 定位知识 → 给出可执行命令/结论 → 提示验证**。

### Step 0：确认环境（所有 Intent 可选执行）

只有影响结论时才询问：

1. 平台：Windows（.bat / 部署目录结构不同）还是 Linux（.sh、CRLF 问题）。
2. 运行方式：独立 CLI（`codescanner/` 目录，bin/codescanner）还是插件调用（dist/）。
3. 是否有多套安装导致 PATH 被旧版本抢占（历史教训：确认 `codescanner -v` 指向的目录）。

### Step 0.5：Command Line Tools 可用性检查（`tool-availability`，扫描前必做）

判断用户是否已具备可用的 command line tools（含 codescanner）：

- **判定方法**：让用户执行 `codescanner -v`（或 `where codescanner` / `which codescanner`）确认命令存在、指向期望部署，**且工具包版本 ≥ 26.0.1**——工具包版本以部署目录/安装包名中的 26.0.x 为准（`-v` 输出的 CLI_VERSION `1.0.0` 是 CLI 内部版本号，**不能**用于判定工具包版本）。
- **版本门槛（硬性要求）**：仅 **26.0.1 及以上版本** 的 command line tools 支持 codescanner 扫描功能；更早版本无 codescanner 或功能不完整，即使能执行也不可指导扫描。版本不符 → 引导升级/下载新版（见下）。
- **未安装或未入 PATH（`command not found`）时的处理**，二选一引导：
  - 用户已有离线包/部署目录 → 让用户**给出 command line tools 位置**（解压后根目录），据此给出绝对路径调用方式（无需配 PATH 也能用：`<工具根目录>/command-line-tools/codescanner/bin/codescanner`）。
  - 用户无工具 → 引导下载：[https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos) （HarmonyOS command line tools 官方下载页，下载即 26.0.x 最新版），下载解压后回到上一步给出位置。
- **判定表述**：回答时**两种标准错误文案都要点明**——Linux/macOS 为 `codescanner: command not found`，Windows cmd 为 `'codescanner' 不是内部或外部命令`（先点用户平台对应的形态，再补另一种对照）——然后按对应形态给出处理，勿只作单一转述。
- **配 PATH 指引**（可选）：Windows 把 `...\command-line-tools\bin` 加入 PATH；Linux 用 `export PATH=<工具根目录>/command-line-tools/bin:$PATH`。
- 检查 SDK（`-s` 缺省时按 §6-1 顺序解析）：工具自带 sdk/ 目录可用，或要求用户提供 SDK 位置。
- 已知多套安装风险：PATH 可能指向旧版本 → 引导用绝对路径 + `-v` 核版本，勿依赖 PATH。

### Step 1：按 Intent 路由

| Intent | 路由 |
|--------|------|
| `usage` / `run-help` | 读 `references/cli-spec.md`，组装命令，逐参数校验路径存在性；回答末尾**必须附带 Step 2 的 run-help 固定附注**（-c 全量/白名单语义 + 产物与日志位置） |
| `explain-result` | 解读 `merged.sarif` / `report.html` 中的 ruleId 命中，按级别+规则汇总 → 查规则含义 |
| `troubleshoot` | 定位日志（`references/error-troubleshooting.md` §日志位置），按错误表匹配 |
| `rule-info` | 读 `references/rules/index.md`，再按语言进 cpp-rules.md / arkts-rules.md |
| `output-info` | 读 `references/exit-codes.md` + `references/cli-spec.md` §输出产物 |
| `tool-availability` | 走 Step 0.5 工具可用性检查 → 引导安装/配置 PATH |

### Step 2：输出结论

- 给命令时：完整给出，不要用省略号；标注哪些参数可省略及省略后果。
- **run-help 固定附注（每次给出扫描命令后必须附带，不可省略）**：

  > 不传 `-c` 即检测全量规则（ArkTS 23 条 + C++ 27 条）；传 `-c` 为白名单语义——仅检测配置中 `skip: false` 的规则，未列出的自动跳过，会收窄检测范围。产物默认 `output/merged.sarif`（`-f html` 另有 `report.html`），日志默认 `scanner/logs/codescanner.log`。

- **给 `-c` 规则配置时（结构固定，禁止输出扁平 `rules` 数组）**：必须按 `rules.arkts` / `rules.cpp` 分引擎分组、组名 `ResourceLeak`，每条规则含 `ruleId` / `severity` / `skip` 三字段（完整说明见 `references/cli-spec.md` §3.5）：

  ```json
  {
    "rules": {
      "arkts": { "ResourceLeak": [ { "ruleId": "WindowListenerNotOff", "severity": "error", "skip": false } ] },
      "cpp":   { "ResourceLeak": [ { "ruleId": "NapiWrap API Not Paired", "severity": "error", "skip": false } ] }
    }
  }
  ```

- 排查时：先给错误分类（权限 > 路径 > JSON 格式，见 `references/error-troubleshooting.md`），再给修复步骤。
- 解读结果时：按严重级别（error/warning/note）+ 规则 ID 分组汇总，附规则文档链接。

### Step 3：验证（推荐）

- 扫描类：先在用户工程的小范围目录（或复制出的子工程）上跑通、确认参数与产物，再全量扫描；待 `test-cases/fixtures/` 落地最小 ArkTS+Cpp 样例工程后，也可先在其上验证（见 §8 Roadmap）。
- 排查类：修复后让用户重跑，比对日志新输出与旧输出差异（cpp-agent 日志 append-only，用 tail 不用 head）。

## 5. 检查清单

回答前按场景逐项自检：

**通用（所有扫描类回答）**
- [ ] 已确认 command line tools 可用：`codescanner -v` 可执行；工具包版本 ≥ 26.0.1（以部署目录/安装包名中的 26.0.x 为准）
- [ ] 给出的命令完整可执行、无省略号；projectPath 等路径已逐项校验存在性
- [ ] 未过度强调 SDK 解析顺序（不传 `-s` 也能扫）

**run-help（组装命令）**
- [ ] 已说明：不传 `-c` 即全量检测（ArkTS 23 + C++ 27），传 `-c` 为白名单语义、会收窄范围
- [ ] 已提示默认产物（`output/merged.sarif`；`-f html` 另有 `report.html`）与默认日志（`scanner/logs/codescanner.log`）
- [ ] 需扫 C++ 时，`--compileCommandsDir` 指向含 compile_commands.json 的目录

**troubleshoot（排查报错）**
- [ ] 已按优先级分类：权限 > 路径 > JSON 格式 > 引擎 > 环境 > 工具可用性
- [ ] 退出码 2 看 stderr；1 看 `[toolId] ERROR:`；引擎细节看引擎自身日志
- [ ] compile_commands.json 三态判断正确（not found / not readable（优先于格式错误）/ not valid JSON），且明确跳过 C++ 不中断整体扫描、**整体退出码可为 0**（跳过不算引擎失败）

**explain-result / rule-info（结果解读）**
- [ ] 按 ruleId 聚合、按严重级别（error/warning/note）分组汇总
- [ ] 规则归属正确：C++ 规则查 cpp-rules.md，ArkTS 规则查 arkts-rules.md
- [ ] 修复建议附修复前/后代码对比，经用户确认后才写入文件

**output-info（产物/退出码）**
- [ ] 退出码口径：0 全成功 / 1 有失败（部分成功仍输出 SARIF）/ 2 启动失败
- [ ] `merged.sarif` 始终写出；`report.html` 仅 `-f html` 时生成且失败不影响退出码

**tool-availability（工具可用性）**
- [ ] 已**同时**引用两种标准错误文案确认判定（`command not found` 与 `不是内部或外部命令`）
- [ ] 二选一引导：给出工具位置（绝对路径调用）或官方下载页
- [ ] 已核对版本门槛（工具包 26.0.1+）；未确认可用前不给扫描命令

## 6. 关键约束（从真实实现提炼，勿臆测）

1. **SDK 路径多数场景无需关心**：不传 `-s` 时工具优先用自带 `sdk/`（部署目录上级）或环境变量 `DEVECO_SDK_HOME` 兜底，多数用户直接跑即可；**不要向用户过度强调解析顺序**（详见 `references/cli-spec.md` §3）。仅当显式 `-s` 指向无效路径或想跳过 ArkTS 时才涉及解析逻辑。
2. **`--no-arkts` 时 SDK 路径不解析**（`opts.arkts` 为 false 时 `sdkPath` 置 undefined，跳过 ArkTS 分析）。
3. **compile_commands.json 错误优先级**：文件不存在 → 读取被拒（EPERM/EACCES，"not readable"）→ 内容非法 JSON（"not valid JSON"）→ 均打印错误并**跳过 C++ 检查**（不中断整体扫描，见 `src/cmd/tools/tool-configs.ts`）。三态错误属**静默降级**（跳过 ≠ 引擎失败）：若 ArkTS 成功，**整体退出码为 0**，不要表述为 1 或部分成功（见 `references/exit-codes.md` §3）。
4. **退出码**：`0` 全成功 / `1` 有失败（部分成功仍输出合并 SARIF）/ `2` 启动失败（参数或 Logger 初始化）。详见 `references/exit-codes.md`。
5. **输出产物**：`merged.sarif` 始终写出；`-f html` 额外产出 `report.html`。引擎中间产物为 `homeflow.sarif`、`codescanner-cpp.sarif`（在 outputDir 下）。
6. **日志**：默认 `scanner/logs/codescanner.log`；cpp-agent 日志 append-only（用 tail 不用 head）。
7. **命令入口**：独立 CLI 部署在 `codescanner/`（bin/codescanner(.bat)）；插件端入口为 `dist/index.js`。
8. **Windows 路径陷阱**：路径长度 > 200 字符会抛错（Windows MAX_PATH=260 余量）；写权限预检用写探测（accessSync(W_OK) 在 Windows 上不可靠）。
9. **Linux 运行 Windows 产物**：shell 脚本若含 CRLF 会报 "required file not found"，需 `sed -i 's/\r$//'`。
10. **产物安全**：发布产物不得含 `.map` 文件与 `sourceMappingURL` 注释（tsconfig sourceMap:false，源码工程以 product-clean 脚本清理）。
11. **规则清单基线**：C++ 27 条（base_rules.json）、ArkTS 23 条（checkerConfig.json），基线版本 26.0.1.272；答疑前确认用户部署版本。
12. **工具可用性前置**：扫描类请求先确认 command line tools 可用（`codescanner -v`）；未安装/未入 PATH 时引导用户给出工具位置或引导下载 [https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos) ，不要直接给扫描命令（见 §4 Step 0.5）。
13. **版本门槛**：仅 **26.0.1 及以上** 的 command line tools 支持 codescanner 扫描；旧版本（< 26.0.1）无 codescanner 扫描功能，指导前必须确认**工具包版本**（部署目录/安装包名中的 26.0.x；`codescanner -v` 仅确认命令可用，其输出 1.0.0 非工具包版本），版本不符引导升级到 26.0.1+（见 §4 Step 0.5）。
14. **不传 `-c` 即检测全量规则**：不传 `-c/--config` 时引擎使用自带默认规则集（ArkTS 23 条 + C++ 27 条全开）；传 `-c` 时是**白名单**——仅 `skip: false` 规则被检测，未列出的自动补 `skip: true`（收窄范围）。想全量检测→不传 -c；想排除误报→传 -c（格式见 `references/cli-spec.md` §3.5）。

## 7. 目录结构

```
deveco-studio-codescanner/
├── SKILL.md                      # 本文档（Skill 入口）
├── references/                   # 知识库目录
│   ├── cli-spec.md               # CLI 选项规范（参数/默认值/产物）
│   ├── exit-codes.md             # 退出码说明
│   ├── error-troubleshooting.md  # 错误排查指南
│   ├── examples.md               # 使用示例
│   └── rules/                    # 规则集目录
│       ├── index.md              # 规则索引（C++ 27 条 / ArkTS 23 条，基线 26.0.1.272）
│       ├── cpp-rules.md          # C++ 扫描规则说明（提取自 cpp-agent base_rules.json）
│       └── arkts-rules.md        # ArkTS 扫描规则说明（提取自 homeflow checkerConfig.json）
├── scripts/                      # 辅助脚本目录
│   ├── extract-rules.js          # 从部署目录提取规则清单（校验/更新 references/rules/*.md）
│   └── run-eval.js               # 评测集驱动（fixtures 断言，36 项）
├── test-cases/                   # 测试目录（唯一测试目录；检视流水线固定读取）
│   ├── trigger.md                # 触发验证（门禁执行）
│   ├── smoke.md                  # Intent 路由冒烟（门禁执行；TC-L3-01 的机器执行版）
│   ├── functional.md             # 功能验证（门禁执行）
│   ├── test-prompts.md           # 人工验证提示词
│   ├── README.md                 # 测试总纲（目标/分层/优先级/Roadmap/执行方式）
│   ├── cases/                    # 分层用例（设计层，按测试层拆分）
│   │   ├── l1-knowledge.md       # L1 知识准确性（13 用例）
│   │   ├── l2-tools.md           # L2 知识库工具（1 用例）
│   │   ├── l3-routing.md         # L3 路由边界与 Slot 提取（人工标注矩阵）
│   │   ├── l4-eval-completeness.md # L4 评测集完备性（7 用例）
│   │   ├── l5-e2e.md             # L5 端到端（6 用例）
│   │   └── l6-cross-platform.md  # L6 跨平台/回归（5 用例）
│   └── fixtures/                 # 评测样例（compile_commands 三态）
```

## 8. 维护与 Roadmap

**Roadmap（未完成项）**
- 样例工程与实测输出：`references/examples.md` 当前为基于真实参数的基础示例（**未经真实工程实测**，文件头部已标注），待 `test-cases/fixtures/` 落地最小 ArkTS+Cpp 样例工程后补全实测输出。
- C3（SDK 解析顺序）/ C5（退出码判定）用例由文档断言升级为可执行用例（需 mock 环境变量与真实 CLI 运行）。

**维护说明（随版本演进需同步的项）**
- 规则清单基线：用 `scripts/extract-rules.js <部署根目录> --out <输出目录>` 对新部署重新提取核对（当前基线 26.0.1.272）。
- 下载链接同步：官方下载链接（command-line-tools-for-hmos）唯一维护于 error-troubleshooting §2.6（description 已精简为触发句、不含 URL），链接变更时同步该处（评测 C9 分别拦截 description 触发句与 §2.6 链接）。
- 版本门槛同步：最低支持版本当前为 26.0.1（frontmatter 版本门槛句 + Step 0.5 + §2.6 + 约束 13 四处一致）；调整时需同步，评测 C9 用完整句断言拦截。
- 评测回归：任何 references/*.md、scripts/*.js、fixtures 变更后全量执行 `node scripts/run-eval.js`（当前 36 项断言）。
