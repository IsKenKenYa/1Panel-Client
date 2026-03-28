# 认证管理模块开发计划

## 里程碑定义

### M1: 核心认证功能 ✅ 已完成

**目标**: 完成基础登录认证功能

| 任务 | 预计时间 | 负责人 | 状态 |
|------|---------|--------|------|
| 创建认证数据模型 | 2h | - | ✅ 已完成 |
| 实现TokenService | 2h | - | ✅ 已完成 (拆分为AuthSessionStore) |
| 实现AuthService | 3h | - | ✅ 已完成 (独立 `auth_service.dart`) |
| 实现AuthProvider | 4h | - | ✅ 已完成 |
| 创建LoginPage UI | 6h | - | ✅ 已完成 |

### M2: 安全增强功能 ✅ 已完成

**目标**: 完善安全相关功能

| 任务 | 预计时间 | 负责人 | 状态 |
|------|---------|--------|------|
| 实现MFA认证UI | 3h | - | ✅ 已完成 |
| 实现验证码功能 | 2h | - | ✅ 已完成 |
| 实现会话超时处理 | 2h | - | ⏳ 待实现 |
| 实现安全状态检测 | 2h | - | ✅ 已完成 |

### M3: 测试与优化 🔄 进行中

**目标**: 完成测试覆盖和性能优化

| 任务 | 预计时间 | 负责人 | 状态 |
|------|---------|--------|------|
| 单元测试编写 | 4h | - | ✅ 已完成 (Provider/Service) |
| 集成测试编写 | 3h | - | ⏳ 待实现 |
| 性能优化 | 2h | - | ⏳ 待实现 |
| 文档完善 | 2h | - | ✅ 已完成 |

## 任务分解

### API层任务

| 任务ID | 任务描述 | 优先级 | 依赖 | 状态 |
|--------|---------|--------|------|------|
| API-001 | 验证现有API方法完整性 | P0 | - | ✅ 已完成 |
| API-002 | 添加错误响应模型 | P0 | - | ✅ 已完成 |
| API-003 | 添加请求重试机制 | P1 | API-001 | ⏳ 待实现 |

### 数据层任务

| 任务ID | 任务描述 | 优先级 | 依赖 | 状态 |
|--------|---------|--------|------|------|
| DATA-001 | 创建LoginRequest模型 | P0 | - | ✅ 已完成 |
| DATA-002 | 创建LoginResponse模型 | P0 | - | ✅ 已完成 |
| DATA-003 | 创建CaptchaModel模型 | P0 | - | ✅ 已完成 |
| DATA-004 | 创建MFALoginRequest模型 | P1 | DATA-001 | ✅ 已完成 |
| DATA-005 | 创建AuthSettings模型 | P1 | - | ✅ 已完成 (LoginSettings) |
| DATA-006 | 实现Token本地存储 | P0 | - | ✅ 已完成 (`flutter_secure_storage`) |
| DATA-007 | 实现Token加密存储 | P1 | DATA-006 | ✅ 已完成 |

### 服务层任务

| 任务ID | 任务描述 | 优先级 | 依赖 | 状态 |
|--------|---------|--------|------|------|
| SVC-001 | 实现AuthService核心逻辑 | P0 | DATA-001,002 | ✅ 已完成 (`auth_service.dart`) |
| SVC-002 | 实现TokenService | P0 | DATA-006 | ✅ 已完成 (`auth_session_store.dart`) |
| SVC-003 | 实现SessionService | P1 | SVC-002 | ✅ 已完成 |
| SVC-004 | 实现登录状态持久化 | P0 | SVC-001 | ✅ 已完成 |

### UI层任务

| 任务ID | 任务描述 | 优先级 | 依赖 | 状态 |
|--------|---------|--------|------|------|
| UI-001 | 创建LoginPage页面 | P0 | SVC-001 | ✅ 已完成 |
| UI-002 | 实现登录表单组件 | P0 | UI-001 | ✅ 已完成 |
| UI-003 | 实现验证码显示组件 | P0 | UI-001 | ✅ 已完成 |
| UI-004 | 创建MFA对话框 | P1 | UI-001 | ✅ 已完成 |
| UI-005 | 创建SplashPage页面 | P0 | SVC-002 | ⏳ 待实现 |
| UI-006 | 实现登录错误提示 | P0 | UI-001 | ✅ 已完成 |
| UI-007 | 实现登录加载状态 | P0 | UI-001 | ✅ 已完成 |

### 测试任务

| 任务ID | 任务描述 | 优先级 | 依赖 | 状态 |
|--------|---------|--------|------|------|
| TEST-001 | AuthV2Api单元测试 | P0 | API-001 | ✅ 已完成 |
| TEST-002 | AuthService单元测试 | P0 | SVC-001 | ✅ 已完成 (`auth_service_test.dart`) |
| TEST-003 | TokenService单元测试 | P0 | SVC-002 | ✅ 已完成 (`auth_service_test.dart`) |
| TEST-004 | 登录流程集成测试 | P0 | UI-001 | ⏳ 待实现 |
| TEST-005 | MFA流程集成测试 | P1 | UI-004 | ⏳ 待实现 |
| TEST-006 | Token过期处理测试 | P1 | SVC-002 | ⏳ 待实现 |

### 文档任务

| 任务ID | 任务描述 | 优先级 | 依赖 | 状态 |
|--------|---------|--------|------|------|
| DOC-001 | API使用文档 | P1 | API-001 | ✅ 已完成 |
| DOC-002 | 认证流程说明文档 | P1 | UI-001 | ✅ 已完成 |
| DOC-003 | 安全最佳实践文档 | P2 | - | ✅ 已完成 |

## 风险与应对策略

### 技术风险

| 风险 | 影响 | 概率 | 应对策略 |
|------|------|------|---------|
| Token刷新机制复杂 | 高 | 中 | 提前设计刷新策略，参考OAuth2.0最佳实践 |
| MFA实现依赖后端 | 中 | 低 | 与后端团队提前确认API规范 |
| 本地存储安全 | 高 | 中 | 使用flutter_secure_storage加密存储 |

### 进度风险

| 风险 | 影响 | 概率 | 应对策略 |
|------|------|------|---------|
| UI设计变更 | 中 | 中 | 保持UI组件解耦，便于快速调整 |
| API接口变更 | 高 | 低 | 建立API变更通知机制 |
| 测试覆盖不足 | 中 | 中 | 预留缓冲时间，优先核心流程测试 |

### 安全风险

| 风险 | 影响 | 概率 | 应对策略 |
|------|------|------|---------|
| Token泄露 | 高 | 低 | 加密存储，定期刷新，安全传输 |
| 暴力破解 | 高 | 中 | 实现登录限制，验证码保护 |
| 会话劫持 | 高 | 低 | HTTPS传输，Token绑定设备 |

---

**文档版本**: 2.1  
**最后更新**: 2026-03-27  
**维护者**: Open1Panel开发团队

## 实现文件索引

| 文件 | 路径 | 说明 |
|------|------|------|
| 数据模型 | `lib/data/models/auth_models.dart` | 7个认证相关模型 |
| Repository | `lib/features/auth/auth_repository.dart` | Auth API边界 |
| Service | `lib/features/auth/auth_service.dart` | 认证业务逻辑 |
| Session Store | `lib/features/auth/auth_session_store.dart` | 安全会话存储 |
| 状态管理 | `lib/features/auth/auth_provider.dart` | Provider状态管理 |
| 登录页面 | `lib/features/auth/login_page.dart` | MDUI3登录UI |
| 单元测试 | `test/features/auth/auth_provider_test.dart` | Provider与模型测试 |
| 单元测试 | `test/features/auth/auth_service_test.dart` | Service测试 |
| 国际化 | `lib/l10n/app_*.arb` | 17条认证相关字符串 |
