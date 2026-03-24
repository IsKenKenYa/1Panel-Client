# TOOLBOX 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:56

## API端点总览

- 端点数量: **39**
- 方法总数: **39**

| 方法 | 数量 |
|------|------|
| GET | 5 |
| POST | 34 |

## API端点详情

### `/toolbox/clam`

#### POST

**摘要**: Create clam

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/base`

#### POST

**摘要**: Load clam base info

**标签**: Clam

**响应**:

- `200`: OK

---

### `/toolbox/clam/del`

#### POST

**摘要**: Delete clam

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/file/search`

#### POST

**摘要**: Load clam file

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/file/update`

#### POST

**摘要**: Update clam file

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/handle`

#### POST

**摘要**: Handle clam scan

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/operate`

#### POST

**摘要**: Operate Clam

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/record/clean`

#### POST

**摘要**: Clean clam record

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/record/search`

#### POST

**摘要**: Page clam record

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/search`

#### POST

**摘要**: Page clam

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/status/update`

#### POST

**摘要**: Update clam status

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clam/update`

#### POST

**摘要**: Update clam

**标签**: Clam

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/clean`

#### POST

**摘要**: Clean system

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | array | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/base`

#### POST

**摘要**: Load device base info

**标签**: Device

**响应**:

- `200`: OK

---

### `/toolbox/device/check/dns`

#### POST

**摘要**: Check device DNS conf

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/conf`

#### POST

**摘要**: load conf

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/byconf`

#### POST

**摘要**: Update device conf by file

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/conf`

#### POST

**摘要**: Update device

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/host`

#### POST

**摘要**: Update device hosts

**标签**: Device

**响应**:

- `200`: OK

---

### `/toolbox/device/update/passwd`

#### POST

**摘要**: Update device passwd

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/update/swap`

#### POST

**摘要**: Update device swap

**标签**: Device

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/device/users`

#### GET

**摘要**: Load user list

**标签**: Device

**响应**:

- `200`: OK

---

### `/toolbox/device/zone/options`

#### GET

**摘要**: list time zone options

**标签**: Device

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/base`

#### GET

**摘要**: Load fail2ban base info

**标签**: Fail2ban

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/load/conf`

#### GET

**摘要**: Load fail2ban conf

**标签**: Fail2ban

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/operate`

#### POST

**摘要**: Operate fail2ban

**标签**: Fail2ban

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/operate/sshd`

#### POST

**摘要**: Operate sshd of fail2ban

**标签**: Fail2ban

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/search`

#### POST

**摘要**: Page fail2ban ip list

**标签**: Fail2ban

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/update`

#### POST

**摘要**: Update fail2ban conf

**标签**: Fail2ban

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/fail2ban/update/byconf`

#### POST

**摘要**: Update fail2ban conf by file

**标签**: Fail2ban

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp`

#### POST

**摘要**: Create FTP user

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp/base`

#### GET

**摘要**: Load FTP base info

**标签**: FTP

**响应**:

- `200`: OK

---

### `/toolbox/ftp/del`

#### POST

**摘要**: Delete FTP user

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp/log/search`

#### POST

**摘要**: Load FTP operation log

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp/operate`

#### POST

**摘要**: Operate FTP

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp/search`

#### POST

**摘要**: Page FTP user

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp/sync`

#### POST

**摘要**: Sync FTP user

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/ftp/update`

#### POST

**摘要**: Update FTP user

**标签**: FTP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/toolbox/scan`

#### POST

**摘要**: Scan system

**标签**: Device

**响应**:

- `200`: OK

---
