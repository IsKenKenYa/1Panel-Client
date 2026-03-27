# 任务日志模块架构设计

## 模块定位

- `task_log` 在信息架构上从属于日志中心
- 不是独立顶级模块
- 目标是提供：
  - 任务日志列表
  - executing count
  - 任务日志详情

## Source of Truth

- `docs/OpenSource/1Panel/frontend/src/api/modules/log.ts`
- `docs/OpenSource/1Panel/frontend/src/views/log/task/index.vue`
- `docs/OpenSource/1Panel/frontend/src/components/log/task/index.vue`
- `lib/api/v2/task_log_v2.dart`
- `lib/api/v2/file_v2.dart`

## 当前接口口径

- `POST /logs/tasks/search`
- `GET /logs/tasks/executing/count`
- `POST /files/read`

其中：

- 列表与执行中计数来自 `task_log_v2`
- 详情正文来自 `/files/read`，使用 `taskID` 驱动按行读取

## 当前移动端结构

- Repository
  - `TaskLogRepository`
- Service
  - `LogsService`
- Provider
  - `TaskLogsProvider`
- Presentation
  - `LogsCenterPage` 的 `Task` tab
  - `TaskLogDetailPage`

## 关键边界

- `TaskLog` 数据模型必须按上游真实字段对齐：
  - `id`
  - `name`
  - `type`
  - `logFile`
  - `status`
  - `errorMsg`
  - `operationLogID`
  - `resourceID`
  - `currentStep`
  - `endAt`
  - `createdAt`
- 不继续沿用旧的虚构字段：
  - `taskType`
  - `taskName`
  - `details`
  - `progress`

## 已知取舍

- 本轮详情页只展示基础元信息和正文日志，不额外做执行参数展开面板
- 不新增单独的 task detail REST 接口适配层

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
