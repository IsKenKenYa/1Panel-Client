# 计划任务与脚本库模块架构设计

## 模块定位

- Phase 1 Week 4-5 交付主链路列表与 CronjobForm MVP，不进入 script library create/edit。
- 当前移动端交付页面：
  - `CronjobsPage`
  - `CronjobRecordsPage`
  - `ScriptLibraryPage`
- Week 5 新增：
  - `CronjobFormPage`
  - backup account/records/recover 联动

## Source of Truth

- Cronjob 前端接口：`docs/OpenSource/1Panel/frontend/src/api/modules/cronjob.ts`
- Cronjob Agent 接口：`docs/OpenSource/1Panel/agent/app/api/v2/cronjob.go`
- Cronjob DTO：`docs/OpenSource/1Panel/agent/app/dto/cronjob.go`
- Script Library Core 接口：`docs/OpenSource/1Panel/core/app/api/v2/script_library.go`
- Script Library 路由：`docs/OpenSource/1Panel/core/router/ro_script_library.go`
- Script Library DTO：`docs/OpenSource/1Panel/core/app/dto/script_library.go`
- Script Run Web UI 参考：
  - `docs/OpenSource/1Panel/frontend/src/views/cronjob/library/index.vue`
  - `docs/OpenSource/1Panel/frontend/src/views/cronjob/library/run/index.vue`

## Week 4 API 真值

### Cronjob 主列表

1. `POST /cronjobs/search`
2. `POST /cronjobs/load/info`
3. `POST /cronjobs/status`
4. `POST /cronjobs/handle`
5. `POST /cronjobs/stop`
6. `POST /cronjobs/next`

### Cronjob 执行记录

1. `POST /cronjobs/search/records`
2. `POST /cronjobs/records/log`
3. `POST /cronjobs/records/clean`

### Cronjob 脚本选项

1. `GET /cronjobs/script/options`

### Script Library

1. `POST /core/script/search`
2. `POST /core/script/sync`
3. `POST /core/script/del`
4. `GET /core/script/run`

## 当前移动端实现

### 路由

- `AppRoutes.cronjobs`
- `AppRoutes.cronjobRecords`
- `AppRoutes.cronjobForm`
- `AppRoutes.scripts`

### 分层落点

- API / Infra
  - `CronjobV2Api`
  - `ScriptLibraryV2Api`
  - `ScriptRunWsClient`
- Repository
  - `CronjobRepository`
  - `ScriptLibraryRepository`
- Service
  - `CronjobService`
  - `ScriptLibraryService`
- Provider
  - `CronjobsProvider`
  - `CronjobRecordsProvider`
  - `CronjobFormProvider`
  - `ScriptLibraryProvider`
- Presentation
  - `CronjobsPage`
  - `CronjobRecordsPage`
  - `CronjobFormPage`
  - `ScriptLibraryPage`

## Week 4 页面主链路

### CronjobsPage

- 搜索
- 分组筛选，支持回到 `all groups`
- 卡片列表
- 状态切换
- `handle once`
- `create / edit / delete`
- 进入执行记录
- shell 运行中任务可 `stop`

### CronjobFormPage

- 四段结构：`Basic / Schedule / Target / Policy & Alerts`
- 第一批真实类型：
  - `shell`
  - `curl`
  - `app / website / database / directory / snapshot / log`
- `next` 预览
- create / update / delete
- import/export 仅做 API/test，不做 Week 5 主 UI
- Week 5 review 收口后，`CronjobFormPage` 与相关 widgets 的用户可见文案、页面级错误提示统一走 l10n
  - `Custom spec {index}` 改为参数化 l10n key
  - backup/database/alert method 的未知值 fallback 不再直接透传后端字符串，而是走模块级 l10n
  - 页面级 error code -> l10n 映射保留，未知错误统一落到模块级 fallback 文案

### CronjobRecordsPage

- 记录状态筛选
- 列表刷新 / 下拉刷新
- 记录日志底部 sheet
- 清理记录二次确认

### ScriptLibraryPage

- 搜索
- 分组筛选，支持回到 `all groups`
- 查看代码
- `sync`
- 只读 run output viewer
- `delete` 仅对非系统脚本显示

## 已知取舍

- `ScriptLibraryV2Api` 已拆出给 Week 4 新代码使用；`command_v2.dart` 中仍保留旧脚本库包装，当前视为 legacy wrapper，后续统一清理。
- `/core/script/run` 在移动端只提供只读输出查看，不扩展为完整终端管理。
- `CronjobsPage` 当前不做批量操作、导入导出，也不做分组编辑；这些仍留给后续阶段。
- `CronjobRecordsPage` 按 Week 4 口径只保留状态筛选，不引入 Web 端日期范围筛选。
- `CronjobFormPage` 不覆盖 `clean / ntp / syncIpGroup / cutWebsiteLog / container shell`。

## 测试口径

- API 对齐测试：`test/api_client/phase1_api_alignment_test.dart`
- 真实环境 API tests：
  - `test/api_client/cronjob_api_client_test.dart`
  - `test/api_client/cronjob_form_api_client_test.dart`
  - `test/api_client/script_library_api_client_test.dart`
- WebSocket 契约测试：
  - `test/core/network/script_run_ws_client_test.dart`
- Provider tests：
  - `test/features/cronjobs/providers/*`
  - `test/features/script_library/providers/*`
- Widget tests：
  - `test/features/cronjobs/pages/*`
  - `test/features/script_library/pages/*`

---

**文档版本**: 2.1  
**最后更新**: 2026-03-27
