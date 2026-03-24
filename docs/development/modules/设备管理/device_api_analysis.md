# DEVICE 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:55

## API端点总览

- 端点数量: **10**
- 方法总数: **10**

| 方法 | 数量 |
|------|------|
| GET | 2 |
| POST | 8 |

## API端点详情

### `/toolbox/device/base`

#### POST

**摘要**: Load device base info

**标签**: Device

**响应**:

- `200`: OK

---

### `/toolbox/device/check/dns`

#### POST

**摘要**: Check device DNS conf

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/conf`

#### POST

**摘要**: load conf

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/byconf`

#### POST

**摘要**: Update device conf by file

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/conf`

#### POST

**摘要**: Update device

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/host`

#### POST

**摘要**: Update device hosts

**标签**: Device

**响应**:

- `200`: OK

---

### `/toolbox/device/update/passwd`

#### POST

**摘要**: Update device passwd

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/swap`

#### POST

**摘要**: Update device swap

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/users`

#### GET

**摘要**: Load user list

**标签**: Device

**响应**:

- `200`: OK

---

### `/toolbox/device/zone/options`

#### GET

**摘要**: list time zone options

**标签**: Device

**响应**:

- `200`: OK

---
