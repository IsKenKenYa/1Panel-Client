# ALERT 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-20 08:33:57

## API端点总览

- 端点数量: **15**
- 方法总数: **15**

| 方法 | 数量 |
|------|------|
| GET | 2 |
| POST | 13 |

## API端点详情

### `/alert`

#### POST

**摘要**: Create alert

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/clams/list`

#### GET

**摘要**: Get clams

**标签**: Alert

**响应**:

- `200`: OK

---

### `/alert/config/del`

#### POST

**摘要**: Delete alert config

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/config/info`

#### POST

**摘要**: Get alert config

**标签**: Alert

**响应**:

- `200`: OK

---

### `/alert/config/search`

#### POST

**摘要**: Page alert config

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/config/test`

#### POST

**摘要**: Test alert config

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/config/update`

#### POST

**摘要**: Update alert config

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/cronjob/list`

#### POST

**摘要**: Get cron jobs

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/del`

#### POST

**摘要**: Delete alert

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/disks/list`

#### GET

**摘要**: Get disks

**标签**: Alert

**响应**:

- `200`: OK

---

### `/alert/logs/clean`

#### POST

**摘要**: Clean alert logs

**标签**: Alert

**响应**:

- `200`: OK

---

### `/alert/logs/search`

#### POST

**摘要**: Page alert logs

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/search`

#### POST

**摘要**: Page alert

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/status`

#### POST

**摘要**: Update alert status

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/alert/update`

#### POST

**摘要**: Update alert

**标签**: Alert

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
