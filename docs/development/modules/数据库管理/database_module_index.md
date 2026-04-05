# 数据库管理模块索引

## 模块定位
Open1PanelApp 的数据库管理模块负责MySQL、PostgreSQL、Redis等数据库的创建、配置、备份恢复与性能监控，提供移动端友好的数据库管理体验。

## S2-0 基线（2026-03-26）

- 当前状态：
  已具备 `route + repository + service + provider + page` 基础闭环，当前主链路覆盖 `list / detail / form / remote / redis config`。
- 阶段 2 hard scope：
  `list / detail / backup / user management`
- API 基线：
  `check_module_api_updates.py database` 当前结果为 `unchanged`
- 当前基线缺口：
  `backup / restore` 需通过 `/backups/*` 链路实现，而不是继续扩展 `database_v2.dart`；
  `user management` 需严格按 V2 真实接口口径实现，而不是假设完整 CRUD。

## S2-1 实施进展（2026-03-26）

- 已落地：
  `database_v2.dart` 第一轮对齐
  `DatabaseRepository`
  `DatabasesService`
  `DatabasesProvider / DatabaseDetailProvider / DatabaseFormProvider`
  `DatabasesPage / DatabaseDetailPage / DatabaseFormPage / DatabaseRemotePage / DatabaseRedisPage`
  `DatabaseBackupRepository / DatabaseBackupService / DatabaseBackupProvider / DatabaseBackupPage`
  `DatabaseUserRepository / DatabaseUserService / DatabaseUsersProvider / DatabaseUsersPage`
- 已补测试：
  `database_api_client_test.dart`
  `database_backup_api_client_test.dart`
  `databases_provider_test.dart`
  `database_backup_provider_test.dart`
  `database_detail_provider_test.dart`
  `database_users_provider_test.dart`
  `database_pages_test.dart`
  `database_s2_integration_test.dart`
- 集成前置条件：
  `test/core/test_config_manager.dart` 已支持环境变量覆盖 `.env`，用于在不改文件的前提下启用 `RUN_INTEGRATION_TESTS`
- 当前仍未闭环：
  MySQL / PostgreSQL 专属详情页仍在补齐；
  列表页与创建页已转向“实例驱动”，但仍需继续补本地/远程实例分组与更细的 Web 行为。
- 本轮收口：
  remote 数据库详情页已隐藏当前不支持的写操作；
  Redis 创建入口已禁用，等待真实创建链路完成后再开放；
  数据库备份已通过 `/backups/*` 接入 `list / create / restore / delete`；
  用户管理已按真实 V2 接入 `MySQL bind user` 与 `PostgreSQL bind user / privilege`。
  数据库模块核心数据流已开始按 Web 对齐为“数据库类型 / 目标实例 / 逻辑数据库名”三层语义，避免继续混用 `engine / database / name`。

## 子模块结构
- 架构设计: docs/development/modules/数据库管理/database_module_architecture.md
- 开发计划: docs/development/modules/数据库管理/database_plan.md
- FAQ: docs/development/modules/数据库管理/database_faq.md
- API分析: docs/development/modules/数据库管理/database_api_analysis.md

## 后续规划
- 继续补齐 MySQL / PostgreSQL 专属详情页
- 列表页补本地/远程实例分组切换
- 创建页按 Web 逐类型补完剩余字段与默认值
- 补更细粒度的数据库状态/变量配置页
