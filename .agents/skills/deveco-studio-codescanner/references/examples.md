# 使用示例（Examples）

> 全部基于独立 CLI（codescanner）的真实参数。路径按实际环境替换。
> **示例状态：基础示例，未经真实工程实测**；待 `test-cases/fixtures/` 落地样例工程后补全实测输出。

## 1. 基础扫描（默认格式 sarif）

```bash
codescanner D:/workspace/demo/MyApp
```

- **多数场景无需关心 SDK**：不传 `-s` 时工具自动用自带 sdk/ 或 DEVECO_SDK_HOME 兜底（见 cli-spec.md §3）
- **不传 `-c` 即检测全量规则**（ArkTS 23 条 + C++ 27 条）
- 输出到 `./output/merged.sarif`，日志到 `./scanner/logs/codescanner.log`

## 2. 完整参数扫描（ArkTS + C++）

```bash
codescanner D:/workspace/demo/MyApp \
  -s D:/command-line-tools/sdk \
  -o output \
  -f sarif \
  -l scanner/logs \
  -c rules/my-config.json \
  --compileCommandsDir D:/workspace/demo/MyApp/.idea/.deveco/cxx
```

- `--compileCommandsDir` 指向含 `compile_commands.json` 的目录（cpp-agent 的 `--scope`）
- 注意：**传 `-c` 会收窄检测范围**（白名单语义，见 §3.5 规则配置）

## 3. 生成 HTML 报告

```bash
codescanner D:/workspace/demo/MyApp -f html -o output
```

- 产出 `output/merged.sarif` + `output/report.html`
- report.html 生成失败不影响退出码

## 4. 只扫 C++ / 只扫 ArkTS

```bash
# 关闭 ArkTS（也不解析 SDK）
codescanner D:/workspace/demo/MyApp --no-arkts --compileCommandsDir .../cxx

# 关闭 C++
codescanner D:/workspace/demo/MyApp --no-cpp
```

## 4.5 规则配置 `-c/--config` 示例

**不传 `-c`（推荐，检测全量规则）**：

```bash
codescanner D:/workspace/demo/MyApp
```

**传 `-c` 只检测指定规则**（白名单，rules.json 内容见下）：

```bash
codescanner D:/workspace/demo/MyApp -c rules/my-config.json
```

`rules/my-config.json` 格式：

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

- 仅 `skip: false` 的规则被检测；未列出的规则自动 `skip: true`（白名单语义）
- 完整字段说明见 `references/cli-spec.md` §3.5

## 5. 多工程 / 指定输出与日志

```bash
codescanner D:/workspace/demo/MyApp -o D:/scan-output -l D:/scan-logs
```

## 6. 预期输出

```text
[info] Using compile_commands.json: <abs>/compile_commands.json
Scan completed: 12 issue(s) found
SARIF output: D:/scan-output/merged.sarif
```

- `Scan completed: N issue(s) found` 的 N = 全部 run.results 长度之和
- 引擎中间产物 `homeflow.sarif` / `codescanner-cpp.sarif` 也落在 outputDir 下

## 7. 引擎/环境变量参考

| 变量 | 用途 |
|------|------|
| `DEVECO_SDK_HOME` | SDK 路径回退（第 2 顺位） |
| `DEVECO_PATH` | 回退为 `DEVECO_PATH/sdk`（第 3 顺位） |

## 8. 排查示例速查

| 场景 | 命令 |
|------|------|
| 查看版本/确认 PATH 指向 | `codescanner -v` |
| 查看帮助 | `codescanner -h` |
| 查看 cpp-agent 日志（append-only） | `tail -n 100 scanner/logs/code_scanner_cpp.log` |
| 修复 CRLF（Linux） | `sed -i 's/\r$//' bin/codescanner*` |
| 重新生成 compile_commands.json | 改 CMakeLists.txt 后重新生成（再跑扫描） |
