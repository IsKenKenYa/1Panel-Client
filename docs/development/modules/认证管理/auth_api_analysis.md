# AUTH 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-04-27 15:19:33

## API端点总览

- 端点数量: **11**
- 方法总数: **11**

| 方法 | 数量 |
|------|------|
| GET | 2 |
| POST | 9 |

## API端点详情

### `/core/auth/captcha`

#### GET

**摘要**: Load captcha

**标签**: Auth

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

### `/core/auth/passkey/finish`

#### POST

**摘要**: User login with passkey

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
