# AUTH 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:21

## API端点总览

- 端点数量: **23**
- 方法总数: **23**

| 方法 | 数量 |
|------|------|
| GET | 4 |
| POST | 19 |

## API端点详情

### `/core/auth/api/generate`

#### POST

**摘要**: generate api key

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/api/update`

#### POST

**摘要**: Update api config

**标签**: Auth

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/auth/captcha`

#### GET

**摘要**: Load captcha

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/current`

#### GET

**摘要**: Load current user info

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/current/update`

#### POST

**摘要**: Update current user info

**标签**: Auth

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/auth/expired/reset`

#### POST

**摘要**: Reset system password expired

**标签**: Auth

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/core/auth/mfa`

#### POST

**摘要**: Load mfa info

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/auth/mfa/bind`

#### POST

**摘要**: Bind mfa

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/auth/mfa/close`

#### POST

**摘要**: Close mfa

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/auth/mfalogin`

#### POST

**摘要**: User login with mfa

**标签**: Auth

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/auth/passkey/begin`

#### POST

**摘要**: User login with passkey

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/passkey/del`

#### POST

**摘要**: Delete passkey

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/passkey/finish`

#### POST

**摘要**: User login with passkey

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/passkey/list`

#### GET

**摘要**: List passkeys

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/passkey/register/begin`

#### POST

**摘要**: Begin passkey registration

**标签**: Auth

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/auth/passkey/register/finish`

#### POST

**摘要**: Finish passkey registration

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/auth/setting`

#### GET

**摘要**: Get Setting For Login

**标签**: Auth

**响应**:

- `200`: OK

---

### `/websites/auths`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/auths/path`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/auths/path/update`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/auths/update`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
