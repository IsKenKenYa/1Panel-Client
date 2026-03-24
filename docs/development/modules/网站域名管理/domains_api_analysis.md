# DOMAINS 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-13 16:41:57

## API端点总览

- 端点数量: **4**
- 方法总数: **4**

| 方法 | 数量 |
|------|------|
| GET | 1 |
| POST | 3 |

## API端点详情

### `/websites/domains`

#### POST

**摘要**: Create website domain

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/domains/:websiteId`

#### GET

**摘要**: Search website domains by websiteId

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| websiteId | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/domains/del`

#### POST

**摘要**: Delete website domain

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/domains/update`

#### POST

**摘要**: Update website domain

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
