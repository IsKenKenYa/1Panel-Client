# OPENRESTY 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-13 16:42:21

## API端点总览

- 端点数量: **9**
- 方法总数: **10**

| 方法 | 数量 |
|------|------|
| GET | 4 |
| POST | 6 |

## API端点详情

### `/openresty`

#### GET

**摘要**: Load OpenResty conf

**标签**: OpenResty

**响应**:

- `200`: OK

---

### `/openresty/build`

#### POST

**摘要**: Build OpenResty

**标签**: OpenResty

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/openresty/https`

#### GET

**摘要**: Get default HTTPs status

**标签**: OpenResty

**响应**:

- `200`: OK

---

#### POST

**摘要**: Operate default HTTPs

**标签**: OpenResty

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/openresty/modules`

#### GET

**摘要**: Get OpenResty modules

**标签**: OpenResty

**响应**:

- `200`: OK

---

### `/openresty/modules/update`

#### POST

**摘要**: Update OpenResty module

**标签**: OpenResty

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/openresty/scope`

#### POST

**摘要**: Load partial OpenResty conf

**标签**: OpenResty

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/openresty/status`

#### GET

**摘要**: Load OpenResty status info

**标签**: OpenResty

**响应**:

- `200`: OK

---

### `/openresty/update`

#### POST

**摘要**: Update OpenResty conf

**标签**: OpenResty

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
