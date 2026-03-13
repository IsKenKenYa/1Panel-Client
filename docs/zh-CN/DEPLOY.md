# 部署指南

## 前置条件

- Flutter 3.16+ 或更高版本
- Dart 3.6+
- 具有API访问权限的1Panel服务器

## 开发规范

- 权威规范：`AGENTS.md`（硬性规则）与 `CLAUDE.md`（流程细则）。
- 提交前基线：`flutter analyze`、`dart run test_runner.dart unit`；涉及 API/网络或 UI 时分别运行 `integration`、`ui`。

## 认证配置

1Panel API 使用 **API密钥 + 时间戳** 认证方式（无需用户名密码）：

```
Token = MD5("1panel" + API-Key + UnixTimestamp)
```

**必需请求头：**
- `1Panel-Token`: 认证字符串的MD5哈希值
- `1Panel-Timestamp`: 当前Unix时间戳（秒级）

## 环境配置

1. 复制示例环境文件：
   ```bash
   cp .env.example .env
   ```

2. 编辑 `.env` 文件，配置您的设置：
   ```bash
   # 服务器配置
   PANEL_BASE_URL=http://your-panel-server:port
   API_VERSION=v2

   # 认证配置（仅需API密钥，无需用户名密码）
   PANEL_API_KEY=your_api_key_here

   # 获取API密钥：1Panel面板 → 设置 → API接口
   ```

3. **重要**：切勿将 `.env` 提交到版本控制！

## 生产构建

### Android

```bash
# 构建APK
flutter build apk --release

# 构建App Bundle（用于Google Play）
flutter build appbundle --release
```

输出位置：
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
# 构建App Store版本
flutter build ios --release

# 或构建IPA
flutter build ipa --release
```

### Web

```bash
flutter build web --release
```

输出位置：`build/web/`

## 部署检查清单

- [ ] API密钥配置正确
- [ ] 服务器URL可访问
- [ ] SSL证书有效（HTTPS）
- [ ] 时间同步已启用（NTP）
- [ ] 部署前测试认证

## API密钥认证

### 如何获取API密钥

登录1Panel面板 → 设置 → API接口 → 生成API密钥

### 令牌生成

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

String generateToken(String apiKey, int timestamp) {
  final data = '1panel$apiKey$timestamp';
  final bytes = utf8.encode(data);
  final digest = md5.convert(bytes);
  return digest.toString();
}
```

### 请求头

```dart
final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
final token = generateToken(apiKey, timestamp);

final headers = {
  '1Panel-Token': token,
  '1Panel-Timestamp': timestamp.toString(),
  'Content-Type': 'application/json',
};
```

## 故障排除

### 常见问题

1. **401 未授权**：检查API密钥和时间戳同步
2. **连接被拒绝**：验证服务器URL和网络连接
3. **SSL证书错误**：检查证书有效性或测试时使用HTTP

### 时间同步

确保您的设备和服务器使用NTP进行时间同步。

```bash
# Linux - 启用NTP
sudo timedatectl set-ntp true
```

---

*最后更新：2024-02-12*
