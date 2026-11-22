# multimedia_media_library 模块概览

> 组件 `@ohos/media_library`，subsystem=multimedia，version 4.0，支持 small+standard，ROM≈10444KB / RAM≈35093KB（**超大模块**）

## 模块职责

媒体库系统服务（media library），负责管理设备上图片/视频/音频等媒体资产的元数据，提供媒体元数据查询、相册管理（创建/重命名/删除）、媒体文件操作（创建/拷贝/移动/删除）、云端同步、MTP、媒体扫描、动态照片（Moving Photo）、选择器（Photo Picker / Album Picker）、主动分析（Active Analysis）等能力。是相册、相机、文件管理等上层应用的基础能力底座。

## 目录结构（简化）

```
multimedia_media_library/
├── interfaces/
│   ├── kits/
│   │   ├── js/                      # JS/NAPI 声明（由 interface_sdk-js 提供 .d.ts）
│   │   ├── c/                       # C API 头文件（Native API）
│   │   │   ├── media_access_helper_capi.h
│   │   │   ├── media_asset_base_capi.h
│   │   │   ├── media_asset_capi.h
│   │   │   ├── media_asset_change_request_capi.h
│   │   │   ├── media_asset_manager_capi.h
│   │   │   ├── moving_photo_capi.h
│   │   │   └── media_asset_manager/  # xxx 构建
│   │   └── cj/                      # Cangjie FFI
│   │       ├── src/ (photo_accesshelper_ffi.cpp, media_asset_manager_ffi.cpp, ...)
│   │       └── libcj_photoaccesshelper_ffi.map
│   └── inner_api/                   # Inner API（C++，仅系统应用）
│       └── media_library_helper/
│           ├── include/media_library_manager.h
│           ├── include/media_library_error_code.h   # 错误码常量
│           ├── analysis_data_kits/      # 主动分析数据
│           ├── native/cloud_sync/       # 端云同步
│           ├── media_permission_helper/
│           └── media_library_camera_helper/
├── frameworks/
│   ├── js/src/                      # ★ NAPI 桥接层（主力，~50 个 _napi.cpp）
│   ├── ani/                         # ArkTS Native Interface
│   ├── client/                      # IPC 客户端代理
│   ├── innerkitsimpl/
│   │   └── medialibrary_data_extension/  # DataShare Extension
│   │       └── src/medialibrary_{album,asset}_operations.cpp
│   ├── native/c_api/                # C API 实现（media_*_capi/*.cpp）
│   └── services/                    # 服务侧实现（部分）
├── services/                        # 旁路服务
│   ├── media_cloud_sync_service/    # 端云同步
│   ├── media_cloud_enhancement/
│   ├── media_mtp/                   # USB MTP（位于其它目录）
│   ├── media_backup_extension/      # 备份
│   ├── media_albums_manager/
│   ├── media_analysis_extension/    # 主动分析扩展
│   ├── media_analysis_data_manager/
│   ├── media_assets_manager/
│   └── media_camera_character_service/
├── tools/
│   ├── medialibrary_scanner/        # 媒体扫描入库
│   └── medialibrary_tool/
└── MediaLibraryExt/ (或其它 HAP)     # 媒体库扩展 HAP
```

## 核心文件清单

### NAPI 模块注册入口（frameworks/js/src/）

| 文件                                                                                       | 用途                                                                                                  |
| ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `native_module_ohos_photoaccess_helper.cpp`                                              | ★ 注册`@ohos.file.photoAccessHelper`（g_photoAccessHelperModule / napi_module_register），主力入口 |
| `native_module_ohos_userfile_manager.cpp`                                                | 注册`@ohos.filemanagement.userFileManager`                                                          |
| `native_module_ohos_medialibrary.cpp`                                                    | 注册旧`@ohos.multimedia.mediaLibrary`                                                               |
| `photopickercomponent.cpp` / `albumpickercomponent.cpp` / `recentphotocomponent.cpp` | UI 选择器组件                                                                                         |
| `sendable/native_module_ohos_photoaccess_helper_sendable.cpp`                            | Sendable 版本                                                                                         |

### NAPI 类实现（frameworks/js/src/）

| 文件                                                                                    | 类                                                      |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `photo_album_napi.cpp`                                                                | PhotoAlbum                                              |
| `file_asset_napi.cpp`                                                                 | FileAsset / PhotoAsset（旧）                            |
| `album_napi.cpp`                                                                      | Album                                                   |
| `media_asset_change_request_napi.cpp`                                                 | MediaAssetChangeRequest（静态创建/删除/移动/拷贝/收藏） |
| `media_album_change_request_napi.cpp`                                                 | MediaAlbumChangeRequest                                 |
| `photo_asset_custom_record_napi.cpp` / `photo_asset_custom_record_manager_napi.cpp` | 自定义记录                                              |
| `moving_photo_napi.cpp`                                                               | MovingPhoto（动态照片）                                 |
| `highlight_album_napi.cpp`                                                            | HighlightAlbum（精彩时刻）                              |
| `smart_album_napi.cpp`                                                                | SmartAlbum                                              |
| `fetch_file_result_napi.cpp`                                                          | FetchResult                                             |
| `result_set_napi.cpp`                                                                 | ResultSet                                               |
| `cloud_media_asset_manager_napi.cpp` / `cloud_enhancement_napi.cpp`                 | 云端资产                                                |
| `photoaccess_helper_napi.cpp`                                                         | PhotoAccessHelper（单例类）                             |

### 错误与工具

| 文件                                                                          | 用途                                                 |
| ----------------------------------------------------------------------------- | ---------------------------------------------------- |
| `napi_error.cpp`                                                            | NapiError → BusinessError，内部 E_ 常量映射到公开码 |
| `medialibrary_napi_utils.cpp` / `../napi_common/src/media_napi_utils.cpp` | NAPI 工具函数（参数校验、异步工作线程）              |

### 错误码源

- `interface_sdk-js/api/@ohos.file.photoAccessHelper.d.ts`（@throws 注解）
- `interface_sdk-js/api/@ohos.filemanagement.userFileManager.d.ts`
- `interfaces/inner_api/media_library_helper/include/media_library_error_code.h`（23800151/238002xx/23800301 常量）

### DataShare Extension（frameworks/innerkitsimpl/medialibrary_data_extension/src/）

- `medialibrary_album_operations.cpp` — 相册增删改
- `medialibrary_asset_operations.cpp` — 资产增删改查
- 落地到 RDB（relational_store）+ 文件系统（file_api）

## 关键依赖（bundle.json 节选）

data_share、relational_store、file_api、image_framework、access_token、ability_runtime、ipc、samgr、hilog、hisysevent、kv_store、dfs_service（云）、camera_framework、player_framework、libexif、huks、storage_service、os_account。

## 架构调用链（简）

```
JS 应用
  → @ohos.file.photoAccessHelper.d.ts
  → frameworks/js/src/native_module_ohos_photoaccess_helper.cpp（注册）
  → photo_album_napi.cpp / file_asset_napi.cpp / media_asset_change_request_napi.cpp 等类实现
  → napi_error.cpp 抛 BusinessError
  → frameworks/client（IPC 代理）
  → MediaLibrary DataShare Extension（medialibrary_{album,asset}_operations.cpp）
  → RDB 数据库 + 文件系统
旁路：tools/medialibrary_scanner（扫描入库）、services/media_cloud_sync_service（端云）、services/media_mtp（USB MTP）、MediaLibraryExt（HAP）
```
