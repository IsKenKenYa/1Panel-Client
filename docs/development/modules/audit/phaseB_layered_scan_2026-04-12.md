# Phase B 分层静态审计（2026-04-12）

## UI 越层风险（Page 直接引用 API/ApiClientManager）

- 发现 4 条命中
- lib/features/settings/backup_account_page.dart:4 -> import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
- lib/features/settings/backup_account_page.dart:32 -> final apiClient = await ApiClientManager.instance.getSettingApi();
- lib/features/settings/backup_account_page.dart:48 -> final apiClient = await ApiClientManager.instance.getSettingApi();
- lib/features/monitoring/monitoring_page.dart:6 -> import '../../api/v2/monitor_v2.dart';

## API 返回体解析风险

- 自定义解析器/unwrap 文件数: 6
- lib/api/v2/container_v2.dart
- lib/api/v2/auth_v2.dart
- lib/api/v2/ai_v2.dart
- lib/api/v2/database_v2.dart
- lib/api/v2/openresty_v2.dart
- lib/api/v2/dashboard_v2.dart

- 存在直接 data 访问模式文件数: 22
- lib/api/v2/system_group_v2.dart
- lib/api/v2/disk_management_v2.dart
- lib/api/v2/command_v2.dart
- lib/api/v2/host_v2.dart
- lib/api/v2/logs_v2.dart
- lib/api/v2/app_v2.dart
- lib/api/v2/task_log_v2.dart
- lib/api/v2/cronjob_v2.dart
- lib/api/v2/ssh_v2.dart
- lib/api/v2/process_v2.dart
- lib/api/v2/container_v2.dart
- lib/api/v2/script_library_v2.dart
- lib/api/v2/host_tool_v2.dart
- lib/api/v2/runtime_v2.dart
- lib/api/v2/compose_v2.dart
- lib/api/v2/ssl_v2.dart
- lib/api/v2/ai_v2.dart
- lib/api/v2/update_v2.dart
- lib/api/v2/snapshot_v2.dart
- lib/api/v2/dashboard_v2.dart
- lib/api/v2/backup_account_v2.dart
- lib/api/v2/docker_v2.dart

## 模型动态字段风险 Top 20（按风险分）

| 文件 | mapDynamic | dynamic | listDynamic | score |
|---|---:|---:|---:|---:|
| lib/data/models/container_models.dart | 99 | 100 | 0 | 397 |
| lib/data/models/setting_models.dart | 75 | 78 | 0 | 303 |
| lib/data/models/setting_models.g.dart | 64 | 98 | 2 | 294 |
| lib/data/models/toolbox_models.dart | 59 | 64 | 5 | 251 |
| lib/data/models/website_models.dart | 61 | 62 | 1 | 247 |
| lib/data/models/app_models.g.dart | 42 | 69 | 9 | 213 |
| lib/data/models/app_models.dart | 52 | 54 | 1 | 212 |
| lib/data/models/common_models.dart | 45 | 51 | 4 | 194 |
| lib/data/models/container_extension_models.dart | 48 | 48 | 0 | 192 |
| lib/data/models/ssl_models.dart | 45 | 46 | 0 | 181 |
| lib/data/models/ai/agent_role_models.dart | 35 | 58 | 5 | 173 |
| lib/data/models/openresty_models.dart | 41 | 42 | 0 | 165 |
| lib/data/models/backup_account_models.dart | 38 | 39 | 1 | 155 |
| lib/data/models/mcp_models.dart | 31 | 39 | 8 | 148 |
| lib/data/models/database_models.dart | 32 | 34 | 0 | 130 |
| lib/data/models/user_models.dart | 28 | 28 | 0 | 112 |
| lib/data/models/logs_models.dart | 26 | 27 | 0 | 105 |
| lib/data/models/ai/agent_channel_enterprise_models.dart | 22 | 30 | 4 | 104 |
| lib/data/models/ai/agent_setting_models.dart | 24 | 28 | 2 | 104 |
| lib/data/models/monitoring_models.dart | 24 | 24 | 0 | 96 |

## API 客户端测试映射缺口（名称粗匹配）

- 未匹配到同名 api_client 测试的 API 文件: 8
- lib/api/v2/system_group_v2.dart
- lib/api/v2/disk_management_v2.dart
- lib/api/v2/website_group_v2.dart
- lib/api/v2/toolbox_v2.dart
- lib/api/v2/terminal_v2.dart
- lib/api/v2/user_v2.dart
- lib/api/v2/auth_v2.dart
- lib/api/v2/host_tool_v2.dart