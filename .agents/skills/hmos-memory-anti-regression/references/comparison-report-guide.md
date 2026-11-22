# 对比报告指南

## 对比报告格式

对比报告格式参考 `references/对比报告.md`，包含以下章节：

1. **深度分析结果**：步骤 3（ArkTS Heap）/ 4（Native Heap）/ 5（SO_SIZE/HAP smaps）对 Top10 中触发深度分析的 SO 逐个归因，合并引用链/根因推断/修复建议/**严重性定级（<span style="color:#e74c3c">高</span>/<span style="color:#e6a700">中</span>/<span style="color:#3498db">低</span>）**（详见下方「深度分析结果（第一章）」节）
2. **Topdown 总览对比**：各内存类别总量差值（markdown 表格）
3. **汇总表一层领域对比**：一层领域总量差值（markdown 表格）
4. **汇总表层级结构**：一层领域→二层领域→SO→type_name 差值（HTML rowspan 合并单元格表格，差值 > 1MB）
5. **Top10 劣化 SO**：以 SO 为键（非 SO+type_name），同一 SO 的多个 type_name 差值累加得出总差值，按总差值降序取前 10，排除虚拟分类；type_name 明细列标注各 type_name 的差值
6. **DMA 对比分析**：DMA 总览对账 + Top10 图片/资源劣化（数据来源 `dma_detail.xlsx` + `mm_dmabuf_info`，详见下方「DMA 对比分析」节；仅展示数据，不写结论/修复建议）
7. **不确定性说明**：碎片波动/addr2line 待符号/sourceMap 限制/步骤覆盖范围等
8. **综合劣化点汇总与优化建议**：8.1 劣化源汇总 + 8.2 优化建议（限制规则见下方「第八章」节）

## 报告纯净性

对比报告是**纯净的数据产物**，只包含以下两类内容：

1. **结构化数据表**：二~六章各章规定的数据（topdown 总览、汇总表、Top10 劣化 SO、DMA 总览/Top10 图片）。
2. **步骤 3/4/5 脚本产出的归因**：第一章中由脚本/工作流直接产出的字段——ArkTS 的 GROWN/NEW 链 + 责任侧 + delta_kb + **count（对象数）** + **引用链 + 根因推断**（按 `arkts-heap-workflow.md` 编号模板逐条输出，归因行格式含 Δ、count、GROWN/NEW）+ **优化方向（引用链拆解，章节级总体建议，置于 1.1 小节开头仅一条，不按引用链逐条补充）**、Native 的差分树 root delta + Top N 叶子 + per-SO 根因、SO_SIZE/HAP 的 `root_cause`/`suggestion` 字段。

**禁止**（属发散分析，不得出现在对比报告中）：
- 跨 SO / 跨章节的"共性根因""关键发现""总体结论""劣化源汇总"等 agent 自行归纳的综述段落。
- 各章末尾追加的"修复建议/优化方向"小结（修复建议只在脚本 `suggestion` 字段或工作流规定的 per-SO 归因里出现；ArkTS Heap 的「优化方向（引用链拆解）」是章节级总体建议、置于 1.1 小节开头，不属于此处禁止的"章末小结"；DMA 章节完全不写结论/建议）。
- 对数据的二次解读、推测、风险评级。

> 综述、优化建议、风险评级统一放到综合防劣化分析报告（步骤 6 产出），不进对比报告。

## 劣化项过滤规则

**Delta < 1MB 的劣化项不展示**——汇总表和详细归因中均省略，仅在注释中提及被省略的 SO 名称。

适用范围：
- **ArkTS Heap 汇总表**：合计 Δ(KB) < 1024（即 < 1MB）的模块行省略
- **Native Heap 汇总表**：root delta < 1MB 的 SO 行省略
- **SO_SIZE/HAP smaps 表**：差值 < 1MB 的 SO 行省略
- **详细归因**：Delta < 1MB 的条目不单独列出

省略时在表后注释中说明被省略的 SO/模块名称及原因。

## 汇总表锚点链接

**汇总表中的 SO/模块名加 markdown 锚点链接**，点击跳转到对应的详细归因段落：

- 详细归因段落用 `<details>` 折叠，`<a id="锚点名">` 放在 `<summary>` 标签内（如 `<summary><a id="nh-libffmpeg">libffmpeg.so</a></summary>`），确保 JS 的 `closest('details')` 能找到并展开
- 汇总表中 SO/模块名用 `[SO名](#锚点名)` 格式链接
- 无详细归因段落的 SO（如被 < 1MB 过滤掉的）不加链接

### 锚点命名规则

| 章节 | 锚点格式 | 示例 |
|------|---------|------|
| Native Heap | `nh-<so名>` | `nh-libffmpeg`, `nh-network_access` |
| SO_SIZE/HAP | 不需要（表格本身即为详细归因） | — |

## 第四章汇总表层级结构模板

使用 HTML `<table>` + `rowspan` 实现单元格合并，规则如下：

- 一层领域、二层领域、同名 SO 均用 `rowspan` 合并
- 同一 SO 的多个 type_name 行，SO 列只出现一次
- 同一二层领域的多个 SO 行，二层领域列只出现一次
- 同一一层领域的多个二层领域行，一层领域列只出现一次

```html
<table>
<tr><th>一层领域</th><th>二层领域</th><th>so</th><th>type_name</th><th>旧版(MB)</th><th>V3(MB)</th><th>差值(MB)</th></tr>
<tr><td rowspan="N">一层领域</td><td rowspan="N">二层领域</td><td rowspan="N">so名称</td><td>type_name</td><td>旧版</td><td>新版</td><td>差值</td></tr>
...
</table>
```

## 排序规则

- **分配器碎片、未覆盖、空服务、其他、(未命名)** 属于无法进一步分析的内存，通篇排序中一律放在对应类别最后
- 此规则适用于所有章节：汇总表层级结构、Top10 劣化 SO
- 汇总表层级结构中，每一层（一层领域/二层领域/SO）内部按差值降序排列，上述无法分析的条目放末尾
- **Top10 劣化 SO 不包含虚拟分类**（分配器碎片/空服务/未覆盖/其他），这些条目无法进一步分析，不应出现在劣化排名中

## 分配器碎片

- "分配器碎片"属于**没有足够证据归因**的内存，无法定位到具体业务代码
- 两次冷启动间分配器碎片波动可达 **±30 MB**，需结合多次采集确认是否存在真实的碎片劣化
- 在对比报告中，分配器碎片的优化方向列留空

## 空服务

- `empty_service` 阈值设为 35 MB，低于此值的进程内存归为"空服务"
- 空服务内存是系统框架基础开销，通常不作为优化目标

## 数据波动

- 同版本两次冷启动间总内存波动约 **±40 MB**
- **±40 MB 仅用于判断总内存差值是否有意义**，不适用于 SO/领域/类别等单项差值；单项差值是否显著参考分析脚本 `limit` 的过滤阈值（默认 < 5 MB 过滤），大于该阈值的单项劣化均应列出分析

## DMA 对比分析

DMA 章节必须遵守以下硬约束，防止数据造假与漏报：

### 数据来源（唯一）

- **图片/资源明细**：读取 `analysis/dma_detail.xlsx` 的 `DMA_by_image` sheet，取差值降序前 10 的劣化项（正差值）。
- **buf_name 用完整形式**：取 `dma_detail.xlsx` 的完整 buf_name；`topdown报告-默认场景.xlsx` 的 "DMA Top20" 会截断到约 60 字符显示（如 `...streamsize-107947-` 切掉 `-mimetype-png`），不得照抄。buf_name 中的 `*` 是系统对 `resource://` 路径的掩码（如 `re*ou*ce`=resource），非截断。
- **原始校验**：`mm_dmabuf_info_<pid>.txt` 是 dma_detail.xlsx 的数据源，列含 `buf_name/buf_type/size_bytes`。
- **禁止**：不得照抄模板示例里的 `graphics/camera/video` 等 buf_type；必须用两版本实际出现的 buf_type（冷启动常见如 `pixelmap`、`NULL`）。

### 三方对账（必做）

DMA 总量在三个来源中必须一致，任一不符先查原因再写章节：

| 来源 | 取值方式 | 应等于 |
|---|---|---|
| topdown 报告 `Graph` 行 | `topdown报告-默认场景.xlsx` 顶层 Graph(MB) | DMA 合计 |
| 汇总表归因 | 汇总表层级结构中 `libdmabufheap.z.so` / type_name=`DMA` 行 | DMA 合计 |
| dma_detail 合计 | `DMA_by_buf_type` sheet 全行 size_MB 求和 | DMA 合计 |

> 三者一致才可落笔写 DMA 章节。若 dma_detail 合计 ≠ topdown Graph，说明 DMA buffer 采集/归因异常，需在报告中显式标注差异并排查，**不得填一个不相关的数（如"0.21 MB 无变化"）蒙混**。

### 章节结构

DMA 劣化（合计差值 > 0.5 MB）时，章节应包含：总览（对账）→ Top10 图片/资源劣化（按差值降序，仅列正差值劣化项）。**不写结论/修复建议节**；合计差值 < 0.3 MB 时，一句话说明无劣化即可。

## Top10 劣化 SO 计算步骤

### 数据源选择

**必须使用 `analysis_详细数据.xlsx`（详细数据），而非 `汇总.xlsx`（汇总表）**。原因：

- 汇总表将小 SO 归入"其他"虚拟分类，丢失逐 SO 差值信息（例如旧版某 SO 不存在时，其内存被归入"其他"，新版该 SO 出现后差值被严重高估）
- 汇总表使用短名（如 `libfoo.so`），详细数据使用完整路径（如 `/data/storage/el1/bundle/libs/arm64/libfoo.so`），需 `os.path.basename()` 取短名
- 详细数据提供精确浮点值，汇总表使用 MB 后缀字符串（如 `"5.00 MB"`），需额外解析

### 计算脚本

使用 `scripts/2_analysis/analysis_utils.py` 中的 `diff_top10_so()` 函数：

```python
from analysis_utils import diff_top10_so

result = diff_top10_so(
    "output/<旧版目录>/analysis/analysis_详细数据.xlsx",
    "output/<新版目录>/analysis/analysis_详细数据.xlsx",
)
print(result.to_string())
```

返回 DataFrame 列：`so`、`total_delta`、`type_name_detail`（各 type_name 差值，降序排列）。

### 计算流程（7 步）

```
步骤 1：读取旧版详细数据 → 所有 (SO, type_name) 组合
步骤 2：读取新版详细数据 → 所有 (SO, type_name) 组合
步骤 3：逐条计算差值（新版 - 旧版），旧版无对应条目则旧版值为 0
步骤 4：排除虚拟分类（见下方排除列表）
步骤 5：以 SO 短名为键聚合，同一 SO 的多个 type_name 差值累加
步骤 6：过滤 SO 总差值 > 1 MB（`total_delta <= min_delta_mb` 的 SO 不统计，默认 1.0）
步骤 7：按总差值降序排列，取前 10
```

> **差值阈值**：SO 的前后版本总差值必须 **> 1 MB** 才进入 Top10 统计；小于等于 1 MB 的 SO 不计入劣化排名（`diff_top10_so(min_delta_mb=1.0)`，可调）。

### 虚拟分类排除列表

以下 `so` 列值属于无法进一步分析的内存，计算 Top10 时必须排除：

- `ArkTS Heap分配器碎片`
- `Native Heap分配器碎片&未覆盖`
- `Native Heap空服务`
- `Filepage Other分配器碎片`
- `AnonPage Other分配器碎片`
- `ArkTS Heap未覆盖`
- `GL分配器缓存`
- `其他`
- `(未命名)`
- `dev分配器碎片`
- `.db分配器碎片`
- `ArkTS Heap空服务`
- `GL空服务`
- `guard空服务`
- `guard分配器碎片`
- `DMA空服务`
- `DMA分配器碎片`
- `AnonPage Other空服务`
- `.db空服务`
- `dev空服务`
- `Filepage Other空服务`
- `[anon:native_heap:brk]`
- `[anon:native_heap:meta]`
- `[anon:native_heap:jemalloc meta]`
- 非字符串值（如 NaN）

### 输出格式

Top10 劣化 SO 表格包含以下列：

| 排名 | SO 名称 | 总差值(MB) | type_name 明细 | 故障归因 |
|------|---------|-----------|----------------|---------|
| 1 | libxxx.so | +5.00 | ARKTS_HEAP: +3.00, NATIVE_HEAP: +2.00 | - ✅ <案例出处>：<故障模式一句话> |

type_name 明细列标注该 SO 各 type_name 的差值，便于判断该 SO 应分发到哪些深度分析步骤（3/4/5）。

**「故障归因」列（步骤 6 回填，规则以 `SKILL.md` 步骤 6 为准）**：
- 列内容为优化方案文档中**匹配成功**案例的故障模式一句话描述（与案例原文表述一致，不扩展，如「taskpool 新增调用 http 任务」），**分点列出**（每行 `- ` 前缀、多条用 `<br>` 分隔）。
- **只针对对应 SO**：只填该 SO 自己命中的案例故障描述；不得把其他 SO 的案例跨行套用（如 libtaskpool 的 http 任务案例不得套到同调用链的 libhttp/libcurl/application/libace 等），不得臆测补充。
- **未命中不填**：该 SO 未匹配案例库（含部分命中）时留空，不写「未匹配案例库，需人工核查」；部分命中不算命中，不填。
- 回填后须重新执行 `report_md_to_html.py` 同步 `.html`。

## 深度分析结果（第一章）

- 步骤 3（ArkTS Heap）、步骤 4（Native Heap）、步骤 5（SO_SIZE/HAP smaps）的触发逻辑以 `SKILL.md`「步骤 3/4/5 触发逻辑」为唯一定义：对第五章的 Top10 劣化 SO（按差值排序、排除虚拟分类）**逐个 SO** 按其 type_name 明细分发到步骤 3/4/5，每个步骤只分析被分发到它的 SO
- 深度分析置于报告**首章**，便于先看归因结论与严重性，再翻阅后续数据章节
- **严重性定级（<span style="color:#e74c3c">高</span>/<span style="color:#e6a700">中</span>/<span style="color:#3498db">低</span>，每条深度分析项必填）**：基于该 SO 前后版本 size 差值与增长比例综合判定，取两者中更严重的一档——<span style="color:#e74c3c">高</span>=差值≥10MB 或 增长比例≥50% 或 新增（旧版=0）；<span style="color:#e6a700">中</span>=差值3–10MB 或 比例20–50%；<span style="color:#3498db">低</span>=差值<3MB 且 比例<20%（增长比例=(新版−旧版)/旧版×100%，旧版=0 视为新增定<span style="color:#e74c3c">高</span>）。**降级规则**：结合源码分析后，若劣化来自自身业务场景的新增功能（如新增页面/模块/能力带来的正常内存增长）或其他无需修复的场景（如测试桩、调试代码、已知可接受的框架开销），严重性可降为<span style="color:#3498db">低</span>。降级须在归因中注明降级理由（如「新增 XX 功能模块，属业务正常增长，降为低」）。

### 各步骤的结果输出

每个步骤独立产出归因结果，**必须合并写入对比报告第一章「深度分析结果」**：

| 步骤 | 触发条件 | 产出文件 | 归因格式来源 |
|------|---------|---------|-------------|
| 3 ArkTS Heap | type_name 含 ARKTS_HEAP | `*.compare.html` / `*.compare.json` / `*.resolved.json` / `*.chain-props.json` (Top3 劣化模块，链级 Δ 模块聚合，见下方「Top3 劣化模块」) | `arkts-heap-workflow.md`「报告内容格式」编号模板（含归因行 + 引用链 + [劣化模块明细] + 根因推断 四字段；归因行含 Δ、count、GROWN/NEW）+ 小节开头一条总体优化方向（引用链拆解） |
| 4 Native Heap | type_name 不全是 SO_SIZE/HAP/DMA | `<so>_diff.json` + Top N 叶子摘要 + `<so>_compare_flame.html`（前后对比火焰图，见 `native-heap-workflow.md` 步骤 5） | `native-heap-workflow.md` 步骤 4 报告模板 |
| 5 SO_SIZE/HAP | type_name 含 SO_SIZE/HAP | `diff_smaps.py` stdout 文本报告 / `smaps_diff.json` | `so-size-hap-workflow.md` 步骤 2-3（root_cause/suggestion 字段） |

### 对比报告第一章要求

- 深度分析结果**必须作为对比报告的第一章「深度分析结果」**输出，与二~八章同处一份报告。
- **每个劣化点用 `<details>` 折叠**——归因行（SO名+严重性+差值+count+GROWN/NEW）放在 `<summary>` 中作为可点击标题，引用链/根因推断/修复建议/火焰图链接放在 `<details>` 体内，默认收起，点击展开。**锚点 `<a id="锚点名">` 放在 `<summary>` 标签内**，确保从汇总表点击锚点跳转时 JS 能找到最近的 `<details>` 并自动展开。
- **步骤 3/4/5 触发 SO 明细用 `<details>` 折叠**——放在第一章标题下、各小节之前，默认收起，点击展开。内容为三个步骤各自触发的 SO 列表及对应 type_name 差值。
- 按步骤 3/4/5 分小节（1.1/1.2/1.3）组织，每个小节内对**被分发到该步骤的 SO** 逐个列出归因结论（引用链 / 根因推断 / **严重性定级**），格式遵循各工作流的报告模板。**每个小节内的 SO 按最终严重性从高到低排列（<span style="color:#e74c3c">高</span>→<span style="color:#e6a700">中</span>→<span style="color:#3498db">低</span>）——最终严重性是指经降级规则调整后的结果，而非初始定级。例如某 SO 初始定级为高，但结合源码分析后降级为低，则该 SO 按低排列。**ArkTS Heap 小节（1.1）开头放一条总体优化方向（引用链拆解），随后按 `arkts-heap-workflow.md` 编号模板逐条输出「归因行（含 Δ、count、GROWN/NEW） + 引用链 + [劣化模块明细] + 根因推断」四字段，优化方向不按引用链逐条补充。**
- **Native Heap 小节（1.2）开头必须放总览表格**：按 `native-heap-workflow.md` 步骤 4.1 模板输出，列为 `# / SO(锚点链接) / 劣化前(MB) / 劣化后(MB) / Root Delta(MB) / 劣化叶子数 / 最大叶子Delta(MB) / 严重性 / 火焰图 / 主要劣化路径简述`，按 Root Delta 降序排列；表格下方逐 SO 详细归因按最终严重性从高到低排列。总览表格的 SO 名加锚点链接 `[so名](#nh-<so名>)`，与 `<summary>` 中的 `<a id="nh-<so名>">` 配对，点击跳转自动展开 `<details>`。小节末尾须包含「缺失符号表 SO 清单」（见 `native-heap-workflow.md` 步骤 4.3），列出调用链中未提供 debug SO 的帧，提醒用户补充后只需重跑步骤 3、无需重新采集。
- **汇总表锚点链接**：汇总表中的 SO/模块名加 markdown 链接（`[SO名](#锚点名)`），点击跳转到对应的详细归因段落；锚点 `<a id="锚点名">` 放在对应劣化点的 `<summary>` 标签内，跳转时自动展开 `<details>`
- **Delta < 1MB 的劣化项不展示**（详见上方「劣化项过滤规则」）
- **汇总表不加合计行**——合计值在跨模块场景下存在重复计入，无参考意义
- **不加"未映射"说明段落**——来源已在汇总表的"业务模块"和"来源包/HAP"列中体现
- 未触发深度分析的 SO（如全部命中虚拟分类）在第一章注明「无 SO 进入深度分析」。
- **DMA 调用栈火焰图（6.4 独立小节，不进 6.2）**：Top10 劣化 SO 中明细含 DMA 的 SO（如 `libbuffer_handle.z.so`），其 DMA 调用路径火焰图（`cluster_calltree.py --frame` 帧名聚类 + `--compare` 生成，见 `native-heap-workflow.md` 步骤 6）挂第六章独立小节（如「6.4 DMA 调用栈归因（辅助）」），用 `<iframe src="flame_compare/<so>_compare_flame.html">` 嵌入。**硬约束：不得写入 6.2 Native Heap 小节、不得并入 native heap 统计/排名**——树上 value 是栈上 malloc 存活分配量（路径归因辅助，通常接近 0），DMA 内存量以第五章 dma_detail 为准；小节开头须注明该口径。A 版空树基线（无匹配调用栈）= 旧版未执行该路径，与 dmabuf 明细（0 条 → N 条）互为印证，如实标注。

### Top3 劣化模块（ArkTS Heap，链级 Δ 模块聚合）
- 一个模块会出现**多条**差分链上，单条链 Δ 只有 KB 级、与总劣化无可比性；**模块劣化 = 该模块相关全部差分链 Δ 之和**，与总劣化 Δ 同口径、可直接对比。在**引用链与根因推断之间**插入 「Top3 劣化模块」表格，由 `resolve_chain_props.js` 自动产出(`*.chain-props.json`)：
 ```
 引用链：...
 **Top3 劣化模块（按全量差分链 Δretained 按模块聚合降序，模块劣化 = 该模块全部相关链 Δ 之和）**：
 | # | 模块 | 模块劣化 Δ | 相关链数 | count | 代表链锚点 | 代表链 Δ | 责任侧 |
 |---|---|---|---|---|---|---|---|
 | 1 | xx | xx | xx | xx | xx | xx | xx |
 | 2 | xx | xx | xx | xx | xx | xx | xx |
 | 3 | xx | xx | xx | xx | xx | xx | xx |

 >参考（非业务模块，不占 Top3）：(VM 内部/系统)Δ = xxxMB —— VM 形状元数据/系统框架，随开发者对象回落。

 根因推断：...
 ```

## 第七章：不确定性说明

列出分析过程中的不确定因素，包括但不限于：
- **分配器碎片波动**：±30MB 波动范围，需多次采集确认
- **数据波动范围**：±40MB 总内存波动
- **addr2line 待补充 debug 符号**：stripped SO 的未解析帧偏移量
- **sourceMap 版本与文件类型限制**：`.js` 模块无法还原到 `.ets`；sourceMap 版本差异导致的行号偏移
- **步骤覆盖范围**：未参与某步骤分析的 SO 及原因（如 DMA 类型非 malloc 堆、非 .so 文件无独立追踪数据等）

## 第八章：综合劣化点汇总与优化建议

第八章分两节：**8.1 劣化源汇总**（排名 / 劣化源 / 差值(MB) / 根因 / 分析步骤）+ **8.2 优化建议**（按优先级排序）。

### 根因与修改建议限制（关键）

综合劣化点汇总与优化建议中的根因和修改建议，**除非在案例库中找到对应的案例和解决方法，否则不随意给出**。

- **案例库范围**：
  - `references/arkts-leak-cases-and-faq.md`（ArkTS 泄漏案例 1.1/1.2/1.3 + FAQ 9/14 等）
  - 各 workflow 的「真实案例 / 根因推断表 / 修复建议方向」：`arkts-heap-workflow.md` 步骤 3.3 劣化类型表、`native-heap-workflow.md` 步骤 3.3 劣化类型表、`so-size-hap-workflow.md` 脚本 `suggestion` 字段
- **匹配到案例时**：可引用案例的根因推断与修复方向，并标注出处（如「见 arkts-leak-cases-and-faq.md 案例 1.3」「同 native-heap-workflow.md 泄露类型」）。
- **未匹配到案例时**：8.1 根因列写「未匹配案例库，需人工核查」，8.2 不给修改建议，仅保留劣化源数据（差值/分析步骤）。**禁止臆测根因、禁止泛化建议**（如「建议优化」「检查代码」等空话不得出现）。
- **禁止泛化条目**：8.2 不得出现「未匹配案例库，需人工核查」的泛化汇总条目——仅列出有明确根因/建议的劣化源，未匹配的不列。
- **可引用的既有结论**：步骤 2 对比报告里脚本 `suggestion` 字段、各 workflow per-SO 归因模板的结论可直接引用；其余发散分析（共性根因/关键发现/总体结论）不写入第八章，保持纯净性。

## 报告 HTML 生成（注入火焰图链接）

对比报告 `.md` 的 md 源文件**不含**火焰图引用；`report_md_to_html.py` 转换时自动扫描 `output/flame_compare/` 目录，按 SO 名称匹配归因段落，在第一章 Native Heap 深度分析**每个 SO 的 `<summary>` 中**注入该 SO 的前后对比火焰图链接（火焰图固定输出到 `output/flame_compare/<so>_compare_flame.html`，与报告 `.html` 同级故相对路径可解析）。**不需要手写链接**，AI 填充归因文本即可，转 html 时自动插入。

```bash
python scripts/2_analysis/report_md_to_html.py <对比报告.md> [-o <对比报告.html>]
```

- `python-markdown` 库 + `md_in_html` 扩展：raw HTML（含 `<table>`、`<details>`）原样直通，0 转义。
- 产物 `.html` 与 `.md` 同级（均固定在 `output/` 下）；火焰图链接用相对路径 `flame_compare/<so>_compare_flame.html`，火焰图固定在 `output/flame_compare/`，与报告 `.html` 同级故相对路径可解析。**不得用 `-o` 改变报告路径或把火焰图输出到其他目录**，否则链接相对路径失效。
- 依赖：`pip install markdown`。
- 单个火焰图本身是 `build_flame_summary.py --compare --single-file` 产出的单文件（d3 已内联），不依赖 `statics/`；报告 `.html` 通过链接引用它们，所以 `flame_compare/` 目录需随报告一起分发。
