# CRONJOB 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:55

## API端点总览

- 端点数量: **16**
- 方法总数: **16**

| 方法 | 数量 |
|------|------|
| GET | 1 |
| POST | 15 |

## API端点详情

### `/cronjobs`

#### POST

**摘要**: Create cronjob

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/del`

#### POST

**摘要**: Delete cronjob

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/export`

#### POST

**摘要**: Export cronjob list

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/group/update`

#### POST

**摘要**: Update cronjob group

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/handle`

#### POST

**摘要**: Handle cronjob once

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/import`

#### POST

**摘要**: Import cronjob list

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/load/info`

#### POST

**摘要**: Load cronjob info

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/next`

#### POST

**摘要**: Load cronjob spec time

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/records/clean`

#### POST

**摘要**: Clean job records

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/records/log`

#### POST

**摘要**: Load Cronjob record log

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/script/options`

#### GET

**摘要**: Load script options

**标签**: Cronjob

**响应**:

- `200`: OK

---

### `/cronjobs/search`

#### POST

**摘要**: Page cronjobs

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/search/records`

#### POST

**摘要**: Page job records

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/status`

#### POST

**摘要**: Update cronjob status

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/stop`

#### POST

**摘要**: Handle stop job

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/update`

#### POST

**摘要**: Update cronjob

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
