# SETTING 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:22

## API端点总览

- 端点数量: **52**
- 方法总数: **55**

| 方法 | 数量 |
|------|------|
| GET | 15 |
| POST | 40 |

## API端点详情

### `/xpack/model/downloader/settings`

#### GET

**摘要**: Get model downloader settings

**标签**: AI

**响应**:

- `200`: OK

---

#### POST

**摘要**: Update model downloader settings

**描述**: Updates the download directory, source endpoints and tokens. The featuredModelsSync field is ignored; use /xpack/model/downloader/featured/sync/status to update automatic synchronization.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/core/settings/search/base`

#### POST

**摘要**: Load base system setting info

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

### `/core/settings/ssl/reload`

#### POST

**摘要**: Reload SSL

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

### `/settings/file-history/search`

#### POST

**摘要**: Load file history setting info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/file-history/update`

#### POST

**摘要**: Update file history setting

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/settings/files/ai/search`

#### POST

**摘要**: Get file manage AI setting info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/files/ai/update`

#### POST

**摘要**: Update file manage AI setting

**标签**: System Setting

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/settings/terminal/ai/search`

#### POST

**摘要**: Get terminal AI setting info

**标签**: System Setting

**响应**:

- `200`: OK

---

### `/settings/terminal/ai/update`

#### POST

**摘要**: Update terminal AI setting

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

### `/settings/website/dir`

#### GET

**摘要**: Load website dir

**标签**: System Setting

**响应**:

- `200`: OK

---
