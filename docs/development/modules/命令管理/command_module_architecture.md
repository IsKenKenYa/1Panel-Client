# 命令管理模块架构设计

## 模块目标

- 提供快捷命令库与脚本库能力
- 服务于 Phase 1 Week 2 的 `CommandsPage` 与 `CommandFormPage`
- 严格遵循 `Presentation -> State -> Service/Repository -> API/Infra`

## 当前 API 真值

### 命令库
1. `POST /core/commands`
2. `POST /core/commands/list`
3. `POST /core/commands/search`
4. `POST /core/commands/tree`
5. `POST /core/commands/update`
6. `POST /core/commands/del`
7. `POST /core/commands/export`
8. `POST /core/commands/import`

### 脚本库
1. `POST /core/script`
2. `POST /core/script/search`
3. `POST /core/script/update`
4. `POST /core/script/del`
5. `POST /core/script/sync`
6. `GET /cronjobs/script/options`

## 已知漂移说明

- Swagger 中 `command` 仍存在旧注解，尤其是列表与树接口的 GET/路径描述不可靠。
- Week 1 以运行中的上游前端与路由为准，命令列表使用 `POST /core/commands/list`，命令树使用 `POST /core/commands/tree`。

## 分层设计

- `CommandRepository`
  - 封装命令/脚本 API client
  - 负责请求体组装与响应映射
- `CommandService`
  - 负责命令列表、树、导入导出等流程编排
- `CommandsProvider` / `CommandFormProvider`
  - 负责列表态与表单态
- 页面层
  - `CommandsPage`
  - `CommandFormPage`

## Week 2 落地重点

- 命令列表：搜索、分组、复制、发送到终端
- 命令表单：名称、分组、命令预览
- 脚本库：先完成主列表与基础同步入口，不扩历史执行体系

---

**文档版本**: 1.1
**最后更新**: 2026-03-26
