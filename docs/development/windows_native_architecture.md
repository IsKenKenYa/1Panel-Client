# Windows 原生轨道架构设计

## 1. 首批模块范围

> 本节为首批（Servers/Files/Settings）立项时的范围记录。当前已扩展为 11 项导航全部接入真实数据与 CRUD（Dashboard/Servers/Files/Containers/Apps/Websites/Databases/Monitoring/AI/Security/Settings，见第 2、6 节），范围登记以 `docs/development/modules/阶段总计划.md` 批次台账为准。

| 模块 | 功能 | 说明 |
|------|------|------|
| Servers | 服务器列表、切换当前服务器 | 展示已注册服务器，支持一键切换当前活跃服务器 |
| Settings | 系统设置摘要、展示类设置切换 | 只读展示关键设置项，支持布尔类设置快速切换 |
| Files | 目录列表只读视图、子目录导航 | 只读浏览目录结构，支持进入子目录 |

首批模块选择原则：

- 数据结构简单，JSON 序列化/反序列化成本低
- 交互模式以列表展示和简单操作为主，不涉及复杂表单
- 可完整验证 NavigationView 导航、Frame 页面缓存、MethodChannel 桥接、四态切换等核心机制

## 2. 导航与内容容器结构

### 主容器

- 主容器使用 `NavigationView`（左侧菜单 + 右侧内容区）
- 对应当前 [MainWindow.xaml](../../windows/runner/native_host/OnePanelNativeHost/MainWindow.xaml) 中的 `RootNavigationView`

### 菜单项

NavigationView 菜单项与 1Panel 模块一一对应：

| 菜单项 | Icon | 已接入 |
|--------|------|----------|
| Dashboard | FontIcon Glyph E80F (Home) | 是（B10） |
| Servers | Globe | 是 |
| Files | Folder | 是 |
| Containers | AllApps | 是 |
| Apps | Library | 是 |
| Websites | World | 是 |
| Databases | FontIcon Glyph EDA2 (HardDrive) | 是（B11） |
| CronJobs | FontIcon Glyph E823 (Recent) | 是（B12） |
| Backups | FontIcon Glyph E777 (UpdateRestore) | 是（B13） |
| Host | FontIcon Glyph E7F8 (DeviceLaptopNoPic) | 是（B15） |
| Toolbox | FontIcon Glyph E90F (Repair) | 是（B15） |
| Monitoring | FontIcon Glyph EC4A (SpeedHigh) | 是（B10） |
| AI | PreviewLink | 是 |
| Commands | FontIcon Glyph E945 (LightningBolt) | 是（B17） |
| ScriptLibrary | FontIcon Glyph E943 (Code) | 是（B20） |
| Security | FontIcon Glyph E72E | 是 |
| Logs | FontIcon Glyph E9D9 (Diagnostic) | 是（B16） |
| OpenResty | FontIcon Glyph E968 (Network) | 是（B16） |
| Orchestration | FontIcon Glyph EF90 (Flow) | 是（B18） |
| Gateway | FontIcon Glyph EA18 (Shield) | 是（B18） |
| Settings | Setting（Footer 组） | 是 |

全部 21 项导航模块均已接入真实数据。注意：`Icon="Protect"` 等非 Symbol 枚举值会在 XAML 解析期抛 `XamlParseException`，Security 菜单项改用 `<FontIcon Glyph="&#xE72E;" />` 显式声明。

### 内容路由

> 本环境（CLI 构建 + self-contained unpackaged）下 `Frame.Navigate` 会触发 native AV（详见「环境约束与规避」），导航采用「单例页面 + Frame.Content 直赋」：

- NavigationView `SelectionChanged` 事件触发页面切换
- 页面工厂映射表（单例缓存 by tag）：

```csharp
static readonly Dictionary<string, Func<Page>> _pageFactories = new()
{
    { "Dashboard", () => new DashboardPage() },
    { "Servers", () => new ServersPage() },
    { "Databases", () => new DatabasePage() },
    { "CronJobs", () => new CronJobsPage() },
    { "Backups", () => new BackupsPage() },
    { "Host", () => new HostPage() },
    { "Toolbox", () => new ToolboxPage() },
    { "Monitoring", () => new MonitoringPage() },
    { "Files", () => new FilesPage() },
    { "Containers", () => new ContainersPage() },
    { "Apps", () => new AppsPage() },
    { "Websites", () => new WebsitesPage() },
    { "AI", () => new AIPage() },
    { "Commands", () => new CommandsPage() },
    { "ScriptLibrary", () => new ScriptLibraryPage() },
    { "Security", () => new SecurityPage() },
    { "Logs", () => new LogsPage() },
    { "OpenResty", () => new OpenRestyPage() },
    { "Orchestration", () => new OrchestrationPage() },
    { "Gateway", () => new SecurityGatewayPage() },
    { "Settings", () => new SettingsPage() },
};
```

### 页面缓存

- 首次进入时经工厂创建页面实例，存入 `_pageCache`；再次进入直接复用，避免重复创建和重复数据拉取
- 切换时执行 `ContentFrame.Content = page` 直赋
- 页面实现 `ActivatePage()` / `OnPageShown()` 契约：每次切到该页时触发数据刷新（等价于旧 `OnNavigatedTo` 语义）
- 桌面左导航场景无需 back stack，不使用 `Frame.Navigate`

## 3. C# 与 Dart 桥接边界

### 桥接方式

- 使用 MethodChannel `com.onepanel.client/method`（与 iOS/macOS 原生轨道同源命名）
- 与现有窗口管理通道 `onepanel/windows_bridge`（[windows_shell_bridge.dart](../../lib/core/channel/windows/windows_shell_bridge.dart)）并行，职责分离
- `onepanel/windows_bridge`：窗口管理、托盘、通知等系统级能力
- `com.onepanel.client/method`：业务数据获取与写入操作（handler 注册在 Dart `NativeChannelManager`）

> 历史通道名 `com.openpanel.windows/shell_bridge` 已废弃，当前代码中不得再出现。

### 命令集

命令集与 Dart 侧 `NativeChannelManager` handler 一一对齐，读命令 + 写命令两类：

| 命令 | 方向 | 类型 | 说明 |
|------|------|------|------|
| getServers | C# -> Dart | 读 | 获取服务器列表 |
| getFiles | C# -> Dart | 读 | 获取指定路径下的文件列表（`path` 参数） |
| getSettings | C# -> Dart | 读 | 获取系统设置 |
| getContainers | C# -> Dart | 读 | 获取容器列表 |
| getApps | C# -> Dart | 读 | 获取应用列表 |
| getWebsites | C# -> Dart | 读 | 获取网站列表 |
| getFirewallRules | C# -> Dart | 读 | 获取防火墙规则 |
| getAIModels | C# -> Dart | 读 | 获取 AI 模型列表 |
| getDashboard | C# -> Dart | 读 | 获取仪表盘数据 |
| getMonitoring | C# -> Dart | 读 | 获取监控数据 |
| getBackups | C# -> Dart | 读 | 获取备份记录列表（返回含 detailName/fileName/fileDir/downloadAccountID 恢复所需字段） |
| getSshInfo | C# -> Dart | 读 | 获取 SSH 状态（返回键值：isActive/autoStart/port/listenAddress/passwordAuthentication/pubkeyAuthentication/permitRootLogin/useDNS 等） |
| getSshConfig | C# -> Dart | 读 | 获取 SSH 配置（返回原始配置文本） |
| getDeviceSnapshot | C# -> Dart | 读 | 获取设备快照（返回键值：hostname/systemName/systemVersion/localTime/timeZone/ntp/dns/swapMemoryTotal 等 + users 列表） |
| getOperationLogs | C# -> Dart | 读 | 获取操作日志分页列表（{page?, pageSize?}；失败返回空列表） |
| getLoginLogs | C# -> Dart | 读 | 获取登录日志分页列表（{page?, pageSize?}；失败返回空列表） |
| getSystemLogContent | C# -> Dart | 读 | 获取系统日志文件内容（{fileName 必填, useCoreLogs?}；返回 {lines, totalLines}） |
| getOpenrestySnapshot | C# -> Dart | 读 | 获取 OpenResty 快照（返回 status/modules/https/configContent） |
| getCommands | C# -> Dart | 读 | 获取命令库列表（{type?} 过滤；返回命令列表） |
| getGroups | C# -> Dart | 读 | 获取分组列表（{type}，命令库下拉传 command） |
| getOllamaContext | C# -> Dart | 读 | Ollama 安装发现流（返回 {found, appInstallId?, candidates?}，AI 域名绑定前置） |
| getComposes | C# -> Dart | 读 | 获取编排列表（分页 100 返回编排列表；失败返回空列表） |
| getPanelSslInfo | C# -> Dart | 读 | 获取面板 SSL 信息（返回键值 map，失败返回空对象） |
| getWebsiteCertificates | C# -> Dart | 读 | 获取网站证书列表（返回证书核心字段列表；失败返回空列表） |
| getScripts | C# -> Dart | 读 | 脚本库分页列表（{page?, pageSize?}；失败返回空列表） |
| connectServer | C# -> Dart | 写 | 连接指定服务器（`id` 参数） |
| addServer / deleteServer | C# -> Dart | 写 | 服务器新增 / 删除 |
| updateSetting | C# -> Dart | 写 | 更新设置项（`key` / `value` 参数） |
| toggleContainerState / deleteContainer | C# -> Dart | 写 | 容器启停 / 删除 |
| toggleWebsiteStatus / deleteWebsite | C# -> Dart | 写 | 网站启停 / 删除 |
| createWebsite | C# -> Dart | 写 | 新建网站（参数 `primaryDomain` / `alias?` / `port?` 默认 80 / `type?` 默认 deployment / `remark?`，返回 `{success: bool}`；deployment 缺省路径，preCheck+create 与 Flutter 向导同序） |
| createDatabase | C# -> Dart | 写 | 新建数据库（name 必填；type 默认 mysql；description 可选；remote 形态加 address/port/username/password；返回 {success: bool}） |
| deleteDatabase | C# -> Dart | 写 | 删除数据库（{id}，OperateByID 链路；返回 {success: bool}） |
| updateDatabaseDescription | C# -> Dart | 写 | 修改描述（{scope, lookupName?|name, engine?, source?, id?, description}，Dart 侧重建最小条目覆盖各引擎分支；返回 {success: bool}） |
| changeDatabasePassword | C# -> Dart | 写 | 修改密码（同上字段 + password 必填；返回 {success: bool}） |
| createCronJob | C# -> Dart | 写 | 新建 shell 定时任务（{name, spec(原生 cron 表达式), script?, groupID?=0}；返回 {success: bool}） |
| updateCronJob | C# -> Dart | 写 | 编辑 shell 定时任务（同上 + {id}；返回 {success: bool}） |
| handleCronJobOnce | C# -> Dart | 写 | 立即执行一次（{id}；返回 {success: bool}） |
| createFolder / deleteFile | C# -> Dart | 写 | 文件系统新建目录 / 删除 |
| addFirewallRule / deleteFirewallRule | C# -> Dart | 写 | 防火墙规则新增 / 删除 |
| createAIModel | C# -> Dart | 写 | 创建（拉取）Ollama 模型（{name 必填}，taskID 时间戳；返回 {success: bool}） |
| recreateAIModel | C# -> Dart | 写 | 重建 Ollama 模型（{name 必填}；返回 {success: bool}） |
| deleteAIModel | C# -> Dart | 写 | 删除 AI 模型 |
| deleteBackup | C# -> Dart | 写 | 删除备份记录（{id, name, type, status}；返回 {success: bool}） |
| restoreBackup | C# -> Dart | 写 | 恢复备份记录（{id, name, type 必填, detailName?, fileName 必填, fileDir?, downloadAccountID?=0}，file=fileDir/fileName 拼接；返回 {success: bool}） |
| operateSsh | C# -> Dart | 写 | SSH 服务操作（{operation ∈ start/stop/restart}；返回 {success: bool}） |
| saveSshConfig | C# -> Dart | 写 | 保存 SSH 配置（{value 非空}；返回 {success: bool}） |
| verifyToolboxDns | C# -> Dart | 写 | 校验 DNS 可用性（{dns 非空}；返回 {success: bool}） |
| updateOpenrestyConfig | C# -> Dart | 写 | 保存 OpenResty 配置源（{content 非空}；返回 {success: bool}） |
| updateOpenrestyHttps | C# -> Dart | 写 | OpenResty 默认 HTTPS 跳转开关（{operate∈enable/disable, sslRejectHandshake?}；返回 {success: bool}） |
| createCommand | C# -> Dart | 写 | 新建命令库条目（{name, command 必填, groupID?}；返回 {success: bool}） |
| deleteCommand | C# -> Dart | 写 | 删除命令库条目（{id}；返回 {success: bool}） |
| createCompose | C# -> Dart | 写 | 新建 Compose（{name 必填, from 默认 path（此时 path 必填）, file 内容, from=template 时 template id 必填}；返回 {success: bool}） |
| updateCompose | C# -> Dart | 写 | 编辑 Compose 配置（{name/path/content 三必填}；返回 {success: bool}） |
| composeOperate | C# -> Dart | 写 | 编排操作（{id, name 必填, action ∈ up/down/start/stop/restart/delete}，重建最小 ContainerCompose；返回 {success: bool}） |
| deleteScripts | C# -> Dart | 写 | 批量删除脚本（{ids: [int]}，空数组失败结构；返回 {success: bool}） |
| uploadCertificate | C# -> Dart | 写 | 上传证书（粘贴形态：{certificate, privateKey 必填, description?}；返回 {success: bool}） |
| applyCertificate | C# -> Dart | 写 | 应用（申请/续签）证书（{id 必填}；返回 {success: bool}） |

> 备注：AI 域名绑定（bindDomain）发现流已实现（getOllamaContext），绑定写操作已接入。
> 备注：Terminal 走 websocket 双向通道，属范围外（EventChannel 明确不做），登记后续批次。

### Codec 锁定

- 编解码使用 Dart `StandardMethodCodec`，C# 端实现同构 codec
- 以 Dart golden 向量双向锁定：`test/core/channel/winui_codec_golden_test.dart`（Dart 侧）与 `OnePanelNativeHost.Tests`（C# 侧）共享同一组向量，任一侧编解码偏差即测试失败

### 数据格式

- 所有数据通过 JSON 序列化/反序列化传递
- C# 端使用 `System.Text.Json`，Dart 端使用 `dart:convert`
- 数据模型示例：

```json
{
  "id": "srv-001",
  "name": "Production",
  "host": "192.168.1.100",
  "port": 8888,
  "isActive": true
}
```

### 不可跨层规则

- C# 端禁止直连 HTTP API，必须通过 Dart Provider/Service 获取数据
- C# 端仅作为 Presentation Layer，不承载任何业务逻辑
- 数据流向严格遵循：`C# UI -> MethodChannel -> Dart Service/Repository -> Dart API/Infra`
- 违反此规则的代码不得合并

## 4. 状态同步策略

> 当前实现状态：MethodChannel 请求/响应已落地；EventChannel 推送为本节设计目标，代码中尚未实现，状态刷新当前由页面 `ActivatePage()` 驱动。

### Dart -> C#（推送）

- 使用 EventChannel 推送状态变更通知
- 推送场景：
  - 服务器列表变更（新增、删除、状态变化）
  - 当前服务器切换完成
  - 设置项变更
- C# 端监听 EventChannel 流，收到通知后调用对应 MethodChannel 拉取最新数据

### C# -> Dart（请求/响应）

- 使用 MethodChannel 进行请求/响应式通信
- 所有数据操作（查询、切换、修改）均通过 MethodChannel 同步完成
- MethodChannel 调用超时设置为 30 秒

### 生命周期

- 页面 `OnNavigatedTo` 时拉取最新数据
- 页面 `OnNavigatedFrom` 时不销毁数据，保留缓存状态
- EventChannel 推送的数据变更会触发当前可见页面刷新

### 同步流程图

```
Dart Provider/Service
       |
       | EventChannel (推送通知)
       v
  C# EventListener
       |
       | MethodChannel (拉取数据)
       v
  C# Page.ViewModel
       |
       | 数据绑定
       v
  C# Page.UI
```

## 5. 异常回退与降级策略

> 当前实现状态：失败重试（C# 侧 `InvokeWithRetryAsync`）与错误态/空态/加载态组件已落地；「连续失败提示切换 MDUI3」为本节设计目标，且渲染模式切换已收敛到 runner 侧 `render_mode_bootstrap`（见第 7 节），不再经 MethodChannel 命令。

### 桥接超时

- 超时阈值：30 秒
- 超时后显示错误态组件（ErrorStateControl）+ 重试按钮
- 重试按钮触发重新调用 MethodChannel

### 桥接连续失败

- 连续失败 3 次后弹出提示对话框
- 对话框内容：建议切换到 MDUI3 模式以获得完整功能
- 提供"切换到 MDUI3 模式"按钮，调用 `setRenderMode("mdui3")`
- 提供"继续重试"按钮，重置失败计数

### 数据为空

- 显示空态组件（EmptyStateControl）
- 空态组件包含图标、提示文字和操作按钮（如"添加服务器"）

### 无权限

- 显示无权限提示
- 提示内容说明当前用户无权访问该模块
- 提供"返回"按钮导航到有权限的页面

### 降级策略汇总

| 异常场景 | 降级行为 | 用户操作 |
|----------|----------|----------|
| 桥接超时（30s） | 显示错误态 + 重试按钮 | 点击重试 |
| 桥接失败 3 次 | 提示切换 MDUI3 模式 | 切换模式或继续重试 |
| 数据为空 | 显示空态组件 | 执行引导操作 |
| 无权限 | 显示无权限提示 | 返回其他页面 |

## 6. 页面组件体系

### ModulePageBase（基类）

所有模块页面的基类，提供四态切换能力：

```
ModulePageBase : Page
  ├── LoadingState    (加载中)
  ├── ContentState    (正常内容)
  ├── EmptyState      (数据为空)
  └── ErrorState      (加载失败)
```

基类职责：

- 管理当前页面状态（Loading/Content/Empty/Error）
- 提供状态切换方法（`ShowLoading()`、`ShowContent()`、`ShowEmpty()`、`ShowError()`）
- 统一处理桥接调用、超时、异常
- 提供 `OnDataLoaded()` 虚方法供子类实现数据渲染逻辑
- ModulePageBase Empty 态统一提供主操作位（空数据服务器仍可创建首条数据）

### 具体页面

本批次交付 19 个模块页，全部继承 `ModulePageBase` 并接入真实数据与 CRUD：

| 页面 | 基类 | 渲染内容 |
|------|------|----------|
| ServersPage | ModulePageBase | 服务器列表，当前服务器高亮，支持连接/新增/删除 |
| FilesPage | ModulePageBase | 文件/目录列表，目录导航 + 新建目录/删除 |
| ContainersPage | ModulePageBase | 容器列表 + 启停/删除 |
| AppsPage | ModulePageBase | 应用列表 |
| WebsitesPage | ModulePageBase | 网站列表 + 启停/删除 |
| DatabasePage | ModulePageBase | 数据库列表 + 新建/删除/改描述/改密码 |
| CronJobsPage | ModulePageBase | 任务列表 + 新建/编辑(shell)/启停/删除/立即执行 |
| AIPage | ModulePageBase | 模型列表 + 创建/重建/删除 + 连接信息与域名绑定 |
| SecurityPage | ModulePageBase | 防火墙规则列表 + 新增/删除 |
| SettingsPage | ModulePageBase | 设置项展示 + 布尔项切换 |
| BackupsPage | ModulePageBase | 备份记录列表 + 恢复/删除 |
| HostPage | ModulePageBase | SSH 状态/服务操作/配置查看编辑 |
| ToolboxPage | ModulePageBase | 设备快照卡 + DNS 校验 |
| LogsPage | ModulePageBase | 操作/登录/系统日志只读三页签 |
| OpenRestyPage | ModulePageBase | 状态快照 + 配置源查看保存 |
| CommandsPage | ModulePageBase | 命令库列表 + 新建/删除 + 分组下拉 |
| ScriptLibraryPage | ModulePageBase | 脚本库只读列表 + 批量删除 |
| OrchestrationPage | ModulePageBase | Compose 列表 + 六动作操作 + 新建/编辑表单（新建支持 path/内容/template 三形态） |
| SecurityGatewayPage | ModulePageBase | 面板 SSL/证书/OpenResty 状态聚合 + 证书上传；证书 Apply（续签） |

### 状态控件

| 控件 | 用途 |
|------|------|
| LoadingStateControl | 显示 ProgressRing + 加载提示文字 |
| ErrorStateControl | 显示错误图标 + 错误信息 + 重试按钮 |
| EmptyStateControl | 显示空态图标 + 提示文字 + 引导操作按钮 |

### 页面状态流转

```
页面创建 -> LoadingState
    |
    v
桥接调用成功
    |
    +-- 数据非空 -> ContentState
    |
    +-- 数据为空 -> EmptyState
    |
桥接调用失败
    |
    +-- ErrorState -> 用户点击重试 -> LoadingState
    |
    +-- 连续失败3次 -> 提示切换 MDUI3
```

## 7. 验收标准

### 构建门禁（可重复执行）

```bash
# 宿主构建（0 错误）
dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug

# 宿主 xUnit 测试（含 codec golden 双向锁定）
dotnet test windows/runner/native_host/OnePanelNativeHost.Tests/OnePanelNativeHost.Tests.csproj -c Debug

# Flutter runner 构建（产出为宿主的引擎/插件资源源）
flutter build windows --debug

# Dart 侧通道与平台测试
flutter test test/core/channel/ test/core/platform/
```

### 导航功能

- NavigationView 菜单切换经单例页面 + `Frame.Content` 直赋显示对应页面
- 21 项导航模块均显示实际内容页面
- 页面切换时实例保留（`_pageCache` 单例缓存），`ActivatePage()` 触发数据刷新

### 四态切换

- 页面初始进入时显示 LoadingState
- 数据加载成功后正确切换到 ContentState 或 EmptyState
- 桥接失败时显示 ErrorState
- 重试按钮可触发重新加载

### 桥接调用

- 桥接调用可返回数据（headless Flutter 引擎运行）
- 数据经 StandardMethodCodec 编解码，golden 向量双向测试通过
- 超时和异常处理符合降级策略

### 渲染模式（native/MDUI3 双模式，2026-09-09 B24 修复后为事实标准）

- 双模式由 runner 侧 `render_mode_bootstrap` 承载：冷启动读取 `%APPDATA%\IsKenKenYa\1Panel Client\shared_preferences.json` 的 `flutter.app_ui_render_mode`
- `native` 模式下 detached 启动 `OnePanelNativeHost.exe`（成功则 runner 退出；失败置 `ONEPANEL_FORCE_MD3=1` 静默回落）；其余走 MDUI3 Flutter 壳
- **宿主 exe 探测候选**（Dart `NativeHostLauncher` 与 C++ bootstrap 同规则，顺序即优先级）：① `<runner目录>\native\`；② `<runner目录>\`；③⑥ 仓库源码树 `dotnet build` 产物 `{Debug,Release}×{win-x64 RID 子目录, TFM 目录}`（csproj 钉 `RuntimeIdentifier=win-x64`，产物在 RID 子目录——B24 之前的候选路径缺 RID 段与分隔符，是「选原生不生效」的深层根因）
- **MDUI3 内选「原生模式」= 立即生效**（B24）：设置页经 `NativeHostLauncher().launch()` 拉起宿主并退出当前进程；exe 缺失时 SnackBar 给出 `dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug` 指引，偏好保留
- **冷启动回落可见化**（B24）：bootstrap 置 `ONEPANEL_FORCE_MD3=1` 时 `AppSettingsController.nativeHostMissing=true`，渲染模式条目显示「原生宿主未就绪…已回退 MDUI3」
- **诊断日志**：bootstrap 每次冷启动把模式判定、逐候选 exists、拉起结果与 GetLastError 追加写入 `<runner目录>\bootstrap_launch.log`（修复「静默回落零感知」）
- **开发调试注意**：`flutter run` 会话内热重启（r/R）不会重跑 main.cpp bootstrap；选「原生模式」拉起宿主后当前 Flutter 进程 `exit(0)`，flutter run 调试会话断连属预期行为。冷启动验证请直接运行 `build\windows\x64\runner\Debug\onepanel_client.exe`
- **宿主侧资产刷新链**：宿主输出的 `data\flutter_assets` 来自 `dotnet build` 的 CopyFlutterEngineBundle（源=flutter build 产物）；arb 变更后必须 `flutter build windows --debug` + `dotnet build` 两段重建，否则 getTranslations 读到旧字典（新键回落英文）
- MDUI3 基线不因原生轨道开发而降级

### 宿主 i18n（B25，运行时查表）

- 单一事实源 = `lib/l10n/app_en.arb`/`app_zh.arb`；C# `L10n` 静态类启动时（`App.OnLaunched` 引擎就绪后 5s 超时）经既有 `getTranslations` 通道拉当前语言整份字典（locale 决策在 Dart 侧：`app_locale` 偏好优先、缺省跟随系统）
- 页面文案统一 `L10n.T("arbKey", "English fallback")`：缺键/未加载回落英文原样，永不抛异常；约 543 处调用点、567 键引用
- **语言切换即时生效**：设置页语言 ComboBox 写入成功 → 重拉字典 → `MainWindow.ApplyLanguage()`（导航路由 Tag 与显示 Content 分离，标签重设 + 全部缓存页按新语言重建），不重启
- 防遗漏门禁：`python scripts/check_l10n_keys.py`（扫 .cs 中 L10n.T 与导航映射引用的键必须存在于 app_en.arb）；`bootstrap_launch.log` 与该脚本均入 B25 验收命令
- 动态/插值文案（$"...{x}..."）与逻辑双用状态串本批未迁移（约一成），登记后续参数化批次

### 端到端冒烟

- 启动 `OnePanelNativeHost.exe` → ServersPage 渲染真实服务器列表

### 架构合规

- C# 端无直接 HTTP 调用
- 所有数据通过 MethodChannel 从 Dart 端获取
- 页面组件继承体系符合 ModulePageBase 规范

## 8. headless 引擎宿主模型

### 进程与组件

- WinUI3 宿主 `OnePanelNativeHost`（WindowsAppSDK 2.4.0 stable、`WindowsAppSDKSelfContained=true`、`win-x64`、`WindowsPackageType=None` unpackaged）
- 胶水 DLL `flutter_headless_host`（[windows/runner/CMakeLists.txt](../../windows/runner/CMakeLists.txt) CMake target，链接 `flutter_wrapper_app`），以无 view 方式运行 headless Flutter 引擎
- Dart 业务核心（NativeChannelManager handler、Provider/Service/Repository）与 MDUI3 轨道完全同源复用

### 启动时序

1. C# `FlutterEngineHost` 经 `DllImport("flutter_headless_host.dll", "StartHeadlessEngine")` 定位 runner 输出目录（`flutter build windows --debug` 产物为资源源）并加载 DLL
2. DLL 侧 `FlutterDesktopEngineCreate` 创建引擎 → **先注册插件**（`RegisterPlugins`）→ `FlutterDesktopEngineRun` 启动
3. `FlutterDesktopEngineGetMessenger` 取 messenger → `FlutterDesktopMessengerAddRef` 后移交 C# `WindowsBridge.Initialize`
4. C# 侧基于该 messenger 建立 `com.onepanel.client/method` MethodChannel 收发

### 进程图（线程模型）

```
OnePanelNativeHost.exe（单进程）
├── WinUI3 UI 线程
│     ├── MainWindow（NavigationView / Frame.Content 直赋）
│     ├── WindowsBridge（持有 AddRef 后的 messenger，
│     │    MethodChannel 调用编解码均在此线程发起）
    │     └── 21 项导航模块页（ModulePageBase 四态）
└── Flutter 引擎 platform 线程（flutter_headless_host 内创建）
      ├── Dart task runner：NativeChannelManager handler 分发
      │    -> Provider/Service/Repository -> API/Infra
      ├── 消息泵：platform channel 消息循环
      └── 无 view 渲染（headless，无 FlutterWindow/surface）
```

- messenger 交接：engine messenger 由 DLL 侧 AddRef 后交 C#，保证引擎生命周期独立于 view 存在；C# 调用与 Dart handler 响应经引擎 platform 线程消息泵往返
- 插件注册先于 `Run`：path_provider / shared_preferences 等插件在引擎启动前完成注册，避免 Dart 侧首帧前访问插件通道失败

## 9. 环境约束与规避

本节记录本环境（CLI 构建 + WindowsAppSDK self-contained unpackaged）实测踩坑与已采用的规避方案。后续在此环境下开发必须遵守：

| 约束现象 | 规避方案 |
|----------|----------|
| `Frame.Navigate` 触发 native AV（access violation） | 导航采用「单例页面 + `Frame.Content` 直赋 + `ActivatePage()`/`OnPageShown()` 契约」；桌面左导航场景无 back stack，页面自身缓存（见 [MainWindow.xaml.cs](../../windows/runner/native_host/OnePanelNativeHost/MainWindow.xaml.cs)） |
| `Icon="Protect"` 等非 Symbol 枚举值抛 `XamlParseException` | 菜单图标只使用 Symbol 枚举合法值；非枚举图标改用显式 `<FontIcon Glyph="..." />` |
| XAML 资源解析失败 | App.xaml 必须挂 `XamlControlsResources`（[App.xaml](../../windows/runner/native_host/OnePanelNativeHost/App.xaml)） |
| packaged 时代遗留的 `PRIResource`/禁用属性导致 `resources.pri` 缺失崩溃 | 清理 packaged-era PRI 禁用属性，保证 resources.pri 正常生成 |
| 宿主进程身份与数据目录 | 宿主 VERSIONINFO（Company=IsKenKenYa, Product=1Panel Client）使 path_provider 与 runner 数据目录同源；Dart 侧再经 `RunnerDataPath` 显式覆盖（详见下节） |

## 10. 数据目录对齐

- **同源机制**：宿主 exe 的 VERSIONINFO（`CompanyName=IsKenKenYa`、`ProductName=1Panel Client`）使 path_provider 计算出的 AppData 目录与 Flutter runner 数据目录同源，宿主与 MDUI3 轨道共享同一份服务器配置与偏好。
- **显式覆盖**：Dart 侧 [runner_data_path.dart](../../lib/core/platform/runner_data_path.dart) 不依赖隐式同源，显式覆盖数据路径。两个消费方必须同时覆盖，缺一即分叉：
  - `PathProviderPlatform.instance`（path_provider 系插件）
  - `SharedPreferencesWindows.pathProvider`（shared_preferences 内部独立解析路径）
- 验证：`flutter test test/core/platform/runner_data_path_test.dart`。
