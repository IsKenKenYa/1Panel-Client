# VM 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-20 08:33:57

## API端点总览

- 端点数量: **41**
- 方法总数: **41**

| 方法 | 数量 |
|------|------|
| GET | 4 |
| POST | 37 |

## API端点详情

### `/vms`

#### POST

**摘要**: Create virtual machine

**描述**: Creates a VM from ISO images or a template. The target node allows 1 VM in Community, 5 in Professional, and unlimited VMs in Enterprise. All VM records count toward the quota, regardless of state; creation fails with ErrVMCountLimit when the quota is reached.
Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/console`

#### POST

**摘要**: Load virtual machine console information

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/console/ws`

#### GET

**摘要**: Connect virtual machine VNC console over WebSocket

**描述**: Upgrades the connection to WebSocket and forwards VNC traffic.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| name | query | unknown | 是 | virtual machine name |

**响应**:

- `101`: Switching Protocols

---

### `/vms/del`

#### POST

**摘要**: Delete virtual machine

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/disks/resize`

#### POST

**摘要**: Expand virtual machine disk

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/environment`

#### GET

**摘要**: Check virtual machine environment

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/environment/enable`

#### POST

**摘要**: Enable virtual machine environment

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/health/check`

#### POST

**摘要**: Check virtual machine health

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/info`

#### POST

**摘要**: Load virtual machine details

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/iso`

#### POST

**摘要**: Create virtual machine ISO image record

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/iso/del`

#### POST

**摘要**: Delete virtual machine ISO image

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/iso/import/start`

#### POST

**摘要**: Start virtual machine ISO image import

**描述**: Creates an import record and returns its id.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/iso/import/update`

#### POST

**摘要**: Update virtual machine ISO image import status

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/iso/list`

#### POST

**摘要**: List virtual machine ISO images

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/iso/search`

#### POST

**摘要**: Page virtual machine ISO images

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/iso/update`

#### POST

**摘要**: Update virtual machine ISO image record

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/networks`

#### POST

**摘要**: Create virtual machine network

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/networks/bridges`

#### GET

**摘要**: List host network bridges for virtual machines

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/networks/del`

#### POST

**摘要**: Delete virtual machine network

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/networks/interfaces`

#### GET

**摘要**: List host network interfaces for virtual machines

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/networks/list`

#### POST

**摘要**: List virtual machine networks

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/networks/update`

#### POST

**摘要**: Update virtual machine network

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/operate`

#### POST

**摘要**: Operate virtual machine

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/orphans/clean`

#### POST

**摘要**: Clean orphaned virtual machine data

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/orphans/scan`

#### POST

**摘要**: Scan orphaned virtual machine data

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/rename`

#### POST

**摘要**: Rename virtual machine

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/search`

#### POST

**摘要**: Page virtual machines

**描述**: Returns the VM list and the target node quota: 1 for Community, 5 for Professional, and 0 for unlimited Enterprise.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/snapshots`

#### POST

**摘要**: Create virtual machine snapshot

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/snapshots/del`

#### POST

**摘要**: Delete virtual machine snapshot

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/snapshots/list`

#### POST

**摘要**: List virtual machine snapshots

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/snapshots/recover`

#### POST

**摘要**: Recover virtual machine snapshot

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/stats`

#### POST

**摘要**: Load virtual machine statistics

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/storages`

#### POST

**摘要**: Create virtual machine storage pool

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/storages/del`

#### POST

**摘要**: Delete virtual machine storage pool

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/storages/list`

#### POST

**摘要**: List virtual machine storage pools

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/storages/update`

#### POST

**摘要**: Update virtual machine storage pool

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/sync`

#### POST

**摘要**: Sync virtual machines

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/templates`

#### POST

**摘要**: Create virtual machine template

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/templates/del`

#### POST

**摘要**: Delete virtual machine template

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/vms/templates/list`

#### POST

**摘要**: List virtual machine templates

**标签**: VirtualMachine

**响应**:

- `200`: OK

---

### `/vms/update`

#### POST

**摘要**: Update virtual machine

**描述**: Returns taskID for tracking the asynchronous operation.

**标签**: VirtualMachine

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
