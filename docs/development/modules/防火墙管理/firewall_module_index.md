# 防火墙管理模块索引

## 模块定位
Open1PanelApp 的防火墙管理模块负责防火墙规则配置、IP白名单管理、端口管理，提供移动端友好的防火墙管理体验。

## S2-0 基线（2026-03-26）

- 当前状态：
  已具备 `route + repository + service + provider + page` 基础闭环，主链路覆盖 `status / rules / ip / ports / rule form`。
- 阶段 2 hard scope：
  `status / rules / ip / ports`
- API 基线：
  `check_module_api_updates.py firewall` 当前结果为 `unchanged`
- 当前基线缺口：
  结构化筛选、批量操作与更细的高级链路仍待补齐。

## S2-1 实施进展（2026-03-26）

- 已落地：
  `firewall_v2.dart` 第一轮对齐到 `/hosts/firewall/*`
  `FirewallRepository`
  `FirewallService`
  `FirewallStatusProvider / FirewallRulesProvider / FirewallIpProvider / FirewallPortsProvider`
  `FirewallPage` 与 `Status / Rules / IP / Ports` 四段页面
- 已补测试：
  `firewall_api_client_test.dart`
  `firewall_status_provider_test.dart`
  `firewall_rule_list_provider_test.dart`
  `firewall_rule_form_provider_test.dart`
  `firewall_page_test.dart`
  `firewall_s2_integration_test.dart`
- 本轮收口：
  `FirewallPage` 已切到 server-aware 入口模式；
  服务器切换场景已有 widget test 覆盖；
  危险操作已补二次确认；
  规则表单已补最小必填校验；
  `FirewallRepository` 已收口到 `FirewallV2Api`；
  `rules / ip / ports` 三个 tab 已补搜索、strategy 筛选、选择模式、批量删除、批量 accept/drop。
- 当前仍未闭环：
  更细粒度的高级规则链路仍待继续收口。

## 子模块结构
- 架构设计: docs/development/modules/防火墙管理/firewall_module_architecture.md
- 开发计划: docs/development/modules/防火墙管理/firewall_plan.md
- FAQ: docs/development/modules/防火墙管理/firewall_faq.md
- API分析: docs/development/modules/防火墙管理/firewall_api_analysis.md

## 后续规划
- 更细粒度的高级规则链路
- 高级链/日志类能力
