# 命令管理模块架构设计

## 模块目标

- Week 2 交付命令管理 MVP，入口固定为 `ServerDetailPage -> OperationsCenterPage -> Commands`。
- 严格遵循 `Presentation -> State -> Service/Repository -> API/Infra`，页面与 Provider 都不直连 `lib/api/v2/`。
- 复用 Week 1 的 `AsyncStatePageBodyWidget`、`GroupSelectorSheetWidget`、`ConfirmActionSheetWidget` 与 `ServerAwarePageScaffold`。

## API 真值

1. `POST /core/commands`：创建命令，body 为 `CommandOperate`
2. `POST /core/commands/list`：返回 `type=command` 的列表/选项数据，Week 2 UI 主列表不直接依赖它
3. `POST /core/commands/search`：主列表搜索接口，使用 `CommandSearchRequest`
4. `POST /core/commands/tree`：保留 client 能力，Week 2 UI 不依赖 tree 渲染主列表
5. `POST /core/commands/update`：更新命令，body 为 `CommandOperate`
6. `POST /core/commands/del`：单条/批量删除，body 为 `ids`
7. `POST /core/commands/export`：返回服务端导出文件路径
8. `POST /core/commands/upload`：上传 CSV，返回导入预览列表
9. `POST /core/commands/import`：最终导入，body 为 `List<CommandOperate>`

## 分层职责

- `CommandRepository`
  - 直接对接 `CommandV2Api`
  - 负责 `CommandSearchRequest`、导入预览、导出路径、删除与创建/编辑调用
- `CommandService`
  - 封装搜索、导入预览分组改写、导出下载保存、`CommandInfo -> CommandOperate` 映射
- `CommandsProvider`
  - 管理搜索词、分组筛选、列表四态、批量删除、导入预览与选择态
- `CommandFormProvider`
  - 管理表单初始化、字段校验、默认分组与保存状态
- 页面层
  - `CommandsPage`：卡片列表、搜索、分组、导入/导出、批量删除
  - `CommandFormPage`：单页表单、等宽命令预览、底部固定保存栏

## Week 2 主链路

| 场景 | 说明 |
|------|------|
| 列表 | 搜索框 + 分组筛选 + 刷新，卡片字段为 `name / group / command preview` |
| 操作 | 卡片支持 `copy / edit / delete`，列表支持批量删除 |
| 导入 | `upload -> preview -> select/apply group -> import` |
| 导出 | `export path -> file download -> FileSaveService` |
| 表单 | 单页输入 `name / group / command`，保存前只校验必填 |

## 约束与取舍

- Week 2 不实现“发送到终端”
- Week 2 不实现 Script Library 页面
- `POST /core/commands/list` 与 `POST /core/commands/tree` 仅保留 API 能力，不作为当前列表渲染真值
- CSV 解析为空或格式异常时直接进入错误/提示态，不进入导入确认流

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
