# 计划任务管理模块架构设计

## 模块目标

- 提供调度中心主链路，覆盖任务列表、状态、一次性执行、记录查看
- 对应 Phase 1 Week 4 与 Week 5 的 `CronjobsPage`、`CronjobFormPage`
- 与脚本库、备份记录、任务日志形成联动

## 当前 API 真值

### 任务管理
1. `POST /cronjobs`
2. `POST /cronjobs/update`
3. `POST /cronjobs/del`
4. `POST /cronjobs/search`
5. `POST /cronjobs/load/info`
6. `POST /cronjobs/group/update`
7. `POST /cronjobs/status`
8. `POST /cronjobs/handle`
9. `POST /cronjobs/stop`
10. `POST /cronjobs/next`

### 执行记录
1. `POST /cronjobs/search/records`
2. `POST /cronjobs/records/log`
3. `POST /cronjobs/records/clean`

### 脚本联动
1. `GET /cronjobs/script/options`

## 已知漂移说明

- 旧文档与旧 client 里存在 `GET /cronjobs/{id}`、`POST /cronjobs/run`、`POST /cronjobs/enable`、`POST /cronjobs/disable`、`GET /cronjobs/status` 等过时口径。
- 当前实现以 `load/info`、`handle`、`status` 为准。

## 分层设计

- `CronjobRepository`
  - 列表、详情、状态、一键执行、记录查询
- `CronjobService`
  - 列表和记录页的组合逻辑
- `CronjobFormService`
  - 表单装配、下一次执行时间预计算
- Provider
  - `CronjobsProvider`
  - `CronjobFormProvider`
  - `CronjobRecordsProvider`

## Week 4-5 落地重点

- Week 4：主列表、状态切换、run once、records 入口、脚本库主链路
- Week 5：复杂表单、分组复用、任务类型分步配置

---

**文档版本**: 1.1
**最后更新**: 2026-03-26
