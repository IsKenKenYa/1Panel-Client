# 网站模块索引

## 模块定位

Open1PanelApp 的网站模块负责站点生命周期管理、反向代理、SSL证书与OpenResty配置能力。

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

## 适配现状与UI链路

- 入口: `lib/features/websites/websites_page.dart` -> `lib/features/websites/website_detail_page.dart`，详情页以 Tab 组织（概览/配置/域名/SSL/重写/代理）。
- OpenResty 入口: 网站列表页右上角设置按钮跳转 `lib/features/openresty/openresty_page.dart`。
- 配置/域名/SSL 多以 JSON 或简单表单完成，缺少模块化子页面与分步流程。
- 关键能力缺口集中在证书申请/上传/解析/列表、域名更新与解析校验、PHP 版本切换、OpenResty 模块管理与构建任务可视化。

## 重复代码检查

- `lib/features/websites/website_detail_page.dart` 与 `lib/features/openresty/openresty_page.dart` 存在 `_JsonEditTab` 重复。
- `lib/features/websites/website_detail_page.dart` 与 `lib/features/openresty/openresty_page.dart` 存在 `_ErrorSection` 重复。
- `lib/data/models/website_models.dart` 与 `lib/data/models/ssl_models.dart` 均定义 `WebsiteSSL`，字段不一致且语义重叠。

## API 实测备注 (2026-03-13)

- `POST /websites/search` 在列表为空时 `data.items` 可能为 `null`，解析需兼容空列表。
- 列表项包含 `primaryDomain/sitePath/sslExpireDate/sslStatus/runtimeType` 等字段，模型需兼容。

## 后续规划

- 站点管理全量能力接入（日志、跨域、防盗链、重定向、RealIP等）
- 证书管理页完善（列表、上传、签发、吊销、自动续期）
