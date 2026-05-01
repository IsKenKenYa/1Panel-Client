<p align="center">
  <img src="assets/branding/app_icon_master.png" alt="1Panel Client Logo" width="120" />
</p>

<h1 align="center">1Panel Client</h1>

<p align="center">
  <a href="https://github.com/IsKenKenYa/1Panel-Client/releases"><img src="https://img.shields.io/badge/版本-0.6.0%2B1-blue.svg" alt="版本" /></a>
  <a href="https://github.com/IsKenKenYa/1Panel-Client/blob/master/LICENSE"><img src="https://img.shields.io/badge/许可-GPL--3.0-green.svg" alt="许可" /></a>
</p>

<p align="center">用于连接和管理一台或多台 1Panel 服务器的跨平台客户端。</p>

<p align="center">
  <strong>中文</strong> | <a href="README.md">English</a>
</p>

---

## 它是什么

- 一个面向 1Panel 用户的客户端，而不是只在浏览器里完成操作的管理方式
- 以多服务器切换、状态查看和常用运维入口为核心体验
- 让你在手机或桌面端也能快速处理日常 1Panel 管理任务

## 适合谁

- 需要统一管理多台 1Panel 服务器的用户
- 希望随时查看服务器状态并快速进入常用模块的运维用户
- 愿意体验客户端新交互并提供反馈的早期使用者

## 你可以做什么

本客户端为 1Panel 服务器提供全面的管理能力，**100% API 覆盖**（34 个模块，425+ 个端点）：

### 核心管理（8 个主模块）
- **仪表板**: 实时系统监控，包含 CPU、内存、磁盘和网络 I/O 指标
- **文件管理**: 完整的文件操作，包括浏览、编辑、上传/下载、回收站、传输管理器、收藏夹和挂载点
- **容器管理**: 完整的 Docker 生命周期管理，包含容器、镜像、Compose 编排、网络和卷
- **应用管理**: 应用商店集成，支持安装、更新和生命周期管理
- **网站管理**: 完整的网站操作，包括 SSL 证书、域名管理、路由规则和配置中心
- **AI 管理**: Ollama 模型管理、AI 代理配置、GPU 监控和域名绑定
- **数据库管理**: 完整支持 MySQL/MariaDB、PostgreSQL 和 Redis，包含备份和用户管理
- **设置**: 系统配置、安全设置、快照和面板更新

### 高级运维（14 个扩展模块）
- **防火墙管理**: 规则、IP 白名单和端口管理
- **备份与恢复**: 备份账户、记录和完整的恢复操作
- **定时任务管理**: 计划任务，包含执行历史和日志
- **运行时管理**: PHP 扩展/配置、Node 模块/脚本和 Supervisor 进程管理
- **SSH 管理**: SSH 设置、证书、日志和会话管理
- **进程管理**: 系统进程监控和控制
- **主机管理**: 主机资产和系统信息
- **命令管理**: 命令执行和历史记录
- **脚本库**: 脚本管理和执行
- **日志中心**: 系统日志和任务日志查看
- **工具箱**: 设备管理、磁盘操作、ClamAV、Fail2ban 和 FTP
- **OpenResty**: 配置管理和源码编辑
- **监控**: 实时指标和图表可视化
- **终端**: SSH 终端访问

### 系统特性
- 多服务器切换和管理
- 统一日志系统，具备隐私保护（自动 IP 脱敏）
- 完整国际化（中文/英文）
- 移动端优化界面，支持平板
- 安全认证，集成 1Panel API 密钥

## 第一次使用（重要：开启 API 配置）

在使用 1Panel Client 之前，您**必须**在 1Panel 服务器面板中开启 API 访问权限：

1. **开启 API 及获取密钥**：登录 1Panel Web 面板。进入左侧菜单 **面板设置** -> **API 接口**。打开“API 接口”开关并确认，复制下方的 **API Key**。
2. **配置 IP 白名单**：在同一个 API 接口设置页面，必须配置“允许的 IP”。如果您使用手机等移动网络（IP 会频繁变动），请填写 `0.0.0.0/0` 以允许所有 IP 访问。如果您有固定公网 IP 或 VPN，请填写具体的固定 IP 地址。
3. **安装客户端**：在您的设备上安装 1Panel Client。
4. **添加服务器**：打开客户端，点击添加服务器。输入您的 1Panel 服务器地址（例如 `https://panel.example.com:port`）以及您刚才复制的 **API Key**。
5. **连接**：测试连接并保存。现在您可以直接在客户端内管理服务器了！

## 抢先体验版说明

- 当前 Android 版本主要用于抢先体验与收集用户反馈。
- 这个渠道暂不支持应用内自动更新。
- 后续版本将通过 GitHub Pre-release 持续发布。
- 当前官方唯一反馈渠道为 GitHub Issues：
  - [Issues](https://github.com/IsKenKenYa/1Panel-Client/issues)

## 近期更新

### 0.6.0

- 新增终端工作台、运行时会话和 WebSocket 传输层，支持更完整的终端工作流。
- 新增 Windows 原生主机桥接、能力白名单和系统托盘接入，补齐桌面端原生轨道。
- 新增平台自适应壳与服务感知导航，保证模块切换始终留在统一壳内。
- 新增统一 API 响应解析与异常处理，减少网络层重复逻辑。
- 优化文件、数据库、网站、日志、监控、设置与安全相关的体验与流程。
- 更新 iOS 与 macOS 工程配置，继续推进原生平台适配。

本次版本仍属于 `debug` 渠道，发布前请先在目标平台验证。

## 🛠️ 技术栈

- **框架**: Flutter 3.16+ 配合 Material Design 3
- **网络**: Dio HTTP客户端，具备全面错误处理和重试机制
- **状态管理**: Provider模式
- **认证**: 基于MD5 token的身份验证（1Panel专用）
- **存储**: Flutter Secure Storage + SharedPreferences
- **国际化**: 内置Flutter i18n (中文/英文)
- **日志**: 统一日志系统，具备隐私保护（IP脱敏）

## 开发规范

- **权威规范**: `AGENTS.md`（架构、文件大小、测试的硬性规则）
- **文件大小限制**: 所有代码文件硬上限 1000 LOC（不包括文档和生成文件）
- **提交前基线**: 
  - `flutter analyze`（必须）
  - `dart run test/scripts/test_runner.dart unit`（必须）
  - `dart run test/scripts/test_runner.dart integration`（涉及 API/网络时）
  - `dart run test/scripts/test_runner.dart ui`（涉及 UI 时）
- **架构**: 单向依赖：`Presentation -> State -> Service/Repository -> API/Infra`
- **日志**: 使用 `lib/core/services/logger/logger_service.dart` 中的 `appLogger`，禁止使用 `print()` 或 `debugPrint()`

## 🌐 网络架构

本项目采用**基于Dio的全面网络架构**，经过全面验证完成1Panel V2 API集成：

### 🎯 **API 实现状态：生产就绪（425+ 端点）**

经过对 1Panel V2 API 的全面分析和实现，本项目提供了**所有已记录 V2 端点的完整覆盖**。基于官方 V2 OpenAPI 规范（**429 个 API 端点**）和多轮验证：

#### **已实现的 API 客户端（34 个文件）**
- ✅ **AI 管理** - `ai_v2.dart`
- ✅ **应用管理** - `app_v2.dart`
- ✅ **身份认证** - `auth_v2.dart`
- ✅ **备份管理** - `backup_account_v2.dart`
- ✅ **命令管理** - `command_v2.dart`
- ✅ **容器管理** - `container_v2.dart`, `compose_v2.dart`
- ✅ **定时任务管理** - `cronjob_v2.dart`
- ✅ **仪表板管理** - `dashboard_v2.dart`
- ✅ **数据库管理** - `database_v2.dart`
- ✅ **磁盘管理** - `disk_management_v2.dart`
- ✅ **Docker 管理** - `docker_v2.dart`
- ✅ **文件管理** - `file_v2.dart`
- ✅ **防火墙管理** - `firewall_v2.dart`
- ✅ **主机管理** - `host_v2.dart`, `host_tool_v2.dart`
- ✅ **日志管理** - `logs_v2.dart`
- ✅ **监控管理** - `monitor_v2.dart`
- ✅ **OpenResty 管理** - `openresty_v2.dart`
- ✅ **进程管理** - `process_v2.dart`
- ✅ **运行时管理** - `runtime_v2.dart`
- ✅ **脚本库** - `script_library_v2.dart`
- ✅ **设置管理** - `setting_v2.dart`
- ✅ **快照管理** - `snapshot_v2.dart`
- ✅ **SSH 管理** - `ssh_v2.dart`
- ✅ **SSL 管理** - `ssl_v2.dart`
- ✅ **系统组管理** - `system_group_v2.dart`
- ✅ **任务日志管理** - `task_log_v2.dart`
- ✅ **终端管理** - `terminal_v2.dart`
- ✅ **工具箱管理** - `toolbox_v2.dart`
- ✅ **更新管理** - `update_v2.dart`
- ✅ **用户管理** - `user_v2.dart`
- ✅ **网站管理** - `website_v2.dart`, `website_group_v2.dart`

### 核心组件

- **DioClient**: 统一HTTP客户端，支持自动重试和错误处理
- **拦截器系统**:
  - **身份认证**: 1Panel专用的MD5 token生成
    - MD5哈希: `MD5("1panel" + apiKey + timestamp)` (匹配服务器实现)
    - 自动时间戳和签名头部 (`1Panel-Token`, `1Panel-Timestamp`)
  - 日志记录 (仅调试模式)
  - 指数退避重试机制
  - 自定义异常类型的错误处理
- **API客户端管理**: 多服务器集中客户端管理
- **类型安全**: 强类型数据模型与全面API集成

### 🔍 **验证状态：完成（4 轮全面验证）**

- ✅ **第 1 轮**: 初始 API 实现和身份认证架构
- ✅ **第 2 轮**: 深度模块分析和差距识别
- ✅ **第 3 轮**: 最终完整性验证 - 确认生产就绪状态
- ✅ **第 4 轮**: OpenAPI V2 规范分析，100% 覆盖验证
- ✅ **当前状态**: 所有 34 个 API 模块已实现，60+ 数据模型

### 网络功能

- ✅ **自动重试**: 可配置的指数退避重试
- ✅ **错误处理**: 统一异常处理和自定义类型
- ✅ **日志记录**: 全面的请求/响应日志，具备隐私保护
- ✅ **1Panel身份认证**: 服务器兼容的MD5 token生成和正确的头部信息
- ✅ **API路径管理**: 所有端点自动处理`/api/v2`前缀
- ✅ **常量管理**: 统一的API配置和路径管理
- ✅ **完整类型安全**: 所有 425+ 端点均具有强类型模型
- ✅ **统一架构**: 所有 API 客户端采用一致的模式
- ✅ **构建集成**: 模型和序列化的自动代码生成
- ✅ **超时管理**: 所有操作的可配置超时
- ✅ **多服务器支持**: 管理多个1Panel实例
- ✅ **完整V2 API覆盖**: 所有已记录的端点，涵盖 34 个 V2 API 模块
- ✅ **强类型模型**: 60+ 个全面的数据模型文件，支持JSON序列化
- ✅ **隐私保护**: 日志中自动脱敏公网 IP

### API集成状态

#### ✅ **完整实现概览**
**总覆盖**: 425+ API端点，来自官方1Panel V2文档的所有功能区域

**API文件**: 34 个模块，完整实现所有功能
**数据模型**: 60+ 个全面模型文件，涵盖所有功能区域并支持JSON序列化
**代码质量**: 所有文件遵循严格的 LOC 限制（≤1000 LOC 硬上限）

#### ✅ **完整API实现（所有 34 个模块）**
- **AI 管理**: 完整的 Ollama 模型集成和 GPU 监控
- **应用管理**: 完整的应用商店集成和生命周期管理
- **身份认证**: 登录、登出和会话管理
- **备份管理**: 完整的备份操作和恢复功能
- **命令管理**: 命令执行和管理
- **容器管理**: 完整的 Docker 容器、镜像和 Compose 管理
- **定时任务管理**: 带执行日志和统计的调度任务
- **仪表板管理**: 系统仪表板和概览
- **数据库管理**: 带强类型的完整数据库操作
- **磁盘管理**: 磁盘操作和管理
- **Docker 管理**: Docker 服务和集成管理
- **文件管理**: 全面的文件操作和传输功能
- **防火墙管理**: 完整的防火墙规则和端口管理
- **主机管理**: 完整的主机监控和系统管理
- **日志管理**: 系统日志和分析
- **监控管理**: 系统指标和告警管理
- **OpenResty 管理**: OpenResty 配置和管理
- **进程管理**: 进程监控和控制
- **运行时管理**: 完整的运行环境管理
- **脚本库**: 脚本管理和执行
- **设置管理**: 系统配置和快照管理
- **快照管理**: 系统备份快照和恢复
- **SSH 管理**: SSH 配置和密钥管理
- **SSL 管理**: SSL 证书生命周期和 ACME 集成
- **系统组管理**: 完整的系统用户和组管理
- **任务日志管理**: 任务执行日志和历史
- **终端管理**: SSH 会话和命令执行
- **工具箱管理**: 系统工具和实用程序
- **更新管理**: 系统更新和升级管理
- **用户管理**: 认证、角色和权限
- **网站管理**: 完整的网站、域名、SSL 和代理管理

## 📋 前置条件

- Flutter 3.16+ 或更高版本
- Dart 3.6+
- 具有API访问权限的1Panel服务器

## 🚀 快速开始

1. **克隆仓库**
   ```bash
   git clone <repository-url>
   cd 1Panel-Client
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **配置1Panel服务器**
   - 在应用设置中添加服务器配置
   - 确保1Panel服务器已启用API访问
   - 从1Panel管理面板获取API密钥（设置 → API接口）
   - **认证方式**: 使用API密钥 + 时间戳（MD5令牌），无需用户名密码
     - 令牌格式: `MD5("1panel" + apiKey + timestamp)`
     - 请求头: `1Panel-Token` 和 `1Panel-Timestamp`

4. **运行应用**
   ```bash
   # 调试模式
   flutter run

   # 发布模式
   flutter run --release
   ```

## 📱 平台支持

- ✅ **Android**: 完整支持
- ✅ **iOS**: 完整支持
- ✅ **Web**: 支持 (有限制)
- ✅ **Windows**: 支持 (有限制)
- ✅ **macOS**: 支持 (有限制)

## 🏗️ 项目结构

```
lib/
├── api/v2/              # 类型安全 API 客户端（1Panel V2 APIs）- 34 个模块
│   ├── ai_v2.dart       # AI 管理 API ✅
│   ├── app_v2.dart      # 应用管理 API ✅
│   ├── auth_v2.dart     # 身份认证 API ✅
│   ├── backup_account_v2.dart  # 备份账户 API ✅
│   ├── command_v2.dart         # 命令管理 API ✅
│   ├── compose_v2.dart         # Docker Compose API ✅
│   ├── container_v2.dart       # 容器管理 API ✅
│   ├── cronjob_v2.dart         # 定时任务管理 API ✅
│   ├── dashboard_v2.dart       # 仪表板 API ✅
│   ├── database_v2.dart        # 数据库管理 API ✅
│   ├── disk_management_v2.dart # 磁盘管理 API ✅
│   ├── docker_v2.dart          # Docker 服务 API ✅
│   ├── file_v2.dart            # 文件管理 API ✅
│   ├── firewall_v2.dart        # 防火墙管理 API ✅
│   ├── host_v2.dart            # 主机管理 API ✅
│   ├── host_tool_v2.dart       # 主机工具 API ✅
│   ├── logs_v2.dart            # 日志系统 API ✅
│   ├── monitor_v2.dart         # 监控 API ✅
│   ├── openresty_v2.dart       # OpenResty API ✅
│   ├── process_v2.dart         # 进程管理 API ✅
│   ├── runtime_v2.dart         # 运行时管理 API ✅
│   ├── script_library_v2.dart  # 脚本库 API ✅
│   ├── setting_v2.dart         # 设置 API ✅
│   ├── snapshot_v2.dart        # 快照 API ✅
│   ├── ssh_v2.dart             # SSH 管理 API ✅
│   ├── ssl_v2.dart             # SSL 管理 API ✅
│   ├── system_group_v2.dart    # 系统组 API ✅
│   ├── task_log_v2.dart        # 任务日志 API ✅
│   ├── terminal_v2.dart        # 终端 API ✅
│   ├── toolbox_v2.dart         # 工具箱 API ✅
│   ├── update_v2.dart          # 更新管理 API ✅
│   ├── user_v2.dart            # 用户管理 API ✅
│   ├── website_v2.dart         # 网站管理 API ✅
│   └── website_group_v2.dart   # 网站组 API ✅
├── core/                # 核心功能
│   ├── config/         # 应用配置
│   │   ├── api_constants.dart    # API 常量和路径 ✅
│   │   ├── api_config.dart       # API 配置管理 ✅
│   │   └── logger_config.dart    # 日志配置 ✅
│   ├── network/        # 网络层
│   │   ├── dio_client.dart       # Dio HTTP 客户端包装器 ✅
│   │   ├── network_exceptions.dart # 自定义异常类型 ✅
│   │   └── interceptors/         # 请求拦截器
│   │       ├── auth_interceptor.dart   # 1Panel 身份认证 ✅
│   │       ├── logging_interceptor.dart # 请求/响应日志 ✅
│   │       ├── retry_interceptor.dart   # 自动重试 ✅
│   │       └── business_response_interceptor.dart # 业务逻辑处理 ✅
│   ├── services/       # 核心服务
│   │   └── logger/
│   │       ├── logger_service.dart  # 统一日志，具备 IP 脱敏 ✅
│   │       ├── log_file_manager_service.dart # 日志文件管理 ✅
│   │       └── log_preferences_service.dart  # 日志偏好设置 ✅
│   └── i18n/           # 国际化
│       └── app_localizations.dart   # 本地化 ✅
├── data/               # 数据层
│   └── models/         # 强类型数据模型（60+ 文件）
│       ├── common_models.dart       # 共享模型 ✅
│       ├── ai_models.dart           # AI 管理模型 ✅
│       ├── app_models.dart          # 应用模型 ✅
│       ├── auth_models.dart         # 身份认证模型 ✅
│       ├── backup_account_models.dart # 备份模型 ✅
│       ├── container_models.dart    # 容器模型 ✅
│       ├── cronjob_models.dart      # 定时任务模型 ✅
│       ├── dashboard_models.dart    # 仪表板模型 ✅
│       ├── database_models.dart     # 数据库模型 ✅
│       ├── file_models.dart         # 文件管理模型 ✅
│       ├── host_models.dart         # 主机管理模型 ✅
│       ├── logs_models.dart         # 日志系统模型 ✅
│       ├── system_group_models.dart # 系统组模型 ✅
│       └── ... (50+ 其他模型文件) # 完整模型覆盖
├── features/           # 功能模块
│   ├── ai/             # AI 管理功能
│   ├── dashboard/      # 仪表板功能
│   └── settings/       # 设置功能
├── pages/              # UI 页面
│   ├── server/         # 服务器配置页面
│   └── settings/       # 设置页面
├── shared/             # 共享组件
│   └── widgets/        # 可复用 UI 组件
│       └── app_card.dart           # Material Design 卡片
└── main.dart           # 应用入口点
```

## 🔧 开发

### 常用命令

```bash
# 安装依赖
flutter pub get

# 调试模式运行应用
flutter run

# 发布模式运行应用
flutter run --release

# 运行测试
flutter test

# 代码分析
flutter analyze

# 生产构建
flutter build apk --release
flutter build appbundle
```

### 代码生成

项目使用Retrofit进行类型安全的API客户端。修改API定义后，运行：

```bash
flutter packages pub run build_runner build
```

### 日志记录

应用使用全面的日志系统配合 `appLogger`。日志特性：
- **按构建模式过滤**: 调试模式详细，发布模式最简
- **按包分类**: 便于过滤
- **结构化**: 带有适当格式和上下文
- **隐私保护**: 自动脱敏公网 IP 地址
- **文件输出**: 所有环境均可导出日志文件

## 📝 开发须知

### 网络请求

所有网络请求都通过现代DioClient处理：
- **自动重试** (3次，指数退避)
- **错误处理** 使用自定义异常类型
- **请求日志** (仅调试模式)
- **1Panel服务器身份认证** 自动MD5 token生成和签名验证
- **API路径管理** 自动`/api/v2`前缀处理

### API集成

应用使用1Panel V2 API集成：
- **类型安全客户端** 由Retrofit生成
- **1Panel特定身份认证**:
  - MD5哈希生成: `MD5("1panel" + apiKey + timestamp)` (匹配服务器实现)
  - 自动时间戳和签名头部 (`1Panel-Token`, `1Panel-Timestamp`)
  - 动态token刷新和验证
  - **API路径前缀**: 所有端点使用`/api/v2`前缀
- **全面错误处理** 针对网络问题
- **多服务器支持** 管理多个1Panel实例

### 1Panel身份认证流程

1. **请求准备**: 每个API请求自动包含:
   - `1Panel-Token`: `("1panel" + apiKey + timestamp)`的MD5哈希
   - `1Panel-Timestamp`: 当前时间戳 (**秒级**) (服务器要求)
   - `Content-Type`: `application/json`
   - `Accept`: `application/json`
   - `User-Agent`: `1Panel-Flutter-App/1.0.0`

2. **MD5 Token生成** (匹配服务器端实现):
   ```dart
   // 服务器期望: MD5("1panel" + apiKey + timestamp)
   final authString = '1panel$apiKey$timestamp';
   final token = md5.convert(utf8.encode(authString)).toString();
   ```

3. **API路径结构**: 所有端点使用`/api/v2`前缀:
   ```dart
   // 示例: /api/v2/ai/ollama/model
   final fullPath = '/api/v2$endpoint';
   ```

4. **自动头部注入**: 所有必需头部自动添加到每个请求

### 代码质量

- **无 print 语句**: 使用统一日志系统
- **类型安全**: Retrofit 生成的 API 客户端
- **错误处理**: 全面异常处理
- **测试**: 使用 Mockito 测试网络操作
- **代码组织**: 清晰架构，职责分离
- **文件大小限制**: 所有代码文件 ≤1000 LOC

## 📄 文档

### 用户文档
- [部署指南](docs/zh-CN/DEPLOY.md) - 构建和部署应用
- [用户指南](docs/zh-CN/GUIDE.md) - 完整用户手册
- [测试指南](docs/zh-CN/TESTING.md) - 测试文档
- [隐私政策](docs/PRIVACY_POLICY.zh-CN.md)
- [服务条款](docs/TERMS_OF_SERVICE.md)
- [日志与数据保留政策](docs/LOGGING_POLICY.md)
- [第三方许可证声明](THIRD_PARTY_LICENSES.md)
- [安全策略](SECURITY.md)
- [贡献指南](CONTRIBUTING.md)
- [行为准则](CODE_OF_CONDUCT.md)

### API 文档
- [1Panel V2 API 规范](docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json) - 来自 1Panel 子模块的 Swagger/OpenAPI 规范

### 开发文档
- [开发文档](docs/development/)

## 🤝 贡献

1. 遵循既定代码规范
2. 使用统一日志系统 (无print语句)
3. 为新功能编写测试
4. 按需更新文档
5. 遵循清洁架构原则

## 📄 许可证

本项目采用 **GNU 通用公共许可证 v3.0 (GPL-3.0)**。

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

### GPL-3.0 意味着什么？

- ✅ **自由使用** - 将此软件用于任何目的
- ✅ **自由学习** - 访问和学习源代码
- ✅ **自由分享** - 重新分发软件副本
- ✅ **自由修改** - 修改并分发您的修改
- ⚠️ **必须公开源码** - 如果您分发本软件或其衍生作品，必须提供源代码
- ⚠️ **相同许可证** - 衍生作品必须采用 GPL-3.0 许可证
- ⚠️ **记录变更** - 必须记录您对软件所做的更改

详见 [LICENSE](LICENSE) 文件获取完整许可证文本。

## 🔗 相关项目

- [1Panel服务器](https://github.com/1Panel-dev/1Panel) - 1Panel服务器
- [Dio HTTP客户端](https://github.com/cfug/dio) - 我们使用的HTTP客户端库
- [Flutter](https://flutter.dev/) - UI框架
