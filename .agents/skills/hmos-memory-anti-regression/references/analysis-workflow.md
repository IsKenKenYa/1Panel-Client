# 分析工作流

## 1. 生成 meminfo.xlsx（每个版本各执行一次，用 harmonyos_pipeline.py）

从 meminfo/dynamic_showmap + dynamic_meminfo + dynamic_process_dmabuf_info 聚合（含 empty_service 区分 + GPU + DMA）：

> `output/<app>_<版本号>[_<场景>]/` 相对运行命令的工作目录（collect.py 产物目录，**非 skill 安装目录**）。版本号为应用真实 versionName（如 `14.8.10`），由 collect.py 自动从 HAP/设备提取。

```bash
python -c "
import sys; sys.path.insert(0, 'scripts/2_analysis'); sys.path.insert(0, 'scripts/_lib')
from harmonyos_pipeline import HarmonyLayer1MaPipeline
HarmonyLayer1MaPipeline(test_case_dir='output/<app>_<版本号>[_<场景>]/').analyze()
"
```

## 2. 运行归因分析（每个版本各执行一次）

```bash
python scripts/2_analysis/main_analysis_all_mem.py \
  -p output/<app>_<版本号>[_<场景>]/ \
  -o output/<app>_<版本号>[_<场景>]/analysis \
  --mm-dmabuf output/<app>_<版本号>[_<场景>]/mm_dmabuf_info_<pid>.txt \
  --detail -l 10,0,5
```

meminfo.xlsx 规则：

- `time` 列值设为 `"默认场景"`（与分析代码匹配）
- GPU (GL) 从 showmap 的 `GL` 行取值：`gpu_gles = GL_Pss / 1024`
- DMA 从 showmap 的 `Graph` 行取值：`dma = Graph_Pss / 1024`
- meminfo.xlsx 必须是**宽格式**（每个 Category 一列），不是长格式

## 2. 运行归因分析（每个版本各执行一次）

`main_analysis_all_mem.py` 会同时完成 meminfo.xlsx 生成和归因分析。

关键配置项（已在脚本中默认设置）：

| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| `type` | DEFAULT_TYPES | 采集类型：native_heap/GPU_VK/GPU_GLES/GPU_CL/SO_SIZE/ARKTS_HEAP/ASHMEM/DMA |
| `limit` | `[10, 0, 5]` | 每个二级领域最多显示 SO 数 / 过滤小于百分比 / 过滤小于 MB |
| `newrule` | `True` | 使用新归因规则 |
| `detail` | `True` | 详细模式 |
| `empty_service` | `35` | 空服务内存阈值 (MB) |
| `hiprofiler_noise` | `0` | hiprofiler 噪声过滤 |

## 3. 分析输出（每个版本）

| 文件 | 说明 |
|------|------|
| `汇总.xlsx` | 一层领域→二层领域→SO→type_name 四级归因，含 size/ratio |
| `topdown报告-默认场景.xlsx` | 按内存类别 (arkts heap/native heap/.so 等) 的 topdown 拆解 |
| `analysis_详细数据.xlsx` | 每条 SO 的 type 级明细 |
| `dma_detail.xlsx` | DMA buffer 详情 |
| `meminfo.xlsx` | 瞬时内存分类汇总 |

## 4. 两版本 topdown 对比 → 对比报告

对比两个版本的 topdown 和汇总表，生成对比报告：

- **Topdown 总览对比**：各内存类别总量差值
- **Topdown 子项拆解对比**：arkts heap/native heap/GL 等内部子项变化
- **汇总表对比**：一层领域→二层领域→SO→type_name 差值
- **Top10 劣化 SO**：按差值排序的前 10 个劣化 SO（排除分配器碎片/空服务/未覆盖等虚拟分类）
- **DMA 对比分析**：topdown Graph(DMA) 总览对账 + DMA buf_type 差值 + NULL 无名缓冲区明细（若有）+ Top10 图片/资源劣化（数据来源 `dma_detail.xlsx` + `mm_dmabuf_info`，须与 topdown Graph 三方对账）
- **劣化/改善根因分析**：定位主要劣化源/改善源

**对比报告格式参考**：`references/对比报告.md`

→ 详见 references/comparison-report-guide.md

## 5. 深度分析（按 Top10 劣化 SO 逐个分发）

**触发规则的唯一定义见 `SKILL.md`「步骤 3/4/5 触发逻辑」**：对第 4 节对比报告中的 Top10 劣化 SO（按新旧版本差值降序、排除虚拟分类）**逐个 SO** 检查其 type_name 明细并分发：

- 该 SO 含 `ARKTS_HEAP` → 步骤 3 + 步骤 4
- 该 SO 不含 `ARKTS_HEAP` 且不全是 `SO_SIZE` / `HAP` / `DMA` → 步骤 4
- 该 SO 全是 `SO_SIZE` / `HAP` / `DMA` → 不分发到步骤 3/4 的 native heap 归因；**但明细含 DMA 的 SO 须生成 DMA 调用栈火焰图**（`cluster_calltree.py --frame` 帧名聚类，不进 native heap 小节/统计，见 `native-heap-workflow.md` 步骤 6）
- 该 SO 含 `SO_SIZE` / `HAP` → 步骤 5（独立，可叠加）
- 该 SO 仅含 DMA → 第五章 DMA 对比分析 + DMA 调用栈火焰图（同上 `--frame`）

每个步骤只分析被分发到它的 SO；某步骤无 SO 被分发时跳过。

**不触发步骤 3/4 的原因**：SO_SIZE / HAP 类型不是运行时堆分配，htrace .db 中无对应的 nativehook 事件数据，步骤 3/4 的分析脚本无法产出有效结果。步骤 5 通过 smaps 对比分析 SO_SIZE/HAP 类型的内存变化，填补此盲区。

| 步骤 | 触发条件 | 依赖 | 产出 | 详见 |
|------|---------|------|------|------|
| Step 3: ArkTS Heap | 单个 SO 的 type_name 包含 ARKTS_HEAP | heapsnapshot 文件 | HTML/JSON 对比报告 + 源码解析 | `references/arkts-heap-workflow.md` |
| Step 4: Native Heap | 单个 SO 的 type_name 不全是 SO_SIZE/HAP/DMA | htrace .db 文件 | 差分 JSON + 源码解析 + 释放端诊断 | `references/native-heap-workflow.md` |
| Step 5: SO_SIZE/HAP smaps | 单个 SO 的 type_name 包含 SO_SIZE 或 HAP | A/B smaps 文件 | Pss 差值 + 劣化 SO/HAP + 根因推测 | `references/so-size-hap-workflow.md` |

## 归因规则

### 三级分类体系

每个 SO 按路径归入对应的三级分类：**FirstKind → SecondKind → ThirdKind**

归因结果体现在汇总表中：一层领域→二层领域→SO→type_name 四级，含 size/ratio。

### 规则文件

规则文件位于 `scripts/2_analysis/so_field/`：

| 规则文件 | 匹配方式 | 说明 |
|---------|---------|------|
| `rule_mapping.json` | 精确路径匹配 | 按 SO 完整路径归入 FirstKind/SecondKind/ThirdKind 三级分类 |
| `rule_pattern.json` | 正则路径匹配 | 覆盖精确匹配无法覆盖的场景（动态路径、三方应用自身 SO 等） |

### 一级分类 (FirstKind)

| FirstKind | SecondKind 数 | SO 数 | 说明 |
|-----------|--------------|-------|------|
| 语言运行时 | 12 | 132 | Ability/ArkTS/C/JS引擎/NAPI/仓颉/毕昇/Rust 等 |
| 系统SDK | 247 | 2681 | 系统自研Kit/系统三方开源库/驱动/图形/安全等 |
| WEB | 2 | 26 | ArkWeb/XWEB |
| 三方自研代码 | 1 | 61 | 三方开源ArkTS库 |
| UI | 1 | 40 | ArkUI 组件库 |
| Flutter | 1 | 3 | Flutter 运行时 |
| RN | 1 | 3 | React Native 运行时 |
| 内核驱动符号 | 1 | 2 | 内核符号/驱动符号 |

### 语言运行时常见二级分类

| SecondKind | 说明 |
|------------|------|
| Ability | 应用能力框架（104 SO） |
| ArkTS Runtime | ArkTS 运行时 |
| C Runtime | C 运行时（brk/jemalloc/mmap 等） |
| JS Engine | JS 引擎 |
| NAPI | NAPI 桥接 |
| 仓颉运行时 | 仓颉语言运行时 |
| 毕昇运行时 | 毕昇编译器运行时 |

### 系统SDK常见二级分类

| SecondKind 类型 | 示例 | 说明 |
|----------------|------|------|
| 系统自研Kit | Accessibility Kit / Audio Kit / Network Kit / ... | 80+ 个 Kit，按功能域划分 |
| 系统三方开源库 | protobuf / opencv / zlib / sqlite3 / ... | 40+ 个开源库 |
| 图形相关 | Graphics 2D / Graphics 3D / Graphic Effect | GPU/渲染相关 |
| 驱动相关 | drivers_peripheral_* / drivers_interface_* | 80+ 个驱动模块 |

### 特殊归因规则

- 未匹配的 SO 默认归入"三方自研代码/其他三方库"
- `.hap` 文件归入"三方自研代码/.HAP"
- `AnonPage other`/`FilePage other`/`dev`/`guard`/`stack` 等非 SO 类型走 `CATEGORY_MAPPING`（`scripts/_lib/config.py` 中定义），不走 SO 归因规则
- `分配器碎片`/`空服务`/`未覆盖` 是分析过程中生成的虚拟分类，不是归因规则的结果
- `rule_pattern.json` 中的三方应用自身 SO 匹配规则：`/proc/.*/data/storage/.*/bundle/.*\\.so.*`
- `rule_pattern.json` 中的应用自身 ArkTS 匹配规则：`.*\\.an$`（排除 stub.an）
