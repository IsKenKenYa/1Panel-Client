# filemanagement_app_file_service

## 模块职责

app_file_service（bundle name `@ohos/app_file_service`，subsystem `filemanagement`，SystemAbility ID **5203**，进程 `backup_sa`，动态库 `libbackup_sa.z.so`）是的“应用文件服务”，对外提供两大能力：

1. **备份与恢复子系统（核心）**：通过 `@ohos.file.backup` 命名空间向系统级应用（如克隆、换机）提供 JS API，触发备份/恢复、获取能力文件、管理会话、控制传输速率。其体系由三部分组成——
   - **JS API**：触发备份/恢复、获取能力文件、增量备份；
   - **BackupExtensionAbility**：集成在待备份三方应用内，由 `backup_sa` 调度，负责具体数据打包/解包；
   - **独立进程备份服务 backup_sa（SA 5203）**：调度任务、管理扩展生命周期与并发、协调零拷贝传输、恢复时可选安装应用。
2. **文件分享与文件 URI**：`@ohos.fileshare`（授予 URI 权限）、`@ohos.file.fileuri`（文件路径与 URI 互转）。

SysCap：`SystemCapability.FileManagement.AppFileService`、`SystemCapability.FileManagement.StorageService.Backup`、`SystemCapability.FileManagement.AppFileService.FolderAuthorization`。API 自 since 10（dynamic）/23（static）起提供，标记为 systemapi，调用需声明 `ohos.permission.BACKUP`。

## 目录结构

```
filemanagement_app_file_service/
├── interfaces/
│   ├── api/js/                         # JS 接口声明（d.ts 在 interface_sdk-js 仓）
│   ├── common/include/                 # 公共头（log.h、common_func.h）
│   ├── innerkits/native/
│   │   ├── file_share/                 # 文件分享 native（file_permission.h、file_share.h）
│   │   ├── file_uri/                   # fileuri native（file_uri.h）
│   │   └── remote_file_share/          # 跨设备文件分享
│   ├── inner_api/native/backup_kit_inner/
│   │   ├── ext/ienhance_service.h
│   │   └── impl/                       # BSession* / ServiceClient 实现
│   └── kits/                           # 对外多语言绑定
│       ├── js/backup/                  # ★ NAPI 桥接（@ohos.file.backup）
│       ├── js/file_share/              # NAPI（@ohos.fileshare）
│       ├── js/file_uri/                # NAPI（@ohos.file.fileuri）
│       └── xxx/ ani/ cj/ taihe/        # Native API / ArkTS-ANI / Cangjie / Taihe 绑定
├── frameworks/
│   ├── native/backup_ext/              # 备份扩展 native 框架
│   └── js/backup_ext(_context)/        # BackupExtensionAbility 实现
├── services/backup_sa/                 # ★ 备份恢复服务进程（SA 5203）
│   ├── include/module_ipc/             # service.h、svc_session_manager.h 等
│   ├── include/module_sched/           # sched_scheduler.h
│   ├── include/module_external/        # bms_adapter、sms_adapter、storage_manager_service
│   ├── src/module_ipc/                 # service.cpp、service_incremental.cpp 等
│   ├── src/module_sched/               # sched_scheduler.cpp
│   └── 5203.json                       # SA profile（SA ID 5203）
├── utils/、tools/、test/fuzztest/
```

## 核心文件

- `interfaces/kits/js/backup/module.cpp` — NAPI 模块注册（`nm_modname = "file.backup"`），实例化 4 个 Exporter。
- `interfaces/kits/js/backup/prop_n_exporter.cpp` — 命名空间函数导出（getLocalCapabilities、getBackupInfo、updateTimer、updateSendRate、getBackupVersion、fileSystemServiceRequest）。
- `interfaces/kits/js/backup/prop_n_operation.cpp` — 命名空间函数实现（PropNOperation::Async/DoGetBackupInfo/DoUpdateTimer/DoUpdateSendRate/DoGetBackupVersion/FileSystemServiceRequest）。
- `interfaces/kits/js/backup/session_backup_n_exporter.cpp` — SessionBackup 类 NAPI（appendBundles、getLocalCapabilities、getBackupDataSize、release、cancel、cleanBundleTempDir、getCompatibilityInfo）。
- `interfaces/kits/js/backup/session_restore_n_exporter.cpp` — SessionRestore 类 NAPI（appendBundles、publishFile、getFileHandle(s)、release、cancel、migrateFile、getApkFileHandle）。
- `interfaces/kits/js/backup/session_incremental_backup_n_exporter.cpp` — IncrementalBackupSession 类 NAPI（appendBundles、getLocalCapabilities、getBackupDataSize、release、cancel）。
- `interfaces/kits/js/file_share/fileshare_n_exporter.cpp` — @ohos.fileshare 模块导出（grantUriPermission 等）。
- `interfaces/kits/js/file_share/grant_uri_permission.cpp` — GrantUriPermission::Async → DoGrantUriPermission 实现。
- `interfaces/kits/js/file_uri/file_uri_n_exporter.cpp` — FileUri 类 NAPI（toString、normalize、equals、getFullDirectoryUri 等）。
- `interfaces/kits/js/file_uri/prop_n_exporter.cpp` — fileuri.getUriFromPath 命名空间函数导出。
- `interfaces/kits/js/file_uri/get_uri_from_path.cpp` — GetUriFromPath::Sync 实现（调用 CommonFunc::GetUriFromPath）。
- `interfaces/inner_api/native/backup_kit_inner/impl/b_session_backup.h` — BSessionBackup 内部 API（客户端会话备份）。
- `interfaces/inner_api/native/backup_kit_inner/impl/b_session_restore.h` — BSessionRestore（整包）/ BIncrementalRestoreSession（增量）内部 API。
- `interfaces/inner_api/native/backup_kit_inner/impl/b_incremental_backup_session.h` — BIncrementalBackupSession 内部 API。
- `interfaces/inner_api/native/backup_kit_inner/impl/service_client.h` — ServiceClient 客户端 IPC 代理。
- `services/backup_sa/include/module_ipc/service.h` — 备份服务 SystemAbility 主体（SA 5203，继承 ServiceStub）。
- `services/backup_sa/src/module_ipc/service.cpp` — 服务实现与 IPC 派发（AppFileReady、AppDone、GetFileHandle、LaunchBackupExtension 等）。
- `services/backup_sa/include/module_ipc/svc_session_manager.h` — 会话生命周期管理。
- `services/backup_sa/include/module_sched/sched_scheduler.h` — 备份/恢复并发调度器。
- `frameworks/js/backup_ext/ext_backup_impl.cpp` — BackupExtensionAbility 框架实现。
- `interface_sdk-js/api/@ohos.file.backup.d.ts` — @ohos.file.backup 接口声明（错误码与 API 面）。
- `interface_sdk-js/api/@ohos.fileshare.d.ts` — @ohos.fileshare 接口声明。
- `interface_sdk-js/api/@ohos.file.fileuri.d.ts` — @ohos.file.fileuri 接口声明。
