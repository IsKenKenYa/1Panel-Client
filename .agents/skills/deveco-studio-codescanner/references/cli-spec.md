# CLI 选项规范（Code Scanner CLI）

> 依据真实实现 `src/cmd/options.ts`（独立 CLI 入口）与 `src/cli/args.ts`（插件入口）。
> 本文件描述**独立 CLI（codescanner 命令）**的完整用法；插件入口参数不同，见文末 §插件入口差异。

## 1. 命令形式

```bash
codescanner [projectPath] [options]
```

- `projectPath` 为位置参数（工程根目录）；缺省时取 `process.cwd()`。
- 所有路径参数内部会做 `path.resolve` 规范化（消除 `..`、`.` 相对序列）。
- 未知选项（`allowUnknownOption: false`）会直接报错并显示帮助。

## 2. 参数一览

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `[projectPath]` | 位置参数 | `process.cwd()` | 工程根目录，必须存在且为目录 |
| `-s, --sdkPath <dir>` | 可选 | 见 §3 SDK 解析 | SDK 目录；不存在则跳过 ArkTS 分析 |
| `-o, --output <dir>` | 可选 | `output` | 输出目录（须存在或祖先可写） |
| `-f, --format <format>` | 可选 | `sarif` | `sarif` 或 `html`，其他值报错 |
| `-l, --logPath <dir>` | 可选 | `scanner/logs` | 日志目录 |
| `-c, --config <path>` | 可选 | 无 | 规则配置文件；**不传即检测全量规则**（见 §3.5） |
| `--compileCommandsDir <dir>` | 可选 | 无 | 含 `compile_commands.json` 的目录（C++ 规则） |
| `--no-cpp` | 开关 | 开启 | 关闭 C++ 规则检查（cpp-agent） |
| `--no-arkts` | 开关 | 开启 | 关闭 ArkTS 规则检查（homeflow），同时不解析 SDK |
| `-v, --version` | 开关 | — | 输出 CLI 内部版本号（当前 CLI_VERSION = `1.0.0`；**非工具包版本**——工具包版本以部署目录/安装包名中的 26.0.x 为准） |
| `-h, --help` | 开关 | — | 显示帮助（含错误后自动显示） |

## 3. SDK 路径：多数场景无需关心

**默认推荐**：不传 `-s` 直接运行即可——工具自带 SDK 或环境变量兜底，多数调用场景不需要用户关心 SDK 解析逻辑：

1. CLI 部署目录上级的 `sdk/`（commandline-tools 自带 SDK，`command-line-tools/sdk`）
2. 环境变量 `DEVECO_SDK_HOME`（且目录存在）
3. 环境变量 `DEVECO_PATH` + `/sdk`（且目录存在）
4. 全部未命中 → 返回 `undefined`（跳过 ArkTS 分析，不报错）

**仅以下场景才需要显式 `-s`**：
- 工程需要特定 SDK 版本（自带 sdk/ 不满足）
- 想跳过 ArkTS 分析（配合 `--no-arkts`，此时不解析 SDK）

> 注意：向用户解释时**不要过度强调解析顺序**——多数用户只需要知道"不传 -s 也能扫"。`--no-arkts` 时**不解析** SDK 路径（`opts.arkts` 为 false 时 sdkPath 置 undefined）。

## 3.5 规则配置 `-c/--config`：不传即全量检测

**关键行为（务必向用户说明）**：

- **不传 `-c`** → 引擎使用自带默认规则集，**检测全量规则**（ArkTS 23 条 + C++ 27 条）。
- **传 `-c`** → 该配置是**白名单**：只有配置中 `skip: false` 的规则会被检测；未列出的规则自动补 `skip: true`（`expandRuleConfigForWhitelist` 扩展，见 `src/cmd/tools/tool-configs.ts`）。

**`-c` 文件格式（JSON）**：

```json
{
  "rules": {
    "arkts": {
      "ResourceLeak": [
        { "ruleId": "WindowListenerNotOff", "severity": "error", "skip": false },
        { "ruleId": "SetIntervalNotRelease", "severity": "error", "skip": true }
      ]
    },
    "cpp": {
      "ResourceLeak": [
        { "ruleId": "NapiWrap API Not Paired", "severity": "error", "skip": false }
      ]
    }
  }
}
```

字段说明：
- `rules.arkts` / `rules.cpp`：按引擎分段的规则组；组名（如 `ResourceLeak`）与引擎默认配置的 checker 名一致。
- 每条规则：`ruleId`（规则 ID，见 `references/rules/`）、`severity`（error/warning/note）、`skip`（**false = 检测，true = 跳过**）。
- **未列出的规则自动补 `skip: true`**（白名单语义）——所以传 `-c` 会**收窄**检测范围，而非扩宽。
- 只有 `skip: false` 的规则会被检测；若 `rules.cpp` 段所有规则均非 `skip:false`，等效 `--no-cpp`（cpp 被抑制）。

**使用建议**：
- 想检测全量规则 → **不要传 `-c`**。
- 想只检测特定规则 / 排除误报规则 → 传 `-c`，把要检测的规则列 `skip: false`，要排除的列 `skip: true`。

## 4. 路径预检规则（parseArgs 阶段）

| 校验 | 规则 | 失败信息 |
|------|------|----------|
| `projectPath` | 必须存在 + 是目录 + 可读 | `projectPath not found / is not a directory / is not readable` |
| `sdkPath` | 可选；存在则必须目录 + 可读 | 同上（`sdkPath` 前缀） |
| `outputDir` / `logDir` | 存在则必须目录 + **真实可写**（写探测）；不存在则向上找最近存在的祖先检查可写 | `outputDir is not writable: <p> (<errno>)` |
| `ruleConfig` | 可选；存在则必须文件 + 可读 | `ruleConfig ...` |
| `compileCommandsDir` | 可选；存在则必须目录 + 可读 | `compileCommandsDir ...` |
| 超长路径 | 任一关键路径 > 200 字符抛错（Windows MAX_PATH=260 余量）；产出文件路径（logFile/mergedSarif/htmlReport）单独校验 | `xxx path is too long (... chars, max 200)` |
| 空字符串 | 任意路径参数为空白串报错 | `xxx cannot be an empty string` |

要点：
- Windows 上 `accessSync(R_OK)` 可能通过但实际读不到（EPERM），故目录校验用 `readdirSync` 兜底合并为同一报错。
- `accessSync(W_OK)` 对 ACL 拒绝可能误判通过，故写权限用**写探测**（临时文件创建即删，`probeWritableDir`）。

## 5. 引擎与产物

| 引擎 | 输入 | 中间产物（outputDir 下） | 规则来源 |
|------|------|--------------------------|----------|
| homeflow（ArkTS） | projectPath、SDK、规则配置 | `homeflow.sarif` | `-c` 指定的 config，或部署目录 `homeflow/config/checkerConfig.json` 派生 |
| cpp-agent（C++） | `--compileCommandsDir/compile_commands.json`（即 `--scope`） | `codescanner-cpp.sarif` | cpp-agent 自带 `base_rules.json` |

最终产物（run-common.ts `mergeAndWriteSarif`）：

| 产物 | 说明 |
|------|------|
| `<outputDir>/merged.sarif` | 合并所有成功引擎的 SARIF 2.1.0，格式化 JSON，**始终写出** |
| `<outputDir>/report.html` | 仅 `-f html` 时生成（由 merged.sarif 经 report-generator 生成）；生成失败不影响退出码（只记日志 + stderr） |

stdout 汇总（成功且有结果时）：

```text
Scan completed: N issue(s) found
SARIF output: <abs path>/merged.sarif
[HTML report: <abs path>/report.html]   # 仅 -f html
```

## 6. 运行骨架（run-common.ts）

主流程：`parseArgs → setupLogger → 构建 ToolConfigs → runAllTools（并发）→ processResults → handleFailures → mergeAndWriteSarif → closeAndExit`。

- 失败处理：全部失败 → 停止、无 SARIF 输出；部分失败 → 仅合并成功部分，继续输出。
- 优雅关闭：SIGINT/SIGTERM 触发日志关闭并 `exit(0)`，防止日志截断与子进程孤儿化。
- 正常路径统一 `logger.close()`（幂等）后按失败情况退出（`closeAndExit`）。
- stderr 净化：子进程 stderr 完整写日志，终端只显示 `summarizeStderr` 摘要（避免 Node 内部堆栈泄漏到终端）。

## 7. 插件入口差异（src/cli/args.ts）

插件端（dist/index.js，由 DevEco Studio 调用）参数不同：

- 必选：`--sdkPath`、`--projectPath`、`--logDir`、`--scope`（cpp 引擎 scope）、`--outputDir`
- 可选：`--ruleConfig`（homeflow）、`--nodePath`（运行 homeflow 的 node，缺省回退 process.execPath）、`--no-cppRules`、`--no-arktsRules`
- 不校验写权限/超长路径（插件侧行为更简）。

> 排查问题前先确认用户用的是独立 CLI 还是插件调用，参数名不同，勿混用。
