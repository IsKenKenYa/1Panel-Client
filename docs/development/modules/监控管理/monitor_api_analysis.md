# MONITOR 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-02-15 15:17:30

## API端点总览

- 端点数量: **5**
- 方法总数: **5**

| 方法 | 数量 |
|------|------|
| GET | 1 |
| POST | 4 |

## API端点详情

### `/hosts/monitor/clean`

#### POST

**摘要**: Clean monitor data

**标签**: Monitor

**响应**:

- `200`: OK

---

### `/hosts/monitor/gpu/search`

#### POST

**摘要**: Load monitor data

**标签**: Monitor

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/monitor/search`

#### POST

**摘要**: Load monitor data

**标签**: Monitor

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/monitor/setting`

#### GET

**摘要**: Load monitor setting

**标签**: Monitor

**响应**:

- `200`: OK

---

### `/hosts/monitor/setting/update`

#### POST

**摘要**: Update monitor setting

**标签**: Monitor

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
