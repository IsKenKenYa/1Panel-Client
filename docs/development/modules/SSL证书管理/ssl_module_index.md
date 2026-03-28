# SSL证书管理模块索引

## 模块定位

SSL证书管理模块是Open1PanelApp的**安全通信模块**，当前主要负责**系统级面板 SSL** 的查看、导入、更新与下载，并承接网站证书体系的共享模型与文档说明。

## S2-0 基线（2026-03-26）

- 当前状态：
  `panel ssl` 目前只以 `settings/panel_ssl` 薄页存在，尚未形成独立模块目录与独立 feature 心智。
- 阶段 2 hard scope：
  `info / update / download`
- API 基线：
  `check_module_api_updates.py system_ssl` 当前结果为 `unchanged`
- 文档缺口：
  当前没有独立的 `panel ssl` 模块索引/架构/计划目录，只能从系统 SSL 文档侧向映射。

### 核心职责

1. **证书申请** - Let's Encrypt自动申请、手动申请
2. **证书管理** - 列表展示、详情查看、更新删除
3. **证书部署** - 网站关联、自动部署
4. **证书续期** - 自动续期、手动续期
5. **证书验证** - DNS验证、HTTP验证

## 子模块结构

```
SSL证书管理/
├── 证书列表
│   ├── 列表展示
│   ├── 搜索过滤
│   └── 状态监控
├── 证书申请
│   ├── Let's Encrypt申请
│   ├── 自定义证书上传
│   └── DNS/HTTP验证
├── 证书详情
│   ├── 基本信息
│   ├── 域名列表
│   └── 关联网站
├── 证书操作
│   ├── 更新证书
│   ├── 续期证书
│   ├── 下载证书
│   └── 删除证书
├── ACME账户
│   ├── 账户管理
│   └── 服务器配置
└── DNS账户
    ├── DNS服务商配置
    └── API密钥管理
```

## API端点映射

| API端点 | 方法 | 功能描述 | 实现状态 |
|---------|------|---------|---------|
| `/websites/ssl` | POST | 创建SSL证书 | ✅ 已实现 |
| `/websites/ssl/{id}` | GET | 获取证书详情 | ✅ 已实现 |
| `/websites/ssl/del` | POST | 删除证书 | ✅ 已实现 |
| `/websites/ssl/download` | POST | 下载证书 | ✅ 已实现 |
| `/websites/ssl/obtain` | POST | 申请证书 | ✅ 已实现 |
| `/websites/ssl/resolve` | POST | 解析证书 | ✅ 已实现 |
| `/websites/ssl/search` | POST | 搜索证书 | ✅ 已实现 |
| `/websites/ssl/update` | POST | 更新证书 | ✅ 已实现 |
| `/websites/ssl/upload` | POST | 上传证书 | ✅ 已实现 |
| `/websites/ssl/website/{id}` | GET | 获取网站证书 | ✅ 已实现 |
| `/websites/ssl/options` | GET | 获取SSL选项 | ⚠️ 不在当前 Swagger，视为漂移接口 |
| `/websites/ssl/validate` | POST | 验证证书配置 | ⚠️ 不在当前 Swagger，视为漂移接口 |
| `/websites/ssl/auto-renew` | POST | 自动续期 | ⚠️ 不在当前 Swagger，视为漂移接口 |
| `/core/settings/ssl/download` | POST | 下载系统证书 | ✅ 已实现 |
| `/core/settings/ssl/info` | GET | 获取系统证书 | ✅ 已实现 |
| `/core/settings/ssl/update` | POST | 更新系统证书 | ✅ 已实现 |

## 现有实现

### API客户端
- [ssl_v2.dart](../../../lib/api/v2/ssl_v2.dart) - 17个API方法

### Flutter 页面
- [panel_ssl_page.dart](../../../lib/features/settings/panel_ssl/pages/panel_ssl_page.dart) - 系统级面板 SSL 管理页
- [ssl_settings_page.dart](../../../lib/features/settings/ssl_settings_page.dart) - 兼容入口薄包装

## 严格审计状态 (2026-03-20)

- V2 单一文档源已切换到 `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
- 系统 SSL 页面已经从通用设置中拆成独立 `PanelSslService / PanelSslProvider / PanelSslPage`
- 网站证书中心与系统 SSL 已在 Flutter 端分流，不再混在同一页面心智模型中
- `/websites/ssl/options`、`/websites/ssl/validate`、`/websites/ssl/auto-renew` 不在当前 Swagger，后续不作为正式能力面继续扩展

### 数据模型
- [ssl_models.dart](../../../lib/data/models/ssl_models.dart) - 完整模型定义
  - `SSLCertificateType` - 证书类型枚举
  - `SSLCertificateStatus` - 证书状态枚举
  - `SSLCertificateInfo` - 证书信息
  - `SSLCertificateCreate` - 创建请求
  - `SSLCertificateUpdate` - 更新请求
  - `SSLCertificateSearch` - 搜索请求
  - `WebsiteSSL` - 网站SSL模型
  - `ACMEAccount` - ACME账户模型
  - `DNSAccount` - DNS账户模型

## 支持的证书类型

| 类型 | 标识 | 说明 |
|------|------|------|
| **Let's Encrypt** | lets-encrypt | 免费自动证书 |
| **自签名** | self-signed | 内部测试用 |
| **自定义** | custom | 第三方证书上传 |

## 证书状态

| 状态 | 标识 | 说明 |
|------|------|------|
| **有效** | valid | 证书正常使用中 |
| **即将过期** | expiring | 30天内过期 |
| **已过期** | expired | 证书已过期 |
| **无效** | invalid | 证书配置错误 |
| **待验证** | pending | 等待域名验证 |

## 后续规划

### 短期目标（1-2周）
1. 创建SSL证书列表页面
2. 实现证书详情页面
3. 添加证书申请表单
4. 添加单元测试覆盖

### 中期目标（1个月）
1. 完善Let's Encrypt申请流程
2. 实现DNS验证功能
3. 添加证书到期提醒
4. 实现批量续期功能

### 长期目标
1. 支持通配符证书
2. 支持多域名证书
3. 证书使用分析
4. 证书链管理

## 质量指标

| 指标 | 当前状态 | 目标 |
|------|---------|------|
| API实现 | 100% | 100% |
| 数据模型 | 100% | 100% |
| 单元测试 | 0% | ≥80% |
| 文档覆盖 | 0% | 100% |
| UI实现 | 0% | 100% |

---

**文档版本**: 1.0  
**最后更新**: 2026-03-20  
**维护者**: Open1Panel开发团队
