# 应用管理模块索引

## 模块定位
Open1PanelApp 的应用管理模块负责应用商店浏览、应用安装、配置管理、应用生命周期管理，提供便捷的应用部署与管理体验。

## 子模块结构
- 架构设计: docs/development/modules/应用管理/app_module_architecture.md
- 页面设计: docs/development/modules/应用管理/app_pages.md
- API设计: docs/development/modules/应用管理/app_api.md
- API分析: docs/development/modules/应用管理/app_api_analysis.md
- API数据: docs/development/modules/应用管理/app_api_analysis.json
- 数据设计: docs/development/modules/应用管理/app_data.md
- 开发计划: docs/development/modules/应用管理/app_plan.md
- 运维手册: docs/development/modules/应用管理/app_ops.md
- 用户手册: docs/development/modules/应用管理/app_user_manual.md
- FAQ: docs/development/modules/应用管理/app_faq.md

## 适配检查结果（基于 1Panel V2 OpenAPI.json，2026-03-20）

**OpenAPI 缺失（swagger 有，客户端已兼容）**
- `GET` /apps/detail/node/{appKey}/{version}

**客户端缺失（OpenAPI 有）**
- （无）

**客户端多余（OpenAPI 无）**
- （无）

**契约说明（已按 OpenAPI 收口）**
- `/apps/installed/config/update` 仅发送 `installID` 与可选 `webUI`
- `/apps/installed/params/update` 承载高级配置、容器名、CPU/内存与 `params`
- `/apps/installed/port/change` 使用单端口请求体 `{key,name,port}`
- `/apps/installed/ignore` 的 `scope` 仅允许 `all | version`

**前端未接入（客户端已有能力）**
- `/core/settings/apps/store/config`
- `/core/settings/apps/store/update`

说明:
- `/apps/detail/node/{appKey}/{version}` 已在客户端实现，但 OpenAPI 未覆盖。
- 卸载前检查 `/apps/installed/delete/check/:appInstallId` 已接入列表页和详情页卸载确认。
- 已安装应用列表已改为分页拉全，不再默认截断前 100 条。
- `InstalledAppDetailPage` 已改为通过 `InstalledAppDetailProvider` 编排多接口加载与局部失败。
- `/dashboard/app/launcher*` 由仪表盘模块的 `DashboardV2Api` 提供，不在 App 模块重复实现。

## 后续规划
- 应用商店配置页接入
- 应用版本回滚功能
- 应用日志查看
- 应用性能监控
