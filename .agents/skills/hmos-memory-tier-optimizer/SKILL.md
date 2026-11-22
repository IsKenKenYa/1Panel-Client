---
name: hmos-memory-tier-optimizer
description: HarmonyOS 应用低端机内存分档优化 Skill，覆盖内存采集、数据分析、分档候选方案、用户确认、代码修改与审查、构建安装、优化后复测、patch 与报告生成全闭环。当用户提供 HarmonyOS 应用内存占用过高、需要在低端机上做内存分档降级、要求优化前后内存对比、或需要执行完整内存优化闭环时，必须使用此技能。即使用户只说"帮我优化这个应用的内存"、"低端机内存超标怎么降"、"做个内存前后对比"，也应立即触发此技能。
agent_created: true
user-invocable: true
license: MIT
compatibility: HarmonyOS 应用开发环境。Requires hdc (HarmonyOS Device Connector), DevEco Studio SDK, Java 11+, Node.js 16+. Supports Windows/macOS/Linux.
metadata:
  author: HarmonyOS Memory Optimization
  version: "2.0.0"
  created: "2026-07-31"
  updated: "2026-08-04"
---

# 内存分档优化技能

## 概述

本技能用于系统化优化 HarmonyOS 应用在低端机上的内存占用，覆盖优化前采集、数据分析、分档候选方案、用户确认、代码修改与审查、构建安装、优化后复测、patch 与报告生成全流程。

---

## 目录结构

```text
hmos-memory-tier-optimizer/
├── SKILL.md                      # 主指令文件（本文件）
├── scripts/                      # 可执行脚本（区分平台）
│   ├── windows/                  # collect_memory.bat / build_template.bat
│   ├── linux/                    # collect_memory.sh / build_template.sh
│   ├── macos/                    # collect_memory.sh / build_template.sh
│   └── scroll_analyzer.py        # 跨平台 Python（长列表滚动分析）
├── references/                   # 参考文档（检测规则、方案库、审查规则等）
└── test_cases/                   # 测试用例
```

按当前系统选择对应平台脚本：Windows 用 `scripts/windows/*.bat`，macOS 用 `scripts/macos/*.sh`，Linux 用 `scripts/linux/*.sh`。`scroll_analyzer.py` 跨平台，用 `python3` 运行。

---

## 工具使用指南

执行本 skill 中的操作时，使用以下工具映射，不要用 Bash 替代专用工具：

| 任务 | 使用工具 | 不要用 |
|-------------|-------------|----------|
| 搜索文件（如 `*.ets`/`build-profile.json5`） | `Glob` (pattern="**/*.ets") | Bash `find`/`dir` |
| 搜索代码内容（如 `cachedCount`、`setInterval`） | `Grep` (pattern="关键词", glob="*.ets") | Bash `grep -r` |
| 读取文件内容 | `Read` | Bash `cat`/`type` |
| 执行命令（hdc、git、构建、python 脚本） | `Bash` | — |
| 运行 Python 分析脚本 | `Bash` (`python3 scripts/scroll_analyzer.py ...`) | — |

---

## 安全原则

- 分析阶段只输出候选方案，不自动修改代码。
- 执行代码修改前，必须让用户确认优化方案、影响文件和验证方式。
- 不自动回退用户工作区。生成 patch 后保留修改，由用户决定提交、继续调整或回退。
- 开始修改前先检查工作区状态；遇到用户已有改动时，只在相关文件上谨慎合并，不覆盖未知改动。
- patch 以真实文件状态为准，优先用 `git diff` 或等价方式生成，不依赖对话上下文里的修改清单。
- 清理构建缓存前必须确认当前目录是 HarmonyOS 项目根目录。

---

## 数据目录约定

默认代码项目目录为当前工作目录。工作目录建议放在代码目录同级：

```text
../AppCode/
  TestData/
    before/
    after/
    comparison/
  Analysis/
  Patches/
  Build/
```

采集输出契约（采集阶段必须遵守）：

| 文件 | 路径 |
|------|------|
| meminfo | `{dataDir}/meminfo/{bundleName}_{pid}.txt` |
| UI 树 | `{dataDir}/uiTree/ui_tree.json` |
| 截图 | `{dataDir}/screenshot.png` |

PSS 口径：`单项类型 PSS = PSS Total + SwapPss Total`；`Total PSS = meminfo 中的 Total PSS，不额外叠加 Swap`。

---

## 工作流程

### 步骤一：优化前采集

通过 `hdc` 采集目标应用在目标场景下的 meminfo、UI 树和截图。

> 调用 `scripts/{windows,linux,macos}/collect_memory`，输出到 `../AppCode/TestData/before`
📖 读取 `references/memory_analysis_guide.md`（meminfo 解读与 PSS 口径）

**一键脚本**（按平台选择）：

```bash
# Windows
scripts\windows\collect_memory.bat [bundleName] [outputDir]
# macOS / Linux
scripts/macos/collect_memory.sh [bundleName] [outputDir]   # 或 scripts/linux/...
```

脚本默认自动检测前台应用（未指定 `bundleName` 时），创建 `meminfo/`、`uiTree/` 子目录并生成 `screenshot.png`。如本机 DevEco/hdc 路径不同，先修改脚本顶部的 `HDC` 变量，或使用 PATH 中的 `hdc`。

**手动命令**（脚本不可用时）：

```bash
hdc list targets                                    # 确认设备连接
hdc shell "aa dump -l"                              # 检测前台应用，记录 bundleName/abilityName
hdc shell "ps -ef | grep <bundleName> | grep -v grep"   # 获取 PID
hdc shell "hidumper --mem <PID>"                    # 采集 meminfo
hdc shell "uitest dumpLayout -p /data/local/tmp/ui_tree.json"
hdc shell "uitest screenCap -p /data/local/tmp/screenshot.png"
hdc file recv /data/local/tmp/ui_tree.json ./uiTree/ui_tree.json
hdc file recv /data/local/tmp/screenshot.png ./screenshot.png
```

记录：`bundleName`、完整 `abilityName`、目标场景操作步骤、采集时间和设备信息。`hdc` 无法连接时，先确认设备连接、授权、亮屏解锁和 DevEco/hdc 占用状态。

✅ **完成标准**: meminfo、UI 树、截图已保存到 `TestData/before/`，bundleName 和 abilityName 已记录。

### 步骤二：分析瓶颈与候选方案

读取 `before` 数据，定位相关 ArkTS/C-API/Flutter/RN 代码，输出候选内存优化方案。**此阶段不修改代码。**

> 调用 `python3 scripts/scroll_analyzer.py <projectDir> --output <output.json>`（当 ark ts heap 占比 > 30% 或 UI 树含 List/Grid/WaterFlow 时；结果中的 `issues` 列表对应规则 1 的 cachedCount 检测）

**scroll_analyzer.py 输出解读**（JSON 格式）：
- `total_files` / `total_components` / `files_with_issues`：扫描文件数、滚动组件数、含问题文件数
- `high_severity_issues` / `medium_severity_issues` / `low_severity_issues`：各严重级别问题计数
- `files[].issues[]`：问题列表，每项含 `severity`（high/medium/low/error）、`message`（如"cachedCount 硬编码为 5"）
- `files[].components[]`：检测到的滚动组件，含 `component_type`（List/Grid/WaterFlow）、`severity`、`suggestion`（建议值）

命中 `issues` 时可直接定位到对应文件，跳过规则 1 的手动 Grep 扫描。
📖 读取 `references/detection_rules.md`（14 条检测规则的触发条件与 Grep 关键词）
📖 读取 `references/device_level_tiering.md`（低端机分档标准）
📖 读取 `references/code_location_guide.md`（代码定位方法）
📖 按瓶颈类型读取 `references/scheme_*.md`（12 个分档优化方案库）

**代码仓目录确定规则**（按优先级）：
1. 用户显式指定 → 直接使用
2. 未指定 → `Glob` 搜索当前工作目录下的 `build-profile.json5`，读取 `AppScope/app.json5` 的 `bundleName`，列出候选并询问用户确认
3. 搜索无结果且用户未指定 → 仅输出分析报告，不执行代码修改

**两种分析模式**：

```
═══ 模式判断 ═══
有 meminfo 数据 → 快速模式（数据驱动，仅扫描与占比相关的规则）
无 meminfo 数据 / 用户要求全面审查 → 完整模式（全仓扫描，按项目类型过滤规则）
```

**快速模式**（根据 meminfo 占比选择规则，不扫描全部 14 条）：

| 占比特征 | 优先检测规则 |
|----------|-------------|
| native heap > 40% | 规则 3(图片)、4(泄漏)、5(Web预加载)、6(多媒体)、9(QuickJS)、10/11(Flutter*)、12(RN*) |
| ark ts heap > 35% | 规则 1(cachedCount)、7(Tabs)、8(不可见组件) |
| GL/Graph 占比高 | 规则 3(图片优化) |
| PSS 持续增长(>1MB/min) | 规则 4(泄漏) |
| UI 树含 Web 组件 | 追加规则 5、13、14 |
| UI 树含 Video 组件 | 追加规则 6 |

*规则 10/11 仅 Flutter 项目适用，规则 12 仅 RN 项目适用 → 先 Grep 检测项目类型。

**完整模式**：先 Grep 检测项目类型（`src/flutter/`→Flutter、`@rnoh/react-native-openharmony`→RN），再全仓扫描适用规则的关键词。

**关键定位技巧**：
- Ability → 页面文件：Grep `src/main/ets/` 下搜索 Ability 名对应页面
- UI 组件 → 代码：从 UI 树提取组件类型 → Grep 搜索组件声明（如 `List(`、`Image(`、`Web(`）
- bundleName → 项目：读取 `AppScope/app.json5` 确认
- Item 复杂度：含 WebView/Video/Canvas 或图片 > 1 或嵌套 > 8 层 → complex，否则 → simple
- C-API 项目：检测到 `.cpp/.h` 含 `arkui/native_node.h` → 查 `references/detection_rules.md` 末尾 C-API 映射表

✅ **完成标准**: 已输出内存瓶颈分析、候选优化方案（来自内置方案库）、预计影响文件和风险等级。

### 步骤三：用户确认

执行修改前向用户说明：
- 将修改哪些文件。
- 使用哪个优化方案。
- 如何验证收益和功能不回退。
- 是否需要备份、分支或 patch-only 模式。

用户确认后再进入修改阶段。

✅ **完成标准**: 用户已明确同意修改方案和影响文件列表。

### 步骤四：代码修改与审查

按已确认方案修改代码（ArkTS 走 `.ets/.ts` 方案，C-API 走 `.cpp/.h` 方案）。修改后执行代码审查。

📖 读取 `references/arkts_rules.md`（ArkTS 类型系统与语法限制详细规则）
📖 读取 `references/review_checklist.md`（逐项审查清单）

**审查流程**：

```
1. 获取修改文件列表（从对话上下文的「修改清单」）
2. ArkTS 编译验证（check_ets_files MCP 可用时优先使用，不可用则降级）：
   ├── 有 check_ets_files MCP → 对 .ets 文件做静态语法检查（文件路径用绝对路径）
   │   ├── 编译返回 Error → 审查结果 FAIL，必须修复
   │   └── 编译返回 Warning → 记录，结果可为 PASS_WITH_WARNINGS
   └── 无 check_ets_files MCP → 降级：提示用户在 DevEco Studio 手动编译验证，或执行 `node hvigorw.js assembleHap --mode module` 验证；报告中标注"未执行 MCP 编译验证，结果可能不准确"
3. 读取修改后代码，执行文本审查（规范/逻辑/安全/性能/可维护性/ArkUI 组件规范）
4. 生成审查报告，输出 PASS / PASS_WITH_WARNINGS / FAIL
```

**⚠️ 编译验证说明**：纯文本审查无法感知 API 返回值类型（如 `hidebug.getSystemMemInfo().totalMem` 是 `bigint`），只有编译器能检测。`check_ets_files` MCP 可用时优先使用（文件路径用绝对路径）；不可用时降级为 DevEco Studio 手动编译或 `node hvigorw.js assembleHap --mode module` 验证，并在报告中明确标注降级。

**审查维度速查**（详细规则见 `references/arkts_rules.md`）：

| 维度 | 关键检查项 |
|------|-----------|
| 代码规范 | 命名（UpperCamelCase/lowerCamelCase）、格式（2 空格缩进、行 ≤120）、注释 |
| ArkTS 类型系统 | 禁用 any/unknown、禁 var、禁 @ts-ignore、禁 structural typing、禁交叉/条件/映射类型 |
| ArkTS 语法限制 | 禁 delete、禁 Symbol()、禁索引访问字段、禁解构赋值、禁 for...in、禁生成器、禁对象字面量类型 |
| 逻辑正确性 | 未使用变量、类型不匹配、空指针风险、循环边界、async/await 错误 |
| 安全性 | SQL 注入、XSS、硬编码密钥、权限检查、输入验证 |
| 性能 | const vs let、循环常量提取、循环内 I/O、内存泄漏、重复计算 |
| 可维护性 | 函数 >50 行警告、嵌套 >3 层警告、重复代码、魔法数字 |
| ArkUI 组件规范 | @Component/@Entry/@State 装饰器、build() 方法、LazyForEach key、cacheCount、aboutToDisappear 释放资源 |

所有 `arkts-*` 规则对应编译时错误，必须修复。Critical 和 Error 必须修复；编译错误视为 Error。

✅ **完成标准**: 审查报告已生成，结果 PASS 或 PASS_WITH_WARNINGS，无 Critical/Error 未修复。

### 步骤五：构建与安装

构建 HarmonyOS 项目生成 HAP 并安装到设备。

> 调用 `scripts/{windows,linux,macos}/build_template`，传入项目路径
📖 读取 `references/build_troubleshooting.md`（构建排错）

**一键脚本**（按平台选择）：

```bash
# Windows
scripts\windows\build_template.bat [projectPath]
# macOS / Linux
scripts/macos/build_template.sh [projectPath]   # 或 scripts/linux/...
```

**项目根目录判定**：必须包含 `build-profile.json5` 和 `hvigor/`。

**环境发现顺序**（脚本自动执行）：
1. DevEco SDK：`DEVECO_SDK_HOME` → `OHOS_SDK_HOME`/`HM_SDK_HOME` → `local.properties` 的 `sdk.dir` → 已发现 `DEVECO_HOME` 下的 `sdk`
2. DevEco Studio 根目录：`DEVECO_HOME` → 由 SDK 反推 → 常见安装目录遍历（Windows: `%ProgramFiles%\Huawei\DevEco Studio`；macOS: `/Applications/DevEco-Studio.app/Contents`；Linux: `/opt/deveco-studio`）
3. Java/Node/Hvigor：`JAVA_HOME`/`NODE_HOME` → DevEco 根目录下 bundled tools

**核心原则**：不硬编码个人机器路径；缓存目录放项目内 `.build-cache/`；构建命令用 `--no-daemon`；清理缓存前确认是项目根目录。

**HAP 输出位置**：`entry/build/default/outputs/default/entry-default-signed.hap`

**安装与启动**：

```bash
hdc install -r <hapPath>
hdc shell "aa start -a <abilityName> -b <bundleName>"   # -a 必须用完整 Ability 名称
```

应用启动失败时，不要反复重试；先确认 ability 名称、安装结果和设备状态。

✅ **完成标准**: HAP 已安装到设备，应用已启动且可进入目标场景。

### 步骤六：优化后采集

让开发人员进入与优化前一致的目标场景，再采集：

```bash
# 按平台调用 collect_memory，输出到 after
scripts/macos/collect_memory.sh <bundleName> ../AppCode/TestData/after
```

对比 `before` 和 `after`：Total PSS、主要内存类型、目标问题是否改善、功能和交互是否正常。

✅ **完成标准**: after 数据已采集，before/after 对比结论明确（改善/无变化/退化）。

### 步骤七：Patch 与报告

生成 patch：

```bash
git diff > ../AppCode/Patches/<date>_<optimization>.patch
```

若项目不是 git 仓库，使用修改文件清单生成统一 diff，并在报告中标注来源。

报告输出到 `../AppCode/Analysis/optimization_report.md`。不要自动删除新增文件或恢复修改文件。需要回退时，先征得用户确认，并优先使用用户指定方式。

✅ **完成标准**: patch 文件已生成，优化报告已保存到 `Analysis/optimization_report.md`，含 before/after 对比数据。

---

## 可用优化方案

**重要**: 只使用内置方案库中已完善的方案，不杜撰方案。检测到问题后，打开对应详细文档获取代码模板。

| 规则 | 方案 | 详细文档 |
|------|------|----------|
| 1 | 滚动组件 cacheCount 分档 | [scheme_cache_count.md](references/scheme_cache_count.md) |
| 3 | 图片资源内存优化 | [scheme_image_optimization.md](references/scheme_image_optimization.md) |
| 4 | 资源泄漏修复 | [scheme_resource_leak.md](references/scheme_resource_leak.md) |
| 5 | Web 预加载分档 | [scheme_web_preload.md](references/scheme_web_preload.md) |
| 13 | Web 预渲染活跃状态 | [scheme_web_on_active.md](references/scheme_web_on_active.md) |
| 14 | Web 离线组件复用释放 | [scheme_web_offline_reuse.md](references/scheme_web_offline_reuse.md) |
| 6 | 多媒体内容分档降级 | [scheme_media_content_tiering.md](references/scheme_media_content_tiering.md) |
| 7 | Tabs 组件缓存分档 | [scheme_tabs_cache.md](references/scheme_tabs_cache.md) |
| 8 | 不可见组件主动下树 | [scheme_component_detach.md](references/scheme_component_detach.md) |
| 9 | QuickJS 引擎内存优化 | [scheme_quickjs_optimization.md](references/scheme_quickjs_optimization.md) |
| 10/11 | Flutter Vulkan 内存分配（Flutter 专项） | [scheme_flutter_vma.md](references/scheme_flutter_vma.md) |
| 12 | RN 内存优化（RN 专项） | [scheme_rn_memory.md](references/scheme_rn_memory.md) |
| 2 | 双层 Navigation 嵌套（仅报告，无代码模板） | — |
| — | 设备分档通用机制 | [device_level_tiering.md](references/device_level_tiering.md) |

**低优先级建议**（仅报告，无代码模板）：规则 2（双层 Navigation 嵌套，Info 级）及其他低优先级项详见 [references/detection_rules.md](references/detection_rules.md)。

**C-API（NDK）注意**：所有方案同时支持 ArkTS 和 C-API。`.ets/.ts` → ArkTS 方案，`.cpp/.h/.c` → C-API 方案。C-API 无 `aboutToAppear/aboutToDisappear`，需在 `disposeNode` 前手动清理资源；`disposeNode` 不可逆，销毁后 handle 不可再用；组件映射表见 `references/detection_rules.md` 末尾。

---

## 输出格式要求

分析完成后，按以下结构输出优化报告：

```
================================================================================
                    HarmonyOS 内存分档优化报告
================================================================================

【应用基本信息】
应用名称     : <bundleName>
目标场景     : <abilityName 及场景描述>
设备信息     : <机型 / 系统版本 / 是否低端机>
分档目标     : <如：低端机 PSS ≤ XXX MB>

【优化前内存基线】
Total PSS    : <before Total PSS，如 512.34 MB>
ArkTS Heap   : <ArkTS 堆内存>
Native Heap  : <Native 堆内存>
GL/Graph     : <图形内存>
主要瓶颈     : <如：长列表 cachedCount 过大、图片未分档、Web 预加载未释放>

【根因分析】
诊断结果     : <一句话概括，如："长列表一次性加载 50 项，低端机 PSS 超标 80MB">
故障类别     : <列表缓存 / 图片资源 / Web 组件 / 资源泄漏 / 媒体分档 / ...>
可信度       : HIGH / MEDIUM / LOW

【候选方案与选择】
┌──────────┬──────────────────────────┬──────────────────┬──────────┐
│  方案    │         说明             │     预计收益      │  风险等级  │
├──────────┼──────────────────────────┼──────────────────┼──────────┤
│ 方案A    │ <如：cachedCount 50→20>  │ <如：-45MB>      │ LOW       │
│ 方案B    │ <如：图片按设备档位降级>  │ <如：-30MB>      │ MEDIUM    │
└──────────┴──────────────────────────┴──────────────────┴──────────┘
已选方案     : <用户确认的方案>
依据         : <引用 references/scheme_*.md 对应方案库>

【代码修改】
修改文件     : <file:line 列表>
核心变更     : <每处改动的简要说明>
审查结果     : <PASS / PASS_WITH_WARNINGS + 审查依据 references/arkts_rules.md>

【优化后对比】
指标         |  Before        |  After         |  变化
-------------|----------------|----------------|--------
Total PSS    |  <XXX MB>      |  <YYY MB>      |  <Δ MB, ↓XX%>
ArkTS Heap   |  ...           |  ...           |  ...
Native Heap  |  ...           |  ...           |  ...
结论         : <改善 / 无变化 / 退化>

【验证结果】
构建状态     : <PASS/FAIL>
安装启动     : <成功/失败>
功能回归     : <目标场景功能正常/异常>

【残余风险与后续建议】
1. <如：高配机未验证，建议后续覆盖>
2. <如：某方案未采用，可在下个版本继续>

================================================================================
```

**代码审查报告格式**详见 [references/review_checklist.md](references/review_checklist.md)。

---

## 错误处理

遇到错误时：

1. 先判断错误归属：采集、分析、代码修改、审查、构建或设备连接。
2. 按对应步骤的排查要点处理（采集→确认 hdc 连接；构建→见 `references/build_troubleshooting.md`；审查→`check_ets_files` MCP 不可用时降级为 DevEco Studio 手动编译或 `node hvigorw.js assembleHap --mode module` 验证）。
3. 如果错误跨多个阶段，先保证当前阶段可复现，再进入下一阶段验证。
4. 解决后在最终报告中记录错误现象、根因、修复方式和验证结果。

**编译验证失败兜底**：当 `check_ets_files` MCP 不可用且 hvigorw 验证也失败时，审查结果不得标为 PASS；应标为 PASS_WITH_WARNINGS 或 FAIL，并在报告中显式列出未验证项，建议用户在 DevEco Studio 中手动编译确认。

---

## 参考文档速查

| 需要什么 | 打开 |
|----------|------|
| meminfo 解读与 PSS 口径 | [references/memory_analysis_guide.md](references/memory_analysis_guide.md) |
| 14 条检测规则触发条件 + Grep 关键词 | [references/detection_rules.md](references/detection_rules.md) |
| 分档优化方案库（12 个）+ 设备分档机制 | 见上方「可用优化方案」表 |
| 代码定位方法 | [references/code_location_guide.md](references/code_location_guide.md) |
| 分析报告格式 | [references/report_templates.md](references/report_templates.md) |
| ArkTS 类型/语法详细规则 | [references/arkts_rules.md](references/arkts_rules.md) |
| 代码审查逐项清单 | [references/review_checklist.md](references/review_checklist.md) |
| 构建排错 | [references/build_troubleshooting.md](references/build_troubleshooting.md) |
