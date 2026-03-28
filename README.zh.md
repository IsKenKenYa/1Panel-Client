# 1Panel Client

1Panel Client 是一个用于连接和管理一台或多台 1Panel 服务器的跨平台客户端。

---

**中文**: [README.zh.md](README.zh.md) | **English**: [README.md](README.md)

## 它是什么

- 一个面向 1Panel 用户的客户端，而不是只在浏览器里完成操作的管理方式
- 以多服务器切换、状态查看和常用运维入口为核心体验
- 让你在手机或桌面端也能快速处理日常 1Panel 管理任务

## 适合谁

- 需要统一管理多台 1Panel 服务器的用户
- 希望随时查看服务器状态并快速进入常用模块的运维用户
- 愿意体验客户端新交互并提供反馈的早期使用者

## 你可以做什么

- 在多台 1Panel 服务器之间快速切换
- 查看服务器状态与关键运行信息
- 进入文件、容器、应用、网站等常用模块处理日常任务
- 在移动端或桌面端获得更直接的操作入口，而不必总依赖浏览器

## 第一次使用

1. 在你的设备上安装客户端。
2. 准备好 1Panel 服务器地址和 API Key。
3. 在应用里添加第一台服务器。
4. 进入服务器详情，开始使用你需要的模块。

## 抢先体验版说明

- 当前 Android 版本主要用于抢先体验与收集用户反馈。
- 这个渠道暂不支持应用内自动更新。
- 后续版本将通过 GitHub Pre-release 持续发布。
- 当前官方唯一反馈渠道为 GitHub Issues：
  - [Issues](https://github.com/IsKenKenYa/1Panel-Client/issues)

## 🛠️ 技术栈

- **框架**: Flutter 3.16+ 配合 Material Design 3
- **网络**: **Dio HTTP客户端** 具备全面错误处理
- **状态管理**: Provider模式
- **认证**: 基于MD5 token的身份验证
- **存储**: Flutter Secure Storage + SharedPreferences
- **国际化**: 内置Flutter i18n (中文/英文)

## 开发规范

- 权威规范：`AGENTS.md`（硬性规则）与 `CLAUDE.md`（流程细则）。
- 提交前基线：`flutter analyze`、`dart run test_runner.dart unit`；涉及 API/网络或 UI 时分别运行 `integration`、`ui`。

## 🌐 网络架构

本项目采用**基于Dio的全面网络架构**，经过全面验证完成1Panel V2 API集成：

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

### 网络功能

- ✅ **自动重试**: 可配置的指数退避重试
- ✅ **错误处理**: 统一异常处理和自定义类型
- ✅ **日志记录**: 全面的请求/响应日志
- ✅ **1Panel身份认证**: 服务器兼容的MD5 token生成和正确的头部信息
- ✅ **API路径管理**: 所有端点自动处理`/api/v2`前缀
- ✅ **常量管理**: 统一的API配置和路径管理
- ✅ **超时管理**: 所有操作的可配置超时
- ✅ **多服务器支持**: 管理多个1Panel实例
- ✅ **完整V2 API覆盖**: 425+个端点，涵盖26个V2 API模块
- ✅ **强类型模型**: 31个全面的数据模型文件，支持JSON序列化
- ✅ **三轮验证**: 完整的API验证和生产就绪确认

### API集成状态

#### ✅ **完整实现概览**
**总覆盖**: 425+ API端点，来自官方1Panel V2文档的所有功能区域

**API文件**: 26个模块，完整实现所有功能
**数据模型**: 31个全面模型文件，涵盖所有功能区域并支持JSON序列化

#### ✅ **完整API实现 (全部26个模块)**
- **AI管理**: 完整的Ollama模型集成和GPU监控 (10个端点)
- **应用管理**: 完整的应用商店集成和生命周期管理 (21个端点)
- **备份管理**: 完整的备份操作和恢复功能 (14个端点)
- **容器管理**: 完整的Docker容器和镜像管理 (50+个端点)
- **数据库管理**: 带强类型的完整数据库操作 (34个端点)
- **文件管理**: 全面的文件操作和传输功能 (28个端点)
- **防火墙管理**: 完整的防火墙规则和端口管理 (12个端点)
- **网站管理**: 完整的网站、域名、SSL和代理管理 (65个端点)
- **系统组管理**: 完整的系统用户和组管理 (4个端点)
- **定时任务管理**: 带执行日志和统计的调度任务 (11个端点)
- **主机管理**: 完整的主机监控和系统管理 (18个端点)
- **监控管理**: 系统指标和告警管理 (6个端点)
- **运行时管理**: 完整的运行环境管理 (24个端点)
- **设置管理**: 系统配置和快照管理 (15个端点)
- **SSL管理**: SSL证书生命周期和ACME集成 (6个端点)
- **快照管理**: 系统备份快照和恢复 (9个端点)
- **终端管理**: SSH会话和命令执行 (6个端点)
- **用户管理**: 认证、角色和权限 (3个端点)
- **进程管理**: 进程监控和控制 (2个端点)
- **日志管理**: 系统日志和分析 (4个端点)
- **仪表板管理**: 系统仪表板和概览 (4个端点)
- **Docker管理**: Docker服务和集成管理 (8个端点)
- **OpenResty管理**: OpenResty配置和管理 (8个端点)

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
├── api/v2/              # 类型安全API客户端 (Retrofit生成)
│   ├── ai_v2.dart       # AI管理API
│   ├── app_v2.dart      # 应用管理API
│   └── ...              # 其他API模块
├── core/                # 核心功能
│   ├── config/         # 应用配置
│   │   ├── api_constants.dart    # API常量和路径
│   │   └── api_config.dart       # API配置管理
│   ├── network/        # 网络层
│   │   ├── dio_client.dart     # 基于Dio的现代HTTP客户端
│   │   ├── network_exceptions.dart  # 自定义异常类型
│   │   ├── api_client.dart     # API客户端包装器
│   │   └── api_client_manager.dart  # 客户端管理
│   │   └── interceptors/       # 请求拦截器
│   │       ├── auth_interceptor.dart   # 1Panel身份认证
│   │       ├── logging_interceptor.dart # 请求日志
│   │       └── retry_interceptor.dart  # 自动重试逻辑
│   ├── services/       # 核心服务 (日志等)
│   └── i18n/           # 国际化
├── data/               # 数据层
│   └── models/         # 数据模型
├── features/           # 功能模块
│   └── ai/             # AI管理功能
├── pages/              # UI页面
├── shared/             # 共享组件
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

应用使用comprehensive日志系统配合`appLogger`。日志特性：
- **按构建模式过滤**: 调试模式详细，发布模式最简
- **按包分类**: 便于过滤
- **结构化**: 带有适当格式和上下文

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

- **无print语句**: 使用统一日志系统
- **类型安全**: Retrofit生成的API客户端
- **错误处理**: 全面异常处理
- **测试**: 使用Mockito测试网络操作
- **代码组织**: 清晰架构，职责分离

## 📄 文档

### 用户文档
- [部署指南](docs/zh-CN/DEPLOY.md) - 构建和部署应用
- [用户指南](docs/zh-CN/GUIDE.md) - 完整用户手册
- [测试指南](docs/zh-CN/TESTING.md) - 测试文档

### API 文档
- [1Panel V2 API 规范](docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json) - 来自 1Panel 子模块的 Swagger/OpenAPI 规范

### 开发文档
- [开发文档](docs/development/)
- [阶段总计划（Phase 1 + Phase 2）](docs/development/modules/阶段2计划.md)

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
