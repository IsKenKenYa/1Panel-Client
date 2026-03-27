# 计划任务管理模块索引

## 模块范围

- 本目录当前同时承载：
  - Cronjob
  - Script Library
- 原因：
  - 上游 Web 端二者位于同一 `cronjob` 能力簇
  - Phase 1 Week 4 也按“Cronjob + Script Library 主链路”一起落地

## 当前交付状态

- Week 4 已完成：
  - `CronjobsPage`
  - `CronjobRecordsPage`
  - `ScriptLibraryPage`
- Week 5 待完成：
  - 已完成 `CronjobFormPage`
  - 继续保留更复杂类型到后续周

## 文档清单

- 架构设计：`docs/development/modules/计划任务管理/cronjob_module_architecture.md`
- API 真值：`docs/development/modules/计划任务管理/cronjob_api_analysis.md`
- 开发计划：`docs/development/modules/计划任务管理/cronjob_plan.md`
- FAQ：`docs/development/modules/计划任务管理/cronjob_faq.md`

## 当前代码落点

- API：
  - `lib/api/v2/cronjob_v2.dart`
  - `lib/api/v2/script_library_v2.dart`
- Repository：
  - `lib/data/repositories/cronjob_repository.dart`
  - `lib/data/repositories/cronjob_form_repository.dart`
  - `lib/data/repositories/script_library_repository.dart`
- Service：
  - `lib/features/cronjobs/services/cronjob_service.dart`
  - `lib/features/cronjobs/services/cronjob_form_service.dart`
  - `lib/features/script_library/services/script_library_service.dart`
- Provider：
  - `lib/features/cronjobs/providers/`
  - `lib/features/script_library/providers/`
- 页面：
  - `lib/features/cronjobs/pages/`
  - `lib/features/script_library/pages/`

## 备注

- 旧索引中引用的 `cronjob_pages.md`、`cronjob_data.md`、`cronjob_ops.md`、`cronjob_user_manual.md` 当前仓库并不存在，已从索引移除。
- Script Library 新代码已经切换到 `ScriptLibraryV2Api`；旧 `command_v2.dart` 中的脚本库方法暂保留为 legacy wrapper。
- `CronjobFormPage` 现在使用 backend-aligned form DTO，不再继续扩展 legacy `cronjob_models.dart`。

---

**文档版本**: 2.1  
**最后更新**: 2026-03-27
