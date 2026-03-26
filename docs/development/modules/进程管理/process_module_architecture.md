# 进程管理模块架构设计

## 模块目标

- 提供系统进程只读列表、详情与终止能力
- 信息架构上归属 `host/process`，不做独立顶级导航
- 对应 Phase 1 Week 3 的 `ProcessesPage` 与 `ProcessDetailPage`

## 当前 API 真值

1. `POST /process/stop`
2. `GET /process/{pid}`
3. `POST /process/listening`

## 已知漂移说明

- Swagger 对 Process 的覆盖不完整，缺少 `process/listening`
- 上游 agent API 与前端都确认 `POST /process/listening` 存在，因此 Week 1 起以源码与前端为准
- 旧版本地实现中的 `/process/search`、`/process/stats`、`/process/start`、`/process/restart`、`/process/kill` 不属于当前高置信集合

## 请求体口径

- 停止进程请求体使用 `{ PID }`
- 详情通过 path `pid`
- `listening` 无请求体

## 分层设计

- `ProcessRepository`
  - 停止、详情、监听端口进程列表
- `ProcessService`
  - 详情装配与 ports/连接信息整理
- `ProcessesProvider`
  - 列表页状态
- `ProcessDetailProvider`
  - 详情页状态

## Week 3 落地重点

- 列表页以 `process/listening` 和详情接口组合出移动端信息卡片
- 危险操作只有 `stop`，统一复用底部确认 Sheet

---

**文档版本**: 1.1
**最后更新**: 2026-03-26
