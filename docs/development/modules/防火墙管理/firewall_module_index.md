# 防火墙管理模块索引

## 模块定位
Open1PanelApp 的防火墙管理模块负责防火墙规则配置、IP白名单管理、端口管理，提供移动端友好的防火墙管理体验。

## S2-0 基线（2026-03-26）

- 当前状态：
  仅有 `firewall_v2.dart + firewall_models.dart + FirewallPage`，且页面仍直接调用 API，未形成 `repository / service / provider / page` 闭环。
- 阶段 2 hard scope：
  `status / rules / ip / ports`
- API 基线：
  `check_module_api_updates.py firewall` 当前结果为 `unchanged`
- 文档缺口：
  索引引用的 `firewall_pages.md / firewall_api.md / firewall_data.md / firewall_ops.md / firewall_user_manual.md` 当前不存在。

## 子模块结构
- 架构设计: docs/development/modules/防火墙管理/firewall_module_architecture.md
- 页面设计: docs/development/modules/防火墙管理/firewall_pages.md
- API设计: docs/development/modules/防火墙管理/firewall_api.md
- 数据设计: docs/development/modules/防火墙管理/firewall_data.md
- 开发计划: docs/development/modules/防火墙管理/firewall_plan.md
- 运维手册: docs/development/modules/防火墙管理/firewall_ops.md
- 用户手册: docs/development/modules/防火墙管理/firewall_user_manual.md
- FAQ: docs/development/modules/防火墙管理/firewall_faq.md

## 后续规划
- 防火墙规则模板
- 防火墙日志分析
- 自动封禁功能
- 防火墙规则导入导出
