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
- Week 5 review 收口后，Week 5 新页面的用户可见文本、confirm 文案、页面级错误提示统一走 l10n

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
- UI 高层分类：
  - `app`
  - `website`
  - `database`
  - `other`（仅用于承接真实记录类型，不作为主路径扩 scope）
- Provider / Service 显式拆分：
  - `recordType`：保留真实 backup 记录来源，用于 `record/search`
  - `requestType`：恢复提交时传给 `/backups/recover`
- 真实记录类型映射：
  - `app -> app`
  - `website -> website`
  - `mysql / mysql-cluster / mariadb -> database`，UI 归为 `mysql` 家族，但从 records 进入时保留原始 `recordType/requestType`
  - `postgresql / postgresql-cluster -> database`
  - `redis / redis-cluster -> database`
  - `directory / snapshot / log -> other`
- `database` 作为非真实 record type 只用作高层分类；若从外部以 `database` 进入，移动端默认落到 `mysql` 家族
- 当前 recover submit 允许：
  - `app`
  - `website`
  - `mysql / mysql-cluster / mariadb`
  - `postgresql / postgresql-cluster`
  - `redis / redis-cluster`
- 当前 recover submit 不开放：
  - `directory`
  - `snapshot`
  - `log`
  这些类型在移动端保留 record context，并明确展示“当前不可直接恢复”的状态，而不是忽略异常值或让 dropdown 进入非法态
  若后续遇到未知 record type，也保持 `other + raw type` 上下文，不静默改写为 `directory`

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
