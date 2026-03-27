# 备份管理模块架构设计

## 模块定位

- Phase 1 Week 5 交付备份主链路：
  - `BackupAccountsPage`
  - `BackupAccountFormPage`
  - `BackupRecordsPage`
  - `BackupRecoverPage`
- `/backups` 直接进入账户页，页内再分流到 `Records` / `Recover`
- 继续遵守 `Presentation -> State -> Service/Repository -> API/Infra`

## Source Of Truth

- Agent/private backup：
  - `docs/OpenSource/1Panel/agent/router/backup.go`
  - `docs/OpenSource/1Panel/agent/app/api/v2/backup.go`
  - `docs/OpenSource/1Panel/agent/app/dto/backup.go`
- Core/public backup：
  - `docs/OpenSource/1Panel/core/router/ro_backup.go`
  - `docs/OpenSource/1Panel/core/app/api/v2/backup.go`
  - `docs/OpenSource/1Panel/core/app/dto/backup.go`
- Web 行为：
  - `docs/OpenSource/1Panel/frontend/src/api/modules/backup.ts`
  - `docs/OpenSource/1Panel/frontend/src/api/interface/backup.ts`
  - `docs/OpenSource/1Panel/frontend/src/views/setting/backup-account/`
  - `docs/OpenSource/1Panel/frontend/src/views/cronjob/cronjob/backup/index.vue`

## Week 5 已落地接口

### 账户
1. `GET /backups/local`
2. `POST /backups/search`
3. `GET /backups/options`
4. `POST /backups`
5. `POST /backups/update`
6. `POST /backups/del`
7. `POST /backups/conn/check`
8. `POST /backups/buckets`
9. `POST /backups/refresh/token`
10. `POST /core/backups`
11. `POST /core/backups/update`
12. `POST /core/backups/del`
13. `POST /core/backups/refresh/token`
14. `GET /core/backups/client/:clientType`

### 记录
1. `POST /backups/record/search`
2. `POST /backups/record/search/bycronjob`
3. `POST /backups/record/size`
4. `POST /backups/record/download`
5. `POST /backups/record/del`
6. `POST /backups/record/description/update`
7. `POST /backups/search/files`

### 备份/恢复
1. `POST /backups/backup`
2. `POST /backups/recover`
3. `POST /backups/recover/byupload`
4. `POST /backups/upload`

## 关键口径

- 运行时真值以 `/backups/conn/check` 为准，不使用旧 Swagger 注释里的 `/backups/check`
- 搜索请求体对 `info/name` 漂移做兼容：移动端统一同值双写
- `accessKey / credential` 的 Base64 编码在 Repository 层完成
- 支持节点参数的 backup/recover/record 写操作默认使用 `operateNode=local`
- `LOCAL` 账户视为内置只读项，不提供 create/edit/delete

## Week 5 页面主链路

### BackupAccountsPage
- 搜索
- type filter
- 列表卡片
- `edit / test / refresh token / browse files / delete`
- `Records / Recover` 快捷入口

### BackupAccountFormPage
- 四段结构：`Basic / Credentials / Storage / Verify`
- `OneDrive / GoogleDrive`：
  - 外部浏览器授权
  - `onepanel://backup/oauth` 回跳
  - callback 失败时允许手动回填 `code`
- `ALIYUN`：
  - token JSON 解析 `drive_id / refresh_token`

### BackupRecordsPage
- 通用搜索模式
- 按 cronjob 搜索模式
- `record/search + record/size` 拼卡片数据
- `download / delete / recover`

### BackupRecoverPage
- 只做 `From record`
- 三步：`Resource / Record / Confirm`
- Week 5 UI 只开放：
  - `app`
  - `website`
  - `database`

## 已知取舍

- `recoverByUpload` 本周只保留 API/service/test 闭环，不开放主 UI
- `OneDrive / GoogleDrive` 已补 callback 基础设施，但严格 release 仍需真机完整授权成功流验证
- `features/settings/backup_account_page.dart` 为 legacy 薄页，不再作为主入口

## 测试口径

- API 对齐：`test/api_client/phase1_api_alignment_test.dart`
- 真实环境 API：
  - `test/api_client/backup_account_api_test.dart`
  - `test/api_client/backup_api_client_test.dart`
- Provider：
  - `test/features/backups/providers/*`
- Widget：
  - `test/features/backups/pages/*`

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
