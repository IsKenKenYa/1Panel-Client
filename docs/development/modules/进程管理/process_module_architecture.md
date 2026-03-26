# 进程管理模块架构设计

## 模块目标

- Phase 1 Week 3 交付移动端可评审的进程管理 MVP。
- 信息架构上归属 `host/process`，统一从运维中心进入。
- 提供：
  - 实时进程列表
  - 进程详情
  - 停止进程

## Source of Truth

- REST 真值：
  - `docs/OpenSource/1Panel/agent/router/ro_process.go`
  - `docs/OpenSource/1Panel/agent/app/api/v2/process.go`
  - `docs/OpenSource/1Panel/frontend/src/api/modules/process.ts`
- websocket 真值：
  - `docs/OpenSource/1Panel/agent/utils/websocket/process_data.go`
  - `docs/OpenSource/1Panel/frontend/src/store/modules/process.ts`
  - `docs/OpenSource/1Panel/frontend/src/views/host/process/`

## 当前 API 真值

### REST
1. `POST /process/stop`
2. `GET /process/{pid}`
3. `POST /process/listening`

### Realtime
4. `GET /process/ws`

说明：
- `ProcessesPage` 的主列表真值来自 `/process/ws` 发送 `type='ps'`
- `/process/listening` 只用于补充监听端口信息
- `SshSessionsPage` 也共用 `/process/ws`，但发送 `type='ssh'`

## 分层设计

- API / Infra
  - `ProcessV2Api`
  - `ProcessWsClient`
- Repository
  - `ProcessRepository`
  - 负责详情、停止、监听端口、实时进程流
- Service
  - `ProcessService`
  - 负责把 websocket `ps` 行与 listening 结果按 PID 合并
- Provider
  - `ProcessesProvider`
  - `ProcessDetailProvider`

## Week 3 页面

### ProcessesPage
- 来源：
  - websocket `type='ps'`
  - REST `/process/listening`
- 支持：
  - 筛选 `pid / name / username / status`
  - 排序 `CPU / Memory / Name / PID`
  - 卡片展示 `name / pid / user / status / cpu / memory / connections / listening ports`
  - `stop` 二次确认

### ProcessDetailPage
- 数据来源：`GET /process/{pid}`
- 分段：
  - `Overview`
  - `Memory`
  - `Open Files`
  - `Connections`
  - `Environment`
- 危险操作：
  - `stop`

## 已知边界与取舍

- Week 3 不做独立 `network` 页面；监听与连接信息只在详情页和列表补充展示。
- websocket 轮询策略与 Web 一致，由移动端定时重新发送查询消息，不依赖服务端主动广播。
- no-server 下 Provider 不连接 websocket，也不请求 listening/detail。

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
