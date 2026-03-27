# 认证管理模块索引

## 模块定位

认证管理模块是Open1PanelApp的P0核心模块，负责用户身份验证、会话管理、MFA双因素认证等功能，是系统安全的第一道防线。

## S2-0 基线（2026-03-26）

- 当前状态：
  登录主流程可用；截至 `2026-03-27`，`AuthProvider` 已收回 `api / session / token storage` 混合职责，改为依赖 `AuthService`。
- 阶段 2 hard scope：
  `session / token / storage / api` 分层与安全收口
- API 基线：
  `check_module_api_updates.py auth` 当前结果为 `unchanged`

## 子模块结构

基于docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json，Auth标签共8个端点：

| 子模块 | 端点数 | API方法 | 说明 |
|--------|--------|---------|------|
| **用户登录** | 2 | GET/POST | 验证码获取、用户登录 |
| **MFA认证** | 1 | POST | 双因素认证 |
| **会话管理** | 1 | POST | 用户登出 |
| **系统设置** | 3 | GET | 登录设置、演示模式、安全状态 |
| **语言设置** | 1 | GET | 系统语言 |

### 端点详情

#### 用户登录 (2端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/core/auth/captcha` | GET | 获取验证码图片 |
| `/core/auth/login` | POST | 用户登录认证 |

#### MFA认证 (1端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/core/auth/mfalogin` | POST | MFA双因素认证登录 |

#### 会话管理 (1端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/core/auth/logout` | POST | 用户登出 |

#### 系统设置 (3端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/core/auth/setting` | GET | 获取登录设置 |
| `/core/auth/demo` | GET | 检查演示模式 |
| `/core/auth/issafety` | GET | 获取安全状态 |

#### 语言设置 (1端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/core/auth/language` | GET | 获取系统语言 |

## 后续规划方向

### 短期目标
- ✅ 完善登录页面UI (MDUI3规范)
- ✅ 实现MFA认证流程
- ✅ 添加验证码支持
- ✅ 完成 Provider/Service 单元测试
- ✅ 国际化支持 (17条字符串)

### 中期目标
- ⏳ 生物识别登录支持
- ⏳ 记住登录状态增强
- ⏳ 多服务器切换
- ✅ Token加密存储

### 长期目标
- SSO单点登录
- OAuth2.0集成
- 权限细粒度控制

## 已实现文件

| 文件 | 路径 | 说明 |
|------|------|------|
| 数据模型 | `lib/data/models/auth_models.dart` | 7个认证模型类 |
| Repository | `lib/features/auth/auth_repository.dart` | Auth API 访问边界 |
| Service | `lib/features/auth/auth_service.dart` | 认证业务与会话编排 |
| Session Store | `lib/features/auth/auth_session_store.dart` | 基于 `flutter_secure_storage` 的会话存储 |
| 状态管理 | `lib/features/auth/auth_provider.dart` | Provider状态管理（仅保留 UI 状态） |
| 登录页面 | `lib/features/auth/login_page.dart` | MDUI3登录UI |
| 单元测试 | `test/features/auth/auth_provider_test.dart` | Provider与模型测试 |
| 单元测试 | `test/features/auth/auth_service_test.dart` | Service与会话存储测试 |
| 国际化 | `lib/l10n/app_*.arb` | 17条认证字符串 |

## 与其他模块的关系

- **系统设置**: 获取登录配置
- **主机管理**: 多服务器认证
- **日志管理**: 登录日志记录

## 相关文档

- [API端点详细分析](auth_api_analysis.md)
- [架构设计](auth_module_architecture.md)
- [开发计划](auth_plan.md)
- [FAQ](auth_faq.md)

---

**文档版本**: 2.1
**最后更新**: 2026-03-27
**数据来源**: docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json
