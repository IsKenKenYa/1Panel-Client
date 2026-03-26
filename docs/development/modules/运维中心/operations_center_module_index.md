# 运维中心模块索引

## 模块定位

运维中心是 Phase 1 的统一入口，不扩张底部主导航，所有第一阶段新增能力统一从 `ServerDetailPage -> OperationsCenterPage` 进入。

## Week 1 已落地内容

- 新增 `AppRoutes.operations`
- 在 `ServerDetailPage` 增加运维中心入口
- 新建 `OperationsCenterPage`
- 按以下三组展示阶段一能力骨架：
  - Automation
  - Runtime & Delivery
  - System Control
- 提前注册阶段一全部建议路由，占位页统一说明对应交付周次

## 路由骨架

| 路由 | 计划周次 | 说明 |
| --- | --- | --- |
| `/operations` | Week 1 | 运维中心主页 |
| `/commands` `/commands/form` | Week 2 | 命令库主链路 |
| `/hosts-assets` `/hosts-assets/form` | Week 2 | 主机资产主链路 |
| `/ssh` `/ssh/logs` `/ssh/sessions` | Week 3 | SSH 主链路 |
| `/processes` `/processes/detail` | Week 3 | 进程主链路 |
| `/cronjobs` `/cronjobs/records` | Week 4 | 计划任务列表主链路 |
| `/scripts` | Week 4 | 脚本库主链路 |
| `/cronjobs/form` | Week 5 | 计划任务表单 |
| `/backups` `/backups/accounts/form` | Week 5 | 备份账户 |
| `/backups/records` `/backups/recover` | Week 6 | 备份记录与恢复 |
| `/logs` `/logs/system` `/logs/task/detail` | Week 6 | 日志中心 |
| `/runtimes` `/runtimes/detail` `/runtimes/form` | Week 7 | Runtime 通用链路 |
| `/runtimes/php/extensions` `/runtimes/php/config` `/runtimes/node/modules` `/runtimes/node/scripts` | Week 8 | PHP/Node 深化 |

## 共享组件

Week 1 统一沉淀以下共享 UI 基座：

- `async_state_page_body_widget.dart`
- `module_empty_state_widget.dart`
- `module_error_state_widget.dart`
- `confirm_action_sheet_widget.dart`
- `server_operation_entry_card_widget.dart`

## 评审关注点

- 是否严格保持 `ServerDetailPage -> OperationsCenterPage` 单入口
- 占位路由是否覆盖阶段一计划范围，且未提前实现 Week 2+
- 运维中心是否遵循手机优先、平板增强的信息架构

---

**文档版本**: 1.1
**最后更新**: 2026-03-25
