# ImageKnifePro 劣化案例模式（libimageknifepro.so / imageknifepro）

> 本文档定义 ImageKnifePro 维度劣化的典型案例模式，供综合报告第八章「劣化点汇总与优化建议」根因匹配使用（案例库范围与匹配规则见 `SKILL.md` 第八章）。
>
> 匹配到下列案例时：可引用案例的根因推断与修复方向，并标注出处（如「见 imageknifepro.md 一、libimageknifepro.so 劣化」）。未匹配到时：8.1 根因列写「未匹配案例库，需人工核查」，不给修改建议。

## 一、ImageKnifePro so 劣化

### 案例模式描述

应用使用 ImageKnifePro（开源图片加载缓存库）加载图片，其 native 模块在设备上的 so 名为 `libimageknifepro.so` 或 `imageknifepro`（不同版本/打包方式下 so 名可能不含 `lib` 前缀），归属「三方自研代码 → 三方图像」二层领域，`type_name=SO_SIZE`。当该 so 的 `size`/`type_size` 由旧版到新版增长时，判定为 ImageKnifePro 维度劣化，指向**图片加载/缓存/解码行为的版本间变化**（缓存上限调大、预加载增多、解码配置变化导致映射/驻留增长）。

### 匹配规则

> **输入**：两版 `analysis_详细数据.xlsx`（报告地址下 `<版本>/analysis/analysis_详细数据.xlsx`，「默认场景」sheet）。**只读取已落盘产物，不执行任何采集操作**（见 `optimization-workflow.md` 数据范围硬约束）。

1. **ImageKnifePro so 劣化**：在两版 xlsx 的「默认场景」sheet 中分别定位 `so` 列为 `libimageknifepro.so` **或** `imageknifepro` 的行，比较其 `size` 列——新版值 **大于** 旧版值（`delta > 0`）即命中。

（本案例仅含此一条数据规则，无核查规则。）

判定口径说明：

- **两版数值相等（delta = 0）**：无劣化，未匹配（如 0.77 → 0.77）。
- **新版小于旧版（delta < 0）**：改善项，未匹配。
- **xlsx 中无该 so 行**（一版或两版缺失）：缺失版按 size = 0 处理（与 hap.md 头部「A 版无映射记 0、B 侧出现映射即视为增长」口径一致）——旧版缺失、新版有值 → delta > 0，命中劣化；旧版有值、新版缺失 → delta < 0，改善项，未匹配；两版均缺失 → delta = 0，无劣化，未匹配。

### 问题代码

可能不涉及具体代码定位（本案例模式不提供问题代码样例）。