# 日志管理模块 FAQ

## 1. 当前移动端日志中心支持哪些日志？

- `Operation`
- `Login`
- `Task`
- `System`

`website logs` 和 `ssh logs` 本轮不在 MVP 范围。

## 2. 为什么 task log 没有独立顶级页面？

Phase 1 Week 6 已明确把 `task_log` 并入日志中心：

- 列表在 `LogsCenterPage` 的 `Task` tab
- 详情在 `TaskLogDetailPage`

这样可以避免信息架构重复，也更贴近上游 Web 的日志中心组织方式。

## 3. 任务日志详情为什么不调用独立详情接口？

因为上游当前没有独立的 task log detail REST 端点。移动端详情页的做法是：

- 元信息来自任务列表项
- 正文内容通过 `taskID` 走 `/files/read` 的按行读取链路

## 4. 系统日志正文是怎么读取的？

流程分两段：

1. `GET /logs/system/files` 获取文件列表
2. `POST /files/read` 按行读取正文

移动端 `SystemLogViewerPage` 复用了这条链路，并通过共享 `LogViewer` 展示文本。

## 5. 当前支持哪些基础操作？

- loading / empty / error / retry
- refresh
- copy
- 基础筛选
- 文本查看

## 6. 当前为什么没有清理日志和导出日志按钮？

API 真值已经保留，但本轮聚焦日志中心的浏览和检索闭环，未把 `clean / export` 纳入主 UI。后续可在不改信息架构的前提下补入。

## 7. no-server 场景下日志页会不会提前打 API？

不会。

- `LogsCenterPage`
- `SystemLogViewerPage`
- `TaskLogDetailPage`

都沿用了 Phase 1 现有页面的 server-aware 初始化方式，在无服务器上下文时不触发加载。

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
