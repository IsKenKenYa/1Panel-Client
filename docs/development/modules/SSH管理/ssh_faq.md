# SSH管理模块 FAQ（Week 3）

## Q1: Week 3 的 SSH 管理包含哪些能力？

- SSH 服务配置读取与更新
- SSH 服务启停 / 重启 / autoStart
- 原始 `sshdConf` 查看与保存
- SSH 证书列表、创建、编辑、同步、删除
- SSH 登录日志查看与导出
- SSH 会话实时列表与断开

## Q2: 为什么 `SshSessionsPage` 不是走 `/hosts/ssh/*`？

- 因为上游没有独立的 SSH session REST 列表接口。
- 真值来自 `GET /process/ws`，发送 `type='ssh'` 查询。
- 这与 Web 端实现保持一致。

## Q3: 为什么断开 SSH 会话会调用 `process/stop`？

- 上游 Web 端就是按会话对应的 sshd PID 调 `POST /process/stop`。
- 移动端沿用同一条能力链路，不额外发明 “session close” 私有接口。

## Q4: SSH 证书为什么要在仓库里做 Base64？

- 上游前端提交 `passPhrase / publicKey / privateKey` 时会先做 Base64 编码。
- 移动端把这层处理放在 `SSHRepository`，避免 UI 层碰敏感字段协议细节。

## Q5: `Raw File` 区域和普通配置开关有什么区别？

- 普通配置通过 `POST /hosts/ssh/update` 按 key/value 更新。
- `Raw File` 直接读取和保存整个 SSH 配置文件：
  - `POST /hosts/ssh/file`
  - `POST /hosts/ssh/file/update`

## Q6: SSH 日志为什么没有时间范围筛选？

- 因为当前上游请求体真值只有 `info + status + page + pageSize`。
- Week 3 不会发明超出上游的筛选协议。

## Q7: 为什么 websocket 默认用 `operateNode=local`？

- App 当前没有节点选择器。
- core 代理层支持 `operateNode`，但移动端暂时只实现本机节点语义。
- 后续如果 App 引入 node selector，再扩展为用户可选。

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
