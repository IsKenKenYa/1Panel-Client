# SYSTEM_SSL 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:56

## API端点总览

- 端点数量: **3**
- 方法总数: **3**

| 方法 | 数量 |
|------|------|
| GET | 1 |
| POST | 2 |

## API端点详情

### `/core/settings/ssl/download`

#### POST

**摘要**: Download system cert

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/ssl/info`

#### GET

**摘要**: Load system cert info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/ssl/update`

#### POST

**摘要**: Update system ssl

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
