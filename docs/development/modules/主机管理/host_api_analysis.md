# HOST 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-04-27 15:19:33

## API端点总览

- 端点数量: **43**
- 方法总数: **44**

| 方法 | 数量 |
|------|------|
| GET | 4 |
| POST | 40 |

## API端点详情

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

### `/hosts/firewall/batch`

#### POST

**摘要**: Batch operate rule

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/filter/chain/status`

#### POST

**摘要**: load chain status with name

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

**摘要**: Apply/Unload/Init iptables filter

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/filter/rule/batch`

#### POST

**摘要**: Batch operate iptables filter rules

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/filter/rule/operate`

#### POST

**摘要**: Operate iptables filter rule

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/filter/search`

#### POST

**摘要**: search iptables filter rules

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/forward`

#### POST

**摘要**: Operate forward rule

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/ip`

#### POST

**摘要**: Operate Ip rule

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

### `/hosts/firewall/port`

#### POST

**摘要**: Create group

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/search`

#### POST

**摘要**: Page firewall rules

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/update/addr`

#### POST

**摘要**: Update Ip rule

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/update/description`

#### POST

**摘要**: Update rule description

**标签**: Firewall

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/hosts/firewall/update/port`

#### POST

**摘要**: Update port rule

**标签**: Firewall

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

### `/hosts/monitor/gpu/search`

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

### `/hosts/tool`

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

### `/hosts/tool/config`

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

**摘要**: Get Supervisor process config file

**标签**: Host tool

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
