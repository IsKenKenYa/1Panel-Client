# filemanagement_file_api 模块概览

## 模块职责

`filemanagement_file_api` 是 **CoreFileKit** 的 C++/NAPI 实现层，提供应用沙箱内基础文件 IO 能力。它通过 5 个 NAPI 模块对外暴露 5 个 JS API 命名空间：`@ohos.file.fs`（核心文件 IO）、`@ohos.file.hash`（文件哈希）、`@ohos.file.statvfs`（文件系统空间统计）、`@ohos.file.environment`（系统目录，系统 API）、`@ohos.file.securityLabel`（数据安全等级 s0~s4）。

实现上基于 **libuv（uv_fs_*）** 完成 POSIX 风格的同步/异步文件操作，并自研 **LibN** 框架（`common/napi/`）封装 NAPI 与异步工作（Promise / Callback 两套）。错误码统一以 `FILEIO_SYS_CAP_TAG = 13900000` 为前缀，由 `utils/filemgmt_libfs/include/fs_error.h` 的 `errCodeTable` 完成 POSIX errno → 业务错误码的映射。

## 简化目录树（3 层）

```
filemanagement_file_api/
├── interfaces/kits/js/src/          # NAPI/JS 接口实现主目录
│   ├── mod_fs/                       # @ohos.file.fs 模块（nm_modname = "file.fs"）
│   │   ├── module.cpp                # 模块入口，初始化各 Exporter
│   │   ├── properties/               # 属性函数（open/copy/mkdir/list_file/stream...）+ ani/
│   │   │   └── prop_n_exporter.cpp   # @ohos.file.fs 全部属性函数导出（Sync+Async）
│   │   ├── class_file/               # File 类（fs_file.cpp, file_n_exporter.cpp）
│   │   ├── class_stat/               # Stat 类（fs_stat.cpp, stat_n_exporter.cpp）
│   │   ├── class_stream/             # Stream 流类
│   │   ├── class_watcher/            # 文件监听 Watcher
│   │   ├── class_filemapping/        # 文件映射 FileMapping / mmap
│   │   ├── class_randomaccessfile/   # RandomAccessFile
│   │   └── class_readeriterator/     # ReaderIterator（listFile 迭代器）
│   ├── mod_hash/                     # @ohos.file.hash（file.hash）+ HashStream
│   ├── mod_statvfs/                  # @ohos.file.statvfs（file.statvfs）
│   ├── mod_environment/              # @ohos.file.environment（file.environment，系统 API）
│   ├── mod_securitylabel/            # @ohos.file.securityLabel（file.securityLabel）
│   └── common/                       # 公共框架
│       ├── napi/                     # LibN 框架（n_class/n_func_arg/n_val/n_async）
│       └── uni_error.{h,cpp}         # 统一错误处理
├── interfaces/kits/c/common/         # C-API 公共错误码
│   └── error_code.h
├── interfaces/kits/native/           # Native C++ 桥接（fileio_native / environment_native）
├── utils/filemgmt_libfs/include/
│   └── fs_error.h                    # 核心错误码定义表（errCodeTable）
└── interfaces/test/                  # 单元测试
```

## 核心文件清单

| 文件（相对模块根） | 用途 |
| --- | --- |
| `interfaces/kits/js/src/mod_fs/module.cpp` | `file.fs` 模块注册入口（nm_modname = "file.fs"），初始化 OpenMode/Whence/Mapping 等枚举并构造各 Exporter |
| `interfaces/kits/js/src/mod_fs/properties/prop_n_exporter.cpp` | 导出 @ohos.file.fs 全部属性函数：access/close/open/read/write/mkdir/stat/copy/move/listFile/stream/mmap 等（Sync 与 Async 两套） |
| `interfaces/kits/js/src/mod_fs/class_file/file_n_exporter.cpp` | File 类导出（fd 包装，readSync/writeSync/close 等） |
| `interfaces/kits/js/src/mod_fs/class_stat/stat_n_exporter.cpp` | Stat 类导出（文件元数据 size/mtime/...） |
| `interfaces/kits/js/src/mod_fs/class_stream/stream_n_exporter.cpp` | Stream 流类导出（read/write/close 流式 API） |
| `interfaces/kits/js/src/mod_fs/class_watcher/watcher_n_exporter.cpp` | 文件监听 Watcher 类（createWatcher） |
| `interfaces/kits/js/src/mod_fs/class_filemapping/` | 文件映射 mmap 实现（mmapSync / mmap） |
| `interfaces/kits/js/src/mod_hash/module.cpp` | `file.hash` 模块入口，注册 HashNExporter + HashStreamNExporter |
| `interfaces/kits/js/src/mod_hash/hash.cpp` | `hash()` 实现，支持 md5/sha1/sha256（调用 DistributedFS::HashFile） |
| `interfaces/kits/js/src/mod_statvfs/statvfs_napi.cpp` | `file.statvfs` 模块入口 + getFreeSize/getTotalSize（Sync/Async），基于 `statvfs(2)` |
| `interfaces/kits/js/src/mod_statvfs/statvfs_n_exporter.cpp` | getFreeSize / getTotalSize 实现 |
| `interfaces/kits/js/src/mod_environment/environment_napi.cpp` | `file.environment` 模块入口（系统 API） |
| `interfaces/kits/js/src/mod_environment/environment_n_exporter.cpp` | getUserDataDir/getUserDownloadDir/getUserDesktopDir 等系统目录获取，含权限与系统应用校验 |
| `interfaces/kits/js/src/mod_securitylabel/securitylabel_napi.cpp` | `file.securityLabel` 模块入口 |
| `interfaces/kits/js/src/mod_securitylabel/securitylabel_n_exporter.cpp` | setSecurityLabel / getSecurityLabel（s0~s4）实现 |
| `interfaces/kits/js/src/common/napi/` | LibN 框架：n_async_work_promise.cpp / n_async_work_callback.cpp（异步工作），n_func_arg（参数解析），n_val，n_class |
| `interfaces/kits/js/src/common/uni_error.{h,cpp}` | 统一错误处理（NError/UniError） |
| `utils/filemgmt_libfs/include/fs_error.h` | **核心错误码表**：FILEIO_SYS_CAP_TAG=13900000，errCodeTable 完成 errno→错误码+消息映射，覆盖 FileIO/StorageService/UserFileMgr/UserFileService/DistributedFile 多子系统前缀 |
| `interfaces/kits/c/common/error_code.h` | C-API 层错误码定义 |
| `interfaces/kits/native/fileio_native.cpp` | Native C++ 桥接（Native API 接口） |
