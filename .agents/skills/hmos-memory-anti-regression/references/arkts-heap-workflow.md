# ArkTS Heap 深度分析工作流

**独立分析步骤**：本步骤不依赖 step 2 的 topdown 对比结果，可独立执行并输出自己的分析报告。在完整防劣化流程中，本步骤由 Top10 劣化 SO 中 type_name 含 ARKTS_HEAP 的 SO 触发（分发规则见 `SKILL.md`「步骤 3/4/5 触发逻辑」）；heapsnapshot 为全堆分析，归因重点是被分发 SO 对应的 ArkTS 对象增长。

> **Windows (Git Bash) 用户**：执行 `hdc shell` 或 `hdc file recv` 命令前，必须先运行 `export MSYS_NO_PATHCONV=1` 和 `export MSYS2_ARG_CONV_EXCL="*"`，否则设备端路径 `/data/log/reliability/...` 会被 Git Bash 自动转换为 `C:/Program Files/Git/data/log/...`，导致 heapsnapshot 拉取失败。详见 `references/collection-workflow.md` 顶部的路径转换警告。

## 前置条件

1. 两个版本的 heapsnapshot 文件（A=旧版/基线，B=新版/当前，**由外部提供**——本工作流不含采集步骤）
2. 两个快照必须是 GC 后采集的（`hidumper --mem-jsheap <pid>`），同一业务场景

## 两步工作流

### 步骤 1：计算 GC Root 最短路径 + 对比

> ### ⚠️ 劣化判据（唯一判据）
> **劣化只看版本增量**：A→B 只要存在 Δretained > 阈值的条目，**即为劣化**——先不问大小、先不问是否"固定"。
> ❌ **不要**用"它是 O(1)/固定/count 不变"否定一个**已存在的版本增量**——固定开销也是 baseline 的一部分，涨了就是劣化；该不该留由步骤 2 依据性核查决定。
> **反面教训（真实案例）**：A→B 版本增量 +4.84 KB 明显存在，却被"它是 O(1) 固定开销"错误否定。**版本增量是否存在，与它是否固定，是两件不相干的事。**

```bash
# 1. 对两个快照分别计算 shortest-path(带 --aggregate 聚类,clusterKey 供 compare_diff.py 直接 join)
node scripts/3_arkts_heap/shortest-path.mjs A.heapsnapshot --all --aggregate --json
node scripts/3_arkts_heap/shortest-path.mjs B.heapsnapshot --all --aggregate --json

# 2. 对比两个 JSON，找 retained-size 增量
python scripts/3_arkts_heap/compare_diff.py A.shortest-path.json B.shortest-path.json --top 10 --json
```

`compare_diff.py` 输出（默认带 `--top 10`：**只截"展示"、不截"判定"**——汇总卡片按全量统计，判劣化看汇总；要追前 10 名以外的链重跑去掉 `--top`）：
- **文本表格**（stdout）：按责任方（ArkTS/Native/Unknown）分组，显示 GROWN/NEW 链（含 delta_kb、count、链类型 tag）
- `--json [PATH]`：结构化 JSON，供下游 resolve-lines.py 使用；rows 每条含 `{delta_kb, count, seq, chain, tag(GROWN/NEW), fm, side}`

> **可比性前提**：A、B 必须同一业务场景、同一预热程度下抓取。若两侧出现"毛增长与毛缩减量级相当、净 retained 几乎不变"的剧烈对调，说明抓取状态不一致，那部分 Δ 是噪声而非版本劣化。（注：这不是用"固定开销"否定真实增量——那是被禁止的——而是用结构性证据判定"两侧不可比"。）

**关键概念**：
- **GROWN**：A/B 都存在的链，B 的 retainedSize > A
- **NEW**：B 中新出现的链（A 中不存在）
- **NEW 链最高优先级**

### 步骤 2：解析源码行号

**硬门控（hard gate）**：对比（步骤 1）跑完、拿到 `--json` 差异后，固定停下来向开发者索要 sourceMap。

> ### ⚠️ 停点完成条件 = sourceMap 文件到手，不是"开发者表达了提供意图"
> - **停点满足** = sourceMap 文件**实际到手**（给了可读路径且已确认存在，或把文件内容拖进来）。
> - **停点未满足** = 开发者只说"我提供/稍等"，或在选择里选了"我提供 sourceMap"——**这只是意图，不是交付。意图 ≠ 文件到手。**
> - **文件没到手，整个步骤 2 暂停**：不跑 `resolve-lines.py`、不读源码做行号定位、不 grep 调用点、不下依据性结论。本轮以一句具体索要收尾并结束，等下一轮文件带回来。
> - **用纯文本索要 sourceMap，不要用 AskUserQuestion**——它接不住文件拖入，选"我提供" ≠ 把文件给你了。比对条件类问题（场景/窗口模式是否一致）可走 AskUserQuestion，但别和文件索取混在同一选择里。

❌ **不得**：(a) 自行从工程 `build/` 翻 sourceMap 顶替或手工算行号；(b) 见"当前源码对得上"就跳过索要直接 grep——**源码与快照可能漂移，"对得上"是最危险的跳过借口**（反面教训 A：曾见快照引用 `Index.ets` 的 line 57/69，而当前 `Index.ets` 早被改写成 Hello World 仅 28 行，当前源码 grep 根本无法定位）；(c) 把"开发者说会提供"当停点已过（反面教训 B：在 AskUserQuestion 选了"我提供"就径直读源码、grep 调用点、下死代码结论——文件没到手停点没过）。**判断"停点过没过"只看一件事：文件在不在我手里。**

```bash
python scripts/3_arkts_heap/resolve-lines.py <compare.json> <sourceMaps.map> [--out PATH]
```

- 将 `.ts` 编译行号解析为 `.ets` 源码行号
- 输出 `<stem>.resolved.json`，保留原始 `chain_ts`
- 如果开发者确认 sourceMap 不可用，回退到 grep `.ts` 行号（标记为近似）

### 定位可疑对象到源码（两步法）

**第一步：看引用链上有没有应用行号**——`compare_diff.py` 文本表/HTML/resolved JSON 已为每条 Δ 渲染完整链（root→…→对象），链本身就是 Path to GC Root。链上有应用行号（解析后形如 `Func [xxx.ets:行号]`）→ 直接打开该 `entry/src/main/ets/.../*.ets` 第 N 行；没有应用行号（全是 VM 内部/匿名对象，或行号只指框架代码）→ 进第二步。

**第二步：用 `queryNode.js` 查对象属性及属性值，再 grep 全搜**——链上认不出对象是谁时，先用 `queryNode.js`（`scripts/3_arkts_heap/queryNode.js`，给定 heapsnapshot + nodeId，打印该对象基本信息 + 全部属性引用/出边 edge）查出属性及属性值，再拿属性/属性值全工程 grep 定位：

```bash
node scripts/3_arkts_heap/queryNode.js <B.heapsnapshot> <nodeId>   # 打印该对象基本信息 + 全部属性引用（出边 edge）
```

拿到属性及属性值后，按值类型搜：
- 先认类：声明对象（class 定义）看 `constructor`；实例化对象（new 出来的）展开 `__proto__` 找 `constructor`；有继承继续展开 `__proto__`。
- 再按属性值类型搜：原始量（字符串/数字/布尔）→ 拿属性名或属性值全工程 grep（URL/资源 ID/key/固定文案通常一搜即中）；函数/方法 → 用其 `#Func(line:N)` 行号定位；对象/数组引用 → 看其 class/constructor 名定位到定义源码，再反查谁创建/持有。

```bash
grep -rn --include="*.ets" --include="*.ts" -F "属性名或属性值" entry/src
```

> 对象类型/各属性（`constructor`/`__proto__`/`HomeObject`/`LexicalEnv`…）完整含义见 `references/snapshot-object-guide.md`。

### Top3 劣化模块（链级 Δ 模块聚合，自动化）

**背景**：一个模块会出现**多条**差分链上，仅按单条链看 Δ 可能只有 KB 级、与总劣化（百 MB 级）无可比性；**模块劣化 = 该模块相关全部差分链 Δ 之和**，与总劣化 Δ 同口径、可直接对比。运行 `resolve_chain_props.js` 自动完成聚合，取劣化 Top3 模块并列出全部相关链明细：

```bash
#快速模式（仅链级模块聚合，不加载 heapsnapshot，秒级）
node scripts/3_arkts_heap/resolve_chain_props.js <compare.json> --no-heap [--out <chain-props.json>]
#双快照模式（加载 A/B heapsnapshot，额外为 Top3 模块做叶子对象定位）
node scripts/3_arkts_heap/resolve_chain_props.js <compare.json> <A.heapsnapshot> <B.heapsnapshot> [--out <chain-props.json>]
```

脚本逻辑：
1. 读 compare.json 全量差分链，**跳过 SyntheticRoot 伪链**（id = 0 虚拟 GC Root 的全堆求和伪差，非真实引用链）
2. 对每条链提取**主模块**：从 leaf→root 方向找到首个业务节点；无业务节点的链归入 `(VM 内部/系统)` 兜底分组
3. 按主模块聚合：**模块劣化 Δ = 该模块全部相关链 Δ 之和**，count 求和，收集链明细（每条链的 Δ/count/tag/原文）
4. 按聚合 Δ 降序取 **Top3 业务模块**；`(VM 内部/系统)` 是无业务节点的兜底分组（VM 形状元数据/系统框架），**单列参考行不占 Top3 名额**，随开发对象回落
5. 输出 `<compare_stem>.chain-props.json`: `top3`（每模块含 module/module_delta_kb/module_count/chain_count/chains 明细/代表链锚点定位）+ `vm_internal` 参考分组 + 总量（total_chain_delta_kb/total_chains/skipped_synthetic）
6. 双快照模式额外为 Top3 模块 Δ 最大链的叶子业务节点做 `#Fun(line:N)` 定位 (function_name/line_number/app_code_path);行号为 `.ts` 编译行号，需 sourceMap 还原到 `.ets` （同 `resolve-lines.py` 口径）

> NameDictionary 条目的 target node 名形如 `com.xingin.xhs_hos/@xhs/xxx@1.0.0/.../Xxx.ts#FuncName(line:N)[module.hap]`，直接编码了文件路径 + 函数名 + 行号。行号为 `.ts` 编译行号，需 sourceMap 还原到 `.ets`（同 `resolve-lines.py` 口径）。

> 输出 Top3 表格（模块 / 模块劣化 Δ / 相关链数 / count / 代表链锚点 / 代表链 Δ / 责任侧）+ VM 参考行，插入对比报告 6.1 小节，格式见 `comparison-report-guide.md`「Top3 劣化模块」。

**定位到源码后：检索上下调用链分析根因（硬性要求）**——无论经第一步（链上行号）还是第二步（grep 属性）定位到源码，最短引用链只回答"谁持有它导致没被回收"，**不回答"为什么会有它 / 为什么变大"**。❌ **不要直接从最短引用链上节点的字面含义推测根因**。✅ 必须在工程源码里检索该位置的**上下调用链**，还原对象的创建与持有路径后再下根因结论：
- **上游（谁调用它）**：grep 该方法/字段的调用点（命令见下方「判断劣化是否合理」），沿调用者逐级向上，找到对象在哪个业务入口被创建 / 注册 / 持有；
- **下游（它调用了谁）**：读该位置函数体，看它创建 / 持有了哪些对象、挂到哪个生命周期上；
- 综合上下调用链得出根因（如"XX 流程每次进入注册回调、离开未解绑导致累积"），而非停在"被 XX 持有"这类链面描述。

### 判断劣化是否合理

对新增/增长的开发者对象，grep 调用点：

```bash
grep -rn --include="*.ets" --include="*.ts" -E "\.(新方法名)\b" entry/src
```

- **有调用点** = 有依据的功能成本（保留，报告标"预期增长"）
- **零调用点** = 无依据死代码劣化（删源码抹平增量：死方法/死字段/模块级未用 `let`/实例）
- **框架基础设施增量**（`GlobalEnv`/`PropertyBox`/`HiddenClass` 登记）= 跟着开发者对象走，删开发者对象即回落，不必单独处理

> 真实案例：B 给 `Product` 加 5 方法 → +4.84 KB（13 条，类定义扩张 + VM 形状登记）→ 判劣化 → grep 发现 5 方法零调用 → 删 5 方法 + 死 import 抹平增量。
> ⚠️ `[entry]` 类/方法**定义**被模块符号表保留是正常存量；但**版本增量**出现在这（新类/新方法）仍要核查死代码——别见"挂在模块下"就判正常放过。

### 减少 retainedSize 的优化方向（引用链拆解规则）

当前最短引用链对比的是两个版本的 **retainedSize 差异**，优化目标即减少劣化链的 retainedSize。减少 retainedSize 须通过**减少引用链上任一对象对其下一对象的持有关系**来实现——断开链上某个对象到后继对象的引用边（edge），即可削弱该路径对后继子树的锚定。具体：

- **链上任意中间对象**：减少它对下一对象的持有关系（断开该 edge），其后继子树不再被该路径锚定，retainedSize 随之回落。
- **最后一个对象**：可减少它对任一下一对象（任一出边）的持有关系，直接释放其引用的子对象。
- **仅需断开链上任一边即可生效，不必整链清除**；优先断开开发者可控对象（带 `[entry]` / 应用源码行号）的出边，框架/VM 内部对象不可控则不单独处理。

## 责任方分类

| GC Root 模式 | 责任方 | 说明 |
|---|---|---|
| `ROOT_VM` / `ROOT_FRAME` | ArkTS | ArkTS 虚拟机/帧栈持有 |
| `ROOT_GLOBAL_HANDLE` / `ROOT_LOCAL_HANDLE` | Native | Native 侧持有 |
| 其他 | Unknown/待确认 | 需进一步分析 |

## 独立分析报告输出

本步骤产出的分析报告，与 step 2 的 topdown/汇总表无关：

| 输出 | 来源脚本 | 说明 |
|------|---------|------|
| `*.compare.html` | `compare_diff.py --html` | 自包含 HTML 报告，按责任侧分组的 retained 增量对比，节点药丸流可视化 |
| `*.compare.json` | `compare_diff.py --json` | 结构化 JSON，含 GROWN/NEW 链、delta_kb、**count（对象数）**、责任侧分类 |
| `*.chain-props.json` | `resolve_chain_props.js` | Top3 劣化模块（链级 Δ 模块聚合： 模块劣化 = 该模块全部相关链 Δ 之和，含相关链明细 + 锚点定位），见「Top3 劣化模块」节 |
| `*.resolved.json` | `resolve-lines.py` | .ts→.ets 源码行号解析结果 |
| 文本表格 | `compare_diff.py` stdout | 按 ArkTS/Native/待确认分组，显示 GROWN/NEW 链、delta、**count** |

**报告解读**：
- **NEW 链最高优先级**：B 版本新增的引用链，通常是泄漏根因
- **GROWN 链**：A/B 都存在但 B 的 retained 更大，可能是对象膨胀或重复创建
- **责任侧判定**：ArkTS 侧（VM/帧栈持有）vs Native 侧（napi/句柄持有），决定修复方向

## 报告内容格式

> ### ⚠️ 结论分两类，泾渭分明
> 能定位到应用具体代码文件的增量 → **一律给代码级结论**（精确到 `entry/src/main/ets/.../*.ets:行号/方法`，写清有/无依据和具体怎么改），不许泛泛而谈。只有无法落到代码文件的（系统框架/VM 内部/源码漂移未解析）→ 才给模糊结论，标注"无法定位、属框架/系统、不用追"。**精度到哪说到哪，不许向下取整成模糊结论。**


> ### ⚠️ 编号模板是必填格式，覆盖所有归因项（不止"劣化项"）
> **凡是给出"一个对象/模块的归因结论"——无论它来自 A→B 增量、还是单快照大头（见上文「单快照构成」）——一律按下述编号模板逐条列出（1. 2. 3. …，逐条编号、不省略）。禁止用叙事表格 / 散文段落替代编号模板。** 漏编号、或把单快照大头分析写成表格/散文，都算"没按模板输出"。（真实教训：A 堆大头根因用叙事表格输出，被用户打回要求按模板重出。）

逐条对每个劣化项（top 10）按以下**编号格式**列出（1. 2. 3. 4. …，逐条编号、不省略）：

```
1. <a id="arkts-1"></a><归因so或模块>（ Δ=xxxKB xxx%，count=xxx，GROWN/NEW ） --- 归因so/模块，增量大小+对象数+链类型

   引用链：root -> ... -> leaf[module.hap]

   劣化模块明细（由 resolve_chain_props.js 产出， 覆盖该模块全部相关链）：
   | # | 模块 | 模块劣化 Δ | 相关链数 | count | 代表链锚点 | 代表链 Δ | 责任侧 |
   |---|---|---|---|---|---|---|---|
   | 1 | @ohos/lottie | xxx.xx KB | xx | xxx | xxx.ts#xxx(line:xx) → xxx.js#xxx(line:xx) | xxx.xx KB | xxx |
   | 2 | ... | ... | ... | ... | ... | ... | ... |
   | 3 | ... | ... | ... | ... | ... | ... | ... |

   根因推断：<根因类型>，工程源码位置精确到 entry/src/main/ets/.../*.ets:行号；无法定位写"无法定位（框架/VM 内部）"。

2. <a id="arkts-2"></a><归因so或模块>（ Δ=xxxKB xxx%，count=xxx，GROWN/NEW ） --- 归因so/模块，增量大小+对象数+链类型
   …（引用链 / [劣化模块明细] / 根因推断 同上）

3. …（top 10 逐条编号，不省略，每条行首加对应 <a id="arkts-N"></a>）
```

字段说明：
1. **归因行**：按责任侧归因到的 so/模块名 + 该模块下增量合计大小与占比 + **count（聚合对象实例数）** + **链类型（GROWN/NEW）**。例：`/system/lib64/module/libworker.z.so（ Δ=12.5MB 23.4%，count=328，NEW ） --- 归因so，增量大小+对象数+链类型` 或 `[entry] com.example.app（ Δ=8.2MB 15.3%，count=56，GROWN ） --- 开发者模块，增量大小+对象数+链类型`。**count 和 GROWN/NEW 不得省略**——count 表示该引用链模式下聚合的对象实例数（`--aggregate` 聚类后同一最短路径的多个对象合并为一条链，count 为合并的对象数），GROWN 表示 A/B 都存在的链（retained 增长），NEW 表示 B 版本新出现的链。
2. **引用链**：从 compare 输出取该对象完整最短引用链（root → leaf），经 `resolve-lines.py` 还原 `.ets` 行号后贴出。**链上仅应用自身模块节点名末尾带 `[so]` 角标**（由 `compare_diff.py` 的 `annotate_node_so` 添加），标明该节点所属 HAP——如 `com.example.app/entry@1.0.0/.../MainPage.ts#anonymous(line:1060)[entry.hap]`；系统 SO（VM 内部/系统框架/GC Root）节点不加角标，保持链文本简洁。**⚠️ 链上节点括号只写 `（Δ=xxxKB，GROWN/NEW）`，不得写节点级 count**——count 仅在归因行（条目首行）出现（多条差分链聚合的对象实例总数）。两级 count 口径不同（归因行=聚合对象数，链节点=该节点堆内实例数，SyntheticRoot 等单例根恒为 1）并列显示会造成混淆（真实反馈：用户质问"为什么有两个count显示"）。
3. **根因推断**：<根因类型>填 Worker 线程 / 开发者死代码 / 框架基础设施 / 系统能力句柄 / VM 形状元数据 等；工程源码位置精确到 `entry/src/main/ets/.../*.ets:行号`，无法定位写"无法定位（框架/VM 内部）"。**根因须由检索上下调用链分析得出，不得直接从最短引用链推测**（见「定位可疑对象到源码」节）。
4. **属性拆解（可选，由 `resolve_chain_props.js` 产出）**：按「Top3 劣化模块」节对全量差分链做链级 Δ 模块聚合后，取与该归因项相关（链主模块为该项目）的全部相关链明细表格，含该模块劣化 Δ （= 该模块全部相关链 Δ 之和）、相关链数、count、代表链锚点、代表链 Δ、责任侧；`(VM 内部/系统)` 兜底分组单列参考行不占 Top3。模块级劣化与总劣化 Δ 同口径、可直接对比。行号为 `.ts` 编译行号，需 sourceMap 还原到 `.ets`。无业务模块节点的纯 VM 内部链不产生此项。
**整体报告还需**：
- **劣化归因汇总表格（置于章节最开头，总体优化方向之前）**：列固定为 `业务来源 | 内存增长 | 严重性等级 | 根因摘要`，按 Δ 降序。业务来源列必须是锚点链接 `[libxxx.so](#arkts-N)`，与对应编号条目行首的 `<a id="arkts-N"></a>` 配对，html 渲染后可点击跳转（`report_md_to_html.py` 保留 raw HTML 锚点）。严重性等级按 Δ 绝对量：≥10MB 为 🔴 高，1~10MB 为 🟡 中，<1MB 为 🟢 低。根因摘要填一句话（与该条目根因推断一致）。此表格是概览导航，**不替代下方编号模板**——详细归因仍逐条编号输出。
- **优化方向（总体，置于汇总表格之后，仅一条）**：减少劣化链 retainedSize 须通过减少引用链上任一对象对其下一对象的持有关系（断开 edge）来实现——链上任一边断开即生效，最后一个对象可减少其任一出边；优先断开开发者可控对象（`[entry]` / 应用源码行号）的出边，框架/VM 内部对象不可控则随开发者对象回落。**此为章节级总体建议，不在每条引用链下重复。**
- **劣化判定总览**：A→B 是否有 Δretained > 阈值的版本增量，有即为劣化（严禁用"固定/O(1)/count 不变"否定已存在增量；有就有，没有就明说没有）。
- **模糊结论汇总**：无法落到代码文件的增量（系统框架/VM 内部/源码漂移未解析）单列，标注"无法定位、属框架/系统、不用追"。

## 依赖

- `node` + `@memlab/core` 或 `memlab` + `@memlab/heap-analysis`（shortest-path.mjs / queryNode 需要）
- Python 3 标准库（compare_diff.py / resolve-lines.py）
- sourceMap 文件（开发者提供，resolve-lines.py 需要）

## 解读经验备忘

- **区分"开发者对象"与"框架对象"（避免误报关键）**：
  - **开发者对象**：类型名带 `[entry]`，或形如 `com.example.<bundle>/entry@<ver>/src/main/ets/.../*.ts#<类>` —— 用户代码产生，需关注。
  - **框架基础设施**（占大头但正常）：`GlobalEnv`/`ArkInternalDict`/`PropertyBox`/`stateMgmt.js#ObserveV2`/`AppStorage`/`LocalStorage`/各 `ark*.js#loadComponent` 组件模块全局。
  - **系统能力句柄**（常见误判源）：`*Session`（Video/Photo）/`AVPlayer`/`PixelMap`/`WebController`/`Web*`/`PubKey`/`HcfKey`/`X509*`/`atManager`/`AccountManager`/`ResourceManager`。应用 `import` 里没对应 `@kit.*` 即框架自动注册的句柄，非开发者创建的实例——反查应用源码 import 即可判定。
  - **跳过 VM 内部对象**：`TaggedDict`/`TaggedArray`/`COWArray`/`ArkInternalConstantPool`/`InternalAccessor` 是 ArkTS 代码层不可见的 VM 结构，分析时直接忽略，聚焦 `JSObject`/`JSArray`/`JSFunction`。
- **堆绝大部分是框架基线**：Hello World 级 ArkUI 应用 ArkTS Heap 就有 8MB+，开发者对象常不足 1%。对着"开发者对象"和"版本增量"看，不对着总量惊慌。
- **模块级 `let x = new ...()` 最常见基线膨胀源**：生命周期=整个应用，GC 永远回收不了，直接计入常驻 baseline。新版本新增这类实例/单例会抬高基线 = 劣化。`[entry]` **实例**挂在模块作用域（`SourceTextModule → LexicalEnv`/模块全局）下即这种常驻开销；但 `[entry]` 类/方法**定义**被符号表保留是正常存量，版本增量仍要核查死代码。
- **retained 比 self_size 更能说明问题**：self_size 小但 retained 大的对象往往是"一个引用撑起一大片"的 retained 锚点，版本增量落在此处影响会被放大。
- **常驻原生句柄计入 baseline**：`*Session`/`WebController`/`PixelMap`/`XComponentController` 被模块/单例长期持有会抬高版本基线，新版本增多即劣化。

## 参考

- 快照对象类型/属性参考：`references/snapshot-object-guide.md`
- 泄漏案例和 FAQ：`references/arkts-leak-cases-and-faq.md`
