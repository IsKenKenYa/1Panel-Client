# Phase 2 主计划

## 文档定位

本文件是 Open1PanelApp 针对 1Panel V2 API 适配的第二阶段执行蓝图。

第二阶段不再按“单个模块零散推进”，而是按 **工作流** 收口。核心目标是把当前“已有入口或已有半成品、但存在能力缺口、分层违规、路由错位、测试不足”的模块，统一拉升为可上线交付状态。

本文件可直接作为：

- Phase 2 执行依据
- 第二个 Agent 的实现输入
- 阶段验收与代码评审的范围定义
- 后续 Phase 3 规划的上游输入

---

## 规范源与约束

### Source of Truth

- OpenAPI 规范：
  `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
- 模块工作流：
  `docs/development/modules/模块适配专属工作流.md`
- 网站严格审计：
  `docs/development/modules/网站管理-OpenResty/website_strict_audit_2026-03-20.md`
- Phase 1 主计划：
  `docs/development/modules/phase1_execution_plan.md`
- 需求跟踪矩阵：
  `docs/development/requirement_tracking_matrix.md`
- API 覆盖追踪：
  `docs/development/api_coverage.md`
- 仓库架构规范：
  `AGENTS.md`

### 强制架构规则

Phase 2 全部模块必须继续遵守：

- 依赖方向只允许：
  `Presentation -> State -> Service/Repository -> API/Infra`
- UI 页面不得直接调用 `lib/api/v2/`
- Provider 不得直接持有 `*V2Api`
- 页面、Provider、Service 必须遵守文件大小限制
- 所有用户可见文本必须国际化
- 所有 UI 改动必须兼顾手机与平板

### Phase 2 完成口径

任一工作流或模块要被判定为“Phase 2 完成”，必须同时满足：

- 有产品入口和命名路由
- 有 `Repository + Service + Provider + Page` 完整闭环
- 已完成真实 API 校准和至少一轮 API 实测
- 关键写操作有测试
- UI 链路不存在明显越层调用
- 模块文档、矩阵、覆盖追踪已同步更新
- 可通过 `flutter analyze`
- 可通过 `dart run test_runner.dart unit`
- UI 改动可通过 `dart run test_runner.dart ui`
- 涉及写操作或主链路网络交互的模块已补 integration

---

## 阶段目标

### 总目标

把以下“已有实现但明显不完整”的模块提升到可上线质量：

- `database`
- `firewall`
- `website`
- `website_domain`
- `website_config`
- `panel ssl`
- `website ssl`
- `openresty`
- `orchestration (compose/image/network/volume)`
- `ai`
- `dashboard`
- `auth`
- `file`

### Phase 2 不做的事

以下内容不进入 Phase 2 主交付范围：

- `toolbox/device` 聚合工具链
- `system group` 独立管理页
- `runtime` 多语言深度增强
- `container/app/monitor/setting` 非必要深化能力
- 网站链路中的所有长尾高级配置
  例如：
  `proxy cache`
  `real ip`
  `stream`
  `复杂负载均衡`

---

## 当前问题基线

Phase 2 不是“补几个按钮”，而是要解决以下结构性问题：

### 1. Page 直连 API

当前典型问题：

- `lib/features/databases/databases_page.dart`
- `lib/features/firewall/firewall_page.dart`

### 2. Provider 越层持有 API

当前典型问题：

- `lib/features/dashboard/dashboard_provider.dart`
- `lib/features/auth/auth_provider.dart`
- `lib/features/orchestration/providers/compose_provider.dart`
- `lib/features/orchestration/providers/network_provider.dart`
- `lib/features/orchestration/providers/image_provider.dart`
- `lib/features/orchestration/providers/volume_provider.dart`
- `lib/features/files/files_provider.dart`

### 3. 模块虽有页面，但功能覆盖远低于上游

当前最典型的是网站链路：

- `website`
- `website_domain`
- `website_config`
- `website_ssl`
- `openresty`

上游对照结论已在：
`docs/development/modules/网站管理-OpenResty/website_strict_audit_2026-03-20.md`

### 4. 模块已写好但未接线

典型代表：

- `AI`
  已有 feature 代码，但缺路由、入口和注入

### 5. 文档完成度高于真实交付度

`module_planning_index.md` 中大量模块被标记为完成，但代码侧仍有明显越层、入口缺失或能力缺口，Phase 2 不再以该文档中的勾选状态作为范围判定依据。

---

## Phase 2 工作流划分

第二阶段按 `5 个工作流 + 1 个收口阶段` 推进。

### S2-0 基线校准

目标：
冻结阶段二真实范围，避免边做边漂移。

覆盖模块：

- `database`
- `firewall`
- `website`
- `ssl`
- `openresty`
- `compose`
- `ai`
- `dashboard`
- `auth`
- `file`

必须执行：

- `check_module_api_updates.py`
- `analyze_module_api.py`
- 重复实现扫描
- 上游 1Panel 前端与 API 模块对照
- API 客户端与真实返回体验证

输出物：

- 模块基线差异清单
- scope freeze 清单
- 漂移接口清单

### S2-1 Database + Firewall

目标：
把两个“只有列表页或薄页面”的业务模块补成完整闭环。

硬范围：

- `database`
  - list
  - detail
  - backup
  - user management
- `firewall`
  - status
  - rules
  - ip
  - ports

强制要求：

- Page 直连 API 必须全部收回
- 必须补 `Repository + Service + Provider + Page`

### S2-2 Website Core

目标：
把 `website + website_domain + website_config` 作为同一条业务主链路推进。

硬范围：

- 站点生命周期：
  create / update / start / stop / restart / delete
- 站点详情
- 默认站点
- 分组
- remark
- 域名：
  CRUD + 校验
- 配置中心：
  结构化配置入口

尾部范围：

- `proxy cache`
- `load balance`
- `real ip`
- `stream`

### S2-3 Security & Gateway

目标：
把 `panel ssl + website ssl + openresty` 收口成一条安全与网关工作流。

硬范围：

- `panel ssl`
  从 settings 薄页抽为独立 feature
- `website ssl`
  证书中心
  站点绑定
  HTTPS 策略
- `openresty`
  status
  https
  modules
  config
  build

强制能力：

- 风险提示
- 差异预览
- 回滚入口

### S2-4 Orchestration + AI

目标：
把编排家族与 AI 接线收口。

硬范围：

- `compose`
- `image`
- `network`
- `volume`
- `ai`
  - route
  - injection
  - entry
  - domain binding 联动

尾部范围：

- image repo
- compose template

### S2-5 Core Refactor

目标：
对核心已上线模块做分层收口和质量修复，不扩大量新功能。

覆盖模块：

- `dashboard`
- `auth`
- `file`

目标拆分：

- `dashboard`
  拆大 Provider，收回 API 依赖
- `auth`
  拆 session/token/storage/api
  替换 `SharedPreferences + debugPrint`
  使用更安全存储和 `appLogger`
- `file`
  以 `files_provider.dart` 为核心拆出：
  `browser / recycle / transfer / preview`

### S2-6 收口与验收

目标：

- 统一路由清理
- 统一测试回归
- 文档回写
- 整体验收

---

## 执行顺序

Phase 2 不按时间表达，只按依赖顺序执行。

### 推荐顺序

1. `S2-0 基线校准`
2. `S2-1 Database + Firewall`
3. `S2-2 Website Core`
4. `S2-3 Security & Gateway`
5. `S2-4 Orchestration + AI`
6. `S2-5 Core Refactor`
7. `S2-6 收口与验收`

### 顺序说明

- `Database + Firewall` 先做，因为它们结构最薄、越层最明显、独立性最好
- `Website Core` 先于 `Security & Gateway`，因为 SSL/OpenResty 要挂靠网站主链路
- `AI` 放到 `Orchestration + AI`，因为其首要任务是接线，而不是扩新功能
- `Core Refactor` 放在后面，避免在前期和主功能建设互相打架

---

## 统一目录与分层模板

Phase 2 所有模块继续使用如下模板：

```text
lib/data/repositories/<module>_repository.dart
lib/features/<module>/
  pages/
  providers/
  services/
  widgets/
```

### 推荐拆分

- 列表模块：
  `*_provider.dart`
- 详情模块：
  `*_detail_provider.dart`
- 表单模块：
  `*_form_provider.dart`
- 日志/预览模块：
  `*_logs_provider.dart`
  `*_preview_provider.dart`

### 共享组件复用要求

优先复用或扩展 Phase 1 共享组件：

- `async_state_page_body_widget.dart`
- `search_filter_bar_widget.dart`
- `selection_action_bar_widget.dart`
- `confirm_action_sheet_widget.dart`
- `status_chip_widget.dart`
- `key_value_section_card_widget.dart`
- `log_text_viewer_widget.dart`

---

## 统一 UI 设计规则

### 信息架构原则

- 不照搬 1Panel Web 表格页
- 手机端优先卡片化
- 平板端增强双栏
- 一级入口不超过 4 个主分段
- 复杂配置改为结构化 section cards

### 列表页统一规则

必须具备：

- 搜索
- 常用筛选
- 刷新
- 空态
- 错态
- 批量模式

### 详情页统一规则

统一建议结构：

- `Overview`
- `Config`
- `History / Logs / Advanced`

### 表单页统一规则

复杂表单必须使用：

- 分步
  或
- 分段 section

### 文本与配置页

必须具备：

- 等宽字体
- 复制
- 风险提示
- 差异预览
- 保存前校验

### 危险操作

必须具备：

- 二次确认
- 明确影响说明
- 可取消

---

## 工作流详解

## S2-0 基线校准

### API层

- 对每个模块执行 API 变更检查
- 重新生成模块分析报告
- 核对本地 client 与 Swagger 路径/请求体/响应体
- 标记 drift endpoints

### Service/Repository层

- 不新增业务实现
- 只做对齐审计和基线输出

### Provider层

- 不新增业务实现

### 页面层

- 不新增业务实现
- 只做 UI 链路扫描和重复实现审计

### 测试

- 补最小 API smoke 验证
- 记录真实返回体样例

### 文档输出

- scope freeze
- drift list
- reuse list

---

## S2-1 Database + Firewall

## Database

### 现状

- 只有列表页
- 页面直连 API
- 缺 service/provider
- 缺 detail/backup/user management

### 目标页面

- `DatabasesPage`
- `DatabaseDetailPage`
- `DatabaseBackupPage`
- `DatabaseUsersPage`

### API层任务

- 校准 `database_v2.dart`
- 对齐 MySQL/PostgreSQL/Redis/Common 能力
- 明确 detail/status/backup/user 相关接口

### Service/Repository任务

- `DatabaseRepository`
- `DatabaseService`
- `DatabaseBackupService`
- `DatabaseUserService`

### Provider任务

- `DatabasesProvider`
- `DatabaseDetailProvider`
- `DatabaseBackupProvider`
- `DatabaseUsersProvider`

### UI任务

- 列表页卡片化
- 详情页分区：
  `overview / status / users / backups`
- 备份管理页
- 用户管理页

### 测试任务

- API client tests
- Provider tests
- Widget tests
- backup/user 写操作验证

## Firewall

### 现状

- 只有规则列表页
- 页面直连 API
- 缺 provider/service
- 缺 status/ip/port/advanced 闭环

### 目标页面

- `FirewallStatusPage`
- `FirewallRulesPage`
- `FirewallIpRulesPage`
- `FirewallPortRulesPage`

### API层任务

- 校准 `firewall_v2.dart`
- 核对 status、rules、ip、ports

### Service/Repository任务

- `FirewallRepository`
- `FirewallService`

### Provider任务

- `FirewallStatusProvider`
- `FirewallRulesProvider`
- `FirewallIpProvider`
- `FirewallPortsProvider`

### UI任务

- 状态卡片
- 规则列表
- 新增/编辑规则表单
- IP 与端口分段

### 测试任务

- API smoke
- Provider tests
- rules 写操作测试

---

## S2-2 Website Core

### 现状

- 主链路已有
- 但覆盖能力远低于上游
- 部分 provider 仍保留 API 适配边界问题

### 硬范围

- site lifecycle
- create/update
- detail
- default site
- group
- remark
- domain CRUD + validation
- structured config center

### 目标页面

- `WebsitesPage`
- `WebsiteDetailPage`
- `WebsiteCreateFlowPage`
- `WebsiteEditPage`
- `WebsiteDomainManagementPage`
- `WebsiteConfigCenterPage`

### API层任务

- 补齐 create/update/default/group/remark/domain
- 校准 `website_v2.dart`

### Service/Repository任务

- 继续拆细现有 website services
- 把 domain/config 中的残余 API 耦合收回

### Provider任务

- `WebsitesProvider`
- `WebsiteDetailProvider`
- `WebsiteCreateProvider`
- `WebsiteEditProvider`
- `WebsiteDomainProvider`
- `WebsiteConfigCenterProvider`

### UI任务

- 网站列表支持默认站点、分组、状态操作
- 创建/编辑表单结构化
- 域名管理支持校验和批量录入入口
- 配置中心从原始编辑为主，升级为结构化入口页

### 测试任务

- website/domain/config API client tests
- create/edit/domain provider tests
- 核心页面 widget tests

### Tail

- proxy cache
- load balance
- real ip
- stream

---

## S2-3 Security & Gateway

### 覆盖范围

- `panel ssl`
- `website ssl`
- `openresty`

## Panel SSL

### 目标

从 settings 子页提升为独立 feature，但仍可保留 settings 入口跳转。

### 页面

- `PanelSslCenterPage`
- `PanelSslDetailPage`

## Website SSL

### 目标

- 证书中心
- 站点绑定
- HTTPS 策略

### 页面

- `WebsiteSslCenterPage`
- `WebsiteCertificateDetailPage`
- `WebsiteSiteSslPage`

## OpenResty

### 目标

从 JSON/手输导向升级为结构化操作中心。

### 页面

- `OpenrestyStatusPage`
- `OpenrestyHttpsPage`
- `OpenrestyModulesPage`
- `OpenrestyConfigPage`
- `OpenrestyBuildPage`

### 强制能力

- 风险提示
- 差异预览
- 回滚入口

### API层任务

- 校准 `ssl_v2.dart`
- 校准 `openresty_v2.dart`
- 标记漂移接口并收口

### Service/Repository任务

- `PanelSslRepository/Service`
- `WebsiteSslRepository/Service`
- `OpenrestyRepository/Service`

### Provider任务

- 列表/详情/编辑/预览/回滚相关 Provider 分拆

### 测试任务

- ssl/openresty API tests
- provider tests
- config diff/rollback widget tests

---

## S2-4 Orchestration + AI

## Orchestration

### 覆盖范围

- compose
- image
- network
- volume

### 目标

不是只修 compose 页面，而是把 `orchestration_page.dart` 下整族 provider 越层问题一起收口。

### 页面

- `OrchestrationPage`
- `ComposePage`
- `ImagePage`
- `NetworkPage`
- `VolumePage`

### API层任务

- 校准 `compose_v2.dart`
- 校准 `docker_v2.dart`

### Service/Repository任务

- `ComposeRepository/Service`
- `ImageRepository/Service`
- `NetworkRepository/Service`
- `VolumeRepository/Service`

### Provider任务

- 现有 provider 全部收回 API 依赖

### Tail

- image repo
- compose template

## AI

### 现状

- feature 代码已存在
- 无路由
- 无注入
- domain binding 仍是半成品

### 目标

优先“接线”和“真实联动”，不在 Phase 2 扩张过多新功能。

### 页面

- 复用现有 `AIPage`
- 补注入与入口
- 补真实 domain binding 流

### API层任务

- 校准 `ai_v2.dart`
- 核对 MCP/域名绑定相关能力

### Service/Repository任务

- 梳理现有 `AIService/AIRepository`
- 移除 Provider 直连 API

### Provider任务

- 现有 `AIProvider` 改为依赖 service

### 路由任务

- 新增 AI 路由和入口

### 测试任务

- AI route/injection smoke
- provider tests
- domain binding 主链路验证

---

## S2-5 Core Refactor

### Dashboard

- 拆分 `dashboard_provider.dart`
- 收回 API 依赖
- 拆成：
  `overview`
  `top processes`
  `quick actions`
  `activity`

### Auth

- 将 `auth_provider.dart` 中的 API、session、token 存储拆开
- 替换 `SharedPreferences`
- 统一使用更安全存储
- 替换 `debugPrint`
- 统一使用 `appLogger`

### File

- 拆 `files_provider.dart`
- 子流拆分：
  `browser`
  `recycle`
  `transfer`
  `preview`
- 回收站等越层 API 调用全部收回 service/repository

### 测试任务

- dashboard/auth/file provider tests
- 关键回归测试

---

## S2-6 收口与验收

### 必做事项

- `flutter analyze`
- `dart run test_runner.dart unit`
- `dart run test_runner.dart ui`
- 必要的 integration
- `dart run test_runner.dart all`
- 路由清理
- 文档回写
- requirement matrix 同步
- api coverage 同步

### 验收输出

- 模块完成清单
- 风险残留清单
- 回归结果清单

---

## Agent 执行要求

若 Phase 2 交给其他 Agent 执行，要求其遵守：

- 先完成 `S2-0`
- 按 `S2-1 -> S2-2 -> S2-3 -> S2-4 -> S2-5 -> S2-6` 顺序推进
- 不允许跳过 `API 校准`
- 不允许把 UI 先于分层修复落地
- 每个工作流完成后必须先自测、补文档，再进入下一个
- 不允许私自扩大 hard scope

---

## 文档更新要求

Phase 2 过程中，必须同步更新：

- 对应模块的 `module_index`
- `module_architecture`
- `plan`
- `faq`
- `requirement_tracking_matrix.md`
- `api_coverage.md`

---

**文档版本**: 1.0  
**最后更新**: 2026-03-25  
**维护者**: Open1PanelApp 协作代理  
