# FILE 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-02-16 23:11:15

## API端点总览

- 端点数量: **53**
- 方法总数: **53**

| 方法 | 数量 |
|------|------|
| GET | 4 |
| POST | 49 |

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

### `/databases/common/load/file`

#### POST

**摘要**: Load Database conf

**标签**: Database Common

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/files/read`

#### POST

**摘要**: Read file by Line

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
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

### `/hosts/ssh/file`

#### POST

**摘要**: Load host SSH conf

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/file/update`

#### POST

**摘要**: Update host SSH setting by file

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/supervisor/process/file`

#### POST

**摘要**: Get Supervisor process config file

**标签**: Host tool

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

### `/openresty/file`

#### POST

**摘要**: Update OpenResty conf by upload file

**标签**: OpenResty

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/file`

#### POST

**摘要**: Get php conf file

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/supervisor/process/file`

#### POST

**摘要**: Operate supervisor process file

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/file/search`

#### POST

**摘要**: Load clam file

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/file/update`

#### POST

**摘要**: Update clam file

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/lbs/file`

#### POST

**摘要**: Update website upstream file

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/proxies/file`

#### POST

**摘要**: Update proxy file

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/redirect/file`

#### POST

**摘要**: Update redirect file

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/upload/file`

#### POST

**摘要**: Upload SSL file

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| type | formData | unknown | 是 | type |
| description | formData | unknown | 否 | description |
| sslID | formData | unknown | 否 | sslID |
| privateKeyFile | formData | unknown | 是 | privateKeyFile |
| certificateFile | formData | unknown | 是 | certificateFile |

**响应**:

- `200`: OK

---
