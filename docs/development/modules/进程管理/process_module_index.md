# 进程管理模块索引

## 模块定位

进程管理是 Phase 1 Week 3 的系统控制能力，和主机资产、SSH 一起构成主机侧运维主链路。

## 子模块结构

| 子模块 | 真值接口 | 主要类型 | 说明 |
|--------|----------|----------|------|
| 进程列表 | `/process/ws` + `/process/listening` | `ProcessListQuery` `ProcessSummary` `ListeningProcess` | 实时列表 + 监听端口补强 |
| 进程详情 | `GET /process/{pid}` | `ProcessDetail` | 全屏详情页 |
| 停止进程 | `POST /process/stop` | `ProcessStopRequest` | 危险操作，统一确认 |

## 当前落地

- 页面：
  - `ProcessesPage`
  - `ProcessDetailPage`
- Provider：
  - `ProcessesProvider`
  - `ProcessDetailProvider`
- Service / Repository：
  - `ProcessService`
  - `ProcessRepository`
- 实时层：
  - `ProcessWsClient`

## 关键实现说明

1. `ProcessesPage` 主列表不是来自 `/process/listening`，而是来自 `/process/ws`。
2. `/process/listening` 只用于把监听端口拼回对应 PID 的卡片展示。
3. 进程详情页使用 `GET /process/{pid}`，不复用 websocket 行数据做伪详情。
4. 当前模块与 dashboard 的 top-process 数据模型无关，Week 3 采用独立 `ProcessSummary / ProcessDetail` 类型，避免和 `dashboard_models.dart` 混名。

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
