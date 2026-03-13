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

## 适配检查结果（基于 1Panel V2 swagger.json，2026-03-13）

**OpenAPI 缺失（swagger 有）**
- `GET` /apps/detail/node/{appKey}/{version}

**客户端缺失（swagger 有）**
- （无）

**客户端多余（swagger 无）**
- （无）

**参数命名差异（路径一致）**
- `/apps/icon/{key}`（swagger） vs `/apps/icon/{appId}`（OpenAPI 与客户端）
- `/apps/installed/params/{appInstallId}`（swagger） vs `/apps/installed/params/{id}`（客户端）

说明:
- `/apps/detail/node/{appKey}/{version}` 已在客户端实现，但 OpenAPI 未覆盖。
- `/core/settings/apps/store/update` 已在客户端实现。
- `/dashboard/app/launcher*` 由仪表盘模块的 `DashboardV2Api` 提供，不在 App 模块重复实现。

## 后续规划
- 应用商店搜索与分类功能增强
- 应用依赖管理
- 应用版本回滚功能
- 应用日志查看
- 应用性能监控
