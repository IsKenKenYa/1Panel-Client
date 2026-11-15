# AI 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-11-15 12:33:21

## API端点总览

- 端点数量: **102**
- 方法总数: **102**

| 方法 | 数量 |
|------|------|
| GET | 4 |
| POST | 98 |

## API端点详情

### `/ai/accounts`

#### POST

**摘要**: Create model service

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/counts`

#### POST

**摘要**: Count model services by provider

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/delete`

#### POST

**摘要**: Delete model service

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/models`

#### POST

**摘要**: List model service models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/models/create`

#### POST

**摘要**: Create model service model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/models/delete`

#### POST

**摘要**: Delete model service model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/models/discover`

#### POST

**摘要**: Discover custom provider models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/models/update`

#### POST

**摘要**: Update model service model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/providers`

#### GET

**摘要**: Get model service providers

**标签**: AI

**响应**:

- `200`: OK

---

### `/ai/accounts/search`

#### POST

**摘要**: Page model services

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/update`

#### POST

**摘要**: Update model service

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/accounts/verify`

#### POST

**摘要**: Verify model service

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents`

#### POST

**摘要**: Create Agent

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/bind`

#### POST

**摘要**: Bind Agent role channel

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/channels`

#### POST

**摘要**: Get Agent role channels from config file

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/create`

#### POST

**摘要**: Create Agent role

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/delete`

#### POST

**摘要**: Delete Agent role

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/list`

#### POST

**摘要**: Get configured Agent roles from config file

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/md/list`

#### POST

**摘要**: Get Agent role markdown files

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/md/update`

#### POST

**摘要**: Update Agent role markdown file

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/agent/unbind`

#### POST

**摘要**: Unbind Agent role channel

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/batch/install`

#### POST

**摘要**: Batch install Agent

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/batch/operate`

#### POST

**摘要**: Batch operate Agent

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/batch/skill/install`

#### POST

**摘要**: Batch install Agent Skill

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/batch/upgrade`

#### POST

**摘要**: Batch upgrade Agent

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/delete`

#### POST

**摘要**: Delete Agent channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/dingtalk/get`

#### POST

**摘要**: Get Agent DingTalk channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/dingtalk/update`

#### POST

**摘要**: Update Agent DingTalk channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/discord/get`

#### POST

**摘要**: Get Agent Discord channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/discord/update`

#### POST

**摘要**: Update Agent Discord channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/feishu/get`

#### POST

**摘要**: Get Agent Feishu channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/feishu/switch`

#### POST

**摘要**: Switch to the bundled OpenClaw Feishu plugin

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/feishu/update`

#### POST

**摘要**: Update Agent Feishu channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/pairing/approve`

#### POST

**摘要**: Approve Agent channel pairing code

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/qqbot/get`

#### POST

**摘要**: Get Agent QQ Bot channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/qqbot/update`

#### POST

**摘要**: Update Agent QQ Bot channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/telegram/get`

#### POST

**摘要**: Get Agent Telegram channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/telegram/update`

#### POST

**摘要**: Update Agent Telegram channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/wecom/get`

#### POST

**摘要**: Get Agent QQ Bot channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/wecom/update`

#### POST

**摘要**: Update Agent WeCom channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/weixin/get`

#### POST

**摘要**: Get Agent Weixin channel config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/channel/weixin/login`

#### POST

**摘要**: Login Agent Weixin channel

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/config-file/get`

#### POST

**摘要**: Get Agent config file

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/config-file/update`

#### POST

**摘要**: Update Agent config file

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/delete`

#### POST

**摘要**: Delete Agent

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/delete/check`

#### POST

**摘要**: Delete check Agent

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/hermes/chat/sessions`

#### POST

**摘要**: Get Hermes chat sessions

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/hermes/chat/sessions/delete`

#### POST

**摘要**: Delete Hermes chat session

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/hermes/chat/sessions/rename`

#### POST

**摘要**: Rename Hermes chat session

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/model/get`

#### POST

**摘要**: Get Agent model config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/model/update`

#### POST

**摘要**: Update Agent model config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/other/get`

#### POST

**摘要**: Get Agent Other config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/other/update`

#### POST

**摘要**: Update Agent Other config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/overview`

#### POST

**摘要**: Get Agent overview

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugin/check`

#### POST

**摘要**: Check Agent plugin installation status

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugin/install`

#### POST

**摘要**: Install Agent plugin

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugin/uninstall`

#### POST

**摘要**: Uninstall Agent plugin

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugin/upgrade`

#### POST

**摘要**: Upgrade Agent plugin

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugins/install`

#### POST

**摘要**: Install an OpenClaw marketplace plugin

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugins/list`

#### POST

**摘要**: List OpenClaw plugins

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugins/operate`

#### POST

**摘要**: Operate an OpenClaw plugin

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/plugins/search`

#### POST

**摘要**: Search OpenClaw plugins

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/remark`

#### POST

**摘要**: Update Agent remark

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/search`

#### POST

**摘要**: Page Agents

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/security/get`

#### POST

**摘要**: Get Agent Security config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/security/update`

#### POST

**摘要**: Update Agent Security config

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/skills/install`

#### POST

**摘要**: Install Agent skill

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/skills/list`

#### POST

**摘要**: List Agent skills

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/skills/search`

#### POST

**摘要**: Search Agent skills

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/skills/uninstall`

#### POST

**摘要**: Uninstall Agent skill

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/skills/update`

#### POST

**摘要**: Update Agent skill status

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/token/reset`

#### POST

**摘要**: Reset Agent token

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/website/bind`

#### POST

**摘要**: Bind Agent website

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/agents/website/unbind`

#### POST

**摘要**: Unbind Agent website

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/domain/bind`

#### POST

**摘要**: Bind domain

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/domain/get`

#### POST

**摘要**: Get bind domain

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/domain/update`

#### POST

**摘要**: Update bind domain

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/gpu/load`

#### GET

**摘要**: Load gpu / xpu info

**标签**: AI

**响应**:

- `200`: OK

---

### `/ai/gpu/options`

#### GET

**摘要**: Get CPU options

**标签**: AI

**响应**:

- `200`: OK

---

### `/ai/gpu/search`

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

### `/ai/mcp/domain/bind`

#### POST

**摘要**: Bind Domain for mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/domain/get`

#### GET

**摘要**: Get bin Domain for mcp server

**标签**: McpServer

**响应**:

- `200`: OK

---

### `/ai/mcp/domain/update`

#### POST

**摘要**: Update bind Domain for mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/search`

#### POST

**摘要**: List mcp servers

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server`

#### POST

**摘要**: Create mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/connection/test`

#### POST

**摘要**: Test mcp server connection

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/del`

#### POST

**摘要**: Delete mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/detail`

#### POST

**摘要**: Load mcp server detail

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/op`

#### POST

**摘要**: Operate mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/status/sync`

#### POST

**摘要**: Sync mcp server status

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/mcp/server/update`

#### POST

**摘要**: Update mcp server

**标签**: McpServer

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/close`

#### POST

**摘要**: Close Ollama model conn

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model`

#### POST

**摘要**: Create Ollama model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/del`

#### POST

**摘要**: Delete Ollama model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/load`

#### POST

**摘要**: Page Ollama models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/recreate`

#### POST

**摘要**: Rereate Ollama model

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/ai/ollama/model/search`

#### POST

**摘要**: Page Ollama models

**标签**: AI

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/files/ai-search`

#### POST

**摘要**: File search: content grep + optional AI summary

**描述**: When file-management AI is enabled, returns mode=ai with summary and hits. When disabled, returns mode=grep with hits only. Scans file contents only. Supports match options, extension/size/time filters, and scan limits.

**标签**: File

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
