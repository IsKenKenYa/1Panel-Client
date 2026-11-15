# FILE 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:22

## API端点总览

- 端点数量: **67**
- 方法总数: **67**

| 方法 | 数量 |
|------|------|
| GET | 10 |
| POST | 57 |

## API端点详情

### `/backups/search/files`

#### POST

**摘要**: List files from backup accounts

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/daemonjson/file`

#### GET

**摘要**: Load docker daemon.json

**标签**: Container Docker

**响应**:

- `200`: OK

---

### `/containers/files/content`

#### POST

**摘要**: Get container file content

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/del`

#### POST

**摘要**: Delete container file

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/download`

#### POST

**摘要**: Download container file

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

---

### `/containers/files/search`

#### POST

**摘要**: List container files

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/size`

#### POST

**摘要**: Get container file size

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/upload`

#### POST

**摘要**: Upload container file

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| containerID | formData | unknown | 是 | containerID |
| path | formData | unknown | 是 | path |
| file | formData | unknown | 是 | file |

**响应**:

- `200`: OK

---

### `/files`

#### POST

**摘要**: Create file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/ai-search`

#### POST

**摘要**: File search: content grep + optional AI summary

**描述**: When file-management AI is enabled, returns mode=ai with summary and hits. When disabled, returns mode=grep with hits only. Scans file contents only. Supports match options, extension/size/time filters, and scan limits.

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/batch/check`

#### POST

**摘要**: Batch check file exist

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/batch/del`

#### POST

**摘要**: Batch delete file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/batch/role`

#### POST

**摘要**: Batch change file mode and owner

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/check`

#### POST

**摘要**: Check file exist

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/chunkdownload`

#### POST

**摘要**: Chunk Download file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/chunkupload`

#### POST

**摘要**: ChunkUpload file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| file | formData | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/compress`

#### POST

**摘要**: Compress file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/compress/stop`

#### POST

**摘要**: Stop compress task

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/content`

#### POST

**摘要**: Load file content

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/convert`

#### POST

**摘要**: Convert file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/convert/log`

#### POST

**摘要**: Convert file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/decompress`

#### POST

**摘要**: Decompress file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/decompress/stop`

#### POST

**摘要**: Stop decompress task

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/del`

#### POST

**摘要**: Delete file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/depth/size`

#### POST

**摘要**: Multi file size

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/download`

#### GET

**摘要**: Download file

**标签**: File

**响应**:

- `200`: OK

---

### `/files/favorite`

#### POST

**摘要**: Create favorite

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/favorite/del`

#### POST

**摘要**: Delete favorite

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/favorite/search`

#### POST

**摘要**: List favorites

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/history/content`

#### POST

**摘要**: Load file history content

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/history/del`

#### POST

**摘要**: Delete file history record

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/history/restore`

#### POST

**摘要**: Restore file history record

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/history/search`

#### POST

**摘要**: Load file history list

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/mode`

#### POST

**摘要**: Change file mode

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/mount`

#### POST

**摘要**: system mount

**标签**: File

**响应**:

- `200`: OK

---

### `/files/move`

#### POST

**摘要**: Move file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/move/stop`

#### POST

**摘要**: Stop file move task

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/owner`

#### POST

**摘要**: Change file owner

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/preview`

#### POST

**摘要**: Preview file content

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/read/{type}`

#### POST

**摘要**: Read file by Line

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| type | path | unknown | 是 | type |
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/recycle/clear`

#### POST

**摘要**: Clear RecycleBin files

**标签**: File

**响应**:

- `200`: OK

---

### `/files/recycle/reduce`

#### POST

**摘要**: Reduce RecycleBin files

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/recycle/search`

#### POST

**摘要**: List RecycleBin files

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/recycle/status`

#### GET

**摘要**: Get RecycleBin status

**标签**: File

**响应**:

- `200`: OK

---

### `/files/remark`

#### POST

**摘要**: Set file remark

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/remarks`

#### POST

**摘要**: Batch get file remarks

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/rename`

#### POST

**摘要**: Change file name

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/save`

#### POST

**摘要**: Update file content

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/search`

#### POST

**摘要**: List files

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/share/check`

#### GET

**摘要**: Check file share code (no login)

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| code | query | unknown | 是 | share code |
| password | query | unknown | 否 | optional password |

**响应**:

- `200`: OK

---

### `/files/share/create`

#### POST

**摘要**: Create temporary file share link

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/share/del`

#### POST

**摘要**: Delete file share by path

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/share/detail`

#### POST

**摘要**: Get file share detail by path

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/share/download`

#### GET

**摘要**: Download file by share code (no login)

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| code | query | unknown | 是 | share code |
| password | query | unknown | 否 | optional password |

**响应**:

- `200`: OK

---

### `/files/share/info`

#### GET

**摘要**: Get file share detail by code (no login)

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| code | query | unknown | 是 | share code |

**响应**:

- `200`: OK

---

### `/files/share/qrcode`

#### GET

**摘要**: Get file share QR code image

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| code | query | unknown | 是 | share code |
| operateNode | query | unknown | 否 | operate node |

**响应**:

- `200`: OK

---

### `/files/share/search`

#### POST

**摘要**: List file shares

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/size`

#### POST

**摘要**: Load file size

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/tree`

#### POST

**摘要**: Load files tree

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/upload`

#### POST

**摘要**: Upload file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| file | formData | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/upload/search`

#### POST

**摘要**: Page file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/user/group`

#### POST

**摘要**: system user and group

**标签**: File

**响应**:

- `200`: OK

---

### `/files/wget`

#### POST

**摘要**: Wget file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/wget/process`

#### GET

**摘要**: Wget process

**标签**: File

**响应**:

- `200`: OK

---

### `/files/wget/process/keys`

#### GET

**摘要**: Process keys

**标签**: File

**响应**:

- `200`: OK

---

### `/files/wget/stop`

#### POST

**摘要**: Stop wget file download

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/logs/system/files`

#### GET

**摘要**: Load system log files

**标签**: Logs

**响应**:

- `200`: OK

---
