# 网站管理模块严格审计报告

**审计日期**: 2026-03-20  
**审计口径**: 严格审计  
**最终结论**: `不完整适配`

## 审计范围

本次审计覆盖以下与网站管理直接相关的链路：

- 网站主模块
- 网站配置管理
- 网站域名管理
- 网站 SSL 证书
- OpenResty 管理

本次审计使用的输入来源：

- 工作流: `docs/模块适配专属工作流.md`
- OpenAPI: `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
- 移动端实现: `lib/features/websites/`、`lib/features/openresty/`、`lib/api/v2/`
- 测试实现: `test/api_client/website*_test.dart`、`test/api_client/openresty_api_client_test.dart`
- 上游源码子模块: `docs/OpenSource/1Panel`，当前检出版本 `c7f185a184b27efa5b605d306b66bbe50aa4d627`

子模块补充说明：

- `git submodule update --init --recursive docs/OpenSource/1Panel` 已成功检出主仓库。
- 递归拉取在 `frontend/src/xpack-ee` 处失败，原因是上游子模块声明缺失。
- 本次审计所需的 `frontend/src/views`、`frontend/src/api/modules`、`agent/app/api/v2` 已完整可读，不影响网站管理主链路对照。

## 正式结论

| 子链路 | 结论 | 依据 |
|--------|------|------|
| 网站管理总体 | `不完整适配` | 工作流要求的 `API / Model / Service / Provider / UI / Test / 国际化 / 文档` 未形成闭环，且网站相关 OpenAPI 仅部分接入 |
| 网站主模块 | `不完整适配` | 移动端仅覆盖列表、详情、启停删等基础操作，缺少创建、更新、默认站点、批量操作、分组、检查、选项等核心能力 |
| 网站配置管理 | `不完整适配` | 上游存在大量结构化配置页，移动端仍以原始文本和 scope 参数编辑为主 |
| 网站域名管理 | `不完整适配` | 已支持列表、添加、删除、SSL 开关，但缺少更新、批量录入、格式校验、解析提示等流程 |
| 网站 SSL 证书 | `不完整适配` | 已有基础证书管理 UI，但缺少 CA、ACME、DNS 账户、详情、日志、筛选排序等上游能力 |
| OpenResty 管理 | `基本适配但缺验收` | `openresty_v2.dart` 与 OpenAPI 已对齐，但 UI 仍为 JSON/手工输入导向，未达到结构化与可回滚的交付标准 |

## API 覆盖审计

### 1. 客户端与 OpenAPI 对照

| 客户端 | 审计范围 | 对齐结果 | 结论 |
|--------|----------|----------|------|
| `lib/api/v2/website_v2.dart` | `/websites/*` | 对齐 `19 / 90` 个方法级接口 | 严重缺口 |
| `lib/api/v2/ssl_v2.dart` | `/websites/ssl/*` + `/core/settings/ssl/*` | 对齐 `11 / 11` 个网站 SSL 接口，`3 / 3` 个系统 SSL 接口 | 基本完整 |
| `lib/api/v2/openresty_v2.dart` | `/openresty/*` | 对齐 `10 / 10` | 完整 |
| 合并口径（`website_v2` + `ssl_v2`） | `/websites/*` | 对齐 `30 / 90` | 仍不完整 |

### 2. `WebsiteV2Api` 明确缺失的能力簇

当前未在移动端 API 层接入的主要网站能力包括：

- 网站创建、更新、预检查、选项获取
- 批量分组、批量 HTTPS、批量操作
- 默认站点、默认 HTML、网站备注外的配置更新
- DNS 账户管理、ACME 账户管理、CA 证书管理
- 基础认证、路径认证
- 目录配置、目录权限、网站资源、网站数据库切换
- 防盗链、跨站访问、CORS、Real IP、代理缓存
- 负载均衡、重定向文件、代理文件、自定义伪静态
- 网站日志操作、Composer 执行、流配置

### 3. `SSLV2Api` 的规范漂移

以下方法存在于移动端 `ssl_v2.dart`，但未出现在当前 OpenAPI，也未在上游 `frontend/src/api/modules/website.ts` 与 `agent/app/api/v2/website_ssl.go` 中找到对应公开接口：

- `/websites/ssl/options`
- `/websites/ssl/validate`
- `/websites/ssl/auto-renew`
- `/websites/ssl/application/:id/status`

结论：

- 这 4 个接口应标记为 `实现与规范漂移`
- 在未确认上游真实后端可用前，不应将其视为正式已适配能力

## UI 链路对照审计

### 上游 1Panel 页面结构证据

上游前端关键入口：

- `docs/OpenSource/1Panel/frontend/src/routers/modules/website.ts`
- `docs/OpenSource/1Panel/frontend/src/views/website/website/index.vue`
- `docs/OpenSource/1Panel/frontend/src/views/website/website/config/index.vue`
- `docs/OpenSource/1Panel/frontend/src/views/website/ssl/index.vue`
- `docs/OpenSource/1Panel/frontend/src/views/website/website/nginx/index.vue`

上游页面颗粒度统计：

- `frontend/src/views/website/ssl` 下 `14` 个 `index.vue`
- `frontend/src/views/website/website/nginx` 下 `9` 个 `index.vue`
- `frontend/src/views/website/website/config` 下 `35` 个 `index.vue`
- `frontend/src/views/website/website/config/basic` 下 `30` 个 `index.vue`
- `frontend/src/views/website/runtime` 下 `38` 个 `index.vue`

### 移动端现状

当前移动端网站相关页面仅有：

- `lib/features/websites/websites_page.dart`
- `lib/features/websites/website_detail_page.dart`
- `lib/features/websites/website_config_page.dart`
- `lib/features/websites/website_domain_page.dart`
- `lib/features/websites/website_ssl_page.dart`
- `lib/features/openresty/openresty_page.dart`

### 子链路能力矩阵

| 子链路 | 上游能力 | 移动端现状 | 结论 |
|--------|----------|------------|------|
| 网站列表 | 创建、分组、默认站点、默认 HTML、搜索筛选、批量操作、收藏、到期时间编辑 | 列表、刷新、进入详情、启停删、跳转 OpenResty | 明显不完整 |
| 网站详情 | 基础状态、配置入口、资源、日志、基础配置、Nginx、批量与扩展操作 | 概览卡、信息卡、快捷操作、配置/域名/SSL/OpenResty 入口 | 仅保留一级导航，未展开上游能力 |
| 配置管理 | `basic/log/resource` 三大主分区，`basic` 下 30 个子页面 | Nginx 文件编辑、scope 参数编辑、手填 runtime ID 切 PHP | 与上游结构差距大 |
| 域名管理 | 独立域名配置页、创建页、批量格式提示、校验与默认域名流程 | 域名列表、添加、删除、SSL 开关 | 基础可用，但缺少更新与校验 |
| SSL 管理 | 列表、详情、申请、上传、CA、ACME、DNS 账户、日志、删除、筛选排序 | 列表、创建、上传、申请、解析、更新、删除、下载、HTTPS 设置 | 有主体，但未覆盖账户和 CA 体系 |
| OpenResty 管理 | 状态、配置资源、性能、日志、模块、其他设置 | 状态、HTTPS、模块、配置、构建、scope，且大量使用 JSON 编辑 | API 对齐，体验与结构未对齐 |

### 配置管理的关键缺口

对照上游 `frontend/src/views/website/website/config/basic`，移动端缺少下列结构化页面或等价流程：

- 域名配置与批量录入
- HTTPS 基础配置
- PHP 配置与 Composer
- 网站目录、默认文档、资源限制
- 基础认证、路径认证
- 反向代理、代理缓存、代理文件
- 伪静态与自定义伪静态
- 重定向与重定向文件
- 负载均衡与负载均衡文件
- 防盗链、CORS、Real IP、流配置、其他设置

### SSL 管理的关键缺口

移动端已具备基础证书操作，但仍缺少：

- CA 证书管理
- ACME 账户管理
- DNS 账户管理
- 证书详情页
- 证书申请日志与错误追踪入口
- 搜索、排序、批量删除
- 与上游一致的状态/消息呈现方式

### OpenResty 管理的关键缺口

虽然 OpenResty API 已全量接入，但移动端缺少：

- 配置资源页
- 性能调整页
- 容器日志页
- “其他”设置页
- 模块管理的结构化操作界面
- HTTPS 与 scope 的参数校验、风险提示、差异预览、回滚入口

## 工作流闭环审计

### 1. 分层架构

工作流要求的建议路径为：

- `lib/api/v2/{模块}_v2.dart`
- `lib/data/models/{模块}_models.dart`
- `lib/features/{模块}/{模块}_service.dart`
- `lib/features/{模块}/{模块}_provider.dart`
- `lib/features/{模块}/{模块}_page.dart`

当前网站相关实现情况：

| 层级 | 现状 |
|------|------|
| API | 已有 |
| Model | 已有 |
| Service | 缺失 |
| Provider | 部分已有 |
| UI Page | 已有 |

审计结论：

- `lib/features/websites/` 与 `lib/features/openresty/` 当前不存在对应 `service.dart`
- 现状为 `Provider 直调 API`，未满足工作流推荐分层

### 2. 模型层

模型层现状：

- `website_models.dart` 定义了大量网站相关模型，但其中相当一部分未在当前 UI 或 API 层接入
- `WebsiteSSL` 当前仅在 `lib/data/models/ssl_models.dart` 中定义

审计结论：

- 当前不存在运行时代码中的 `WebsiteSSL` 双重定义
- 旧文档中“`website_models.dart` 与 `ssl_models.dart` 重复定义 `WebsiteSSL`”的备注已经过期，应视为 `文档未更新`

### 3. 测试链路

当前仅存在 API 客户端测试文件：

- `test/api_client/website_api_client_test.dart`
- `test/api_client/website_config_api_client_test.dart`
- `test/api_client/website_domain_api_client_test.dart`
- `test/api_client/website_ssl_api_client_test.dart`
- `test/api_client/openresty_api_client_test.dart`

当前缺失或阻塞项：

- 未发现网站/OpenResty 相关 widget 测试
- 未发现 service 层单元测试
- `.env` 文件不存在，无法提供真实服务器凭据
- 当前环境 `flutter` 命令不可用，无法执行工作流要求的 `flutter test ... --no-pub`

审计结论：

- 测试链路为 `部分存在但未闭环`
- 所有“已适配”判断都不能上调为“完整适配”

### 4. 国际化

国际化现状：

- `lib/l10n/app_en.arb` 与 `lib/l10n/app_zh.arb` 已覆盖当前已实现网站页面的大部分文案
- 现有页面中的主要 key 均可在 ARB 文件中找到对应项

审计结论：

- 已实现页面的国际化基本完整
- 缺失能力没有对应文案，根因是 UI 本身尚未实现，而非已实现页面遗漏国际化

### 5. 文档

文档现状：

- 模块索引、架构、计划、FAQ 已存在
- 多份文档仍停留在阶段性规划口径
- 个别结论已落后于当前代码，例如 SSL 模型重复定义备注

审计结论：

- 文档体系存在，但需要和当前代码重新对齐
- 本次严格审计报告应作为后续修正网站模块文档的基线

## 本次审计后的正式判断

只有同时满足以下条件时，网站管理模块才能从 `不完整适配` 上调：

1. 网站主链路缺失的关键 OpenAPI 能力完成接入或明确降 scope
2. `service.dart` 分层与测试链路完成补齐
3. `.env` 配置齐备且 `flutter test` 可执行
4. 上游源码对照后的差异项全部归因完成
5. `ssl_v2.dart` 中的 4 个漂移接口完成核真、移除或降级标注

在这些条件完成前，本模块的正式结论维持：

- 网站管理总体: `不完整适配`
- OpenResty 子链路: `基本适配但缺验收`
- `SSLV2Api` 额外接口: `实现与规范漂移`

## 后续实施优先级

建议按以下顺序推进修复：

1. 优先补齐 `WebsiteV2Api` 的核心网站能力缺口
2. 为 `websites` 与 `openresty` 引入 service 层，消除 provider 直连 API
3. 对 `ssl_v2.dart` 的 4 个漂移接口做核真或下线
4. 为网站与 OpenResty 页面补齐 widget 测试、模型测试与 API 实测
5. 将配置管理与 OpenResty 页面从 JSON 编辑器逐步替换为结构化表单
