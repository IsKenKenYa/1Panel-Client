# CONTAINER 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-04-27 15:19:33

## API端点总览

- 端点数量: **69**
- 方法总数: **73**

| 方法 | 数量 |
|------|------|
| GET | 15 |
| POST | 58 |

## API端点详情

### `/containers`

#### POST

**摘要**: Create container

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

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

### `/containers/commit`

#### POST

**摘要**: Commit Container

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose`

#### POST

**摘要**: Create compose

**标签**: Container Compose

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

### `/containers/compose/env`

#### POST

**摘要**: Load compose environment variables

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/operate`

#### POST

**摘要**: Operate compose

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/search`

#### POST

**摘要**: Page composes

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/test`

#### POST

**摘要**: Test compose

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/compose/update`

#### POST

**摘要**: Update compose

**标签**: Container Compose

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/daemonjson`

#### GET

**摘要**: Load docker daemon.json

**标签**: Container Docker

**响应**:

- `200`: OK

---

### `/containers/daemonjson/file`

#### GET

**摘要**: Load docker daemon.json

**标签**: Container Docker

**响应**:

- `200`: OK

---

### `/containers/daemonjson/update`

#### POST

**摘要**: Update docker daemon.json

**标签**: Container Docker

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/daemonjson/update/byfile`

#### POST

**摘要**: Update docker daemon.json by upload file

**标签**: Container Docker

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/docker/operate`

#### POST

**摘要**: Operate docker

**标签**: Container Docker

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/docker/status`

#### GET

**摘要**: Load docker status

**标签**: Container Docker

**响应**:

- `200`: OK

---

### `/containers/files/content`

#### POST

**摘要**: Get container file content

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/del`

#### POST

**摘要**: Delete container file

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/download`

#### POST

**摘要**: Download container file

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

---

### `/containers/files/search`

#### POST

**摘要**: List container files

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/size`

#### POST

**摘要**: Get container file size

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/files/upload`

#### POST

**摘要**: Upload container file

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| containerID | formData | unknown | 是 | containerID |
| path | formData | unknown | 是 | path |
| file | formData | unknown | 是 | file |

**响应**:

- `200`: OK

---

### `/containers/image`

#### GET

**摘要**: load images options

**标签**: Container Image

**响应**:

- `200`: OK

---

### `/containers/image/all`

#### GET

**摘要**: List all images

**标签**: Container Image

**响应**:

- `200`: OK

---

### `/containers/image/build`

#### POST

**摘要**: Build image

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/image/load`

#### POST

**摘要**: Load image

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/image/pull`

#### POST

**摘要**: Pull image

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/image/push`

#### POST

**摘要**: Push image

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/image/remove`

#### POST

**摘要**: Delete image

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/image/save`

#### POST

**摘要**: Save image

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/image/search`

#### POST

**摘要**: Page images

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/image/tag`

#### POST

**摘要**: Tag image

**标签**: Container Image

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/info`

#### POST

**摘要**: Load container info

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/inspect`

#### POST

**摘要**: Container inspect

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/ipv6option/update`

#### POST

**摘要**: Update docker daemon.json ipv6 option

**标签**: Container Docker

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/item/stats`

#### POST

**摘要**: Load container stats size

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/limit`

#### GET

**摘要**: Load container limits

**响应**:

- `200`: OK

---

### `/containers/list`

#### POST

**摘要**: List containers

**标签**: Container

**响应**:

- `200`: OK

---

### `/containers/list/byimage`

#### POST

**摘要**: List containers by image

**标签**: Container

**响应**:

- `200`: OK

---

### `/containers/list/stats`

#### GET

**摘要**: Load container stats

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

### `/containers/network`

#### GET

**摘要**: List networks

**标签**: Container Network

**响应**:

- `200`: OK

---

#### POST

**摘要**: Create network

**标签**: Container Network

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/network/del`

#### POST

**摘要**: Delete network

**标签**: Container Network

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/network/search`

#### POST

**摘要**: Page networks

**标签**: Container Network

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/operate`

#### POST

**摘要**: Operate Container

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/prune`

#### POST

**摘要**: Clean container

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/rename`

#### POST

**摘要**: Rename Container

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/repo`

#### GET

**摘要**: List image repos

**标签**: Container Image-repo

**响应**:

- `200`: OK

---

#### POST

**摘要**: Create image repo

**标签**: Container Image-repo

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/repo/del`

#### POST

**摘要**: Delete image repo

**标签**: Container Image-repo

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/repo/search`

#### POST

**摘要**: Page image repos

**标签**: Container Image-repo

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/repo/status`

#### POST

**摘要**: Load repo status

**标签**: Container Image-repo

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/repo/update`

#### POST

**摘要**: Update image repo

**标签**: Container Image-repo

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/search`

#### POST

**摘要**: Page containers

**标签**: Container

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

### `/containers/stats/:id`

#### GET

**摘要**: Container stats

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | 容器id |

**响应**:

- `200`: OK

---

### `/containers/status`

#### GET

**摘要**: Load containers status

**标签**: Container

**响应**:

- `200`: OK

---

### `/containers/template`

#### GET

**摘要**: List compose templates

**标签**: Container Compose-template

**响应**:

- `200`: OK

---

#### POST

**摘要**: Create compose template

**标签**: Container Compose-template

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/template/batch`

#### POST

**摘要**: Bacth compose template

**标签**: Container Compose-template

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/template/del`

#### POST

**摘要**: Delete compose template

**标签**: Container Compose-template

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/template/search`

#### POST

**摘要**: Page compose templates

**标签**: Container Compose-template

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/template/update`

#### POST

**摘要**: Update compose template

**标签**: Container Compose-template

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/update`

#### POST

**摘要**: Update container

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/upgrade`

#### POST

**摘要**: Upgrade container

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/users`

#### POST

**摘要**: Load container users

**标签**: Container

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/volume`

#### GET

**摘要**: List volumes

**标签**: Container Volume

**响应**:

- `200`: OK

---

#### POST

**摘要**: Create volume

**标签**: Container Volume

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/volume/del`

#### POST

**摘要**: Delete volume

**标签**: Container Volume

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/containers/volume/search`

#### POST

**摘要**: Page volumes

**标签**: Container Volume

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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
