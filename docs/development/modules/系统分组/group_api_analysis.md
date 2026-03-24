# GROUP 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-23 18:47:55

## API端点总览

- 端点数量: **12**
- 方法总数: **12**

| 方法 | 数量 |
|------|------|
| POST | 12 |

## API端点详情

### `/core/groups`

#### POST

**摘要**: Create group

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/groups/del`

#### POST

**摘要**: Delete group

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/groups/search`

#### POST

**摘要**: List groups

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/groups/update`

#### POST

**摘要**: Update group

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/core/hosts/update/group`

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

### `/cronjobs/group/update`

#### POST

**摘要**: Update cronjob group

**标签**: Cronjob

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/user/group`

#### POST

**摘要**: system user and group

**标签**: File

**响应**:

- `200`: OK

---

### `/groups`

#### POST

**摘要**: Create group

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/groups/del`

#### POST

**摘要**: Delete group

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/groups/search`

#### POST

**摘要**: List groups

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/groups/update`

#### POST

**摘要**: Update group

**标签**: System Group

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/batch/group`

#### POST

**摘要**: Batch set website group

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
