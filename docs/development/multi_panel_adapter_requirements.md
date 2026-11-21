# KenPanel 多面板适配器架构改造需求

> 本文是提交给 Codex 讨论与评估的需求文档。撰写时基于仓库真实代码与宝塔官方 API 文档的实际内容，
> 不含推测。文中标注「待确认」的部分是尚未取得一手事实的接口，不要凭常识补全。

## 1. 项目背景与目标

KenPanel（原 1Panel Client）是 Flutter 多平台客户端，当前只支持 1Panel 面板，已完成 1Panel V2 全部
端点适配（31 个模块组，`missing_in_client` 已清零）。

目标是把客户端从「1Panel 专用」改造成「通用面板客户端」，支持多面板并存与批量接入：

1. 服务器列表、连接管理、多机切换、应用锁、设置这些基础设施对所有面板类型统一。
2. 进入某台服务器后，按面板类型分发到对应的功能界面。
3. 面板适配器采用开放式注册机制，任何第三方面板可由社区接入，包括非标准 action 接口的面板。
4. UI 与状态管理层要足够完善，支持多机同时管理的优化。

用户已明确的决策：**界面分层采用「列表统一 + 面板专属页」**，不做「全页面统一 + 能力裁剪」。

## 2. 现状基线（基于真实代码，不是推测）

### 2.1 网络层

`lib/core/network/api_client_manager.dart`（244 行）是单例，`ApiClientManager._internal()` +
`static final _instance`。结构：

- `getClient(serverId, serverUrl, apiKey, {allowInsecureTls})` 返回 `DioClient`，按 `serverId` 缓存，
  配置变化时重建（`_ClientConfigMeta` 比较 `url`/`apiKey`/`allowInsecureTls`）。
- `getCurrentClient()` 从 `ApiConfigManager.getCurrentConfig()` 取当前配置。
- **34 个 `getXxxApi()` 方法**，全部形如 `Future<AppV2Api> getAppApi() async => AppV2Api(await getCurrentClient());`，
  硬编码返回 `lib/api/v2/` 下的具体类。这些方法名是 `getAppApi`、`getAlertApi`、`getVMApi`、
   `getContainerApi`、`getFileApi`、`getWebsiteApi`、`getDatabaseApi`、`getMonitorApi`、`getSettingApi`、
  `getSslApi`、`getCronjobApi`、`getFirewallApi`、`getTerminalApi`、`getToolboxApi`、`getHealthApi` 等。

`lib/core/network/dio_client.dart` 承载 1Panel 认证：`AuthInterceptor` 计算
`hmac_sha256(apiKey, '1panel:' + unixTimestamp)`，写请求头 `1Panel-Token`（签名值）与
`1Panel-Timestamp`（时间戳）。另有 `RetryInterceptor`（SSE 端点需 `disableRetryKey`）、
`ApiResponseParser`（`withData`/`asMap`/`unwrap`/`extractListDataFromMap`）。

### 2.2 配置与凭据

`lib/core/config/api_config.dart`（287 行起）定义：

```dart
class ApiConfig {
  final String id;
  final String name;
  final String url;
  final String apiKey;
  final int tokenValidity;
  final bool allowInsecureTls;
  final bool isDefault;
  final DateTime lastUsed;
}
```

`apiKey` 不落 SharedPreferences（`_toPersistedJson` 里 `json.remove('apiKey')`），改由
`ApiKeyStore` 存平台安全存储：`SecureApiKeyStore` 包装 `PlatformSecureStorage`，键为
`api_config_api_key_<serverId>`。OHOS 有 SharedPreferences 明文兜底（HUKS 可能静默返回 null），
桌面端不兜底。桌面 debug 支持从 `.env` 的 `PANEL_API_KEY=` 读密钥。

**`ApiConfig` 没有面板类型字段。** 面板类型当前是一个全局隐含假设。

### 2.3 仓库层

`lib/data/repositories/` 下 **37 个仓库**，统一模式（以 `container_repository.dart` 为例）：

```dart
class ContainerRepository {
  ContainerRepository({ApiClientManager? clientManager, ContainerV2Api? api})
      : _clientManager = clientManager ?? ApiClientManager.instance, _api = api;

  Future<ContainerV2Api> ensureApi() async {
    try {
      _api ??= await _clientManager.getContainerApi();
      return _api!;
    } catch (e) {
      if (e is StateError && e.message == 'No API config available') {
        throw const NetworkConnectionException('未配置服务器连接');
      }
      rethrow;
    }
  }

  void resetForServerChange() => _api = null;
}
```

仓库直接把 1Panel 的具体 API 类作为字段类型，因此仓库层本身就绑定了 1Panel。这是改造的主要成本来源。

### 2.4 层架构约束（AGENTS.md 强制）

依赖方向仅允许 `Presentation -> State -> Service/Repository -> API/Infra`。UI 层禁止直接调用
`lib/api/v2/`。状态管理默认 Provider。共享业务核心必须由 Dart 实现，原生层只承载 UI 容器与平台能力。

## 3. 宝塔面板接口的一手事实

来源：`https://www.bt.cn/api-doc.pdf`（13 页，文档自称未写完）与 `https://www.bt.cn/api_demo_php.zip`
（`demo.php`）。以下内容均为原文摘录后归纳，未做推测。

### 3.1 签名算法（PDF「签名算法」节与 demo.php `GetKeyData()` 一致）

```
api_sk        = 接口密钥（面板设置页面 - API 接口中获取）
request_time  = 当前请求时间的 unix 时间戳（秒级）
request_token = md5( string(request_time) + md5(api_sk) )
```

PHP 原文：`$request_token = md5($request_time . '' . md5($this->BT_KEY))`

**注意与 1Panel 的差别**：1Panel 是 HMAC-SHA256 且签名值放请求头；宝塔是双层 MD5 且签名放表单参数。

### 3.2 请求约定（PDF「注意事项」原文四条）

1. 请统一使用 POST 方式请求 API 接口
2. 为了确保请求效率，请保存 cookie，并在每次请求时附上 cookie
3. 为了面板安全考虑，请务必添加 IP 白名单
4. 所有响应内容统一为 Json 数据格式

`demo.php` 的 `HttpPostCookie()` 证实：CURLOPT_POST=1，POSTFIELDS 直接放关联数组（即
`application/x-www-form-urlencoded`），`CURLOPT_COOKIEJAR` 与 `CURLOPT_COOKIEFILE` 指向同一个
以面板地址 md5 命名的 cookie 文件，超时 60 秒，SSL 校验关闭。

### 3.3 URI 与 action 分发

不是 REST。按 URI 前缀分四组，语义由 `action` 参数决定：

| 前缀 | 已知 action |
|---|---|
| `/system` | `GetSystemTotal`、`GetDiskInfo`、`GetNetWork` |
| `/ajax` | `GetTaskCount`、`UpdatePanel` |
| `/site` | `get_site_types`、`GetPHPVersion`、`AddSite`、`DeleteSite`、`SiteStop`、`SiteStart`、`SetEdate`、`GetRewriteList`、`GetDirUserINI`、`SetDirUserINI`、`logsOpen`、`SetPath`、`SetSiteRunPath`、`SetHasPwd`、`CloseHasPwd`、`GetLimitNet`、`SetLimitNet`、`CloseLimitNet`、`GetIndex`、`SetIndex`、`AddDomain`、`DelDomain`、`ToBackup`、`DelBackup` |
| `/data` | `getData`（配 `table=sites` / `backup` / `domain` / `logs`）、`setPs`（配 `table=sites`）、`getKey` |
| `/files` | `GetFileBody`、`SaveFileBody` |

`/data?action=getData` 是通用数据表查询入口，参数为 `p`（分页）、`limit`（必传）、`search`、
`order`、`tojs`、`table`。这是宝塔把「列表查询」统一到一个端点的做法。

### 3.4 响应结构（关键：无统一信封）

同一份官方文档里三种形态并存，都属正常响应：

- 状态型：`{"status": true, "msg": "站点已启用"}`
- 裸数组：`/site?action=get_site_types` 返回 `[{"id":0,"name":"默认分类"}]`
- 数据表型：`{"data": [...], "where": "type_id=0", "page": "<div><span class='Pcurrent'>1</span>..."}`
- **`page` 字段是 HTML 片段字符串**，不是结构化分页对象。
- 裸标量：`/ajax?action=GetTaskCount` 返回 `0`（不是 JSON 对象）。

字段命名混用驼峰与下划线（`cpuRealUsed`、`memRealUsed` 与 `type_id`、`ftp_username` 并存）。
部分字段是字符串化的数字（`"status": "1"`、`"port": 80` 与字符串混杂）。
`time` 字段是中文自然语言（`"0天23小时45分钟"`）。

### 3.5 已知未覆盖范围

PDF 只有系统状态与网站管理两章。文件管理、数据库、FTP、SSL、计划任务、防火墙、软件商店、
Docker、进程、日志等章节未写入文档。原文称「通过宝塔 API，可以完全控制宝塔 Linux 面板的所有功能，
包括第三方插件应用功能，事实上，在用户登录面板后使用的所有功能也是通过相同的接口对接的，
这意味着，如果你熟悉使用浏览器调试器，就可以轻松对照宝塔 Linux 面板的操作参数完成一个第三方的前端对接」。

即：完整接口清单只能通过浏览器调试器逐页抓取，或从面板安装目录的 Python 源码
（`/www/server/panel/` 下 `*.py` 的 `def xxx_get`/`def xxx_post`）提取。**这些都是待确认范围，
不要在架构设计里假定具体的文件、数据库、SSL 端点存在。**

## 4. 核心难点（讨论重点）

### 4.1 各面板响应形态无法统一

1Panel 有稳定信封 `{code, message, data}`；宝塔三种形态混用且含 HTML 分页。这是**传输层差异**，
不是模型层差异。适配器必须在自己的边界内完成归一化，不能让上层感知原始形态。

### 4.2 有状态会话与无状态签名的对立

1Panel 每个请求独立签名，无会话。宝塔必须持有 cookie（首次访问可能需要登录或至少建立会话）。
适配器接口必须能表达「连接生命周期」：建立、保持、失效重建。当前 `DioClient` 只有拦截器，
没有会话保持的概念。

### 4.3 仓库层绑定具体 API 类

37 个仓库把 `ContainerV2Api` 这类具体类型作为字段与 `ensureApi()` 返回类型。多面板要求仓库面向
抽象接口，而不是具体类。改造范围大，需要给出可验证的迁移路径。

### 4.4 能力不对等

1Panel 有应用商店、AI 模型下载器、虚拟机管理、运行时环境。宝塔有软件商店（但插件体系完全不同）、
FTP 管理、PHP 站点类型。两边能力集交集只在「基础监控、网站、文件、容器、数据库、计划任务、
防火墙、SSL」这些面上，且参数与状态枚举不同。

按已定决策，「列表统一 + 面板专属页」意味着不需要强行统一这些功能的 UI，但**磨平共性部分**仍要
设计：健康探测、服务器卡片指标、多机切换这些跨面板统一的部分，需要各适配器提供统一的最小数据集。

### 4.5 多机同时管理

当前 `ApiClientManager` 按 `serverId` 缓存 `DioClient`，天然支持多连接并存。但
`ApiConfigManager.getCurrentConfig()` 是全局单一「当前」配置，多数 Provider 依赖"当前服务器"。
要支持「多机同时管理」（同屏对比、跨机批量操作），需要评估现有状态层是否要改成显式传入
`serverId`，而不是隐式读全局当前值。

## 5. 需要讨论并给出明确结论的问题

1. **适配器接口的粒度**：按能力域拆分（`FileCapability`、`SiteCapability`、`ContainerCapability`、
   `MonitorCapability`、`HealthCapability`…），还是单一大接口？能力域拆分能让「某面板不支持某能力」
   在类型上显式表达，代价是实现类分散；单接口简单但要用运行时能力查询。给出取舍结论。

2. **能力声明机制**：如何表达「这台服务器支持哪些能力、哪些只读、哪些不支持」？需要一份可序列化
   的能力清单，供 UI 决定显示哪些入口。这直接关系到「面板专属页」如何分发。

3. **凭据模型**：`ApiConfig` 要加面板类型字段。但宝塔还需要额外的什么？已知签名只需 `api_sk`，
   但 cookie 会话是否需要网关密码或面板用户名？这部分**待确认**。凭据模型要能容纳未来未知面板的
   任意附加字段，同时不破坏现有 `SecureApiKeyStore` 的安全存储路径（`apiKey` 不进
   SharedPreferences）。

4. **响应归一化边界**：HTML 分页字符串如何转成统一分页对象（总数、页码）？用正则从
   `<span class='Pcount'>共1条数据</span>` 提取是否符合「禁止手写 parser 解析成熟格式」的约束？
   注意 AGENTS.md 明确禁止手写 parser 解析成熟文件格式，HTML 片段属于此列。给出合规做法。

5. **仓库层迁移路径**：37 个仓库如何在保持 1Panel 现有功能不回归的前提下改为面向抽象接口？
   是先加抽象层并行运行，还是按模块逐个切换？每种做法如何验证？

6. **多机同时管理的状态层改造**：Provider 从「隐式读当前服务器」改为「显式带 serverId」的影响范围
   与验证方式。

7. **社区接入的规范边界**：适配器注册机制如何定义，第三方适配器需要满足什么约定（最小能力集、
   错误映射、日志脱敏、凭据安全），才允许注册进产品。

8. **1Panel 的现有 31 个模块组与 425 个端点在新架构下的定位**：全部下沉为 `OnePanelAdapter` 的实现，
   还是保留部分模块（如应用商店、AI、虚拟机）为 1Panel 专属而不进适配器抽象？

## 6. 约束（不可违反）

- 六层架构：`Presentation -> State -> Service/Repository -> API/Infra`，UI 层禁止直接调用 `lib/api/v2/`。
- 共享业务核心必须由 Dart 实现，原生层只承载 UI 容器与平台能力。iOS/macOS/Windows 原生轨道
  （SwiftUI / WinUI3）同样必须走 `Presentation -> State -> Service/Repository -> API/Infra`。
- 单一代码文件行数上限 1000 LOC（非空非注释行）。
- 状态管理默认 Provider，其他模式需评审。
- 禁止 mock、假数据、只为通过测试的 workaround。
- 禁止手写 parser 解析成熟文件格式（含 HTML、PDF，需用第三方库）。
- 错误反馈分层强制：L1 瞬态用 `SnackBarUtils`，L2 首屏阻塞用 `ModuleErrorStateWidget`，L3 有缓存
  刷新失败用 `PartialErrorToastListener`。
- 日志统一 `appLogger`，禁止 `print`/`debugPrint`。
- `flutter analyze` 与 `dart run test/scripts/test_runner.dart unit` 为提交门禁；涉及 API/网络加跑
  `integration`，涉及 UI 加跑 `ui`。

## 7. 当前未验证事项（请勿假定）

- 宝塔除系统状态与网站管理外的接口清单、参数、响应结构。
- 宝塔 cookie 会话是否需要独立登录步骤，还是首次签名请求即可建立会话。
- 宝塔面板版本差异对接口的影响（PDF 示例版本为 6.8.2，当前宝塔版本号未知）。
- 宝塔 HTTPS 自签证书场景的兼容要求。
- 「第三方插件应用功能」的接口是否也走 `/site`、`/data` 这类标准前缀，还是插件各自注册独立路由。

## 8. 期望产出

1. 架构方案：适配器接口定义（含能力域划分与结论）、能力声明格式、凭据模型、响应归一化层的
   合规做法、注册机制。
2. 迁移路径：37 个仓库与 34 个 API getter 的具体改造顺序，每步的验证方式与回归风险。
3. 1Panel 现有功能的归属清单：哪些下沉为适配器实现，哪些保留为面板专属。
4. 多机同时管理的状态层改造方案。
5. 分批次实施计划，每批次的验收标准（可执行的命令与预期输出）。

方案要求一步到位，不接受「第一版先如何、观察后再如何」的分阶段表述。
