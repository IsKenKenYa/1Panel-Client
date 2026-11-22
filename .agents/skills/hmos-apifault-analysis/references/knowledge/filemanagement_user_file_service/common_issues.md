# filemanagement_user_file_service 常见问题

## 1. 权限问题（201 / 202）

- **201 Permission denied**：未声明或未授权所需权限。
  - fileAccess 系列：要求 `ohos.permission.FILE_ACCESS_MANAGER`（部分接口另需 `GET_BUNDLE_INFO_PRIVILEGED`）。
  - recent / trash：要求 `FILE_ACCESS_MANAGER` 且需系统应用。
  - 云盘同步：要求 `ACCESS_CLOUD_DISK_INFO`。
- **202 非系统应用**：fileAccess 模块仅允许系统应用调用。**更严格的约束**：即使声明了权限，目前也**仅 FilePicker（文件选择器）和 FileManager（文件管理器）可用**，其它系统应用调用会被拒绝。
- **修复**：module.json5 声明对应 `requestPermissions`；确认应用属于系统应用且在 FilePicker/FileManager 范围内；fileAccess_service SA SELinux 域为 `u:r:file_access_service:s0`，权限不足会在日志中体现。

## 2. 参数问题（401 / 13900020 / 14000001 / 14000002 / 14000003）

- **401 参数校验失败**：类型不符、必填缺失、超出范围（d.ts 通用标注）。
- **13900020 EINVAL / 13900022**：flags 非法、相对路径格式错误。
- **14000001 Invalid display name**：文件名为空、含非法字符（`/ : * ? " < > |`）、超长。
- **14000002 Invalid uri**：URI 格式错误、scheme/authority 不正确、无法解析（如传入非 `file://` 或非本扩展域 URI）。
- **14000003 Invalid file extension**：文件扩展名与目录已存在项冲突或不被允许。
- **修复**：调用前校验入参；createFile 前先 query/access 判断重名；URI 取自 getRoots/getFileInfoFromUri 的合法返回值，不要自行拼接。

## 3. 文件系统 POSIX 错误（13900xxx）

- **13900002 无此文件或目录（ENOENT）**：parentUri 指向的目录已被删除或不存在。常见于 createFile/move/rename。
- **13900015 文件已存在（EEXIST）**：createFile/mkDir 目标重名。修复：先判断，或改为覆盖语义。
- **13900019 是目录（EISDIR）**：对目录执行了仅文件适用的操作（openFile 写模式打开目录）。
- **13900018 非目录（ENOTDIR）**：路径中某段不是目录，或对文件执行了目录操作。
- **13900025 空间不足（ENOSPC）**：目标卷剩余空间不够（createFile/copy/move）。修复：清理空间或换卷。
- **13900027 只读文件系统（EROFS）**：对外置只读存储执行写操作。
- **13900001 操作不允许（EPERM）/ 13900012 EACCES**：底层文件系统访问被拒（区别于 201 权限框架层）。
- **13900042 未知错误**：底层非常见 errno 兜底，需查 HILOG 进一步定位。

## 4. IPC / 连接问题（14300xxx / 29189）

- **14300009 连接 FileAccessExtensionAbility 失败**：扩展未安装、未启动、被冻结或权限不足。**最常见的连接类故障**。修复：确认目标扩展（ExternalFileManager / medialibrary）已安装且 `extension` 配置为 `fileAccess`；查 `hilog | grep FileAccessService` 是否有 connect 超时。
- **14300003 获取扩展信息失败（E_GETINFO）**：扩展配置错误或不可达（Want 匹配不到）。
- **14300001 IPC error**：跨进程写/读数据失败。
- **14300004 Get wrong result**：扩展返回结果码不合法。
- **14300010 Too many records**：单次返回记录超上限，需分页或缩小查询。
- **14300005 / 14300006 / 14300007 / 14300008**：注册/反注册/初始化通知 agent 失败，影响 registerObserver。
- **29189 服务死亡（E_SERVICE_DIED）**：FileAccessService SA 或扩展进程死亡，远端对象失效。修复：重启相关进程或重试。
- **14300015 Load SA failed**：加载 FileAccessService SA 失败。

## 5. 云盘同步问题（34400xxx）

- **34400002 同步路径未授权**：应用无权访问该路径。
- **34400004 同步目录数量超限**：减少同步目录数量。
- **34400005 与自身应用同步目录冲突** / **34400006 与其它应用同步目录冲突**：注册路径与已有同步目录嵌套或重复。修复：调整路径使其互不包含。
- **34400008 同步目录未注册**：对其执行移除/监听却未注册。
- **34400011/34400012 监听器未注册/已注册**：重复或无效的监听操作。
- **34400014 Try again**：临时性失败（服务初始化中），可重试。
- **34400015 System restricted**：IT 设备禁止使用该能力。

## 6. 约束与使用限制

- **调用方限制**：fileAccess 全部 API 仅 FilePicker / FileManager 可用（系统应用）。
- **运行模型**：仅支持 stage 模型（FA 模型不可用）。
- **生命周期**：API 9 起 available，**API 23 起 deprecated**，新代码应使用 `@ohos.file.fs:fileIo`。
- **能力隔离**：未实现的能力返回 **801 Capability not supported**（E_NOT_SUPPORT）。
- **回收站语义**：文件被软删除会返回 **14000004 File has been put into trash bin**，需先 `trash.recover` 还原后才能正常操作。
- **回收站 / 最近访问**：trash 实际操作本地 `.Trash` 目录（`/storage/Users/currentUser/.Trash`），recent 操作 `.recent` 符号链接目录；依赖底层存储挂载状态。
