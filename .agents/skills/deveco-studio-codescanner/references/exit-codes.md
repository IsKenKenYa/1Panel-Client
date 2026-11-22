# 退出码说明（Exit Codes）

> 独立 CLI（codescanner）退出码由 `src/run-common.ts` 的 `closeAndExit` 决定；
> 启动失败退出码为 2。插件端行为近似但由插件宿主解释，排查时注意区分。

## 1. 退出码表

| 退出码 | 含义 | 触发场景 | 是否有输出 |
|--------|------|----------|------------|
| `0` | 全部成功 | 所有启用的引擎成功（或全部引擎被显式跳过） | `merged.sarif` 完整写出 |
| `1` | 有失败 | 至少一个引擎失败；若部分成功，仅合并成功部分 | 部分 `merged.sarif` 仍写出；stdout 仍打印 `Scan completed: N issue(s) found` |
| `2` | 启动失败 | 参数校验失败（路径不存在/不可读/不可写/超长/非法 format）、Logger 初始化失败、runPipeline 未捕获异常 | 无 SARIF；stderr 打印 `[codescanner] ...` 干净错误 |

## 2. 各场景明细

| 场景 | 引擎退出码 | 产物文件 | CLI 行为 |
|------|-----------|----------|----------|
| 成功 | `0` | 有效 SARIF | 计入合并结果 |
| 成功但未写文件 | `0` | 缺失 | 失败：`Output file not found` |
| 成功但文件非法 | `0` | 非法 JSON/SARIF | 失败：`Invalid SARIF output` |
| 非零退出 | 非 `0` | — | 失败：`Exited with code N` |
| 超时 | —（默认无超时限制） | — | 失败：`Timed out after ${timeoutMs / 1000}s` |
| 可执行文件缺失 | — | — | 失败：`Failed to start` |

## 3. 引擎跳过（非失败，不影响退出码）

| 条件 | 结果 |
|------|------|
| `--no-arkts` | homeflow 不运行（SDK 也不解析） |
| `--no-cpp` | cpp-agent 不运行 |
| `--compileCommandsDir` 未传 / compile_commands.json 不存在 / 不可读 / 非法 JSON | **跳过 C++ 检查**，打印 `[error]` 提示，整体仍可退出 `0`（若 ArkTS 成功） |

> 注意：compile_commands.json 的"跳过"是**静默降级**而非失败——CLI 设计上不因 C++ 输入缺失而中断扫描。

## 4. 判断技巧

- 退出码 `1` 时先看 stderr 的 `[toolId] ERROR:` 行，`toolId` 为 `homeflow` 或 `cpp-agent`。
- 退出码 `2` 时错误来自参数预检或 Logger，日志文件可能不存在（Logger 未初始化）。
- `-f html` 时 report.html 生成失败**不会**改变退出码（只写日志与 stderr）。
- 插件端 `--nodePath` 不可访问时回退 `process.execPath` 并告警，**不**算失败。
