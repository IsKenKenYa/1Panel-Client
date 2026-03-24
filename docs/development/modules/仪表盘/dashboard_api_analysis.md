# DASHBOARD 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-02-15 15:17:29

## API端点总览

- 端点数量: **12**
- 方法总数: **12**

| 方法 | 数量 |
|------|------|
| GET | 8 |
| POST | 4 |

## API端点详情

### `/dashboard/app/launcher`

#### GET

**摘要**: Load app launcher

**标签**: Dashboard

**响应**:

- `200`: OK

---

### `/dashboard/app/launcher/option`

#### POST

**摘要**: Load app launcher options

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/dashboard/app/launcher/show`

#### POST

**摘要**: Update app Launcher

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/dashboard/base/:ioOption/:netOption`

#### GET

**摘要**: Load dashboard base info

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| ioOption | path | unknown | 是 | request |
| netOption | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/dashboard/base/os`

#### GET

**摘要**: Load os info

**标签**: Dashboard

**响应**:

- `200`: OK

---

### `/dashboard/current/:ioOption/:netOption`

#### GET

**摘要**: Load dashboard current info

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| ioOption | path | unknown | 是 | request |
| netOption | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/dashboard/current/node`

#### GET

**摘要**: Load dashboard current info for node

**标签**: Dashboard

**响应**:

- `200`: OK

---

### `/dashboard/current/top/cpu`

#### GET

**摘要**: Load top cpu processes

**标签**: Dashboard

**响应**:

- `200`: OK

---

### `/dashboard/current/top/mem`

#### GET

**摘要**: Load top memory processes

**标签**: Dashboard

**响应**:

- `200`: OK

---

### `/dashboard/quick/change`

#### POST

**摘要**: Update quick jump

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/dashboard/quick/option`

#### GET

**摘要**: Load quick jump options

**标签**: Dashboard

**响应**:

- `200`: OK

---

### `/dashboard/system/restart/:operation`

#### POST

**摘要**: System restart

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| operation | path | unknown | 是 | request |

**响应**:

- `200`: OK

---
