# B2 文件管理深度 · 宿主通道契约 v1（冻结）

> Dart handler 与 C# WindowsBridge 的单一事实源。服务端端点对照上游 `frontend/src/api/modules/files.ts`。
> MDUI3 现成底层：`lib/api/v2/file_v2.dart`（80+ 方法）与 `FileBrowserService`。

## 写通道（全部 `{success, error?}` 惯例）

| method | 参数（扁平） | 服务端端点 |
| --- | --- | --- |
| createFileHandler | `{path: string(全路径)}`（isDir=false 固定） | POST /files |
| renameFileHandler | `{oldName: string(完整旧路径), newName: string(完整新路径)}` | POST /files/rename |
| moveFilesHandler | `{oldPaths: string[], newPath: string(目标目录), type: 'copy'\|'cut'}` | POST /files/move |
| compressFilesHandler | `{files: string[], type: string(zip\|gz\|tar.gz…), dst: string, name: string}` | POST /files/compress |
| decompressFileHandler | `{path: string, dst: string, type: string}` | POST /files/decompress |
| changeFileModeHandler | `{path: string, mode: int(八进制值如 493=0755)}` | POST /files/mode |
| changeFileOwnerHandler | `{path: string, user: string, group: string}` | POST /files/owner |
| getFileContentHandler | `{path: string}` | POST /files/content `{path, expand:true}` |
| saveFileContentHandler | `{path: string, content: string}` | POST /files/save |
| addFavoriteHandler | `{path: string}` | POST /files/favorite |
| removeFavoriteHandler | `{id: int}` | POST /files/favorite/del |
| getFavoritesHandler | `{}` | POST /files/favorite/search |
| wgetDownloadHandler | `{url: string, path: string, name: string}` | POST /files/wget |

## 既有方法修复

| method | 修复 |
| --- | --- |
| deleteFile | C# `DeleteFileAsync` 需透传 `isDir: bool` 参数（Dart handler 已支持 `{path, isDir?}`），FilesPage 行删除按条目类型传入 |

## 实现约定

1. 同 B1：读 handler 原样透传/空值惯例；写 handler `{success, error?}` + 必填缺失快速失败；dispatch 全注册。
2. `moveFilesHandler` 的 `oldPaths` 与 `compressFilesHandler` 的 `files` 为字符串数组（StandardMessageCodec List<String> 直传）。
3. `getFileContentHandler` 返回 `{content}` 或服务端原始对象（含 `content` 键），C# 端取 `content` 字段。
