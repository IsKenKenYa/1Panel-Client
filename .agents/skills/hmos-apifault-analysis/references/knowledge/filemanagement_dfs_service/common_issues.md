# filemanagement_dfs_service 常见问题模式

## 权限问题（201 / 202）

- **201 权限校验失败**：调用标有 `@permission` 的接口前必须在 `module.json5` 的 `requestPermissions` 声明对应权限，否则抛 201。本模块涉及三组权限：
  - `ohos.permission.CLOUDFILE_SYNC` — 图库/应用文件端云同步、优化存储、缓存清理等（GallerySync/Download.on、optimizeStorage、registerUploadProgress、cleanCache 等大量 cloudSync 接口）。
  - `ohos.permission.CLOUDFILE_SYNC_MANAGER` — 云同步管理类系统接口（enableCloud、disableCloud、clean、notifyDataChange(userId)、DowngradeDownload 全量下载、getBundlesLocalFilePresentStatus）。此类接口未声明该权限时报 201。
  - `ohos.permission.ACCESS_CLOUD_DISK_INFO` — 第三方云盘信息读取（cloudDiskManager 的 SyncFolderAccessor 构造与 getAllSyncFolders）。xxx 侧未声明对应权限返回 201（CLOUD_DISK_PERMISSION_DENIED）。
- **202 非系统应用**：GallerySync、Download 类，以及 cloudSyncManager / cloudDiskManager 命名空间下所有接口均标注 `@systemapi`，仅系统应用可调用；三方应用调用直接抛 202。

## 参数问题（401 / 13900020 / 34400001）

- **401 参数错误**：NAPI 层最先校验，常见于 accountId/bundleName 非 string、switches/appActions 非对象、uris 非数组、必选参数缺失、参数个数不匹配（NARG_CNT 校验）。CloudSyncManager 导出函数与 DowngradeDownload 构造、enableCloud 的 switches 解析（ParseSwitches）、clean 的 appActions 解析（ParseAppActions）失败均抛 401。
- **13900020 无效参数**：进阶参数语义校验。如 registerUploadProgress 同时注册实例数超上限、getUploadList/getDownloadList 的 uris 长度超限或含非法 uri、bundleNames 超 20 上限（GetBundlesLocalFilePresentStatus/GetDowngradeDownloadTaskState 硬编码 BUNDLES_MAX_SIZE=20）、startTransfer 的 targetUri 不属于文件管理公共目录。
- **34400001 入参非法（Native API）**：syncFolderPath/customAlias/callback 为空指针或长度非法、syncFolder 结构体为 nullptr。

## 网络 / 电量问题（22400002 / 22400003）

- **22400002 网络不可用**：GallerySync.start / FileSync.start 触发同步时，仅当**移动数据网络与 Wi-Fi 同时不可用**才报错（移动网络可用即可正常同步）。DownloadErrorType.NETWORK_UNAVAILABLE=2、startBatch 等下载流程也受影响。
- **22400003 电量过低**：非充电状态下电量低于 10% 时禁止触发或继续端云同步。同步进行中电量降到 10% 会在当前上传完成后停止并上报 BATTERY_LEVEL_LOW。下载侧 DownloadStopReason 体系用 NETWORK_UNAVAILABLE/TEMPERATURE_LIMIT 等独立枚举描述。

## 云状态问题（22400001）

- **22400001 云状态未就绪**：内部码 E_CLOUD_SDK（云 SDK 未初始化）。触发端云同步（GallerySync/FileSync 的 start）时，若华为云账号未登录、Drive Kit 未就绪、云服务未开启则报此错。排查：确认设备已登录华为账号、已在设置中开启云空间/云同步开关、目标应用已在云同步白名单内。

## IPC / 服务问题（13600001、SA 未拉起）

- **13600001 IPC 错误**：内部码 E_BROKEN_IPC / E_RDB / E_DEAD_REPLY(29189) / E_SA_LOAD_FAILED / E_SYSTEM_LOAD_OVER 统一映射。典型场景：
  - 云同步相关 SA（cloudsyncservice/cloudfiledaemon/clouddiskservice）或分布式文件 SA（distributedfiledaemon）**未拉起或已退出**。SA 由 samgr 按需拉起，若 SELinux 策略未放行（如 distributedfiledaemon:s0、cloudfiledaemon:s0、clouddiskservice:s0）或 profile 配置缺失，SA 加载失败 → E_SA_LOAD_FAILED → 13600001。
  - IPC binder 对端死亡（DEAD_REPLY=29189）。
  - RDB（关系数据库）打开/SQL 执行异常。
- **排查建议**：`hidumper -s <SA名>` 确认 SA 存活；`hilog | grep -E "E_SA_LOAD_FAILED|DEAD_REPLY|E_BROKEN_IPC"` 查看根因；检查 SELinux 拒绝日志 `dmesg | grep avc`。

## 第三方云盘冲突（34400005 / 34400006 / 34400004）

- **34400005 本应用冲突**：注册同步根路径与当前应用已注册的另一同步根存在包含/重叠（父子目录关系）。
- **34400006 跨应用冲突**：注册路径与其它第三方云盘应用已注册的同步根冲突（文件管理器需统一展示，不允许重叠）。
- **34400004 数量超限**：单个应用/设备注册的第三方云盘同步根目录数量超过上限。
- **34400013 变更序列号无效**：GetSyncFolderChanges 的 startUsn 过期（服务端已淘汰该 USN 之前的增量记录），需用 0 做全量查询。
- **34400014 临时失败**：网络抖动或 Native API 内存分配失败，建议重试。

## VFS 限制（hmdfs / 云文件 xattr 行为）

- **getFileSyncState / getCoreFileSyncState 读取 xattr**：这两个接口不经过 SA，直接在 NAPI/Core 层对 `file://...` 沙箱路径调用 `getxattr` 读取 `user.cloud.filestatus` 扩展属性。因此：
  - 路径必须为 `file` scheme，否则返回 EINVAL(13900020)。
  - 文件不存在返回 ENOENT(13900002)；文件系统拒绝返回 EACCES(13900012)；读到的值非法返回 22400005（getCoreFileSyncState）或回退为 COMPLETED。
  - getxattr 本身失败（如不支持 xattr 的文件系统）→ 13900042 未知错误（errMessageTable: 'getxattr failed'）。
- **软链接（symlink）不支持**：分布式文件 hmdfs 挂载点与云文件缓存路径对 symlink 支持有限，跨设备 symlink 不解析。
- **mmap 只读**：云文件未全量下载时 mmap 仅支持只读；写映射或随机写在仅占位（placeholder）文件上会失败。
- **rename 仅同目录**：跨目录 rename 在分布式/云文件路径上受限，应通过文件管理 API 迁移；startTransfer(DowngradeDownload) 用于把全量下载数据迁移到文件管理公共目录，任务运行中调用返回 13900001。
- **软总线传输错误**：SOFTBUS_TRANS_FILE_* 错误经 softbusErr2ErrCodeTable 转 POSIX errno：权限拒绝→EPERM(13900001)、磁盘配额→EIO(13900005)、无内存→ENOMEM、网络→ENETUNREACH、文件不存在→ENOENT(13900002)、已存在→EEXIST、取消→ECANCELED。
