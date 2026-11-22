# L1 知识准确性测试用例

> 层对象：references/*.md 事实 vs 真实 CLI 实现（src/cmd/options.ts、src/cmd/tools/tool-configs.ts、src/run-common.ts、src/cli/args.ts、src/cmd/index.ts）
> 质量属性：知识准确性（事实与真实 CLI 一致）
> 编号规则：TC-L1-<序号>

---

## TC-L1-01 SDK 路径默认解析顺序（P0）

- 前置：`dist/cmd/options.js` 可被 node 导入；临时目录可建
- 步骤：
  1. 构造临时目录：`proj/`、`out/`、`log/`、`home-sdk/`、`deveco-root/sdk/`
  2. 场景 1：仅设 `DEVECO_SDK_HOME=home-sdk`，`DEVECO_PATH` 清空，调用 `parseArgs(['node','codescanner', proj, '-o', out, '-l', log])`
  3. 场景 2：清空 `DEVECO_SDK_HOME`，设 `DEVECO_PATH=deveco-root`，再次调用
  4. 场景 3：显式 `-s home-sdk` 调用
  5. 场景 4：追加 `--no-arkts` 调用
- 预期：
  - 场景 1 `sdkPath === resolve(home-sdk)`（第 2 顺位）
  - 场景 2 `sdkPath === resolve(deveco-root/sdk)`（第 3 顺位）
  - 场景 3 `sdkPath === resolve(home-sdk)`（第 1 顺位）
  - 场景 4 `sdkPath === undefined`（`opts.arkts` 为 false 不解析，见 options.ts L240）
- 断言实现方式：`node --input-type=module -e "<探针脚本>"` 对 `dist/cmd/options.js` 做 env mock（已实测通过）
- 对应 run-eval.js：C3（当前为文档关键词断言，TODO 升级为可执行断言）

---

## TC-L1-02 部署目录上级 sdk/ 第 1 顺位（P1）

- 前置：可定位 CLI 部署根目录（`codescanner/cmd/options.js` 上 2 层 + `sdk/`）
- 步骤：在部署目录上级创建 `sdk/` 目录；清空 env 变量；调用 parseArgs
- 预期：`sdkPath` 命中部署 `sdk/`（options.ts `resolveSdkPath` L41）
- 判定标准：断言 `sdkPath` 值等于部署目录 `sdk/` 的 resolve 结果（非仅"非 undefined"）
- 说明：仓库内 `dist/` 无真实部署结构，建议在部署机（26.0.1.272）上执行或构造目录镜像

---

## TC-L1-03 全部未命中 → undefined 不报错（P0）

- 前置：无 `-s`；部署 `sdk/` 不存在；`DEVECO_SDK_HOME`/`DEVECO_PATH` 未设置或指向不存在目录
- 步骤：调用 parseArgs
- 预期：`sdkPath === undefined`，不抛错（options.ts L59；tool-configs.ts `buildHomeflowConfig` 打印 `[warn] SDK path not found, skipping ArkTS rule checking` 并返回 null）

---

## TC-L1-04 compile_commands.json 三态错误优先级（P0）

- 前置：临时目录 `cc-missing/`（空）、`cc-invalid/`（含 `not valid json{` 的 compile_commands.json）、`cc-valid/`（含 `[]`）、`proj/`、`out/`、`log/`
- 步骤（`--no-arkts` 隔离，避免 homeflow 可执行文件依赖；调用 `buildToolConfigs`）：
  1. 场景 A：不传 `--compileCommandsDir`
  2. 场景 B：传 `--compileCommandsDir cc-missing`
  3. 场景 C：传 `--compileCommandsDir cc-invalid`
  4. 场景 D：传 `--compileCommandsDir cc-valid`
  5. 场景 E：cc-valid + `--no-cpp`
- 预期：
  - A：stdout 出现 `[warn] --compileCommandsDir not provided`；configs 不含 `cpp-agent`
  - B：stderr 出现 `[error] compile_commands.json not found in: ... skipping C++ rule checking`；configs 不含 `cpp-agent`；**不抛异常**
  - C：stderr 出现 `[error] compile_commands.json is not valid JSON: ...`；configs 不含 `cpp-agent`；**不抛异常**
  - D：stdout 出现 `[info] Using compile_commands.json: ...`；部署机（含 exe）上 configs 含 `cpp-agent`；仓库 dist 缺 exe 时会抛 `CodeScanner C++ executable not found`，此属部署完整性检查，断言应限定在部署机执行或降级为"断言 stdout 出现 `[info] Using compile_commands.json` 且未打印任何 `[error]`"
  - E：configs 不含 `cpp-agent`
- 断言实现方式：探针脚本捕获 stdout/stderr 子串（已实测 A/B/C/D 行为正确）
- fixtures：`test-cases/fixtures/compile_commands/{valid,invalid-json,missing-file}/`
- 对应 run-eval.js：C4（当前为 `check(..., true)` 恒真断言，**必须替换为可执行断言**）

---

## TC-L1-05 不可读优先级高于非法 JSON（P0，Windows）

- 前置：Windows；`cc-denied/` 含 compile_commands.json，用 `icacls` 对该文件 deny 读取（accessSync 不可靠，需 icacls + 写探测）
- 步骤：传 `--compileCommandsDir cc-denied` 调用 buildToolConfigs
- 预期：stderr 含 `is not readable: ... (EPERM...)`，**不含** `not valid JSON`（tool-configs.ts `resolveCompileCommands` L229-239：EPERM/EACCES 分支先于 JSON.parse）
- 说明：Linux 上可用 `chmod 000` 等效；若环境无法构造，降级为"以单测 mock `readFileSync` 抛 EPERM 验证分支"（P2 降级）

---

## TC-L1-06 退出码 0/1/2 判定（P0）

- 前置：读取 `src/run-common.ts` `closeAndExit`（L148-151）与 `runPipeline` catch（L207）
- 步骤（静态+动态混合）：
  1. 静态断言：`closeAndExit` 中 `process.exit(failures.length > 0 ? 1 : 0)`；`setupFileLogger` 失败 `exit(2)`；`runPipeline` catch `exit(2)`
  2. 动态断言（mock 引擎手法，参照源码工程 `test/runner/runner.test.ts` 与 `test/fixtures/mock-exit-1.cjs` 等）：构造 ToolConfigs 使全部成功 → 期望 0；一个 mock 引擎 exit 1 → 期望 1 且 merged.sarif 只含成功引擎结果；全部失败 → 期望 1 且无 SARIF
- 预期：与 exit-codes.md 表完全一致；`-f html` report.html 生成失败不改变退出码（cmd/index.ts `outputResults` catch 只记日志 + stderr）
- 对应 run-eval.js：C5（当前为文档断言 + TODO，升级为可执行用例）

---

## TC-L1-07 路径预检顺序（not found 先于 too long）（P1）

- 前置：构造"存在但长度 > 200"的目录（`base/d*210`）
- 步骤：
  1. 场景 1：传入**不存在**的超长路径 → 观察报错
  2. 场景 2：传入**存在**的超长目录 → 观察报错
- 预期：
  - 场景 1：`projectPath not found`（validateDir 先执行）
  - 场景 2：`projectPath path is too long (265 chars, max 200)`（assertPathLength 后执行）
- 说明：options.ts 预检顺序为 validateDir → validateOutputDir → assertPathLength；知识库未记录该顺序，建议在 cli-spec.md §4 补充

---

## TC-L1-08 写探测机制 probeWritableDir（P0）

- 前置：options.ts `probeWritableDir`（L136-147）源码可读；Windows 上 accessSync(W_OK) 不可靠
- 步骤（静态断言 + 动态）：
  1. 静态：`probeWritableDir` 先 `writeFileSync(.codescanner-write-probe-<pid>)` 再 `rmSync`，catch 时抛 `${name} is not writable: ${p} (${errno})`
  2. 动态：对只读目录调用 `validateOutputDir` → 期望抛 `is not writable`（Windows 用 icacls deny 构造；或 mock writeFileSync 抛 EPERM）
- 预期：写探测在预检阶段暴露不可写目录；cli-spec.md §4 与 error-troubleshooting.md §2.1 描述一致

---

## TC-L1-09 超长阈值 = 200（常量断言）（P1）

- 步骤：静态断言 `src/cmd/options.ts` 含 `const LONG_PATH_THRESHOLD = 200;`（L70）；cli-spec.md §4 含 `max 200`
- 预期：两者一致；产出文件路径（logFile/mergedSarif/htmlReport）同样参与校验（options.ts L272-274）

---

## TC-L1-10 引擎失败文案映射（P0）

- 前置：`src/runner/runner.ts` 各失败分支
- 步骤：静态断言 runner.ts 中错误文案：
  - 非零退出 → `Exited with code ${code}: ${message}`
  - 无输出文件 → `Output file not found: <path>`
  - 输出非法 → `Invalid SARIF output: ...`
  - 超时 → `Timed out after ${timeoutMs / 1000}s`
  - 启动失败 → `Failed to start "<exe>": <err>`
- 预期：exit-codes.md §2 明细表 6 行与 runner.ts 一一对应

---

## TC-L1-11 规则清单数量与版本（P0）

- 前置：`references/rules/cpp-rules.md`、`arkts-rules.md`；部署 26.0.1.272 或 `scripts/extract-rules.js` 输出
- 步骤：静态断言 cpp-rules.md 含 27 条规则 ID（抽样 `NapiWrap API Not Paired`、`Malloc API Not Paired`、`JSVM_Reference_Conut API Not Paired`）；arkts-rules.md 含 23 条（抽样 `WindowListenerNotOff`、`SetIntervalNotRelease`、`RpcMessageSequenceNotRelease`）
- 预期：数量=27/23；基线版本标注 26.0.1.272；版本差异提示存在（index.md §版本差异提示）
- 对应 run-eval.js：R1/R2/R3（TODO 升级为数量+ID 校验）

---

## TC-L1-12 stderr 净化摘要规则（P1）

- 前置：`src/common.ts` `summarizeStderr`
- 步骤：构造含 Node 堆栈的 stderr 字符串调用 `summarizeStderr`
- 预期：输出仅保留 Error 行 + `[code=..., syscall=..., path=...]` 字段；`at /`、`node:fs:` 帧被丢弃；error-troubleshooting.md §3 描述一致

---

## TC-L1-13 插件入口参数差异（P1）

- 前置：`src/cli/args.ts`
- 步骤：静态断言插件参数集合为 `--sdkPath/--projectPath/--logDir/--scope/--outputDir`（必选）+ `--ruleConfig/--nodePath/--no-cppRules/--no-arktsRules`（可选）；cli-spec.md §7 一致
- 预期：两者一致；排查前先确认独立 CLI 或插件调用（SKILL.md Step 0）
