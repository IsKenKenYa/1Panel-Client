# XPACK 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-20 08:33:57

## API端点总览

- 端点数量: **16**
- 方法总数: **17**

| 方法 | 数量 |
|------|------|
| GET | 1 |
| POST | 16 |

## API端点详情

### `/xpack/model/downloader/featured/search`

#### POST

**摘要**: Page featured models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/featured/sync`

#### POST

**摘要**: Synchronize featured models

**描述**: Synchronizes the featured model catalog immediately, independently of the automatic synchronization setting. Does nothing in offline mode.

**标签**: AI

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/featured/sync/status`

#### POST

**摘要**: Update featured model automatic synchronization

**描述**: Set value to Enable or Disable. This updates the automatic synchronization setting without triggering an immediate synchronization.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/hf/download`

#### POST

**摘要**: Download Hugging Face model

**描述**: Creates an asynchronous download task. Query /xpack/model/downloader/tasks/search for progress.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/hf/info`

#### POST

**摘要**: Get Hugging Face model details

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/hf/search`

#### POST

**摘要**: Search Hugging Face models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/local/delete`

#### POST

**摘要**: Delete locally downloaded model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/local/search`

#### POST

**摘要**: Page locally downloaded models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/modelscope/download`

#### POST

**摘要**: Download ModelScope model

**描述**: Creates an asynchronous download task. Query /xpack/model/downloader/tasks/search for progress.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/modelscope/info`

#### POST

**摘要**: Get ModelScope model details

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/modelscope/search`

#### POST

**摘要**: Search ModelScope models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

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

### `/xpack/model/downloader/tasks/cancel`

#### POST

**摘要**: Cancel model download task

**描述**: Only waiting or downloading tasks can be canceled. The withFile field is ignored.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/tasks/remove`

#### POST

**摘要**: Remove model download task

**描述**: Waiting or downloading tasks cannot be removed. Set withFile to true to also delete downloaded files.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/tasks/retry`

#### POST

**摘要**: Retry model download task

**描述**: Only failed or canceled tasks can be retried. Returns the task while the download runs asynchronously.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/xpack/model/downloader/tasks/search`

#### POST

**摘要**: Page model download tasks

**描述**: Set includeLocal to true to include locally downloaded models.

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
