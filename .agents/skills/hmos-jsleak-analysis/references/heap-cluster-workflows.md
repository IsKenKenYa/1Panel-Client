# Heap Cluster 工作流

使用 `scripts/node/heap_cluster.js` 分析堆快照；用户明确要求 GlobalHandler对象关联native堆栈时，使用 `scripts/node/heap_node_native_stack.mjs`。运行环境、依赖检查和具体命令以主 `SKILL.md` 为准。

所有聚类和对比模式都会在分组前重新计算最短强引用链。默认最短链经过
`WeakMap`、`WeakSet`、`WeakRef`、`WeakRefPool`、`js_weak_map`、
`weak_linked_hash_map` 等弱容器或 `weak` 边时，改用其他最短强引用链；
只有仅弱引用可达的对象不进入候选。弱容器自身被强引用时可以展示，但不能
继续保活下游对象。

## 单快照聚类

- **作用**：分析单个 `.heapsnapshot`，识别占用内存较大的业务对象、公共对象及其引用链。
- **效果**：生成 Markdown、HTML 和 JSON 聚类报告，为泄漏对象筛选和根因判断提供依据。使用 `--top <N>` 可同步调整业务对象和公共对象的展示数量，默认为 5。

## 目录逐份聚类

- **作用**：批量分析目录中的多个快照，并分别保留每份快照的结果。
- **效果**：快速查看各快照的对象分布和引用链，适合逐份排查，不生成跨快照总榜。

## 多快照总榜

- **作用**：聚合一个目录中的多份快照，识别持续出现、累计占用较大或反复进入高排名的对象。
- **效果**：生成业务对象和公共对象总榜，并展示累计 Retained Size、出现次数和代表引用链，便于判断长期持有和疑似泄漏对象。

## 双版本增长对比

- **作用**：比较基线版本和新版本的多份快照，分析对象在版本升级后的变化。
- **效果**：分别展示新增对象和增长对象，区分业务对象与公共对象，并结合增长量和代表引用链定位内存回归。

## GlobalHandler对象关联native堆栈

- **作用**：支持 `.heapsnapshot + Native Hook DB` 旧模式，也支持 `.rawheap + .htrace + js_map*.txt` 三合一目录。三合一入口复用同级 `nativeleak-analysis/scripts` 中的 trace_streamer，将 htrace 转为 SQLite DB，再完成快照聚类和 Node ID 地址映射。
- **精确关联**：优先使用含 `addr_id` 的 `native_hook_statistic`。从聚类 Node ID 在 `js_map*.txt` 中取得十六进制地址，规范化为 `0x...` 后依次关联 `data_dict.id -> native_hook_statistic.callchain_id -> native_hook_frame.symbol_id -> data_dict.data`。一个 Node ID 对应的全部地址都参与统计，每个 GlobalHandler 对象最多展示 Native Top 3 栈；该表不含地址字段时再尝试 `native_hook` 或旧版 `native_hook_event`。
- **聚合回退**：数据库只有 `native_hook_statistic` 时，提取 `RES_ARK_GLOBAL_HANDLE` 的未释放数量、大小及调用栈。该结果只代表 GlobalHandle 整体分配来源，不与某个 JS 对象绑定。
- **续跑**：已生成 DB 后可以提供 `--snapshot` 跳过 rawheap 转换，提供 `--cluster-json` 跳过转换和聚类，提供 `--native-hook-db` 跳过 htrace 转换。转换失败时保留成功产物。
