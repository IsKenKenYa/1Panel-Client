# WEBSITE_SSL 模块API端点详细分析

> 基于 1PanelV2OpenAPI.json 自动生成
> 生成时间: 2026-03-13 16:42:03

## API端点总览

- 端点数量: **11**
- 方法总数: **11**

| 方法 | 数量 |
|------|------|
| GET | 2 |
| POST | 9 |

## API端点详情

### `/websites/ssl`

#### POST

**摘要**: Create website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/:id`

#### GET

**摘要**: Search website ssl by id

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/del`

#### POST

**摘要**: Delete website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/download`

#### POST

**摘要**: Download SSL  file

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/obtain`

#### POST

**摘要**: Apply  ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/resolve`

#### POST

**摘要**: Resolve website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/search`

#### POST

**摘要**: Page website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/update`

#### POST

**摘要**: Update ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/upload`

#### POST

**摘要**: Upload ssl

**标签**: Website SSL

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

### `/websites/ssl/website/:websiteId`

#### GET

**摘要**: Search website ssl by website id

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| websiteId | path | unknown | 是 | request |

**响应**:

- `200`: OK

---
