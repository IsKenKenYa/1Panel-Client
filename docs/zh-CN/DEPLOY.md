# 部署指南

## 前置条件

- Flutter 3.16+ 或更高版本
- Dart 3.6+
- 具有API访问权限的1Panel服务器

## 开发规范

- 权威规范：`AGENTS.md`（硬性规则，其中「最高优先级执行规则」优先于本文）与 `CLAUDE.md`（流程细则）。每次用户消息提到 AGENTS.md 时，重新阅读 `AGENTS.md` 全文。
- 实时功能批次与验证证据：`docs/development/modules/阶段总计划.md`。
- 提交前基线：`flutter analyze`、`dart run test/scripts/test_runner.dart unit`；涉及 API/网络或 UI 时分别运行 `integration`、`ui`；跨模块改动运行 `all`。提交消息遵循 Conventional Commits 并填写 `scope`，按模块或类别分组提交。默认直接在当前分支修改，新建分支需要用户明确同意。

## 原生 UI 适配与强门禁

- 原生 UI 适配流程与模块链路适配流程：`AGENTS.md` § 模块适配与原生UI工作流
- 跨平台治理总纲：`docs/development/cross_platform_ui_governance.md`

强制门禁（任一失败即阻断推进）：

```bash
flutter analyze
dart run test/scripts/test_runner.dart unit
dart run test/scripts/test_runner.dart integration   # 涉及 API/网络/数据写入，需要 RUN_LIVE_API_TESTS=true
dart run test/scripts/test_runner.dart ui            # 涉及 UI 改动
dart run test/scripts/test_runner.dart all           # 跨模块改动或回归基线
dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug   # Windows 原生 UI 改动
hflutter build hap --release                        # HarmonyOS/OHOS 平台能力或构建配置改动
```

上游 1Panel 快照更新后的适配门禁，在 `docs/development/modules/` 目录执行：

```bash
python3 check_module_api_updates.py --all
python3 check_module_client_coverage.py --all
```

`check_module_client_coverage.py` 的 `missing_in_client` 必须清零。客户端保留的增强端点会列入报告并注明原因，属于非阻断项。`check_module_api_updates.py` 显示 `updated` 时，用 `python3 analyze_module_api.py <模块关键词>` 重新生成该模块分析基线，并在 `阶段总计划.md` 回写批次状态与命令结果。

Apple 原生 UI 轨道改动需在 macOS/CI 额外执行：

```bash
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug build
```

说明：Web 不在当前原生 UI 适配范围内。

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

### 生产构建说明

当前适配范围为 Android、iOS、iPadOS、macOS、Windows、Linux、HarmonyOS。Web 不在当前适配范围，MDUI3 基线持续作为全平台可用轨道。

## 部署检查清单

- [ ] API密钥配置正确
- [ ] 服务器URL可访问
- [ ] SSL证书有效（HTTPS）
- [ ] 时间同步已启用（NTP）
- [ ] 部署前测试认证

## API密钥认证

### 如何获取API密钥与配置API访问权限

1. 登录您的 1Panel 面板。
2. 进入 **面板设置** -> **API 接口**。
3. 打开“API接口”开关以启用 API，然后复制 **API Key**。
4. **重要提醒：配置 IP 白名单**。在“允许的 IP”栏目中，您必须填入将要连接到该服务器的客户端设备 IP。如果您的客户端运行在移动设备（如手机网络）且 IP 频繁变动，请输入 `0.0.0.0/0` 以允许所有 IP 访问。

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

*最后更新：2026-11-15*
