# Developer Knowledge MCP 使用指南

Google 官方远程 MCP（`https://developerknowledge.googleapis.com/mcp`），从会话中直接检索
Flutter / Dart / Android / Firebase / Google Cloud 等官方文档。本仓库已在 `.mcp.json` 登记
`google-developer-knowledge` 服务器；认证由使用者完成（见下）。

## 登录（二选一）

### 方式一：OAuth client ID（推荐，无静态密钥）

1. Google Cloud Console → APIs & Services → OAuth consent screen：User type 选
   **External**，在 Test users 添加自己的 Google 邮箱。
2. Credentials → Create client → **Web application**，redirect URI 按所用客户端官方
   文档的精确值填写（不支持自定义）。
3. 在客户端的 MCP OAuth 设置中填入 client ID 与 secret，发起检索时按提示登录。
   配置文件无需携带任何密钥（`.mcp.json` 已是最终形态）。

### 方式二：API key（更简单，静态凭据）

1. Console → 启用 **Developer Knowledge API** → Credentials → Create credentials →
   API key（建议限制为该 API）。
2. 在客户端 MCP 配置的 headers 中加入 `"X-Goog-Api-Key": "<你的 key>"`（Cursor/Claude
   Code 等在 `.mcp.json` 的服务器条目加 `headers` 字段；VS Code 用顶层 `servers` 键）。
   **key 只放 header，禁止放 URL 参数。**

ADC 流程（`gcloud auth application-default login`）与逐客户端 JSON 示例见
`https://developers.google.com/knowledge/mcp`。

## 三个工具与使用要求

| 工具 | 用途 | 使用要求 |
| --- | --- | --- |
| `search_documents` | 搜索官方文档返回最相关片段 | 查 CLI flag、API 语法、权限等具体问题用 2–5 个精准关键词 |
| `get_documents` | 按 search 返回的资源名取整页 Markdown | 仅在片段缺少上下文时调用，先片段后整页 |
| `answer_query` | 从语料生成结构化答案 | 宽泛 how-to 与比较类问题 |

- Agent 查证 Flutter/Dart/Android 官方 API 用法时优先走本 MCP，替代网页搜索；
  具体提问要指明产品、平台与语言，避免宽泛请求浪费上下文。
- 配套技能 `retrieving-developer-knowledge`（`google/skills` 官方）已安装：包含工具
  选择规则、错误优先判断（区分配额/密钥错误与文档缺失）与 MCP 不可用时降级用
  `curl` 调 REST API 的流程。

## 已知限制

- 仅收录公开文档且**仅英文**；HarmonyOS（docs 官方中文语料）不在语料内，鸿蒙问题
  用项目内 `hmos-arkui-knowledge-retriever` 等技能或上游文档。
- 客户端需能访问 `developerknowledge.googleapis.com`；企业网络受限时按官方页配置
  Private Google Access。

## 故障排查速查

| 现象 | 处理 |
| --- | --- |
| `404` / `403` API 未启用 | `gcloud services enable developerknowledge.googleapis.com` |
| `400 API key not valid` | key 只能放 `X-Goog-Api-Key` header |
| `401` ADC 过期 | 重新 `gcloud auth application-default login` |
| `403 access_denied` | OAuth consent 的 Test users 未加当前账号 |
| `429` | 项目配额耗尽，申请提升 |

配置后验证：向 agent 发一个 Flutter API 用法问题，其调用 `search_documents` 并返回
官方文档内容即为连通。
