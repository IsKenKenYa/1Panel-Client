# filemanagement_storage_service

> @ohos/storage_service | subsystem: filemanagement | SA ID 5003（storage_manager）+ storage_daemon | 版本 3.1
> SysCap: `SystemCapability.FileManagement.StorageService.{Volume,SpatialStatistics,Encryption}`

## 模块职责

filemanagement_storage_service 为系统和应用提供基础存储查询与管理能力，采用**双进程架构**协作完成：

- **storage_manager（SA ID 5003，进程 storage_manager，库 libstorage_manager.z.so，run-on-create:true）**：上层服务进程，承载 JS/NAPI 接口。职责包括卷管理（Volume，挂载/卸载/格式化/分区）、磁盘管理（Disk，含光驱 ISO/burn）、空间统计（SpatialStatistics，卷/用户/应用/业务空间）、用户存储配额（Quota）、加密钥匙管理（fscrypt keyManager 去激活、encryptedVolumeManager 卷级加解密）、存储监控与状态上报。通过 IPC 向 storage_daemon 下发底层操作。
- **storage_daemon**：底层守护进程。通过 netlink 监听内核 uevent 实现热插拔，管理磁盘（disk_manager）、卷（volume）、文件系统挂载（fs）、fscrypt 文件级加密（crypto/libfscrypt，对接 huks）、用户目录（user）、配额（quota）、MTP/相机文件系统（mtp/gphotofs/file_sharing）。

JS 命名空间与本仓 NAPI exporter 对应：`@ohos.file.volumeManager`（volumemanager_n_exporter）、`@ohos.file.storageStatistics`（storage_statistics_n_exporter）、`@ohos.file.keyManager`（keymanager_n_exporter）、`@ohos.file.encryptedVolumeManager`（encrypted_volumemanager_n_exporter）。`@ohos.file.statvfs` 与 `@ohos.file.environment` 的 .d.ts 在本接口仓内，但其 NAPI/native 实现位于兄弟仓 `filemanagement_file_api`，本仓不含。

## 目录结构

```
filemanagement_storage_service/
├── interfaces/
│   ├── innerkits/storage_manager/        # 对内 IPC 接口（IStorageManager / Stub / Proxy / native 错误码 storage_service_errno.h）
│   └── kits/js/storage_manager/          # 对外 NAPI 头文件（storage_manager_connect.h 等）
├── services/
│   ├── storage_manager/                  # ★ 上层服务（SA 5003）
│   │   ├── include/
│   │   │   ├── ipc/storage_manager_provider.h      # StorageManagerProvider : SystemAbility, StorageManagerStub
│   │   │   ├── client/storage_manager_client.h     # 客户端代理
│   │   │   ├── disk/disk_manager_service.h         # 磁盘服务
│   │   │   └── storage/                            # 空间统计/监控/配额子服务
│   │   ├── kits_impl/src/                          # ★ 4 个 NAPI exporter
│   │   ├── ipc/src/storage_manager_provider.cpp    # SA 主体实现
│   │   ├── client/storage_manager_client.cpp       # 客户端代理实现
│   │   ├── disk/, volume/, storage/, scan/         # 业务模块
│   │   ├── storage_daemon_communication/           # 与 daemon 的 IPC 桥
│   │   └── sa_profile/5003.json                    # SA 注册配置
│   └── storage_daemon/                  # ★ 底层守护进程
│       ├── crypto/, libfscrypt/         # fscrypt 文件级加密（对接 huks）
│       ├── disk/, disk_manager/         # 磁盘管理（含光驱 ISO/burn）
│       ├── volume/                      # 卷挂载（mount/unmount/format）
│       ├── fs/, quota/, user/           # 文件系统/配额/用户目录
│       ├── netlink/                     # 内核 uevent 监听（热插拔）
│       └── mtp/, mtpfs/, gphotofs/, file_sharing/
├── tools/ohos-storage-manager/          # 命令行工具（dump）
└── docs/, figures/
```

## 核心文件

NAPI 导出层（JS → StorageManagerConnect）：
- `services/storage_manager/kits_impl/src/volumemanager_n_exporter.cpp` — volumeManager NAPI（Mount/Unmount/GetAllVolumes/Format/Partition/CreatePartition/DeletePartition/FormatPartition/GetAllDisks/GetDiskById/GetPartitionTable 等）
- `services/storage_manager/kits_impl/src/storage_statistics_n_exporter.cpp` — storageStatistics NAPI（GetTotalSizeOfVolume/GetFreeSizeOfVolume/GetBundleStats/GetUserStorageStats/GetTotalSize/GetFreeSize/GetTotalInodes/SetExtBundleStats 等）
- `services/storage_manager/kits_impl/src/keymanager_n_exporter.cpp` — keyManager NAPI（DeactivateUserKey）
- `services/storage_manager/kits_impl/src/encrypted_volumemanager_n_exporter.cpp` — encryptedVolumeManager NAPI（Encrypt/Unlock/Decrypt/UpdateCryptPasswd/GetCryptProgressById 等）
- `interfaces/kits/js/storage_manager/include/storage_manager_connect.h` — StorageManagerConnect 单例代理（持有 IStorageManager，封装 IPC 调用 + Convert2JsErrNum 错误码转换）

SA 主体与客户端：
- `services/storage_manager/include/ipc/storage_manager_provider.h` — StorageManagerProvider（SA 5003，继承 SystemAbility + StorageManagerStub，所有 IPC 方法 override 声明）
- `services/storage_manager/ipc/src/storage_manager_provider.cpp` — SA 主体实现（OnRemoteRequest 由 Stub 派发）
- `services/storage_manager/include/client/storage_manager_client.h` — 客户端代理头
- `services/storage_manager/sa_profile/5003.json` — SA 5003 注册配置（进程名、库、run-on-create）
- `interfaces/innerkits/storage_manager/native/storage_service_errno.h` — 内部 ErrNo 与 JsErrCode 枚举（STORAGE_SERVICE_SYS_CAP_TAG = 13600000 基址）

业务子服务：
- `services/storage_manager/include/disk/disk_manager_service.h` — DiskManagerService 磁盘服务
- `services/storage_manager/include/storage/storage_status_manager.h` — StorageStatusManager 空间统计
- `services/storage_manager/include/storage/storage_total_status_service.h` — StorageTotalStatusService
- `services/storage_manager/include/storage/storage_quota_controller.h` — StorageQuotaController 配额

storage_daemon 底层：
- `services/storage_daemon/include/volume/volume_manager.h` — 卷管理（daemon 侧）
- `services/storage_daemon/include/disk/disk_manager.h` — 磁盘管理（daemon 侧）
- `services/storage_daemon/include/netlink/netlink_manager.h` — 内核 uevent 热插拔监听
- `services/storage_daemon/include/crypto/` — fscrypt 加密（对接 huks）

接口声明（interface_sdk-js 仓）：
- `interface_sdk-js/api/@ohos.file.volumeManager.d.ts` — volumeManager JS 接口与错误码
- `interface_sdk-js/api/@ohos.file.storageStatistics.d.ts` — storageStatistics JS 接口与错误码
- `interface_sdk-js/api/@ohos.file.statvfs.d.ts` — statvfs JS 接口（NAPI 在 file_api 仓）
- `interface_sdk-js/api/@ohos.file.environment.d.ts` — environment JS 接口（NAPI 在 file_api 仓）
- `interface_sdk-js/api/@ohos.file.keyManager.d.ts` — keyManager JS 接口
- `interface_sdk-js/api/@ohos.file.encryptedVolumeManager.d.ts` — encryptedVolumeManager JS 接口
