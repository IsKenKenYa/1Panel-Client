# HOST 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:22

## API端点总览

- 端点数量: **74**
- 方法总数: **75**

| 方法 | 数量 |
|------|------|
| GET | 15 |
| POST | 60 |

## API端点详情

### `/hosts`

#### POST

**摘要**: Create host

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/components/{name}`

#### GET

**摘要**: Check if a system component exists

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| name | path | unknown | 是 | Component name to check (e.g., rsync, docker) |

**响应**:

- `200`: OK

---

### `/hosts/del`

#### POST

**摘要**: Delete host

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/diagnostics/goroutines`

#### GET

**摘要**: Load grouped goroutine snapshot

**标签**: RuntimeDiagnostics

**响应**:

- `200`: OK

---

### `/hosts/diagnostics/profiles`

#### POST

**摘要**: Capture runtime profile

**标签**: RuntimeDiagnostics

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/diagnostics/summary`

#### GET

**摘要**: Load runtime diagnostics summary

**标签**: RuntimeDiagnostics

**响应**:

- `200`: OK

---

### `/hosts/disks`

#### GET

**摘要**: Get complete disk information

**描述**: Get information about all disks including partitioned and unpartitioned disks

**标签**: Disk Management

**响应**:

- `200`: OK

---

### `/hosts/disks/mount`

#### POST

**摘要**: Mount disk

**描述**: Mount partition to specified mount point

**标签**: Disk Management

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | mount request |

**响应**:

- `200`: Disk mounted successfully

---

### `/hosts/disks/partition`

#### POST

**摘要**: Partition disk

**描述**: Create partition and format disk with specified filesystem

**标签**: Disk Management

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | partition request |

**响应**:

- `200`: Partition created successfully

---

### `/hosts/disks/unmount`

#### POST

**摘要**: Unmount disk

**描述**: Unmount partition from mount point

**标签**: Disk Management

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | unmount request |

**响应**:

- `200`: Disk unmounted successfully

---

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

### `/hosts/info`

#### POST

**摘要**: Get host by ID

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/monitor/clean`

#### POST

**摘要**: Clean monitor data

**标签**: Monitor

**响应**:

- `200`: OK

---

### `/hosts/monitor/iooptions`

#### GET

**摘要**: Get IO options

**标签**: Monitor

**响应**:

- `200`: OK

---

### `/hosts/monitor/netoptions`

#### GET

**摘要**: Get network options

**标签**: Monitor

**响应**:

- `200`: OK

---

### `/hosts/monitor/search`

#### POST

**摘要**: Load monitor data

**标签**: Monitor

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

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

### `/hosts/search`

#### POST

**摘要**: Search host

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

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

### `/hosts/terminal/container`

#### GET

**摘要**: Ws container terminal

**标签**: Terminal

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| cols | query | unknown | 否 | cols |
| rows | query | unknown | 否 | rows |

**响应**:

- `200`: OK

---

### `/hosts/terminal/local`

#### GET

**摘要**: Ws local terminal

**标签**: Terminal

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| command | query | unknown | 否 | command |

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

### `/hosts/test/byid`

#### POST

**摘要**: Test by ID

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/test/byinfo`

#### POST

**摘要**: Test by info

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/config/get`

#### POST

**摘要**: Get tool config

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/config/set`

#### POST

**摘要**: Update tool config

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/init`

#### POST

**摘要**: Create Host tool Config

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/operate`

#### POST

**摘要**: Operate tool

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/status`

#### POST

**摘要**: Get tool status

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/supervisor/process`

#### GET

**摘要**: Get Supervisor process config

**标签**: Host tool

**响应**:

- `200`: OK

---

#### POST

**摘要**: Create Supervisor process

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/supervisor/process/file`

#### POST

**摘要**: Operate Supervisor process config file

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tool/supervisor/process/file/get`

#### POST

**摘要**: Get Supervisor process config file

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/tree`

#### POST

**摘要**: Host tree

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/update`

#### POST

**摘要**: Update host

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/update/group`

#### POST

**摘要**: Update host group

**标签**: Host

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
