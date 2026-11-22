# 更新日志

## [1.1.0] - 2026-07-21

### 新增
- `references/execution_rules.md`：从 SKILL.md 中提取的执行细则补充文档，包含：Python>=3.7 要求、SDK路径回退逻辑、hilogtool候选路径、`hilog_collector.py` JSON输出字段定义与状态处理矩阵、媒体文件分析触发/结果矩阵、子Agent委派契约与结构化JSON返回格式。
- `references/platform_config.md`：平台特定命令参考，包含：OS/Shell检测命令、bash与powershell跨平台命令映射表（mkdir/文件检查/ls/find/grep/timestamp）、hilogtool二进制命名规则、SDK路径提取与回退逻辑、路径拼接规则。
### 修改
- `references/module_mapping.md`：错误码 `293xxx` 行补充 EL5 安全等级标注；`hiviewdfx_hicollie` 行移除无效的 "见hicollie.h" 文档路径。
- `references/report_template.md`： 阶段编号适配（阶段5→6, 阶段4→5）；报告标题增加 "HarmonyOS" 前缀；根因描述从"应用侧行为"改为"应用侧具体操作"。
- `references/tool_mapping.md`："文档RAG"更名为"HarmonyOS 文档RAG"；新增日志采集强制使用 `hilog_collector.py` 而非Agent内置工具的原则；阶段编号适配（3→4）。
### 重构
- `SKILL.md` — 核心工作流文档大幅重构：
  - 触发描述扩展：从泛化描述改为详细的触发条件清单（API调用失败、特定错误码、崩溃/冻屏日志等）
  - 工作流阶段重编号：0-5 → 0-6，深挖分析移至阶段4，项目源码移至阶段5，输出移至阶段6
  - 新增"执行承诺"节：强制所有阶段必须尝试执行并记录缺口，而非条件缺失时跳过（仅阶段4可根据置信度跳过）
  - 精简冗余内容：将内联命令序列委托至 `platform_config.md` 和 `execution_rules.md`
  - 阶段2新增步骤C：设备可达时采集未落盘的内存中hilog缓冲（`hilog -x`）
  - 新增重要提示节：全流程强制执行、阶段4置信度门槛、绝对路径使用、根因须追溯到应用侧操作

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-apifault-analysis` Skill
- 支持错误码、错误日志、执行失败等问题的结构化诊断
- 内置四阶段诊断流程：环境发现 → 线索提取与模块识别 → 分诊查询 → 深潜分析
- 新增参考资料：
  - `references/log_patterns.md`：日志解析模式
  - `references/module_mapping.md`：模块映射表（含代码仓/文档仓 URL）
  - `references/knowledge/{module_name}/`：各模块知识库（错误码、API 调用链、常见问题等）
- 新增脚本工具：
  - `references/scripts/media_file_analyzer.py`：媒体文件分析
  - `references/scripts/hilog_collector.py`：hilog 日志采集与解析
- 支持 CodeGenie 内置工具调用（文件读写、正则搜索、文档查询、命令执行等）
- 支持状态机转换序列追踪与日志自动采集落盘
