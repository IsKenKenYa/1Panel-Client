# 数据库管理模块索引

## 模块定位
Open1PanelApp 的数据库管理模块负责MySQL、PostgreSQL、Redis等数据库的创建、配置、备份恢复与性能监控，提供移动端友好的数据库管理体验。

## S2-0 基线（2026-03-26）

- 当前状态：
  仅有 `database_v2.dart + database_models.dart + DatabasesPage`，且页面仍直接调用 API，未形成 `repository / service / provider / page` 闭环。
- 阶段 2 hard scope：
  `list / detail / backup / user management`
- API 基线：
  `check_module_api_updates.py database` 当前结果为 `unchanged`
- 文档缺口：
  索引引用的 `database_pages.md / database_api.md / database_data.md / database_ops.md / database_user_manual.md` 当前不存在。

## 子模块结构
- 架构设计: docs/development/modules/数据库管理/database_module_architecture.md
- 页面设计: docs/development/modules/数据库管理/database_pages.md
- API设计: docs/development/modules/数据库管理/database_api.md
- 数据设计: docs/development/modules/数据库管理/database_data.md
- 开发计划: docs/development/modules/数据库管理/database_plan.md
- 运维手册: docs/development/modules/数据库管理/database_ops.md
- 用户手册: docs/development/modules/数据库管理/database_user_manual.md
- FAQ: docs/development/modules/数据库管理/database_faq.md

## 后续规划
- 数据库性能监控图表
- 慢查询分析功能
- 数据库迁移工具
- 多数据库实例管理
