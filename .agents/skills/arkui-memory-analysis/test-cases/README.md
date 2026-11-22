# Test Cases

## 触发测试

| 用例 | 输入 | 预期 |
|---|---|---|
| 源码含 5 类反模式 | .ets 文件含 List ForEach + Tabs 无 cachedMaxCount + preloadItems + Canvas 渐变 + 布局深嵌套 | 每类至少 1 条命中 |
| 空输入 | 无反模式的 .ets 文件 | 输出"未发现已知故障" |
| Dump 含不可见页面 | .dump 文件含 VisibleAndActive=0 的大子树 | 命中 invisible_page |
| Dump 含 Tabs 缓存 | .dump 文件含多个不可见 TabContent | 命中 tabs_cache_not_released |

详细测试用例见 [functional.md](functional.md) 和 [trigger.md](trigger.md)。

## 功能验收

| 用例 | 输入 | 预期 |
|---|---|---|
| schema 输出 | 任意有效输入 | JSON schema 含 hotspot_type/severity/location/description/suggestion |
| 报告生成 | dump + source schema | Markdown 报告含 7 章：汇总/可视化工具推荐/热点分布/详细诊断/优化建议/schema/闭环 |
| 可视化查看指引 | dump 侧 finding | 每条含"可视化查看"字段，指引在 ArkUIDumpViewer 中的操作 |
