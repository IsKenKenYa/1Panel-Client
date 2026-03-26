# 网站模块索引

## 模块定位

Open1PanelApp 的网站模块负责站点生命周期管理、反向代理、SSL证书与OpenResty配置能力。

## S2-0 基线（2026-03-26）

- 当前状态：
  网站家族已具备 `pages / providers / services` 骨架，但严格审计结论仍是 `不完整适配`，后续实现必须以严格审计报告为准，而不是以“已有页面”判断完成度。
- 阶段 2 hard scope：
  `website lifecycle / detail / default site / group / remark`
  `website_domain CRUD + validation`
  `website_config structured config center entry`
  `website ssl certificate center + website binding + HTTPS strategy`
  `openresty status / https / modules / config / build`
- API 基线：
  `website / openresty / domains / website_ssl / system_ssl` 当前脚本检查均为 `unchanged`
- 边界：
  `proxy cache / load balance / real ip / stream / CA / ACME / DNS account` 不在当前阶段 2 hard scope。

## 子模块结构

- 网站管理-OpenResty
  - 架构设计: [openresty_module_architecture.md](openresty_module_architecture.md)
  - 页面设计: [openresty_pages.md](openresty_pages.md)
  - API设计: [openresty_api.md](openresty_api.md)
  - 数据设计: [openresty_data.md](openresty_data.md)
  - 开发计划: [openresty_plan.md](openresty_plan.md)
  - 运维手册: [openresty_ops.md](openresty_ops.md)
  - 用户手册: [openresty_user_manual.md](openresty_user_manual.md)
  - FAQ: [openresty_faq.md](openresty_faq.md)
  - 严格审计: [website_strict_audit_2026-03-20.md](website_strict_audit_2026-03-20.md)

- 网站配置管理
  - 索引: [website_config_module_index.md](../网站配置管理/website_config_module_index.md)
  - 架构: [website_config_module_architecture.md](../网站配置管理/website_config_module_architecture.md)
  - 计划: [website_config_plan.md](../网站配置管理/website_config_plan.md)
  - FAQ: [website_config_faq.md](../网站配置管理/website_config_faq.md)

- 网站域名管理
  - 索引: [website_domain_module_index.md](../网站域名管理/website_domain_module_index.md)
  - 架构: [website_domain_module_architecture.md](../网站域名管理/website_domain_module_architecture.md)
  - 计划: [website_domain_plan.md](../网站域名管理/website_domain_plan.md)
  - FAQ: [website_domain_faq.md](../网站域名管理/website_domain_faq.md)

- 网站SSL证书
  - 索引: [website_ssl_module_index.md](../网站SSL证书/website_ssl_module_index.md)
  - 架构: [website_ssl_module_architecture.md](../网站SSL证书/website_ssl_module_architecture.md)
  - 计划: [website_ssl_plan.md](../网站SSL证书/website_ssl_plan.md)
  - FAQ: [website_ssl_faq.md](../网站SSL证书/website_ssl_faq.md)

## 严格审计结论 (2026-03-20)

- 总体结论: `不完整适配`
- 上游对照基线: `docs/OpenSource/1Panel` 已检出至 `c7f185a184b27efa5b605d306b66bbe50aa4d627`
- 审计报告: [website_strict_audit_2026-03-20.md](website_strict_audit_2026-03-20.md)
- 关键结论:
  - `WebsiteV2Api` 仅覆盖网站主链路的少量接口，网站总体仍有大面积能力缺口
  - `SSLV2Api` 与 `OpenRestyV2Api` 覆盖度较高，但分别存在规范漂移和结构化 UI 缺口
  - 当前已落地 `services / providers / pages / widgets` 骨架，但测试链路仍未闭环

## 本轮实现进展

- 网站模块已开始向 `services / providers / pages / widgets` 结构收敛
- 站点工作台、配置中心、域名管理、站点 SSL、网站证书中心、OpenResty 中心、系统 SSL 兼容入口均已落地 MVP 页面
- 现有原始配置/JSON 编辑能力仍保留为高级入口，后续继续逐步结构化

## 适配现状与UI链路

- 入口: `lib/features/websites/websites_page.dart` -> `lib/features/websites/website_detail_page.dart`，详情页当前以卡片入口跳转到配置/域名/SSL/OpenResty 子页面。
- OpenResty 入口: 网站列表页右上角设置按钮跳转 `lib/features/openresty/openresty_page.dart`。
- 配置/域名/SSL 多以 JSON 或简单表单完成，缺少模块化子页面与分步流程。
- 关键能力缺口集中在网站创建与批量操作、结构化配置页、域名更新与解析校验、CA/ACME/DNS 账户管理、OpenResty 性能/日志/其他设置。

## 重复代码检查

- `lib/features/websites/website_detail_page.dart` 与 `lib/features/openresty/openresty_page.dart` 存在 `_JsonEditTab` 重复。
- `lib/features/websites/website_detail_page.dart` 与 `lib/features/openresty/openresty_page.dart` 存在 `_ErrorSection` 重复。
- 当前代码中 `WebsiteSSL` 已统一来源于 `lib/data/models/ssl_models.dart`，旧版双重定义备注已过期。

## API 实测备注 (2026-03-13)

- `POST /websites/search` 在列表为空时 `data.items` 可能为 `null`，解析需兼容空列表。
- 列表项包含 `primaryDomain/sitePath/sslExpireDate/sslStatus/runtimeType` 等字段，模型需兼容。

## 后续规划

- 站点管理全量能力接入（日志、跨域、防盗链、重定向、RealIP等）
- 证书管理页完善（列表、上传、签发、吊销、自动续期）
