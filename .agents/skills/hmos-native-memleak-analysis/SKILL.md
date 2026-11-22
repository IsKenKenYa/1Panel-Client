---
name: hmos-native-memleak-analysis
description: >
  自动分析 HarmonyOS / OpenHarmony Native内存泄漏问题，基于 sample 采样文件、smaps 文件、profiler 火焰图等信息定位泄漏根因并输出完整证据链。
  当用户提供 sample 采样文件、smaps 文件、profiler 火焰图、NMD 数据，或询问应用内存泄漏/内存增长/OOM问题的根因
  即使用户只说"帮我分析这个内存泄漏"、"应用内存一直涨"、"native泄漏分析"、"PSS泄漏"、"DMA泄漏"、"GPU泄漏"，也应立即触发此技能。
metadata:
   author: Huawei Reliability Technology Lab
   version: 1.4.0
---

# Native Memory Leak Analysis Skill

## 约束

- **必须基于用户提供的实际信息分析**，严禁编造、拼接、伪造不存在的数据。
- 每条关键结论必须有原始数据内容作为佐证。
- 不能假设未提供的数据。
- 确保证据链的逻辑性和完整性。
- 按以下 Step 顺序逐步分析。
- 不需要读取任何的文件进行分析，所有的信息调用脚本获取即可

---

## 分析工作流

### Step 0 — 前置环境检查

在调用任何 nativeleak 脚本前，必须先完成以下环境检查：

1. **Python 可用性检查**
   ```bash
   python --version
   ```
   - 若命令不可用，先提示用户安装 Python 3。
   - 若系统同时存在 `python3`，可使用 `python3` 替代后续命令中的 `python`。

2. **第三方依赖检查**
   nativeleak Python 脚本依赖 `dill`，需要先确认依赖可导入：
   ```bash
   python -c "import dill"
   ```
   - 若检查失败，提示用户在仓库根目录执行：
     ```bash
     pip install -r requirements.txt
     ```

3. **脚本路径检查**
   确认以下脚本存在：
   - `scripts/file_process.py`
   - `scripts/sample.py`
   - `scripts/native_rate_parser.py`
   - `scripts/native_parser.py`
   - `scripts/kernel_leak.py`
   - `scripts/flame_analyzer.py`

4. **输入路径检查**
   确认用户提供的日志目录或文件路径存在。若路径不存在，先提示用户修正路径，不继续执行分析。

### Step 1 — 获取要分析的文件并判断是否为统一管控

> 不需要查看日志文件有哪些，直接调用 `python scripts/file_process.py -p {dir_path}` 获取所有要分析的文件
> 返回文件类型示例：

- Sample文件：`memleak-native-{bundleName}-{pid}-sample.txt`
- Smaps文件：`memleak-native-{bundleName}-{pid}-smaps.txt`
- Profiler文件：`memleak-native-{bundleName}-{pid}-{timestamp}.txt`
- Kernel文件：`memleak-kernel-{bundleName}-{pid}-{timestamp}.txt`
- Kernel companion文件：`memleak-kernel-hiapp-{bundleName}-{pid}-{timestamp}.txt`（按采集时间选择最新/与Native采集最接近的文件；同一时间同时存在时优先标准文件，禁止重复统计）
- 如果**仅有 kernel 文件**，说明是**非统一管控场景**

---

### Step 2 — 判断泄漏类型

> 调用 `python scripts/sample.py -p {file_path}` 获取泄漏类型占比和内存变化趋势
> 这里的文件路径是 sample 文件路径

#### 2a. 统一管控场景

判定说明：
（1）泄漏检测模块支持检测应用整体内存占用情况（去重后），即基于进程的PSS、DMA、GPU内存之和与进程基线进行比较去判定是否存在泄漏，即泛PSS泄漏。
（2）对于统一管控触发的泄漏上报而言，不论是DMA、GPU还是PSS，都会有对应的采样文件，用来展示进程的整体内存增长趋势，其中有星号标记的行，是PSS经过校准后的进程真实内存占用（可信度最高）
判断规则：
如果仅有kernel侧泄漏文件，则属于非统一管控，反之是同一管控场景

如果是统一管控场景，则基于泄漏类型占比判断具体泄漏类型：

- **PSS 内存泄漏**：PSS 占比较大且超过50%，直接执行Step3
- **DMA 内存泄漏**：DMA 占比较大且超过50%，直接执行Step 5
- **GPU 内存泄漏**：GPU 占比较大且超过50%，直接执行Step 5
- **注意**：可能不止一种泄漏类型，当两个或多个内存占比均较大时，但均不超过50%时，需同时标注并分析。

#### 2b. 非统一管控场景

如果不是统一管控，则直接跳转至 **Step 5** 进行分析

#### 2c. 内存增长趋势分析

**必须执行**：给出内存增长趋势分析，包括：

- 内存增长起点值与终点值
- 增长幅度（绝对值与百分比）
- 增长趋势特征（持续线性增长 / 阶梯式增长 / 突然跳变等）

---

### Step 3 — PSS 内存泄漏细分（仅 PSS 泄漏时执行）

如果 Step 1 判定为 **PSS 内存泄漏**，需通过 `python scripts/native_rate_parser.py -p {file_path}`
获取泄漏子类型占比
> 这里的文件路径是 smaps 文件

根据子类型占比判断：

- **Jemalloc**：堆内存泄漏（jemalloc）
- **ArkTS**：ArkTS 虚拟机对象泄漏
- **Ashmem**：共享内存泄漏
- **Anon**：匿名内存泄漏

#### 3a. 兜底规则

如果上述四种类型占比**均不超过 50%**，则选择**占比较大**的类型作为最终泄漏类型（可能不唯一，需同时列出）。

---

### Step 4 — PSS 子类型深入分析

根据 Step 3 确定的 PSS 泄漏子类型，执行对应的深入分析。

#### 4a. 堆内存（jemalloc）泄漏深入分析

- **判断规则**：jemalloc 类型占比超过总 PSS 内存的 50%
- **分析命令**：
  > 调用 `python scripts/native_parser.py -p {file_path} -t jemalloc` 获取分析结果
  主要关注其size和allocated两列，是否有比较突出的内存占用,如果有，假设size为a（如128），就去调用栈（profiler）中查找size为a的内存申请，重点分析这行调用栈，极可能是泄漏点。
  > 说明
  >
  Size：用户申请的内存经过对齐后的大小，jemalloc对齐size的分割是按照一个特定算法算的，8字节是最小单位，从第二个size开始，最小step是16，一个size到它的两倍size之间有4个分档。用户态传入的申请大小会向下对齐到离它最近的size中。
  > Allocated：size申请的总内存。
  > 调用 `python scripts/flame_analyzer.py <trace数据库路径> -s <size列表> -t malloc` 解析 profiler / trace 数据，识别泄漏的具体模块（.so 文件）和函数调用路径
- **输出内容**：
    - 泄漏的堆内存大小及占比
    - 泄漏最严重的 .so 模块名称
    - 具体函数调用路径
    - 怀疑方向（如：频繁创建对象未释放、缓存未清理等）

#### 4b. 虚拟机对象（ArkTS）泄漏提醒

- **判断规则**：arkts 类型占比超过总 PSS 内存的 50%
- **输出提醒**：
    - "需要进一步提供快照文件（Snapshot）分析找到泄漏对象"
    - "如有相关快照文件(.heapsnapshot类型文件)可使用 heap-leak-analysis skill 进行分析"
- **补充分析**：如用户同时提供了其他文件，可分析其他可能原因

#### 4c. ashmem 泄漏深入分析

- **判断规则**：ashmem 类型占比超过总 PSS 内存的 50%
- **分析命令**：
  > 调用 `python scripts/native_parser.py -p {file_path} -t ashmem`
- **分析内容**：
    1. **怀疑方向**：开发者使用 image 组件、pixmap 组件可能未释放，或开发者直接通过系统调用申请共享内存
    2. **下一步**：分析虚拟内存最大的进程，以及该进程的所有句柄（handle）的虚拟内存占用
    3. 定位未释放的 ashmem 区域及其关联的业务模块

#### 4d. anon 泄漏深入分析

- **判断规则**：anon 占用超过总 PSS 内存的 50%
- **分析命令**：
  > 调用 `python scripts/flame_analyzer.py <trace数据库路径> -s <size列表> -t mmap` 解析 profiler / trace 数据，识别泄漏的具体模块（.so 文件）和函数调用路径
- **分析内容**：
    - 泄漏的匿名内存大小及占比
    - 泄漏最严重的 .so 模块名称
    - 具体函数调用路径
    - 怀疑方向（如：mmap 映射未释放、线程栈泄漏等）

---

### Step 5 — kernel泄漏分析

如果存在kernel侧泄漏：
调用 `python scripts/kernel_leak.py -p {file_path}`

- 脚本兼容 `memoryName:*`、`Process dma_heap info`、`MM_DMABUF_INFO`、`LOGGER_PROCESS_DMABUF_INFO` 新旧格式。
- 需要结构化数据时调用 `python scripts/kernel_leak.py -p {file_path} --json`。
- 若脚本非零退出并提示“不支持或无法识别”，必须如实记录检测到的标记和缺失数据，不得把空输出解释为“无泄漏”。

1. 获取 kernel 文件中的内存信息
2. 获取主要内存占用类型
3. 根据内存占用类型比判断：

- **DMA**：DMA泄漏，跳转至Step6
- **GPU**：GPU泄漏，跳转至Step7
- **ASHMEM**：共享内存泄漏，跳转至Step8
- **SLAB**：跳转至Step9

---

### Step 6 — DMA 内存泄漏分析（仅 DMA 泄漏时执行）

调用 `python scripts/kernel_leak.py -p {file_path}`
获取Top5进程的DMA使用情况和共享内存

1. 完整日志优先使用带单位的系统MemInfo `IonTotalUsed/DmaHeapTotalUsed` 作为物理DMA总量；裁剪日志没有该值时使用 **DMA明细按 ino 去重总量**。必须同时报告明细覆盖总量及二者差额；“原始引用合计”仅反映fd/进程引用，禁止当作物理独占总量。
2. 分析Top5进程的总DMA、进程私有、共享归属，并给出占用较大的 **size_bytes**、**buf_name**、**buf_type**、**leak_type**。
3. `is_reclaim=0` 才计入DDR，`is_reclaim=1` 计入可回收/UFS；字段缺失或取值未知时必须单列“回收状态未知”，禁止强行计入DDR。
4. 根据 `buf_name`、`buf_type`、`leak_type` 给出对应组件；若字段为空或损坏，只能标记待补证。
5. 参考 dma.md，分析 DMA buffer 未释放的可能原因：
    - 媒体业务未释放解码缓冲区
    - 图形渲染未释放纹理/帧缓冲区
    - Camera 业务未释放预览缓冲区

---

### Step 7 — GPU 内存泄漏分析（仅 GPU 泄漏时执行）

1. 分析识别 **GPU 内存占用最高的类型**（如显存类型、纹理内存、渲染缓冲区等）
2. 给出 GPU 内存泄漏的来源模块及可能的触发场景：
    - EGL 上下文未销毁
    - OpenGL ES 纹理/缓冲区未释放
    - GPU 渲染缓存未清理
3. 如有 profile 文件，解析调用栈定位具体模块

---

### Step 8 — 综合结论输出

综合以上所有步骤信息，输出最终分析结果。
8a. 严格按照故障模式库匹配（必须执行）
读取 references/fault-mode-library.md，按以下顺序逐级匹配：

一级：判断故障大类（当前库覆盖：RSS 泄漏，进程泛 PSS 泄漏）
二级：按照细分泄漏子类型进行匹配
三级：按各编码的判定规则逐条匹配，找到唯一命中条目（优先精确匹配，无匹配时使用兜底条目）注意：最终无需输出编码信息
---

## 输出格式模板

1.PSS泄漏报告示例如下（报告中标记的引用部分必须完整保留，用“>”符号标记的内容）
注意：分析报告模板提到的引用部分例如：分析说明、判定规则和分析规则在最后报告必须完整保留，方便开发者感知串联起完整的分析过程（避免分析结果太跳跃看不懂）

---

# Native 内存泄漏综合分析报告

## 一、分析信息概览

| 项目    | 内容    |
|-------|-------|
| 应用包名  | xxx   |
| 进程PID | xxx   |
| 分析时间  | xxx   |
| 采样时长  | xxx分钟 |

## 二、分析流程记录

### Step 1 - 泄漏类型判定

> 判定规则：
> 1、通过分析采样日志sample文件，根据totalmem列分析进程内存的增长趋势，并根据totalpss、DMA、gpu列来判定进程属于哪种泄漏
> 2、根据占比大小判定泄漏类型，具体分为PSS内存泄漏、DMA内存泄漏、GPU内存泄漏（可能不止一种泄漏类型，当两个或多个内存占比均较大时，需同时标注并分析）

**内存增长趋势分析：（如果未显示某种内存，说明未采集，用~代替）**

| 内存类型 | 起始内存 | 终止内存 | 峰值内存 | 增长幅度（%） | 关键内存增长时间（寻找内存增长最快的时间段） | 趋势特征 |
|------|------|------|------|---------|------------------------|------|
| pss  | xxx  | xxx  | xxx  | xx%     | xxx                    | xxx  |
| dma  | xxx  | xxx  | xxx  | xx%     | xxx                    | xxx  |
| gpu  | xxx  | xxx  | xxx  | xx%     | xxx                    | xxx  |

**结论：** 经过对sample文件内存趋势分析，判断是XXX内存泄漏

### Step 2 - PSS泄漏子类型细分

> 判定规则：
> 1、通过分析细分类型：具体包含堆内存泄漏（Heap/jemalloc泄漏）、虚拟机对象泄漏（ArkTS泄漏）、Ashmem泄漏、Anon泄漏
> 2、细分规则：分析进程的smaps信息，结合下方规则定位分析是哪一块泄漏
> （1）堆内存泄漏判断规则：通过在smaps文件搜索关键字"jemalloc"，PSS和SWAP PSS列的值加起来占比高，则说明是堆内存泄漏
> （2）虚拟机对象泄漏判断规则：通过在smaps文件搜索关键字"ArkTS"，PSS和SWAP PSS列的值加起来占比高，则说明是ArkTS内存泄漏
> （3）Ashmem泄漏判断规则：通过在smaps文件搜索关键字"/dev/ashmem"，如果占总PSS内存的高，则说明是Ashmem内存泄漏
> （4）Anon泄漏判断规则：单个Anon类型占用内存较大，占如果超过总PSS内存高，怀疑mmap内存未释放，直接排查profiler栈，框选All
> Anonymous VM，筛选Created & Existing，排查内存占用最多的部

**具体PSS内存占用情况：**

| 内存类型     | 占用大小(MB) | 占比(%) |
|----------|----------|-------|
| Je     | xxx      | xxx   |
| ArkTS    | xxx      | xxx   |
| Anon     | xxx      | xxx   |
| Ashmem   | xxx      | xxx   |

**结论：** XXXX占比xxx%，判定为**XXX泄漏**

### Step 3 - 堆内存泄漏（Heap泄漏）深入分析

> 分析说明：如果确定是堆内存泄漏（Heap泄漏），需要分析smaps文件进程的堆内存申请信息，找到内存申请大的内存块，并结合profiler火焰图分析具体调用栈信息
> 规则：分析smaps文件，通过两次NMD内存采样信息（间隔5分钟），分别找到各size内存块申请内存最大的TOP3（通过allocated列判断），以及两次NMD内存采样信息中申请内存增量最大的内存块TOP3

#### 3.1 内存块分析

**内存申请最大的内存块信息（TOP3）：**
| Size(B) | Allocated(B) | 占用比例(%) |
|---------|--------------|---------|
| xxx | xxx | xxx |

**两次NMD采样内存申请增量最大的内存块信息（TOP3）：**
| Size(B) | Allocated(B) | 增量(B) |
|---------|--------------|---------|
| xxx | xxx | xxx |

#### 3.2 profiler文件调用链定位,给出完整调用链

> 分析说明：
> 1、分析内容：分析profiler信息（检测到泄漏后抓取15min内的进程内存trace，将日志通过Open File加载到DevEco Studio进行解析）
> 2、选择All Heap：
> （1）展示抓取15分钟内的内存情况，记录了hook malloc等系统调用的堆栈。Native日志是以so+偏移的形式展示调用栈（每一行表示一次内存分配行为调用栈），需要结合符号表进一步分析。
> （2）点击Call Trees可以查看抓取进程的调用栈，筛选“Created & Existing”，根据没有释放的内存占比排序，展开可查看详细进程调用信息，优先排查内存占用较高的堆栈
> 3、分析规则：通过TOP内存块size信息，在profiler日志筛选每个内存块的TOP调用栈内存占用情况，最后将所有调用栈内存占比信息从大到小排序，从大到小展示调用栈直到累计占比达成60%，最多不超过5个（即展示前TOP5）

**调用链详情：**
profiler采样内存：XXX

Top1 内存占用调用栈, 分配内存：xxxB 归属内存块：2097152, 占采样内存比例：xxx%, 堆栈类型：xxx
完整的调用栈信息展示：

TOP2 内存占用调用栈, 分配内存：xxxB 归属内存块：2097152, 占采样内存比例：xxx%, 堆栈类型：xxx
完整的调用栈信息展示：

xxx

xxx

**引用链分析泄漏点定位：**

- **问题模块**: libface_detect.so
- **问题函数**: AIPipe::CVLiteNormalize::MallocOutput
- **完整调用路径**: Node::InvokeLoop → TaskQueue::AddNodeForProcess → Node::ProcessNode → CVLiteNormalize::Process →
  MallocOutput

## 三、分析结论

### 3.1 证据链

| 序号 | 证据描述      | 原始数据                                                      |
|----|-----------|-----------------------------------------------------------|
| 1  | 泄漏类型判定    | sample文件显示仅PSS内存增长，DMA/GPU均为"~"，总内存从1495623KB增长到1849208KB |
| 2  | 泄漏子类型判定   | smaps文件解析显示jemalloc占用1773.20MB，占总PSS的98.19%               |
| 3  | 泄漏点定位     | nmd显示size=2097152的内存块allocated比例达108.39%，累计分配155648KB但未释放 |
| 3  | profile定位 | size=2097152对应的调用链累计分配155648KB但未释放，占profile采样比例 xx%       |

### 3.2 根本原因

【三级根因定位】（依据故障模式库）
展示模板：注意无需带上FM-L1-B等字样，即最终无需输出编码信息

| 排名   | 进程名        | 匹配依据     |
|------|------------|----------|
| 一级根因 | <具体一级根因名称> | <原始日志片段> |
| 二级根因 | <具体二级根因名称> | <原始日志片段> |
| 三级根因 | <具体三级根因名称> | <原始日志片段> |

### 3.3 根因模块 (注意调用栈要显示完整，不要省略，参考模版的示例)

| 调用栈                                                               | 责任描述                                         |
|-------------------------------------------------------------------|----------------------------------------------|
| /data/storage/el1/bundle/faceService/libs/arm64/libface_detect.so | AI推理核心模块，负责CVLiteNormalize::MallocOutput内存分配 |

### 3.4 修复建议

<1-3 条具体建议>

---

2.DMA泄漏报告如下

# DMA内存泄漏综合分析报告

## 一、分析信息概览

| 项目           | 内容  |
|--------------|-----|
| 应用包名         | xxx |
| 进程PID        | xxx |
| DMATotalUsed | xxx |
| TOP1 DMA使用进程 | xxx |
| 游离态DMA       | xxx |

## 二、分析流程记录

2.1.DMA使用TOP5进程

| 排名  | 进程名 | pid | DMA使用 | 进程私有 | buff_name使用 |
|-----|-----|-----|-------|------|-------------|
| xxx | xxx | xxx | xxx   | xxx  | xxx         |

2.2 TOP1 DMA使用进程size拆解

| size(B) | 占用内存 | buffer_name | buffer_type | 数量  |
|---------|------|-------------|-------------|-----|
| xxx     | xxx  | xxx         | xxx         | xxx |

2.3 关键泄漏点分析
<1-3 条可疑的泄漏点>

## 三、分析结论

### 3.1 根因定位

【三级根因定位】（依据故障模式库）

| 排名   | 进程名                    | 匹配依据     |
|------|------------------------|----------|
| 一级根因 | <具体三级根因名称>漏                 | <原始日志片段> |
| 二级根因 | <具体三级根因名称>                   | <原始日志片段> |
| 三级根因 | <具体三级根因名称>                   | <原始日志片段> |

### 3.2 根因模块

1.问题进程：xxx
2.问题模块：xxx
3.怀疑方向：xxx

### 3.3 修复建议

<1-3 条具体建议>

```

---

## 注意事项

1. **数据真实性**：所有分析结论必须基于用户提供的实际数据，禁止推测或编造。
2. **多种泄漏并存**：当多种泄漏类型并存时（如 PSS + DMA），需分别分析并在报告中逐一呈现。
3. **占比计算**：所有占比计算需给出分子、分母及计算过程，确保可验证。
4. **证据链完整性**：每个结论必须有对应的原始数据支撑，形成闭环的证据链。
5. **模块定位精确性**：根因模块需精确到 .so 文件或服务名，不可停留在模糊描述。
6. **非统一管控场景**：非统一管控时跳过 PSS 细分分析，直接进行内存分析。
7. **ArkTS 提醒**：当识别到 ArkTS 泄漏时，必须提醒用户提供快照文件进一步分析。
