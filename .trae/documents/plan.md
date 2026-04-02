# 优化存储功能权限请求计划 (修订版)

## 目标 (Summary)
根据反馈，保留 `flutter_downloader` 以支持断点续传等高级下载功能。优化权限请求方式：
1. **停止申请“所有文件访问权限” (`MANAGE_EXTERNAL_STORAGE`)**，应用不再需要读取用户的所有文件。
2. **对于保存/导出由应用生成的小文件（如应用日志）**，全面改用 `FilePicker`，彻底无需任何权限。
3. **对于从服务器下载的文件**，继续使用 `flutter_downloader` 下载到公共的 `Downloads` 文件夹，并仅在需要时（Android 9及以下）请求普通的存储写入权限。

## 现状分析 (Current State Analysis)
目前应用在以下场景会请求并使用存储权限：
1. **日志导出**：在 `FeedbackCenterPage` 导出日志时，调用了 `FileSaveService.requestStoragePermission`，如果拒绝会引导去设置页。
2. **文件下载**：在 `FilesProvider.downloadFile` 和 `FileTransferService.checkAndRequestStoragePermission` 中，不仅请求了 `Permission.storage`，还请求了 `Permission.manageExternalStorage`（所有文件访问权限）。
3. **Android 存储处理**：`FileSaveService._saveFileAndroid` 依赖物理存储路径并请求权限。

## 提议的更改 (Proposed Changes)

1. **移除 `MANAGE_EXTERNAL_STORAGE` 请求**:
   - 在 `FileTransferService.checkAndRequestStoragePermission` 中，删除所有对 `Permission.manageExternalStorage` 的检查和请求。
   - 在 `files_page_async_actions_part.dart` 的错误处理逻辑中，移除引导用户去设置中开启“所有文件访问权限”的弹窗。

2. **重构 `FileSaveService` (`lib/core/services/file_save_service.dart`)**:
   - **全面使用 Picker 保存**：修改 `_saveFileAndroid`，不再检查权限和写入本地特定目录，而是像 iOS 一样直接使用 `FilePicker.platform.saveFile(dialogTitle: '保存文件', fileName: fileName, bytes: bytes)`。这让用户可以自由选择保存位置，且无需任何权限。
   - **移除多余的权限逻辑**：删除 `PermissionStatus` 枚举，移除 `requestStoragePermission`、`hasStoragePermission` 和 `isPermissionPermanentlyDenied` 方法。

3. **更新日志导出界面 (`lib/features/settings/feedback_center_page.dart`)**:
   - 移除 `_exportAppLogs` 中的存储权限检查逻辑（`result.permissionStatus == fs.PermissionStatus.permanentlyDenied` 等）。
   - 移除弹窗请求权限的方法 `_showPermissionSettingsDialog`。直接调用 `LogExportService().exportLogs`。

4. **优化文件下载权限逻辑 (`lib/features/files/services/file_transfer_service.dart`)**:
   - 更新 `checkAndRequestStoragePermission`：仅请求 `Permission.storage`。如果请求结果被拒绝（例如在 Android 13+ 上 `Permission.storage` 默认被拒绝且不可授权），我们**仍然返回 `true` 放行下载**。因为从 Android 10 开始，应用无需权限即可向公共的 `Downloads` 目录创建和写入新文件。这样既满足了旧版 Android 的权限要求，又解决了新版 Android 上的权限被拒问题。

## 假设与决策 (Assumptions & Decisions)
- **保留 FlutterDownloader**：满足断点续传、后台下载的需求。其下载路径默认使用 `path_provider` 的 `getDownloadsDirectory()`，在 Android 上指向公共的 `Downloads` 目录。
- **兼容 Android 13+**：在 Android 13+ 上，由于 `WRITE_EXTERNAL_STORAGE` 已经被废弃，请求 `Permission.storage` 会直接返回 `denied`。我们通过忽略该拒绝并继续执行下载，依赖 Android 的 Scoped Storage 机制来完成对 `Downloads` 目录的合法写入。

## 验证步骤 (Verification Steps)
1. 在 Android 13+ 设备/模拟器上测试：
   - 导出日志，确认系统弹出文件选择器，无需权限即可保存。
   - 在文件管理中下载文件，确认应用**没有**弹出权限请求框，文件成功下载到 `Downloads` 目录。
2. 在 Android 9 或以下设备上测试：
   - 下载文件时，确认应用仅请求普通的“存储空间”权限（而非“所有文件访问权限”），授权后成功下载。
3. 验证应用全局不再包含 `Permission.manageExternalStorage` 的调用。