# L4 评测集完备性测试用例

> 层对象：run-eval.js 断言有效性、缺口补齐
> 质量属性：评测集自身有效（断言不恒真、无缺口）
> 编号规则：TC-L4-<序号>
> 说明：本节用例是"针对 run-eval.js 自身的测试"，确保评测集能真实拦住回归。

---

## TC-L4-01 C4 恒真断言修复（P0）

- 现状：run-eval.js `caseC4()` 三条 `check(..., true)` **恒真**，无实际校验
- 预期：改为可执行断言——以 TC-L1-04 的探针脚本（真实 CLI buildToolConfigs）驱动，断言 stderr 文案与 configs 不含 cpp-agent；退出码为 0
- 判定标准：把恒真 `true` 换成可失败表达式；注入故意错误的文案（如 `not valid json` 改 `valid json`）应导致用例失败（负向自检）

---

## TC-L4-02 C3 SDK 解析顺序可执行化（P0）

- 现状：C3 为文档关键词断言（`cli-spec.md 含..."`）+ TODO
- 预期：接入 TC-L1-01 探针脚本，4 场景（env mock）可执行
- 判定标准：任一顺位场景回归（如 DEVECO_SDK_HOME 不再命中）时用例失败

---

## TC-L4-03 C5 退出码判定可执行化（P0）

- 现状：C5 为文档断言 + TODO
- 预期：接入 mock 引擎（复用源码工程 `test/fixtures/mock-exit-1.cjs`/`mock-sarif-ok.cjs`/`mock-non-json.cjs`/`mock-no-file.cjs` 手法），对真实 `runPipeline` 断言退出码 0/1/2 与 merged.sarif 产物存在性
- 判定标准：部分失败场景 merged.sarif 只含成功引擎；全失败场景无 SARIF 且退出 1；参数非法退出 2

---

## TC-L4-04 R 组规则知识断言（P0）

- 现状：R1/R2/R3 标注"TODO 加入 run-eval.js"
- 预期：新增 caseR1/caseR2/caseR3：
  - R1：cpp-rules.md 含 `NapiWrap API Not Paired`、`Malloc API Not Paired`、`JSVM_Reference_Conut API Not Paired`，规则总数 = 27（按表格行数或标题计数）
  - R2：arkts-rules.md 含 `WindowListenerNotOff`，且含 `Window.on → .off` 配对描述
  - R3：arkts-rules.md / cli-spec.md 含 `skip` 配置说明（`-c` 未列出规则补 skip:true）

---

## TC-L4-05 负向自检 Mutation Test（P1）

- 步骤：对每个自动断言（C4 三态文案、C9 版本门槛/下载链接句）做一次"故意改错"注入：把 fixtures 中 `not valid json` 改为 `valid json`、把 SKILL.md frontmatter 版本门槛句改为 `25.0.0`
- 预期：对应断言**必须失败**（证明断言有效）；恢复后全部通过
- 说明：C9 负向自检已实测（TC-L4-06）→ 本用例补 C4 等其余断言

---

## TC-L4-06 断言计数与 exit code 自洽（P1）

- 步骤：全量 `node scripts/run-eval.js`；断言 `结果: N passed, 0 failed` 且 N ≥ 26 + 新增用例数；有失败时 exit 1
- 预期：run-eval.js 行为一致；单用例 `--filter C9` 只跑 C9

---

## TC-L4-07 C9 工具可用性可执行化（P0）

- 现状：C9 已接入 run-eval.js（caseC9，13 项关键词断言：description 含 tool-availability 触发句 + **版本门槛句** + 下载链接、Step 0.5 存在 + 版本门槛判定、§2.6 存在 + command not found 判定 + 版本不符处理、约束 12/13）。**关键断言严格限定 frontmatter**（skillFrontmatter()），正文内容不计入触发判定
- 预期：保持可执行；改 SKILL.md 触发句 / 删 §2.6 下载链接 / 改版本门槛时用例必须失败
- 判定标准：负向自检（已实测）——① 仅替换 frontmatter 中 `command-line-tools-for-hmos` → "description 含下载链接"失败；② 把版本门槛完整句 `仅 26.0.1+ 支持 codescanner 扫描` 改为 `25.0.0` → "description 含版本门槛触发句"失败（12 passed, 1 failed）。注意断言须用完整句而非裸 `26.0.1`（frontmatter 路由句中也有该数字，裸匹配会假通过）
