# filemanagement_dfs_service 概览

## 模块职责

`filemanagement_dfs_service`（@ohos/dfs_service，subsystem: filemanagement，kit: CoreFileKit）是**分布式文件服务**模块，提供两大能力：

1. **跨设备分布式文件访问** — 基于内核堆叠文件系统 **hmdfs**（Hybrid Mobile Distributed File System）挂载，叠加 **分布式软总线 dsoftbus** 完成动态组网、设备上下线、P2P 文件/资产收发，实现多设备间文件的透明访问与传输。
2. **云文件同步** — 对接华为云盘（Drive Kit）与第三方云盘，提供图库（Gallery）端云同步、应用文件端云同步、云文件下载/缓存、批量下载、文件版本管理、存储空间优化、全量下载（降级下载）等能力。

模块以四个常驻 System Ability（SA）形态对外提供服务：`distributedfiledaemon`（分布式文件 daemon，uid 1009）、`cloudfileservice`（云同步 SA，又称 cloudsyncservice）、`cloudfiledaemon`（云文件 daemon，uid 1009）、`clouddiskservice`（第三方云盘 SA，uid 6161）。对外通过 NAPI（@ohos.file.cloudSync / cloudSyncManager）、Native API（@ohos.file.cloudDiskManager）、ANI（ArkTS）、Inner API 多层接口暴露能力。

## 简化目录树（3 层）

```
filemanagement_dfs_service/
├── interfaces/                      # 对外接口层
│   ├── kits/
│   │   ├── js/                      # NAPI 接口
│   │   │   ├── cloudfilesync/       # @ohos.file.cloudSync (GallerySync/Download/FileSync/CloudFileCache/FileVersion)
│   │   │   ├── cloudsyncmanager/    # @ohos.file.cloudSyncManager (系统 API)
│   │   │   └── ani/                 # ArkTS Native Interface (file_cloud_sync/manager)
│   │   └── xxx/
│   │       └── clouddiskmanager/    # @ohos.file.cloudDiskManager (libohclouddiskmanager.so)
│   └── inner_api/native/            # Inner API
│       ├── cloudsync_kit_inner/     # 云同步内部 kit (cloud_sync_manager.h)
│       ├── clouddiskservice_kit_inner/  # 第三方云盘内部 kit
│       ├── cloud_daemon_kit_inner/  # 云 daemon 内部 kit
│       └── cloud_file_kit_inner/    # 云文件内部 kit
├── frameworks/native/               # Inner API 实现 + lite 实现
│   ├── cloudsync_kit_inner/         # CloudSyncManager 实现 (IPC proxy → SA)
│   ├── clouddiskservice_kit_inner/
│   ├── cloud_daemon_kit_inner/
│   ├── cloud_file_kit_inner/
│   └── distributed_file_inner/      # 分布式文件内部实现
├── services/                        # 四个 SA 服务端实现
│   ├── distributedfiledaemon/       # 分布式文件 daemon (88 cpp: ipc/network/softbus/mountpoint/device/channel_manager/multiuser/dfx)
│   ├── cloudsyncservice/            # 云同步 SA (cycle_task/sync_rule/transport/ipc)
│   ├── cloudfiledaemon/             # 云文件 daemon
│   ├── clouddiskservice/            # 第三方云盘 SA (ipc/monitor/sync_folder/seccomp_policy)
│   └── clouddisk_database/          # 第三方云盘数据库
└── utils/log/include/dfs_error.h    # 错误码体系（内部码 ↔ JS/xxx 对外码映射）
```

## 核心文件清单

| 文件（相对模块根） | 用途 |
| --- | --- |
| `utils/log/include/dfs_error.h` | 错误码体系：内部枚举 CloudSyncServiceErrCode、JsErrCode（对外码）、errCodeTable（内部→对外映射）、softbus 错误转换 |
| `interfaces/kits/js/cloudfilesync/cloud_sync_n_exporter.cpp` | @ohos.file.cloudSync NAPI 模块注册（RegisterModule），导出 getFileSyncState/getCoreFileSyncState/optimizeStorage/startOptimizeSpace/stopOptimizeSpace/registerChange/unregisterChange 及各类与枚举 |
| `interfaces/kits/js/cloudfilesync/cloud_sync_napi.cpp` | cloudSync NAPI 桥接实现（GetFileSyncState/GetCoreFileSyncState/OptimizeStorage/RegisterChange 等） |
| `interfaces/kits/js/cloudfilesync/cloud_sync_core.cpp` | cloudSync Core 层，getFileSyncState 通过 getxattr 读 `user.cloud.filestatus`；start/stop/optimize 调 CloudSyncManager |
| `interfaces/kits/js/cloudfilesync/gallery_sync_napi.cpp` | GallerySync 类 NAPI（图库端云同步 on/off/start/stop） |
| `interfaces/kits/js/cloudfilesync/file_sync_napi.cpp` | FileSync 类 NAPI（应用文件端云同步） |
| `interfaces/kits/js/cloudfilesync/cloud_file_cache_napi.cpp` | CloudFileCache 类 NAPI（云文件下载/缓存/批量下载） |
| `interfaces/kits/js/cloudsyncmanager/cloud_sync_manager_napi.cpp` | @ohos.file.cloudSyncManager NAPI 模块注册 + DowngradeDownload 类导出 |
| `interfaces/kits/js/cloudsyncmanager/cloud_sync_manager_n_exporter.cpp` | cloudSyncManager NAPI 导出函数（ChangeAppCloudSwitch/EnableCloud/DisableCloud/Clean/NotifyDataChange/GetBundlesLocalFilePresentStatus/GetDowngradeDownloadTaskState） |
| `interfaces/kits/js/cloudsyncmanager/cloud_sync_manager_core.cpp` | cloudSyncManager Core 层，统一调用 CloudSyncManager::GetInstance() |
| `interfaces/kits/js/cloudsyncmanager/downgrade_download_napi.cpp` | DowngradeDownload 类 NAPI（全量下载 getCloudFileInfo/startDownload/stopDownload/startTransfer） |
| `interfaces/kits/xxx/clouddiskmanager/include/cloud_disk_error_code.h` | Native API 错误码 CloudDisk_ErrorCode（0/201/801/34400001-34400015） |
| `interfaces/kits/xxx/clouddiskmanager/include/oh_cloud_disk_manager.h` | xxx 对外头文件 |
| `interfaces/kits/xxx/clouddiskmanager/src/oh_cloud_disk_manager.cpp` | xxx 实现：OH_CloudDisk_GetSyncFolders/RegisterSyncFolder/GetSyncFolderChanges/SetFileSyncStates 等 |
| `interfaces/inner_api/native/cloudsync_kit_inner/cloud_sync_manager.h` | 云同步 Inner API（CloudSyncManager 单例，StartSync/OptimizeStorage/ChangeAppSwitch/EnableCloud 等） |
| `frameworks/native/cloudsync_kit_inner/include/cloud_sync_manager_impl.h` | CloudSyncManager IPC proxy 实现（→ cloudsyncservice SA） |
| `interfaces/inner_api/native/clouddiskservice_kit_inner/cloud_disk_service_manager.h` | 第三方云盘 Inner API（CloudDiskServiceManager） |
| `services/distributedfiledaemon/` | 分布式文件 daemon SA：hmdfs 挂载、软总线组网、设备管理、P2P 通道、文件/资产收发 |
| `services/cloudsyncservice/` | 云同步 SA：cycle_task 周期任务、sync_rule 同步规则、transport 传输、cloud_sync_service IPC stub |
| `services/cloudfiledaemon/` | 云文件 daemon |
| `services/clouddiskservice/` | 第三方云盘 SA：sync_folder 同步目录管理、monitor、seccomp_policy |
| `services/clouddisk_database/` | 第三方云盘数据库 |
