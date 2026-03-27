# 备份管理模块开发计划

## Phase 1 周计划对齐

### Week 5 已完成

- `BackupAccountsPage`
- `BackupAccountFormPage`
- `BackupRecordsPage`
- `BackupRecoverPage`
- `BackupRepository`
- `BackupAccountService`
- `BackupRecordService`
- `BackupRecoverService`
- `BackupOauthCallbackService`
- API 对齐测试、真实环境 API tests、Provider tests、Widget tests

## Week 5 交付边界

### 已纳入

- 账户列表、create、edit、delete
- connection test
- refresh token
- browse files
- records 搜索、按 cronjob 搜索、size merge、download、delete
- recover from record
- OAuth callback 基础设施

### 明确未纳入

- `recoverByUpload` 主 UI
- 完整 node selector
- provider 引导文档化流程
- 更深的 bucket/file browser

## 代码结构

- `lib/data/repositories/backup_repository.dart`
- `lib/features/backups/services/`
- `lib/features/backups/providers/`
- `lib/features/backups/pages/`

## 剩余风险

- `OneDrive / GoogleDrive / ALIYUN` 仍需真机 destructive/完整授权成功流验证
- `recover / refresh token` 为 release gate 级写操作
- `info/name` 搜索口径兼容是移动端适配策略，后续若上游统一字段仍需回收

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
