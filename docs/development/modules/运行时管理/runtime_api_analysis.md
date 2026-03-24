# RUNTIME 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:56

## API端点总览

- 端点数量: **31**
- 方法总数: **31**

| 方法 | 数量 |
|------|------|
| GET | 8 |
| POST | 23 |

## API端点详情

### `/runtimes`

#### POST

**摘要**: Create runtime

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/:id`

#### GET

**摘要**: Get runtime

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/del`

#### POST

**摘要**: Delete runtime

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/installed/delete/check/:id`

#### GET

**摘要**: Delete runtime

**标签**: Website

**响应**:

- `200`: OK

---

### `/runtimes/node/modules`

#### POST

**摘要**: Get Node modules

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/node/modules/operate`

#### POST

**摘要**: Operate Node modules

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/node/package`

#### POST

**摘要**: Get Node package scripts

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/operate`

#### POST

**摘要**: Operate runtime

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/:id/extensions`

#### GET

**摘要**: Get php runtime extension

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/config`

#### POST

**摘要**: Update runtime php conf

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/config/:id`

#### GET

**摘要**: Load php runtime conf

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/container/:id`

#### GET

**摘要**: Get PHP container config

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/container/update`

#### POST

**摘要**: Update PHP container config

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/extensions`

#### POST

**摘要**: Create Extensions

**标签**: PHP Extensions

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/extensions/del`

#### POST

**摘要**: Delete Extensions

**标签**: PHP Extensions

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/extensions/install`

#### POST

**摘要**: Install php extension

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/extensions/search`

#### POST

**摘要**: Page Extensions

**标签**: PHP Extensions

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/extensions/uninstall`

#### POST

**摘要**: UnInstall php extension

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/extensions/update`

#### POST

**摘要**: Update Extensions

**标签**: PHP Extensions

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/file`

#### POST

**摘要**: Get php conf file

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/fpm/config`

#### POST

**摘要**: Update fpm config

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/fpm/config/:id`

#### GET

**摘要**: Get fpm config

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/fpm/status/:id`

#### GET

**摘要**: Get PHP runtime status

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/php/update`

#### POST

**摘要**: Update php conf file

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/remark`

#### POST

**摘要**: Update runtime remark

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/runtimes/search`

#### POST

**摘要**: List runtimes

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/runtimes/sync`

#### POST

**摘要**: Sync runtime status

**标签**: Runtime

**响应**:

- `200`: OK

---

### `/runtimes/update`

#### POST

**摘要**: Update runtime

**标签**: Runtime

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
