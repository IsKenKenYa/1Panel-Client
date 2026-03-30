# COMMAND 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:54

## API端点总览

- 端点数量: **9**
- 方法总数: **9**

| 方法 | 数量 |
|------|------|
| GET | 2 |
| POST | 7 |

## API端点详情

### `/containers/command`

#### POST

**摘要**: Create container by command

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/commands`

#### POST

**摘要**: Create command

**标签**: Command

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/commands/command`

#### GET

**摘要**: List commands

**标签**: Command

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/commands/del`

#### POST

**摘要**: Delete command

**标签**: Command

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/commands/export`

#### POST

**摘要**: Export command

**标签**: Command

**响应**:

- `200`: OK

---

### `/core/commands/import`

#### POST

**摘要**: Import command

**标签**: Command

**响应**:

- `200`: OK

---

### `/core/commands/search`

#### POST

**摘要**: Page commands

**标签**: Command

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/commands/tree`

#### POST

**摘要**: Tree commands

**标签**: Command

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/commands/update`

#### POST

**摘要**: Update command

**标签**: Command

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
