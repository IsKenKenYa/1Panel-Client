# filemanagement_filemanagement_cangjie_wrapper 常见问题模式

> 仓颉（Cangjie）语言实现的文件管理 API 封装（非 NAPI）。错误经 `BusinessException` 抛出，码值 errno 风格（基址 13900000，POSIX errno）。
> 统一错误处理：`code = Ffi*(...)` → `if code != SUCCESS_CODE` → `FS_LOG.error(getErrorInfo(code))` → `throw BusinessException(code, getErrorInfo(code))`。
> 注意：`getErrorInfo` 仅查 `ERROR_CODE_MAP`（见 `ohos/file/fs/conflict_file_exception.cj`），未命中返回 "Unknown error"。**13900043、14300002 不在 map 中**，异常 code 仍为原值但 message 会回落为 "Unknown error"。

---

## 一、参数校验类（13900020 EINVAL，最高频）

`INVALID_ARGS_CODE = 13900020` 是本模块最常见的错误码。触发场景：

- **空字符串路径**：`FileIo.open("")`、`FileUri("")`、`getUriFromPath("")` 等在仓颉侧直接校验抛 13900020。
  - 排查：打印入参路径，确认非空且为合法absolute path。
  - 源码：`ohos/file/fileuri/file_uri.cj:108`（FileUri）、`file_uri.cj:199`（getUriFromPath）。
- **Filter / AccessModeType / WhenceType 非法枚举值**：`listFile` 的 Filter、`access` 的 mode、`lseek` 的 whence 传入非法整型。
  - 排查：使用枚举类型常量（`AccessModeType.Exist`、`WhenceType.SeekSet` 等），勿手填裸整数。
  - 源码：`ohos/file/fs/cj_file_fs.cj`（access:1202 / lseek:2461 / listFile:2550）。
- **WriteOptions.length > buffer.size**：`Stream.write`、`RandomAccessFile.write`、`FileIo.write` 中 options.length 超出实际缓冲长度。
  - 排查：核对 `WriteOptions.length` 与 buffer 大小关系。
  - 源码：`stream.cj:129/187`、`random_access_file.cj:124/159`。
- **createRandomAccessFile 误传 start/end**：旧版/异构参数透传（如把 RandomAccessFileOptions 的 offset 当 start/end）。
  - 排查：按 `RandomAccessFileOptions` 字段构造，避免手填无关键。
  - 源码：`cj_file_fs.cj:1797/1875`。
- **OpenMode 非法组合**：open 的 mode 未用 `OpenMode` 常量按位或。

---

## 二、路径/文件不存在（13900002 ENOENT，高频）

- 任意需要解析路径的 API（open/stat/access/rename/unlink/rmdir/moveDir/copyDir/copyFile/moveFile/mkdtemp/truncate/listFile/readText/utimes）在路径不存在时 native 返回 ENOENT。
- 排查：
  1. 确认路径前缀是否在应用沙箱可见范围内（仓颉接口默认沙箱内）。
  2. 调用前用 `FileIo.access(path, AccessModeType.Exist)` 预检，或先 `stat` 探测。
  3. 注意相对路径与absolute path混用——仓颉文件接口建议使用应用沙箱absolute path。
- 源码：`ohos/file/fs/conflict_file_exception.cj:27`（map 定义）。

---

## 三、权限（13900012 EACCES）

- 仓颉接口大多运行在应用沙箱内，权限问题相对少；典型触发：
  - `access(path, Read/Write)` 对无权限路径返回 13900012。
  - `open` 带 WRITE 到只读沙箱外路径、`mkdir`/`unlink`/`rename` 跨越无写权限目录。
- 排查：
  1. 确认目标路径属于应用沙箱（`getFilesDir`/`getCacheDir`/`getDistributedFilesDir` 等 context 路径）。
  2. 公共目录访问需通过选择器或公共文件服务，**仓颉 Beta 不支持**（见末尾 Beta 限制）。
  3. 检查模块是否声明了对应权限（沙箱内一般无需额外权限）。
- 源码：`conflict_file_exception.cj:37`。

---

## 四、I/O 错误（13900005 EIO）

- 底层读写 I/O 失败，通常是存储介质异常、文件系统损坏、native 侧 libc 返回 EIO。
- 文档声明可抛的 API：createStream/fdopenStream/lstat/Stat 属性/getParent/Stream 全系列/RandomAccessFile 全系列等。
- 排查：复现率低时优先排查目标文件是否被外部进程损坏、是否在可移动/网络挂载上。重试或换路径验证。

---

## 五、文件描述符（13900008 EBADF）

- **close 后误用 fd** 是最典型场景：`FileIo.close(file)` 后再次 read/write/lseek/fsync/fdatasync，或对已 close 的 Stream/RandomAccessFile 继续操作。
- `dup`/`fdopenStream` 传入非法 fd。
- 排查：
  1. 关闭后立即将引用置空/标记，避免悬空使用。
  2. 记录 fd 生命周期：open → 使用 → close，单一线性流程。
  3. 注意 `File` 对象析构（`~init` → `releaseFFIData`）会释放 FFI 句柄，重复 close 同一 File 可能触发。
- 源码：`conflict_file_exception.cj:33`；`file.cj:36`（析构）。

---

## 六、目录操作类

- **13900018 Not a directory**：路径中某段应为目录但实际是文件（如 rmdir("/a/b.txt/c")、moveDir 父段非目录）。
- **13900019 Is a directory**：对目录执行仅文件可用操作——`unlink` 删目录、`open(WRITE)` 目录、`readText`/Stream 写目录、`truncate` 目录。
- **13900032 Directory not empty**：`rmdir` 非空目录（非递归模式）。改用 `moveDir`/递归清理或专用递归删除。
- **13900027 Read-only file system**：在只读分区/系统资源目录上执行 mkdir/open(WRITE)/unlink/rename。
- 排查：先用 `stat(path).isDirectory()` 判定节点类型；递归目录操作确认调用语义（`mkdir(path, recursion=true)`）。
- 源码：`conflict_file_exception.cj:43/45/57/53`。

---

## 七、磁盘空间 / 配额（13900025 ENOSPC、13900041 EDQUOT）

- **13900025**：磁盘空间不足，write/mkdir/copyFile/moveFile 写入耗尽空间。
- **13900041**：配额超限（应用沙箱/用户配额耗尽）。注意沙箱环境更易触发配额而非裸空间不足。
- 排查：
  1. 仓颉 Beta **不支持**文件系统空间统计/应用空间统计 API，需通过系统设置或其它途径查看空间。
  2. 写入大文件前做大小预估，分片写入。
  3. 清理 cache 目录后重试。
- 源码：`conflict_file_exception.cj:50/66`。

---

## 八、文件锁（13900043 ENOLCK，不在 map）

- 仅 `File.tryLock(exclusive)` 与 `File.unlock` 抛出，native 在锁资源耗尽或锁状态错误时返回该码。
- **重要**：13900043 不在 `ERROR_CODE_MAP`，`getErrorInfo(13900043)` 会回落为 "Unknown error"，但 `BusinessException` 抛出的 code 仍为 13900043。日志/异常处理时需特殊识别此码而非仅看 message。
- 排查：
  1. 确认 tryLock 与 unlock 配对，避免泄漏锁。
  2. 非阻塞 tryLock 获取失败可能抛 13900034（Operation would block），需与 13900043 区分。
- 源码：`ohos/file/fs/file.cj:102/125`。

---

## 九、URI 相关

- **14300002 Invalid uri**（AppFileService 域，不在 fs map）：`FileUri(uriOrPath)`、`File.getParent` 在 native 校验 URI 失败时抛出。
  - 排查：确认 URI scheme（如 `file://`）合法、路径在沙箱内；FileUri 暂不支持外部存储目录。
  - 源码：`ohos/file/fileuri/file_uri.cj`（FileUri 构造）、`ohos/file/fs/file.cj:146`（getParent 文档声明）。
- **13900031 Function not implemented**：仅在使用基类 `Uri.path`/`Uri.toString`（而非 `FileUri` 子类）时抛出 "The prop/function is not supported."。
  - 注意：`FileUri` 已重写 path/toString 为可用实现，正常使用 FileUri 不会触发 13900031。
  - 源码：`file_uri.cj:60/74`（基类抛出点）。

---

## 十、并发 / 线程约束

- 部分接口标注 `workerthread: true`（或通过 @!APILevel/调度约束），不可在主线程调用，否则可能阻塞 UI 或触发系统约束错误。
- 排查：将文件密集操作（大文件 copyFile/moveFile、listFile 大目录、readText 大文件、readLines 全量迭代）放入 worker/异步上下文。
- 仓颉侧无显式并发计数限制（单并发任务约束属于本平台 Location VOD 运行时，非模块本身）。

---

## 十一、Beta 限制（不支持的能力）

相对等价 ArkTS `@ohos.file.fs` / `@ohos.file.fileuri`，仓颉 Beta **不支持**以下能力，调用对应（不存在的）API 会编译失败或行为受限：

- 端云同步、目录环境（environment）、文件哈希（hash）、选择器（picker）、数据标签（statfs/data label）。
- 文件系统空间统计（statfs）、应用空间统计。
- 文件分享。
- 文件 URI 不支持外部存储目录。
- 仅 standard 设备；文件接口仅支持 UTF-8 / UTF-16。

排查"找不到 API"或"行为与 ArkTS 不一致"类问题时，优先确认是否落入上述未支持范围。详见 `README.md` / `README_zh.md`。

---

## 通用排查清单

1. **抓取异常 code 与 message**：仓颉 `BusinessException` 直接含 code；注意 message 对未在 map 的码（13900043/14300002）会显示 "Unknown error"，需以 code 为准。
2. **核对 hilog**：模块 hilog domain `FILEIO_DOMAIN_ID = 0xD004388u32`（FileUri 用 `0xD003900`），搜索该 domain 可定位 native 返回的原始 code。
3. **路径规范化**：始终使用 context 提供的沙箱根路径拼接，避免硬编码。
4. **fd/句柄生命周期**：open/create/dup 与 close 显式配对，依赖析构（`~init` → `releaseFFIData`）兜底但不要滥用。
5. **重载选择**：copyFile/truncate/close/createRandomAccessFile/mkdir/write 等有多个重载，按入参类型（String vs Int32 vs File）匹配，误用易触发 13900020。
