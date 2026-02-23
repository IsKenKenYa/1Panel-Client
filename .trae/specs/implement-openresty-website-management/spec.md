# 网站管理（OpenResty + 站点配置/域名/SSL）适配 Spec

## Why
当前分支需要完成「网站管理-OpenResty」相关模块适配，但代码侧主要停留在 API/Models 与网站列表页，缺少端到端 UI 链路、状态管理与测试验证，且 OpenResty API 客户端存在与 OpenAPI 不一致的问题。

## What Changes
- 修正 OpenResty API 客户端与 OpenAPI 端点方法不一致的问题（GET/POST 等）。
- 完成「网站管理」端到端 UI 链路：站点列表 → 站点详情（配置/域名/SSL/伪静态/反向代理）。
- 补齐站点相关功能的状态管理与服务层，统一错误处理与加载状态。
- 复用现有 API/Models（website_v2 / ssl_v2 / openresty_v2），在必要处补齐缺失能力与测试用例。
- UI 统一遵循 MDUI3，所有用户可见文本走国际化（l10n）。
- 测试范围仅覆盖：网站管理-OpenResty、网站配置管理、网站域名管理、网站SSL证书；API 集合以 `analyze_module_api.py` 从 OpenAPI 提取为准。

## Impact
- Affected specs: 网站管理-OpenResty、网站配置管理、网站域名管理、网站SSL证书
- Affected code:
  - OpenResty API/Models：`lib/api/v2/openresty_v2.dart`、`lib/data/models/openresty_models.dart`
  - Website API/Models：`lib/api/v2/website_v2.dart`、`lib/data/models/website_models.dart`
  - SSL API/Models：`lib/api/v2/ssl_v2.dart`、`lib/data/models/ssl_models.dart`
  - Websites UI：`lib/features/websites/*`（扩展站点详情、子功能页、Provider/Service）
  - 路由与导航：`lib/config/app_router.dart`
  - 测试：`test/api_client/*`（新增/补齐 openresty 与 website 子功能测试）
  - 辅助脚本：`docs/development/modules/analyze_module_api.py`

## ADDED Requirements

### Requirement: 网站管理入口与站点列表
系统 SHALL 提供网站管理入口并展示站点列表，支持刷新、启停、重启、删除等基础操作，并在操作后刷新列表状态。

#### Scenario: 列表加载成功
- **WHEN** 用户进入网站管理模块
- **THEN** 系统展示站点列表与加载状态
- **AND** 支持下拉刷新重新获取数据

#### Scenario: 启停/重启/删除成功
- **WHEN** 用户在列表对站点执行启停/重启/删除
- **THEN** 系统展示操作结果提示
- **AND** 列表数据刷新并反映最新状态

### Requirement: 站点详情（配置/域名/SSL/伪静态/反向代理）
系统 SHALL 提供站点详情页面，至少覆盖以下能力：站点配置查看与更新、域名管理、站点 SSL 查看与更新、伪静态规则查看与更新、反向代理查看与更新。

#### Scenario: 进入站点详情
- **WHEN** 用户从站点列表进入某站点详情
- **THEN** 系统展示站点信息与功能分区（例如分段控件/Tab）
- **AND** 每个分区均具备独立的加载/错误/重试状态

### Requirement: 域名管理（website_domain）
系统 SHALL 支持在站点详情中查看域名列表、添加域名、删除域名，并在成功后同步刷新。

#### Scenario: 添加域名成功
- **WHEN** 用户输入合法域名并提交添加
- **THEN** 域名出现在域名列表中

#### Scenario: 删除域名成功
- **WHEN** 用户确认删除某域名
- **THEN** 该域名从列表移除

### Requirement: 站点 SSL（website_ssl）
系统 SHALL 支持在站点详情中查看与更新站点 SSL 配置（开启/关闭、证书选择或上传、删除绑定），并保证与后端返回结构兼容。

#### Scenario: 查看站点 SSL
- **WHEN** 用户进入站点 SSL 分区
- **THEN** 系统展示当前证书信息与 HTTPS 相关配置（若存在）

#### Scenario: 更新站点 SSL 成功
- **WHEN** 用户提交站点 SSL 更新（例如切换证书或更新配置）
- **THEN** 系统提示成功并刷新站点 SSL 信息

### Requirement: OpenResty 管理（openresty）
系统 SHALL 提供 OpenResty 管理相关能力入口与基础页面，用于查看状态/模块信息并执行更新类操作（以 OpenAPI/模块文档为准）。

#### Scenario: 查看 OpenResty 状态
- **WHEN** 用户进入 OpenResty 状态页
- **THEN** 系统展示状态信息并支持刷新

## MODIFIED Requirements

### Requirement: 测试仅覆盖目标模块
系统 SHALL 仅为以下模块新增/更新 API 测试：网站管理-OpenResty、网站配置管理、网站域名管理、网站SSL证书。

#### Scenario: 生成并依据模块 API 集合编写测试
- **WHEN** 需要开展某模块 API 测试
- **THEN** 先使用 `analyze_module_api.py` 从 OpenAPI 提取该模块 API 集合
- **AND** 测试仅覆盖该集合内端点，不扩散到其他模块

### Requirement: OpenResty API 客户端与 OpenAPI 一致
系统 SHALL 确保 OpenResty API 客户端的请求方法、路径与请求体格式与 OpenAPI 规范一致。

#### Scenario: build/file/scope/https 等端点调用
- **WHEN** 客户端调用 OpenResty 的构建/文件/作用域/HTTPS 更新类端点
- **THEN** 请求方法与请求体符合 OpenAPI
- **AND** 单元测试可验证请求成功并能解析响应

## REMOVED Requirements
无

