# 日志管理模块架构设计

## 模块定位

- 日志中心是 Phase 1 Week 6 的运维入口之一。
- 信息架构上采用一个顶级 `LogsCenterPage`，统一承载：
  - `Operation`
  - `Login`
  - `Task`
  - `System`
- `task_log` 作为日志中心的一个子视图实现，不再单独做顶级模块。

## Source of Truth

- Web API：`docs/OpenSource/1Panel/frontend/src/api/modules/log.ts`
- Web 路由：`docs/OpenSource/1Panel/frontend/src/routers/modules/log.ts`
- Web 页面：`docs/OpenSource/1Panel/frontend/src/views/log/`
- 本地客户端：
  - `lib/api/v2/logs_v2.dart`
  - `lib/api/v2/task_log_v2.dart`
  - `lib/api/v2/file_v2.dart`

## Week 6 已落地接口

- `POST /core/logs/operation`
- `POST /core/logs/login`
- `GET /logs/system/files`
- `POST /logs/tasks/search`
- `GET /logs/tasks/executing/count`
- `POST /files/read`
  - 用于 `system` 与 `task` 正文按行读取

## 当前移动端结构

### 路由

- `AppRoutes.logs`
- `AppRoutes.systemLogViewer`
- `AppRoutes.taskLogDetail`

### 分层落点

- Repository
  - `LogsRepository`
  - `TaskLogRepository`
- Service
  - `LogsService`
- Provider
  - `LogsProvider`
  - `SystemLogsProvider`
  - `TaskLogsProvider`
- Presentation
  - `LogsCenterPage`
  - `SystemLogViewerPage`
  - `TaskLogDetailPage`

## 页面职责

### LogsCenterPage

- `DefaultTabController + TabBar + TabBarView`
- 四个 Tab：
  - `Operation`
  - `Login`
  - `Task`
  - `System`
- 每个 tab 都具备：
  - loading
  - empty
  - error
  - retry
  - refresh
  - copy
  - 基础筛选

### SystemLogViewerPage

- 独立页查看系统日志文件
- 顶部提供：
  - Agent/Core 来源切换
  - 文件选择
  - watch 开关
- 正文复用共享 `LogViewer`

### TaskLogDetailPage

- 展示任务元信息：
  - task id
  - task type
  - status
  - current step
  - created at
  - log file
- 正文通过 `taskID` 驱动 `/files/read`
- 不发明新的 task detail REST 接口

## 关键边界

- `task_log` 详情正文并不来自独立详情 API，而是来自任务日志文件读取链路。
- `system` / `task` 正文查看统一复用 `FileReadByLineRequest`，避免在日志模块重复发明文本读取协议。
- no-server 场景下，三个日志页都不提前打 API。

## 已知取舍

- `website` 与 `ssh` 日志暂不纳入日志中心 MVP。
- 日志清理与导出动作暂不开放 UI，只保留后续扩展位。
- 文本查看先优先可读性和筛选，不做更复杂的多源 tail/stream 编排。

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
