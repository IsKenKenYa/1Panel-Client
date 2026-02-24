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

## 后续规划

- 站点管理全量能力接入（日志、跨域、防盗链、重定向、RealIP等）
- 证书管理页完善（列表、上传、签发、吊销、自动续期）
