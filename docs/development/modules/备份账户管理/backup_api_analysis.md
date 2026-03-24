# BACKUP 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:54

## API端点总览

- 端点数量: **25**
- 方法总数: **25**

| 方法 | 数量 |
|------|------|
| GET | 3 |
| POST | 22 |

## API端点详情

### `/backups`

#### POST

**摘要**: Create backup account

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/backup`

#### POST

**摘要**: Backup system data

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/buckets`

#### POST

**摘要**: List buckets

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/check`

#### POST

**摘要**: Check backup account

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/del`

#### POST

**摘要**: Delete backup account

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/local`

#### GET

**摘要**: get local backup dir

**标签**: Backup Account

**响应**:

- `200`: OK

---

### `/backups/options`

#### GET

**摘要**: Load backup account options

**标签**: Backup Account

**响应**:

- `200`: OK

---

### `/backups/record/del`

#### POST

**摘要**: Delete backup record

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/record/description/update`

#### POST

**摘要**: Update backup record description

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/record/download`

#### POST

**摘要**: Download backup record

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/record/search`

#### POST

**摘要**: Page backup records

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/record/search/bycronjob`

#### POST

**摘要**: Page backup records by cronjob

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/record/size`

#### POST

**摘要**: Load backup record size

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/recover`

#### POST

**摘要**: Recover system data

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/recover/byupload`

#### POST

**摘要**: Recover system data by upload

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/refresh/token`

#### POST

**摘要**: Refresh token

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/search`

#### POST

**摘要**: Search backup accounts with page

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

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

### `/backups/update`

#### POST

**摘要**: Update backup account

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/backups/upload`

#### POST

**摘要**: Upload file for recover

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/backups`

#### POST

**摘要**: Create backup account

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/backups/client/:clientType`

#### GET

**摘要**: Load backup account base info

**标签**: Backup Account

**响应**:

- `200`: OK

---

### `/core/backups/del`

#### POST

**摘要**: Delete backup account

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/backups/refresh/token`

#### POST

**摘要**: Refresh token

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/backups/update`

#### POST

**摘要**: Update backup account

**标签**: Backup Account

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
