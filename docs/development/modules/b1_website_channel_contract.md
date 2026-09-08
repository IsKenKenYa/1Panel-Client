# B1 网站配置中心 · 宿主通道契约 v1（冻结）

> 本契约是 Dart handler 与 C# WindowsBridge 的**单一事实源**。双方实现必须逐字对齐
> method 名与参数键名。返回值统一走各 handler 既有惯例（读：原始数据；写：`{success: bool, error?: string}`）。
> 服务端端点对照上游 `frontend/src/api/modules/website.ts`。

## 读通道（NativeChannelReadHandlers + WindowsBridge.Get*Async → JsonElement?）

| method | 参数 | 服务端端点 | 返回 |
| --- | --- | --- | --- |
| getWebsiteHttpsConfig | `{id: int}` | GET /websites/{id}/https | `{enable, ssl, httpConfig, sslProtocol[], algorithm, hsts, hstsIncludeSubDomains, http3}` 原样透传 |
| getWebsiteProxies | `{id: int}` | POST /websites/proxies `{id}` | items 数组透传 |
| getWebsiteRedirects | `{websiteID: int}` | POST /websites/redirect | items 数组透传 |
| getWebsiteRewrite | `{websiteID: int, name: string}` | POST /websites/rewrite | `{content}` 透传 |
| getWebsiteCors | `{id: int}` | GET /websites/cors/{id | CORS 配置透传 |
| getWebsiteLeech | `{websiteID: int}` | POST /websites/leech | Leech 配置透传 |
| getWebsiteAuths | `{websiteID: int}` | POST /websites/auths | `{enable, items[]}` 透传 |
| getWebsitePathAuths | `{websiteID: int}` | POST /websites/auths/path | NginxPathAuthConfig[] 透传 |
| getWebsiteDomains | `{id: int}` | GET /websites/domains/{id | domains 数组透传 |
| getWebsiteLogs | `{id: int, logType: 'access.log'\|'error.log', page?, pageSize?}` | POST /websites/log/search | 分页结果透传 |

## 写通道（NativeChannelWriteHandlers + WindowsBridge.XxxAsync → `{success, error?}`）

| method | 参数（全部扁平） | 服务端端点 |
| --- | --- | --- |
| updateWebsiteHttpsConfig | `{websiteId: int, enable: bool, websiteSSLId?: int, type: 'existed'\|'manual', certificate?: string, privateKey?: string, httpConfig: 'HTTPToHTTPS'\|'HTTPAlso'\|'HTTPSOnly', sslProtocol: string[](如 ['TLSv1.3','TLSv1.2']), algorithm: string, hsts?: bool, hstsIncludeSubDomains?: bool, http3?: bool}` | POST /websites/{websiteId}/https |
| updateWebsiteProxy | `{websiteID: int, operate: 'create'\|'edit', name: string, match: string, proxyProtocol: string, proxyAddress: string, proxyHost: string, sni?: bool, proxySSLName?: bool, sslVerify?: bool, cache?: bool, serverCacheTime?: int, serverCacheUnit?: string, browserCache?: 'enable'\|'disable'\|'noModify', cacheTime?: int, cacheUnit?: string, cors?: bool, allowOrigins?: string, allowMethods?: string, allowHeaders?: string, allowCredentials?: bool, preflight?: bool}` | POST /websites/proxies/update |
| deleteWebsiteProxy | `{id: int, name: string}` | POST /websites/proxies/delete |
| updateWebsiteProxyStatus | `{id: int, name: string, status: 'enable'\|'disable'}` | POST /websites/proxies/status |
| updateWebsiteRedirect | `{websiteID: int, operate: 'create'\|'edit'\|'delete'\|'enable'\|'disable', enable: bool, name: string, keepPath?: bool, type: 'domain'\|'path'\|'404', redirect: '301'\|'302', path?: string, target?: string, domains?: string[]}` | POST /websites/redirect/update |
| updateWebsiteRewrite | `{websiteID: int, name: string, content: string}` | POST /websites/rewrite/update |
| updateWebsiteCors | `{websiteID: int, cors: bool, allowOrigins: string, allowMethods: string, allowHeaders?: string, allowCredentials?: bool, preflight?: bool}` | POST /websites/cors/update |
| updateWebsiteLeech | `{websiteID: int, enable: bool, extends: string, serverNames: string[], noneRef?: bool, blocked?: bool, return_: string('400'\|'403'\|'404'), cache?: bool, cacheTime?: int, cacheUint?: string, logEnable?: bool}`（注意：`return` 是 Dart 保留字，参数键名用 `return_`，发请求时映射回 `return`） | POST /websites/leech/update |
| updateWebsiteAuth | `{websiteID: int, operate: 'create'\|'edit'\|'delete'\|'enable'\|'disable', scope: 'root', username?: string, password?: string, remark?: string}` | POST /websites/auths/update |
| updateWebsitePathAuth | `{websiteID: int, operate: 'create'\|'edit'\|'delete', path?: string, username?: string, password?: string, name?: string}` | POST /websites/auths/path/update |
| addWebsiteDomains | `{websiteID: int, domains: [{domain: string, port: int, ssl: bool}]}` | POST /websites/domains |
| deleteWebsiteDomain | `{id: int}` | POST /websites/domains/del/ |

## 实现约定

1. Dart 侧：读 handler 返回**原始解析数据**（列表/映射透传，不做字段裁剪）；写 handler 返回 `{success: true}` 或 `{success: false, error: <原文>}`；全部注册进 `NativeChannelManager` dispatch。
2. C# 侧：每个读 method 一个 `GetXxxAsync()` → `JsonElement?`；每个写 method 一个 `XxxAsync(...)` → `bool`（内部 `IsSuccess`）；`RetryableMethods` 不新增（写操作不重试，读可选）。
3. 服务端 4xx/5xx 已由网络层转成 `success:false`/null，handler 不得吞成默认值。
4. `getWebsiteLogs` 复用日志分页语义；`operateWebsiteLog`（开关/清空）本期不做 UI，仅预留。
