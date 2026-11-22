# CodeLinter CLI 规范

## 命令格式

```
node <codelinter入口> [options] [dir]
```

- `codelinter入口`：DevEco Studio 安装目录下的 `plugins/codelinter/run/index.js`
- `dir`：待检查的**文件或目录**。传目录时扫描整个工程（受配置文件 `files`/`ignore` 约束）；传单个文件路径时仅扫描该文件。不指定时默认为当前目录

## 规则加载机制

CodeLinter 规则统一通过 `code-linter.json5` 的 `ruleSet` / `rules` 字段配置。其中：

- 带 `@` 前缀的规则（如 `@typescript-eslint`、`@performance`、`@security` 等）通过 `ruleSet` 预设或 `rules` 字段逐条启用。
- `hp-*` 前缀的规则（如 `hp-arkui-*`、`hp-specs-*`、`hp-performance-*` 等）由工具自动加载，选中对应规则集的任意预设即全部运行，通常无需手动配置。

所有规则按类别分布在各规则集文档中，详见 [规则集索引](rules/index.md)。

> **注意**：向用户介绍规则加载机制时，不要提及内部引擎名称、agent 模块名或独立配置文件名，统一表述为 "CodeLinter 规则集"。

## 入口路径探测

DevEco Studio 标准安装位置：

| 平台 | 典型路径 |
|------|---------|
| macOS | `/Applications/DevEco-Studio.app/Contents/plugins/codelinter/run/index.js` |
| Windows (用户) | `%LOCALAPPDATA%\Huawei\DevEco Studio\plugins\codelinter\run\index.js` |
| Windows (64位) | `C:\Program Files\Huawei\DevEco Studio\plugins\codelinter\run\index.js` |
| Windows (32位) | `C:\Program Files (x86)\Huawei\DevEco Studio\plugins\codelinter\run\index.js` |

探测脚本见 [scripts/detect-codelinter.js](../scripts/detect-codelinter.js)。

探测失败时，直接询问用户 DevEco Studio 的安装目录，然后拼接 `<安装目录>/plugins/codelinter/run/index.js`。

## 命令行参数

| 参数 | 说明 |
|------|------|
| `[dir]` | 待检查的文件或目录（不指定则用当前目录）。传目录扫描整个工程；传单文件路径仅扫描该文件，但仍读取工程根的 `code-linter.json5` 作为规则来源 |
| `-c/--config <filepath>` | 指定配置文件（默认读取工程根目录下的 `code-linter.json5`） |
| `--fix` | 检查的同时执行 QuickFix 自动修复 |
| `-f/--format <format>` | 输出格式：`default`（文本）/ `json` / `xml` / `html` |
| `-o/--output <filepath>` | 将结果保存到文件（控制台不显示） |
| `-i/--incremental` | 仅检查 Git 增量文件（新增/修改/重命名） |
| `-p/--product <productName>` | 指定生效的 product（多 product 工程时使用） |
| `-e/--exit-on <levels>` | 指定哪些级别返回非零退出码，多个用逗号分隔（如 `error,warn`） |
| `-v/--version` | 查看 codelinter 版本 |
| `-h/--help` | 查看帮助 |

## 常用命令组合

### 基本检查

```bash
node <CODELINTER> /path/to/project
```

### 仅检查单个文件

直接将文件路径作为 `[dir]` 传入，codelinter 会自动定位其所属工程并读取工程根的 `code-linter.json5`，但只扫描该文件而非整个项目：

```bash
node <CODELINTER> -f json -o /tmp/lint-result.json /path/to/project/entry/src/main/ets/pages/Index.ets
```

> **注意**：即使传单文件，工程配置中的 `ignore` 规则仍会生效。若目标文件被 `ignore` 匹配（如 `**/src/test/**/*`），需用 `-c` 指向临时配置文件覆盖 `ignore`。

### 指定配置文件，JSON 格式输出到文件

```bash
node <CODELINTER> -c /path/to/code-linter.json5 -f json -o /tmp/lint-result.json /path/to/project
```

### 仅检查 Git 增量文件（CI 场景）

```bash
node <CODELINTER> -i /path/to/project
```

### 检查并自动执行 QuickFix

```bash
node <CODELINTER> --fix /path/to/project
```

### 多 product 工程，指定 product

```bash
node <CODELINTER> -p default /path/to/project
```

### CI/CD 门禁集成

```bash
node <CODELINTER> -i -e error,warn -f json -o /tmp/lint-report.json /path/to/project
```

## `--exit-on` 退出码说明

退出码为 3 位二进制（高→低：error/warn/suggestion）转十进制。某位为 1 当且仅当：该级别在 `--exit-on` 中**配置了**且结果中**存在**该级别告警（两者同时满足）。未配置的级别对应位恒为 0。

| 配置 | 结果包含 | 退出码 |
|------|---------|--------|
| `--exit-on error` | error、warn、suggestion | `4`（100₂） |
| `--exit-on error,warn` | error、warn | `6`（110₂） |
| `--exit-on error,warn,suggestion` | error、warn（无 suggestion） | `6`（110₂） |
| `--exit-on error,warn,suggestion` | error、warn、suggestion | `7`（111₂） |
| `--exit-on error` | 仅 warn（无 error） | `0`（000₂） |
| `--exit-on warn` | warn | `2`（010₂） |

退出码含义：

| 退出码 | 二进制 | 含义 |
|--------|--------|------|
| `0` | 000 | 结果中无配置级别的问题 |
| `1` | 001 | 存在 suggestion（配置了 suggestion） |
| `2` | 010 | 存在 warn（配置了 warn） |
| `4` | 100 | 存在 error（配置了 error） |
| `6` | 110 | 存在 error 和 warn |

## 输出格式

### JSON 格式

JSON 输出为数组，按文件分组，每个文件包含 `messages` 列表：

```json
[
  {
    "filePath": "/path/to/entry/src/main/ets/pages/Index.ets",
    "messages": [
      {
        "line": 42,
        "column": 8,
        "severity": "warn",
        "message": "Preferentially use the @Builder method instead of custom components.",
        "rule": "@performance/avoid-overusing-custom-component-check"
      }
    ]
  }
]
```

### severity 取值

| 值 | 级别 | 处理策略 |
|----|------|---------|
| `"error"` | 错误 | 必须修复（影响编译或运行时行为） |
| `"warn"` | 警告 | 强烈建议修复 |
| `"suggestion"` | 建议 | 可选优化 |

JSON 解析与汇总脚本见 [scripts/parse-result.js](../scripts/parse-result.js) 和 [scripts/analyze-results.js](../scripts/analyze-results.js)。

配置校验脚本见 [scripts/validate-config.js](../scripts/validate-config.js)，在运行 CodeLinter 前校验规则集/规则名/路径是否存在。

## 注意事项

- `oh_modules` 和 `build` 目录必须在配置文件的 `ignore` 中排除，否则会产生大量无关告警
- `--fix` 并非对所有规则都有效，复杂重构类问题仍需手动处理
- `-i/--incremental` 依赖 Git，需在 Git 仓库内运行
- Windows 路径包含空格时需用引号包裹
