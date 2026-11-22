---
name: hmos-memory-anti-regression
description: HarmonyOS 应用内存防劣化分析。对同一应用的两个版本分别执行数据采集和归因分析，通过 topdown 对比识别劣化源，对 Top10 劣化 SO 按 type_name 分发 ArkTS Heap / Native Heap / SO_SIZE 三类深度分析，综合输出防劣化报告并匹配案例库。当用户提到 htrace 采集、内存对比、防劣化、topdown、smaps、hidumper、hiprofiler、heapsnapshot、native heap、arkts heap、版本对比等场景时使用此技能。
license: MIT
metadata:
  author: harmonyos-dev-skills
  version: "1.0.0"
  created: "2026-03-17"
  updated: "2026-11-02"
  keywords: ["memory", "anti-regression", "harmonyos", "topdown", "htrace"]
compatibility: Requires Python 3.10+, hdc, trace_streamer, DevEco Studio. Depends on hypium for scenario replay.
---

# hmos-memory-anti-regression Skill

HarmonyOS 应用内存防劣化分析：双版本采集 → 对比分析 → 深度归因 → 综合报告

## 防劣化分析总流程

```
0. 环境检查
1. 对旧版、新版分别执行数据采集（采完旧版 → 装新版 → 再采新版，顺序见步骤 1）
2. 对两个版本分别执行归因分析，各自生成 topdown + 汇总表
   → 根据两个版本的 topdown 对比结果，生成对比报告
   → 根据 Top10 劣化 SO 的 type_name 判断触发哪些深度分析（判定规则见下方「步骤 3/4/5 触发逻辑」）
3. ArkTS Heap 深度分析（Top10 劣化 SO 中存在 type_name 含 ARKTS_HEAP 的 SO 时触发，归因聚焦这些 SO）
4. Native Heap 深度分析（Top10 劣化 SO 中存在 type_name 不全是 SO_SIZE/HAP/DMA 的 SO 时触发，仅差分这些 SO）
5. SO_SIZE/HAP smaps 对比分析（Top10 劣化 SO 中存在 type_name 含 SO_SIZE/HAP 的 SO 时触发，仅对比这些 SO）
6. 综合 2 的对比报告 + 3/4/5 的深度分析结果，输出总体防劣化分析报告；
   劣化源根因按 references/optimization-workflow.md 匹配案例库并产出《案例匹配报告_<旧>_vs_<新>.md》（只给匹配结果，不出优化方案），
   匹配成功案例的故障模式描述回填对比报告「Top10 劣化 SO」章节
7. 报告生成后主动优化：优化方案第一章存在匹配成功项时，基于 references/optimization-skill-invocation.md
   调用 harmonyos-memory-optimization-solution SKILL（定位场景 → 优化方案 → 逐一确认 → 执行优化 → 构建验证）；
   内存复测不进优化 SKILL，回到步骤 1 采集流程（优化后新包 vs 基线）做差值收敛对账
```

- **排序规则**：分配器碎片、未覆盖、空服务、其他、(未命名)属于无法进一步分析的内存，通篇排序中一律放在对应类别最后
- **步骤 2 自身产出**：对比报告（topdown 总览 + 汇总表一层领域对比 + 汇总表层级结构 + Top10 劣化 SO + DMA 对比分析）
- **步骤 3/4/5 触发逻辑**（唯一定义，references 中各处相关描述均以此为准）：
  - **判据来源**：步骤 2 对比报告中的 Top10 劣化 SO（按新旧版本差值降序，排除分配器碎片/空服务/未覆盖/其他/(未命名) 等虚拟分类）
  - **分发方式**：对 Top10 中**每个 SO 单独**检查其在汇总表中挂载的 type_name 明细（一个 SO 可挂多个 type_name），按下表将该 SO 分发到对应深度分析步骤（同一 SO 可命中多个步骤）：

    | 该 SO 的 type_name 明细 | 分发步骤 |
    |------------------------|---------|
    | 包含 ARKTS_HEAP | 步骤 3 + 步骤 4 |
    | 不含 ARKTS_HEAP，且不全是 SO_SIZE / HAP / DMA | 步骤 4 |
    | 全是 SO_SIZE / HAP / DMA | 不分发到步骤 3/4 的 native heap 归因（DMA 为 gralloc/dmabuf 分配、SO_SIZE/HAP 为文件映射，均不经 malloc，htrace .db 的 native_hook 表中无对应调用栈——libhdi.z.so / libbuffer_handle.z.so 即属此类，按 SO 名聚类必然报"无匹配调用栈"、无法生成 native heap 火焰图，属数据本质限制而非脚本故障）。**但明细含 DMA 的 SO 须生成 DMA 调用栈火焰图**：用 `cluster_calltree.py --frame <关键字>`（如 `SurfaceBuffer`）按帧名聚类、**全事件口径**（ION_Alloc/Mmap/Alloc/FD 全类型含已释放；ION_Alloc_Event 的 value 即 DMA 分配字节，实际调用栈按真实字节宽度渲染），再走 diff + `--compare` 火焰图；产物**不进 6.2 Native Heap 小节、不并入 native heap 统计**，挂第六章独立小节，差分 delta 与 dmabuf 快照差值对账，详见 `native-heap-workflow.md` 步骤 6 |
    | 包含 SO_SIZE / HAP | 步骤 5（独立于上述三行，可叠加） |
    | 仅含 DMA（无 SO_SIZE/HAP） | 不分发到步骤 3/4/5 的常规归因，归因走第五章 DMA 对比分析（dma_detail.xlsx 按 buf_type/buf_name 拆解）；**同时生成 DMA 调用栈火焰图**（`--frame` 帧名聚类全事件口径，同上：不进 native heap 显示，挂第六章独立小节，见 `native-heap-workflow.md` 步骤 6） |

  - **步骤执行范围**：每个深度分析步骤只针对被分发到它的 SO 执行——步骤 4 只差分这些 SO 的调用栈，步骤 5 只对比这些 SO 的 smaps 项，步骤 3 为全堆分析但归因重点是含 ARKTS_HEAP 的被分发 SO；某步骤没有任何 SO 被分发时跳过该步骤。报告中须注明每个步骤针对的 SO 列表。

- **步骤 3/4/5 并行执行**（关键优化）：三步互相独立，只共同依赖步骤 2 的 Top10 分发结果。分发完成后，使用 Task 工具同时启动最多 3 个 `general` agent 并行执行：

  | Agent | 步骤 | 输入文件 | 脚本 | 返回内容 |
  |-------|------|---------|------|---------|
  | Agent 1 | 步骤 3 ArkTS Heap | 两版本 .heapsnapshot | `shortest-path.mjs` → `compare_diff.py` → `resolve_chain_props.js`（链级 Δ 模块聚合） | GROWN/NEW 链 + 责任侧分类 + delta_kb + count（对象数）+ Top3劣化模块（模块劣化 = 该模块全部相关链 Δ 之和，含相关链明细 + 锚点定位） |
  | Agent 2 | 步骤 4 Native Heap | 两版本 .db + 分发 SO 列表 | `cluster_calltree.py`（每 SO 一对 tree）→ `diff_cluster_tree.py` → `build_flame_summary.py`（前后对比火焰图）；另对明细含 DMA 的 Top10 劣化 SO 按 `native-heap-workflow.md` 步骤 6 生成 DMA 调用栈火焰图（`--frame` 帧名聚类全事件口径，产物不进 native heap 小节/统计） | 每 SO 差分树 root delta + Top N 劣化叶子调用链 + `<so>_compare_flame.html`；DMA 型 SO 另出实际调用栈火焰图（全事件口径，ION_Alloc 链 value 即 DMA 分配字节） |
  | Agent 3 | 步骤 5 SO_SIZE/HAP smaps | 两版本 smaps | `diff_smaps.py` | smaps_diff.json + Top N 劣化 SO/HAP + root_cause/suggestion |

  **并行执行规则**：
  1. 步骤 2 生成对比报告后，从中提取 Top10 劣化 SO 及其 type_name 明细，完成分发判定
  2. 在**单条消息**中同时发起所有触发的步骤 agent（未触发的步骤不启动 agent）
  3. 每个 agent 的 prompt 必须包含：分发到该步骤的 SO 列表、输入文件路径、脚本路径、输出格式要求
  4. 步骤 4 内部可进一步并行：多个 SO 的 `cluster_calltree.py` 可在同一 agent 内批量执行或启动子 agent
  5. **步骤 3 的 sourceMap 硬门控**由主 agent 处理：子 agent 先运行 shortest-path + compare_diff，拿到 `--json` 差异后返回结果给主 agent；主 agent 收到后向用户索要 sourceMap；sourceMap 未到手时返回 .ts 行号结果并标注"需 sourceMap 精确到 .ets"
  6. **步骤 4 的 debug SO 硬门控**由主 agent 处理：子 agent 先运行 cluster_calltree + diff_cluster_tree 拿到差分树，**到行号解析前（native-heap-workflow.md §3.1）停下来**，由主 agent 显式向用户索要 B 版归因 SO 的带 debug 符号版本路径或目录（用户可拒绝）；未索要前**阻塞**不得静默解析，用户提供路径后须用 `readelf` 校验未 strip，用户拒绝时按 `native-heap-workflow.md`「调用链回溯完整性限制」保留未解析帧出报告并标注"待补充 debug 符号"
  7. 所有 agent 返回后，主 agent 汇总结果写入对比报告第一章（深度分析），再执行步骤 6 综合报告

- **步骤 6 的综合**：将步骤 2 的对比报告与步骤 3/4/5 的深度分析结果合并，输出总体报告

## 流程总览

| 阶段 | 职责 |
|------|------|
| 0 环境检查 | hdc/trace_streamer/设备连接/依赖检查 |
| 1 数据采集 | 冷启动/运行态 htrace + 瞬时快照（对两个版本分别执行） |
| 2 归因分析 + 对比报告 | 两个版本各自 topdown + 汇总表 + 对比报告 |
| 3 ArkTS Heap 深度分析 | heapsnapshot 对比 + GC Root 最短路径 + sourceMap 行号解析 |
| 4 Native Heap 深度分析 | A/B 差分 + addr2line 行号解析 + 泄露/延时释放诊断 |
| 5 SO_SIZE/HAP smaps 对比 | A/B smaps 对比 + Pss 差值 + 劣化 SO/HAP 定位 + 根因推测 |
| 6 综合报告 | 合并 2 + 3 + 4 + 5 的结果输出总体防劣化分析报告 |
| 7 主动优化 | 报告生成后基于 `optimization-skill-invocation.md` 调用优化 SKILL 执行代码优化 + 构建验证 + 复测对账 |

## 步骤 0：环境检查

检查 hdc/设备连接/应用包名/trace_streamer 可用性。如果应用未安装但用户提供了安装包路径，则执行 hdc install。

**应用安装后，通过 `--login-scenario` + `--login-scenario-dir` 自动执行 Hypium 登录预制脚本（如 `python main.py MyappPrerequisiteSetup`），脚本执行成功（退出码 0 + xdevice 报告校验通过）后自动继续采集流程，无需人工登录确认。未提供时回退为人工确认：等待用户完成登录等前置操作并确认应用处于正常使用状态后，才能继续采集流程。**

**工具路径查找**：所有工具路径通过 `scripts/_lib/tool_finder.py` 自动查找，按优先级：环境变量（`HDC_PATH`/`TRACE_STREAMER_PATH`/`ADDR2LINE_PATH`/`DEVECO_HOME`）→ DevEco Studio 安装目录 → 系统 PATH。

**trace_streamer**：通过 `tool_finder.py` 自动查找（`TRACE_STREAMER_PATH` → DevEco Studio → PATH）。若本机未找到，可下载：`https://gitcode.com/openharmony/developtools_smartperf_host/releases/download/HiSmartPerf_20260730/trace_streamer_binary.zip`（兜底：`https://gitcode.com/openharmony/developtools_smartperf_host/releases`）。zip 包含全平台二进制，解压后按平台选择对应可执行文件，设置 `TRACE_STREAMER_PATH` 或加入 PATH。→ 详见 references/environment.md

**环境要求**：推荐 Python 3.10（hypium 依赖推荐 3.10 版本；>= 3.10 可满足 `DataFrame.map()` 需求）；修改代码后需清除 `__pycache__`：`find scripts -name '__pycache__' -type d -exec rm -rf {} +`

**hypium 依赖检查**：采集流程依赖 hypium（场景复现 + 登录预制脚本通过 Hypium 工程执行）。`check_env.py` 自动检查 hypium 是否安装，未安装时自动执行 `pip install hypium -U --trusted-host mirrors.huaweicloud.com -i https://mirrors.huaweicloud.com/repository/pypi/simple`（**推荐 Python 3.10 环境下安装**）。

## 步骤 1：数据采集

**htrace 采集前必须通知用户并等待确认，不可自动执行。** 确认内容包括：
1. 告知即将执行的采集步骤（杀应用 → 重启应用 → htrace → 瞬时数据）
2. 告知采集时长
3. 提醒用户确保应用已登录并处于正常使用状态
4. 等待用户明确确认后才开始 htrace 采集

**通知确认由 AI 在调用 collect.py 之前自行完成，不得依赖 collect.py 内部的确认。** collect.py 以非交互子进程方式被调用，其 `prompt_confirm` 在非 TTY 且无 `--yes` 时直接报错退出；AI 的 Bash 工具在命令结束前拿不到交互输入。因此 AI 必须：① 先向用户发出采集通知（步骤/时长/复现时机/登录状态）并用 question 工具或文本取得明确确认；② 确认后再运行 `python scripts/1_collection/collect.py --yes ...`（`--yes` 跳过确认门禁，前提是 AI 已与用户确认）。未传 `--yes` 的非交互调用 collect.py 会直接报错退出，杜绝静默采集。

**未经用户确认，不得执行杀应用、启动 profiler 等 htrace 采集操作。** 瞬时数据采集（showmap/smaps/heapsnapshot 等）在 htrace 结束后自动执行，无需额外确认。

**场景复现自动化**（`--scenario` + `--scenario-dir` 参数）：当外部 Hypium 场景复现工程可用时，使用 `--scenario <xdevice测试用例名> --scenario-dir <工程路径>` 可在 htrace 采集期间自动执行 UI 操作，替代手动复现：
- `collect.py` 在 htrace 启动后自动后台运行 `<工程路径>/<测试用例路径>`（由 Hypium 脚本负责拉起应用）
- 场景模式下 `collect.py` 不执行 `aa start`，由 Hypium 脚本的 step1 负责拉起应用
- **场景执行结果校验**：场景脚本退出后，`collect.py` 解析 xdevice 报告（`reports/<timestamp>/report_data.json`），通过时间窗口+场景名匹配定位当前场景报告，判断 pass/fail；失败时提示用户选择是否重新采集
- **htrace 采集时长自动调整**：当 `--scenario` 指定时，`collect.py` 优先从历史 xdevice 报告读取实际耗时，无历史报告时使用保守默认值（180s）；若用户指定时长不足，自动上调
- Hypium 工程为外部依赖，不包含在本 skill 内，需调用方提供路径

**手动复现（无 --scenario 时）**：hiprofiler_cmd 一旦启动即进入 trace 采集状态，必须在紧邻 hiprofiler_cmd 执行前后显式提醒用户开始复现操作：
- **冷启动场景**：profiler 启动 → sleep 3 → 应用拉起，**应用拉起后即可开始复现问题**
- **运行态场景**：profiler 启动后**立即**开始复现问题，提示与 hiprofiler_cmd 执行间隔越短越好

对旧版、新版分别执行 htrace + 瞬时快照采集。单版本采集流程：杀应用 → 启动 profiler → **清空 hilog 缓冲区** → sleep 3 → 启动应用 → [场景复现 or 手动操作] → wait → 瞬时数据（showmap/smaps/heapsnapshot）→ 拉取 htrace 及其余产物。

**产物目录命名规则（关键）**：`collect.py` 的产物目录名格式为 `<app>_<version>[_<scenario>]`——`version` 为应用真实版本号（如 `14.8.10`），`scenario` 为可选的场景标签（如 `MyappScenarioReplay`）。版本号来源优先级：`--version_tag` 显式传入 > HAP 文件 versionName > 设备已装 versionName。**禁止使用 `old`/`new` 等无版本信息的泛化标签**，必须使用真实版本号，确保产物目录可追溯。示例：`hmapp_14.8.10/`、`hmapp_14.8.30_MyappScenarioReplay/`。
> **hilog 采集说明**：collect.py Phase 2 在应用拉起前执行 `hilog -r`（清空缓冲区），确保后续 dump 只含本次场景日志；dump_mem.py 在瞬时数据采集阶段通过 `hilog -T <pid>`（Popen + 10s timeout 捕获流式输出）落盘 hilog 日志至 `meminfo/hilog/`，同时通过 `hidumper -s WindowManagerService -a "-dumpWindow"`（best-effort）落盘窗口/组件树至 `meminfo/window_dump/`。hilog 日志供 ArkWeb 案例匹配规则 2（CreateNWeb/NWebImpl::OnDestroy 事件计数）使用，窗口 dump 供规则 2 的 `b` 值（当前显示 Web 组件数）使用。

**双版本采集顺序（关键，不可逆）**：

> 产物输出目录 = 运行 `collect.py` 时工作目录下的 `output/`（`collect.py` 默认 `--output-base ./output`，相对当前运行目录，**非 skill 安装目录**）。AI 调用时工作目录通常为 workspace 根目录，产物落到 `<workspace>/output/<app>_<version>[_<scenario>]/`。

1. 安装旧版 → **登录前置**（`--login-scenario` + `--login-scenario-dir` 自动执行 Hypium 登录脚本，或人工登录确认）→ **阶段一确认（采集方案）→ 阶段二确认（复现时机）** → 执行采集 → collect.py 采集后**自动校验产物完整性**，校验通过保存 `collection_meta.json`（记录 duration/scenario/ability 等全部参数）→ 产物归置到 `<工作目录>/output/<app>_<旧版本号>[_<scenario>]/`
2. **确认旧版采集成功**（collect.py 返回 0 = 校验通过）
3. ★ **旧版归因分析与新版采集并行**：用 Task agent（`general` 类型）在后台启动旧版归因分析（步骤 2 的 ① meminfo 生成 + ② htrace→db + 归因分析），**不等旧版分析完成**，立即继续下一步。分析在本地 CPU 跑，不占设备
4. ★ **参数一致性校验（仅限同一次防劣化分析的旧版 vs 新版）**：读取旧版 `output/<旧版目录>/collection_meta.json`，提取 duration / scenario / scenario_dir / login_scenario / ability 等参数。新版采集**必须使用完全相同的参数**（同一 duration、同一 scenario 或同为手动操作、同一 scenario-dir、同一 login-scenario）。**禁止混用自动场景复现与手动操作模式**，否则数据不可比。**注意：此校验仅针对同一次防劣化分析的前后两版本，不同场景或不同分析之间不要求参数一致**
5. 覆盖安装新版 → **登录前置**（使用与旧版相同的 `--login-scenario` 或人工登录）→ **阶段一确认 → 阶段二确认** → 使用与旧版相同的参数执行采集 → 产物归置到 `<工作目录>/output/<app>_<新版本号>[_<scenario>]/`
6. 新版采集验证通过后，执行新版归因分析（若旧版分析仍在跑，两者并行；否则直接执行）
7. **两版本分析都完成后**，执行 `generate_comparison_report.py` 生成对比报告

> **Task agent 旧版分析 prompt 要点**：包含旧版产物目录路径、分析命令（meminfo 生成 + main_analysis_all_mem.py）、输出目录。agent 完成后返回旧版分析产物路径。主 agent 不等待该 agent 完成即可继续新版采集流程，但在生成对比报告前需确认 agent 已返回。

→ 详见 references/collection-workflow.md

## 步骤 2：归因分析 + 总报告(数据部分)

对两个版本分别执行（**旧版可在新版采集期间通过 Task agent 并行执行，见步骤 1 第 3 步**）：
① meminfo 生成（harmonyos_pipeline.py，从 dynamic_showmap/meminfo/dmabuf_info 聚合 → meminfo.xlsx）
② htrace→db 转换 → 归因分析（main_analysis_all_mem.py，归因需 meminfo）

每个版本输出：meminfo.xlsx + 汇总.xlsx + topdown报告 + 详细数据 + dma_detail。

```bash
# ① meminfo 生成（归因前置）
python -c "
import sys; sys.path.insert(0, 'scripts/2_analysis'); sys.path.insert(0, 'scripts/_lib')
from harmonyos_pipeline import HarmonyLayer1MaPipeline
HarmonyLayer1MaPipeline(test_case_dir='output/<app>_<版本号>[_<scenario>]/').analyze()
"
# ② 归因分析
python scripts/2_analysis/main_analysis_all_mem.py \
  -p output/<app>_<版本号>[_<scenario>]/ -o output/<app>_<版本号>[_<scenario>]/analysis \
  --mm-dmabuf output/<app>_<版本号>[_<scenario>]/mm_dmabuf_info_<pid>.txt \
  --detail -l 10,0,5
```

然后对比两个版本的 topdown 和汇总表，由 `generate_comparison_report.py` 生成**总报告的数据部分**(一章深度分析占位 + 二~六章: topdown 总览/汇总表/Top10/DMA):

```bash
python scripts/2_analysis/generate_comparison_report.py \
  --old-dir output/<app>_<旧版本号> --new-dir output/<app>_<新版本号> \
  --old-label <旧版本号> --new-label <新版本号> \
  -o output/对比报告_<旧版本号>_vs_<新版本号>.md
```

> **路径固定（不可改动）**：对比报告 `.md` 固定输出到 `output/对比报告_<旧版本号>_vs_<新版本号>.md`，`report_md_to_html.py` 生成的 `.html` 同级（`output/对比报告_<旧版本号>_vs_<新版本号>.html`）；步骤 4 火焰图固定输出到 `output/flame_compare/`。报告 `.html` 与 `flame_compare/` 均在 `output/` 下同级，链接使用相对路径 `flame_compare/<so>_compare_flame.html` 可正确解析。**不得用 `-o` 改到其他目录，否则链接相对路径失效。**

步骤 3/4/5 填入一章深度分析，DMA 填入六章，步骤 6 填入第八章(劣化汇总/优化建议/不确定性)，最终产出**一份总报告**。

→ 详见 references/analysis-workflow.md
→ 总报告格式参考 references/comparison-report-guide.md

## 步骤 3：ArkTS Heap 深度分析

**条件触发**：Top10 劣化 SO 中存在 type_name 明细包含 ARKTS_HEAP 的 SO 时触发；归因重点为这些 SO（分发规则详见上方「步骤 3/4/5 触发逻辑」）
**输入**：A/B 两个版本的 .heapsnapshot 文件 + sourceMap
**输出**：retained-size 增量报告（GROWN/NEW 链 + delta_kb + count 对象数 + 责任侧分类）、源码行号归因、**Top3劣化模块（链级 Δ 模块聚合：模块劣化 = 该模块全部相关链 Δ 之和，取 Top3 并列出全部相关链明细，由 `resolve_chain_props.js` 自动产出）**、**优化方向（章节级总体建议，置于 ArkTS Heap 小节开头，仅一条，不按引用链逐条补充）**
**关键约束**：sourceMap 必须开发者实际提供，不能自动推测

**⚠️ 优化方向是章节级总体建议，不按引用链逐条补充**：对比报告第一章 ArkTS Heap 小节**开头放一条总体优化方向**即可，不在每条 GROWN/NEW 链归因项下重复。该总体建议基于以下规则：

> **减少 retainedSize 的优化方向（引用链拆解规则）**：
> - **链上任意中间对象**：减少它对下一对象的持有关系（断开该 edge），其后继子树不再被该路径锚定，retainedSize 随之回落。
> - **最后一个对象**：可减少它对任一下一对象（任一出边）的持有关系，直接释放其引用的子对象。
> - **仅需断开链上任一边即可生效，不必整链清除**；优先断开开发者可控对象（带 `[entry]` / 应用源码行号）的出边，框架/VM 内部对象不可控则不单独处理。

→ 详见 references/arkts-heap-workflow.md

## 步骤 4：Native Heap 深度分析

**条件触发**：Top10 劣化 SO 中存在 type_name 不全是 SO_SIZE / HAP / DMA 的 SO 时触发；仅差分这些 SO 的调用栈（分发规则详见上方「步骤 3/4/5 触发逻辑」）  
**不触发**：某 SO 的 type_name 全是 SO_SIZE / HAP / DMA 时，该 SO 不分发到步骤 4 的 native heap 归因（DMA 为 gralloc/dmabuf 分配、SO_SIZE/HAP 为文件映射，均不是 malloc 运行时堆分配，htrace .db 的 native_hook 表中无对应调用栈；libhdi.z.so / libbuffer_handle.z.so 等图形 DMA 型 SO 按名称聚类会得到"无匹配调用栈"，无法生成 native heap 火焰图属预期，勿反复重试——含 SO_SIZE/HAP 明细的走步骤 5，纯 DMA 的走第五章 DMA 对比分析）。**例外（DMA 调用栈火焰图）**：明细含 DMA 的 Top10 劣化 SO 仍须生成调用路径火焰图——`cluster_calltree.py --frame SurfaceBuffer --label <so>` 按帧名聚类、全事件口径（ION_Alloc_Event/MmapEvent/AllocEvent/FD_Open_Event 含已释放；**禁止**用 malloc 存活口径，会丢 ION/Mmap 链致 value≈0 火焰图空白），A/B diff + `--compare` 火焰图（ION_Alloc 链 value 即 DMA 分配字节，按真实宽度渲染实际调用栈）；产物**不进 6.2 Native Heap 小节、不并入 native heap 统计**，挂第六章独立小节（如 6.4），差分 delta 与 dmabuf 差值对账，详见 `native-heap-workflow.md` 步骤 6  
**输入**：A/B 两个版本的 .db 文件 + 劣化SO名称 + debug SO 目录(可选) + 源码工程目录(可选) + addr2line路径  
**输出**：native heap 劣化诊断报告 + 前后对比火焰图（固定输出到 `output/flame_compare/<so>_compare_flame.html`，见 `native-heap-workflow.md` 步骤 5；报告链接用相对路径 `flame_compare/<so>_compare_flame.html` 引用，与报告 `.html` 同级可解析）

## 步骤 5：SO_SIZE/HAP smaps 对比分析

**条件触发**：Top10 劣化 SO 中存在 type_name 明细含 SO_SIZE 或 HAP 的 SO 时触发；仅对比这些 SO 的 smaps 项（分发规则详见上方「步骤 3/4/5 触发逻辑」）
**输入**：A/B 两个版本的 smaps 文件（`hidumper --mem-smaps <pid>` 或 `cat /proc/<pid>/smaps`）
**输出**：smaps_diff.json（按 Pss 差值降序）+ 劣化 SO/HAP 名称 + 根因推测 + 修复建议
**说明**：SO_SIZE/HAP 类型不是运行时堆分配，htrace .db 中无对应数据，步骤 3/4 无法分析。本步骤通过 smaps 对比直接分析 SO/HAP 的内存变化，填补步骤 3/4 的盲区。

→ 详见 references/so-size-hap-workflow.md

## 步骤 6：综合报告

综合步骤 2 的对比报告 + 步骤 3/4/5 的深度分析结果，输出总体报告：
- 两个版本的内存总览对比
- 各内存类别变化详情
- ArkTS Heap / Native Heap / SO_SIZE/HAP smaps 深度归因结果（如有），**其中 ArkTS Heap 小节开头放一条总体优化方向（引用链拆解），不按引用链逐条补充**（规则见步骤 3）
- 劣化点汇总 + 案例匹配结果（第八章，受下方根因限制约束）
- **案例匹配产出（按 `references/optimization-workflow.md` 执行）**：8.1 根因列不得凭经验手写——须按该流程两个子步骤执行：子步骤 1 逐劣化源匹配 `references/cases/` 案例库（数据规则只读已落盘产物、核查规则读应用源码工程，证据范围受其「数据范围硬约束」限制）→ 子步骤 2 落盘《案例匹配报告_<旧>_vs_<新>.md》至对比报告同目录（只含匹配结果与判定证据，**不含优化建议/修复方案**；未匹配/部分命中不写根因）。优化 SKILL 的调用不在该流程内，报告生成后按步骤 7 执行。下方第八章的案例库清单是该匹配范围的速览，与流程文档冲突时以 `optimization-workflow.md` 为准
- **案例库遍历完整性硬约束（防案例文件遗漏）**：进入案例匹配前，必须先 `ls references/cases/*.md` 实际清点目录，记录完整文件清单与规则总数。禁止凭本文件下方「案例库范围」清单、凭对比报告 §8.1 速览、凭劣化源 SO 名推断案例文件清单——本文件清单可能因新增案例文件后未同步而遗漏（历史教训：ArkUI.md/ArkWeb.md/三方框架.md 三个案例文件曾因清单未同步而被跳过，导致 libace_compatible.z.so +3.33MB 本应匹配 ArkUI.md 却误判为「无案例覆盖」）。报告速览「按案例规则看」表行数须与案例库规则总数对账，不等则回溯补齐。详见 `optimization-workflow.md`「1.0 案例库清点」。
- **证据实测硬约束（防证据编造，本次案例分析教训）**：第八章案例匹配的**每一条判定证据**（尤其数据规则）**以匹配规则中指定的查看内容为准**、必须实际读取落盘产物——对匹配规则明确要求查看的产物字段（如差分树含 `napi_deserialize` 帧、火焰图某帧占用增加、xlsx 某单元格）先执行实际检索命令（`grep -c <指定帧名> <so>_diff.json`、`grep -o 'napi_[a-z_]*' <so>_diff.json | sort | uniq -c` 等），拿到真实输出后才落笔；按规则指定的查看项检索不到关键帧/字段时，该规则按「❌ 不通过」判定，不得写"含 xxx 帧"或"xxx 占用增加"。**禁止凭上一轮分析记忆、凭其他场景（另一案例页/另一采集）的帧名推断本轮产物**——差分树/火焰图/smaps 每次独立生成，跨轮跨场景套用即证据无效。证据列须写明产物路径 + 实际检索命令 + 真实输出，保证可复核。规则未指定查看项的帧名仅作调用链展示，不参与案例判定证据。详见 `optimization-workflow.md`「1.1.2 证据实测硬约束」。
- **规则类型不可替代硬约束（防规则类型混淆，本次案例分析教训）**：案例匹配规则分「数据规则」（读落盘产物）和「核查规则」（读应用源码）两类，**严格不可互相替代**。真实教训：ArkWeb.md 案例一规则 2 是 hilog 核查规则，AI 未执行 hilog 命令，用源码核查（发现 `preCreate(6)` 调用）替代了 hilog 数据规则，误判为「通过」。数据规则只能用产物数据判定（产物中检索不到判 ❌ 或无法判定），核查规则只能用源码判定，**不得**用源码核查替代数据规则（即使源码中明确存在对应调用），也不得用产物数据替代核查规则。详见 `optimization-workflow.md`「1.1.3 规则类型不可替代硬约束」。
- **禁止引入规则之外判定标准（防主观臆测，本次案例分析教训）**：案例匹配判定**仅**由案例文档定义的匹配规则（通常 2-3 条）的通过/不通过决定。AI 不得额外引入规则之外的判定标准（如"主要矛盾"、"运行时是否触发"、"冷启动阶段"等主观判断）。真实教训：ArkWeb.md 案例三三条规则全部通过，但 AI 额外引入"冷启动阶段主要矛盾是预创建，累积型增长需运行时触发"的主观判断，将匹配成功误判为未匹配。全部规则通过 = 匹配成功，无例外；规则之外的合理业务判断可写入报告备注但不影响匹配判定。详见 `optimization-workflow.md`「1.2 禁止引入规则之外的判定标准」。
- **子 agent 结果复核硬约束（防子 agent 误判传播，本次案例分析教训）**：案例匹配委托 general agent 执行时，主 agent **必须逐条复核**子 agent 返回的每条规则判定——核对判定是否严格按案例文档规则执行、是否遵守「证据实测硬约束」和「规则类型不可替代硬约束」、是否引入了规则之外的判定标准、**是否遗漏规则正文中的口径区分子条款**。复核方式：对子 agent 标注「✅通过」的数据规则，抽查 1-2 条用对应检索命令复查产物，确认证据真实存在；对子 agent 标注「❌不通过」或「未匹配」的判定，检查是否因引入规则之外的主观判断导致误判。**未经复核不得直接采纳子 agent 的匹配结果落盘报告**。
- **规则内子条款完整性硬约束（防口径子条款遗漏，本次案例分析教训）**：案例匹配规则的标题条件（如 worker.md 规则 3「同一任务 worker 数量 ≥ 8」）满足**不等于**规则通过——规则正文可能含**统计口径子条款**（定义关键术语如何计数）、**例外/排除子条款**（定义条件适用边界）、**降级子条款**（定义特定条件下的降级处理）。真实教训：worker.md 规则 3 标题条件 `WORKER_COUNT=8 ≥ 8` 满足，但正文统计口径子条款区分「同一 script 循环创建 N 个（口径 a，计 N）」与「不同 script 各 1 个（口径 b，不累加）」，实际代码 `WORKER_SCRIPTS[i]` 是 8 个不同 script 路径属口径 b，同一任务实例数 = 1 < 8，规则 3 不通过——AI 只看标题条件就判通过，忽略口径子条款导致案例误判为「匹配成功」。**判定前必须通读每条规则的全部正文，识别并逐项检查所有口径区分/例外/降级子条款，任一子条款不满足即该规则不通过**。详见 `optimization-workflow.md`「1.1.4 规则内子条款完整性硬约束」。
- **故障模式回填 Top10 劣化 SO 章节（表格「故障归因」列）**：匹配报告落盘后，将其第一章各匹配成功小节的**故障模式描述**（案例文档「案例模式描述」的一句话概括，与案例原文表述一致，不扩展，如「taskpool 新增调用 http 任务」）回填至**步骤 2 对比报告第四章「Top10 劣化 SO」表格中的「故障归因」列**。回填规则（硬性要求）：
  - **形式**：在 Top10 表格中新增一列「故障归因」，**不得在表格下方单独写一段话**；列内容为匹配成功案例的故障模式一句话描述，**分点列出**（每行用 `- ` 前缀、`<br>` 分隔多条）。
  - **只针对对应 SO**：每行的故障归因**只填该 SO 自己命中的案例故障描述**；不得把其他 SO 命中的案例（如 libtaskpool 的 http 任务案例）跨行套用到同调用链的其他 SO（libhttp/libcurl/application/libace 等），也不得臆测补充。
  - **未命中不填**：该 SO 未匹配案例库（含部分命中）时，故障归因列**留空**，不写「未匹配案例库，需人工核查」等字样（未匹配/部分命中信息保留在案例匹配报告文档中即可）。
  - **部分命中不算命中**：仅当案例规则**全部**通过（匹配成功）时回填故障描述；部分命中（如案例一规则 2 napi_deserialize 帧缺失）不填。
  - 回填后须重新执行 `report_md_to_html.py` 同步 `.html`。
- 不确定性说明（如分配器碎片波动范围）

### 报告章节 6.1：ArkTS Heap 小节格式硬性要求（必须遵守，曾因遗漏导致 count 缺失）

6.1 小节必须按 `arkts-heap-workflow.md` 的「报告内容格式」编号模板逐条输出，**禁止用 markdown 表格/散文段落替代**详细归因条目（章节开头的汇总表格除外，见下）。每条归因项必须包含：

```
N. <a id="arkts-N"></a><归因so或模块>（ Δ=xxxKB xxx%，count=xxx，GROWN/NEW ） --- 归因so/模块，增量大小+对象数+链类型

    引用链：root -> ... -> leaf

    根因推断：<根因类型>，精确到 .ets:行号
```

**count 仅出现在归因行（条目首行）**：count 表示该归因 SO/分类下所有差分链聚合的对象实例总数（多条链 count 累加）。**引用链行及链上节点括号、根因推断叙述中一律不得再写节点级 count**（如 `SyntheticRoot（Δ=...，count=1，GROWN）` 这种链节点实例数禁止出现）——两级 count 口径不同并列显示会造成混淆（真实反馈：用户质问"为什么有两个count显示"，SyntheticRoot 这类单例根节点 count 恒为 1 无信息量）。引用链行节点括号只写 `（Δ=xxxKB，GROWN/NEW）`。

**count 和 GROWN/NEW 不得省略**。填入报告前，对照 `compare_diff.py` stdout 原始输出逐条核对 `count` 字段是否已写入——**count 在原始输出中必存在，遗漏是人工抄写错误**，非数据缺失。

**章节开头必须先放劣化归因汇总表格**（在总体优化方向之前）：列为 `业务来源 | 内存增长 | 严重性等级 | 根因摘要`，按 Δ 降序排列；业务来源列用锚点链接 `[libxxx.so](#arkts-N)` 跳转到对应编号条目（条目行首放 `<a id="arkts-N"></a>`，`report_md_to_html.py` 保留 raw HTML 锚点可跳转）。严重性等级按 Δ 绝对量：≥10MB 为 🔴 高，1~10MB 为 🟡 中，<1MB 为 🟢 低。格式自检清单：
- [ ] 是否使用编号模板（1. 2. 3. …）做详细归因，而非全节表格化？
- [ ] 章节开头是否有汇总表格（业务来源/内存增长/严重性等级/根因摘要），且业务来源带 `#arkts-N` 锚点链接、条目行首有对应 `<a id="arkts-N"></a>`？
- [ ] 每条归因行是否包含 `Δ=`、`count=`、`GROWN/NEW` 三个字段？
- [ ] 引用链行/链节点括号是否**没有** count（只有 Δ + GROWN/NEW）？
- [ ] 是否将 `compare_diff.py` 原始输出的 count 列逐条填入归因行？
- [ ] 开头是否有一条总体优化方向（引用链拆解），且未在每条链下重复？

### 报告章节 8：综合劣化点汇总与案例匹配（根因限制）

第八章单节：**8.1 劣化源汇总**（排名 / 劣化源 / 差值(MB) / 根因 / 分析步骤），根因列 = 案例匹配结果。案例匹配与《案例匹配报告_<旧>_vs_<新>.md》落盘统一按 `references/optimization-workflow.md` 执行（优化 SKILL 调用见步骤 7 / `optimization-skill-invocation.md`），本章下方的案例库清单为其子步骤 1 的匹配范围速览。

**⚠️ 根因限制（关键）**：综合劣化点汇总中的根因，**除非在案例库中匹配到对应案例，否则不随意给出**；**本章不输出优化建议/修复方案**（修复动作由步骤 7 优化 SKILL 或人工基于匹配结果进行）。

- **案例库范围**（⚠️ 下方为注册清单，**非权威来源**——每次匹配前必须 `ls references/cases/*.md` 实际清点目录，以目录实际内容为准；下方清单可能因新增案例文件后未同步而遗漏）：
  - `references/arkts-leak-cases-and-faq.md`（ArkTS 泄漏案例 1.1/1.2/1.3 + FAQ 9/14 等）
  - `references/cases/hap.md`（HAP 维度劣化案例模式：.abc 劣化 / .so 劣化）
  - `references/cases/dma.md`（DMA 维度劣化案例模式：①不可见 XComponent SurfaceBuffer 未释放，按 libbuffer_handle.z.so 劣化 + .db 帧检索含 SurfaceBuffer 关键帧（DMA 型 SO 无 native heap 火焰图属预期）+ 源码释放逻辑三规则匹配；②cachedCount 缓存图片数量过多，按「Top10 劣化 libhdi.so + 报告 DMA 内存增加 + dma_detail.xlsx 图片数量增加 + 源码 diff 新增 cachedCount」四规则匹配）
  - `references/cases/imageknifepro.md`（ImageKnifePro 维度劣化案例模式：libimageknifepro.so 劣化，以两版 `analysis_详细数据.xlsx` 中该 so 行 `size` 差值为正单规则匹配）
  - `references/cases/taskpool.md`（TaskPool 维度劣化案例模式：libtaskpool.z.so 劣化，三个案例——①跨线程序列化传输大量数据：Top10 劣化 + 火焰图 napi_deserialize 占用增加 + 源码核查 taskpool.Task/taskpool.execute 传参大对象；②新增调用 http 任务：Top10 劣化 + 源码 diff 新增任务承载 http 通信的调用（需 A/B 两版源码做版本 diff，「新增」为必要条件；单版源码无法判定时降级）；③多点新增 @Concurrent 任务：Top10 劣化且旧版无占用 + 新增 @Concurrent 分布在不同文件）
  - `references/cases/worker.md`（Worker 维度劣化案例模式：libworker.z.so 劣化 / worker 新增数量过多，按「Top10 劣化 + 源码 diff worker 数量增加（新增 new worker.ThreadWorker()/new worker.Worker() 调用，或存量调用点创建数量调大）+ worker 实例总数 ≥ 8」三规则匹配）
  - `references/cases/ArkWeb.md`（ArkWeb 维度劣化案例模式：①Web 离线组件预创建，按「libarkweb_engine.so NATIVE_HEAP 增长 + hilog 日志 CreateNWeb/OnDestroy 计数差值 + 离线组件个数 > 0」三规则匹配，hilog 数据由步骤 1 采集落盘至 `meminfo/hilog/`；②预渲染 Web 页面，按「libarkweb_engine.so NATIVE_HEAP 增长 + 源码核查 loadUrl 预加载 + 源码扫描未使用 onInactive」三规则匹配）
  - `references/cases/ArkUI.md`（ArkUI 维度劣化案例模式：libace_compatible.z.so 劣化，6 条案例——预加载不可见 Tab 页面/冗余加载 Tabs 中间页面/Tabs 缓存数量过多/长列表滚动不懒加载/滚动预加载 cachedCount 设置不合理/布局写法冗余低效，均按「libace_compatible.z.so 劣化 + arkui dumpview 或源码核查」两规则匹配）
  - `references/cases/三方框架.md`（KMP/RN/Flutter 维度劣化案例模式：新增使用/内存使用增加/字符库重复加载，按「框架 so 从无到有或 native heap 增长 + 源码核查引入路径」规则匹配）
  - 各 workflow 的「真实案例 / 根因推断表 / 修复建议方向」：`arkts-heap-workflow.md` 步骤 3.3 劣化类型表、`native-heap-workflow.md` 步骤 3.3 劣化类型表、`so-size-hap-workflow.md` 脚本 `suggestion` 字段
- **匹配到案例时**：8.1 根因列引用案例的根因推断并标注出处（如「见 arkts-leak-cases-and-faq.md 案例 1.3」「同 native-heap-workflow.md 泄露类型」）。
- **未匹配到案例时**：8.1 根因列写「未匹配案例库，需人工核查」，仅保留劣化源数据（差值/分析步骤）。**禁止臆测根因、禁止泛化建议**（如「建议优化」「检查代码」等空话不得出现）。
- **可引用的既有结论**：步骤 2 对比报告里脚本 `suggestion` 字段、各 workflow per-SO 归因模板的结论可直接引用；其余发散分析（共性根因/关键发现/总体结论）不写入第八章，保持纯净性（见 `comparison-report-guide.md`「报告纯净性」）。

> 步骤 2 的对比报告 `.md`（`output/对比报告_<旧>_vs_<新>.md`）源文件不含火焰图引用；`report_md_to_html.py` 转 `.html` 时在步骤 4 每个 SO 归因块后自动注入前后对比火焰图链接（相对路径 `flame_compare/<so>_compare_flame.html`，火焰图在 `output/flame_compare/`）。查看火焰图需运行 `python scripts/2_analysis/report_md_to_html.py output/对比报告_<旧>_vs_<新>.md` 生成同级 `.html`（`output/对比报告_<旧>_vs_<新>.html`）后用浏览器打开点击链接跳转（见 `comparison-report-guide.md`「报告 HTML 生成」）。

## 步骤 7：主动优化（报告生成后，调用 harmonyos-memory-optimization-solution SKILL）

**触发条件**：步骤 6 的对比报告与《案例匹配报告_<旧>_vs_<新>.md》已落盘，且匹配报告第一章存在**匹配成功**的劣化源（无匹配成功项时跳过本步骤——未匹配/部分命中场景不得臆测优化）。

**执行依据**：`references/optimization-skill-invocation.md`（本地 SKILL 检查、远程安装流程、安装约束、调用传入参数、主动优化闭环与复测对账口径的唯一详细定义）。

**流程概要**（详见上述文档）：

1. 检查/安装优化 SKILL（`.claude/skills/harmonyos-memory-optimization-solution/`，缺失时按文档远程安装流程拉取，禁止覆盖已存在的扩展版）
2. 调用 SKILL：传入**匹配成功**的劣化场景 + 根因/源码位置 + 应用源码工程路径（数据范围硬约束：仅分析该路径）
3. SKILL 内部走「定位场景 → 优化方案 → **逐一询问用户确认（不得批量确认/代答）** → 执行优化 → 构建验证」
4. **内存复测不进优化 SKILL**：优化后构建重新出包，回到步骤 1 采集流程（优化后新版本 vs 基线版本），步骤 2 重新生成对比报告做差值收敛对账（劣化源差值/DMA 调用栈差分/dmabuf 快照三项口径，见文档 §3.3），复测结果回写优化方案文档「复测记录」节；未收敛时回 SKILL 步骤 1 重新排查

## 目录结构

```
hmos-memory-anti-regression/
├── SKILL.md                          # Skill 入口：流程骨架 + 决策逻辑
├── test-cases/                       # 测试用例
│   ├── trigger.md                    # 触发验证测试（test-runner）
│   ├── functional.md                 # 功能性测试（test-runner）
│   ├── test-prompts.md               # 测试提示词（8 个场景，手动集成测试）
│   ├── test-case-1.md                # 双版本全闭环测试
│   └── test-case-2.md                # Top10 分发判定测试
├── references/                       # 详细参考资料（AI 执行时按需查阅）
│   ├── environment.md               # 环境搭建指南（工具下载/安装/配置）
│   ├── collection-workflow.md        # 采集工作流
│   ├── analysis-workflow.md          # 分析工作流 + 归因规则
│   ├── comparison-report-guide.md    # 对比报告格式和注意事项
│   ├── arkts-heap-workflow.md        # ArkTS Heap 深度分析工作流
│   ├── native-heap-workflow.md       # Native Heap 深度分析工作流
│   ├── so-size-hap-workflow.md      # SO_SIZE/HAP smaps 对比分析工作流
│   ├── snapshot-object-guide.md      # 快照对象类型/属性参考
│   ├── optimization-workflow.md     # 案例匹配报告流程（主调用点：步骤 6 第八章；匹配案例库 + 落盘案例匹配报告并回填 Top10 章节故障模式，可复用，不出优化方案；SKILL 调用已分离至 optimization-skill-invocation.md）
│   ├── optimization-skill-invocation.md  # 优化 SKILL 调用与主动优化执行（步骤 7 依据：SKILL 检查/远程安装/调用参数 + 逐一确认→执行优化→构建验证闭环 + 复测对账口径）
│   ├── arkts-leak-cases-and-faq.md   # 泄漏案例和 FAQ
│   ├── cases/                        # 案例库（供 optimization-workflow.md 匹配）
│   │   ├── hap.md                    # HAP 劣化案例模式（.abc/.so）
│   │   ├── dma.md                    # DMA 劣化案例模式（不可见 XComponent SurfaceBuffer 未释放）
│   │   ├── imageknifepro.md          # ImageKnifePro 劣化案例模式（libimageknifepro.so）
│   │   ├── taskpool.md               # TaskPool 劣化案例模式（libtaskpool.z.so：序列化大对象传输/http 任务/多点新增 @Concurrent）
│   │   ├── worker.md                 # Worker 劣化案例模式（libworker.z.so：worker 新增数量过多）
│   │   ├── ArkUI.md                   # ArkUI 劣化案例模式（libace_compatible.z.so：Tab 预加载/缓存/长列表等 6 条）
│   │   ├── ArkWeb.md                  # ArkWeb 劣化案例模式（libarkweb_engine.so：离线组件预创建/预渲染）
│   │   └── 三方框架.md                # KMP/RN/Flutter 劣化案例模式
│   ├── hidumper_commands.md          # hidumper 命令完整参考
│   ├── hiprofiler_config.md          # hiprofiler_cmd 配置参考
│   └── 对比报告.md                 # 对比报告模板
├── scripts/
│   ├── 0_prerequisites/              # 环境检查
│   │   └── check_env.py
│   ├── 1_collection/                 # 数据采集
│   │   ├── collect.py                # 主采集脚本 (支持 --scenario --scenario-dir 自动场景复现)
│   │   ├── dump_mem.py
│   │   ├── convert_htrace.py
│   │   ├── convert_htrace_to_sqlitedb.py
│   │   └── verify_collection.py       # 产物完整性校验
│   ├── 2_analysis/                   # 归因分析
│   │   ├── harmonyos_pipeline.py    # meminfo 生成(showmap/gpu/dma → meminfo.xlsx)
│   │   ├── base_pipeline.py          # meminfo 生成基类(Layer1MaPipeline)
│   │   ├── main_analysis_all_mem.py  # 归因分析主入口
│   │   ├── analyze.py
│   │   ├── statistic_htrace_analysis.py
│   │   ├── first_kind_proc.py
│   │   ├── third_kind_proc.py
│   │   ├── topdown.py
│   │   ├── hidumper.py
│   │   ├── hybrid_mod.py
│   │   ├── callchain.py
│   │   ├── detail_mode.py
│   │   ├── rule.py
│   │   ├── tracedbs.py
│   │   ├── analysis_utils.py
│   │   ├── generate_comparison_report.py  # 对比报告生成(topdown/汇总/Top10/DMA)
│   │   ├── report_md_to_html.py      # 对比报告 md→html(注入步骤4火焰图链接)
│   │   └── so_field/                 # SO 归因规则
│   ├── 3_arkts_heap/                 # ArkTS Heap 深度分析
│   │   ├── shortest-path.mjs
│   │   ├── compare_diff.py
│   │   ├── resolve_chain_props.js   # 链级 Δ 模块聚合(Top3 劣化模块 +相关链明细 + VM 内部参考)
│   │   ├── resolve-lines.py
│   │   ├── queryNode.js              # 查对象属性及属性值
│   │   ├── self_size.mjs             # self size 计算
│   │   └── package.json
│   ├── 4_native_heap/                # Native Heap 深度分析
│   │   ├── cluster_calltree.py      # 聚类树(<so>_tree.json)
│   │   ├── diff_cluster_tree.py     # 差分树(<so>_diff.json)
│   │   ├── build_flame_summary.py  # 火焰图(单版本/前后对比, bs4 单文件)
│   │   ├── analyze_diff.py           # 差分分析
│   │   └── statics/                 # d3 火焰图模板+资源(flame/flame-c/example.template)
│   ├── 5_so_size_hap/                 # SO_SIZE/HAP smaps 对比分析
│   │   └── diff_smaps.py
│   └── _lib/                         # 公共库
│       ├── __init__.py
│       ├── config.py
│       ├── cmd_runner.py
│       ├── hidumper_cmd_runner.py
│       ├── file_utils.py
│       ├── encoding.py
│       ├── tool_finder.py            # 工具路径自动查找(hdc/trace_streamer/addr2line)
│       └── utf8_bootstrap.py
```

## 验证门槛

1. **采集后**: htrace > 100MB (冷启动60s) 表示有数据
2. **转换后**: .db > 50MB，native_hook 表有数据
3. **分析后**: 汇总.xlsx 行数 > 50，topdown 报告覆盖率 > 75%
4. **对比报告**: 总内存差值合理（同版本两次冷启动波动约 ±40 MB）
5. **第六章 6.1 ArkTS Heap 小节格式**：每条归因项按编号模板（`Δ=` + `count=` + `GROWN/NEW` 三字段齐全），详细条目不用表格化（开头汇总表格除外）；count 仅在归因行，引用链行节点括号无 count；`compare_diff.py` stdout 中的 count 列已逐条填入归因行（缺失即人工抄写错误，须回查原始输出补齐）；开头汇总表格含锚点跳转链接且与条目 `<a id>` 配对
6. **优化方案证据实测**（防证据编造）：优化方案/对比报告第八章中的每一条**数据规则证据**（如差分树含某帧、火焰图某帧占用增加、xlsx 某值）均已对落盘产物执行实际检索（`grep`/读取 JSON/xlsx），证据列含"产物路径 + 检索命令 + 真实输出"；产物中检索不到的关键帧（如 `napi_deserialize`）按「❌ 不通过」判定而非写"含该帧"。抽查：随机挑 1-2 条数据规则证据，用对应检索命令复查，确认报告表述与产物一致；不一致即证据编造，须重跑该规则判定
7. **规则类型不可替代校验**（防规则类型混淆）：案例匹配报告中每条规则的类型标注（数据规则/核查规则）与案例文档一致；数据规则的证据来自落盘产物（非源码核查），核查规则的证据来自应用源码（非产物数据）；抽查 1-2 条数据规则，确认证据列不含源码核查替代
8. **子 agent 结果复核校验**（防子 agent 误判传播）：案例匹配委托 general agent 执行时，主 agent 已逐条复核子 agent 返回的每条规则判定——对标注「✅通过」的数据规则抽查产物复查，对标注「❌不通过/未匹配」的判定检查是否引入了规则之外的主观判断
9. **规则内子条款完整性校验**（防口径子条款遗漏）：案例匹配中每条规则的判定不仅检查标题条件，还检查规则正文中的口径区分/例外/降级子条款。抽查方法：对标注「✅通过」的核查规则，回查规则正文是否含统计口径子条款，若有则核查证据列是否对每个口径子条款都给出了判定（而非只查了标题条件）。典型反例：worker.md 规则 3「同一任务 worker 数量 ≥ 8」，`WORKER_COUNT=8` 但 `WORKER_SCRIPTS[i]` 是不同 script 路径（口径 b 多任务并行），同一任务实例数 = 1 < 8，规则 3 不通过——只看标题条件 `8 ≥ 8` 判通过即此校验失败
