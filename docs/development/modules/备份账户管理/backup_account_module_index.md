# 备份管理模块索引

## 当前范围

- 本目录当前承载：
  - backup account
  - backup records
  - backup recover
- Phase 1 Week 5 已把原计划中部分 Week 6 的 records/recover 主链路前移，一并落地

## 当前交付状态

- Week 5 已完成：
  - `BackupAccountsPage`
  - `BackupAccountFormPage`
  - `BackupRecordsPage`
  - `BackupRecoverPage`
  - `BackupRepository / BackupAccountService / BackupRecordService / BackupRecoverService`
- Week 5 review 收口补充：
  - `BackupRecoverPage` 已对 `app / website / mysql / postgresql / redis / directory / snapshot / log` 做明确类型映射
  - 恢复链路已拆成 `recordType`（records/search）和 `requestType`（recover submit），避免真实记录类型把页面带进非法状态
  - `directory / snapshot / log` 在移动端保留记录上下文，不再把页面打进非法 dropdown 状态；当前仅阻止直接 recover submit
  - Week 5 新页残留用户文案已统一迁移到 l10n
- 后续增强：
  - `recoverByUpload` 主 UI
  - 更完整的 OAuth/provider 引导
  - 更细的 bucket/文件浏览体验

## 文档清单

- 架构设计：`docs/development/modules/备份账户管理/backup_account_module_architecture.md`
- API 真值：`docs/development/modules/备份账户管理/backup_api_analysis.md`
- 开发计划：`docs/development/modules/备份账户管理/backup_account_plan.md`
- FAQ：`docs/development/modules/备份账户管理/backup_account_faq.md`

## 当前代码落点

- API：
  - `lib/api/v2/backup_account_v2.dart`
- Repository：
  - `lib/data/repositories/backup_repository.dart`
- Service：
  - `lib/features/backups/services/`
- Provider：
  - `lib/features/backups/providers/`
- 页面：
  - `lib/features/backups/pages/`

## 备注

- 旧文档里的 `/backup/accounts/*` 口径已经废弃，当前仓库统一以 `/backups/*` 和 `/core/backups/*` 为真值
- legacy [backup_account_page.dart](/Volumes/FanXiangMac/MyOpenSource/Open1PanelApp/lib/features/settings/backup_account_page.dart) 不再是产品入口

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
