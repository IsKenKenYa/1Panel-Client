# SSH管理模块架构设计

## 模块目标

- Phase 1 Week 3 交付系统 SSH 管理 MVP，入口固定为 `ServerDetailPage -> OperationsCenterPage -> SSH`。
- 覆盖四个可评审页面：`SshSettingsPage`、`SshCertsPage`、`SshLogsPage`、`SshSessionsPage`。
- 严格遵循 `Presentation -> State -> Service/Repository -> API/Infra`，页面与 Provider 不直连 `lib/api/v2/`。

## Source of Truth

- SSH REST 真值：
  - `docs/OpenSource/1Panel/agent/router/ro_host.go`
  - `docs/OpenSource/1Panel/agent/app/api/v2/ssh.go`
  - `docs/OpenSource/1Panel/frontend/src/api/modules/host.ts`
  - `docs/OpenSource/1Panel/frontend/src/views/host/ssh/`
- SSH session 实时真值：
  - `docs/OpenSource/1Panel/agent/router/ro_process.go`
  - `docs/OpenSource/1Panel/agent/utils/websocket/process_data.go`
  - `docs/OpenSource/1Panel/frontend/src/views/host/ssh/session/index.vue`

## 当前 API 真值

### SSH 配置 / 文件 / 证书 / 日志
1. `POST /hosts/ssh/search`
2. `POST /hosts/ssh/operate`
3. `POST /hosts/ssh/update`
4. `POST /hosts/ssh/file`
5. `POST /hosts/ssh/file/update`
6. `POST /hosts/ssh/cert`
7. `POST /hosts/ssh/cert/update`
8. `POST /hosts/ssh/cert/search`
9. `POST /hosts/ssh/cert/delete`
10. `POST /hosts/ssh/cert/sync`
11. `POST /hosts/ssh/log`
12. `POST /hosts/ssh/log/export`

### SSH 会话
- `GET /process/ws`
- `POST /process/stop`

说明：
- 上游没有独立 `SSH session REST list`。
- `SshSessionsPage` 的数据真值来自 `/process/ws`，发送 `type='ssh'`、`loginUser`、`loginIP`。

## 数据与分层设计

- API / Infra
  - `SshV2Api`：承接 `/hosts/ssh/*`
  - `ProcessWsClient`：承接 `/process/ws`，统一生成 `1Panel-Token` / `1Panel-Timestamp` 并默认 `operateNode=local`
- Repository
  - `SSHRepository`
  - 负责 SSH 配置、原始文件、证书、日志、会话流，以及通过 `process/stop` 结束会话
- Service
  - `SSHService`
  - 负责导出日志下载、配置值映射、会话流编排、错误归一化
- Provider
  - `SshSettingsProvider`
  - `SshCertsProvider`
  - `SshLogsProvider`
  - `SshSessionsProvider`

## Week 3 页面规划

### SshSettingsPage
- 顶部复用 `SshSectionNavWidget`
- 分段：
  - `Service`
  - `Authentication`
  - `Network`
  - `Raw File`
- 主操作：
  - `start / stop / restart`
  - `autoStart enable / disable`
  - 更新端口、监听地址、root 登录、密码认证、公钥认证、UseDNS
  - 加载 / 保存原始 `sshdConf`

### SshCertsPage
- 卡片字段：
  - `name`
  - `encryptionMode`
  - `description`
  - `createdAt`
- 主操作：
  - `create`
  - `edit`
  - `sync`
  - `delete`
- 创建 / 编辑通过全屏 bottom sheet 承载，不新增顶级路由

### SshLogsPage
- 搜索条件：
  - `info`
  - `status = All / Success / Failed`
- 列表字段：
  - `address`
  - `port`
  - `user`
  - `authMode`
  - `status`
  - `date`
  - `message`
- 主操作：
  - `refresh`
  - `copy`
  - `export`

### SshSessionsPage
- 通过 `process/ws` 获取活跃 SSH 会话
- 查询体：
  - `type='ssh'`
  - `loginUser`
  - `loginIP`
- 列表字段：
  - `username`
  - `terminal`
  - `host`
  - `loginTime`
  - `pid`
- 主操作：
  - `disconnect`，底层调用 `POST /process/stop`

## 已知边界与取舍

- Week 3 不做 Web terminal 页面，`terminal_page.dart` 不作为本模块功能上限，也不在本周扩展。
- `operateNode` 当前统一固定为 `local`，因为 App 里还没有节点选择器。
- SSH session 实时列表与进程实时列表共用 `/process/ws`，这是上游当前设计，不是移动端私有折中。
- SSH 日志遵循上游请求体，仅支持 `info + status + page + pageSize`，本周不发明额外 time range。

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
