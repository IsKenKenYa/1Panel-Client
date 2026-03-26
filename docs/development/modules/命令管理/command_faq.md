# 命令管理模块 FAQ（Week 2 命令库）

## 常见问题

### 1. Week 2 已经支持哪些命令能力？

- `CommandsPage`：搜索、分组筛选、下拉刷新、卡片列表、复制、编辑、删除、批量删除。
- `CommandFormPage`：新建/编辑命令，字段为 `name / group / command`，底部固定保存按钮。
- CSV 导入：`POST /core/commands/upload` 预览后，再通过 `POST /core/commands/import` 确认导入。
- CSV 导出：`POST /core/commands/export` 返回服务端路径，客户端再下载并保存到本地。

### 2. 如何创建或编辑命令？

1. 从 `ServerDetailPage -> OperationsCenterPage -> Commands` 进入命令库。
2. 点击右下角创建按钮，或在卡片上点击 `edit`。
3. 填写 `name`、选择 `group`、输入 `command`。
4. 保存时由 `CommandFormProvider` 校验必填项，并通过 `CommandService -> CommandRepository -> CommandV2Api` 提交。

### 3. 如何管理分组？

- Week 2 没有新增独立顶级分组管理页。
- 命令页顶部的分组筛选入口会打开 `GroupSelectorSheetWidget`，可直接选择、创建或重命名命令分组。
- 导入预览页也可以复用相同分组能力做统一改组。

### 4. 导入和导出分别怎么走？

- 导入：
  1. 选择单个 `.csv` 文件。
  2. 调用 `POST /core/commands/upload` 获取预览数据。
  3. 在 `CommandImportPreviewSheetWidget` 中勾选条目、统一改组后确认导入。
- 导出：
  1. 调用 `POST /core/commands/export` 获取服务端文件路径。
  2. 使用 `FileV2Api.downloadFile` 下载字节。
  3. 通过 `FileSaveService` 保存到本地 CSV。

### 5. 为什么没有“发送到终端”按钮？

- 这是 Week 2 的明确延期项。
- 当前命令库只负责模板管理、导入导出与表单编辑，不做终端预填或会话交接。
- 相关能力会在后续 terminal / SSH 链路完善后统一接入。

### 6. 导入预览为空或格式错误怎么办？

- `CommandsProvider.loadImportPreview` 会把上传异常或空预览直接落到错误提示，不进入确认导入流程。
- 优先检查 CSV 是否至少包含 `name,command` 两列，且内容不为空。
- 若需要批量改组，请在预览成功后再使用 `GroupSelectorSheetWidget` 统一修改 `groupID`。

## 最佳实践

1. 命令内容较长时，优先使用 `CommandFormPage` 的等宽预览确认格式。
2. 删除前先用搜索词和分组缩小范围，再执行批量删除，降低误删风险。
3. 导入前先整理命令命名规范，避免后续列表里出现难以区分的模板。

---

**文档版本**: 2.0
**最后更新**: 2026-03-26
