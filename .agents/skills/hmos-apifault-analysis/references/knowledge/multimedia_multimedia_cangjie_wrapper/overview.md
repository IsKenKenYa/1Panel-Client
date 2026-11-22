# multimedia_multimedia_cangjie_wrapper

## 模块职责

OS 媒体软件仓颉封装（beta 特性）。在 OpenHarmony 平台上为开发者提供使用 **仓颉（Cangjie）语言** 进行应用开发时所需的媒体能力，是媒体子系统对外的仓颉接口层。该模块不包含自身的媒体业务实现，而是通过 **FFI（Foreign Function Interface）** 桥接调用底层四个媒体组件的能力，对外统一暴露四类业务：相册管理（PhotoAccessHelper）、相机管理（Camera）、图片处理（Image）、媒体服务（Media/视频缩略图）。仅支持 standard 设备，当前开放接口为 beta。

模块定位为「接口层 + 框架层」的仓颉封装：
- 接口层：对外公开的仓颉 API（kit/ 目录与 ohos/ 目录下的 public class/func）。
- 框架层：仓颉封装实现，负责参数 C 结构转换、FFI 调用、错误码映射并抛出 BusinessException。

底层依赖组件（真正实现）：
- `media_library`（multimedia_media_library）— 相册/照片资源管理
- `camera_framework`（multimedia_camera_framework）— 相机基础功能
- `image_framework`（multimedia_image_framework）— 图片编解码
- `player_framework`（multimedia_player_framework）— 媒体服务（视频缩略图 AVImageGenerator）

## 目录结构

```
foundation/multimedia/multimedia_cangjie_wrapper
├── figures/                         # README 架构图
├── kit/                             # 仓颉媒体 kit 化接口（声明/聚合）
│   ├── CameraKit/
│   ├── ImageKit/
│   ├── MediaKit/
│   └── MediaLibraryKit/
├── ohos/                            # 仓颉媒体接口实现（FFI 桥接层）
│   ├── file/
│   │   └── photo_access_helper/     # 相册管理（创建/访问/修改相册）
│   └── multimedia/
│       ├── camera/                  # 相机（预览/拍照/录像）
│       ├── image/                   # 图片编解码
│       ├── media/                   # 媒体服务（视频缩略图）
│       └── multimedia.cj            # 顶层 package 声明（空命名空间）
├── mock/                            # 桩实现
├── test/                            # 仓颉测试用例（camera/image/media/photo_accesshelper）
├── bundle.json                      # 部件定义（multimedia 子系统，版本 6.1）
└── BUILD.gn                         # 顶层构建（cjc.gni 仓颉编译）
```

## 子模块与 package 一览

| 子模块 | package | 主要职责 | 对应 ArkTS .d.ts | 底层组件 |
|--------|---------|----------|------------------|----------|
| 相册管理 | `ohos.file.photo_access_helper` | 获取/修改照片与相册资源、监听变更、创建资产请求、安全相册对话框 | `@ohos.file.photoAccessHelper.d.ts` | media_library |
| 相机管理 | `ohos.multimedia.camera` | 相机设备管理、预览/拍照/录像、闪光灯/曝光/对焦/防抖/变焦 | `@ohos.multimedia.camera.d.ts` | camera_framework |
| 图片处理 | `ohos.multimedia.image` | 图片编解码、PixelMap 操作、ImageReceiver、图片变换 | `@ohos.multimedia.image.d.ts` | image_framework |
| 媒体服务 | `ohos.multimedia.media` | 视频缩略图提取（AVImageGenerator） | `@ohos.multimedia.media.d.ts` | player_framework |

## 核心文件

**相册管理（photo_access_helper）** — 本知识库重点关注
- `ohos/file/photo_access_helper/photo_accesshelper.cj` — `PhotoAccessHelper` 类与 `getPhotoAccessHelper()` 入口、getAssets/getAlbums/registerChange/release/applyChanges
- `ohos/file/photo_access_helper/photo_accesshelper_ffi.cj` — 全部 `foreign` FFI 函数声明与 `@C` 结构体（CFetchOptions、CPhotoCreationConfigs、CChangeData 等）
- `ohos/file/photo_access_helper/photo_accesshelper_utils.cj` — 错误码映射表（BASIC_FILE_IO / USER_DATA_MANAGEMENT / SPACE_STATISTICS / USER_FILE_ACCESS / DEVICE_CLOUD_SYNCHRONIZATION）、`checkRet()`、FetchOptions、枚举（AlbumType/AlbumSubtype/PhotoType/PhotoKeys 等）
- `ohos/file/photo_access_helper/photo_asset.cj` — `PhotoAsset` 类（get/set/commitModify/getThumbnail）
- `ohos/file/photo_access_helper/album.cj` — `AbsAlbum`/`Album` 类（相册属性、getAssets、commitModify）
- `ohos/file/photo_access_helper/fetch_result.cj` — `FetchResult`/`AlbumResult`/`PhotoAssetResult`（结果集遍历）
- `ohos/file/photo_access_helper/media_asset_change_request.cj` — `MediaAssetChangeRequest`（创建/删除资产、添加资源、保存相机照片）
- `ohos/file/photo_access_helper/media_album_change_request.cj` — `MediaAlbumChangeRequest`（重命名、增删相册资产）

**相机管理（camera）**
- `ohos/multimedia/camera/camera_ffi.cj` — 全部 `foreign` FFI 声明
- `ohos/multimedia/camera/camera_manager.cj` — `CameraManager` 入口
- `ohos/multimedia/camera/camera_input.cj`、`camera_session.cj`、`camera_output.cj`、`photo_output.cj`、`preview_output.cj`、`video_output.cj` — 输入/会话/输出
- `ohos/multimedia/camera/camera_ability.cj` — 能力接口（AutoExposure/Flash/Focus/Zoom/Stabilization/ColorManagement）
- `ohos/multimedia/camera/camera_common.cj` — 相机错误码映射与 `successOrThrow()`

**图片处理（image）**
- `ohos/multimedia/image/image_source.cj`、`image_packer.cj`、`image_receiver.cj`、`pixel_map.cj`、`image.cj` — 核心类
- `ohos/multimedia/image/cj_image_common.cj` — 图片错误码映射与 `checkAndThrow()`
- `ohos/multimedia/image/cj_image_enum.cj`、`cj_image_utils.cj`、`cj_image_log.cj` — 枚举/工具/日志

**媒体服务（media）**
- `ohos/multimedia/media/avimage_generator.cj` — `AVImageGenerator` 与 `createAVImageGenerator()`
- `ohos/multimedia/media/media_ffi.cj` — `foreign` FFI 声明
- `ohos/multimedia/media/media_common.cj` — 媒体错误码映射与 `throwIfNotSuccess()`

## 关键技术特征

- **语言**：仓颉（Cangjie），源文件后缀 `.cj`；通过 `foreign` 块声明 native 函数，`@C` 标注 C 兼容结构体。
- **桥接模式**：仓颉对象持有一个 Int64 句柄（`id`/`getID()`），`RemoteDataLite` 管理其 `myDataId`；析构 `~init()` 调用 `releaseFFIData()` 释放。
- **错误处理**：统一抛出 `ohos.business_exception.BusinessException(code, message)`；每个子模块各自维护错误码→消息映射表。
- **API 等级**：全部 `@!APILevel[since: "22"]`，syscap 为 `SystemCapability.FileManagement.PhotoAccessHelper.Core`（相册）/ 相机/图片相关。
- **Beta 状态**：仓颉接口为 beta，能力范围小于 ArkTS（不支持安全相机、多图对象、图像元数据、音视频播放录制转码等，详见 README 约束）。
