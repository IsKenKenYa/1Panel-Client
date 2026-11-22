# SO_SIZE/HAP smaps 对比分析工作流

**独立分析步骤**：本步骤不依赖 step 2 的 topdown 对比结果，可独立执行并输出自己的分析报告。

## 前置条件

1. 两个版本的 smaps 文件（A=旧版/基线，B=新版/当前），通过 `hidumper --mem-smaps <pid>` 或 `cat /proc/<pid>/smaps` 采集
2. 两个 smaps 在相同操作路径下采集（同一业务场景）

## 工作流

### 步骤 1：对比 smaps

```bash
python scripts/5_so_size_hap/diff_smaps.py \
  --smaps-a <A版本_smaps.txt> \
  --smaps-b <B版本_smaps.txt> \
  --top 20 \
  --json smaps_diff.json
```

**解析原理**：
- 自动检测 smaps 格式：hidumper 表格格式 或 raw /proc/pid/smaps 格式
- **hidumper 表格格式**（`hidumper --mem-smaps <pid>` 输出）：按行解析表格列，按 `Category` 列过滤 `.so`/`.hap`，按 `Name` 列取文件路径，每行已聚合无需合并
- **raw /proc/pid/smaps 格式**（`cat /proc/<pid>/smaps` 输出）：按内存段分块，提取 pathname 以 `.so` 或 `.hap` 结尾的映射，按完整 pathname 汇总 Pss（同一 SO 的多个映射段：r-xp 代码段、r--p rodata、rw-p data/bss 合并）
- A/B 按 pathname 配对，计算 Pss 差值（delta = B - A）
- 按差值降序排列，输出 Top N

### 步骤 2：阅读报告

脚本 stdout 输出文本报告，包含：
- 总览：A/B SO/HAP Pss 合计 + 差值
- Top N 差异项表格（名称、A/B Pss、差值、状态）
- 根因分析与修复建议（按差值降序，仅劣化和新增项）

### 步骤 3：根因分析

脚本自动根据以下规则推测根因：

| 条件 | 根因类型 | 说明 |
|------|---------|------|
| 映射在 B 中首次出现 | 新增依赖 | 新引入的 SO/HAP，可能是新功能或新依赖 |
| 映射段数增加 + Size 增长 | 二进制体积增大 | 新增代码段或数据段，可能是编译选项变化或新功能 |
| Size 不变但 Pss 增长 | 运行时数据膨胀 | 二进制大小不变但驻留内存增加，运行时数据结构或缓存增多 |
| Size + Pss 同时增长 | 代码+数据同时增长 | 二进制和运行时内存同时增长 |

### 步骤 4：归属领域推断

脚本根据 pathname 关键词推断 SO/HAP 归属领域：

| 路径关键词 | 归属领域 |
|------------|---------|
| `.hap` | HAP（应用安装包） |
| `arkui` / `ace` | ArkUI/ACE 框架 |
| `arkts` / `ecmascript` / `js_runtime` | ArkTS/JS 运行时 |
| `flutter` | Flutter 运行时 |
| `react` / `hermes` | React Native 运行时 |
| `graphic` / `render` / `gl_` / `vulkan` | 图形/渲染 |
| `audio` / `media` / `camera` | 音视频 |
| `sqlite` / `rdb` / `preference` | 数据库/存储 |
| `bundle` + `el1` | 应用自身 SO |

## 劣化类型分类

| 差值 | 段数变化 | Size 变化 | 类型 | 后续动作 |
|------|---------|----------|------|---------|
| > 0 | 增加 | 增长 | 二进制膨胀 | 检查编译产物，对比新增符号 |
| > 0 | 不变 | 不变 | 运行时数据膨胀 | 检查运行时内存分配行为 |
| > 0 | 不变 | 增长 | 代码+数据增长 | 同时检查编译产物和运行时 |
| > 0 | — | — | 新增映射 | 检查是否为新引入依赖 |
| < 0 | — | — | 改善 | 无需处理 |

## 独立分析报告输出

| 输出 | 来源脚本 | 说明 |
|------|---------|------|
| 文本报告 | `diff_smaps.py` stdout | 总览 + Top N 差异项表格 + 根因分析 + 修复建议 |
| `smaps_diff.json` | `diff_smaps.py --json` | 结构化 JSON，含 summary + items（每项含 pathname/pss/delta/root_cause/suggestion/category） |

**报告解读**：
- **delta_pss_mb > 0**：SO/HAP 的 Pss 增长，为劣化方向
- **is_new = true**：B 版本新增的映射，优先检查是否为预期引入
- **is_removed = true**：B 版本移除的映射，为改善方向
- **root_cause 字段**：脚本自动推测的根因
- **suggestion 字段**：脚本自动生成的修复建议

## 依赖

- Python 3 标准库（无外部依赖）

## 与步骤 2 的关系

步骤 2 的归因分析会将 SO 按 `type_name = SO_SIZE` 或 `type_name = HAP` 分类，这些类型的 SO 在 htrace .db 中没有对应的 nativehook 事件数据，步骤 3（ArkTS Heap）和步骤 4（Native Heap）无法分析它们。

本步骤通过 smaps 对比直接分析 SO_SIZE/HAP 类型的内存变化，填补了步骤 3/4 的盲区。当 Top10 劣化 SO 全部只含 SO_SIZE/HAP 类型时，步骤 3/4 无 SO 被分发而不触发，本步骤是唯一的深度分析手段。

按 `SKILL.md`「步骤 3/4/5 触发逻辑」的分发规则，本步骤由 Top10 劣化 SO 中 type_name 含 SO_SIZE/HAP 的 SO 触发；解读输出报告时**聚焦这些被分发 SO 的差异项**，其余差异项作为背景参考。
