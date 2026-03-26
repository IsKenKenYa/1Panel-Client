# 网站SSL证书模块索引

## 模块定位

网站SSL证书模块是Open1PanelApp的P1高价值扩展模块，提供网站级SSL证书的申请、更新、上传与绑定能力，是网站安全运行的重要保障。

## S2-0 基线（2026-03-26）

- 当前状态：
  当前已具备基础证书流，但 `CA / ACME / DNS account / detail / log / filter` 仍缺失，不能视为完整网站证书体系。
- 阶段 2 hard scope：
  `certificate center + website binding + HTTPS strategy`
- 明确不做：
  `CA / ACME / DNS account`
- API 基线：
  `check_module_api_updates.py website_ssl` 当前结果为 `unchanged`
- 命名风险：
  当前目录内的 `ssl_api_analysis.json` 与 `SSL证书管理` 下的 `ssl_api_analysis.*` 命名存在重叠。

## 子模块结构

| 子模块 | 端点数 | API客户端 | 说明 |
|--------|--------|-----------|------|
| **网站SSL证书** | 11 | ssl_v2.dart | 证书申请、更新、上传、下载、解析 |

## UI链路分析

- 入口: `lib/features/websites/websites_page.dart` -> `lib/features/websites/website_detail_page.dart` -> SSL 管理页。
- 当前已支持证书列表、创建、上传、申请、解析、更新、删除、下载以及网站 HTTPS 配置编辑。
- 仍缺少 CA、ACME、DNS 账户、详情与日志等上游配套流程。

## 严格审计状态 (2026-03-20)

- 结论: `不完整适配`
- 当前移动端比旧索引描述更完整，实际上已经具备:
  - 证书列表
  - 创建、上传、申请、解析、更新、删除、下载
  - 网站 HTTPS 配置编辑
  - 站点 SSL 页与网站证书中心的分离骨架
- 但与上游对照后仍缺少:
  - CA 证书管理
  - ACME 账户管理
  - DNS 账户管理
  - 证书详情页与日志追踪
  - 与上游一致的筛选、排序、批量操作
- 详情见: `../网站管理-OpenResty/website_strict_audit_2026-03-20.md`

## 待改进项

- 增加证书列表与详情页面，支持筛选与状态提示。
- 补齐证书申请、上传、解析、更新与删除流程。
- HTTPS 配置建议拆分为结构化表单，避免直接 JSON 编辑。

## 重复代码检查

- 当前代码中 `WebsiteSSL` 已统一来源于 `lib/data/models/ssl_models.dart`。
- 旧版关于 `website_models.dart` 与 `ssl_models.dart` 双重定义 `WebsiteSSL` 的备注已过期，应视为文档未及时更新。

## 后续规划方向

### 短期目标
- 完善网站证书信息展示
- 实现证书申请与更新流程

### 中期目标
- 实现证书自动续期
- 添加证书监控和告警

### 长期目标
- 支持多证书提供商
- 提供证书安全评估

## 与其他模块的关系

- **网站管理**: 证书与网站关联
- **监控管理**: 证书到期告警
- **日志管理**: 证书操作日志
- **系统设置**: 全局SSL配置

---

**文档版本**: 1.0
**最后更新**: 2026-03-20
