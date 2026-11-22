# 诊断报告模板（阶段 6 输出时读取）

阶段 6「结果输出」读取本文件，按下述模板与要求填充字段，写入 `diagnosis/diagnosis_{timestamp}.md`。

## 报告 Markdown 模板

报告必须严格遵循以下 Markdown 模板：

```markdown
# HarmonyOS 问题诊断报告

> 诊断时间：{YYYY-MM-DD HH:mm:ss} | 诊断深度：{triage 或 deep_dive} | 模块：{module_identified}

## 问题摘要

{一句话问题摘要}

---

## 项目上下文

{仅在阶段 5 有分析结果时展示本节}

- **项目源码分布**：{各类型文件数量}
- **目标 API 版本**：{从 build-profile.json5 提取}
- **已声明权限**：{从 module.json5 提取的权限列表}
- **相关源码文件**：{定位到的与问题相关的文件路径列表}

---

## 线索提取

| 类别 | 内容 |
|------|------|
| 错误码 | {error_codes；无则写"无"} |
| 事件名 | {event_names；无则写"无"} |
| 模块 | {modules} |
| API | {api_names；无则写"无"} |
| DOMAIN | {domains；无则写"无"} |
| .so 库 | {so_libraries；无则写"无"} |
| hilog domain_id | {hilog_domain_ids；无则写"无"} |

### 调用栈关键行

{- 每条一个列表项；无则写"无"}

### 状态转换时间线

{- 每条一行；无则写"无状态转换事件"}

### 媒体文件分析

{仅在执行了文件分析时展示本小节，否则省略}

- **文件路径**：{file_path}
- **检测格式**：{format_detected}
- **Media Kit 支持**：{supported_by_media_kit}
- **评估结论**：{overall_assessment}
- **发现问题**：{issues 列表；无则写"无"}

---

## 知识库匹配

### {source 文件名}

{content 匹配到的内容摘要}

{多条匹配每条一个 ### 小节；无匹配则写"无知识库匹配"}

## 文档参考

- **{source}**：{relevant_content 摘要} — [链接]({url})
{多条参考分行列出；无参考则写"无文档参考"}

---

## 根因分析

### 候选根因 #{rank}（置信度：{high/medium/low}）

{根因描述，必须追溯到应用侧具体操作}

**证据：**

{- 每条 evidence 一个列表项}

**证据来源：**

{- 每条 evidence_source 一行，格式：`{type}`: {path}}

{多个根因候选按 rank 顺序排列}

---

## 修复建议

### 针对候选根因 #{for_candidate}

1. {步骤1}
2. {步骤2}
{编号列表}

**参考文档：**

{- 每条 reference 一个 URL 链接}

{多个候选根因的修复建议按 for_candidate 顺序排列}
```

## 诊断置信度标准

- **high**：有明确的代码位置 + 错误处理逻辑 + 知识库/文档确认
- **medium**：有文档参考或知识库匹配，但缺少代码级确认
- **low**：仅基于推测或间接证据

## 关键要求

- `diagnostic_depth` 必须准确反映实际执行路径（"triage" 或 "deep_dive"）
- `module_identified` 若阶段 1 未能识别模块，必须为 "未识别"
- 每个根因候选的证据来源必须标注来源类型（knowledge_base / documentation / code）
- 修复建议必须具体、可操作
- **根因必须追溯到应用侧具体操作**：rank-1 的根因描述中必须包含应用侧具体操作
- Markdown 必须格式完整、各节标题层级清晰
- 若 `media_file_analysis` 未执行，省略该小节
- 若 `project_analysis` 未获取到信息，省略"项目上下文"节
