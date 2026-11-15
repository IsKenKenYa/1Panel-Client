# PROCESS 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:22

## API端点总览

- 端点数量: **12**
- 方法总数: **13**

| 方法 | 数量 |
|------|------|
| GET | 6 |
| POST | 7 |

## API端点详情

### `/files/wget/process`

#### GET

**摘要**: Wget process

**标签**: File

**响应**:

- `200`: OK

---

### `/files/wget/process/keys`

#### GET

**摘要**: Process keys

**标签**: File

**响应**:

- `200`: OK

---

### `/hosts/tool/supervisor/process`

#### GET

**摘要**: Get Supervisor process config

**标签**: Host tool

**响应**:

- `200`: OK

---

#### POST

**摘要**: Create Supervisor process

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/supervisor/process/file`

#### POST

**摘要**: Operate Supervisor process config file

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/supervisor/process/file/get`

#### POST

**摘要**: Get Supervisor process config file

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/process/listening`

#### POST

**摘要**: Get Listening Process

**标签**: Process

**响应**:

- `200`: OK

---

### `/process/stop`

#### POST

**摘要**: Stop Process

**标签**: Process

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/process/ws`

#### GET

**摘要**: Process ws

**标签**: Process

**响应**:

- `200`: OK

---

### `/process/{pid}`

#### GET

**摘要**: Get Process Info By PID

**标签**: Process

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| pid | path | unknown | 是 | PID |

**响应**:

- `200`: OK

---

### `/runtimes/supervisor/process`

#### POST

**摘要**: Operate supervisor process

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/supervisor/process/:id`

#### GET

**摘要**: Get supervisor process

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/supervisor/process/file`

#### POST

**摘要**: Operate supervisor process file

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
