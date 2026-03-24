# LOG 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:56

## API端点总览

- 端点数量: **18**
- 方法总数: **18**

| 方法 | 数量 |
|------|------|
| GET | 3 |
| POST | 15 |

## API端点详情

### `/containers/clean/log`

#### POST

**摘要**: Clean container log

**标签**: Container

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

### `/containers/logoption/update`

#### POST

**摘要**: Update docker daemon.json log option

**标签**: Container Docker

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/search/log`

#### GET

**摘要**: Container logs

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| container | query | unknown | 否 | 容器名称 |
| since | query | unknown | 否 | 时间筛选 |
| follow | query | unknown | 否 | 是否追踪 |
| tail | query | unknown | 否 | 显示行号 |
| timestamp | query | unknown | 否 | 是否显示时间 |

**响应**:

- `200`: OK

---

### `/core/auth/login`

#### POST

**摘要**: User login

**标签**: Auth

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| EntranceCode | header | unknown | 是 | 安全入口 base64 加密串 |
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/auth/logout`

#### POST

**摘要**: User logout

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/logs/clean`

#### POST

**摘要**: Clean operation logs

**标签**: Logs

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/logs/login`

#### POST

**摘要**: Page login logs

**标签**: Logs

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/logs/operation`

#### POST

**摘要**: Page operation logs

**标签**: Logs

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/cronjobs/records/log`

#### POST

**摘要**: Load Cronjob record log

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/convert/log`

#### POST

**摘要**: Convert file

**标签**: File

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/log`

#### POST

**摘要**: Load host SSH logs

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/log/export`

#### POST

**摘要**: Export host SSH logs

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/logs/system/files`

#### GET

**摘要**: Load system log files

**标签**: Logs

**响应**:

- `200`: OK

---

### `/logs/tasks/executing/count`

#### GET

**摘要**: Get the number of executing tasks

**标签**: TaskLog

**响应**:

- `200`: OK

---

### `/logs/tasks/search`

#### POST

**摘要**: Page task logs

**标签**: TaskLog

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp/log/search`

#### POST

**摘要**: Load FTP operation log

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/log`

#### POST

**摘要**: Operate website log

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
