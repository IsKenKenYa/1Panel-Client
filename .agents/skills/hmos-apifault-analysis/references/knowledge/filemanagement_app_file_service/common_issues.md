# filemanagement_app_file_service 常见问题模式

> 错误码以 `@ohos.file.backup.d.ts` / `@ohos.fileshare.d.ts` 实际声明的 135xxxxx / 136xxxxx / 139xxxxx / 143xxxxx 段为准。括号内为历史等价码（500xxx / 900xxx / 600xxx），便于匹配旧日志。

## 一、权限问题（201 / 202 / 900012）

- **201 — Permission verification failed**
  - 原因：调用方缺少 `ohos.permission.BACKUP`，或 `AccessTokenKit::VerifyAccessToken` 校验失败。
  - 排查：确认调用方 `module.json5` 声明了 `ohos.permission.BACKUP`（system_grant，系统权限）；确认调用方为系统应用。NAPI 入口统一在 `SAUtils::CheckBackupPermission()` 处拦截，命中即抛 `E_PERMISSION`。

- **202 — 非系统应用调用系统 API**
  - 原因：备份相关 API 全部为 `@systemapi`，三方应用不可调用。
  - 排查：`SAUtils::IsSystemApp()` 返回 false；需将调用方打包为系统应用或换用系统级入口（如克隆应用）。

- **900012 — Permission denied（fileshare）**
  - 原因：`grantUriPermission` 仅允许系统应用调用。
  - 排查：`FileShare::GrantUriPermission is not System App!` 日志。

## 二、参数问题（401 / 13900020 / 900020）

- **401 — Parameter error**
  - 原因：必填参数缺失、类型不符或校验失败。常见于 `appendBundles` 传入非字符串数组、`getFileHandle` 的 `fileMeta` 缺 `bundleName`、`updateSendRate` 的 `sendRate` 非整数。
  - 排查：查 NAPI 层 `VerifyParamSuccess` / `VerifyAppendBundlesParam` / `VerifyPublishFileParam` 抛出的具体信息；注意 `bundleNames` 与 `bundleInfos` 数量必须一致。

- **13900020 / 900020 — Invalid argument（EINVAL）**
  - 原因：fd 无效（`fcntl(fd, F_GETFD) == -1`）、`remoteCapabilitiesFd` 已关闭、`triggerType`/`writeSize`/`waitTime` 超出 `fileSystemServiceRequest` 范围。
  - 排查：fileshare 场景下表现为 "Invalid tokenID"；确认 fd 来自 `getLocalCapabilities` 且未被提前 close。

## 三、IPC / 服务问题（13600001 / 600001 / 14300001 / 300001）

- **13600001 / 600001 — IPC error**
  - 原因：`backup_sa`（SA ID **5203**，进程 `backup_sa`，动态库 `libbackup_sa.z.so`）未启动或代理获取失败；客户端 `ServiceClient` 通过 samgr 拉起服务超时。
  - 排查：
    1. `hilog | grep backup_sa` 确认进程是否存在；
    2. 查 SA profile `services/backup_sa/5203.json`，确认 `run-on-create:false`、按需拉起条件 `usual.event.USER_UNLOCKED` 且 `persist.backupservice.workstatus=true`；
    3. `ps -ef | grep backup_sa` 与 `hidumper -s 5203` 确认服务状态。

- **14300001 / 300001 — fileshare IPC error**
  - 原因：`grantUriPermission` 经 datashare 连接失败（`InsertByDatashare connect to datashare failed!`）。
  - 排查：确认 datashare 服务正常、URI 前缀合法。

## 四、I/O 与空间问题（13900005 / 13900025 / 900005 / 900025）

- **13900005 / 900005 — I/O error（EIO）**
  - 原因：临时能力文件读写失败、扩展沙箱目录不可写、零拷贝 fd 传输中断。
  - 排查：关注 `onFileReady` 回调中携带的 `system errno`；查 SELinux 是否拒绝 `backup_sa` 访问目标路径。

- **13900025 / 900025 — No space left on device（ENOSPC）**
  - 原因：备份/恢复临时目录或目标分区空间不足。
  - 排查：检查 `data/service/el2/.../backup/` 临时目录与恢复目标分区剩余空间；必要时调小备份范围或清理 `cleanBundleTempDir`。

## 五、备份扩展生命周期问题

- **13500001 / 500001 — 应用未被加入备份/恢复**
  - 原因：`appendBundles` 传入的 `bundleName` 未注册到当前会话，或会话已 `release`。`onBundleBegin` 回调常见。
  - 排查：确认 `bundlesToBackup` 列表与会话状态；避免 release 后继续操作。

- **13500002 / 500002 — 启动应用扩展失败**
  - 原因：目标应用的 `BackupExtensionAbility` 未在 `module.json5` 配置，或 `LaunchBackupExtension(bundleName)` 调度失败（BMS 找不到扩展）。
  - 排查：`bm dump -n <bundleName>` 确认扩展存在；查 `bms_adapter` 日志。

- **13500003 / 500003 — 备份/恢复超时**
  - 原因：扩展处理时间超过默认超时。`onBundleEnd` 回调常见。
  - 排查：使用 `backup.updateTimer(bundleName, timeout)` 调大超时；优化扩展内打包/解包逻辑。

- **13500004 / 500004 — 应用扩展死亡**
  - 原因：`BackupExtensionAbility` 进程崩溃或被系统杀死。`onBundleEnd` 回调常见。
  - 排查：抓取 faultlog（AppFreeze / CPP_CRASH）定位扩展崩溃根因。

- **13500006 / 500006 — Tar 错误**
  - 原因：备份打包（tar）失败，常见于文件被占用、权限拒绝、路径过长。`onProcess` 回调常见。
  - 排查：查 `b_tar` / `BFile` 日志；确认待备份文件可读。

- **13500008 / 500008 — Untar 错误**
  - 原因：恢复解包（untar）失败，常见于数据包损坏、格式不匹配、目标路径冲突。`onProcess` 回调常见。
  - 排查：校验备份包完整性；确认目标路径可写且无残留。

## 六、其它

- **13500011 / 13500012 — cancel 返回码**
  - 13500011：取消失败（任务状态不允许取消）；13500012：无此任务。
  - 排查：`SessionBackup.cancel` / `SessionRestore.cancel` 直接返回 int，非异常抛出。

- **onBackupServiceDied 回调触发**
  - 现象：`GeneralCallbacks.onBackupServiceDied` 被调用，会话失效。
  - 原因：`backup_sa` 进程异常退出（OOM、崩溃）。客户端通过 `ServiceClient::RegisterBackupServiceDied` 监听。
  - 排查：抓取 `backup_sa` 的 faultlog；查内存与崩溃日志。
