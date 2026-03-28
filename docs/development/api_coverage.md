# 1Panel V2 API 覆盖度追踪

## 概览

- 来源: docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json
- 端点总数: 546
- API方法总数: 527
- API客户端文件: 32
- 标签数: 52
- 覆盖口径: 已实现=存在API调用与数据模型，已测试=具备单元/集成/端到端测试，已文档=包含使用说明与已知限制

## Phase 2 增量覆盖（2026-03-28）

- 范围: S2-3 Security & Gateway（Panel TLS、Website SSL、OpenResty）
- 收口项:
	- Website SSL Center：provider 全量筛选项与证书健康状态文案完成国际化映射。
	- OpenResty Center：风险提示/差异预览/摘要文案维持本地化映射闭环。
	- Panel TLS：页面文案与风险提示映射维持一致。
- 范围补充: S2-2 / S2-3 repository 边界收口
- 收口项补充:
	- Website Core：新增 `WebsiteRepository / WebsiteDomainRepository / WebsiteConfigRepository`，现有 website services 改为通过 repository 访问 API。
	- Security & Gateway：新增 `WebsiteSslRepository / OpenRestyRepository / PanelSslRepository`，现有 services 改为通过 repository 访问 API。
	- 测试补充：新增 `website_ssl_center_provider_test.dart`、`openresty_provider_test.dart`，并扩展 `website_s2_integration_test.dart` 与 `security_gateway_s2_integration_test.dart`。
- 范围增量: S2-4 Orchestration + AI（主链路收口）
- 收口项增量:
	- Orchestration：新增 `orchestration_repository.dart` 与 `orchestration_service.dart`，compose/image/network/volume provider 去 API 直连，并补齐独立页的 create/pull/detail/confirm/retry 主流程。
	- AI：`AIProvider` 改为依赖 `AIRepository`，`AIRepository` 改为通过 `ApiClientManager` 获取 API；`AIPage` 拆为 `Ollama / GPU / Domain` 三标签并完成域名绑定联动。
	- 回归测试：新增 `test/features/ai/ai_provider_test.dart`、`test/features/orchestration/providers/orchestration_provider_flow_test.dart`。
- 范围增量补充: S2-4 验证 + S2-5 Auth（进行中）
- 收口项增量补充:
	- S2-4：新增 `test/features/ai/ai_page_test.dart` 与 `test/features/orchestration/orchestration_page_test.dart`，补齐 route/injection 与页面壳 smoke。
	- S2-5：`AuthProvider` 改为依赖 `AuthService`；新增 `AuthRepository / AuthSessionStore`，会话存储切换到 `flutter_secure_storage`。
	- S2-5：新增 `DashboardRepository / DashboardService`，`DashboardProvider` 改为依赖 service；`FilesProvider` 的回收站读取已收回 service。
	- S2-5：`file` 分层继续收口为 `FilesRepository + Browser/Recycle/Transfer/Preview services`，并新增 `RecycleBinProvider / TransferManagerProvider / FilePreviewProvider` 承接页面状态。
	- S2-5：新增 `test/data/repositories/files_repository_test.dart`，覆盖缓存失效、多服务切换、无配置异常路径。
- 门禁结果:
	- `flutter analyze`：通过
	- `dart run test_runner.dart unit`：通过
	- `dart run test_runner.dart ui`：通过
	- `dart run test_runner.dart integration`：通过（部分依赖环境变量的用例按预期跳过）
	- `dart run test_runner.dart all`：通过
- 备注: 本节为阶段增量记录，不改写全量统计口径；全量统计在下一轮统一盘点时回刷。

## Phase 2 Final Snapshot（2026-03-28）

- Final 口径: Phase 2 以工作流收口为准，当前进入可合并状态。
- 核心完成面:
	- S2-1/S2-2/S2-3/S2-4/S2-5 均完成对应硬范围的主链路闭环。
	- S2-6 验收产物已落盘：
	  - `docs/development/s2_module_completion_list.md`
	  - `docs/development/s2_risk_residual_list.md`
	  - `docs/development/s2_regression_results.md`
	  - `docs/development/s2_route_cleanup_list.md`
- 已批准残留（Phase 3）:
	- `database` 用户管理细节与更多写操作表单。
	- `firewall` 高级链路（forward/filter advance/chain status）。
- 范围边界确认:
	- Website 长尾能力与 Orchestration 长尾能力按计划不纳入 Phase 2 硬交付。
	- 路由清理本轮仅做清单和证据归档，不进行字符串路由重构。

## 实现状态统计

| 维度 | 完成数 | 完成率 |
| --- | --- | --- |
| **API客户端实现** | 51/52 | 98% |
| **单元测试覆盖** | 28/52 | 54% |
| **文档覆盖** | 15/52 | 29% |

### 按优先级统计

| 优先级 | 模块数 | 已实现 | 已测试 | 已文档 |
| --- | --- | --- | --- | --- |
| **P0** | 15 | 15 (100%) | 12 (80%) | 4 (27%) |
| **P1** | 26 | 26 (100%) | 12 (46%) | 9 (35%) |
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
| Backup Account | 25 | backup_account_v2.dart | 26 | ✅ | ✅ |
| Runtime | 25 | runtime_v2.dart | 12 | ✅ | ✅ |
| Container | 19 | container_v2.dart | 43 | ✅ | ✅ |
| Database Mysql | 14 | database_v2.dart | 17 | ✅ | ❌ |
| Dashboard | 12 | dashboard_v2.dart | 16 | ✅ | ❌ |
| Database | 9 | database_v2.dart | 17 | ✅ | ❌ |
| Database PostgreSQL | 9 | database_v2.dart | 17 | ✅ | ❌ |
| Database Redis | 7 | database_v2.dart | 17 | ✅ | ❌ |
| Auth | 5 | auth_v2.dart | 8 | ✅ | ❌ |
| Monitor | 5 | monitor_v2.dart | 7 | ❌ | ❌ |
| Database Common | 3 | database_v2.dart | 17 | ✅ | ❌ |

### P1 高价值扩展模块

| 标签 | 端点数 | API客户端 | 方法数 | 已测试 | 已文档 |
| --- | --- | --- | --- | --- | --- |
| Cronjob | 16 | cronjob_v2.dart | 12 | ✅ | ✅ |
| Firewall | 15 | firewall_v2.dart | 12 | ❌ | ❌ |
| SSH | 12 | ssh_v2.dart | 12 | ✅ | ✅ |
| Website SSL | 11 | ssl_v2.dart | 17 | ❌ | ❌ |
| AI | 10 | ai_v2.dart | 18 | ✅ | ❌ |
| Container Image | 10 | container_v2.dart | 43 | ❌ | ❌ |
| Host | 10 | host_v2.dart | 9 | ✅ | ✅ |
| OpenResty | 10 | openresty_v2.dart | 9 | ❌ | ✅ |
| Command | 8 | command_v2.dart | 14 | ✅ | ✅ |
| Container Docker | 8 | docker_v2.dart | 60 | ❌ | ❌ |
| Website CA | 7 | ssl_v2.dart | 17 | ❌ | ❌ |
| Container Compose-template | 6 | container_compose_v2.dart | 14 | ❌ | ❌ |
| Container Image-repo | 6 | docker_v2.dart | 60 | ❌ | ❌ |
| Container Compose | 5 | container_compose_v2.dart | 14 | ❌ | ❌ |
| ScriptLibrary | 5 | script_library_v2.dart | 3 | ✅ | ✅ |
| Container Network | 4 | container_v2.dart | 43 | ❌ | ❌ |
| Container Volume | 4 | container_v2.dart | 43 | ❌ | ❌ |
| Logs | 4 | logs_v2.dart | 12 | ✅ | ✅ |
| Website Acme | 4 | ssl_v2.dart | 17 | ❌ | ❌ |
| Website DNS | 4 | website_v2.dart | 20 | ❌ | ❌ |
| Website Domain | 4 | website_v2.dart | 20 | ✅ | ❌ |
| Website Nginx | 4 | openresty_v2.dart | 9 | ❌ | ❌ |
| Process | 2 | process_v2.dart | 4 | ✅ | ✅ |
| TaskLog | 2 | task_log_v2.dart | 2 | ✅ | ✅ |
| Website HTTPS | 2 | ssl_v2.dart | 17 | ❌ | ❌ |
| Website PHP | 1 | openresty_v2.dart | 9 | ❌ | ❌ |

### P2 工具类模块

| 标签 | 端点数 | API客户端 | 方法数 | 已测试 | 已文档 |
| --- | --- | --- | --- | --- | --- |
| Clam | 12 | toolbox_v2.dart | 42 | ✅ | ❌ |
| Device | 12 | host_v2.dart | 9 | ❌ | ❌ |
| FTP | 8 | toolbox_v2.dart | 42 | ✅ | ❌ |
| McpServer | 8 | ai_v2.dart | 18 | ✅ | ❌ |
| System Group | 8 | system_group_v2.dart | 8 | ✅ | ✅ |
| Fail2ban | 7 | toolbox_v2.dart | 42 | ✅ | ❌ |
| Host tool | 7 | toolbox_v2.dart | 42 | ✅ | ❌ |
| Disk Management | 4 | toolbox_v2.dart | 42 | ✅ | ❌ |
| PHP Extensions | 4 | openresty_v2.dart | 9 | ❌ | ❌ |
| untagged | 4 | - | - | ❌ | ❌ |
| Menu Setting | 1 | setting_v2.dart | 27 | ❌ | ❌ |

## 测试文件清单

> Week 7 同步说明：`RuntimesCenterPage` / `RuntimeDetailPage` / `RuntimeFormPage` 已接入真实页面、Repository、Service、Provider 与 no-server 回归；Week 7 只覆盖运行时通用链路，PHP/Node 深能力留到 Week 8。

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
- backup_api_client_test.dart
- command_api_client_test.dart
- cronjob_api_client_test.dart
- cronjob_form_api_client_test.dart
- phase1_api_alignment_test.dart
- container_api_client_test.dart
- dashboard_api_client_test.dart
- database_backup_api_client_test.dart
- database_api_client_test.dart
- firewall_api_client_test.dart
- file_api_client_test.dart
- host_api_client_test.dart
- process_api_client_test.dart
- setting_api_client_test.dart
- script_library_api_client_test.dart
- ssh_api_client_test.dart
- website_api_client_test.dart
- website_lifecycle_api_client_test.dart

### WebSocket 契约测试
- process_ws_client_test.dart
- script_run_ws_client_test.dart

## 关键差距

### 测试覆盖不足
- P1 模块测试率进一步提升，但 Firewall 等模块仍未补齐
- P0 核心模块中 Auth、Monitor 仍缺模块级测试

### 文档覆盖不足
- 目前 `Cronjob / Backup Account / SSH / Process / Command / Host / OpenResty / ScriptLibrary / System Group / Logs / TaskLog / Runtime` 已有阶段性文档
- 仍有大量模块缺少使用说明和已知限制

### UI集成缺失
- api_coverage.json未跟踪UI集成状态
- 需要建立UI页面与API的关联追踪

## 更新机制

- 新增功能必须同步更新 api_coverage.json 与本表
- 每个端点需要标记实现、测试、文档三个维度
- 以标签为最小单元推进覆盖率，同时维护端点级补充清单
- 定期运行测试验证实现状态

---

**最后更新**: 2026-03-27
