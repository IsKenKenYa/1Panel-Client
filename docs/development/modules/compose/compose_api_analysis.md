# COMPOSE 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-02-23 20:50:14

## API端点总览

- 端点数量: **7**
- 方法总数: **7**

| 方法 | 数量 |
|------|------|
| POST | 7 |

## API端点详情

### `/containers/compose`

#### POST

**摘要**: Create compose

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/clean/log`

#### POST

**摘要**: Clean compose log

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/operate`

#### POST

**摘要**: Operate compose

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/search`

#### POST

**摘要**: Page composes

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/test`

#### POST

**摘要**: Test compose

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/update`

#### POST

**摘要**: Update compose

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/exec/composer`

#### POST

**摘要**: Exec Composer

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
