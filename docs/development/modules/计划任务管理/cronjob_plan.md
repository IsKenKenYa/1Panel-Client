# 计划任务与脚本库开发计划

## Phase 1 周计划对齐

### Week 4 已完成

- `CronjobsPage`
- `CronjobRecordsPage`
- `ScriptLibraryPage`
- `CronjobRepository / Service / Provider`
- `ScriptLibraryRepository / Service / Provider`
- `ScriptRunWsClient`
- API 对齐测试、真实环境 API client tests、Provider tests、Widget tests

### Week 5 已完成

- `CronjobFormPage`
- Cronjob create / update / delete UI
- `next preview`
- backup account/records/recover 联动
- Week 5 review closeout：
  - `CronjobFormPage` 残留硬编码文案与错误提示已清到 l10n
  - backup/database/alert method 的未知值与页面级未知错误已统一走模块级 l10n fallback

## Week 4 交付边界

### 已纳入

- Cronjob 列表
- Cronjob 状态切换
- Cronjob handle once
- Cronjob 记录列表与日志查看
- Cronjob 记录清理
- Script Library 列表
- Script code preview
- Script sync
- Script run output viewer

### 明确未纳入

- Cronjob create / edit 表单
- Cronjob 批量操作
- Script create / edit 页面
- 完整 terminal 管理

## 代码结构

- `lib/data/repositories/cronjob_repository.dart`
- `lib/data/repositories/script_library_repository.dart`
- `lib/features/cronjobs/`
- `lib/features/script_library/`
- `lib/core/network/script_run_ws_client.dart`

## 收口标准

Week 5 判定完成需要同时满足：

- 路由已从 placeholder 替换为真实页面
- no-server 场景不触发 API load
- `flutter analyze` 通过
- `dart run test_runner.dart unit` 通过
- `dart run test_runner.dart ui` 通过
- `requirement_tracking_matrix` / `api_coverage` / 模块文档已同步

## 剩余风险

- Script run 真实环境成功流依赖目标环境里存在可安全执行的脚本
- Cronjob destructive create/update/delete/import/export 仍需要隔离环境兜底验证
- 旧 `command_v2.dart` 中仍保留脚本库 legacy wrapper，后续可继续清理

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
