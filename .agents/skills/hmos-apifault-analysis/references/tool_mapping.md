# 工具映射表与适配约定

本 Skill 以「能力」描述工具调用，下表给出各环境对应的具名工具。**全局约定：下文统一用 CodeGenie 的 `builtin_*` 工具名描述；在终端 Agent（如 Claude Code、OpenCode 等 CLI）执行时，按下表替换为对应工具。** `builtin_web_rag` 与 `builtin_check_editor_errors` 在终端无 1:1 等价物，按下方降级方案 W / E 执行。

| 能力 | CodeGenie 工具 | 终端 Agent 工具 | 说明 |
| --- | --- | --- | --- |
| 读取文件 | `builtin_read_file` | `Read` | 支持分页（offset/limit）处理大文件 |
| 写入文件 | `builtin_write_file` | `Write` | 创建/覆盖写入文件（诊断报告） |
| 编辑文件 | `builtin_edit_file` | `Edit` | 精确替换文件中的文本 |
| glob 查找 | `builtin_glob` | `Glob` | 按 glob 模式查找文件（如 `**/*.ets`） |
| 正则搜索 | `builtin_grep` | `Grep` | 按正则搜索文件内容，可配合 glob 过滤 |
| 执行命令 | `builtin_execute_command` | `Bash` | hdc/python/curl 等，**30 秒超时** |
| 结构化任务 | `builtin_write_todo` | `TaskCreate`/`TaskUpdate` | 创建和管理任务列表 |
| HarmonyOS 文档 RAG | `builtin_web_rag` | **无 → 降级方案 W** | 查官方文档/ArkTS 语法/API 用法 |
| 编辑器语法检查 | `builtin_check_editor_errors` | **无 → 降级方案 E** | 检查文件语法错误与代码问题 |
| 派发子 Agent（阶段 4） | **无 → 主上下文内联执行** | `Agent` | 阶段 4 在终端委派子 Agent 隔离大块原始抓取；CodeGenie 无子 Agent，主上下文顺序执行 4.1→4.5 |

## 工具选择原则

- 文件读写/搜索 → 优先用 `builtin_*` 工具（终端：Read/Write/Edit/Glob/Grep）
- HarmonyOS 文档查询 → `builtin_web_rag`（终端：降级方案 W）
- 系统命令（hdc、python） → `builtin_execute_command`（终端：Bash，注意 30 秒超时）
- Gitee 代码仓原始文件 → `builtin_execute_command` + `curl`（终端：Bash + curl，web_rag 覆盖不到时）
- 日志采集（hilog）→ 必须用 `builtin_execute_command`（终端：Bash）跑本 skill 的 `hilog_collector.py` / `hilog -x`；**不得**用 agent 自带的日志采集工具替代。脚本产出结构化 `status`/`parsed_files`，自带工具不兼容（详见 SKILL.md 步骤5）。

## 降级方案 W — HarmonyOS 文档查询（终端 Agent，替代 `builtin_web_rag`）

1. `WebSearch` 按错误码 / API 名称 / 功能关键词检索
2. 复用本 Skill 既有的 Gitee raw 文件 `curl` 兜底（见阶段 3.2 步骤 2 / 4.2 / 4.4）
3. 命中后用 `WebFetch` 取正文要点

> 召回质量低于 CodeGenie 专属 RAG，在诊断报告「文档参考」处注明"文档来源为通用检索"。

## 降级方案 E — 语法/代码问题检查（终端 Agent，替代 `builtin_check_editor_errors`）

1. 优先用 `Bash` 跑项目编译器/linter：`.ts` → `tsc --noEmit`；`.ets` → hvigor lint / ohpm linter
2. 均不可用时退化为人工审查：用 `Grep` 找明显语法问题（括号/分号缺失、未闭合块等）

> 在诊断报告中注明实际使用的检查器（或"人工审查"）。
