# filemanagement_user_file_service 概览

## 模块职责

`filemanagement_user_file_service`（对外命名空间 `@ohos.file.fileAccess`，subsystem `filemanagement`，SysCap `SystemCapability.FileManagement.UserFileService`）是**公共文件访问框架（File Access Framework）**。它向上对接系统应用（仅 FilePicker / FileManager 可调用），向下通过 `FileAccessExtensionAbility` 扩展机制对接底层文件管理服务（内置 ExternalFileManager 文档管理扩展，外部对接 medialibrary 媒体库、外置存储、共享盘、云盘），为系统应用提供对公共文件（媒体文件、文档、共享盘、外置存储、云盘同步目录）的统一查询 / 创建 / 删除 / 打开 / 移动 / 重命名 / 注册监听能力。此外还提供 `@ohos.file.recent`（最近访问）、`@ohos.file.trash`（回收站）、云盘同步目录（`CloudDiskManager` / SyncFolder）等子能力。

> 注：`@ohos.file.fileAccess` 自 API 23 起标记 deprecated，useinstead `@ohos.file.fs:fileIo`。

## 简化目录树（3 层）

```
filemanagement_user_file_service/
├── frameworks/js/napi/                  # JS/NAPI 桥接层
│   ├── file_access_module/              # @ohos.file.fileAccess（FileAccessHelper + 顶层函数）
│   ├── file_extension_info_module/      # @ohos.file.fileExtensionInfo
│   ├── file_access_ext_ability/         # FileAccessExtensionAbility（扩展提供方继承）
│   └── common/                          # file_extension_info 公共 NAPI
├── interfaces/
│   ├── inner_api/file_access/           # 内部 API（扩展 stub、extension info）
│   ├── inner_api/cloud_disk_kit_inner/  # 云盘内部 API
│   └── kits/
│       ├── native/recent/               # @ohos.file.recent
│       ├── native/trash/                # @ohos.file.trash
│       ├── native/clouddiskmanager/     # 云盘同步目录（SyncFolder）
│       └── picker/                      # DocumentViewPicker 文件选择器
├── services/
│   ├── native/file_access_service/      # SA 服务层（FileAccessService，SystemAbility）
│   ├── native/cloud_disk_service/       # 云盘服务
│   ├── file_extension_hap/              # 内置 ExternalFileManager 扩展（ArkTS HAP）
│   ├── rdb_adapter/                     # 关系型数据库适配（ufs_db）
│   └── notify_event/                    # 通知事件
└── utils/
    └── file_access_framework_errno.h    # 错误码定义（统一）
```

## 核心文件清单

| 层 | 文件 | 说明 |
| --- | --- | --- |
| NAPI | `frameworks/js/napi/file_access_module/napi_fileaccess_helper.cpp` | FileAccessHelper 类方法 + 顶层 `createFileAccessHelper`/`getFileAccessAbilityInfo` 导出（250-283 行 properties 注册） |
| NAPI | `frameworks/js/napi/file_access_module/native_fileaccess_module.cpp` | 模块注册（nm_modname = "file.fileAccess"） |
| NAPI | `frameworks/js/napi/file_extension_info_module/module_export_napi.cpp` | `@ohos.file.fileExtensionInfo` 导出 |
| Native Kit | `interfaces/kits/native/recent/recent_n_exporter.cpp` | `@ohos.file.recent`（add / remove / listFile） |
| Native Kit | `interfaces/kits/native/trash/src/file_trash_n_exporter.cpp` | `@ohos.file.trash`（listFile / recover / completelyDelete） |
| Native Kit | `interfaces/kits/native/clouddiskmanager/src/sync_folder_access_n_exporter.cpp` | 云盘同步目录 `getAllSyncFolders` |
| Inner API | `interfaces/inner_api/file_access/file_access_ext_ability.h` | 扩展能力接口 |
| Inner API | `interfaces/inner_api/file_access/file_access_ext_stub_impl.h` | 扩展 IPC stub 实现 |
| Inner API | `interfaces/inner_api/cloud_disk_kit_inner/cloud_disk_sync_folder_manager.h` | 云盘同步目录管理 |
| SA | `services/native/file_access_service/include/file_access_service.h` | FileAccessService（SystemAbility + Stub，223 行类定义） |
| SA 配置 | `services/file_access_service.cfg` | SA 配置（uid/gid ufs，ondemand） |
| 错误码 | `utils/file_access_framework_errno.h` | 全模块统一错误码定义 |
| 内置扩展 | `services/file_extension_hap/` | 内置 ExternalFileManager 文档管理扩展 HAP |
| DB | `services/rdb_adapter/` | ufs_db 关系型数据库适配 |
