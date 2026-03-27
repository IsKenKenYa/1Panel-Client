# 网站配置管理模块索引

## 模块定位

网站配置管理模块是Open1PanelApp的P1高价值扩展模块，提供网站服务器配置的管理能力，包括Nginx配置、PHP扩展管理等，是网站性能优化和功能扩展的重要模块。

## S2-0 基线（2026-03-26）

- 当前状态：
  当前仍以 `Nginx 原始文本编辑 + scope 参数编辑 + 手工 runtime ID` 为主，与上游结构化配置页差距较大。
- 阶段 2 hard scope：
  `structured config center entry`
- API 基线：
  `check_module_api_updates.py website` 当前结果为 `unchanged`
- 命名风险：
  当前目录下 API 分析文件命名为 `website_api_analysis.*`，与主网站模块目录下同名文件容易混淆。

## 子模块结构

| 子模块 | 端点数 | API客户端 | 说明 |
|--------|--------|-----------|------|
| **Nginx配置** | 4 | website_v2.dart | 网站配置拉取与更新 |
| **PHP版本** | 1 | website_v2.dart | PHP版本切换管理 |

## UI链路分析

- 入口: `lib/features/websites/websites_page.dart` -> `lib/features/websites/website_detail_page.dart` -> 配置管理页。
- 当前已形成配置中心首页，包含：
  - `Basic`
  - `Routing`
  - `Access`
  - `Advanced`
- `Advanced` 仍是原始 Nginx 编辑入口。
- `Basic` 已作为结构化入口页，展示 siteDir / runtime / database binding / https summary / remark。

## 严格审计状态 (2026-03-20)

- 结论: `不完整适配`
- 上游对照显示 `frontend/src/views/website/website/config/basic` 下已有 30 个结构化子页面。
- 当前移动端已新增 `WebsiteConfigCenterPage` 作为配置中心首页，并保留高级源码页。
- 当前已覆盖:
  - 配置中心导航骨架
  - `Basic` 结构化入口
  - Nginx 配置文件读取与保存
  - scope 参数加载与更新
  - 手工输入 runtime ID 的 PHP 版本切换
- 主要缺口:
  - 域名/HTTPS/PHP/默认文档/目录/认证/重写/代理/缓存/CORS/重定向/负载均衡/防盗链/Real IP/流配置等结构化页面均未接入
- 详情见: `../网站管理-OpenResty/website_strict_audit_2026-03-20.md`

## 待改进项

- 增加配置语法校验与保存前确认提示。
- 提供配置版本与备份管理入口。
- 补齐 PHP 版本切换 UI，并提示切换风险与重启影响。

## 重复代码检查

- 与 OpenResty/网站详情页共用 JSON 编辑器需求明显，当前 `_JsonEditTab` 重复实现。

## 后续规划方向

### 短期目标
- 完善Nginx配置管理
- 添加配置备份功能

### 中期目标
- 支持配置模板库
- 实现配置版本管理

### 长期目标
- 支持多服务器配置同步
- 实现配置自动优化
- 提供性能分析建议

## 与其他模块的关系

- **网站管理**: 网站配置关联
- **OpenResty管理**: 服务器配置联动
- **日志管理**: 配置变更日志
- **监控管理**: 配置性能监控

---

**文档版本**: 1.0
**最后更新**: 2026-03-20
