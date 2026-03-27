# 认证管理模块FAQ

## 常见问题

### Q1: 登录后Token存储在哪里？

**A**: Token使用 `flutter_secure_storage` 进行存储（当前实现），存储键值：
- Token键: `auth_token`
- 用户名键: `auth_username`

**相关代码**: [auth_session_store.dart](../../../lib/features/auth/auth_session_store.dart)

### Q2: Token过期后如何处理？

**A**: 当前实现中Token过期处理：
1. API请求返回401状态码
2. 清除本地存储的Token
3. 跳转回登录页面

**未来规划**: 实现Token自动刷新机制。

**相关代码**: [auth_service.dart](../../../lib/features/auth/auth_service.dart)

### Q3: 如何启用MFA多因素认证？

**A**: MFA认证流程：
1. 用户在系统设置中启用MFA
2. 扫描二维码绑定认证器（如Google Authenticator）
3. 登录时输入用户名密码后，系统提示输入MFA码
4. 输入6位数字MFA码完成认证

**API端点**: `POST /core/auth/mfalogin`

**相关代码**: [auth_provider.dart](../../../lib/features/auth/auth_provider.dart)

### Q4: 演示模式有哪些限制？

**A**: 演示模式限制：
- 只能查看数据，不能修改
- 部分敏感功能禁用
- 登录会话时间较短（30分钟）
- 无法上传文件

**API端点**: `GET /core/auth/demo`

### Q5: 验证码有效期是多久？

**A**: 验证码有效期为5分钟，过期后需要重新获取。建议用户在获取后尽快输入。

**API端点**: `GET /core/auth/captcha`

### Q6: 登录失败多少次会被锁定？

**A**: 默认策略：
- 连续失败5次锁定账户30分钟
- 锁定期间显示剩余解锁时间
- 管理员可手动解锁账户

### Q7: 如何实现"记住登录"功能？

**A**: 当前实现通过 `AuthSessionStore + flutter_secure_storage` 持久化存储：
- Token存储在本地
- 应用启动时检查Token有效性
- 有效则自动登录，无效则显示登录页

### Q8: 支持哪些登录方式？

**A**: 当前支持：
- 用户名+密码
- 用户名+密码+验证码
- 用户名+密码+MFA
- 未来计划支持：OAuth2.0、SAML、生物识别

## 故障排查指南

### 问题1: 登录时提示"网络错误"

**可能原因**:
- 网络连接异常
- 服务器地址配置错误
- 防火墙阻止

**排查步骤**:
1. 检查网络连接
2. 验证服务器地址配置
3. 查看防火墙规则
4. 检查服务器状态

### 问题2: 登录成功后立即跳转回登录页

**可能原因**:
- Token存储失败
- Token验证失败
- 认证拦截器配置错误

**排查步骤**:
1. 检查`flutter_secure_storage`权限
2. 查看认证拦截器日志
3. 验证API响应格式
4. 检查Token格式是否正确

### 问题3: MFA码输入后提示"验证失败"

**可能原因**:
- MFA码错误
- 时间同步问题
- 认证器未正确绑定

**排查步骤**:
1. 确认MFA码输入正确
2. 检查设备时间是否同步
3. 重新绑定认证器
4. 联系管理员重置MFA

### 问题4: 验证码图片无法显示

**可能原因**:
- API调用失败
- 图片格式不支持
- 网络问题

**排查步骤**:
1. 检查API响应状态码
2. 验证图片格式（Base64）
3. 检查网络连接
4. 查看控制台错误日志

### 问题5: Token刷新失败

**可能原因**:
- Refresh Token过期
- 网络问题
- 服务器异常

**排查步骤**:
1. 检查Refresh Token有效期
2. 验证网络连接
3. 查看服务器日志
4. 重新登录获取新Token

## 最佳实践建议

### 开发建议

1. **使用Provider管理认证状态**
   ```dart
   // 当前实现示例
   class AuthProvider extends ChangeNotifier {
     AuthStatus _status = AuthStatus.initial;
     String? _token;
     
     AuthStatus get status => _status;
     bool get isAuthenticated => _status == AuthStatus.authenticated;
     
     Future<bool> login(String username, String password) async {
       // 登录逻辑
     }
   }
   ```

2. **实现自动登录**
   - 应用启动时调用`checkAuthStatus()`
   - Token有效则自动登录
   - Token无效则显示登录页

3. **错误处理**
   - 区分网络错误和业务错误
   - 提供友好的错误提示
   - 记录错误日志便于排查

### 安全建议

1. **Token安全**
   - 使用HTTPS传输
   - 当前已使用 `flutter_secure_storage` 加密存储
   - 定期刷新Token
   - 敏感操作二次验证

2. **密码安全**
   - 强制密码复杂度
   - 密码加密传输
   - 定期提醒修改密码

3. **会话管理**
   - 设置合理的会话超时
   - 提供手动登出功能
   - 多设备登录管理

### 用户体验建议

1. **登录流程**
   - ✅ 简洁明了的表单
   - ✅ 清晰的错误提示
   - ✅ 加载状态反馈
   - ✅ 验证码支持

2. **MFA体验**
   - ✅ 清晰的MFA输入界面
   - ⏳ 备用恢复码提供（待实现）

3. **错误处理**
   - ✅ 友好的错误提示
   - ✅ 明确的解决方案
   - ✅ 快速重试机制

---

**文档版本**: 2.1  
**最后更新**: 2026-03-27  
**维护者**: Open1Panel开发团队
