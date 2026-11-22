# 更新日志

## [1.4.0] - 2026-09-28

### 变更
- skill版本号升级至 v1.4.0

## [1.3.0] - 2026-09-01

### 变更
- skill版本号升级至 v1.3.0

## [1.2.0] - 2026-08-14

### 新增
- 新增全图强引用最短路径查找：默认路径经过弱引用边或弱容器时，重新查找另一条最短强引用链；仅弱引用可达的对象不进入候选。
- 单快照聚类新增 `--top <N>` 参数，默认为 5，Markdown、HTML 和 JSON 同步使用自定义 Top 数量。
- 新增 `.rawheap + .htrace + js_map*.txt` 三合一日志入口，自动完成 HTrace 转 SQLite DB、快照聚类、Node ID 到 Native 地址映射和调用栈关联。
- 新增 `native_hook_statistic`、`native_hook`、`native_hook_event` 及 GlobalHandle 聚合回退数据库适配，区分对象级精确关联和整体聚合栈，避免将聚合结果误归因到单个 JS 对象。
- 新增三合一分析续跑能力，支持通过 `--snapshot`、`--cluster-json` 和 `--native-hook-db` 跳过已完成阶段。
- 将 Native 输入准备、数据库适配和聚合报告拆分为独立模块，便于维护和复用。

### 变更
- GlobalHandler 精确关联按 `js_map Node ID -> 地址 -> data_dict.id -> native_hook_statistic.callchain_id -> native_hook_frame.symbol_id -> data_dict.data` 链路解析 Native 调用栈，支持一个 Node ID 对应多个地址。
- 三合一分析统一复用同级 `nativeleak-analysis/scripts` 中的 Trace Streamer，不在 JSLeak Skill 内复制二进制。
- 更新 `SKILL.md`、Heap Cluster 工作流和 README，补充强引用替代、TopN、三合一分析、聚合回退和续跑说明，并适配 `01-fault-analysis/jsleak-analysis/` 新目录结构。
- Windows `rawheap_translator.exe` 更新为 OpenHarmony SDK `26.0.0.37-Beta` 版本。

### 修复
- 修正弱引用对象处理方式，不再在聚类后按对象名称删除整组结果，而是在寻路阶段替换为强引用链。
- 兼容 `@memlab/core` 的 ESM 命名导出和 CommonJS default 导出，避免 `StrongReferenceTraceFinder extends TraceFinder` 因构造器未解析而报错。
- 修正 Windows Trace Streamer 版本和 `native_hook_statistic.addr_id` 映射逻辑，支持 `data_dict.data` 中逗号分隔的多地址，并保留完整调用栈。
- 修正目录迁移后 JSLeak、NativeLeak、Heap Cluster 和 Trace Streamer 的路径发现逻辑。
- 将新增 Native 栈关联脚本的内部变量、参数和对象属性统一为小驼峰命名，JSON 对外字段保持原有 snake_case 兼容格式。

## [1.1.0] - 2026-07-15

### 新增
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-jsleak-analysis` Skill
- 支持 .rawheap / .heapsnapshot 内存对象数据泄漏分析
- 内置 rawheap_translator 转换工具（支持 Windows/Linux/MacOS 多平台）
- 内置 heap_cluster 聚类脚本（`scripts/windows/heap_cluster.exe`）
- 支持四类泄漏规则检测：
  - Detached DOM 泄漏
  - 全局引用泄漏（window/Global/Cache/Map）
  - 闭包泄漏（context/system Context）
  - 异常大小对象泄漏
- 支持故障模式库匹配（ROOT_VM / ROOT_FRAME / ROOT_LOCAL_HANDLE / ROOT_GLOBAL_HANDLE / Unknown）
- 新增参考资料：
  - `references/fault-modes.md`：故障模式库
  - `references/ArkTS_OOM_故障模式库.md`：ArkTS OOM 故障模式库
- 输出结构化泄漏嫌疑清单（含引用链、根因分析、修复建议）
