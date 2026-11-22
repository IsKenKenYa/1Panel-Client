# 常见问题

> 本文件供 problem-locator Agent 快速匹配问题模式。按子模块与问题类型组织。

## 权限问题（错误码 201 / 13900012）

### 相册读写权限
- **201 / 13900012**：缺少 `ohos.permission.READ_IMAGEVIDEO`（getAssets/getAlbums/getThumbnail/Album.getAssets）或 `ohos.permission.WRITE_IMAGEVIDEO`（commitModify/applyChanges/deleteAssets/getWriteCacheHandler）。
  - 修复：在 `module.json5` 的 `requestPermissions` 声明，并在调用前用 `abilityAccessCtrl` 动态申请用户授权。
  - 注意：READ_IMAGEVIDEO / WRITE_IMAGEVIDEO 为 restricted 权限，需额外声明 ACL。
  - 源码：`ohos/file/photo_access_helper/photo_accesshelper.cj` 的 `@!APILevel[permission: ...]` 注解。

### 监听接口的「权限」码不一致
- registerChange / unregisterChange / getThumbnail 在 @throws 中声明的是 **13900012**（BASIC_FILE_IO 的 "Permission denied"），而非 201。开发者若按 201 排查会误判。
  - 源码：`ohos/file/photo_access_helper/photo_accesshelper.cj:172`、`photo_asset.cj:168`。

### 相机权限
- **201**：相机 createCameraInput 需要 `ohos.permission.CAMERA`；PhotoOutput.enableMovingPhoto 需要 `ohos.permission.MICROPHONE`。
  - 源码：`ohos/multimedia/camera/camera_manager.cj`、`photo_output.cj`。

## 参数问题（错误码 13900020 / 401）

### 13900020 — 相册模块最高频
- 触发场景：`getPhotoAccessHelper` 的 context 获取失败（FFI 返回 -1 时显式抛出）；各类枚举 `parse()` 收到未知取值（AlbumType/AlbumSubtype/PhotoType 等）；PhotoAsset.get/set 传入非法 member。
- 排查：检查 context 是否为有效 `UIAbilityContext`；枚举值是否在映射表内；PhotoKeys member 是否为合法属性名。
- 源码：`ohos/file/photo_access_helper/photo_accesshelper.cj:48`、`photo_accesshelper_utils.cj`（各 enum parse）。

### 401 — MediaChangeRequest 分发
- `PhotoAccessHelper.applyChanges` 传入既非 MediaAlbumChangeRequest 也非 MediaAssetChangeRequest 时内联抛出 401。
- `MediaAssetChangeRequest.getAsset` / `MediaAlbumChangeRequest.getAlbum` 在 FFI 返回 id==0 时抛出 401（资产/相册不存在）。
- 源码：`photo_accesshelper.cj:353`、`media_asset_change_request.cj:213`、`media_album_change_request.cj:75`。

### 相机 7400101 / 7400103 / 7400104
- **7400101**：参数缺失或类型错误（如 createSession/createCameraInput 传 null）。
- **7400103**：Session 未 commitConfig 即调用 start/能力接口。
- **7400104**：Session 未 start 即调用 stop 或查询能力。
- 源码：`ohos/multimedia/camera/camera_common.cj`。

## 资源/句柄问题（错误码 13900002 / 14000011 / 16000050）

### 13900002 — 文件不在沙箱
- createImageAssetRequest / createVideoAssetRequest / addResource(fileUri) 要求 fileUri 指向**应用沙箱目录**，否则抛 13900002。
- 排查：确认 URI 形如 `file://...` 且确实位于沙箱；媒体库 URI 不能直接用于创建请求。
- 源码：`media_asset_change_request.cj:77,102,264`。

### 14000011 — 系统内部失败
- 几乎贯穿相册所有接口。常见根因：底层 media_library 服务异常、数据库不可用、IPC 失败。
- `getWriteCacheHandler` 在 FFI 返回 -1 时**显式**把 errCode 改写为 14000011 再 checkRet。
- 源码：`media_asset_change_request.cj:254`（SYSTEM_INNER_FAIL 常量定义于 :25）。

### 16000050 — 不可达兜底
- getBurstAssets、PhotoAsset.get 的 unsafe 块尾部 `throw BusinessException(16000050, "Internal error.")` 是逻辑上不可达的兜底；若实际触发，说明 FFI 返回路径异常，应作为 bug 上报。
- 源码：`photo_accesshelper.cj:126`、`photo_asset.cj:115`。

## 操作能力受限（错误码 14000016）

- MediaAssetChangeRequest 的 addResource / getWriteCacheHandler / saveCameraPhoto / discardCameraPhoto，以及 MediaAlbumChangeRequest 的 addAssets / removeAssets，在某些资源类型或设备能力下会抛 **14000016 Operation Not Support**。
- 仓颉 Beta 限制：与 ArkTS 相比，相机不支持安全相机；图片不支持多图对象/图像元数据；媒体服务不支持音视频播放录制转码。详见 `README_zh.md` 约束章节。

## PixelMap 修改问题（错误码 62980248 / 7600201）

- 对**只读 PixelMap**（isEditable==false）调用 writePixels / opacity / crop / scale / translate / rotate / flip 等修改接口会失败。
- 内部码 62980248（"PixelMap does not allow modification."），对外码 7600201（"Unsupported operation."）。
- 源码：`ohos/multimedia/image/cj_image_common.cj`（convertErrCode 映射）。

## 内存释放与泄漏

- 仓颉对象持有 Int64 句柄（`RemoteDataLite` 管理 `myDataId`）。**必须显式调用 release()**：PhotoAccessHelper / FetchResult(close) / Album / ImageSource / ImagePacker / PixelMap / Session / 各 Output 均需释放。
- 析构 `~init()` 调用 `releaseFFIData(myDataId)`，但不应依赖 GC 时机（尤其 FetchResult 需手动 close）。
- CString 通过 `LibC.mallocCString` 分配后须 `LibC.free` 或用 `.asResource()` 配合 `try` 资源管理；`CPhotoCreationConfigs`/`FfiBundleInfo` 有 free()。
- 源码：`photo_accesshelper.cj`（各 release）、`photo_accesshelper_ffi.cj`（各 @C struct 的 free）。

## AVImageGenerator 缩略图失败（5400103 / 5400106）

- **5400103 I/O error**：通常因 `fdSrc` 未设置或 fd 无效。务必先赋值 `avImageGenerator.fdSrc = AVFileDescriptor(fd, length, offset)`。
- **5400106 Unsupported format**：容器/编码格式设备不支持（部分硬件编解码依赖设备）。
- **5400101 No memory**：请求的缩略图尺寸过大或同时请求过多帧。
- 源码：`ohos/multimedia/media/avimage_generator.cj`、`media_common.cj`。

## 监听注册重复/注销

- `registerChange` 对**同一个 callback 对象**重复注册同一 URI 会被忽略（`refEq` 判断），并打印日志 "registerChange failed: The same function has registered."，开发者可能误以为注册成功却收不到回调。
- `unregisterChange` 不传 callback 时注销该 URI 下**全部**监听（FFI funcId 传 -1）。
- 源码：`photo_accesshelper.cj:182-204`、`254-259`。

## 枚举值映射易错点

- AlbumSubtype：UserGeneric=1, Favorite=1025, Video=1026, Image=1031, AnyAlbum=2147483647（注意非连续）。
- AlbumType：User=0, System=1024。
- PhotoType：Image=1, Video=2。
- PhotoKeys.toString() 映射到数据库列名（如 'display_name'、'media_type'），fetchColumns 中应使用这些列名。
- 未知取值统一抛 13900020。
- 源码：`ohos/file/photo_access_helper/photo_accesshelper_utils.cj`。
