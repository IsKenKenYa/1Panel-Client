## 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：hmos-lazy-import-analysis  
**类型**：functional（功能验证）

#### 输入

请描述 hmos-lazy-import-analysis 的完整工作流程，从输入收集到最终交付，每个阶段的职责是什么？

#### 预期输出

**验证标准**：

- 应列出 Phase 0-6 的完整流程（输入收集 → 报表生成 → 候选识别 → 副作用预判 → 批量确认 → 引用定位+建议报告 → 修改应用）
- 应说明 Phase 0 需一次问齐两项输入：应用源码根目录、redundant file 来源（设备拉取 app_name 或本地 txt 路径）
- 应说明 Phase 1/2/5 有脚本执行（redundant_file_analyzer.py、analyze_report.py、gen_safe_importers_report.py、xlsx_to_md.py），Phase 6 应用由脚本执行
- 应说明 Phase 3 副作用预判由 agent 读源码完成，不调用脚本
- 应说明默认只产出建议报告（lazy_import_suggestions_{date}.md），Phase 6 修改应用是可选阶段
- 应说明最终交付物包含 4 个产出物路径并告知用户

**应包含**：Phase 0, Phase 3, 建议报告, Phase 6

---

### 测试用例：FUNC-002

**skill**：hmos-lazy-import-analysis  
**类型**：functional（功能验证）

#### 输入

Phase 2 输出的 has_toplevel 列取值有 false / true / maybe / skip / unresolved，各是什么含义？分别怎么处理？它和脚本 stdout 的 verdict 是什么关系？

#### 预期输出

**验证标准**：

- 应说明 false = 无顶层代码，天然可 lazy，直接进 safe 候选，无需读码
- 应说明 true = 有顶层代码，进 Phase 3 副作用预判
- 应说明 maybe = 存疑（装饰器/不可解析包），进 Phase 3 按 references/lazy_safety_rules.md 细化
- 应说明 skip / unresolved = .so、系统模块或无法定位，跳过并在报告中说明
- 应明确指出 has_toplevel 与脚本 stdout verdict 语义相反，以 SKILL.md Phase 2 语义表为准

**应包含**：false, true, maybe, 语义相反

**不应包含**：has_toplevel=false 需要读码

---

### 测试用例：FUNC-003

**skill**：hmos-lazy-import-analysis  
**类型**：functional（功能验证）

#### 输入

用户要求直接把 lazy-import 修改写入源码。Phase 6 能不能跳过 diff 预览，生成并一步应用？

#### 预期输出

**验证标准**：

- 应明确回答不可以：顺序不可绕过，先生成 diff（预览，不写源码）→ 用户选择 → 按计划应用
- 应说明脚本 `--apply` 必须携带预览产出的计划文件（lazy_apply_plan_{time}.json），无计划文件时直接拒绝执行
- 应说明用户在看到 diff 之后有三种选择：应用该计划 / 调整范围重新预览（--rows）/ 不应用
- 应说明应用时脚本按计划复核当前源码，内容一致才写入，不一致的行跳过并提示重新预览
- 应说明仅 `可lazy? = 可` 行做机械改写（`import {...} from` → `import lazy {...} from`）

**应包含**：diff, 计划文件, 拒绝执行

---

### 测试用例：FUNC-004

**skill**：hmos-lazy-import-analysis  
**类型**：functional（功能验证）

#### 输入

一个候选模块被预判为 critical（比如顶层代码修改了 AppStorage），最终报告该怎么写？这种模块的治理重构能自动应用吗？

#### 预期输出

**验证标准**：

- 应说明 critical 模块默认排除在 lazy 建议外，用户可强制纳入但需记录风险提示
- 应说明不可 lazy 的模块必须给出完整证据链：报表 why 原文 → 源头文件:行号 → 顶层代码片段原文 → 被调实现 → 命中 C1-C5 条目
- 应给出治理建议：顶层副作用代码移入导出的 initialize() 函数、使用方显式调用（官方治理模式）
- 应明确说明 critical/unknown 的治理重构属结构性代码变更，不自动应用，由用户按报告人工实施

**应包含**：C1, initialize(), 不自动应用

---

### 测试用例：FUNC-005

**skill**：hmos-lazy-import-analysis  
**类型**：functional（功能验证）

#### 输入

safe_importers 报告里有个 parentModule 文件叫 pages/Index.ets，是不是 barrel 文件？它里面的 import 能改成 lazy 吗？

#### 预期输出

**验证标准**：

- 应说明判据是引用行本身是否 `export ... from` re-export，不按 parentModule 文件名判定 barrel
- 应说明 pages/Index.ets 这类 @Entry 页面是普通使用方，其中的普通 `import ... from` 可 lazy
- 应说明 `export ... from` re-export 的行脚本会标注 `暂不可(re-export)`，不给出改写
- 应提醒不能因文件名为 Index.ets 就漏给建议（这是常见错误，SKILL.md 常见错误表有列）

**应包含**：@Entry, 暂不可, export ... from

---

### 测试用例：FUNC-006

**skill**：hmos-lazy-import-analysis  
**类型**：functional（功能验证）

#### 输入

redundant file 报告我只有本地的 txt 文件，手头没有真机，这个 skill 还能用吗？另外请说明两种 redundant file 来源模式分别需要什么条件、报告是怎么拿到的，以及 Phase 1 报表生成会产出什么文件、里面有哪些 sheet？

#### 预期输出

**验证标准**：

- 应说明本地文件模式可用：`redundant_file_analyzer.py --file {txt路径}`，无需连接设备
- 应说明设备拉取模式需要 hdc 与真机：用户提供 app_name 后拉取由 Phase 1 脚本自动完成，无需手动执行 hdc；脚本失败（无设备/hdc 不可用）时会打印手动命令
- 应说明两种来源模式在 Phase 0 一次问齐、二选一即可
- 应说明 Phase 1 产出 `{名称}_redundant_file_report.xlsx`，含 Summary / Used Files / Unused Files 三个 sheet

**应包含**：--file, hdc
