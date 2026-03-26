# 进程管理模块 FAQ（Week 3）

## Q1: Week 3 的进程管理包含哪些能力？

- 实时进程列表
- 条件筛选与排序
- 进程详情
- 停止进程

## Q2: 为什么列表要同时用 websocket 和 `/process/listening`？

- `GET /process/ws` 提供进程主列表真值。
- `POST /process/listening` 提供监听端口集合。
- 移动端按 PID 合并两者，才能在列表卡片里展示完整的“进程 + 端口”信息。

## Q3: 为什么不直接做网络连接独立页面？

- 上游 Web 有 `/hosts/process/network`，但本阶段范围只到：
  - 进程列表
  - 进程详情
  - stop
- 监听与连接信息在详情页中已经有最小闭环，不再扩 Week 3 scope。

## Q4: 停止进程为什么算危险操作？

- `POST /process/stop` 是直接 kill 目标 PID。
- 这可能影响系统服务或业务进程，因此移动端统一走二次确认。

## Q5: 进程状态为什么是本地筛选，不是后端筛选？

- 因为 websocket `type='ps'` 查询真值只支持：
  - `pid`
  - `name`
  - `username`
- `status` 过滤由移动端在收到实时数据后本地执行。

## Q6: 为什么 Process 模块没有复用旧的 `process_models.dart`？

- 旧文件没有生产代码在用，而且字段口径和上游 agent 的实际返回体不一致。
- Week 3 已改为 backend-aligned 的 `ProcessSummary / ProcessDetail / ListeningProcess`。

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
