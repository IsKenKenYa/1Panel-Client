# 1Panel V2 API 覆盖度追踪

## 概览

- 来源: docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json
- 端点总数: 546
- API方法总数: 524
- API客户端文件: 30
- 标签数: 52
- 覆盖口径: 已实现=存在API调用与数据模型，已测试=具备单元/集成/端到端测试，已文档=包含使用说明与已知限制

## 实现状态统计

| 维度 | 完成数 | 完成率 |
| --- | --- | --- |
| **API客户端实现** | 51/52 | 98% |
| **单元测试覆盖** | 20/52 | 38% |
| **文档覆盖** | 6/52 | 12% |

### 按优先级统计

| 优先级 | 模块数 | 已实现 | 已测试 | 已文档 |
| --- | --- | --- | --- | --- |
| **P0** | 15 | 15 (100%) | 11 (73%) | 3 (20%) |
| **P1** | 26 | 26 (100%) | 5 (19%) | 1 (4%) |
| **P2** | 11 | 10 (91%) | 4 (36%) | 2 (18%) |

## 优先级规则

- P0: 核心业务链路与主流程依赖（认证、仪表盘、应用、容器、网站、文件、系统设置、数据库、运行时、监控、备份账户）
- P1: 高价值扩展与运维能力（OpenResty归属网站模块、SSL、SSH、日志、任务、脚本、容器细分能力）
- P2: 工具类或低频能力（设备、Clam、Fail2ban、FTP、磁盘、菜单设置等）

## 标签覆盖清单

### P0 核心模块

| 标签 | 端点数 | API客户端 | 方法数 | 已测试 | 已文档 |
| --- | --- | --- | --- | --- | --- |
| Website | 54 | website_v2.dart | 20 | ✅ | ❌ |
| System Setting | 43 | setting_v2.dart | 27 | ✅ | ❌ |
| File | 37 | file_v2.dart | 40 | ✅ | ✅ |
| App | 30 | app_v2.dart | 27 | ✅ | ✅ |
| Backup Account | 25 | backup_account_v2.dart | 26 | ❌ | ❌ |
| Runtime | 25 | runtime_v2.dart | 12 | ❌ | ❌ |
| Container | 19 | container_v2.dart | 43 | ✅ | ✅ |
| Database Mysql | 14 | database_v2.dart | 17 | ✅ | ❌ |
| Dashboard | 12 | dashboard_v2.dart | 16 | ✅ | ❌ |
| Database | 9 | database_v2.dart | 17 | ✅ | ❌ |
| Database PostgreSQL | 9 | database_v2.dart | 17 | ✅ | ❌ |
| Database Redis | 7 | database_v2.dart | 17 | ✅ | ❌ |
| Auth | 5 | auth_v2.dart | 8 | ❌ | ❌ |
| Monitor | 5 | monitor_v2.dart | 7 | ❌ | ❌ |
| Database Common | 3 | database_v2.dart | 17 | ✅ | ❌ |

### P1 高价值扩展模块

| 标签 | 端点数 | API客户端 | 方法数 | 已测试 | 已文档 |
| --- | --- | --- | --- | --- | --- |
| Cronjob | 16 | cronjob_v2.dart | 12 | ❌ | ❌ |
| Firewall | 15 | firewall_v2.dart | 12 | ❌ | ❌ |
| SSH | 12 | terminal_v2.dart | 18 | ❌ | ❌ |
| Website SSL | 11 | ssl_v2.dart | 17 | ❌ | ❌ |
| AI | 10 | ai_v2.dart | 18 | ✅ | ❌ |
| Container Image | 10 | container_v2.dart | 43 | ❌ | ❌ |
| Host | 10 | host_v2.dart | 9 | ❌ | ❌ |
| OpenResty | 10 | openresty_v2.dart | 9 | ❌ | ✅ |
| Command | 8 | command_v2.dart | 14 | ✅ | ❌ |
| Container Docker | 8 | docker_v2.dart | 60 | ❌ | ❌ |
| Website CA | 7 | ssl_v2.dart | 17 | ❌ | ❌ |
| Container Compose-template | 6 | container_compose_v2.dart | 14 | ❌ | ❌ |
| Container Image-repo | 6 | docker_v2.dart | 60 | ❌ | ❌ |
| Container Compose | 5 | container_compose_v2.dart | 14 | ❌ | ❌ |
| ScriptLibrary | 5 | command_v2.dart | 14 | ❌ | ❌ |
| Container Network | 4 | container_v2.dart | 43 | ❌ | ❌ |
| Container Volume | 4 | container_v2.dart | 43 | ❌ | ❌ |
| Logs | 4 | logs_v2.dart | 12 | ❌ | ❌ |
| Website Acme | 4 | ssl_v2.dart | 17 | ❌ | ❌ |
| Website DNS | 4 | website_v2.dart | 20 | ❌ | ❌ |
| Website Domain | 4 | website_v2.dart | 20 | ❌ | ❌ |
| Website Nginx | 4 | openresty_v2.dart | 9 | ❌ | ❌ |
| Process | 2 | process_v2.dart | 6 | ❌ | ❌ |
| TaskLog | 2 | task_log_v2.dart | 2 | ❌ | ❌ |
| Website HTTPS | 2 | ssl_v2.dart | 17 | ❌ | ❌ |
| Website PHP | 1 | openresty_v2.dart | 9 | ❌ | ❌ |

### P2 工具类模块

| 标签 | 端点数 | API客户端 | 方法数 | 已测试 | 已文档 |
| --- | --- | --- | --- | --- | --- |
| Clam | 12 | toolbox_v2.dart | 42 | ✅ | ❌ |
| Device | 12 | host_v2.dart | 9 | ❌ | ❌ |
| FTP | 8 | toolbox_v2.dart | 42 | ✅ | ❌ |
| McpServer | 8 | ai_v2.dart | 18 | ✅ | ❌ |
| System Group | 8 | system_group_v2.dart | 4 | ❌ | ❌ |
| Fail2ban | 7 | toolbox_v2.dart | 42 | ✅ | ❌ |
| Host tool | 7 | toolbox_v2.dart | 42 | ✅ | ❌ |
| Disk Management | 4 | toolbox_v2.dart | 42 | ✅ | ❌ |
| PHP Extensions | 4 | openresty_v2.dart | 9 | ❌ | ❌ |
| untagged | 4 | - | - | ❌ | ❌ |
| Menu Setting | 1 | setting_v2.dart | 27 | ❌ | ❌ |

## 测试文件清单

### 单元测试 (test/api/)
- ai_api_test.dart
- app_api_test.dart
- command_api_test.dart
- common_models_test.dart
- container_api_test.dart
- mcp_api_test.dart
- toolbox_api_test.dart

### 集成测试 (test/api_client/)
- app_api_client_test.dart
- container_api_client_test.dart
- dashboard_api_client_test.dart
- database_api_client_test.dart
- file_api_client_test.dart
- setting_api_client_test.dart
- website_api_client_test.dart

## 关键差距

### 测试覆盖不足
- P1模块测试率仅19%，需要重点补充
- P0核心模块中Auth、Monitor、Backup Account、Runtime缺少测试

### 文档覆盖不足
- 仅12%的模块有文档
- 大部分模块缺少使用说明和已知限制

### UI集成缺失
- api_coverage.json未跟踪UI集成状态
- 需要建立UI页面与API的关联追踪

## 更新机制

- 新增功能必须同步更新 api_coverage.json 与本表
- 每个端点需要标记实现、测试、文档三个维度
- 以标签为最小单元推进覆盖率，同时维护端点级补充清单
- 定期运行测试验证实现状态

---

**最后更新**: 2026-02-14
