# filemanagement_storage_service 常见问题模式

> 错误码均以 d.ts 与 `interfaces/innerkits/storage_manager/native/storage_service_errno.h` 为准（基址 STORAGE_SERVICE_SYS_CAP_TAG = 13600000）。
> 本模块自定义码形如 `13600xxx`；errno 衍生（statvfs / environment，跨仓 file_api）形如 `13900xxx`。

## 一、权限问题（201 / 202）

- **201 Permission verification failed.** — 调用方未申请所需权限。volumeManager 的 mount/unmount/erase/eject 需 `ohos.permission.MOUNT_UNMOUNT_MANAGER`；format/partition/createPartition/deletePartition/formatPartition 需 `ohos.permission.MOUNT_FORMAT_MANAGER`；getAllVolumes/getVolumeByUuid/getDiskById 与 storageStatistics 多数接口需 `ohos.permission.STORAGE_MANAGER`；keyManager.deactivateUserKey 需 `ohos.permission.STORAGE_MANAGER_CRYPT`；encryptedVolumeManager 全部接口需 `ohos.permission.ENCRYPT_VOLUME_MANAGER`。排查：核对 module.json5 的 requestPermissions 与 ACL 配置，确认权限已授予。
- **202 The caller is not a system application.** — 调用方非系统应用却调用了 @systemapi。volumeManager / storageStatistics / keyManager / encryptedVolumeManager / environment 的 getStorageDataDir 等均为系统 API。排查：确认调用方为系统应用（配置 `system=true` 或持有系统签名），NAPI 侧 `IsSystemApp()` 校验失败即抛 E_PERMISSION_SYS(202)。

## 二、参数问题（401 / 13600010 / 13900020）

- **401 The input parameter is invalid.** — OS 通用参数错误。必填参数缺失、参数类型不匹配、参数个数不对。NAPI 侧由 `NFuncArg::InitArgs` 与 `ToUTF8String/ToInt32` 校验失败触发（E_PARAMS）。排查：核对 d.ts 形参类型与个数，异步 callback 与 promise 重载的参数边界。
- **13600010 The input parameter is invalid.** — 较新接口（erase/createIsoImage/burn/getOpProcess/verifyBurnData/createPartition/deletePartition/getDiskById/getPartitionTable 及 encryptedVolumeManager 各接口）的业务层参数校验失败（JsErrCode E_JS_PARAMS_INVALID）。与 401 区别：401 在 NAPI 参数解析阶段，13600010 多在 IPC 调用前的业务字段校验阶段（如 volumeId 为空、超过 256 字符、PartitionParams 缺字段）。
- **13900020 Invalid argument.** — errno EINVAL，statvfs / environment（file_api 仓）参数处理阶段抛出。

## 三、IPC 问题（13600001）

- **13600001 IPC error.** — IPC 通信失败。storage_manager SA 5003 未启动、storage_daemon 未启动、IPC 调用超时或 Proxy 为空。NAPI 侧 `StorageManagerConnect::Connect()` 拿不到 IStorageManager，或 Stub 返回非 E_OK。排查：
  1. `hidumper -s 5003 -a "-h"` 确认 storage_manager SA 已注册；
  2. `ps -ef | grep storage_daemon` 确认 daemon 进程存活；
  3. 查 hilog 中 storage_manager / storage_daemon 标签的 fatal；
  4. 检查 samgr 是否完成 SA 上线（依赖 init 启动配置）。

## 四、卷 / 挂载问题（1360002 / 1360003 / 1360004 / 1360005）

- **13600002 Not supported filesystem.** — 不支持的文件系统类型。当前仅支持 FAT/exFAT/ext4/NTFS 等，mount/format/erase/eject/burn 遇到其它 fsType 抛出。排查：用 `blkid` 或 daemon 日志确认卷实际文件系统类型，确认内核已加载对应驱动。
- **13600003 Failed to mount.** — 挂载失败。卷损坏、文件系统驱动未加载、设备只读、挂载点目录创建失败。排查：查 daemon `volume/` 模块日志，确认 mount 系统调用的 errno；必要时先 `e2fsck`/`fsck.vfat` 修复。
- **13600004 Failed to unmount.** — 卸载失败。卷被占用（有进程持有文件/工作目录）、卸载忙（E_UMOUNT_BUSY）、卸载超时。排查：`lsof +D <挂载点>` 找占用进程，daemon 的 user/ 模块会尝试清理后再卸载。
- **13600005 Incorrect volume state.** — 卷状态不正确。如对已挂载卷 format、对未挂载卷 unmount、对非加密卷执行加密操作。排查：先 `getVolumeById` 查 state（0=未挂载/2=已挂载/3=弹出中），按状态机约束调用。

## 五、磁盘 / 光驱 / 分区问题（13600021~13600032）

- **13600021 Get partition table failed（volumeManager）** — 获取分区表失败（JsErrCode E_JS_GET_PARTITION_ERROR，内部 E_GET_PARTITION_ERROR/E_GET_PARTITION_TIMEOUT）。排查：确认 diskId 有效，daemon disk_manager/ 读取分区表是否超时。
- **13600022 Create partition failed（volumeManager）** — 创建分区失败（E_JS_CREATE_PARTITION_ERROR）。注意：在 encryptedVolumeManager 语境 13600022 是 "Incorrect password"，同名码语义按 d.ts 上下文区分。
- **13600023 Delete partition failed.** — 删除分区失败（E_JS_DELETE_PARTITION_ERROR）。
- **13600024 Empty disc.** — createIsoImage 对空光盘操作。排查：确认光盘已写入数据。
- **13600025 Failed to write the ISO file.** — 写 ISO 文件失败，目标路径不可写或磁盘满。
- **13600026 Erase operation failed.** — erase 卷擦除失败。
- **13600028 Burn operation failed.** — burn 刻录失败，光驱硬件异常或介质不支持。
- **13600030 Verification failed.** — verifyBurnData 校验不一致，刻录数据与原数据不符。
- **13600032 Format partition failed.** — formatPartition 格式化失败（E_JS_FORMAT_PARTITION_ERROR）。

## 六、空间统计问题（13600011~13600018 / 1360009）

- **13600009 User id out of range.** — userId 越界（E_OUTOFRANGE / E_USERID_RANGE）。getUserStorageStats(userId) 与 keyManager.deactivateUserKey 须 userId 在 100~10736 之间。排查：确认 os_account 中该 userId 已创建。
- **13600011 Failed to report the specified business space usage.** — setExtBundleStats 写入数据库失败（E_JS_SET_EXT_BUNDLE_STATS_ERROR）。排查：确认 userId 存在、businessName 非空、size 非负、flag 为 boolean。
- **13600012 / 13600013** — getExtBundleStats / getAllExtBundleStats 查询数据库失败。
- **13600015 Failed to traverse the query data partition directory.** — listUserdataDirInfo 扫描 /data 目录树异常（目录不可读或 stat 失败）。
- **13600016 Failed to query the inode information of the data partition.** — getTotalInodes/getFreeInodes 调 statvfs 失败（E_JS_GET_INODE_ERROR）。
- **13600017 Failed to query the inode information of the application.** — getCurrentBundleInodes 失败（E_JS_GET_BUNDLE_INODES_ERROR）。
- **13600018 Failed to query the system data size.** — getSystemDataSize 失败（E_JS_GET_SYSTEM_DATA_SIZE_ERROR）。

## 七、加密卷密码问题（13600019~13600022，encryptedVolumeManager）

- **13600019 密码强度不达标** — 密码须包含大写/小写/数字/特殊字符中至少两类且满足长度。排查：按提示加强密码复杂度。
- **13600020 Invalid encryption key format.** — bindRecoverKeyToPasswd / resetCryptPasswd 的 recoverKey 格式非法。
- **13600021 Volume is not encrypted.** — 对未加密卷执行 getCryptProgressById/unlock/decrypt/updateCryptPasswd。排查：先 encrypt 再操作。
- **13600022 Incorrect password.** — unlock/decrypt/verifyCryptPasswd/updateCryptPasswd 密码错误。

## 八、errno 类（13900xxx，statvfs / environment，跨仓 file_api）

- **13900002 No such file or directory (ENOENT)** — statvfs 传入的 path 不存在。
- **13900005 I/O error (EIO)** — I/O 错误，常见于存储介质损坏。
- **13900011 Out of memory (ENOMEM)** — 内存不足。
- **13900012 Permission denied (EACCES)** — path 访问权限不足。
- **13900031 Function not implemented (ENOSYS)** — 内核/文件系统不支持该 statvfs 操作。
- **13900042 Unknown error** — 所有存储接口的兜底错误码。内部错误经 `Convert2JsErrNum` 无具体映射时统一转为此码。排查：需结合 hilog 中 storage_manager/daemon 的原始 errno 日志定位真实原因（本仓 storage_service_errno.h 中数百个内部码未对 JS 暴露，多数会折叠到 13900042）。
