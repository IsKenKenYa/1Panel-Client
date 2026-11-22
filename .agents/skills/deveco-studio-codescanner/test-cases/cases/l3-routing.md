# L3 Trigger / Intent / Slot 路由测试用例

> 层对象：SKILL.md §3 的 7 Intent 路由与边界
> 质量属性：路由正确性（提问→Intent→知识源）
> 编号规则：TC-L3-<序号>
> 说明：路由逻辑位于 SKILL.md §3/§4，为 LLM 行为，采用"构造典型提问 + 人工标注预期 + 关键词断言"方式验证。

---

## TC-L3-01 7 类 Intent 典型提问命中（P0）

> **机器可执行版见本目录上级 [../smoke.md](../smoke.md)**（7 例，同一断言以 smoke.md 为准维护），以下保留人工标注全集口径。

- 前置：SKILL.md §3.2/§4 路由表；人工标注集（Q&A 14 组，中英各 7）
- 输入（构造 14 组，中英各 7）：
  - usage：`codescanner 怎么用？` / `How to use codescanner?`
  - run-help：`帮我用 codescanner 扫 D:\demo\MyApp，SDK 在 D:\sdk` / `Run codescanner on my project with a custom SDK`
  - explain-result：`扫描结果怎么解读？` / `What do these scan results mean?`
  - troubleshoot：`codescanner 扫描报错了怎么办` / `codescanner scan failed with an error`
  - rule-info：`WindowListenerNotOff 是什么意思？` / `Explain rule NapiWrap API Not Paired`
  - output-info：`codescanner 退出码都是什么意思？` / `What output files does codescanner produce?`
  - tool-availability：`codescanner 命令找不到` / `Where to download command line tools?`
- 步骤：对每组提问按 SKILL.md §4 执行路由，记录 Intent + 路由到的知识源/脚本
- 预期：
  - usage → cli-spec.md
  - run-help → cli-spec.md + 路径逐项校验
  - explain-result → 解读 merged.sarif/report.html（ruleId 聚合）+ rules/*.md
  - troubleshoot → error-troubleshooting.md（分类优先序：权限 > 路径 > JSON > 引擎 > 环境 > 工具可用性）
  - rule-info → rules/index.md → cpp-rules.md / arkts-rules.md
  - output-info → exit-codes.md + cli-spec.md §产物
  - tool-availability → SKILL.md §4 Step 0.5 → error-troubleshooting.md §2.6（给出位置 / 下载引导）
- 判定标准：每条提问给出"路由到的知识源/脚本 + 结论关键要素"清单；任一提问路由错层或结论缺关键要素即为失败
- 对应 run-eval.js：C1（usage）、C2（run-help）、C9（tool-availability）部分覆盖

---

## TC-L3-02 Trigger 命中/未命中边界（P0）

- 命中组：含 `codescanner`/`code-scanner`/`code scanner`/`代码扫描` 关键词；`扫描报错了`（上下文指向 codescanner）；`这个 rule 什么意思`
- 未命中组：`帮我写个 Python 脚本`、`今天天气如何`、`这个 UI 按钮怎么实现`（不指向 CLI）
- 预期：命中组激活 Skill；未命中组不激活（或激活后回答"不在适用边界"——SKILL.md §1 适用边界）

---

## TC-L3-03 Slot 提取与缺省（P0）

- 输入 1（全槽位）：`codescanner D:\demo\MyApp -s D:\sdk -o out -f html -l logs -c rules.json --compileCommandsDir ...\cxx --no-arkts`
- 预期：Slot 提取为 projectPath=D:\demo\MyApp、sdkPath=D:\sdk、outputDir=out、format=html、logDir=logs、ruleConfig=rules.json、compileCommandsDir=...\cxx、noArkts=true
- 输入 2（缺省）：`codescanner D:\demo\MyApp`
- 预期：outputDir 缺省 `output`、logDir 缺省 `scanner/logs`、format 缺省 `sarif`、sdkPath 走默认解析（需环境确认）、noCpp/noArkts 缺省 false
- 输入 3（位置参数歧义）：`codescanner -s D:\sdk D:\demo\MyApp`（`-s` 之外的首个路径为 projectPath）
- 预期：projectPath=D:\demo\MyApp（SKILL.md §3.3 定义）
- 对应 run-eval.js：C2 部分覆盖

---

## TC-L3-04 Intent 误触发边界（P1）

- 输入：`codescanner 报错说 Error: EPERM...`（应走 troubleshoot 而非 explain-result）；`codescanner 的输出有哪些文件`（output-info 而非 usage）；`能不能只扫 C++`（run-help + noCpp slot 而非 rule-info）
- 预期：按意图核心动作路由正确（SKILL.md §3.2 核心动作列）

---

## TC-L3-05 组合意图（P1）

- 输入：`扫描报错了，而且退出码是 2`（troubleshoot + output-info 交叉）
- 预期：先按退出码 2 → stderr/Logger 定位（error-troubleshooting.md §1 排查步骤 1），再给修复

---

## TC-L3-06 tool-availability 路由与两分支引导（P0）

- 前置：SKILL.md §3.2 Intent 表含 `tool-availability`；§4 Step 0.5；error-troubleshooting.md §2.6
- 输入（4 组）：
  - 分支 A（用户有工具）：`codescanner 命令找不到，但我下载过 command line tools`
  - 分支 B（用户无工具）：`command line tools 在哪下载？` / `codescanner: command not found`
  - 分支 C（版本 < 26.0.1）：`codescanner -v 显示 25.x，能扫描吗？`
  - 分支 D（版本 ≥ 26.0.1 但非期望部署）：`codescanner -v 显示旧版本`
- 步骤：按 Step 0.5 判定（命令存在 + **版本 ≥ 26.0.1**）→ 二选一引导 / 版本升级引导
- 预期：
  - 分支 A → 引导给出 command line tools 位置 → 给出绝对路径调用方式（无需配 PATH），并核 `-v` 版本 ≥ 26.0.1
  - 分支 B → 引导下载 [https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos) → 解压后给位置
  - 分支 C → **明确不支持扫描**，引导升级到 26.0.1+（不做扫描指导）
  - 分支 D → 用绝对路径调用目标部署；检查 PATH 顺序（error-troubleshooting.md §2.5/§2.6）
- 判定标准：扫描类请求必须先确认工具可用性且**版本 ≥ 26.0.1**（SKILL.md §5 约束 12/13），未确认或旧版直接给扫描命令即为失败
- 对应 run-eval.js：C9（13 项关键词断言，含版本门槛与下载链接负向自检）
