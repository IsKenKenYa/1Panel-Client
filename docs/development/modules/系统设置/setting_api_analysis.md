# SETTING 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-04-27 15:19:33

## API端点总览

- 端点数量: **53**
- 方法总数: **55**

| 方法 | 数量 |
|------|------|
| GET | 15 |
| POST | 39 |
| DELETE | 1 |

## API端点详情

### `/core/auth/setting`

#### GET

**摘要**: Get Setting For Login

**标签**: Auth

**响应**:

- `200`: OK

---

### `/core/settings/api/config/generate/key`

#### POST

**摘要**: generate api key

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/api/config/update`

#### POST

**摘要**: Update api config

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/apps/store/config`

#### GET

**摘要**: Get appstore config

**标签**: App

**响应**:

- `200`: OK

---

### `/core/settings/apps/store/update`

#### POST

**摘要**: Update appstore config

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/bind/update`

#### POST

**摘要**: Update system bind info

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/by`

#### POST

**摘要**: Load system setting by key

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/expired/handle`

#### POST

**摘要**: Reset system password expired

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/interface`

#### GET

**摘要**: Load system address

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/memo`

#### GET

**摘要**: Load dashboard memo

**标签**: System Setting

**响应**:

- `200`: OK

---

#### POST

**摘要**: Update dashboard memo

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/menu/default`

#### POST

**摘要**: Default menu

**标签**: Menu Setting

**响应**:

- `200`: OK

---

### `/core/settings/menu/update`

#### POST

**摘要**: Update system setting

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/mfa`

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

### `/core/settings/mfa/bind`

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

### `/core/settings/passkey/list`

#### GET

**摘要**: List passkeys

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/passkey/register/begin`

#### POST

**摘要**: Begin passkey registration

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/passkey/register/finish`

#### POST

**摘要**: Finish passkey registration

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/passkey/{id}`

#### DELETE

**摘要**: Delete passkey

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/password/update`

#### POST

**摘要**: Update system password

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/port/update`

#### POST

**摘要**: Update system port

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/proxy/update`

#### POST

**摘要**: Update proxy setting

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/search`

#### POST

**摘要**: Load system setting info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/search/available`

#### GET

**摘要**: Load system available status

**标签**: System Setting

**响应**:

- `200`: OK

---

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

### `/core/settings/terminal/search`

#### POST

**摘要**: Load system terminal setting info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/core/settings/terminal/update`

#### POST

**摘要**: Update system terminal setting

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/update`

#### POST

**摘要**: Update system setting

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/upgrade`

#### GET

**摘要**: Load upgrade info

**标签**: System Setting

**响应**:

- `200`: OK

---

#### POST

**摘要**: Upgrade

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/upgrade/notes`

#### POST

**摘要**: Load release notes by version

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/settings/upgrade/releases`

#### GET

**摘要**: Load upgrade notes

**标签**: System Setting

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

### `/settings/basedir`

#### GET

**摘要**: Load local backup dir

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/description/save`

#### POST

**摘要**: Save common description

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/get/{key}`

#### GET

**摘要**: Load system setting by key

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| key | path | unknown | 是 | key |

**响应**:

- `200`: OK

---

### `/settings/search`

#### POST

**摘要**: Load system setting info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/search/available`

#### GET

**摘要**: Load system available status

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/snapshot`

#### POST

**摘要**: Create system snapshot

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/snapshot/del`

#### POST

**摘要**: Delete system backup

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/snapshot/description/update`

#### POST

**摘要**: Update snapshot description

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/snapshot/import`

#### POST

**摘要**: Import system snapshot

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/snapshot/load`

#### GET

**摘要**: Load system snapshot data

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/snapshot/recover`

#### POST

**摘要**: Recover system backup

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/snapshot/recreate`

#### POST

**摘要**: Recreate system snapshot

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/snapshot/rollback`

#### POST

**摘要**: Rollback system backup

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/snapshot/search`

#### POST

**摘要**: Page system snapshot

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/settings/ssh/conn/default`

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

### `/settings/update`

#### POST

**摘要**: Update system setting

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
