# macOS 钥匙串访问修复

## 问题描述

在 macOS 上，应用无法可靠地从 FlutterSecureStorage 读取 API 密钥，导致即使配置了有效的 API 密钥也会出现 401 未授权错误。症状包括：

- 服务器列表可以显示名称和 URL
- 服务器切换界面正常工作
- 但实际的 API 请求失败，返回 401 错误
- 发起请求时 API 密钥显示为空

## 根本原因

问题有两个根本原因：

### 1. 缺少钥匙串访问权限

macOS 应用启用了沙盒（`com.apple.security.app-sandbox = true`），但缺少必需的钥匙串访问权限。没有 `keychain-access-groups` 权限，沙盒化的 macOS 应用无法访问钥匙串，导致所有 FlutterSecureStorage 操作静默失败或超时。

### 2. FlutterSecureStorage 配置不当

FlutterSecureStorage 使用默认设置初始化：
- 超时时间过短（200ms），容易导致过早失败
- 没有 macOS 平台特定选项
- 没有为钥匙串项目设置明确的可访问性

## 解决方案

### 1. 添加钥匙串权限

更新了 `macos/Runner/DebugProfile.entitlements` 和 `macos/Runner/Release.entitlements`：

```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.onepanel.client</string>
</array>
```

这为应用授予了访问其钥匙串组的明确权限。

### 2. 启用代码签名

更新了 `macos/Runner.xcodeproj/project.pbxproj`，将所有构建配置（Debug、Release、Profile）的 `CODE_SIGN_IDENTITY` 从 `"-"`（不签名）改为 `"Apple Development"`。

钥匙串权限要求应用必须正确签名。使用 "Apple Development" 可以为本地开发启用自动签名。

### 3. 改进 FlutterSecureStorage 配置

使用适当的平台特定选项更新了所有 FlutterSecureStorage 初始化：

```dart
const FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
)
```

主要改进：
- 将超时时间从 200ms 增加到 5 秒
- 设置 `KeychainAccessibility.first_unlock` 以提高可靠性
- 确保钥匙串项目在设备首次解锁后可访问
- iOS 和 macOS 配置保持一致
- 移除了 Android 已弃用的 `encryptedSharedPreferences` 选项

### 3. 移除回退机制

之前的实现有一个使用 SharedPreferences 和内存存储的复杂回退系统。现已移除，原因如下：
- 它掩盖了真正的问题而不是修复它
- 产生了安全隐患（API 密钥存储在 SharedPreferences 中）
- 增加了不必要的复杂性
- 使调试更加困难

### 4. 添加迁移功能

创建了 `ApiConfigMigration` 来将旧的 SharedPreferences 回退中的现有 API 密钥迁移到正确的安全存储。这确保使用过回退机制的用户不会丢失他们的配置。

## 修改的文件

1. `macos/Runner/DebugProfile.entitlements` - 添加钥匙串权限
2. `macos/Runner/Release.entitlements` - 添加钥匙串权限
3. `macos/Runner.xcodeproj/project.pbxproj` - 将 CODE_SIGN_IDENTITY 从 "-" 改为 "Apple Development"
4. `lib/core/config/api_config.dart` - 改进存储配置，移除回退机制
5. `lib/features/auth/auth_session_store.dart` - 改进存储配置
6. `lib/core/storage/hive_storage_service.dart` - 改进存储配置
7. `lib/core/config/api_config_migration.dart` - 新增迁移辅助工具
8. `lib/main.dart` - 在应用初始化期间添加迁移调用

## 测试方法

应用此修复后：

1. 确保你有 Apple 开发者账号或使用个人团队签名（Xcode 会自动处理）
2. 清理并构建 macOS 应用：`flutter clean && flutter build macos`
3. 运行应用
4. 配置带有 API 密钥的服务器
5. 验证 API 请求成功（无 401 错误）
6. 重启应用
7. 验证 API 密钥持久化且请求仍然正常工作

注意：首次运行时，Xcode 可能会提示你选择开发团队。选择你的 Apple ID 或个人团队即可。

## 技术细节

### 为什么使用 `first_unlock` 可访问性？

`KeychainAccessibility.first_unlock` 意味着：
- 项目在设备启动后首次解锁后可访问
- 在安全性和可用性之间提供良好平衡
- 比 `unlocked`（需要设备当前处于解锁状态）更可靠
- 适用于应用运行时需要可用的 API 密钥

### 为什么使用 5 秒超时？

之前的 200ms 超时过于激进：
- 钥匙串操作在首次访问时可能需要更长时间
- macOS 钥匙串可能需要初始化
- 网络同步的钥匙串项目可能需要时间
- 5 秒提供了合理的缓冲，同时仍能捕获真正的失败

## 相关问题

此修复解决了"macOS 下 API key 读取不稳定"问题，即 API 密钥在 macOS 桌面上间歇性加载失败。

## 参考资料

- [Apple 钥匙串服务文档](https://developer.apple.com/documentation/security/keychain_services)
- [flutter_secure_storage 包](https://pub.dev/packages/flutter_secure_storage)
- [macOS 应用沙盒权限](https://developer.apple.com/documentation/bundleresources/entitlements)
