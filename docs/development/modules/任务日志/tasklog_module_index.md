# 任务日志模块索引

## 当前定位

- Phase 1 Week 6 起，`task_log` 不再作为独立顶级模块推进。
- 当前统一并入日志中心：
  - 列表位于 `LogsCenterPage` 的 `Task` tab
  - 详情位于 `TaskLogDetailPage`

## 当前交付状态

- Week 6 已完成：
  - `TaskLogRepository`
  - `TaskLogsProvider`
  - `TaskLogDetailPage`
  - `task search / executing count` API 对齐
  - no-server / provider / widget / API client tests
- 关键口径：
  - 列表数据来自 `task_log_v2.dart`
  - 正文详情不发明新 REST 接口，而是复用 `files/read` 按行查看

## 与日志管理模块的关系

- `task_log` 作为日志中心的子域推进
- 文档上保留本目录，是为了说明 task logs 的独立真值与已知取舍
- 产品入口不再新增单独的 task log 顶级路由

## 剩余风险

- 任务日志的导出/清理动作仍未进入移动端主 UI
- 大日志量场景下，文本查看仍有继续优化空间

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
