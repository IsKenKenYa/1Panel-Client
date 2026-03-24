# AI 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:54

## API端点总览

- 端点数量: **18**
- 方法总数: **18**

| 方法 | 数量 |
|------|------|
| GET | 2 |
| POST | 16 |

## API端点详情

### `/ai/domain/bind`

#### POST

**摘要**: Bind domain

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/domain/get`

#### POST

**摘要**: Get bind domain

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/gpu/load`

#### GET

**摘要**: Load gpu / xpu info

**标签**: AI

**响应**:

- `200`: OK

---

### `/ai/mcp/domain/bind`

#### POST

**摘要**: Bind Domain for mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/domain/get`

#### GET

**摘要**: Get bin Domain for mcp server

**标签**: McpServer

**响应**:

- `200`: OK

---

### `/ai/mcp/domain/update`

#### POST

**摘要**: Update bind Domain for mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/search`

#### POST

**摘要**: List mcp servers

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server`

#### POST

**摘要**: Create mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/del`

#### POST

**摘要**: Delete mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/op`

#### POST

**摘要**: Operate mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/update`

#### POST

**摘要**: Update mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/close`

#### POST

**摘要**: Close Ollama model conn

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model`

#### POST

**摘要**: Create Ollama model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/del`

#### POST

**摘要**: Delete Ollama model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/load`

#### POST

**摘要**: Page Ollama models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/recreate`

#### POST

**摘要**: Rereate Ollama model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/search`

#### POST

**摘要**: Page Ollama models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/sync`

#### POST

**摘要**: Sync Ollama model list

**标签**: AI

**响应**:

- `200`: OK

---
