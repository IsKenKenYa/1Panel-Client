---
name: hmos-jsleak-analysis
description: DFX Skills，分析 HarmonyOS/ArkTS rawheap、heapsnapshot 和 Heap Cluster 报告，识别疑似 JS 内存泄漏；支持 rawheap 转换、单快照聚类、目录批处理、多快照总榜、双版本增长对比、测试版对象差值对比，以及 GlobalHandler对象关联native堆栈。当用户提供 .rawheap、.heapsnapshot、聚类报告、native hook DB，或 rawheap + htrace + js_map 三合一日志，要求运行 heap_cluster、多快照、版本对比或 GlobalHandler对象关联native堆栈，或询问哪些对象未释放、内存为何增长时使用。
metadata:
   author: Huawei Reliability Technology Lab
   version: 1.4.0
---

# JSLeak Analysis

针对 rawheap / heapsnapshot 内存对象数据进行聚类、跨快照比较和泄漏定位。技能既能把 rawheap 转成 heapsnapshot，也能运行 Node 源码版 Heap Cluster 生成 Markdown、HTML、JSON 报告，并在用户明确要求时执行 GlobalHandler对象关联native堆栈；完成数据处理后，再按故障模式库输出根因和修复建议。

---
 
 
### 排序与展示
- 嫌疑对象按 Retained Size **从大到小**
- 引用链只沿强引用寻找；默认最短链经过弱引用时改用下一条最短强引用链，仅弱可达对象不参与排行
- 输出完整详情（引用链 + 根因 + 建议）
- 不得截断，所有嫌疑对象都要出现
 
---

## Step -1 — rawheap 前置转换（仅当输入是 .rawheap 文件时）

如果用户提供的是 `.rawheap` 文件，必须先调用对应系统目录中的 `rawheap_translator`，将 rawheap 转换为 `.heapsnapshot`，再继续执行后续 heapsnapshot 聚类与泄漏分析流程。

如果 `.rawheap` 与 `.htrace`、`js_map*.txt` 同时提供，且用户要求 GlobalHandler对象关联native堆栈，不要单独执行本节命令；直接按 Step 0C 运行三合一入口，由脚本统一完成转换、聚类和关联。

转换工具路径：
- Windows: `scripts/windows/rawheap_translator.exe`
- Linux: `scripts/linux/rawheap_translator`
- MacOS ARM64: `scripts/macos/rawheap_translator_arm64`
- MacOS X64: `scripts/macos/rawheap_translator_x64`

解析命令示例：

```bash
# Windows: 打开 cmd 并进入 rawheap 文件路径，指定在当前路径下生成 heapsnapshot 文件
${SKILL_DIR}/scripts/windows/rawheap_translator.exe memleak-js-com.example.myapplication-7979-7979-20241215191332.rawheap myapplication-7979-7979.heapsnapshot

# Linux: 进入 rawheap 文件路径，指定在当前路径下生成 heapsnapshot 文件
${SKILL_DIR}/scripts/linux/rawheap_translator memory_leak/memleak-js-com.example.myapplication-7979-7979-20241215191332.rawheap myapplication-7979-7979.heapsnapshot

# MacOS: 根据 CPU 架构选择 arm64 或 x64 工具，指定在当前路径下生成 heapsnapshot 文件
${SKILL_DIR}/scripts/macos/rawheap_translator_arm64 memory_leak/memleak-js-com.example.myapplication-7979-7979-20241215191332.rawheap myapplication-7979-7979.heapsnapshot
${SKILL_DIR}/scripts/macos/rawheap_translator_x64 memory_leak/memleak-js-com.example.myapplication-7979-7979-20241215191332.rawheap myapplication-7979-7979.heapsnapshot
```

转换完成后，将生成的 `.heapsnapshot` 作为 Step 0 的输入继续分析。最终报告的 `输入` 字段需要标明原始 `.rawheap` 文件以及转换后的 `.heapsnapshot` 文件。

部分压缩包中的 Ark rawheap 可能使用 `.log` 扩展名。确认文件头为 rawheap 格式后，保留原件并创建 `.rawheap` 硬链接或副本再调用转换器；转换器会严格校验输入扩展名。

## Step -0.5 — Node 环境与依赖检查（运行 Node 源码版前必做）

当后续需要运行 `scripts/node/heap_cluster.js` 或 `scripts/node/heap_node_native_stack.mjs` 时，必须先执行依赖检查；如果依赖不存在，需要先安装依赖，再继续分析。不要跳过这一步，也不要只告诉用户安装命令。

检查规则：
1. 将 `jsleak-analysis` 目录记为 `SKILL_DIR`，`SCRIPT_DIR = $SKILL_DIR/scripts/node`。
2. 检查 Node 版本：优先使用 Codex bundled Node 或系统 `node`，要求 Node 24，最低 Node 22.5。
3. 检查 pnpm：优先使用 Codex bundled pnpm 或系统 `pnpm`；若 pnpm 不可用但 Node 提供 `corepack`，先启用 corepack 后再使用 pnpm。
4. 检查依赖目录：确认 `$SCRIPT_DIR/node_modules/@memlab/heap-analysis` 和 `$SCRIPT_DIR/node_modules/@memlab/core` 均存在。
5. 在 `SCRIPT_DIR` 内验证 `@memlab/core` 能导出可用的 `TraceFinder`；目录缺失或导出校验失败时重新安装锁定依赖。
6. 依赖安装必须在 `SCRIPT_DIR` 内完成，不要全局安装，不要提交 `node_modules/`。

推荐检查与安装命令：

```powershell
& $NODE --version
& $PNPM --version

$HEAP_ANALYSIS = "$SCRIPT_DIR/node_modules/@memlab/heap-analysis"
$MEMLAB_CORE = "$SCRIPT_DIR/node_modules/@memlab/core"
$DEPENDENCY_READY = (Test-Path $HEAP_ANALYSIS) -and (Test-Path $MEMLAB_CORE)

if ($DEPENDENCY_READY) {
  Push-Location $SCRIPT_DIR
  $TRACE_FINDER_CHECK = (
    "const m=await import('@memlab/core');" +
    "const d=m.default;" +
    "const t=m.TraceFinder??d?.TraceFinder??d?.default?.TraceFinder;" +
    "if(typeof t!=='function')process.exit(1);"
  )
  & $NODE --input-type=module -e $TRACE_FINDER_CHECK
  $DEPENDENCY_READY = $LASTEXITCODE -eq 0
  Pop-Location
}

if (-not $DEPENDENCY_READY) {
  & $PNPM --dir "$SCRIPT_DIR" install --frozen-lockfile --ignore-scripts
}
```

如果 `$PNPM` 不存在，可尝试：

```powershell
corepack enable
corepack pnpm --dir "$SCRIPT_DIR" install --frozen-lockfile --ignore-scripts
```

## Step 0 — heapsnapshot 预处理（仅当输入是 .heapsnapshot 文件时）

优先使用 Node 源码版：`scripts/node/heap_cluster.js`。它支持单快照、目录批处理、多快照总榜、普通/测试版双版本对比和 HTML 报告。需要执行 GlobalHandler对象关联native堆栈时使用 `scripts/node/heap_node_native_stack.mjs`。

执行前必须先完成 Step -0.5 的 Node 环境与依赖检查，然后读取 `references/heap-cluster-workflows.md`，根据用户输入选择唯一必要模式：

```powershell
& $NODE "$SKILL_DIR/scripts/node/heap_cluster.js" --top 5 "<input.heapsnapshot>" "<output_dir>"
```

单快照默认输出业务对象 Top5 和公共对象 Top5。用户指定 TopN 时，将 `--top 5` 调整为对应正整数；Markdown、HTML 和 JSON 使用相同数量。

常用高级入口：

```powershell
& $NODE "$SKILL_DIR/scripts/node/heap_cluster.js" --multi "<snapshot_dir>" "<output_dir>"
& $NODE "$SKILL_DIR/scripts/node/heap_cluster.js" --compare "<baseline_dir>" "<current_dir>" "<output_dir>"
& $NODE "$SKILL_DIR/scripts/node/heap_cluster.js" --compare-experimental "<baseline_dir>" "<current_dir>" "<output_dir>"
```

Heap Cluster 分析统一使用 Node 源码版。不要在版本对比后自动执行 GlobalHandler对象关联native堆栈，只有用户明确要求且存在 native hook DB，或提供 rawheap + htrace + js_map 三合一日志时才运行。

### Step 0A — 多快照分析（用户提供一个快照目录且要求聚合分析时）

当用户提供一个目录，且表达“多快照分析 / 多份快照聚合 / 总榜 / 出现次数 / 平均排名 / 累计大小 / 哪些对象持续增长或反复出现”等诉求时，选择多快照分析。执行前必须完成 Step -0.5，并读取 `references/heap-cluster-workflows.md` 的“多快照总榜”章节。

执行命令：

```powershell
& $NODE "$SKILL_DIR/scripts/node/heap_cluster.js" --multi --multi-top 20 "<snapshot_dir>" "<output_dir>"
```

如果用户指定 TopN，则同步调整 `--multi-top`；否则默认 20。命令完成后必须确认以下产物存在且非空：
- `multi-snapshot-clusters.md`
- `multi-snapshot-clusters.html`
- `multi-snapshot-clusters.json`

多快照分析报告必须基于生成的 `multi-snapshot-clusters.md` 或 `multi-snapshot-clusters.json` 继续分析，不要只返回文件路径。重点输出：
- 跨快照持续出现的业务对象和公共对象 TopN
- 累计 Retained Size、出现次数、平均排名或代表快照
- 代表引用链及 GC Root / distance=1 根节点特征
- 最严重泄漏对象的一级、二级、三级根因
- 多快照视角下的优先排查顺序：优先级按累计大小、出现次数、单次峰值和业务对象权重综合判断

### Step 0B — 不同版本快照分析（用户提供基线版本和新版本两个目录时）

当用户提供两个版本目录，或明确表达“旧版本 vs 新版本 / baseline vs current / 版本对比 / 新增对象 / 增长对象 / 回归分析 / 哪个版本泄漏更严重”等诉求时，选择不同版本快照分析。执行前必须完成 Step -0.5，并读取 `references/heap-cluster-workflows.md` 的“双版本增长对比”章节。

默认执行普通版本对比：

```powershell
& $NODE "$SKILL_DIR/scripts/node/heap_cluster.js" --compare --compare-top 20 --multi-top 20 "<baseline_dir>" "<current_dir>" "<output_dir>"
```

当用户明确要求“测试版 / 对象 retained size 差值优先 / 先按对象大小增长筛选”时，执行测试版对比：

```powershell
& $NODE "$SKILL_DIR/scripts/node/heap_cluster.js" --compare-experimental --compare-top 20 --multi-top 20 "<baseline_dir>" "<current_dir>" "<output_dir>"
```

如果用户指定 TopN，则同步调整 `--compare-top` 和必要的 `--multi-top`；否则默认 20。普通版本对比完成后必须确认以下产物存在且非空：
- `version-comparison.md`
- `version-comparison.html`
- `version-comparison.json`
- 基线版本和新版本各自的多快照报告目录

测试版对比完成后必须确认以下产物存在且非空：
- `experimental-version-comparison.md`
- `experimental-version-comparison.json`
- 基线版本和新版本各自的多快照报告目录

不同版本快照分析报告必须基于生成的对比 Markdown 或 JSON 继续分析，不要只返回文件路径。重点输出：
- 新版本新增对象 TopN、增长对象 TopN，并区分业务对象和公共对象
- 增长量、增长比例、出现快照数、新版本峰值和代表引用链
- 相似引用链组及其共同持有路径
- 判断是“新增泄漏”“已有泄漏加重”“公共运行时增长”还是“证据不足”
- 最严重增长对象的一级、二级、三级根因
- 回归排查建议：优先排查新增且增长大的业务对象，其次排查增长对象，再看公共对象和相似链组

### Step 0C — GlobalHandler对象关联native堆栈（仅用户明确要求时）

当用户明确要求 GlobalHandler对象关联native堆栈，并提供下列任一输入组合时执行：

- 三合一日志目录：一份 `.rawheap`、一份 `.htrace` 和一份 `js_map*.txt`。
- 续跑输入：`.heapsnapshot` 或 `<snapshot>.clusters.json`、Native Hook DB 和 `js_map*.txt`。
- 旧版输入：`.heapsnapshot` 和 `*_native_hook.db`，地址映射来自快照内的 `objectIdMap`。

先完成 Step -0.5。三合一目录使用一条命令自动完成 htrace 转 DB、rawheap 转 heapsnapshot、单快照聚类、Node ID 到 Native 地址映射和调用栈关联：

```powershell
& $NODE "$SKILL_DIR/scripts/node/heap_node_native_stack.mjs" `
  --case-dir "<three-in-one-dir>" `
  --out-dir "<output-dir>"
```

脚本必须复用与 `$SKILL_DIR` 同级的 `nativeleak-analysis/scripts` 下当前系统对应的 `trace_streamer`，不要复制二进制。目录中出现多个同类型输入时，不要猜测文件，应使用 `--rawheap`、`--htrace`、`--js-map` 等参数明确指定。

旧版输入或转换后的续跑命令：

```powershell
& $NODE "$SKILL_DIR/scripts/node/heap_node_native_stack.mjs" `
  --snapshot "<snapshot.heapsnapshot>" `
  --native-hook-db "<native-hook.db>" `
  --js-map "<js_map.txt>" `
  --cluster-json "<snapshot.clusters.json>" `
  --out-dir "<output-dir>"
```

确认生成 `<snapshot>.cluster-native-stacks.md` 和 `<snapshot>.cluster-native-stacks.json`：

- 地址级关联可用时，报告每个 GlobalHandler 对象命中的 Native Top 3 栈。
- 只有 `native_hook_statistic` 时，报告必须保留聚类对象及其完整引用链，标记为“GlobalHandle 聚合回退”，并单独展示 `RES_ARK_GLOBAL_HANDLE` 聚合 Top 栈，不得归因到具体 JS 对象。
- rawheap 转换失败时，确认已生成的 DB 被保留，并使用脚本输出的 `--snapshot` 或 `--cluster-json` 命令续跑。

`native_hook_statistic` 包含 `addr_id` 时，精确关联必须按以下顺序执行：

1. 使用聚类结果的 distance=0 Node ID 在 `js_map*.txt` 中查找十六进制地址，将前导零地址统一为 `0x...`。
2. 使用地址匹配 `data_dict.data`，取得对应的 `data_dict.id` 作为 `addr_id`。
3. 使用 `native_hook_statistic.addr_id` 查找 `callchain_id`。
4. 使用 `native_hook_frame.callchain_id` 查找 `symbol_id`，再使用 `data_dict.id = symbol_id` 取得调用栈符号。

如果 `native_hook_statistic` 不包含 `addr_id`，但包含申请、释放数量与大小等聚合字段，则只能输出 GlobalHandle 聚合 Native 栈，不得关联到具体对象。

## Step 1 — 数据校验

确认聚类数据包含以下关键字段（缺失任一项要先告知用户）：
- 对象名称 / 类型
- 引用链（对象的路径 -> GC Root）
- Retained Size
- 数量 / Distance（可选但重要）

多快照和版本对比还必须校验：
- 快照数量、成功/失败快照列表
- 多快照累计大小、出现次数、平均排名或代表快照
- 版本对比中的新增/增长状态、增长量、基线版本大小、新版本大小
- 对比报告中的代表引用链或相似引用链组

## Step 2 — 规则

弱引用路径处理：聚类前重新计算到 GC Root 的最短强引用链。默认最短链经过
`WeakMap`、`WeakSet`、`WeakRef`、`FinalizationRegistry`、`WeakRefPool`、
`JSWeakmap`、`js_weak_map`、`js_weak_ref`、`weak_linked_hash_map` 或
`edge.type=weak` 时，继续寻找其他最短强引用链。找到替代链后正常展示对象；
仅弱引用可达的对象不进入候选。弱引用容器自身存在强引用时可以展示，但不能
作为保活下游对象的引用链节点。

关注 Detached DOM: 如果对象名称或种类包含 "Detached"，且 Retained Size 较大，且被 JS 引用（非 WeakMap），极大概率是泄漏。
关注全局引用: 检查引用链的根节点（GC Root）。如果引用链起始于 window, Global, 或意外的长生命周期缓存（Cache, Map），且对象本应是短生命周期的，标记为泄漏。
关注闭包 (Closures): 如果引用链中包含 context 或 system / Context，且持有了大量不该存在的对象，可能是闭包泄漏。

## Step 3 — 故障模式分类（必做）
 
**每一个被识别为泄漏嫌疑的对象都必须从故障模式库中匹配一个编号**。这一步是强制的，不能跳过。
 
读取参考文件:
- `references/fault-modes.md`
- `references/ArkTS_OOM_故障模式库.md`
 
匹配方法（按 distance=1 节点名识别根节点类型）：
 
| distance=1 节点名特征 | 故障模式 | 责任侧 |
|----------------------|---------|--------|
| `SourceTextModule` / `Source_Text_Module_Record` / `global_env` / `GlobalEnv` | **** ROOT_VM | ArkTS |
| 含 `Frame` / `StackFrame` 字样 | **** ROOT_FRAME | ArkTS |
| 含 `LocalHandle` 字样 | **** ROOT_LOCAL_HANDLE | Native |
| 含 `GlobalHandle` / `Reference` / `napi_ref` 字样 | **** ROOT_GLOBAL_HANDLE | Native |
| 以上都不匹配 | **Unknown** | 待确认 |
 
匹配规则：
1. 优先看引用链最右侧 (GC Root 端) 的 distance=1 节点
2. 若 distance=1 节点信息不足，沿引用链向 root 方向查找特征节点
3. 仍无法匹配则标 FM-Unknown，并在根因分析中说明原因（通常是当前快照尚不支持 ROOT 标签）
4. 在最终报告中**每个嫌疑对象都必须输出 `故障模式`字段**

### Root 类型定义（生成根因/建议时必须正确引用）
**VM_Root**
指该root对象为虚拟机内部创建，无法删除，建议断开引用关系解决内存泄漏 
**LocalHandleRoot** 
指该对象在napi侧被napi_value持有，由napi_open_scope和napi_close_scope管理
**GlobalHandleRoot**
指该对象在napi侧被napi_create_reference创建的napi_ref持有

---
 
## Step 4 — 输出结构化报告
**注意** 
```
========================================
  内存泄漏分析报告
========================================

输入: <数据来源描述，如"xxx.heapsnapshot (经 heap_cluster.mjs 聚类)">
扫描对象数: <N>
嫌疑对象数: <M>
分析模式: <单快照 / 多快照 / 不同版本对比 / 测试版不同版本对比>
生成产物: <Markdown / HTML / JSON 路径；如无脚本产物则写“直接分析用户提供报告”>
**注意** 
LocalHandleRoot，GlobalHandleRoot是虚拟节点，仅作标识符，不作为GC ROOT
----------------------------------------
🔴 泄漏嫌疑 - 业务对象
----------------------------------------

[#Top1] <对象名称><给出完整对象名称不要省略行号>
     对象分类: 业务对象
     大小:   <Retained Size>
     数量:   <count>
	 故障模式:    (名称)
     
     引用链<给出完整对象名称不要省略行号>:
       ⬤ <leaf 完整名>
         ├▶ <中间节点 1 完整名>
         ├▶ <中间节点 2 完整名>
         └▶ <root 完整名>

	
     根因分析:
       <解释为什么这是泄漏，引用链中的可疑节点是哪个>
	   1. 对象本质:
          <这个对象是什么？业务用途？属于哪个模块？属于哪个文件哪一行？>
       2. 持有路径分析:
          <逐跳分析引用链：每一层是谁、扮演什么角色、是否是关键持有者>
          <找出"决定性的那一跳" — 即如果断开这一跳，对象就可被回收>
     修复建议:
       <1-3 条具体建议>

[#Top2] <对象名称>
     对象分类: 业务对象
     大小:   <Retained Size>
     数量:   <count>
	 故障模式:    (名称)
	 
     引用链<给出完整对象名称不要省略行号>:
       ⬤ <leaf 完整名>
         ├▶ <中间节点 1 完整名>
         ├▶ <中间节点 2 完整名>
         └▶ <root 完整名>

	
     根因分析:
       <解释为什么这是泄漏，引用链中的可疑节点是哪个>
	   1. 对象本质:
          <这个对象是什么？业务用途？属于哪个模块？属于哪个文件哪一行？>
       2. 持有路径分析:
          <逐跳分析引用链：每一层是谁、扮演什么角色、是否是关键持有者>
          <找出"决定性的那一跳" — 即如果断开这一跳，对象就可被回收>
     修复建议:
       <1-3 条具体建议>

----------------------------------------
🔴 泄漏嫌疑 - 公共对象
----------------------------------------

[#Top1] <对象名称><给出完整对象名称不要省略行号>
     对象分类: 公共对象
     大小:   <Retained Size>
     数量:   <count>
	 故障模式:    (名称)
     
     引用链<给出完整对象名称不要省略行号>:
       ⬤ <leaf 完整名>
         ├▶ <中间节点 1 完整名>
         ├▶ <中间节点 2 完整名>
         └▶ <root 完整名>

	
     根因分析:
       <解释为什么这是泄漏，引用链中的可疑节点是哪个>
	   1. 对象本质:
          <这个对象是什么？公共容器/系统对象/框架对象的类型？它持有了哪些业务对象？>
       2. 持有路径分析:
          <逐跳分析引用链：每一层是谁、扮演什么角色、是否是关键持有者>
          <找出"决定性的那一跳" — 即如果断开这一跳，对象就可被回收>
     修复建议:
       <1-3 条具体建议>

[#Top2] <对象名称>
     对象分类: 公共对象
     大小:   <Retained Size>
     数量:   <count>
	 故障模式:    (名称)
	 
     引用链<给出完整对象名称不要省略行号>:
       ⬤ <leaf 完整名>
         ├▶ <中间节点 1 完整名>
         ├▶ <中间节点 2 完整名>
         └▶ <root 完整名>

	
     根因分析:
       <解释为什么这是泄漏，引用链中的可疑节点是哪个>
	   1. 对象本质:
          <这个对象是什么？公共容器/系统对象/框架对象的类型？它持有了哪些业务对象？>
       2. 持有路径分析:
          <逐跳分析引用链：每一层是谁、扮演什么角色、是否是关键持有者>
          <找出"决定性的那一跳" — 即如果断开这一跳，对象就可被回收>
     修复建议:
       <1-3 条具体建议>

========================================
  总结
========================================
故障模式分布:
  (ROOT_VM):           N 个,  X.X MB
  (ROOT_FRAME):        N 个,  X.X MB
  (LOCAL_HANDLE):      N 个,  X.X MB
  (GLOBAL_HANDLE):     N 个,  X.X MB
   Unknown:                N 个,  X.X MB

主要泄漏来源:
  1. <一句话描述最严重的泄漏模式>
  2. <第二严重>
  ...

多快照/版本对比结论:
  模式: <多快照 / 不同版本对比 / 不适用>
  多快照重点: <持续出现对象、累计大小、出现次数、代表引用链；不适用则写“不适用”>
  版本增长重点: <新增对象、增长对象、增长量、相似链组；不适用则写“不适用”>

GlobalHandler对象关联native堆栈:
  状态: <已执行 / 未触发>
  关联模式: <地址级精确关联 / GlobalHandle 聚合回退 / 不适用>
  关联结果: <精确模式写对象及 Native Top 3；聚合模式写 RES_ARK_GLOBAL_HANDLE 整体 Top 栈并声明不能归因到具体对象；未触发写“不适用”>

最严重泄漏根因:
  依据: <按 Retained Size 最大的泄漏嫌疑对象确定>
  一级根因: <从 ArkTS_OOM_故障模式库.md 中匹配，如 ArkTS OOM>
  二级根因: <根据最严重对象的 distance=1 根节点/持有类型匹配，如 VMRoot 类型根节点持有 / HandleRoot - GlobalHandle 类型根节点持有 / 一次性分配超大对象导致 OOM>
  三级根因: <根据引用链、对象属性名、文件名、调用栈或 Error message 匹配到的具体三级根因；若无法匹配，写“未明确匹配”并说明缺失证据>

建议优先排查:
  • <按优先级列出的修复路径>

```
