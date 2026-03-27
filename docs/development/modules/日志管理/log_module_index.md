# 日志管理模块索引

## 当前范围

- Phase 1 Week 6 将 `logs + task_log` 统一收口为日志中心。
- 当前移动端只覆盖：
  - operation logs
  - login logs
  - task logs
  - system log files
- 明确不在本轮范围：
  - website logs
  - ssh logs
  - log clean / export UI

## 当前交付状态

- Week 6 已完成：
  - `LogsCenterPage`
  - `SystemLogViewerPage`
  - `TaskLogDetailPage`
  - `LogsRepository`
  - `TaskLogRepository`
  - `LogsService`
  - `LogsProvider`
  - `SystemLogsProvider`
  - `TaskLogsProvider`
- 关键实现口径：
  - `task_log` 不再做独立顶级模块，统一并入 `logs/task`
  - `operation / login / task / system` 采用一个日志中心入口，4 Tab 聚合
  - `system` 与 `task` 的正文查看复用 `/files/read` 按行读取链路和共享 `LogViewer`

## 代码落点

- API：
  - `lib/api/v2/logs_v2.dart`
  - `lib/api/v2/task_log_v2.dart`
  - `lib/api/v2/file_v2.dart`
- Repository：
  - `lib/data/repositories/logs_repository.dart`
  - `lib/data/repositories/task_log_repository.dart`
- Service：
  - `lib/features/logs/services/logs_service.dart`
- Provider：
  - `lib/features/logs/providers/`
- 页面：
  - `lib/features/logs/pages/`

## 已知取舍

- `website logs`、`ssh logs` 在上游 Web 端存在，但本轮不进入移动端日志中心 MVP。
- `clean logs` / `export logs` 保留 API 真值，不做本轮主 UI。
- `system` / `task` 正文按行查看优先保证可读性、refresh、watch、copy，不在本轮扩展复杂 tail 策略。

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
