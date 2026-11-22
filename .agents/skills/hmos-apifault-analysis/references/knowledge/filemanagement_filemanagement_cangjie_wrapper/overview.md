# filemanagement_filemanagement_cangjie_wrapper 模块概览

## 模块职责

为 （standard 设备）应用开发者提供 **仓颉（Cangjie）语言** 的文件管理 API 封装。覆盖文件基本管理（打开/读写/移动/拷贝/删除/截断/同步）、目录管理（创建/递归移动拷贝/列举）、文件信息统计（Stat 元数据）、流式读写（Stream / RandomAccessFile）、文件 URI 等核心能力。

本模块 **不是 NAPI/JS 模块**，而是用 `.cj`（仓颉）语言实现，通过仓颉 FFI（`foreign` 声明的 `FfiOHOS*` 函数）调用底层 native C 实现。native 实现位于外部依赖组件 `file_api`（文件/目录/流）与 `app_file_service`（URI / 公共文件访问），本仓不含 native 源码。

- 组件名：`@ohos/filemanagement_cangjie_wrapper`
- subsystem：filemanagement，version 6.1，仅 standard，ROM 467KB / RAM 412KB
- **Beta API**（能力范围小于等价的 ArkTS `@ohos.file.fs` / `@ohos.file.fileuri`）
- 错误统一模式：调用 FFI → 检查 `code != SUCCESS_CODE` → `FS_LOG.error(getErrorInfo(code))` → `throw BusinessException(code, getErrorInfo(code))`
- FFI 句柄通过 `RemoteDataLite` 管理，析构 `releaseFFIData` 释放

## 目录结构（简化）

```
filemanagement_filemanagement_cangjie_wrapper/
├── kit/CoreFileKit/index.cj          # Kit 入口：public import ohos.file.fs.* 和 ohos.file.fileuri.*
├── ohos/file/
│   ├── file_package.cj               # package 文件
│   ├── fs/                           # package ohos.file.fs —— 基本文件管理
│   │   ├── native.cj                 # FFI 声明（~60 个 FfiOHOS* foreign 函数）
│   │   ├── cj_file_fs.cj             # FileIo 静态类 + 数据结构（Options/OpenMode/Stat 等）
│   │   ├── file.cj                   # File 类（fd/path/name/tryLock/unlock/getParent）
│   │   ├── stat.cj                   # Stat 类（元数据 + isXxx 判定）
│   │   ├── stream.cj                 # Stream 类（close/flush/read/write）
│   │   ├── random_access_file.cj     # RandomAccessFile 类（随机读写）
│   │   └── conflict_file_exception.cj# ERROR_CODE_MAP + getErrorInfo()
│   └── fileuri/file_uri.cj           # package ohos.file.fileuri —— 文件 URI
├── mock/                             # 仓颉 mock（测试桩）
└── test/                             # 测试（file_uri / filemanagement）
```

## 核心文件清单

| 路径（相对模块根） | 用途 |
|---|---|
| `kit/CoreFileKit/index.cj` | Kit 入口，public import 暴露 `ohos.file.fs.*` 与 `ohos.file.fileuri.*` |
| `ohos/file/fs/cj_file_fs.cj` | **核心 API**：`FileIo` 静态类（stat/open/read/write/mkdir/copy/move/listFile/readText/utimes 等 40+ 方法）及全部数据结构（OpenMode/Options/Filter/ListFileOptions 等） |
| `ohos/file/fs/native.cj` | FFI 声明层：~60 个 `foreign func FfiOHOS*`（File/Stat/Stream/RandomAccessFile/File 系列） |
| `ohos/file/fs/file.cj` | `File` 类：fd/path/name 属性 + tryLock/unlock/getParent |
| `ohos/file/fs/stat.cj` | `Stat` 类：ino/mode/uid/gid/size/atime/mtime/ctime + isBlockDevice/isDirectory/isFile 等 |
| `ohos/file/fs/stream.cj` | `Stream` 类：close/flush/read/write |
| `ohos/file/fs/random_access_file.cj` | `RandomAccessFile` 类：fd/filePointer/setFilePointer/close/read/write |
| `ohos/file/fs/conflict_file_exception.cj` | `ERROR_CODE_MAP`（13900001~13900042、13900044）+ `getErrorInfo()`；常量 `FILEIO_DOMAIN_ID=0xD004388u32`、`INVALID_ARGS_CODE=13900020` |
| `ohos/file/fileuri/file_uri.cj` | `Uri`（基类，path/toString 未实现抛 13900031）/ `FileUri` / `getUriFromPath`；内含 FileUri 专属 FFI（FfiOHOSFILEUri*） |
| `bundle.json` | 构建依赖：app_file_service、cangjie_ark_interop（BusinessException/APILevel/FFI）、hiviewdfx_cangjie_wrapper（Hilog）、file_api |

## 分层调用链（无 NAPI）

```
仓颉应用(.cj)
  → ohos.file.fs.FileIo::open(...)        [cj_file_fs.cj]
  → foreign FfiOHOSFileFsOpen(...)        [native.cj FFI 声明]
  → native C 实现（file_api 组件，外部仓 filemanagement_file_api）
  → OS 文件系统（open/read/write/mkdir 等 libc）
```

FileUri 链路：`ohos.file.fileuri.FileUri` / `getUriFromPath` → `FfiOHOSFILEUri*`（声明在 `file_uri.cj` 顶部）→ native（app_file_service 组件）。

## 关键约束（README）

- 仅 standard 设备；文件接口仅支持 UTF-8 / UTF-16。
- 文件 URI 暂不支持外部存储目录。
- 相对 ArkTS 不支持：端云同步、目录环境、文件哈希、选择器、数据标签、文件系统/应用空间统计、文件分享。
- Beta 特性，能力范围小于等价 ArkTS API。
