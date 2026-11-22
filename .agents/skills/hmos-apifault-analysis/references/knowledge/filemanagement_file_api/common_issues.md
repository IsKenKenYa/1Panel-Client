# filemanagement_file_api 常见问题模式

按错误类别组织。每条给出错误码、根因与修复建议。错误码以 `13900000` 为 FileIO 子系统前缀（`FILEIO_SYS_CAP_TAG`），来源：`utils/filemgmt_libfs/include/fs_error.h`。

## 一、权限与系统应用问题

### 1. 201 — Permission verification failed

- **根因**：调用方未声明/授予所需权限。典型场景：`@ohos.file.environment` 的 `getUserDownloadDir` / `getUserDesktopDir` / `getUserDocumentDir` 需要对应 `READ_WRITE_DOWNLOAD_DIRECTORY` / `READ_WRITE_DESKTOP_DIRECTORY` / `READ_WRITE_DOCUMENTS_DIRECTORY` 权限，且需开启 `const.filemanager.full_mount.enable`。
- **修复建议**：在 `module.json5` 声明 `requestPermissions`，并确认系统参数已开启全量挂载；否则返回 801。

### 2. 202 — The caller is not a system application

- **根因**：`@ohos.file.environment`、`getStorageDataDir` 等为系统 API，调用方不是系统应用（`TokenIdKit::IsSystemAppByFullTokenID` 校验失败）。
- **修复建议**：改用应用沙箱内的 `getContext().filesDir` 等应用级目录；或确认应用具备系统应用签名。

### 3. 13900012 — Permission denied（EACCES）

- **根因**：路径在沙箱外或 SELinux/文件权限位（rwx）阻止访问；或 securityLabel 设置的高安全等级（s3/s4）限制低等级进程读取。
- **修复建议**：使用应用沙箱目录（`getFilesDir`/`getCacheDir`/`distributedFilesDir`）；检查 `securityLabel` 等级一致性。

### 4. 13900001 — Operation not permitted（EPERM）

- **根因**：操作被禁止，常见于对受保护文件执行写/删/重命名，或文件被占用锁定。
- **修复建议**：先关闭已打开的 fd；确认目标文件非系统只读资源。

## 二、参数问题

### 5. 401 — The input parameter is invalid

- **根因**：参数类型/数量不匹配（各函数 `InitArgs` 校验失败），或路径非合法字符串、options 对象结构错误。
- **修复建议**：按 d.ts 校验参数个数与类型；路径用沙箱absolute path字符串。

### 6. 13900020 — Invalid argument（EINVAL）

- **根因**：参数值非法，如 `mode` 不为 0/1/2/3、`offset` 为负且越界、`Whence` 枚举错误、buffer 长度非法、securityLabel 的 `dataLevel` 不在 s0~s4 范围（`DATA_LEVEL.find` 失败）。
- **修复建议**：核对 `OpenMode` / `AccessMode` / `Whence` / `dataLevelEnum` 取值；`dataLevel` 仅允许 "s0"~"s4"。

### 7. 13900030 — File name too long（ENAMETOOLONG）

- **根因**：单段文件名或全路径超过 `PATH_MAX`（4096）。
- **修复建议**：缩短路径或使用相对短名；必要时分目录存储。

## 三、文件不存在与路径问题

### 8. 13900002 — No such file or directory（ENOENT）

- **根因**：路径错误或文件未创建。最常见错误码。`access` 对不存在文件返回 false（不抛错），但 `open`/`stat`/`read`/`copy` 会抛 13900002。
- **修复建议**：先 `access`/`statSync` 判断存在性；确认路径拼接无误（注意相对/absolute path）；云盘/分布式文件本地缺失时也会返回此码。

### 9. 13900018 — Not a directory（ENOTDIR）

- **根因**：路径中某段本应是目录却指向文件（如 `/a.txt/b`）。
- **修复建议**：检查中间路径段是否均为目录。

### 10. 13900019 — Is a directory（EISDIR）

- **根因**：对目录执行仅限文件的操作，如 `read(fd)` 对目录 fd、`unlink` 目录。
- **修复建议**：目录用 `rmdir`/`rmdirSync`，文件用 `unlink`。

### 11. 13900015 — File exists（EEXIST）

- **根因**：`mkdir` 目标路径已存在（`MkdirExec` 中 `AccessCore` 返回 0 即抛 EEXIST）。
- **修复建议**：先判断存在性，或使用递归选项时先清理同名目录。

## 四、文件描述符与读写问题

### 12. 13900008 — Bad file descriptor（EBADF）

- **根因**：fd 已 `close` 或非法（`fd < 0`）、重复关闭、跨实例传递 fd。`ReadSync`/`WriteSync` 对 `fd < 0` 直接抛 EINVAL，对已关闭 fd 抛 EBADF。
- **修复建议**：确保 fd 来自 `open` 且仅 close 一次；避免跨 Worker/HAP 传递 fd。

### 13. 13900005 — I/O error（EIO）

- **根因**：底层读写失败，常见于存储介质异常、分布式文件网络抖动、配额服务异常。
- **修复建议**：重试；检查存储健康状态；分布式场景排查网络。

### 14. 13900011 — Out of memory（ENOMEM）

- **根因**：分配 `uv_fs_t` 或异步参数失败（代码中多处 `new (std::nothrow)` 失败时返回 ENOMEM）。
- **修复建议**：减少并发大对象；检查系统内存压力。

### 15. 13900022 — Too many open files（EMFILE）

- **根因**：进程打开文件数超限，通常是 fd 泄漏（未 close）。
- **修复建议**：复用 fd、及时 close；排查 `Stream`/`File`/`RandomAccessFile` 是否泄漏。

## 五、空间与配额问题

### 16. 13900025 — No space left on device（ENOSPC）

- **根因**：磁盘满。`write`/`copyFile`/`copyDir` 写入时空间不足。
- **修复建议**：先用 `statvfs.getFreeSize` 检查可用空间；清理缓存。

### 17. 13900041 — Quota exceeded（EDQUOT）

- **根因**：用户/应用磁盘配额超限（应用沙箱有配额上限）。
- **修复建议**：清理应用数据；申请更大配额或改用 cacheDir。

### 18. 13900024 — File too large（EFBIG）

- **根因**：文件超过 `RLIMIT_FSIZE` 或文件系统单文件上限。
- **修复建议**：分片存储或换用支持大文件的存储路径。

## 六、只读与跨设备问题

### 19. 13900027 — Read-only file system（EROFS）

- **根因**：对只读路径（如某些系统资源、外置只读存储）执行写入/删除。
- **修复建议**：改用应用可写目录（filesDir/cacheDir）。

### 20. 13900016 — Cross-device link（EXDEV）

- **根因**：`rename`/`moveFile` 跨挂载点（源与目标不在同一文件系统）。
- **修复建议**：跨设备场景改用 `copy` + `unlink` 组合，或使用 `move`（内部会处理跨设备复制）。

## 七、目录操作问题

### 21. 13900032 — Directory not empty（ENOTEMPTY）

- **根因**：`rmdir`/`rmdirSync` 对非空目录操作。
- **修复建议**：先递归清空子项，或使用支持递归删除的方案（`listFile` 遍历后删除）。

### 22. 13900033 — Too many symbolic links encountered（ELOOP）

- **根因**：符号链接循环或层级过深，常见于自引用 symlink 链。
- **修复建议**：检查 `symlink` 是否构成环；遍历时限制深度。

## 八、mmap 相关问题（13900056~13900061）

### 23. 13900056 — Buffer read/write out of bounds（E_MMAP_OOB）

- **根因**：对 mmap 返回的缓冲区读写越界（offset+length 超出映射区）。
- **修复建议**：按 `mmap` 返回的 size 严格限定访问范围。

### 24. 13900057 — Mmap buffer released（E_MMAP_FREE）

- **根因**：访问已被释放的 mmap 缓冲区。
- **修复建议**：释放后置空引用，避免再次访问。

### 25. 13900058 — Read-only mmap buffer（E_MMAP_RO）

- **根因**：对以只读模式映射的缓冲区执行写操作。
- **修复建议**：写场景使用 `MappingMode.READ_WRITE`。

### 26. 13900061 — Mmap does not support mapping this file（E_MMAP_FILE）

- **根因**：目标文件类型不支持 mmap（如管道、设备文件、size 为 0 的文件）。
- **修复建议**：确保是常规文件且 size > 0。

## 九、分布式/云文件（dfs / cloud）问题

### 27. 13900051 / 22400002 — Network is unreachable / Network unavailable

- **根因**：分布式文件（`/data/storage/el2/distributedfiles`）或云盘文件（`/data/storage/el2/cloud`）操作时网络异常。`connectDfs`/`disconnectDfs` 也可能触发。
- **修复建议**：检查网络连通性；分布式文件需设备已组网。

### 28. 13900054 — Operation canceled（ECANCELED）

- **根因**：dfs 传输任务被取消（`DFS_CANCEL_SUCCESS = 204` → ECANCELED）。
- **修复建议**：检查是否主动取消；重试。

### 29. 22400001 — Cloud status not ready

- **根因**：云盘未就绪（未登录/未同步）。云文件本地缺失时 `access` 可能返回 ENOENT（13900002）。
- **修复建议**：确认云账号登录并完成第一==次==同步；用 `flag = AccessFlag.LOCAL` 检查本地副本。

### 30. 22400004 — Exceed the maximum limit

- **根因**：分布式/云文件数量或大小超限。
- **修复建议**：减少同步文件数量。

## 十、能力不支持问题

### 31. 801 — The device doesn't support this api

- **根因**：设备/系统不支持该能力。`environment` 在未开启 `const.filemanager.full_mount.enable` 时返回 801（`CheckInvalidAccess`）。
- **修复建议**：开启全量挂载参数；或降级使用应用沙箱目录。

### 32. 13900031 — Function not implemented（ENOSYS）

- **根因**：当前平台/文件系统未实现该系统调用。
- **修复建议**：更换路径或改用兼容 API。

### 33. 13900042 — Unknown error（E_UKERR）

- **根因**：未识别的 errno 兜底码。`CommonErrCode::E_UNKNOWN_ERROR = 13900042`，所有 errCodeTable 中未命中的错误均映射到此。
- **修复建议**：抓取 hilog（tag `FileManagement`）获取底层 errno；联系平台排查。

## 通用排查指引

1. **抓日志**：开启 debug 日志 `param set param.key.fileapi.debug.log true`，hilog 过滤 tag `FileManagement` / `CoreFileKit.fileio`。代码中关键路径有 `HILOGE`/`HILOGD` 打印 errno。
2. **Metrics 上报**：错误路径会上报 `CoreFileKit.fileio.Dyn.<api>.Err` 指标，可用于定位失败 API。
3. **路径校验**：绝大多数参数类错误（401/13900020）源于路径，优先用应用沙箱目录（`getContext().filesDir`、`cacheDir`、`distributedFilesDir`、`cloudFileDir`）。
4. **fd 生命周期**：`open` 返回的 fd 必须配对 `close`；Stream/RandomAccessFile/File 对象内部持有 fd，需调 `close()` 释放。
