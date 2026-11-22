# L5 端到端测试用例

> 层对象：真实 CLI（dist/ 或部署 codescanner）级联跑通
> 质量属性：全链路行为（真实 CLI 级联）
> 编号规则：TC-L5-<序号>
> 说明：依赖真实 CLI 构建产物（`npm run build` → `dist/` + `codescanner/`）与部署 SDK/引擎。默认在部署机（26.0.1.272）或本地 dist 半集成环境执行。

---

## TC-L5-01 最小工程全链路（P0）

- 前置：最小 ArkTS+Cpp 样例工程（待补充）；含有效 compile_commands.json；SDK 有效
- 步骤：`codescanner <proj> -s <sdk> -o <out> -f sarif -l <log> --compileCommandsDir <cxx>`
- 预期：退出码 0；out/merged.sarif 存在且合法；stdout 含 `Scan completed:` 与 `SARIF output:`；scanner/logs/codescanner.log 存在

---

## TC-L5-02 HTML 报告生成失败不改变退出码（P0）

- 前置：同上；构造 report.html 生成失败（如输出目录只读或注入生成器抛错）
- 步骤：`-f html` 运行
- 预期：merged.sarif 正常写出；stderr 含 `[codescanner] HTML report generation failed:`；退出码仍为 0/1（不因此变 2）
- 说明：cmd/index.ts `outputResults` catch 分支已证实；本用例验证端到端一致性

---

## TC-L5-03 部分失败合并（P0）

- 前置：mock 引擎替换 cpp-agent（失败）+ 真实 homeflow（成功），或反向
- 步骤：运行 CLI
- 预期：退出码 1；merged.sarif 仅含成功引擎 run；stdout 仍打印 `Scan completed:`；日志含 `Partial results: merging SARIF from succeeded tools only`

---

## TC-L5-04 全部失败无产物（P0）

- 步骤：两引擎均 mock 失败
- 预期：退出码 1；无 merged.sarif；stderr 含 `[codescanner] All tools failed, no SARIF output`（经 run-common handleFailures）

---

## TC-L5-05 SIGINT/SIGTERM 优雅关闭（P1）

- 步骤：扫描运行中发 SIGINT
- 预期：日志含 `Received SIGINT, shutting down gracefully...`；`logger.close()` 后 `exit(0)`（run-common.ts setupGracefulShutdown）

---

## TC-L5-06 参数级端到端（P1）

- 步骤：对不存在 projectPath、空字符串 output、非法 format、存在但超长的目录分别调用 parseArgs
- 预期：分别抛 `projectPath not found`、`output cannot be an empty string`、`Invalid format "pdf", must be: sarif or html`、`projectPath path is too long (265 chars, max 200)`（均已实测）；真实 CLI 运行路径下均映射退出码 2
