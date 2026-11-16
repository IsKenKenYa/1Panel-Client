# 1Panel 移动端APP - 开发环境设置文档

## 1. 概述

本文档提供了1Panel移动端APP开发环境的详细设置指南，帮助开发人员快速搭建开发环境并开始工作。同时，本文档也包含了开发标准和规范，以确保代码质量和可维护性，避免"屎山代码"的堆积。

## 2. 系统要求

### 2.1 硬件要求
- **操作系统**：Windows 10/11、macOS 12+、Linux (Ubuntu 20.04+)
- **处理器**：Intel Core i5 或更高配置
- **内存**：8GB RAM 或更高
- **存储空间**：至少 10GB 可用空间
- **网络连接**：稳定的互联网连接

### 2.2 软件要求
- **Flutter SDK**：3.16+（推荐最新稳定版）
- **Dart SDK**：3.2+（与Flutter SDK捆绑）
- **Android Studio**：最新稳定版（用于Android开发）
- **Xcode**：14.0+（macOS上，用于iOS开发）
- **Visual Studio Code**：最新稳定版（推荐的代码编辑器）
- **Git**：最新稳定版

## 3. 安装Flutter SDK

### 3.1 Windows安装步骤

1. 访问 [Flutter官网下载页面](https://flutter.dev/docs/get-started/install/windows) 下载最新的Flutter SDK压缩包
2. 解压Flutter SDK到你选择的目录（例如 `C:\src\flutter`）
3. 将Flutter的`bin`目录添加到系统环境变量`PATH`中
4. 打开命令提示符或PowerShell，运行以下命令以验证安装：
   ```powershell
   flutter doctor
   ```

### 3.2 macOS安装步骤

1. 访问 [Flutter官网下载页面](https://flutter.dev/docs/get-started/install/macos) 下载最新的Flutter SDK压缩包
2. 解压Flutter SDK到你选择的目录（例如 `~/development/flutter`）
3. 将Flutter的`bin`目录添加到`PATH`中：
   ```bash
   echo "export PATH=\$PATH:\$HOME/development/flutter/bin" >> ~/.zshrc
   source ~/.zshrc
   ```
4. 打开终端，运行以下命令以验证安装：
   ```bash
   flutter doctor
   ```

### 3.3 Linux安装步骤

1. 访问 [Flutter官网下载页面](https://flutter.dev/docs/get-started/install/linux) 下载最新的Flutter SDK压缩包
2. 解压Flutter SDK到你选择的目录（例如 `~/development/flutter`）
3. 将Flutter的`bin`目录添加到`PATH`中：
   ```bash
   echo "export PATH=\$PATH:\$HOME/development/flutter/bin" >> ~/.bashrc
   source ~/.bashrc
   ```
4. 打开终端，运行以下命令以验证安装：
   ```bash
   flutter doctor
   ```

## 4. 安装Android开发工具

### 4.1 安装Android Studio

1. 访问 [Android Studio官网](https://developer.android.com/studio) 下载并安装最新版本的Android Studio
2. 启动Android Studio，并按照安装向导的指示完成设置
3. 在Android Studio中安装Android SDK、Android SDK Platform-Tools和Android SDK Build-Tools
4. 配置Android SDK环境变量：
   - Windows: 设置`ANDROID_SDK_ROOT`环境变量指向Android SDK的安装路径
   - macOS/Linux: 在shell配置文件中添加`export ANDROID_SDK_ROOT=$HOME/Android/Sdk`

### 4.2 配置Android虚拟设备 (AVD)

1. 在Android Studio中，点击"Tools" > "AVD Manager"
2. 点击"Create Virtual Device..."
3. 选择一个设备定义（推荐使用"Pixel 5"或更高版本）
4. 选择一个系统镜像（推荐使用最新的稳定版Android系统）
5. 完成虚拟设备的创建和配置

## 5. 安装iOS开发工具 (仅macOS)

### 5.1 安装Xcode

1. 从Mac App Store下载并安装最新版本的Xcode
2. 打开Xcode，按照提示完成初始设置
3. 安装Xcode命令行工具：
   ```bash
   xcode-select --install
   ```

### 5.2 配置iOS模拟器

1. 在Xcode中，点击"Xcode" > "Preferences" > "Components"
2. 选择并安装最新的iOS模拟器
3. 打开模拟器：`open -a Simulator`

## 6. 安装Visual Studio Code

1. 访问 [Visual Studio Code官网](https://code.visualstudio.com/) 下载并安装最新版本的VS Code
2. 打开VS Code，安装以下推荐的扩展：
   - Flutter（由Dart Code提供）
   - Dart（由Dart Code提供）
   - Material Icon Theme
   - GitLens
   - Bracket Pair Colorizer

## 7. 安装Git

1. 访问 [Git官网](https://git-scm.com/downloads) 下载并安装最新版本的Git
2. 配置Git用户名和邮箱：
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

## 8. 克隆项目代码

1. 打开命令行工具（命令提示符/PowerShell/终端）
2. 导航到你想要存储项目的目录
3. 运行以下命令克隆项目代码：
   ```bash
   git clone <repository-url>
   cd onepanelapp_app
   ```

## 9. 安装项目依赖

1. 在项目根目录中，运行以下命令安装Flutter依赖：
   ```bash
   flutter pub get
   ```
2. 运行以下命令安装代码生成工具：
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## 10. 配置开发环境

### 10.1 API配置

1. 在项目根目录创建一个`.env`文件
2. 添加以下配置（根据你的环境修改）：
   ```
   API_BASE_URL=https://your-1panel-server.com
   DEBUG_MODE=true
   ```

### 10.2 IDE配置

1. 在VS Code中打开项目
2. 配置调试器：点击"Run" > "Add Configuration" > 选择"Dart & Flutter"
3. 更新`launch.json`文件以包含正确的配置

## 11. 运行项目

### 11.1 在Android模拟器/设备上运行

1. 确保Android模拟器正在运行或已连接Android设备
2. 在VS Code中，按`F5`或点击"Run" > "Start Debugging"
3. 或者在命令行中运行：
   ```bash
   flutter run
   ```

### 11.2 在iOS模拟器/设备上运行 (仅macOS)

1. 确保iOS模拟器正在运行或已连接iOS设备
2. 在VS Code中，按`F5`或点击"Run" > "Start Debugging"
3. 或者在命令行中运行：
   ```bash
   flutter run
   ```

### 11.3 Flutter Web

使用 Node.js 22.18 及以上版本和 pnpm 安装固定的发布依赖：

```bash
pnpm install --frozen-lockfile
pnpm build:web
pnpm check:web
```

`pnpm build:web` 准备本地 PDF.js 资源，并生成 `build/web/` 的 Flutter release 应用。`pnpm check:web` 只执行 Cloudflare 静态发布预演。固定域名与 Worker 名称位于 `cloudflare.config.ts`；部署时在终端执行 `pnpm exec cf auth login`，完成账户登录后执行 `pnpm deploy:web`。发布账户需要拥有目标域名。

浏览器开发使用 localhost 作为安全来源：

```bash
flutter run -d chrome --web-port 8765
flutter test --platform chrome test/web/browser_vault_test.dart test/web/browser_file_operations_test.dart
```

真实浏览器 API 测试通过 `.env` 读取测试凭据，测试面板需要明确允许 localhost 来源的 CORS 请求。仅使用专用测试主机，文件往返测试会创建并删除专用目录：

```bash
flutter test --platform chrome test/web/browser_api_integration_test.dart --dart-define-from-file=.env
```

本地密码仅检查非空与两次输入一致；成功后向浏览器密码管理器提交保存提示，表单不会向网络发送密码。是否保存或同步由浏览器及密码管理器设置决定。用户也可以主动选择浏览器密钥模式。Safari 分享菜单中的“添加到主屏幕”可以创建 iPhone、iPad 的独立应用入口。浏览器中的数据按来源隔离，固定使用正式域名才能持续访问同一份本地配置。

Cloudflare 使用 `web/_headers` 提供 CSP 与隐私响应头。客户端接受 HTTP/HTTPS 地址；HTTP 连接需要用户确认风险，仍受浏览器混合内容与局域网权限检查。支持 Local Network Access 的 Chrome/Edge 可授权访问局域网 HTTP；Safari 尚不支持同类豁免。公网 HTTP 不能依靠该权限解除混合内容限制。HTTPS 面板需要可信证书。

认证统一使用 `hmac_sha256(API-Key, '1panel:' + UnixTimestamp)`，HTTP、WebSocket 和后台下载复用 `OnePanelAuthHeaders`。签名不会给 HTTP 加密，认证签名与数据仍可能被截获或篡改，签名在有效窗口内可能被重放。API Key 不进入 URL 或原始密钥请求头；浏览器网络日志不保存正文、查询参数或签名。

面板需要允许网页来源的 `GET, POST, PUT, PATCH, DELETE, OPTIONS`、实际请求使用的 `1Panel-Token`、`1Panel-Timestamp`、`Content-Type` 等请求头；文件下载需要暴露 `Content-Disposition` 与 `Content-Length`。预检请求应在认证之前返回成功，来源应明确限定。网站模块的 CORS 配置作用于该网站；本次测试面板原始管理 API 的 OPTIONS 未返回 CORS 响应头。

用户可在自己控制的面板反向代理中增加以下配置；将 `13802` 替换为实际的本机面板端口。此配置位于用户服务器，Cloudflare 静态应用不转发面板请求。代理入口的 HTTPS 与证书需要单独配置。

```nginx
location /api/v2/ {
    add_header Access-Control-Allow-Origin "https://1pc.iskenkenya.com" always;
    add_header Vary "Origin" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Accept, 1Panel-Token, 1Panel-Timestamp" always;
    add_header Access-Control-Expose-Headers "Content-Disposition, Content-Length" always;

    if ($request_method = OPTIONS) {
        return 204;
    }

    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://127.0.0.1:13802;
}
```

使用代理时，按 1Panel 的可信代理设置正确识别来源 IP，并保留 API Key 的 IP 白名单。CORS 授权不替代 API 鉴权。WebSocket 认证能力边界见跨平台治理文档。

## 12. 开发工具和技巧

### 12.1 Flutter DevTools

Flutter提供了一组强大的开发工具，用于调试、性能分析和UI检查：

1. 在命令行中运行：
   ```bash
   flutter pub global activate devtools
   ```
2. 启动应用后，运行：
   ```bash
   flutter pub global run devtools
   ```
3. 在浏览器中打开提供的URL

### 12.2 常用Flutter命令

```bash
# 检查Flutter环境
flutter doctor

# 获取依赖
flutter pub get

# 运行应用
flutter run

# 热重载（在应用运行时按r键）
r

# 热重启（在应用运行时按R键）
R

# 构建APK
flutter build apk

# 构建iOS应用
flutter build ios

# 运行测试
flutter test

# 生成代码
flutter pub run build_runner build
```

## 13. 常见问题解决

### 13.1 Android许可证问题

如果运行`flutter doctor`时出现Android许可证问题：

```bash
flutter doctor --android-licenses
```

按照提示接受所有许可证。

### 13.2 依赖冲突问题

如果遇到依赖冲突：

```bash
flutter pub upgrade
```

普通 Flutter 平台可以按需升级依赖，但 HarmonyOS/OHOS 构建必须优先使用仓库中的 `pubspec.lock`。不要为排障随意删除 `pubspec.lock`，否则可能把第三方包升级到未处理 `TargetPlatform.ohos` 的版本。

### 13.3 HarmonyOS / OHOS 构建

HarmonyOS 使用 Flutter-OH，不与官方 Flutter 共用 SDK。macOS 可直接使用完整路径：

```bash
/Volumes/FanXiangMac/DevTools/Flutter_HMOS/flutter_flutter/bin/flutter --version
/Volumes/FanXiangMac/DevTools/Flutter_HMOS/flutter_flutter/bin/flutter build hap --release
```

Windows 使用 `flutter.bat` 完整路径，不依赖 `hflutter` shell 函数：

```powershell
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat --version
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat build hap --release
```

当前已验证 Flutter-OH：`3.35.8-ohos-0.0.3`，framework revision `8957a7cf95`。构建产物位于 `build/ohos/hap/entry-default-signed.hap`。

如果出现 `TargetPlatform.ohos` switch exhaustiveness 错误，先确认是否使用仓库 lock 和已验证 Flutter-OH revision；项目代码应增加 OHOS/default 分支，第三方包优先 pin 回已验证版本或通过项目自有 platform facade 绕开。

完整指南见 `docs/development/harmonyos_build_and_sideload.md`。

### 13.4 Xcode版本不兼容问题

如果Xcode版本不兼容：

1. 更新到最新版本的Xcode
2. 或在`Podfile`中指定兼容的iOS版本

### 13.5 模拟器启动缓慢问题

如果Android模拟器启动缓慢，可以启用GPU加速或使用物理设备进行开发。

## 14. 开发标准与规范

为确保项目的代码质量、可维护性和可扩展性，所有开发人员必须严格遵守以下开发标准和规范。

### 14.1 代码规范

#### 14.1.1 Dart语言规范
- 遵循[Dart官方风格指南](https://dart.dev/guides/language/effective-dart/style)
- 使用2个空格进行缩进
- 每行不超过100个字符
- 使用小驼峰命名变量和函数（如`userName`、`getUserData()`）
- 使用大驼峰命名类和枚举（如`UserModel`、`AuthService`）
- 使用下划线前缀标识私有成员（如`_privateVar`、`_privateMethod()`）
- 导入顺序：Dart核心库、Flutter库、第三方库、项目内部库
- 使用空安全（null safety）特性
- 避免使用`dynamic`类型

#### 14.1.2 Flutter组件规范
- 组件命名使用大驼峰（如`UserProfileCard`）
- 组件应保持单一职责
- 使用`const`构造函数创建无状态组件
- 避免在`build`方法中执行复杂计算
- 使用`const`修饰符优化性能
- 组件应具备可复用性和可测试性
- 优先使用组合而非继承

### 14.2 架构设计

#### 14.2.1 整体架构
- 采用MVVM（Model-View-ViewModel）或Clean Architecture架构模式
- 分离UI逻辑和业务逻辑
- 使用依赖注入管理对象创建和依赖关系
- 实现数据层与UI层的松耦合

#### 14.2.2 目录结构
- `lib/`：主源代码目录
  - `src/`：应用源代码
    - `models/`：数据模型
    - `services/`：服务类（API调用、数据处理等）
    - `viewmodels/`：视图模型（处理UI逻辑和状态）
    - `views/`：UI组件和页面
    - `widgets/`：可复用UI组件
    - `utils/`：工具函数和辅助类
    - `constants/`：常量定义
    - `routes/`：路由配置
    - `themes/`：主题和样式
    - `localization/`：国际化资源
  - `main.dart`：应用入口文件

### 14.3 状态管理

- 优先使用Flutter内置的状态管理（`setState`、`InheritedWidget`）
- 对于复杂状态，使用`Provider`、`Riverpod`或`Bloc`
- 避免在Widget之间直接传递状态
- 状态应尽可能在最低需要它的层级上管理
- 对于全局状态，考虑使用单例或全局状态管理器

### 14.4 错误处理

- 统一的错误处理机制
- 使用try-catch捕获可能的异常
- 为网络请求添加超时处理
- 向用户显示友好的错误信息
- 记录详细的错误日志，包括时间、操作、错误类型和堆栈跟踪
- 实现崩溃报告机制

### 14.5 日志记录

- 使用统一的日志工具（如`logger`包）
- 分级日志：调试、信息、警告、错误、严重错误
- 在开发环境显示详细日志，生产环境只记录关键信息
- 避免在日志中包含敏感信息（如密码、令牌等）
- 实现日志文件存储，便于问题排查

### 14.6 性能优化

- 优化Widget重建
- 使用`const`构造函数
- 实现懒加载和分页加载
- 优化网络请求（缓存、压缩、批量请求）
- 合理使用`FutureBuilder`和`StreamBuilder`
- 避免内存泄漏（正确处理流订阅、定时器等）
- 使用`Flutter DevTools`进行性能分析

### 14.7 安全性

- 安全存储敏感信息（使用`flutter_secure_storage`）
- 避免硬编码凭证
- 实现HTTPS通信
- 定期刷新认证令牌
- 验证所有用户输入
- 防止SQL注入和XSS攻击
- 实现数据加密存储

## 15. 团队协作流程

### 15.1 Git工作流

1. 创建新分支进行开发：
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. 提交更改：
   ```bash
   git add .
   git commit -m "Add feature description"
   ```
3. 推送到远程仓库：
   ```bash
   git push origin feature/your-feature-name
   ```
4. 创建Pull Request进行代码审查

### 15.2 代码审查流程

1. 所有代码更改必须通过Pull Request
2. 至少需要一位团队成员批准才能合并
3. 确保所有测试通过
4. 遵循项目的代码规范
5. 关注代码质量、性能和安全性
6. 提供具体的反馈和改进建议

### 15.3 文档规范

- 为所有公共API编写文档注释
- 代码注释应解释为什么这样做，而不是做了什么
- 为复杂的业务逻辑提供流程图或说明
- 定期更新API文档和用户文档
- 确保文档与代码保持同步

## 15. 后续步骤

1. 阅读项目文档，了解项目架构和设计
2. 熟悉1Panel API文档
3. 开始实现功能或修复Bug
4. 定期更新Flutter SDK和依赖

---

通过遵循本指南，您应该能够成功设置1Panel移动端APP的开发环境并开始开发工作。如果您遇到任何问题，请参考Flutter官方文档或联系团队成员寻求帮助。
