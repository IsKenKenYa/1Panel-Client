# Phase 1 主计划

## 文档定位

本文件是 Open1PanelApp 针对 **1Panel V2 API 模块适配** 的第一阶段总执行蓝图，目标是把当前“API 客户端已较多落地、但模块入口、分层、页面和测试闭环缺失”的状态，推进到一组可交付、可复用、可持续扩展的移动端模块基线。

本计划可直接作为：

- 第一阶段排期与执行依据
- 其他 Agent 的实现输入
- 后续评审、验收、补测、补文档的统一标准
- 第二阶段、第三阶段计划文档的模板母版

---

## 规范源与约束

### Source of Truth

- OpenAPI 规范：
  `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
- 模块工作流：
  `docs/development/modules/模块适配专属工作流.md`
- 需求跟踪矩阵：
  `docs/development/requirement_tracking_matrix.md`
- API 覆盖追踪：
  `docs/development/api_coverage.md`
- 仓库架构规范：
  `AGENTS.md`
- 上游 1Panel 前端/路由/API 模块：
  `docs/OpenSource/1Panel/frontend/src/views/`
  `docs/OpenSource/1Panel/frontend/src/routers/modules/`
  `docs/OpenSource/1Panel/frontend/src/api/modules/`

### 强制架构规则

以下规则在第一阶段全部强制执行：

- 依赖方向只允许：
  `Presentation -> State -> Service/Repository -> API/Infra`
- UI 页面不得直接调用 `lib/api/v2/`
- Provider 不得直接持有 `*V2Api`
- 业务逻辑不得写在 Widget `build()` 中
- 状态管理默认使用 `Provider`
- 页面、Provider、Service 必须遵守仓库文件大小拆分规则
- 所有用户可见文本必须国际化

### 第一阶段完成口径

任一模块要被判定为“阶段一完成”，必须同时满足：

- 有明确路由入口
- 有 `Repository + Service + Provider + Page` 闭环
- 页面和 Provider 不直接引用 `lib/api/v2/`
- 具备 `loading / empty / error / retry` 四态
- 至少一条主操作成功流测试
- 至少一条主操作失败流测试
- 已补模块文档与测试清单
- 已纳入 `flutter analyze` 与 `test_runner` 基线

---

## 阶段目标

### 核心目标

第一阶段只做 **高价值闭环**，不追求面面俱到。目标是先把当前缺失最严重、但运维价值最高的模块做成可交付 MVP。

### 阶段范围

第一阶段纳入以下工作流：

1. `group` 共享分组底座
2. `host asset + ssh + process`
3. `command`
4. `cronjob + script library`
5. `backup`
6. `logs + task log`
7. `runtime`

### 明确不纳入第一阶段

以下模块不进入第一阶段：

- `toolbox`
- `device`
- `container` 深化能力
- `database` 深化能力
- `firewall` 深化能力
- `website / ssl / openresty` 深化能力
- `ai`

### 范围收口说明

- `task_log` 不单独做顶级导航模块，直接并入 `logs/task`
- `process` 不单独做顶级导航模块，归属 `host/process`
- `device` 不单独做顶级模块，后续归属 `toolbox/device`
- `runtime` 作为独立 feature 落地，但信息架构上保留“与网站运行时相关”的语义

## 执行进度快照（2026-03-28）

### Week 6 收口状态

- `Logs + Task Log` 已完成代码评审收口。
- 主链路可用、可评审、可测试。

### Week 7 收口状态

- `Runtime` 通用链路已完成：
  - `RuntimesCenterPage`
  - `RuntimeDetailPage`
  - `RuntimeFormPage`
  - `RuntimeRepository + RuntimeService + 3 Provider`
- 入口与路由已接入：
  - `OperationsCenterPage -> AppRoutes.runtimes`
  - `AppRoutes.runtimeDetail`
  - `AppRoutes.runtimeForm`
- 范围边界已锁定：
  - 已交付：`list/detail/create/update/delete/operate/sync/remark` 通用链路
  - 延后到 Week 8：`PHP 扩展/FPM 深配置`、`Node modules/scripts`、多语言完整创建向导

### Week 7 门禁结果

- `flutter analyze`：通过
- `dart run test_runner.dart unit`：通过
- `dart run test_runner.dart ui`：通过
- Runtime 聚焦测试（API / Provider / Page / Route / no-server）：通过

### Week 8 启动门槛判断

- 结论：已达到“可继续 Week 8”的门槛。
- 本阶段未解决项属于 destructive/隔离环境与语言深能力，不阻塞 Week 8 开始。

### Week 8 收口实施进展（已完成）

- 深能力数据层已落地：
  - `RuntimeV2Api` 已补 `PHP 扩展安装/卸载`、`Node modules 查询/操作`、`Node package scripts 查询`。
  - `RuntimeRepository` 已补对应仓储方法。
  - `runtime_models.dart` 已补 Week 8 请求/响应模型（PHP extension install、Node module/package/scripts）。
- 页面与路由已落地：
  - `AppRoutes.phpExtensions/phpConfig/nodeModules/nodeScripts` 已从 placeholder 切换为真实页面与 Provider 注入。
  - `RuntimeDetailAdvancedTabWidget` 已增加 PHP/Node 深能力跳转按钮。
- Week 8 新增实现：
  - Services: `php_runtime_service.dart`、`node_runtime_service.dart`
  - Providers: `php_extensions_provider.dart`、`php_config_provider.dart`、`php_supervisor_provider.dart`、`node_modules_provider.dart`、`node_scripts_provider.dart`
  - Pages: `php_extensions_page.dart`、`php_config_page.dart`、`php_supervisor_page.dart`、`node_modules_page.dart`、`node_scripts_page.dart`
  - Router/入口：`AppRoutes.phpSupervisor` 与 Runtime 详情高级页 supervisor 跳转按钮已接通。
  - Supervisor 最小闭环：
    - API/Repository 已补 `/runtimes/supervisor/process`、`/runtimes/supervisor/process/file`。
    - Provider + Page 已支持进程状态查看、start/stop/restart/delete 操作、配置文件查看/保存、日志查看/清空。
  - Supervisor 高级编排闭环：
    - API/Repository/Service 已补 `/runtimes/supervisor/process` 的 create/update 编排请求体与调用链路。
    - `PhpSupervisorProvider/PhpSupervisorPage` 已支持进程编排新增/编辑（name/command/user/dir/numprocs/environment）并接入保存流。
    - 已补 API 对齐断言与 Provider 回归测试。
  - PHP 深能力闭环：
    - API/Repository/Service 已补齐：`/runtimes/php/file`、`/runtimes/php/update`、`/runtimes/php/fpm/config`、`/runtimes/php/container/{id}`、`/runtimes/php/container/update`。
    - `PhpConfigProvider` 已支持 FPM 参数、Container 配置、PHP/FPM 原始文件读写状态管理与保存流。
    - `PhpConfigPage` 已升级为多分区 Tab（Basic/FPM/Container/PHP File/FPM File），并拆分独立子组件。

### Week 8 当前验证结果

- `flutter analyze`：通过
- 聚焦新增测试：
  - `app_router_runtime_routes_test.dart`（含四条 Week8 路由）通过
  - 4 个新增 Provider 单测通过
  - `phase1_api_alignment_test.dart` 已补 Week8 路由与 payload 断言：
    - `POST /runtimes/node/modules`
    - `POST /runtimes/node/modules/operate`
    - `POST /runtimes/node/package`
    - `POST /runtimes/php/extensions/install`
    - `POST /runtimes/php/extensions/uninstall`
- Node scripts 执行协议已与上游对齐：
  - 由“误用 `/runtimes/node/modules/operate` 执行 script”切换为“更新 runtime 参数 `EXEC_SCRIPT/CUSTOM_SCRIPT/PACKAGE_MANAGER` 后走 runtime update 链路”。
- Node scripts 执行反馈闭环已补齐：
  - `NodeScriptsProvider/NodeScriptsPage` 已接入“执行触发 -> 状态轮询回读 -> 完成/失败展示”。
  - `NodeRuntimeService` 已在 update 后轮询 runtime 状态并返回执行反馈（成功/失败/超时、轮询次数、message）。
- 最新门禁与回归结果（2026-03-28）：
  - `flutter analyze`：通过
  - `dart run test_runner.dart unit`：通过
  - `dart run test_runner.dart ui`：通过
  - `dart run test_runner.dart integration`：执行通过（当前环境 `RUN_INTEGRATION_TESTS` 未开启，集成写操作用例按 gate 跳过）
  - 目标回归测试：
    - `test/api_client/phase1_api_alignment_test.dart`：通过（已补 supervisor operate/create + PHP file/update/fpm/container route/payload 对齐断言）
    - `test/features/runtimes/providers/php_supervisor_provider_test.dart`：通过（含 Supervisor create/update 编排保存流）
    - `test/features/runtimes/providers/php_config_provider_test.dart`：通过（已覆盖 FPM/Container/Raw File 保存流）
    - `test/config/app_router_runtime_routes_test.dart`：通过（已覆盖 `AppRoutes.phpSupervisor`）

### Week 8 收尾结论（已完成）

- Runtime 深能力 API：已完成（PHP deep + Supervisor operate/create/update 均已对齐）。
- Runtime 深能力页面：已完成（PHP 配置深能力 + Supervisor create/update 编排均已闭环）。
- Week 8 门禁状态：当前环境 `unit/ui/integration` 全部通过；integration 写操作在未开启 `RUN_INTEGRATION_TESTS` 环境下按 gate skip，转入模块二并行分支做实网补跑，不阻塞 Phase 1 收尾。
- 收尾判定：Phase 1 Week 8 已达到合并条件，可进入“模块二并行变更合并”窗口。

---

## 当前问题基线

第一阶段要优先解决的不是“端点数量”，而是以下系统性问题：

### 1. 入口缺失

大量已存在 API 客户端或规划文档的模块，在 App 内没有产品入口、路由入口或统一操作中心。

### 2. 分层违规

当前已有多个页面或 Provider 直接调用 API，例如：

- `databases_page.dart`
- `firewall_page.dart`
- `terminal_page.dart`
- `dashboard_provider.dart`
- `auth_provider.dart`
- `compose_provider.dart`

第一阶段新增模块不允许复制这种实现方式。

### 3. 文档完成度高于真实落地度

若干规划文档显示“已完成”，但实际 App 内不可达或只完成了 API 层。

### 4. 移动端信息架构未重绘

不能把 1Panel Web 端的表格 + 弹窗 + 左侧菜单结构直接搬到移动端。第一阶段必须按移动端触控、窄屏、错误恢复和大段文本查看场景重构。

---

## 信息架构与路由策略

## 统一入口

第一阶段不扩充底部主导航，不新增可钉选主模块。

统一方案：

- 在 `ServerDetailPage` 增加一个“运维中心”入口
- 新建 `OperationsCenterPage`
- 所有第一阶段模块从运维中心进入

### 新增路由建议

建议在 `AppRoutes` 中新增：

- `operations = '/operations'`
- `commands = '/commands'`
- `commandForm = '/commands/form'`
- `hostAssets = '/hosts-assets'`
- `hostAssetForm = '/hosts-assets/form'`
- `ssh = '/ssh'`
- `sshLogs = '/ssh/logs'`
- `sshSessions = '/ssh/sessions'`
- `processes = '/processes'`
- `processDetail = '/processes/detail'`
- `cronjobs = '/cronjobs'`
- `cronjobForm = '/cronjobs/form'`
- `cronjobRecords = '/cronjobs/records'`
- `scripts = '/scripts'`
- `backups = '/backups'`
- `backupAccountForm = '/backups/accounts/form'`
- `backupRecords = '/backups/records'`
- `backupRecover = '/backups/recover'`
- `logs = '/logs'`
- `systemLogViewer = '/logs/system'`
- `taskLogDetail = '/logs/task/detail'`
- `runtimes = '/runtimes'`
- `runtimeDetail = '/runtimes/detail'`
- `runtimeForm = '/runtimes/form'`
- `phpExtensions = '/runtimes/php/extensions'`
- `phpConfig = '/runtimes/php/config'`
- `phpSupervisor = '/runtimes/php/supervisor'`
- `nodeModules = '/runtimes/node/modules'`
- `nodeScripts = '/runtimes/node/scripts'`

### 运维中心分组

`OperationsCenterPage` 分三组展示：

- `Automation`
  `Cronjobs`
  `Scripts`
  `Commands`
  `Backups`
- `Runtime & Delivery`
  `Runtimes`
- `System Control`
  `Hosts`
  `SSH`
  `Processes`
  `Logs`

### 平台与布局规则

- 手机端：
  单列模块卡片 + 二级全屏页面
- 平板端：
  运维中心使用 2 列卡片网格
  `HostAssets`、`Processes`、`Runtimes` 可升级为双栏列表/详情

---

## 统一目录模板

第一阶段所有新模块默认使用下列目录模板：

```text
lib/data/repositories/<module>_repository.dart
lib/features/<module>/
  pages/
  providers/
  services/
  widgets/
```

### Provider 拆分规则

默认拆成：

- `*_provider.dart`
  列表/总览状态
- `*_detail_provider.dart`
  详情页状态
- `*_form_provider.dart`
  创建/编辑表单状态

若模块没有表单或详情，可酌情减少，但不得将列表、详情、表单、日志、批量动作全塞进一个 Provider。

### Repository 与 Service 边界

- `Repository`
  负责对接 API client、请求体组装、响应体映射、错误转换
- `Service`
  负责跨 repository 编排、动作流程、缓存复用、轮询/同步策略
- `Provider`
  只负责 UI 可观察状态与用户动作分发

---

## 统一 UI 设计规则

### 列表页

全部第一阶段列表页统一具备：

- 顶部搜索
- 常用筛选 Chips 或下拉筛选
- 下拉刷新
- 卡片式列表
- 空状态
- 错误态
- 批量模式

### 详情页

详情页统一使用：

- `Overview`
- `Config`
- `History / Logs / Advanced`

三段式结构，避免超长单页。

### 表单页

复杂表单统一使用分步或分段结构：

- 第一步：基础信息
- 第二步：功能配置
- 第三步：高级配置/校验
- 第四步：确认提交

### 文本与日志页

统一提供：

- 等宽字体
- 自动换行开关
- 复制
- 刷新
- 错误高亮
- 底部快速跳转

### 危险操作

统一使用底部确认 Sheet：

- 删除
- 停止
- 恢复
- 清理
- 批量禁用/启用

---

## 统一共享组件清单

第一阶段先补以下共享组件，后续模块全部复用：

- `operations_center_page.dart`
- `server_operation_entry_card_widget.dart`
- `async_state_page_body_widget.dart`
- `search_filter_bar_widget.dart`
- `selection_action_bar_widget.dart`
- `confirm_action_sheet_widget.dart`
- `status_chip_widget.dart`
- `key_value_section_card_widget.dart`
- `log_text_viewer_widget.dart`
- `group_selector_sheet_widget.dart`
- `paged_list_footer_widget.dart`
- `module_empty_state_widget.dart`
- `module_error_state_widget.dart`

---

## 模块工作流详解

## A. Group 共享分组底座

### 定位

不是先做“系统分组管理页”，而是先做共享分组底座，服务于：

- host asset
- command
- cronjob
- 后续 website / backup / terminal 等模块

### API层任务

- 对齐 `core/groups` 与 `groups`
- 明确 `type` 维度
- 统一默认分组处理逻辑

### Service/Repository任务

- `GroupRepository`
  - `listGroups(type)`
  - `createGroup(type, name)`
  - `updateGroup(...)`
  - `deleteGroup(...)`
- `GroupService`
  - 默认分组名称映射
  - 分组缓存
  - 常用模块分组加载复用

### Provider任务

- `GroupOptionsProvider`
  用于选择器场景
- `GroupManagementProvider`
  预留给第三阶段独立管理页

### UI任务

- `GroupSelectorSheet`
- `GroupEditSheet`

### 测试任务

- Repository 单测
- Service 缓存单测
- Sheet widget test

### 路由任务

- 第一阶段不提供独立 `group` 顶级页面

---

## B. Host Asset + SSH + Process

### 定位

该工作流分为三部分：

- 远程主机资产管理
- 系统 SSH 管理
- 系统进程管理

### 上游功能参考

- `frontend/src/views/terminal/host/`
- `frontend/src/views/host/ssh/`
- `frontend/src/views/host/process/`
- `frontend/src/api/modules/terminal.ts`
- `frontend/src/api/modules/host.ts`
- `frontend/src/api/modules/process.ts`

### 页面清单

- `HostAssetsPage`
- `HostAssetFormPage`
- `SshSettingsPage`
- `SshCertsPage`
- `SshLogsPage`
- `SshSessionsPage`
- `ProcessesPage`
- `ProcessDetailPage`

### API层任务

- 修正 `host_v2.dart` 与上游 `core/hosts/*` 路径漂移
- 修正 `process_v2.dart` 与上游 `/process/{pid}`、`/process/stop`、`/process/listening` 对齐
- 补齐 `SSH` 配置、证书、日志、session 对应 client

### Service/Repository任务

- `HostAssetRepository`
- `HostAssetService`
- `SshRepository`
- `SshService`
- `ProcessRepository`
- `ProcessService`

### Provider任务

- `HostAssetsProvider`
- `HostAssetFormProvider`
- `SshSettingsProvider`
- `SshCertsProvider`
- `SshLogsProvider`
- `SshSessionsProvider`
- `ProcessesProvider`
- `ProcessDetailProvider`

### UI规划

#### HostAssetsPage

- 顶部：搜索 + 分组筛选
- 列表卡片字段：
  `addr / user / port / auth mode / group / last test status`
- 操作：
  `edit / test / delete / move group`

#### HostAssetFormPage

- 分三段：
  `基础信息 / 认证方式 / 连接验证`
- 支持：
  `password` 与 `private key`

#### SshSettingsPage

- 分四段：
  `Service`
  `Authentication`
  `Network`
  `Raw File`
- 主操作：
  `启停 / 更新端口 / 切换认证模式 / 更新配置文件`

#### SshCertsPage

- 列表字段：
  `name / type / createdAt / synced`
- 操作：
  `create / edit / sync / delete`

#### SshLogsPage

- 顶部筛选：
  `status / ip / time range`
- 列表项：
  `ip / user / status / message / time`

#### SshSessionsPage

- 列表项：
  `session id / user / source / startedAt`
- 行为：
  第一阶段只做只读与结束会话

#### ProcessesPage

- 顶部搜索
- 排序 chips：
  `CPU / Memory / Name / PID`
- 卡片字段：
  `name / pid / user / cpu / memory / listening`
- 批量：
  暂不做

#### ProcessDetailPage

- 展示：
  `cmdline / ports / user / start time / threads / memory / cpu`
- 操作：
  `stop`

### 测试任务

- Host asset API client tests
- SSH API smoke tests
- Process API smoke tests
- Host/SSH/Process provider tests
- 页面 widget tests

### 路由任务

- `/hosts-assets`
- `/hosts-assets/form`
- `/ssh`
- `/ssh/logs`
- `/ssh/sessions`
- `/processes`
- `/processes/detail`

---

## C. Command

### 定位

命令模块定位为“快捷命令库”，不是完整终端替代。

### 上游功能参考

- `frontend/src/views/terminal/command/`
- `frontend/src/api/modules/command.ts`

### 页面清单

- `CommandsPage`
- `CommandFormPage`

### API层任务

- 对齐：
  `search / tree / create / update / delete / import / export / upload`
- 明确是否需要 `list` 与 `tree` 同时保留

### Service/Repository任务

- `CommandRepository`
- `CommandService`

### Provider任务

- `CommandsProvider`
- `CommandFormProvider`

### UI规划

#### CommandsPage

- 搜索 + 分组筛选
- 卡片项：
  `name / group / command preview`
- 操作：
  `copy / send to terminal / edit / delete`
- 批量模式：
  `delete / export`

#### CommandFormPage

- 字段：
  `name / group / command`
- 预览：
  等宽命令预览区域

### 测试任务

- Command API client test
- Provider test
- Page widget test

### 路由任务

- `/commands`
- `/commands/form`

---

## D. Cronjob + Script Library

### 定位

调度中心，含任务管理与脚本库。

### 上游功能参考

- `frontend/src/views/cronjob/cronjob/`
- `frontend/src/views/cronjob/library/`
- `frontend/src/api/modules/cronjob.ts`

### 页面清单

- `CronjobsPage`
- `CronjobFormPage`
- `CronjobRecordsPage`
- `CronjobLogPage`
- `ScriptLibraryPage`
- `ScriptFormPage`

### API层任务

- 对齐：
  `search / next / load info / create / update / delete / status / handle once / stop`
- 对齐：
  `search records / get record log / clean records`
- 补齐脚本库：
  `/core/script/*`

### Service/Repository任务

- `CronjobRepository`
- `CronjobService`
- `CronjobFormService`
- `ScriptLibraryRepository`
- `ScriptLibraryService`

### Provider任务

- `CronjobsProvider`
- `CronjobFormProvider`
- `CronjobRecordsProvider`
- `ScriptLibraryProvider`

### UI规划

#### CronjobsPage

- 搜索
- 分组筛选
- 状态筛选
- 卡片字段：
  `name / type / group / status / next run / retain copies / last record status`
- 卡片动作：
  `enable/disable / run once / edit / records / delete`
- 长按进入多选模式

#### CronjobFormPage

- Step 1：
  `任务类型 / 分组 / 名称`
- Step 2：
  `调度规则`
- Step 3：
  `执行内容`
- Step 4：
  `保留/超时/重试/告警`
- 第一阶段优先支持任务类型：
  `shell/script`
  `url`
  `backup`

#### CronjobRecordsPage

- 筛选：
  `time range / status`
- 列表字段：
  `startTime / status / message / targetPath`

#### CronjobLogPage

- 纯日志查看页
- 支持复制、刷新、换行开关

#### ScriptLibraryPage

- 搜索 + 分组筛选
- 列表字段：
  `name / groups / description / isInteractive`

### 测试任务

- Cronjob API client test
- Script API client test
- Form provider test
- Records page test

### 路由任务

- `/cronjobs`
- `/cronjobs/form`
- `/cronjobs/records`
- `/cronjobs/log`
- `/scripts`
- `/scripts/form`

---

## E. Backup

### 定位

不是“备份账户设置页”，而是完整备份管理入口。

### 上游功能参考

- `frontend/src/api/modules/backup.ts`
- `frontend/src/api/interface/backup.ts`

### 页面清单

- `BackupAccountsPage`
- `BackupAccountFormPage`
- `BackupRecordsPage`
- `BackupRecordDetailPage`
- `BackupRecoverPage`

### API层任务

- 对齐账户管理：
  `options / create / update / delete / refresh token / client info / conn check / buckets`
- 对齐执行：
  `backup / recover / recover by upload`
- 对齐记录：
  `record search / record download / record delete / record size / search files / by cronjob`

### Service/Repository任务

- `BackupRepository`
- `BackupService`
- `BackupActionService`

### Provider任务

- `BackupAccountsProvider`
- `BackupAccountFormProvider`
- `BackupRecordsProvider`
- `BackupActionProvider`

### UI规划

#### BackupAccountsPage

- 列表字段：
  `name / type / isPublic / bucket/path / last check state`
- 操作：
  `test / edit / delete`

#### BackupAccountFormPage

- Step 1：
  `Provider type`
- Step 2：
  `Credentials`
- Step 3：
  `Path/Bucket`
- Step 4：
  `Test & Save`

#### BackupRecordsPage

- 筛选：
  `type / detailName / account / time`
- 列表字段：
  `accountName / fileName / size / createdAt`

#### BackupRecoverPage

- 选择记录
- 填写恢复参数
- 风险确认
- 提交恢复

### 测试任务

- Backup account API client tests
- Backup record provider test
- Backup recover flow integration test

### 路由任务

- `/backups`
- `/backups/accounts/form`
- `/backups/records`
- `/backups/recover`

---

## F. Logs + Task Log

### 定位

日志中心，不再单独做 `task_log` 顶级模块。

### 上游功能参考

- `frontend/src/api/modules/log.ts`
- `frontend/src/routers/modules/log.ts`
- `frontend/src/views/log/`

### 页面清单

- `LogsCenterPage`
- `SystemLogViewerPage`
- `TaskLogDetailPage`

### API层任务

- 对齐：
  `operation logs / login logs / system files / task search / executing count`
- 整合：
  `task_log_v2.dart` 用于任务日志详情

### Service/Repository任务

- `LogsRepository`
- `LogsService`
- `TaskLogRepository`

### Provider任务

- `LogsProvider`
- `SystemLogsProvider`
- `TaskLogsProvider`

### UI规划

#### LogsCenterPage

- Tab：
  `Operation`
  `Login`
  `Task`
  `System`

#### Operation / Login

- 顶部筛选
- 卡片字段：
  `source/ip/status/action/time`

#### Task

- 列表字段：
  `name / type / status / current step / error / createdAt`
- 点击进入详情

#### System

- 先选日志文件
- 再进入文本查看器

### 测试任务

- Logs API client test
- Logs provider test
- System log viewer widget test

### 路由任务

- `/logs`
- `/logs/system`
- `/logs/task/detail`

---

## G. Runtime

### 定位

运行时中心，第一阶段最复杂模块。

### 上游功能参考

- `frontend/src/views/website/runtime/`
- `frontend/src/api/modules/runtime.ts`
- `frontend/src/api/interface/runtime.ts`

### 页面清单

- `RuntimesCenterPage`
- `RuntimeDetailPage`
- `RuntimeFormPage`
- `PhpExtensionsPage`
- `PhpConfigPage`
- `NodeModulesPage`
- `NodeScriptsPage`

### API层任务

- 对齐通用：
  `search / get / create / update / delete / operate / sync / remark`
- 对齐 Node：
  `package scripts / modules / modules operate`
- 对齐 PHP：
  `extensions / extension install / extension uninstall / config / file / fpm config / fpm status / container config`
- 对齐 supervisor：
  `process / process file`

### Service/Repository任务

- `RuntimeRepository`
- `RuntimeService`
- `PhpRuntimeService`
- `NodeRuntimeService`
- `PhpExtensionsService`
- `PhpConfigService`
- `NodeModulesService`
- `NodeScriptsService`

### Provider任务

- `RuntimesProvider`
- `RuntimeDetailProvider`
- `RuntimeFormProvider`
- `PhpRuntimeProvider`
- `NodeRuntimeProvider`
- `PhpExtensionsProvider`
- `PhpConfigProvider`
- `NodeModulesProvider`
- `NodeScriptsProvider`

### UI规划

#### RuntimesCenterPage

- 顶部语言 tabs：
  `PHP / Node / Java / Go / Python / .NET`
- 卡片字段：
  `name / version / status / port / codeDir`
- 操作：
  `start / stop / restart / sync / remark`

#### RuntimeDetailPage

- 分段：
  `Overview`
  `Config`
  `Advanced`

#### RuntimeFormPage

- Step 1：
  `Language / Name / Version`
- Step 2：
  `Port / Env / Volumes / Extra Hosts`
- Step 3：
  `Runtime specific options`
- 第一阶段完整支持：
  `PHP`
  `Node`
- 其他语言第一阶段仅做：
  `list/detail/operate`

#### PhpExtensionsPage

- 列表字段：
  `name / installed / versions / check`
- 操作：
  `install / uninstall`

#### PhpConfigPage

- 分区：
  `Basic`
  `FPM`
  `Container`
  `Raw File`

#### NodeModulesPage

- 列表字段：
  `name / version / description`
- 操作：
  `install / remove / update`

#### NodeScriptsPage

- 列表字段：
  `name / script`
- 操作：
  `copy`

### 测试任务

- Runtime API client tests
- Runtime list/detail provider tests
- PHP extensions/config tests
- Node modules/scripts tests

### 路由任务

- `/runtimes`
- `/runtimes/detail`
- `/runtimes/form`
- `/runtimes/php/extensions`
- `/runtimes/php/config`
- `/runtimes/node/modules`
- `/runtimes/node/scripts`

---

## 按周排期

| 周次 | 核心目标 | 主要模块 | 关键交付 |
|---|---|---|---|
| Week 1 | 统一入口、共享组件、Group 底座、API 对齐 | foundation + group | 运维中心与模块骨架 |
| Week 2 | 快捷命令库与主机资产 | command + host asset | 主机与命令 CRUD 可用 |
| Week 3 | SSH 与进程 | ssh + process | SSH/Process MVP |
| Week 4 | 计划任务列表与脚本库 | cronjob + script library | 调度中心主列表可用 |
| Week 5 | 计划任务表单与备份账户 | cronjob form + backup account | 创建任务与账户配置可用 |
| Week 6 | 备份执行/恢复与日志中心 | backup + logs | 备份与日志中心 MVP |
| Week 7 | 运行时中心列表/详情 | runtime | Runtime 通用链路可用 |
| Week 8 | Runtime PHP/Node 深化 + 回归 | runtime + regression | 阶段一闭环验收 |

---

## 每周分层任务清单

## Week 1

### API层

- 完成阶段一模块客户端对齐审计
- 修正路径漂移和错误请求体
- 扩展 `ApiClientManager`

### Service层

- `GroupService`
- 统一错误映射

### Provider层

- 共享 Provider 基类或约定

### 页面层

- `OperationsCenterPage`
- 共享空态/错态/确认组件

### 测试

- 共享组件 Widget tests
- Group service tests

### 路由

- 注册全部阶段一路由空壳

## Week 2

### API层

- `command`
- `host asset`

### Service层

- `CommandService`
- `HostAssetService`

### Provider层

- `CommandsProvider`
- `HostAssetsProvider`

### 页面层

- `CommandsPage`
- `CommandFormPage`
- `HostAssetsPage`
- `HostAssetFormPage`

### 测试

- `command_api_client_test`
- `host_api_client_test`

### 路由

- `/commands`
- `/hosts-assets`

## Week 3

### API层

- `ssh`
- `process`

### Service层

- `SshService`
- `ProcessService`

### Provider层

- `Ssh*Provider`
- `Process*Provider`

### 页面层

- `SshSettingsPage`
- `SshCertsPage`
- `SshLogsPage`
- `SshSessionsPage`
- `ProcessesPage`
- `ProcessDetailPage`

### 测试

- ssh/process provider tests

### 路由

- `/ssh`
- `/processes`

## Week 4

### API层

- `cronjob`
- `script library`

### Service层

- `CronjobService`
- `ScriptLibraryService`

### Provider层

- `CronjobsProvider`
- `ScriptLibraryProvider`

### 页面层

- `CronjobsPage`
- `CronjobRecordsPage`
- `ScriptLibraryPage`

### 测试

- cronjob/script API tests

### 路由

- `/cronjobs`
- `/scripts`

## Week 5

### API层

- `cronjob form`
- `backup account`

### Service层

- `CronjobFormService`
- `BackupService`

### Provider层

- `CronjobFormProvider`
- `BackupAccountsProvider`
- `BackupAccountFormProvider`

### 页面层

- `CronjobFormPage`
- `BackupAccountsPage`
- `BackupAccountFormPage`

### 测试

- cronjob form tests
- backup account tests

### 路由

- `/cronjobs/form`
- `/backups`

## Week 6

### API层

- `backup records/recover`
- `logs/task log`

### Service层

- `BackupActionService`
- `LogsService`

### Provider层

- `BackupRecordsProvider`
- `LogsProvider`
- `TaskLogsProvider`

### 页面层

- `BackupRecordsPage`
- `BackupRecoverPage`
- `LogsCenterPage`
- `SystemLogViewerPage`

### 测试

- backup recover flow
- logs widget/provider tests

### 路由

- `/backups/records`
- `/backups/recover`
- `/logs`

## Week 7

### API层

- runtime 通用能力

### Service层

- `RuntimeService`

### Provider层

- `RuntimesProvider`
- `RuntimeDetailProvider`
- `RuntimeFormProvider`

### 页面层

- `RuntimesCenterPage`
- `RuntimeDetailPage`
- `RuntimeFormPage`

### 测试

- runtime API tests
- runtime provider tests

### 路由

- `/runtimes`
- `/runtimes/detail`
- `/runtimes/form`

## Week 8

### API层

- PHP/Node 深化

### Service层

- `PhpConfigService`
- `PhpExtensionsService`
- `NodeModulesService`
- `NodeScriptsService`

### Provider层

- 对应 PHP/Node 专项 Provider

### 页面层

- `PhpExtensionsPage`
- `PhpConfigPage`
- `NodeModulesPage`
- `NodeScriptsPage`

### 测试

- 全量回归
- UI 回归
- integration 写操作回归

### 路由

- `/runtimes/php/extensions`
- `/runtimes/php/config`
- `/runtimes/node/modules`
- `/runtimes/node/scripts`

---

## 测试与验收要求

### 必跑命令

- `flutter analyze`
- `dart run test_runner.dart unit`
- `dart run test_runner.dart ui`
- 涉及 API/网络/数据写入的功能需补 `integration`

### 每个模块最少测试集

- 1 个 API client test
- 1 个 Provider test
- 1 个 Widget test
- 1 条主写操作验证

### UI 验收清单

- 手机与平板可用
- 操作触点满足最小点击面积
- 破坏性操作有确认
- 日志/配置页面支持复制
- 网络错误有重试
- 无硬编码中文作为逻辑条件

---

## 风险与应对

| 风险 | 影响 | 应对 |
|---|---|---|
| 本地 API client 与上游路径漂移 | 高 | Week 1 必须先做 API 对齐审计 |
| 模块边界再次混乱 | 高 | 统一从运维中心进入，禁止随意挂入主壳导航 |
| Provider 过大 | 中 | 列表、详情、表单、日志分拆 |
| 移动端照搬 Web 结构 | 高 | 统一使用卡片、分段页、Step form、底部 Sheet |
| 日志/配置页性能问题 | 中 | 统一日志查看器组件，延迟加载和分页 |
| 文档与实现脱节 | 高 | 每周收口同步更新本文件与 requirement_tracking_matrix |

---

## 阶段一完成交付物

- 运维中心入口与统一路由
- Group 共享分组底座
- Host Asset + SSH + Process MVP
- Command MVP
- Cronjob + Script Library MVP
- Backup MVP
- Logs Center MVP
- Runtime MVP
- 完整测试基线
- 同步更新的规划文档

---

## 执行说明

本文件是第一阶段执行总纲。若由其他 Agent 实施，建议其按：

1. Week 1 先做共享基础设施与 API 对齐
2. 按工作流逐周推进
3. 每完成一周做一次阶段性评审
4. 不跨周提前扩张范围

---

**文档版本**: 1.3  
**最后更新**: 2026-03-28  
**维护者**: Open1PanelApp 协作代理  
