# Native Heap 深度分析工作流

**独立分析步骤**：本步骤不依赖 step 2 的 topdown 对比结果，可独立执行并输出自己的分析报告。在完整防劣化流程中，本步骤由 Top10 劣化 SO 中 type_name 不全是 SO_SIZE/HAP/DMA 的 SO 触发（分发规则见 `SKILL.md`「步骤 3/4/5 触发逻辑」），差分结果的解读**聚焦这些被分发 SO** 的调用栈。

**DMA 型 SO 无法生成本步骤火焰图（数据本质限制）**：type_name 全为 DMA/SO_SIZE/HAP 的 SO（典型如 `libhdi.z.so`、`libbuffer_handle.z.so`）不进入本步骤——其内存由 gralloc/dmabuf（DMA）或文件映射（SO_SIZE/HAP）承载，不经 malloc 分配，`native_hook` 表中无其调用栈帧（实测两版 .db 中这两个 SO 的帧引用均为 0）。对这类 SO 运行 `cluster_calltree.py` 会以退出码 1 报"无匹配调用栈"并附诊断说明，**属预期行为而非脚本故障，勿反复重试**；其归因走步骤 5 smaps 对比（含 SO_SIZE/HAP 明细时）或第五章 DMA 对比分析（dma_detail.xlsx）。SurfaceBuffer 相关的用户态元数据分配帧（`SurfaceBufferImpl::Alloc` 等）挂在 `libhdi_base.z.so` / `libdisplay_buffer_*.so` 等库的调用栈上，如需核查 SurfaceBuffer 分配路径，应按**帧名**检索 .db（`data_dict` + `native_hook_frame`）或对这些承载库聚类，而非按 `libbuffer_handle.z.so` 名称聚类。

## 前置条件

开始分析前，逐项检查以下条件：

| # | 条件 | 检查方式 | 不满足时 |
|---|------|---------|---------|
| 1 | 已确认存在 native heap 劣化 | 调用方已确认 | 未确认则**终止**，本 workflow 不负责劣化预检 |
| 2 | 用户提供了两个版本的 db 文件 | 确认用户提供了**劣化前后两个版本**的 `.db` 文件路径，且文件存在 | 缺失版本的数据文件时，要求用户提供，等待补充后继续。无法提供则**终止分析** |
| 3 | 用户提供了归因 SO 名称 | 确认用户指定了需要分析的 SO（如 `libtaskpool.z.so`） | 要求用户提供，本 workflow 不负责 SO 选择 |
| 4 | 劣化后版本的带 debug 符号的 SO 文件 | **执行步骤 3 前必须显式向用户索要**劣化后（B 版）归因 SO 的带 debug 符号版本——单文件路径或所在目录均可，来自当前编译输出或归档 | **未索要前阻塞**，不得静默进入步骤 3（即使用户大概率没有，也要先问）；用户拒绝提供时，跳过 3.1 行号解析，按 3.1「调用链回溯完整性限制」保留未解析帧生成报告。用户可拒绝，拒绝不构成失败 |
| 5 | addr2line 可用 | 按以下优先级查找 `llvm-addr2line`：<br>1. 读取 `~/.config/tools.env` 中的缓存路径，有则直接使用<br>2. 系统 PATH 中查找 `addr2line` 或 `llvm-addr2line`，找到则无需持久化<br>3. 以上未找到 → 询问用户提供 DevEco Studio 安装路径，并在该目录下查找（`<DevEco Studio安装目录>\sdk\{default,版本号}\openharmony\native\llvm\bin\`）<br>若通过本步骤找到，将 **(llvm-)addr2line 路径和 DevEco Studio 安装路径** 写入 `~/.config/tools.env` 持久化 | 无 addr2line 时**终止**步骤 3，但步骤 1-2 仍可运行 |
| 6 | 用户 APP 源码目录 | 询问用户提供 APP 项目源码根目录（本 workflow 分析的是用户 APP 的劣化，非系统 SO） | 无源码目录时仍可完成劣化类型判定，但无法读取源码上下文定位具体代码根因 |


## 分析流程

```
步骤 1：聚类（A/B 两个版本各生成聚类树）
步骤 2：差分 + 定位劣化点
步骤 3：解析源码行号 + 读取源码上下文 + 归因劣化类型与根因
步骤 4：输出劣化报告
```

## 步骤 1：聚类

> **输入**：前置条件 2 的两个 db 文件路径 + 前置条件 3 的 SO 名称  
> **输出**：A/B 版本各一份 `<so_name>_tree.json`（聚类树）

对 A/B 两个版本的 db 分别运行 `cluster_calltree.py`，按用户指定的 SO 生成前缀树聚类树：

```bash
python ${SKILL_DIR}/scripts/4_native_heap/cluster_calltree.py \
    --db <版本.db> --so <so名称>
```

参数：
- `--db`：db 文件路径
- `--so`：用户指定的归因 SO 名称（如 `libtaskpool.z.so`）

输出：db 同目录下 `<so_name>_tree.json`，包含 `string_table` 和 `tree` 两部分。`tree` 中每个节点含 `name`、`value`（字节数）、`value_mb`、`apply_count`、`release_count`；叶子节点标记 `is_leaf: true` 并携带 `callchain_id`。

**聚类原理**：前缀树聚类——共享前缀的调用栈自动合并到同一节点，不同路径自动分叉。相同调用路径的多次 malloc 共享同一 callchain_id，在树中表现为同一个叶子节点，value 是它们存活内存的总和。这样可以把数万条调用栈压缩为一棵层次分明的树，上卷看到模块级热点，下钻看到具体调用链。

对 A、B 版本各执行一次，得到两份聚类树 JSON。

## 步骤 2：差分 + 定位劣化点

> **输入**：步骤 1 的两份聚类树 JSON  
> **输出**：差分聚类树 JSON + 终端 Top N 劣化叶子摘要

### 2.1 差分

对步骤 1 产出的两份聚类树做差分：

```bash
python ${SKILL_DIR}/scripts/4_native_heap/diff_cluster_tree.py \
    --tree-a <A版本_so_tree.json> --tree-b <B版本_so_tree.json> \
    --top 20
```

参数：
- `--tree-a`：A 版本（劣化前）的聚类树 JSON（步骤 1 产出）
- `--tree-b`：B 版本（劣化后）的聚类树 JSON（步骤 1 产出）
- `--top`：终端摘要打印 Top N 劣化叶子（默认 20）

输出：`<so_name>_diff.json`，差分聚类树。结构与输入聚类树一致，每个节点额外增加：

| 字段 | 含义 |
|------|------|
| `a_value_mb` | A 版本该节点存活内存 |
| `b_value_mb` | B 版本该节点存活内存 |
| `delta_mb` | B - A（**核心指标**，正=劣化，负=改善） |
| `match_type` | 匹配类型：`both`（A/B 都有，增量）、`only_b`（仅 B 有，新增路径）、`only_a`（仅 A 有，消失路径） |

children 按 `delta_mb` 降序排列。叶子节点保留 `is_leaf`，并携带以下字段：

| 字段 | 含义 |
|------|------|
| `callchain_id` | B 版本该叶子对应的 callchain_id（用于回溯 db 查询原始 alloc/free 事件详情，不用于差分匹配） |
| `callchain_id_a` | A 版本同名叶子对应的 callchain_id。仅 A 版也有同名叶子时存在；不存在时说明该叶子为 B 版新增路径。（注：叶子匹配基于路径位置，非 callchain_id 数值。callchain_id 跨版本不一致，仅用于 db 回溯。） |

差分逻辑：同时递归遍历两棵树，按 `name` 字段匹配同名节点（name 已做路径归一化，去除 `/proc/<PID>/root` 前缀，确保 app-bundle SO 跨版本可匹配）。A 和 B 都有 → `both`（增量）；B 有 A 没有 → `only_b`（新增路径）；A 有 B 没有 → `only_a`（消失路径）。叶子节点按路径位置匹配，同一非叶子路径下的叶子视为同一调用链，合并 a/b 值。

### 2.2 定位劣化点

**方法：遍历差分树所有叶子，按 delta_mb 降序排序，最大的叶子就是最大劣化点。**

差分脚本终端已输出 Top N 叶子摘要：
```
Top 20 叶子节点:
    delta(MB)  callchain_id
      +15.25  181744
       +7.00  59040
       ...
```

拿到 callchain_id 后，从差分树 JSON 中回溯该叶子到 root 的路径，即为完整调用链。例如 callchain_id=46789 的路径：

```
root
  ld-musl+0xb49f8
    ld-musl+0x1e8ed0
      napi_create_runtime
        CreateRuntimeFunc
          JSNApi::CreateJSVM
            libark_jsruntime.so+0x5b9f74
              ...
                meta:46789 [LEAF]
```

**注意：不能从 root 顺着最大 delta child 往下走来定位劣化点**。非叶子节点的 delta 是子树汇总值，一个节点可能整体改善（delta<0），但内部藏着劣化分支（delta>0），顺着最大 delta 走可能走进没变化的分支。只有叶子节点的 delta 才是单条调用栈的真实劣化量。

**判断增量 vs 新增**：查差分树叶子所在路径的非叶子节点 `a_value_mb`。若非叶子路径节点 `a_value_mb > 0`，说明该路径在 A 版存在，为增量；若 `a_value_mb = 0`，为新增路径。也可直接查 A 版聚类树确认函数是否存在。

**交叉验证（可选）**：如果差分树中所有劣化叶子的 `a_value_mb` 均为 0（即全部显示为新增路径），可能存在匹配失效。此时取 Top 劣化叶子的关键函数名（如 `libnativemem.so+0x2bdc`），直接在 A 版聚类树 JSON 中搜索该函数名是否存在。若存在，说明是增量而非新增，差分匹配可能因路径归一化等问题失效。

## 步骤 3：解析源码行号 + 读取源码上下文 + 归因根因

> **输入**：步骤 2 的差分树 JSON + 前置条件 4 的 SO 目录 + 前置条件 5 的 addr2line + 前置条件 6 的源码目录
> **输出**：根因定位（劣化类型 + 代码根因，仅客观分析）

**⚠️ debug SO 硬门控（进入 3.1 前必执行）**

native heap 分析要落到源码行号，**必须**有带 debug 符号的 SO。执行 3.1 行号解析前，**必须显式向用户索要**劣化后（B 版）归因 SO 的带 debug 符号版本路径（单文件路径或所在目录均可）。规则：

1. **必须先问，不得静默跳过**：未向用户发起索要前**阻塞**，不得进入 3.1——即使用户大概率没有，也要先问。这是与 `SKILL.md` 步骤 3（ArkTS Heap）的 sourceMap 硬门控对称的硬门控。
2. **用户可拒绝**：拒绝是合法路径，不构成失败。拒绝后跳过 3.1/3.2 的行号解析与源码上下文读取，直接按下方 3.1「调用链回溯完整性限制」**保留未解析帧**（`so_name+offset` 形式，标注"待补充 debug 符号"）生成报告。
3. **提供后校验**：用户提供路径后，先用 `readelf -S` / `file` 确认 SO 未被 strip（含 `.debug_info` 段），再用于 addr2line；若实际为 stripped 版本，按用户拒绝处理并告知。
4. **范围说明**：用户通常只能提供**目标 SO** 的 debug 版本（自有构建产物）；调用链中的系统/运行时 SO 帧默认仍无法解析，按「调用链回溯完整性限制」保留，**不得因用户提供了一个 SO 就删除其余未解析帧**。

> 并行执行场景下（见 `SKILL.md`「步骤 3/4/5 并行执行」），步骤 4 agent 先运行 cluster + diff 拿到差分树，**到 3.1 前停下来**，由主 agent 向用户索要 debug SO；用户回应后再续跑行号解析，或按拒绝路径出报告。

### 3.1 解析源码行号

差分树叶子到 root 的路径中，节点名称有两种形态：
- 已解析的函数名（如 `JSNApi::CreateJSVM`）→ 可直接阅读
- 未解析的 SO+偏移（如 `libentry.so+0x5b9f74`）→ 需用 addr2line 还原为源码行号

直接用 Bash 调用 addr2line，无需脚本。从差分树 Top N 劣化叶子回溯 root 路径，提取其中 `so_name+offset` 格式的节点，逐个解析：

```bash
<addr2line路径> -e <SO目录>/<so_name> <offset>
```

示例：
```bash
llvm-addr2line -e /path/to/unstripped/libentry.so 0x5b9f74
# 输出: /home/build/entry/src/main/cpp/napi_manager.cpp:142
```

**获取带 debug 信息的 SO 文件**：
- 设备上的 SO 通常是 stripped 的，addr2line 无法解析源码行号
- 需要从编译产物获取带 debug 信息的 SO（如 OHOS 源码编译输出的 `.unstripped` 文件）
- 如果拿不到 debug SO，就只能看到函数名 + 偏移地址；偏移量须保留（见下方「调用链回溯完整性限制」），可用于后续补充 debug 符号后二次解析

#### ⚠️ 调用链回溯完整性限制（重要，生成报告前必读）

差分树叶子到 root 的回溯路径中，节点来自**多个不同 SO**——既包括用户归因的目标 SO（如 `libentry.so`），也包括系统/运行时 SO（如 `ld-musl`、`libark_jsruntime.so`、`libnapi.so`、`libace_napi.z.so` 等）。用户**可能提供零个、一个或多个** debug SO：常见情况是至多提供目标 SO 的带 debug 符号版本，但也可能**完全不提供任何 debug SO**（前置条件 4 要求显式索要，但用户可拒绝提供）。**任何**其 SO 缺少对应 debug SO 的帧，偏移量都**无法用 addr2line 解析**——这可能包括目标 SO 本身（未提供时）、也可能包括系统/运行时 SO（通常拿不到 debug 版本）。

这是预期行为而非失败，但若处理不当会导致**调用链在报告中被截断、省略**，从而让根因定位失真。生成报告时**必须遵守以下规则**：

1. **不得省略未解析帧**：无法解析的 `so_name+offset` 节点**必须原样保留在报告中**，不得因为"没有源码行号"就跳过或删除。省略后调用链会出现断点，破坏 root→leaf 的父子关系，导致报告读者无法定位真正的分配起点。

2. **混合呈现完整路径**：报告中应展示从 root 到叶子的**完整路径**，已解析帧（`文件:行号` 或函数名）与未解析帧（`so_name+offset`）按原始顺序交错排列。例如：
   ```
   root
     ld-musl+0xb49f8                   ← 未解析（系统 SO，无 debug 符号），保留
       napi_create_runtime              ← 已解析函数名
         libark_jsruntime.so+0x5b9f74   ← 未解析（运行时 SO），保留
           JSNApi::CreateJSVM           ← 已解析函数名
             libentry.so → napi_manager.cpp:142  ← 已解析（目标 SO）
               meta:46789 [LEAF]
   ```

3. **未解析帧仍有归因价值**：即使 `so_name+offset` 无法落到源码行号，它仍携带关键信息——SO 名称指示归属模块，偏移量可用于后续补充 debug 符号后二次解析。报告应将未解析帧标注为"待补充 debug 符号"，而非删除。

4. **前置条件 4 的局限澄清**：前置条件 4 要求"显式索要"且未索要前阻塞，但用户**可拒绝提供**——拒绝或部分提供并非全帧可解析：即便用户提供了**目标 SO** 的 debug 版本，调用链中的系统/运行时 SO 帧仍因拿不到 debug 版本而无法解析。**无论用户最终提供了几个 debug SO**，未覆盖到的 SO 对应帧默认无法解析——这是预期行为，不影响报告完整性判定（前提是按上述规则保留未解析帧）。

**违反上述规则的后果**：若报告省略未解析帧，调用链会出现"跳跃"，读者会误以为分配直接发生在某个已解析的函数内，掩盖真正的分配路径与责任模块，导致根因误判。**这是已知的高频错误模式，必须在每次生成报告时显式检查调用链是否完整。**

### 3.2 读取源码上下文

addr2line 输出的文件名是用户 APP 源码文件（如 `napi_manager.cpp:142`），用该文件名在前置条件 6 的源码目录下搜索定位文件，读取目标行附近的代码上下文（前后各 20 行左右）。

通过源码上下文可以：
- 确认具体的分配/释放调用位置
- 判断是否存在遗漏释放、重复分配、缓存策略变更等问题
- 直接定位根因

### 3.3 归因根因

从差分树定位到 Top N 劣化叶子后，结合 addr2line 解析的源码位置和源码上下文，**客观**判定劣化类型与根因（只输出可由源码/数据证实的结论）。以下为常见劣化类型的根因推断方向参考：

| 劣化类型 | 根因推断方向（须由源码/数据证实，非臆测） |
|---|---|
| 泄露 | 遗漏 `napi_remove_wrap`/`free`/`delete` 等释放调用 |
| 延时释放 | 缓存策略变更、GC 触发条件改变、生命周期管理变更 |
| 分配次数增加 | UI 事件重复绑定、循环内重复创建对象、回调注册未去重 |
| 单次分配变大 | Buffer size 常量变更、数据结构字段增加、预分配策略变更 |

判断依据：
- **泄露**：源码中分配路径存在，但对应释放路径缺失（如 `napi_wrap` 后无 `napi_remove_wrap`）
- **延时释放**：释放路径存在但调用时机延后（如 GC 触发条件变更、缓存淘汰策略放宽）
- **分配次数增加**：同一分配点在 B 版本被更频繁调用（如循环内重复创建、事件重复绑定）
- **单次分配变大**：分配点调用频率不变，但单次分配尺寸增大（如 Buffer 常量值变大）

## 步骤 4：输出劣化报告

> **输入**：步骤 3 的根因判定 + 源码上下文 + 差分树指标
> **输出**：结构化劣化分析报告

报告分为两部分：**总览表格**（所有 SO 概况一览）+ **逐 SO 详细归因**（`<details>` 折叠）。

### 4.1 总览表格

小节开头先输出一个**总览表格**，方便快速浏览所有劣化 SO 的概况：

| 列 | 含义 | 数据来源 |
|---|---|---|
| # | 序号（从 1 开始） | — |
| SO | SO 名（加锚点链接 `[so名](#nh-<so名>)`，点击跳转到详细归因并展开） | 差分树文件名 |
| 劣化前(MB) | A 版本该 SO 存活内存 | 差分树根节点 `a_value_mb` |
| 劣化后(MB) | B 版本该 SO 存活内存 | 差分树根节点 `b_value_mb` |
| Root Delta(MB) | B - A 存活内存增量（**核心指标**） | 差分树根节点 `delta_mb` |
| 劣化叶子数 | `delta_mb > 0` 的叶子节点数量 | 差分树遍历统计 |
| 最大叶子Delta(MB) | 所有劣化叶子中最大的 `delta_mb` | 差分树叶子排序取 Top1 |
| 严重性 | 🔴高/🟡中/🟢低（定义见下方） | — |
| 火焰图 | ✅ 有（已生成）/ — 无 | 检查 `flame_compare/<so>_compare_flame.html` 是否存在 |
| 主要劣化路径简述 | Top1 劣化叶子的 root→leaf 路径中已解析函数名串联，截断到 ~60 字符 | 差分树 Top1 叶子回溯路径 |

**表格排序**：按 Root Delta 从大到小降序排列。

**严重性定级**（基于 Root Delta 绝对量）：
- 🔴 **高**：Root Delta ≥ 10MB
- 🟡 **中**：Root Delta 1–10MB
- 🟢 **低**：Root Delta < 1MB（受劣化项过滤规则约束，< 1MB 的 SO 不展示在表格中）

> **注意**：表格中的严重性是基于 Root Delta 的初始定级；表格下方逐 SO 详细归因按**最终严重性**（经降级规则调整后）从高到低排列。降级规则见 `comparison-report-guide.md`「深度分析结果（第一章）」严重性定级。

模板示例：

```
| # | SO | 劣化前(MB) | 劣化后(MB) | Root Delta(MB) | 劣化叶子数 | 最大叶子Delta(MB) | 严重性 | 火焰图 | 主要劣化路径简述 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | [libEGL.so](#nh-libegl) | 0.09 | 24.19 | +24.10 | 3 | +0.19 | 🔴 高 | ✅ | eglCreateWindowSurface → CreateEglSurface → libhvgr_v200.so |
| 2 | [libentry.so](#nh-libentry) | 6.26 | 8.56 | +2.30 | 5 | +1.28 | 🟡 中 | ✅ | SourceMap::Init → ExtractSourceMapData → operator new |
```

### 4.2 逐 SO 详细归因

表格下方按**严重性从高到低**排列逐个 SO 输出详细归因。每个劣化 SO 用 `<details>` 折叠，归因行放在 `<summary>` 中，锚点 `<a id="nh-<so名>">` 放在 `<summary>` 内：

```
<details>
<summary><a id="nh-<so名>"><归因SO路径>( <delta_mb>MB <delta_pct>%) 【严重性】</a></summary>

完整调用链（root → leaf，按原始顺序，不得省略未解析帧）：
<列出该劣化叶子从 root 到 leaf 的完整路径节点，已解析帧标 `文件:行号`/函数名，未解析帧保留 `so_name+offset` 形式并标注"待补充 debug 符号">

客观分析结论：
劣化源来自于<根因模块描述>，版本间增量 <delta_mb> MB，工程源码位置：<源码文件:行号>
劣化类型：<泄露/延时释放/分配次数增加/单次分配变大>
<结合源码上下文陈述可证实的事实>

> 📊 [查看 <so名> 前后对比火焰图](flame_compare/<so名>_compare_flame.html)

</details>
```

**字段说明**：
- `归因SO路径`：差分树对应的 SO（如 `libentry.so`），来自前置条件 3 用户指定的 SO
- `delta_mb`：B - A 存活内存增量（来自差分树叶子 `delta_mb`）
- `delta_pct`：增量占比百分比（`delta_mb / 差分树根节点 b_value_mb × 100`）
- `源码文件:行号`：步骤 3.1 addr2line 解析结果
- `完整调用链`：**必须包含 root→leaf 全部节点**，未解析的 `so_name+offset` 帧原样保留并标注"待补充 debug 符号"——详见步骤 3.1「调用链回溯完整性限制」。**提交报告前逐一核对调用链是否完整，禁止因缺 debug 符号而省略帧。**
- 客观分析结论（含劣化类型）参考步骤 3.3 的劣化类型表；修复建议不在本报告范围内，如需请向 AI 询问

### 4.3 缺失 debug 符号 SO 清单

报告末尾**必须**输出"缺失 debug 符号 SO 清单"。步骤 3.1 遍历劣化调用链做 addr2line 解析时，agent 天然知道哪些 `so_name+offset` 帧解析成功、哪些因缺少对应 debug SO 而未解析。将未解析帧的 SO 名去重汇总，列出：

| SO 名 | 待解析 offset | 所在劣化叶子 delta_mb |
|---|---|---|

- 系统/运行时 SO（如 `ld-musl`、`libark_jsruntime.so`、`libnapi.so` 等）通常无法获取 debug 版本，属预期不可解析，**不列入此清单**
- 清单为空时输出"所有用户/第三方 SO 均已提供 debug 版本 ✅"

**补充提示**（清单下方必须附上）：
> 提供以上 SO 的带 debug 符号版本后，可解析对应帧到源码行号。**只需重新执行步骤 3（深度分析），无需重新采集 htrace / .db 数据**——步骤 1-2 的聚类树和差分树可直接复用。

## 步骤 5：火焰图生成

> **输入**：步骤 1 的 `*_tree.json`（聚类树，**非** `_diff.json`）
> **脚本**：`scripts/4_native_heap/build_flame_summary.py`（静态资源在 `scripts/4_native_heap/statics/`）
> **输出**：单文件 HTML（d3 资源已 bs4 内联，不依赖 statics/ 目录，可独立打开/分享）

火焰图基于**单版本聚类树**渲染该版本 native heap 分配 profile（不是两版差分 delta）。`convert_node` + `StringTable` 把 tree 压缩成 d3 短键格式注入 `flame.template`/`flame-c.template`，d3-flamegraph 渲染交互式火焰图。

### 5.1 单版本汇总

```bash
python scripts/4_native_heap/build_flame_summary.py <version_dir> --single-file
```

- 扫 `<version_dir>/*_tree.json` → 每个 SO 一个 `<so>_flame.html` + 汇总页 `<version>_flamegraphs.html`（链接引用各 SO 火焰图）。
- `--single-file`：bs4 `bundle()` 把 4 个 d3 资源（`d3.flameGraph.min.css`/`d3.v7.js`/`d3-flamegraph.min.js`/`d3-flamegraph-tooltip.min.js`）内联进 HTML，产物为单文件；不加则用相对路径引用 `statics/`（产物离不开 statics 目录）。

### 5.2 同 SO 前后对比（A/B）

> **⚠️ 必须使用 `--compare` 模式**：防劣化流程中，所有火焰图都必须用 `--compare` 模式生成前后对比。**禁止**使用 5.1 的单版本汇总模式（不带 `--compare`）来生成对比火焰图——单版本汇总产出的是汇总页（链接引用子 `<so>_flame.html`），在 `output/flame_compare/` 中子文件不存在，链接会 404。即使旧版缺少 tree.json（该 SO 在旧版不存在），也必须用 `--compare` 模式 + `--a-tree` 传入不存在路径，脚本自动空槽占位。

```bash
python scripts/4_native_heap/build_flame_summary.py --compare \
  --so <so_name> --a-tree <A版_tree.json> --b-tree <B版_tree.json> \
  --a-label "8.0.21" --b-label "8.3.4" --single-file \
  -o output/flame_compare/<so_name>_compare_flame.html
```

- 用 `flame-c.template`（多火焰循环渲染），`soData=[A,B]`，同一 SO 两版聚类树纵向堆叠，同屏对照。
- **始终 2 槽**：A/B 各一槽。某版本缺 `tree.json`（如该 SO 为新版新增）时该槽用空槽占位（`{name:"<label>（无 tree.json，空槽）", tree:{value:0,children:[]}}`），保留前后对比结构；**两版都缺才不生成**（调用方在 md 注明，真实 SO 不会两版都缺）。
- B-only 新增 SO：省略 `--a-tree`，A 槽自动留空。

### 5.3 渲染准确性

- `convert_node` 保留 `value`（字节，全精度）和 `children` 层级 → 火焰图宽度/结构忠实于 `tree.json`；`shorten`/`split_name`/`StringTable`/`si` 取整只影响标签/tooltip。
- d3 `minFrameSize(1)` 过滤亚像素帧（极小分配不可见）、`inverted(true)` 隐藏 root、兄弟按 `value` 降序排序；叶子标签为 `meta:<callchain_id>`（不透明，查实际调用链去 `_diff.json` 取 id）。
- 聚类树父值 == 子值之和（无 gap/溢出），火焰渲染平衡。

## 步骤 6：DMA 型 SO 调用栈火焰图（--frame 帧名聚类）

> **触发场景**：Top10 劣化 SO 的 type_name 明细含 DMA（如 `libbuffer_handle.z.so`、`libhdi.z.so`）。这类 SO 的 DMA 内存由 gralloc/dmabuf 承载（分配发生在 allocator_host 进程）、不经应用进程 malloc，按 SO 名聚类必然为空（见 `diagnose_no_match`）；但 SurfaceBuffer 读取/请求路径（`ReadSurfaceBufferImpl` / `SurfaceBufferImpl::*` / `OH_NativeWindow_NativeWindowRequestBuffer` 等）发生在应用进程内，其调用栈已被 native_hook 抓到——按**帧名关键字**聚类可还原完整调用路径（main 线程 vsync → XComponent 布局 → 应用 so → RequestBuffer → ReadSurfaceBufferImpl），配合 dmabuf 明细构成 DMA 劣化的调用路径归因。

```bash
# ① 两版各自按帧名聚类（--label 传 SO 名，保持下游文件命名一致）
python scripts/4_native_heap/cluster_calltree.py \
  --db <版本.db> --frame SurfaceBuffer --label <so_name> \
  --output <版本目录>/<so_name>_tree.json
# 帧名关键字可逗号分隔多个（symbol_data 子串匹配，任一帧命中即取整条链）
# 全事件口径：覆盖 ION_Alloc_Event / MmapEvent / AllocEvent / FD_Open_Event
# 全部 hook 事件类型、含已释放——dmabuf 分配记录为 ION_Alloc_Event（heap_size
# 即 DMA 字节数），按 malloc 存活口径过滤会丢栈且 value≈0、火焰图空白
# 无匹配时不报错退出，生成空树基线（value=0）——旧版无该路径本身就是有效对比结果

# ② A/B 差分（与常规 SO 相同）
python scripts/4_native_heap/diff_cluster_tree.py \
  --tree-a <A>/<so>_tree.json --tree-b <B>/<so>_tree.json \
  --output output/flame_compare/<so>_diff.json

# ③ 前后对比火焰图（--compare 模式，同 5.2）
python scripts/4_native_heap/build_flame_summary.py --compare \
  --so <so_name> --a-tree <A>/<so>_tree.json --b-tree <B>/<so>_tree.json \
  --a-label <旧标签> --b-label <新标签> --single-file \
  -o output/flame_compare/<so_name>_compare_flame.html
```

**⚠️ 口径硬约束（报告挂载与统计隔离）**：

1. **树上 value = 关键字路径事件累计字节（全事件、含已释放）**：其中 `ION_Alloc_Event` 链的 value 即 **DMA 分配字节数本身**（火焰图按真实字节宽度渲染，实际调用栈可见）；A/B 差分 delta = 新增分配量，可与第五章 dmabuf 快照差值直接对账（实测：差分 Top1 `+2.33MB` ≡ dmabuf 2445312 字节）。**禁止**用 malloc 存活口径（query_callchains）生成该图——会丢掉 ION/Mmap 链、value≈0，火焰图空白看不出调用栈。
2. **不进 Native Heap 小节显示**：该火焰图**不得**写入对比报告 6.2 Native Heap 小节、不得并入 native heap 统计/排名——native heap 口径仅 AllocEvent 存活分配，混入会造成口径混淆。
3. **挂载位置**：对比报告第六章独立小节（如「6.4 DMA 调用栈归因（辅助）」）或第五章 DMA 对比分析之后，iframe 相对路径 `flame_compare/<so>_compare_flame.html`；小节须注明口径（"全事件累计字节，ION_Alloc_Event 子树即 DMA 分配量，可对账 dmabuf"），并摘录差分 Top 劣化链的实际调用栈（root→leaf）。
4. **空树基线语义**：A 版空树/B 版有路径 = 旧版未执行该路径（B-only 新增），火焰图 A 槽空占位正是差异证据，与 dmabuf 明细（0 条 → N 条）互为印证。
