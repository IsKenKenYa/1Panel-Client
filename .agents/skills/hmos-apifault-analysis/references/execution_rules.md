# 执行规则详解（细节补充）

本文档是 SKILL.md 工作流的**细节补充**，只在需要查阅具体字段 / 路径 / 契约时读取。**工作流本身（阶段、步骤、分支、强制检查点、核心命令）以 SKILL.md 为唯一权威源，此处不再复述**——避免两份镜像带来的同步负担。

---

## 阶段0：环境发现 - 补充细节

### Python 版本要求
脚本使用了 f-string、`pathlib.Path`、`from __future__ import annotations`（新式类型注解）等 Python 3.7+ 特性，因此要求 **Python ≥3.7**。若探测到的版本低于 3.7，在诊断报告中标注并提示用户升级。

### SDK 路径兜底
读取 `local.properties` 的 `sdk.dir=` 失败时：先尝试 `build-profile.json5` 获取 API 版本信息；仍不可用则在对话中询问用户 SDK 路径。

### hilogtool 候选路径与存在性检查
（二进制名规则见 `platform_config.md §3`；存在性检查命令见 `platform_config.md §2`。）

**候选路径（按优先级）：**
1. `{sdk_path}/hms/toolchains/{binary_name}`
2. `{sdk_path}/default/hms/toolchains/{binary_name}`

**存在性检查：**
- bash → `test -f "{path}"`
- powershell → `Test-Path "{path}"`

**结果记录：** 找到 → 记录 `hilogtool_path`；两个候选路径都不存在 → `null`（并在诊断报告中注明"日志采集降级为 gzip，可能含乱码"）。只有确实搜索过、两个候选都不存在时才记 null——不得图省事直接跳过搜索（理由见 SKILL.md 阶段0 步骤4）。

---

## 阶段2：日志采集 - 脚本输出 JSON 字段

`hilog_collector.py` 始终输出一个 JSON 对象（即使部分采集 / 超时 / 异常），字段如下：

| 字段 | 含义 |
|------|------|
| `status` | `success` / `partial` / `no_logs` / `no_device` / `error` |
| `parsed_files` | 解析后的文本文件路径列表（按时间从旧到新排序） |
| `hilogtool_used` | 是否使用了 hilogtool（`false` = gzip 降级，可能含乱码） |
| `partial` | 是否部分结果 |
| `failed_files` | 拉取失败 / 被跳过的文件 |
| `reason` | 部分原因 |
| `timed_out` | 是否触达时间预算 |
| `elapsed_s` | 耗时秒 |

**状态处理矩阵（速查）：**

| status | 处理方式 |
|--------|---------|
| success | 执行步骤C采集内存缓冲区，再进入相关性检查 |
| partial | 注明"日志采集部分超时/不完整"后执行步骤C，再继续分析 |
| no_logs | 进入步骤B开启落盘（不执行步骤C） |
| no_device | 注明"hdc日志采集失败"后继续后续阶段（不执行步骤C） |
| error | 注明"hdc日志采集失败"后继续后续阶段（不执行步骤C） |

> 步骤A/B/C、采集工具约束、优先级1/2、相关性检查的完整规则见 SKILL.md 阶段2。

---

## 阶段3：媒体文件分析 - 路径确认与结果处理

**触发：** 错误码含 5400103 / 5400106 / 5400102，且日志涉及文件路径 / URI。

**文件路径确认优先级：**
1. `problem_description` 或 `code_snippet` 中的可识别路径
2. 从问题描述提取文件名 → glob 搜索：`**/*{filename}*`
3. 无明确文件名 → glob 搜索项目媒体文件：`**/*.{mp4,mkv,ts,m4a,aac,mp3,flac,wav,ogg,amr}`
4. 搜索结果多于一个 → 对话中询问用户确认
5. 无文件路径且搜索无结果 → 对话中询问用户提供路径
6. 用户无法提供 → 跳过本步骤

**脚本执行：**
```
{py_cmd} "{skill_dir}/references/scripts/media_file_analyzer.py" --file "{media_file_path}" --json
```

**结果处理矩阵：**

| overall_assessment | 置信度 | 后续动作 |
|-------------------|--------|---------|
| unsupported_format | 高 | 直接返回结论 |
| likely_corrupt / possibly_corrupt | 高 | 将文件损坏作为 rank-1 根因候选 |
| healthy | - | 文件无问题，深入排查其它原因 |
| unknown_format | 中 | 文件可能严重损坏 |
| analysis_error | 中 | 文件不可达 |

---

## 阶段4：深潜分析 - 子 Agent 委派与返回契约

**终端 Agent：** 主 Agent 用 Task 工具委派子 Agent 执行 4.1→4.5。
- 传入：`clues`、阶段3 分诊结论、`module_identified`、references 路径、宿主变量（host_os / host_shell / py_cmd / sdk_path / hilogtool_path）
- 返回：下方结构化结论 JSON

**CodeGenie：** 无子 Agent 能力 → 阶段4 在主上下文内顺序执行 4.1→4.5，在报告"根因分析"处标注"阶段4 未隔离 / CodeGenie 内联"。

**返回契约 JSON：**
```json
{
  "diagnostic_depth": "deep_dive",
  "root_cause_candidates": [
    {
      "rank": 1,
      "confidence": "high/medium/low",
      "description": "追溯到应用侧具体操作",
      "evidence": [
        {
          "finding": "具体发现",
          "source_type": "knowledge_base|documentation|code",
          "source_path": "文件路径"
        }
      ],
      "fix_hint": "修复建议（可选）"
    }
  ],
  "api_chain_findings": {},
  "notes": "其它说明（可选）"
}
```

---

## 阶段5：源码问题分析 - 检查清单

1. API 调用时序是否正确（对照 `api_chain.json`）
2. 权限声明是否完整（对照 `module.json5` 与 API 要求）
3. 语法问题（`builtin_check_editor_errors` 或降级方案 E）
4. 错误用法（结合诊断结论定位）
5. rank-1 根因表述为应用侧具体操作（区分"框架拦截机制"与"应用侧触发行为"）
