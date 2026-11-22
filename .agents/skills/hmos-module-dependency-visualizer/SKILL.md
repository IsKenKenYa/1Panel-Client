---
name: hmos-module-dependency-visualizer
description: 采集并可视化 HarmonyOS/OpenHarmony 应用 ArkTS 模块的依赖关系，聚合文件级依赖为模块级，产出含循环依赖检测与扇入/扇出排行的交互式 HTML 依赖图和 Markdown 分析报告。支持 hdc 真机一键采集与本地 *_dependency_graph.txt 日志解析两种模式（工具为 skill 内嵌单文件，详见正文命令表）。Use when 用户提到 模块依赖、依赖图、依赖可视化、循环依赖、被依赖排行、dependency_graph.txt、modtree、采集应用依赖、分析抖音/头条等鸿蒙应用的模块结构。不处理启动性能、卡顿、内存、功耗等性能优化问题——「冷启动」仅指采集所需的完全重启，与启动速度无关。
license: MIT
metadata:
  author: wanghaha1204
  version: "1.0.8"
  created: "2026-10-19"
  updated: "2026-11-12"
  homepage: https://gitcode.com/wanghaha1204/module_tree
  keywords: ["modtree", "module-dependency", "dependency-graph", "hdc", "dfx", "visualization", "circular-dependency"]
compatibility: Windows x64（modtree.exe 单文件已内置前端模板）。真机采集模式需 hdc 在 PATH 且 USB 连接 HarmonyOS/OpenHarmony 设备（已开启开发者模式与 USB 调试）；本地日志分析模式无额外依赖。
---

# hmos-module-dependency-visualizer：模块依赖采集与可视化

本 skill **自带工具**：`scripts/modtree.exe`（Windows x64 单文件，前端模板已内置，零外部依赖）。直接执行即可，**不要**引导用户另行下载或从源码编译。工具源码仓库：https://gitcode.com/wanghaha1204/module_tree

## Workflow（总流程）

### Input

- 模式 A（真机采集）：目标应用包名（如 `com.ss.hm.ugc.aweme`），可选主 Ability 名与采集延时（默认 3000ms）
- 模式 B（本地解析）：依赖日志文件路径（`*_dependency_graph.txt`），可选输出路径

### Process

1. 按决策树（§3）判定模式与前置条件
2. 模式 A 走 SOP-1（§4），模式 B 走 SOP-2（§5）
3. 按输出契约（§1）从 stdout 判定成败
4. 读取统计与 Markdown 报告，汇报结论与产物路径

### Output

- 交互式 HTML 依赖图（DAG 拓扑布局，实线=静态导入、虚线=动态加载）+ Markdown 分析报告 + 原始采集日志（txt）
- 概览统计：文件级节点数 / 聚合后模块数 / 依赖边数 / 业务域数 / 循环依赖组数

## 1. 输出契约（先读，决定成败判定）

| stdout 标记 | 含义 | 动作 |
|---|---|---|
| `[+] 解析完成: 共 N 个文件级节点` | 日志解析成功 | 继续 |
| `[+] 分析完成: 模块数 N \| 依赖边数 N \| 业务域数 N \| 循环依赖 N 组`（单行） | 聚合分析成功 | 记录统计用于汇报 |
| `[OK] 完成！耗时 X 秒` + `HTML:` / `Markdown:` 路径 | 全流程成功（退出码 0） | 汇报产物路径 |
| `[ERROR] ...` | 致命失败（退出码非 0） | 转决策树降级分支 |
| `[WARN] ...` | 非致命告警（不影响退出码） | 继续，汇报时说明 |
| `[>] 正在清理设备侧旧依赖日志` | 拉起前预清理设备旧文件，保证拉到本次冷启动的新文件 | 信息性提示 |
| `拉取的日志不完整（可能仍在写入中）` | 拉到写入中的半成品快照，轮询继续等待重拉 | 属正常重试，非失败 |
| `[>] 正在恢复设备 DFX 参数原值` / `[+] DFX 参数已恢复` | 采集结束，设备系统参数已还原（原先未设置则置 0） | 信息性提示 |
| `[!] 警告: 自动拉取日志超时` + `[r]/[m]/[q]` 菜单 | 采集进入人工交互分支 | 按安全红线 3 处理，禁止无限等待 |

补充契约：

- 成功后工具自动调用系统默认浏览器打开 HTML，属预期行为，无需重复打开
- 汇报数字必须来自 stdout 或报告产物，禁止臆造

## 2. 工具定位与命令表

工具路径：本 SKILL.md 同级的 `scripts/modtree.exe`（路径固定，无需搜索文件系统即可定位；下表以 `modtree` 代称）。

交互约束（无论当前环境能否立即执行都必须遵守）：

- 回复必须先给出完整执行方案：`scripts/modtree.exe` 工具路径 + 具体命令 + stdout 成功标志（`[OK] 完成！耗时` 与 `HTML:` / `Markdown:` 路径）+ 产物说明（成功后浏览器自动打开 HTML 属预期行为）
- 用户只给日志文件名而未给路径：先询问完整路径，同时给出待执行的完整命令
- 当前环境无执行能力（如仅有读取工具）：给出执行方案与待确认问题后即完成回复，交由具备执行能力的环境运行；禁止以「无可用工具」为由不展现 skill 能力
- 路径即事实：`scripts/modtree.exe` 为约 9MB 二进制文件，禁止用读取工具验证其存在或内容（极耗时且无意义）；references/ 仅在参考节标注的触发场景下读取

| 命令 | 说明 | 样例 |
|---|---|---|
| `modtree -bundle <包名>` | 真机全自动采集：DFX 配置 → 强杀冷启动 → 拉起 → 轮询拉取 → 出图 | `scripts/modtree.exe -bundle com.ss.hm.ugc.aweme` |
| `modtree -bundle <包名> -ability <名>` | 手动指定拉起的 Ability（缺省自动 bm dump 探测主入口） | `scripts/modtree.exe -bundle com.example.app -ability EntryAbility` |
| `modtree -bundle <包名> -duration <毫秒>` | 指定采集延时（默认 3000，大型应用调大保证模块加载完整） | `scripts/modtree.exe -bundle com.example.app -duration 5000` |
| `modtree [-o <输出.html>] <日志文件>` | 解析本地依赖日志出报告 | `scripts/modtree.exe -o report.html app_dependency_graph.txt` |
| `modtree -h` | 查看命令行帮助 | — |
| `modtree -tui` | 交互式终端向导（需真人终端，Agent 禁用） | — |

注意：

- 产物固定写入**当前工作目录**（`-o` 仅改 HTML 路径，MD 报告同名替换扩展名）——执行前切换到专用输出目录或显式 `-o`
- **禁止无参数执行**：会进入交互式 TUI 向导并阻塞

## 3. 决策树（模式选择与降级）

```text
用户需求是什么？
├─ 提供了本地日志文件（*_dependency_graph.txt）
│   └─ 模式 B：本地解析（SOP-2），无需设备
├─ 问启动性能 / 卡顿 / 启动速度优化
│   └─ 不适用本 skill：不做任何性能分析，「冷启动」仅指采集流程的完全重启 → 转性能分析类 skill
├─ 要看某真机应用的模块依赖
│   ├─ 只给应用名（如"抖音"）→ 推断包名后必须反述确认再执行（抖音=com.ss.hm.ugc.aweme，头条=com.ss.hm.article.news）
│   ├─ 设备未连接 / hdc 不可用 → 引导连接设备并开 USB 调试，或转模式 B
│   └─ 包名与设备就绪 → 模式 A：真机采集（SOP-1）
├─ 采集拉取超时（进入 [r]/[m]/[q] 交互菜单）
│   └─ 终止进程 → 说明原因（应用未拉起 / 日志未落盘）→ 请用户手动打开应用到首页后重试，或由用户手动拉取日志转模式 B
└─ 用户反馈"缺模块 / 图不完整"
    └─ 用 `-duration 5000~10000` 重新采集（采集延时不足导致模块未加载完即落盘）
```

## 4. SOP-1：真机自动采集（有设备副作用，严格按序）

1. [确认门] 完成「采集前三问」（§7），任一问未通过禁止执行
2. [准备] 切换到专用输出目录，执行 `modtree -bundle <包名> [-o <输出名>.html]`；exec 超时设为 ≥120 秒，stdin 预置 `q`（防止超时菜单阻塞）
3. [等待] 工具自动完成 DFX 配置、强杀冷启动、设备侧旧日志预清理、拉起应用与静默轮询（全程约 15~30 秒）；期间禁止重复发起第二次采集——并发会竞态修改 DFX 参数并对同一应用双重冷启动
4. [检查] 按输出契约判定：成功 → 读取产物并汇报统计与路径；`[ERROR]` → 转决策树降级分支（无论成败，采集结束后工具自动恢复 DFX 参数原值）
5. [逃逸] 若进入 `[r]/[m]/[q]` 交互菜单：终止进程并按降级策略处理，禁止无限等待

## 5. SOP-2：本地日志分析

1. [检查门] 确认日志文件存在且非空（`*_dependency_graph.txt`）；用户仅给文件名未给路径时，先询问路径并同步给出将执行的完整命令（见 §2 交互约束）
2. [准备] 在输出目录执行 `modtree -o <输出名>.html <日志路径>`
3. [汇报] 读取 stdout 统计与 Markdown 报告，汇报概览数字、循环依赖、头部模块与产物路径；需解读报告章节/视觉约定或回答依赖细节问题时，**MUST 先读 [references/report-guide.md](references/report-guide.md)**

## 6. 安全红线

1. 禁止对未经用户确认的应用执行 `-bundle`：采集会 `kill -9` 目标应用进程，并在采集期间临时修改设备系统参数（`persist.ark.properties`、`persist.ark.importDuration`，结束后自动恢复原值），属破坏性操作
2. 禁止无参数执行 modtree（会进入交互式 TUI 向导并阻塞）
3. exec 必须设置超时；自动拉取超时后工具阻塞在 stdin 交互菜单，禁止无限等待
4. 禁止臆造依赖关系与统计数字；一切结论必须来自工具 stdout 或生成的 HTML/MD 产物——报告数字是用户架构决策的依据，错误数字比无数字危害更大
5. `-o` 指定的输出路径已存在同名文件时会被直接覆盖，覆盖前必须向用户确认

## 7. 检查清单（采集前三问 + 执行后核验）

### 采集前三问（模式 A 执行前自检，SOP-1 步骤 1 引用）

- [ ] 包名已经用户**反述确认**？（反述时按安全红线 1 说明破坏性：采集会 `kill -9` 目标应用进程并在采集期间临时修改设备 DFX 系统参数，包名错误会操作错误目标，结束后自动恢复；仅给应用名时先完成映射：抖音=com.ss.hm.ugc.aweme，头条=com.ss.hm.article.news，其余必须询问）
- [ ] 设备在线？（`hdc list targets` 非破坏验证；无设备走决策树降级）
- [ ] 专用输出目录已定且无同名冲突？（`-o` 会直接覆盖既有文件）

### 执行后核验

- [ ] stdout 出现 `[OK] 完成` 且退出码 0，产物路径已报告
- [ ] 概览统计（模块数 / 边数 / 循环组数）来自工具实际输出
- [ ] 存在循环依赖时已主动提示（报告将其标为警告）

## 8. 快速参考（高频场景）

| 用户输入 | 动作 | 要点 |
|---|---|---|
| "分析一下抖音的模块依赖" | `modtree -bundle com.ss.hm.ugc.aweme` | 应用名→包名映射先确认；真机模式 |
| 已有 *_dependency_graph.txt 日志 | `modtree <文件>` | 本地模式，无需设备 |
| "哪些模块循环依赖了？" | 读 MD `## 循环依赖` 章节 | 章节缺失即 0 组 |
| "被依赖最多的模块是什么？" | 读 MD `## 扇入排行` 表 | 被依赖=扇入，依赖别人=扇出 |
| "哪些模块是动态加载的？" | HTML 虚线边（dynamic） | specifier 可溯源原始导入语句 |
| "模块 A 依赖了谁、被谁依赖？" | 读 MD `## 模块依赖邻接表` | 每模块列出双向清单及次数 |
| 采集失败 / 应用拉不起 | 加 `-ability` 显式指定主 Ability | 部分应用主 Ability 非标准名且探测失败 |
| 报告缺模块 / 图不完整 | `-duration 5000~10000` 重新采集 | 延时不足导致落盘过早 |

## 参考（按需加载纪律）

- 依赖图日志格式与模块名提取规则 → [references/log-format.md](references/log-format.md)（仅日志格式疑问时读）
- HTML / Markdown 报告解读指南 → [references/report-guide.md](references/report-guide.md)（汇报报告细节前 MUST 读）
- 使用指南（面向人类读者） → [assets/README.md](assets/README.md)（Agent 无需加载）
- 测试用例 → `test-cases/`（trigger.md 触发验证 + functional.md 功能验证，由 hmos-skill-test-runner 流水线在隔离子进程中执行；Agent 日常无需读取）
- **Do NOT Load**：真机采集执行阶段（SOP-1 步骤 2~5）无需读任何 references/；模式 B 仅解析出图时同样无需读
