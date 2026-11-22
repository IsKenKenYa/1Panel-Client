# 更新日志

## [1.4.0] - 2026-09-28

### 新增
- 新增 `references/react_native.md` React Native / RNOH JsCrash 案例库，覆盖 ArkTS TurboModule 返回值非 Promise 导致 "Failed to retrieve property from object" 崩溃场景，包含堆栈模式、HiLog 证据规则、根因分析和修复建议。
- `SKILL.md` 输出模板新增第 4 条修复建议格式要求：涉及代码修改的建议，每条修改使用一个 diff 代码块展示。
- `SKILL.md` 新增「修复建议 diff 格式示例」段，给出基于真实证据的 diff 代码块书写示意。
- 新增 SourceMap 反解前 UUID / 构建指纹校验门禁：反解前必须比对故障日志中的 `Fingerprint` 与 SourceMap 产物携带的构建指纹，一致才允许反解。
- `references/sourcemap-symbolication.md` 新增 UUID / 构建指纹校验要求：明确日志与产物指纹的来源和比对时机。
- 新增两种降级处理：日志缺少 `Fingerprint`/UUID 字段或产物缺少构建指纹时标记"无法校验"；日志与产物指纹不一致时标记"UUID/构建指纹不匹配"。

### 变更
- skill版本号升级至 v1.4.0
- `SKILL.md` 工作流步骤4（匹配错误模式）新增 RN/RNOH 专项路由：堆栈出现 `librnoh.so`、TurboModule、NAPI Promise 相关帧时，优先读取 `references/react_native.md` 匹配 RN/RNOH 案例库。
- `SKILL.md` 参考文件列表新增 `references/react_native.md` 条目。
- `SKILL.md` 证据链/输出模板新增「修复建议 diff 展示」规则：涉及代码修改的修复建议必须使用以 `diff` 为语言标记的围栏代码块，只展示增删行，不展示文件头和行号标注。
- `SKILL.md` 工作流步骤2（SourceMap 反解门禁）新增源码可达性检测：在当前工作目录查找 `build-profile.json5` 等文件，读取 `bundleName` 与故障进程名对比，一致即源码可达。
- `SKILL.md` 工作流步骤6（形成根因）新增源码级修复建议要求：当 SourceMap 已反解并定位到源码位置时，必须给出源码级修复建议。
- `SKILL.md` 输出格式模板的【修复建议】标题增加"源码可达时需给出源码级修复建议"标注。
- `SKILL.md` 输出格式要求新增可信度判定指引和多假设保留规则。
- `SKILL.md` 输出模板根因判断新增"可信度"字段（HIGH/MEDIUM/LOW）。
- `SKILL.md` 输出模板根本原因字段增加多假设要求。
- `SKILL.md` 输出模板关键证据链第 3 项调用栈证据改为分层展示。
- `SKILL.md` 输出格式要求新增 Error code 系统含义要求。
- `SKILL.md` 输出格式要求新增调用栈全帧展示要求（帧数≤15 时展示全部帧并逐帧注释）。
- `SKILL.md` 输出格式要求新增调用方向明确展示要求。
- `SKILL.md` 输出格式要求新增末尾补充说明要求。
- `SKILL.md` 输出模板末尾新增补充说明段。
- 分析报告模板新增"日志 Fingerprint（构建指纹/UUID）"和"UUID 校验"字段。
- 证据链"SourceMap 映射证据"增加日志指纹与产物指纹的比对结果。
- SourceMap 匹配要求由版本等字段扩展为同时要求构建指纹匹配。
- 反解结果校验将 UUID / 构建指纹校验列为前置步骤，指纹不一致的结果一律不得作为证据。

## [1.3.0] - 2026-09-01

### 新增
- 新增 SourceMap 反解门禁：关键业务栈未还原时，优先使用匹配版本的 `sourceMaps.json` 和 `hstack` 还原源码位置；启用名称混淆时同时使用 `nameCache.json`。
- 新增 `references/sourcemap-symbolication.md`，说明反解输入、命令、结果校验和失败降级规则。
- 内置跨平台 `hstack` 工具包，提供 Windows、Linux 和 macOS 启动入口，用户无需另行下载 DevEco Studio 命令行工具。

### 变更
- 报告增加 SourceMap 反解状态、映射输入和原始栈到源码栈的映射证据；未反解时将补充匹配构建产物并重新分析作为第一项建议。
- SourceMap 反解流程增加 Node.js 与内置工具完整性检查，`mappings.wasm` 作为完整二进制随仓库发布，不依赖 Git LFS 拉取。
- skill版本号升级至 v1.3.0

## [1.2.0] - 2026-08-14

### 新增
- 新增 OOM 快照联动分析：当 JS Crash 明确定性为 `OutOfMemoryError` / OOM 且用户提供 `.rawheap` 或 `.heapsnapshot` 时，自动调用 `jsleak-analysis` Skill 继续定位疑似泄漏对象。
- 联合报告新增 OOM 快照分析部分，输出最严重疑似泄漏对象、Retained Size、最短强引用链、JS Leak 三级根因及其与本次 OOM 的关联可信度。

### 变更
- 明确先完成 JS Crash 定性，再执行 JS Leak 快照流程；日志与快照无法确认属于同一场景时，不将疑似泄漏对象直接认定为 OOM 根因。
- 同步更新 OOM 故障模式库和错误模式表，统一要求在已有快照时执行 JS Leak 分析。
- 更新 `SKILL.md` 文档内容，完善技能触发条件：新增排除规则，当日志为 cppcrash/freeze 或用户询问原生/C++层崩溃且无 JS/ArkTS 错误字段时，不应调用此技能
- 更新 `references/fault-mode-library.md` 故障模式库，大幅扩充三级根因条目：新增 `TypeError`（12 条）、`SyntaxError`（16 条）、`RangeError`（9 条）二级根因及对应三级根因，移除 `AggregateError`，重构表格格式

## [1.1.0] - 2026-07-15

### 新增
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-jscrash-analysis` Skill
- 支持 HarmonyOS/OpenHarmony JS/ArkTS 层闪退故障分析
- 支持 Reason/Error name/Error message/Error code 多维度分类
- 内置五步工作流：关键信息提取 → 故障类型分类 → 错误模式匹配 → 堆栈分析 → 根因形成
- 支持 JSError 三级根因匹配（ReferenceError、TypeError、Error、BusinessError、OutOfMemoryError 等）
- 新增参考资料：
  - `references/fault-mode-library.md`：JSError 一级/二级/三级根因库
  - `references/jscrash-patterns.md`：JS Crash 错误模式与修复建议矩阵
- 支持 SourceMap 缺失时的 raw stack 分析
- 支持 HybridStack / NAPI / libark_jsruntime 桥接证据分析
