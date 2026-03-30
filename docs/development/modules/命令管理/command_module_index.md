# 命令管理模块索引

## 模块定位

命令管理是 Phase 1 Week 2 的运维中心主链路之一。Week 1 已完成入口、Group 底座与 API 口径收敛，Week 2 将 `/commands` 与 `/commands/form` 从占位页替换为可评审 MVP。

## 子模块结构

| 子模块 | 端点数 | API 客户端 | 数据模型 | 说明 |
|--------|--------|------------|----------|------|
| 命令库 | 9 | `command_v2.dart` | `command_models.dart` + `tool_models.dart` | 覆盖 `create/list/search/tree/update/del/export/upload/import` |
| 脚本库 | 5 | `script_library_v2.dart` + `script_run_ws_client.dart` | `script_library_models.dart` | Week 4 已独立交付，详见 `docs/development/modules/脚本库管理/` |

## 已有落地

- `CommandsPage`
  - 搜索框、分组筛选、刷新、导入、导出
  - 卡片式列表，支持拷贝、编辑、删除、批量删除
- `CommandFormPage`
  - 单页表单
  - 命令内容等宽预览
  - 底部固定保存栏
- `CommandsProvider`
  - 维护 `CommandSearchRequest`
  - 维护导入预览、选择态与删除流
- `CommandService`
  - 封装 `searchCommands`
  - 封装 `exportCommandsCsv`
  - 封装导入预览分组改写与 `toOperate`

## 接口对齐说明

1. `POST /core/commands`：创建命令
2. `POST /core/commands/list`：返回 `type=command` 的列表数据，当前 UI 不直接渲染
3. `POST /core/commands/search`：Week 2 主列表真值
4. `POST /core/commands/tree`：保留 client 能力，当前 UI 不依赖 tree
5. `POST /core/commands/update`：更新命令
6. `POST /core/commands/del`：接收 `ids`
7. `POST /core/commands/export`：返回文件路径，随后走下载与本地保存
8. `POST /core/commands/upload`：返回导入预览
9. `POST /core/commands/import`：提交最终导入

## 契约偏差状态

- 已确认偏差：
  - Swagger 快照中 `tree/command` 存在 `GET` 标注
  - 运行时路由与客户端执行均以 `POST` 为真值
- 当前策略：客户端严格 `POST`，不做 `GET` 回退。
- 证据来源：
  - 路由：`docs/OpenSource/1Panel/core/router/command.go`
  - 注解：`docs/OpenSource/1Panel/core/app/api/v2/command.go`
  - Swagger：`docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
  - 客户端：`lib/api/v2/command_v2.dart`
- issue 跟踪：
  - 上游 issue：`1Panel-dev/1Panel#12363`
  - 本仓 issue：`IsKenKenYa/1Panel-Client#6`

## 链路同步检查

- API 契约变更后，必须同步更新 Repository/Service/Provider/Page/测试/模块文档。
- 若任一链路未更新，模块不得进入“完成”状态。

## 后续计划

1. 后续周再评估“发送到终端”交接能力
2. `command_v2.dart` 中残留的脚本库 helper 视为 legacy wrapper，不再作为当前 UI 真值

---
**文档版本**: 2.0
**最后更新**: 2026-03-27
