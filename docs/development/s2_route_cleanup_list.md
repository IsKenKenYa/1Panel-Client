# S2-6 路由清理清单

更新日期: 2026-03-28  
适用分支: 模块适配-阶段2

## 1. 本轮决策

- 本轮目标: 形成路由清理证据与映射清单。
- 本轮边界: 不执行字符串路由到 AppRoutes 常量的代码重构。
- 后续建议: 在 Phase 3 单独立项执行统一常量化与回归。

## 2. 证据来源

- lib/config/app_router.dart
- lib/features/shell/app_shell_page.dart
- lib/features/server/server_detail_page.dart

## 3. 当前路由现状摘要

### 3.1 已使用 AppRoutes 常量的主路径

- AI、Orchestration、Websites、Database、Firewall、Settings、SystemSettings 等主入口已具备命名路由。

### 3.2 当前仍存在的字符串路由

| 路由 | 出现位置 | 当前处理 | 结论 |
| --- | --- | --- | --- |
| /containers | app_router + server_detail | 页面跳转可用 | 保留，后续常量化 |
| /apps | app_router + server_detail | 页面跳转可用 | 保留，后续常量化 |
| /container-create | app_router | 页面跳转可用 | 保留，后续常量化 |
| /websites | server_detail | 页面跳转可用 | 保留，后续统一为 AppRoutes.websites |
| /databases | server_detail | 页面跳转可用 | 保留，后续统一为 AppRoutes.databases |
| /firewall | server_detail | 页面跳转可用 | 保留，后续统一为 AppRoutes.firewall |
| /terminal | server_detail | 页面跳转可用 | 保留，后续统一为 AppRoutes.terminal |
| /monitoring | server_detail | 页面跳转可用 | 保留，后续统一为 AppRoutes.monitoring |
| /backups | app_router | LegacyRedirectPage | 保留兼容，后续评估删除 |
| /help | app_router | LegacyRedirectPage | 保留兼容，后续评估删除 |

## 4. 清理动作记录（S2-6）

| 动作 | 结果 |
| --- | --- |
| 统一路由盘点 | 已完成 |
| 字符串路由映射归档 | 已完成 |
| LegacyRedirect 路由登记 | 已完成 |
| 代码重构执行 | 本轮不执行（按决策冻结） |

## 5. Phase 3 建议任务

- 统一将字符串路由迁移为 AppRoutes 常量。
- 对 LegacyRedirectPage 的 /backups 与 /help 给出去留结论。
- 为路由映射补充 smoke 测试，防止重构回归。
