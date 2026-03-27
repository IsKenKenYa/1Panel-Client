# 计划任务与脚本库 FAQ

## 1. Week 4 为什么没有 Cronjob 创建/编辑表单？

Phase 1 计划明确把复杂表单放到 Week 5。Week 4 只交付主链路：

- Cronjob 列表
- 状态切换
- 执行一次
- 执行记录
- Script Library 列表 / 查看代码 / sync / run output

## 2. Cronjob 列表当前支持哪些操作？

- 搜索
- 分组筛选
- 启用 / 停用
- 执行一次
- 打开执行记录
- 对运行中的 shell 任务执行 `stop`

不支持：

- 批量启停
- 批量删除
- 导入导出
- 表单编辑

## 3. 为什么执行记录页没有 Web 端的时间范围筛选？

Week 4 按移动端主链路收口，只保留：

- 状态筛选
- 刷新
- 查看单条日志
- 清理记录

时间范围筛选不是当前 MVP 阻塞项，后续再补。

## 4. Script Library 为什么不是完整终端？

上游 `/core/script/run` 本质是终端式 websocket 会话，但 Week 4 明确不扩 scope 到完整 terminal 管理。当前移动端只做：

- 建立 websocket
- 读取 base64 输出
- 展示只读 run output

不做：

- 终端复用
- 节点切换 UI
- 复杂交互输入

## 5. Script Library 目前为什么还能看到 delete？

Week 4 允许在“文件大小安全、主链路不扩表单”的前提下保留 `delete`。当前实现只对非系统脚本展示删除入口，并统一二次确认。

## 6. Script Library 现在的真实接口真值是什么？

- `POST /core/script/search`
- `POST /core/script/sync`
- `POST /core/script/del`
- `GET /core/script/run`

移动端新实现使用 `ScriptLibraryV2Api + ScriptRunWsClient`。旧 `command_v2.dart` 中脚本库包装仍存在，但不再是 Week 4 UI 的主依赖。

## 7. Cronjob 真实接口真值是什么？

- `POST /cronjobs/search`
- `POST /cronjobs/load/info`
- `POST /cronjobs/status`
- `POST /cronjobs/handle`
- `POST /cronjobs/stop`
- `POST /cronjobs/search/records`
- `POST /cronjobs/records/log`
- `POST /cronjobs/records/clean`
- `GET /cronjobs/script/options`

## 8. Week 4 已覆盖哪些测试？

- API 对齐测试
- 真实环境 API client tests
- script run websocket 契约测试
- Provider tests
- Widget / no-server tests

## 9. 当前离“严格发版门槛”还差什么？

- Script run 的真实环境 websocket 成功流仍依赖环境中存在可安全执行的非交互脚本
- Cronjob `handle` / `records/clean` 属于写操作，严格发布前仍建议在隔离环境补固定 destructive 成功流

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
