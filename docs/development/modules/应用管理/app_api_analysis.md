# APP 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-02-23 15:42:29

## API端点总览

- 端点数量: **33**
- 方法总数: **33**

| 方法 | 数量 |
|------|------|
| GET | 13 |
| POST | 20 |

## API端点详情

### `/apps/:key`

#### GET

**摘要**: Search app by key

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| key | path | unknown | 是 | app key |

**响应**:

- `200`: OK

---

### `/apps/checkupdate`

#### GET

**摘要**: Get app list update

**标签**: App

**响应**:

- `200`: OK

---

### `/apps/detail/:appId/:version/:type`

#### GET

**摘要**: Search app detail by appid

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| appId | path | unknown | 是 | app id |
| version | path | unknown | 是 | app 版本 |
| version | path | unknown | 是 | app 类型 |

**响应**:

- `200`: OK

---

### `/apps/details/:id`

#### GET

**摘要**: Get app detail by id

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| appId | path | unknown | 是 | id |

**响应**:

- `200`: OK

---

### `/apps/icon/:appId`

#### GET

**摘要**: Get app icon by app_id

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| appId | path | unknown | 是 | app id |

**响应**:

- `200`: app icon

---

### `/apps/ignored/cancel`

#### POST

**摘要**: Cancel Ignore Upgrade App

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/ignored/detail`

#### GET

**摘要**: List Upgrade Ignored App

**标签**: App

**响应**:

- `200`: OK

---

### `/apps/install`

#### POST

**摘要**: Install app

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/check`

#### POST

**摘要**: Check app installed

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/conf`

#### POST

**摘要**: Search default config by key

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/config/update`

#### POST

**摘要**: Update app config

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/conninfo`

#### POST

**摘要**: Search app password by key

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/delete/check/:appInstallId`

#### GET

**摘要**: Check before delete

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| appInstallId | path | unknown | 是 | App install id |

**响应**:

- `200`: OK

---

### `/apps/installed/ignore`

#### POST

**摘要**: Ignore Upgrade App

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/info/:appInstallId`

#### GET

**摘要**: Get app install info

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| appInstallId | path | unknown | 是 | App install id |

**响应**:

- `200`: OK

---

### `/apps/installed/list`

#### GET

**摘要**: List app installed

**标签**: App

**响应**:

- `200`: OK

---

### `/apps/installed/loadport`

#### POST

**摘要**: Search app port by key

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/op`

#### POST

**摘要**: Operate installed app

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/params/:appInstallId`

#### GET

**摘要**: Search params by appInstallId

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| appInstallId | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/params/update`

#### POST

**摘要**: Change app params

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/port/change`

#### POST

**摘要**: Change app port

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/search`

#### POST

**摘要**: Page app installed

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/installed/sync`

#### POST

**摘要**: Sync app installed

**标签**: App

**响应**:

- `200`: OK

---

### `/apps/installed/update/versions`

#### POST

**摘要**: Search app update version by install id

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| appInstallId | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/search`

#### POST

**摘要**: List apps

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/services/:key`

#### GET

**摘要**: Search app service by key

**标签**: App

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| key | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/apps/sync/local`

#### POST

**摘要**: Sync local  app list

**标签**: App

**响应**:

- `200`: OK

---

### `/apps/sync/remote`

#### POST

**摘要**: Sync remote app list

**标签**: App

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

### `/dashboard/app/launcher`

#### GET

**摘要**: Load app launcher

**标签**: Dashboard

**响应**:

- `200`: OK

---

### `/dashboard/app/launcher/option`

#### POST

**摘要**: Load app launcher options

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/dashboard/app/launcher/show`

#### POST

**摘要**: Update app Launcher

**标签**: Dashboard

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
