# SSH 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:22

## API端点总览

- 端点数量: **20**
- 方法总数: **20**

| 方法 | 数量 |
|------|------|
| GET | 2 |
| POST | 18 |

## API端点详情

### `/hosts/ssh/cert`

#### POST

**摘要**: Generate host SSH secret

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/cert/delete`

#### POST

**摘要**: Delete host SSH secret

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/cert/search`

#### POST

**摘要**: Load host SSH secret

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/cert/sync`

#### POST

**摘要**: Sycn host SSH secret

**标签**: SSH

**响应**:

- `200`: OK

---

### `/hosts/ssh/cert/update`

#### POST

**摘要**: Update host SSH secret

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/file`

#### POST

**摘要**: Load host SSH conf

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/file/update`

#### POST

**摘要**: Update host SSH setting by file

**标签**: SSH

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

### `/hosts/ssh/log/clean`

#### POST

**摘要**: Clean host SSH logs

**标签**: SSH

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

### `/hosts/ssh/operate`

#### POST

**摘要**: Operate SSH

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/ssh/search`

#### POST

**摘要**: Load host SSH setting info

**标签**: SSH

**响应**:

- `200`: OK

---

### `/hosts/ssh/update`

#### POST

**摘要**: Update host SSH setting

**标签**: SSH

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/terminal/ssh`

#### GET

**摘要**: Ws host SSH

**标签**: Terminal

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | query | unknown | 否 | id |
| command | query | unknown | 否 | command |

**响应**:

- `200`: OK

---

### `/settings/ssh`

#### POST

**摘要**: Save local conn info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/ssh/check`

#### POST

**摘要**: Check local conn

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/ssh/check/info`

#### POST

**摘要**: Check local conn info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/ssh/conn`

#### GET

**摘要**: Load local conn

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/ssh/default`

#### POST

**摘要**: Update local is conn

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/operate/sshd`

#### POST

**摘要**: Operate sshd of fail2ban

**标签**: Fail2ban

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
