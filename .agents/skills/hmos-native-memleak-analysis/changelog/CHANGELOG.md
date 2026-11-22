# 更新日志

## [1.4.0] - 2026-09-28

### 变更
- skill版本号升级至 v1.4.0

## [1.3.0] - 2026-09-01

### 新增
- 新增 Native/Kernel 日志文件名解析与确定性文件选择，支持按进程、PID、采集时间自动匹配 sample、smaps、profile 和 kernel companion 日志。

### 变更
- Kernel 内存分析兼容 `MM_DMABUF_INFO`、`LOGGER_PROCESS_DMABUF_INFO`、`Process dma_heap info` 和 `memoryName` 等新旧格式，并增加 JSON 汇总输出。
- DMA 统计区分系统物理总量、按 inode 去重明细、进程引用合计、私有/共享占用和回收状态，避免将重复引用误判为物理独占内存。
- 完善空日志、未知格式、无效数值和序列化失败的显式错误处理。
- 统一 NativeLeak Python 类的方法排列顺序，满足 `function-order` 门禁规则，不改变现有方法签名和解析行为。
- 拆分 Kernel/DMA、Flame、文件发现和 jemalloc 报告中的超大函数，确保所有 Python 函数不超过 50 NBNC 行。
- 调整 staticmethod、classmethod 和普通方法的排列，并降低 MemInfo 日志解析函数的嵌套深度，适配代码门禁规则。
- skill版本号升级至 v1.3.0

## [1.2.0] - 2026-08-14

### 变更
- 更新 Windows `trace_streamer_windows.exe` 可执行文件，修正 HTrace 转 SQLite DB 的 `native_hook_statistic`、`native_hook_frame` 和 `data_dict` 数据解析结果。
- Trace Streamer 继续按 Git LFS 规则管理，并作为 JSLeak 三合一 Native 栈关联功能的共享转换工具。

## [1.1.0] - 2026-07-15

### 新增
- 初始版本发布，新增 `hmos-native-memleak-analysis` Skill
- 支持 HarmonyOS/OpenHarmony Native 层内存泄漏自动化分析，覆盖 PSS、DMA、GPU、Kernel 等多种泄漏类型
- 内置智能场景判定：自动识别统一管控与非统一管控场景，并据此切换分析策略
- 支持多维度泄漏细分：
  - **PSS 泄漏**：自动细分 Jemalloc（堆内存）、ArkTS（虚拟机对象）、Ashmem（共享内存）、Anon（匿名内存）子类型
  - **DMA/GPU 泄漏**：分析 Top5 进程内存占用，定位未释放的 buffer 与渲染组件
  - **Kernel 泄漏**：解析内核侧内存分配，识别 SLAB、DMA 等内核态泄漏
- 提供完整的分析工具链：
  - `sample.py`：分析内存增长趋势与泄漏类型占比
  - `native_rate_parser.py`：解析 smaps 文件进行 PSS 子类型判定
  - `native_parser.py`：深入分析 jemalloc/ashmem 内存块分布
  - `flame_analyzer.py`：解析 profiler/trace 火焰图，定位泄漏模块与函数调用路径
  - `kernel_leak.py`：提取并分析 kernel 侧内存数据
- 支持故障模式库三级根因匹配（RSS 泄漏、进程泛 PSS 泄漏等）
- 输出结构化综合分析报告（含内存趋势表、泄漏点定位、证据链、根因模块与修复建议）
- 新增参考资料：`references/fault-mode-library.md`、`references/dma.md`、`references/dma_template.md`、`references/native_template.md`
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息
