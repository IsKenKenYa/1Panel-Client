# FIREWALL 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:22

## API端点总览

- 端点数量: **27**
- 方法总数: **27**

| 方法 | 数量 |
|------|------|
| GET | 4 |
| POST | 23 |

## API端点详情

### `/hosts/firewall/base`

#### POST

**摘要**: Load firewall base info

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/docker/endpoints`

#### GET

**摘要**: List Docker published ports

**标签**: Firewall

**响应**:

- `200`: OK

---

### `/hosts/firewall/docker/operate`

#### POST

**摘要**: Operate Docker port guard

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/docker/policies/batch`

#### POST

**摘要**: Batch upsert Docker port guard policies

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/docker/policies/delete/batch`

#### POST

**摘要**: Delete Docker port guard policies

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/docker/ports`

#### GET

**摘要**: List Docker port guard status and policies

**标签**: Firewall

**响应**:

- `200`: OK

---

### `/hosts/firewall/family/operate`

#### POST

**摘要**: Initialize, repair or bind one firewall address family

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/filter/operate`

#### POST

**摘要**: Apply/Unload/Init firewall filter chain

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/forward/base`

#### POST

**摘要**: Load forwarding base info

**标签**: Firewall

**响应**:

- `200`: OK

---

### `/hosts/firewall/forward/enable`

#### POST

**摘要**: Enable forwarding

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/forward/operate`

#### POST

**摘要**: Operate forwarding rules

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/forward/search`

#### POST

**摘要**: Page forwarding rules

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/operate`

#### POST

**摘要**: Operate firewall

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/rules`

#### POST

**摘要**: Queue firewall rule creation

**描述**: Creation and import return a taskID immediately; validation and execution results are written to the task log.

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK
- `400`: Bad Request
- `409`: Conflict

---

### `/hosts/firewall/rules/backups`

#### GET

**摘要**: List firewall rule backups

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| subsystem | query | unknown | 否 | Firewall subsystem |

**响应**:

- `200`: OK

---

### `/hosts/firewall/rules/delete`

#### POST

**摘要**: Queue firewall rule deletion

**描述**: Deletes non-whitelist rules by scope and instance key. Returns a taskID immediately; results are written to the task log.

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK
- `400`: Bad Request

---

### `/hosts/firewall/rules/native/detail`

#### POST

**摘要**: Load one provider-native firewall object definition

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK
- `400`: Bad Request

---

### `/hosts/firewall/rules/reorder`

#### POST

**摘要**: Reorder a firewall rule

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK
- `400`: Bad Request

---

### `/hosts/firewall/rules/reset`

#### POST

**摘要**: Reset firewall rules

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK
- `400`: Bad Request

---

### `/hosts/firewall/rules/search`

#### POST

**摘要**: List unified firewall v2 rules

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK
- `400`: Bad Request

---

### `/hosts/firewall/rules/update`

#### POST

**摘要**: Update a firewall rule

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK
- `400`: Bad Request

---

### `/hosts/firewall/settings`

#### GET

**摘要**: Load firewall settings

**标签**: Firewall

**响应**:

- `200`: OK

---

### `/hosts/firewall/settings/ipv6`

#### POST

**摘要**: Update firewall IPv6 support

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/settings/operate`

#### POST

**摘要**: Operate firewall backend

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/settings/whitelist`

#### POST

**摘要**: Create firewall port whitelist rules

**描述**: Saves whitelist configuration and applies missing allowances; existing rules are not removed.

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/settings/whitelist/delete`

#### POST

**摘要**: Delete firewall port whitelist rules

**描述**: Removes whitelist configuration; existing firewall rules are not removed.

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/settings/whitelist/update`

#### POST

**摘要**: Update firewall port whitelist rules

**描述**: Saves whitelist configuration and applies missing allowances; existing rules are not removed.

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
