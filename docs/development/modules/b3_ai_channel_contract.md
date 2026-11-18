# B3 AI 管理深度 · 宿主通道契约 v1（冻结）

> Dart handler 与 C# WindowsBridge 的单一事实源。MDUI3 底层 `lib/api/v2/ai_v2.dart`（~90 方法）现成复用。
> 返回惯例同 B1/B2（读透传、写 `{success, error?}`）。

## 读通道

| method | 参数 | 底层（ai_v2.dart） | 服务端 |
| --- | --- | --- | --- |
| getGpuLoad | `{}` | loadGpuInfo | GET /ai/gpu/load |
| getGpuOptions | `{}` | getGpuOptions | GET /ai/gpu/options |
| searchGpuHistory | `{productName: string, startTime: string, endTime: string}` | searchGpu | POST /ai/gpu/search |
| getAgentAccounts | `{page: int, pageSize: int, name?: string}` | pageAgentAccounts | POST /ai/accounts/search |
| getAgentAccountModels | `{accountId: int}` | getAgentAccountModels | POST /ai/accounts/models |
| getMcpServers | `{page: int, pageSize: int, name?: string}` | searchMcpServers | POST /ai/mcp/search |
| getMcpServerDetail | `{id: int}` | getMcpServerDetail | POST /ai/mcp/server/detail |
| pageAgentsNative | `{page: int, pageSize: int}` | pageAgents | POST /ai/agents/search |
| getAgentOverviewNative | `{agentId: int}` | getAgentOverview | POST /ai/agents/overview |
| getAIBindDomain | `{appInstallID: int}` | getBindDomain | POST /ai/domain/get |

## 写通道

| method | 参数（扁平） | 底层 | 服务端 |
| --- | --- | --- | --- |
| createAgentAccountNative | `{provider, name, apiKey, baseURL, apiType, authMode?, validateAvailability?: bool, verifyModel?, remark?}` | createAgentAccount | POST /ai/accounts |
| updateAgentAccountNative | `{id: int, provider, name, apiKey, baseURL, apiType, remark?}` | updateAgentAccount | POST /ai/accounts/update |
| deleteAgentAccountNative | `{id: int}` | deleteAgentAccount | POST /ai/accounts/delete |
| discoverAgentModels | `{provider, baseURL, apiKey, apiType}` | discoverAgentAccountModels | POST /ai/accounts/models/discover |
| createMcpServerNative | `{name, type: 'npx'\|'uvx', command, protocol, url, outputTransport, ssePath?, streamableHttpPath?, gatewayImage?, containerName, port: int, hostIP?: string}` | createMcpServer | POST /ai/mcp/server |
| deleteMcpServerNative | `{id: int}` | deleteMcpServer | POST /ai/mcp/server/del |
| operateMcpServerNative | `{id: int, operate: 'start'\|'stop'\|'restart'}` | operateMcpServer | POST /ai/mcp/server/op |
| testMcpConnection | `{id: int}` | testMcpServerConnection | POST /ai/mcp/server/connection/test |
| syncMcpStatus | `{ids: int[]}` | syncMcpServerStatus | POST /ai/mcp/server/status/sync |
| createAgentNative | `{agentType, name, remark?, appVersion, webUIPort: int}` | createAgent | POST /ai/agents（长超时） |
| deleteAgentNative | `{id: int, forceDelete?: bool}` | deleteAgent | POST /ai/agents/delete |
| loadOllamaModelNative | `{name: string}` | loadOllamaModel | POST /ai/ollama/model/load |
| closeOllamaModelNative | `{name: string}` | closeOllamaModel | POST /ai/ollama/close |
| syncOllamaModelsNative | `{}` | syncOllamaModels | POST /ai/ollama/model/sync |

## 实现约定

1. 同 B1/B2：Dart handler 透传/`{success,error?}` + 必填缺失快速失败 + dispatch 注册；C# 读 `GetXxxAsync→JsonElement?`（InvokeWithRetryAsync）、写 `XxxAsync→bool`（InvokeAsync+IsSuccess），列表参数用 `List<object>`。
2. 智能体渠道/技能/插件/Hermes 等 ~40 端点属后续深度批次，本契约不含。
3. `pageAgentsNative/getAgentOverviewNative` 命名加 Native 后缀避免与潜在既有同名冲突。
