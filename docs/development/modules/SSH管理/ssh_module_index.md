# SSH管理模块索引

## 模块定位

SSH 管理是 Phase 1 Week 3 的系统控制主链路，和 `Host Asset`、`Process` 一起构成运维中心的主机侧闭环。

## 子模块结构

| 子模块 | 真值接口 | 主要类型 | 说明 |
|--------|----------|----------|------|
| SSH 设置 | `/hosts/ssh/search` `/hosts/ssh/operate` `/hosts/ssh/update` `/hosts/ssh/file*` | `SshInfo` `SshUpdateRequest` `SshFile*` | 配置、启停、原始文件 |
| SSH 证书 | `/hosts/ssh/cert*` | `SshCertOperate` `SshCertInfo` | 证书列表、创建、编辑、同步、删除 |
| SSH 日志 | `/hosts/ssh/log` `/hosts/ssh/log/export` | `SshLogSearchRequest` `SshLogEntry` | 登录日志查询与导出 |
| SSH 会话 | `/process/ws` `/process/stop` | `SshSessionQuery` `SshSessionInfo` | 实时会话列表与断开 |

## 当前落地

- 页面：
  - `SshSettingsPage`
  - `SshCertsPage`
  - `SshLogsPage`
  - `SshSessionsPage`
- Provider：
  - `SshSettingsProvider`
  - `SshCertsProvider`
  - `SshLogsProvider`
  - `SshSessionsProvider`
- Service / Repository：
  - `SSHService`
  - `SSHRepository`
- 实时层：
  - `ProcessWsClient`

## 路由结构

- `/ssh`
- `/ssh/certs`
- `/ssh/logs`
- `/ssh/sessions`

说明：
- 入口仍只从 `OperationsCenterPage` 进入，不扩底部导航。
- 各页面通过 `SshSectionNavWidget` 做共享导航。

## 重要实现约束

1. `SshSessionsPage` 不走虚构 REST，而是严格复用 `/process/ws`。
2. 会话断开走 `POST /process/stop`，按 PID 结束 sshd 进程。
3. no-server 下页面只显示 `ServerAwarePageScaffold` 的缺省态，不触发 API load。
4. 证书敏感字段 Base64 编码在 `SSHRepository` 完成，不允许页面或 Provider 处理。

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
