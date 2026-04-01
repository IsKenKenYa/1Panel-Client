# Open1PanelApp 项目规则

## UI框架与跨平台策略
- **Android 与 Android 平板**：继续使用 Dart 代码渲染 **Material Design 3 (MDUI3)** 规范。
- **其他平台 (macOS, iOS, Windows, Linux)**：使用各自平台的原生代码实现原生系统的原生 UI 和原汁原味的交互逻辑（如 macOS 26 的液态玻璃）。允许通过设置切换回使用 Dart 代码渲染的 MDUI3。
- **macOS 特别说明**：目前先规划和完成 macOS，主要针对 **macOS 26** 进行适配，稍微适配 macOS 15（至少需要可以打开）。

## Dart 核心架构层级规范
除了平台特定的原生 UI 层（Presentation Layer）之外，项目主要包含以下几个核心架构层级，**全部使用 Dart 代码实现**：

### 状态管理层 (State Layer)
- **技术选型**：项目默认使用 `Provider` 进行状态管理。
- **职责**：负责连接 UI 层与业务逻辑层，处理界面状态的流转。禁止在 Widget 的 `build()` 方法中编写业务逻辑，必须下沉到 Provider/ViewModel。
- **代码位置**：主要分布在 `lib/features/*/providers/` 或各模块的 `*_provider.dart` 文件中。

### 服务与业务逻辑层 (Service Layer)
- **职责**：处理核心的业务规则、复杂的数据加工、文件流转等，并协调不同的 Repository。
- **代码位置**：包括核心服务（如 `lib/core/services/` 下的缓存、日志、存储等服务）以及各业务模块的服务（如 `app_service.dart`）。

### 数据仓库层 (Repository Layer)
- **职责**：作为数据的单一事实来源（Single Source of Truth），对上层屏蔽数据的具体来源（网络接口或本地缓存）。
- **规则限制**：UI 层严格禁止直接调用底层 API，必须通过 Repository 获取和提交数据。
- **代码位置**：集中管理在 `lib/data/repositories/` 目录下。

### 数据模型层 (Data Model Layer)
- **职责**：定义应用中的实体、请求参数、响应结构等数据结构，配合代码生成工具使用。
- **代码位置**：集中在 `lib/data/models/` 目录下。

### API 与基础设施层 (API/Infra Layer)
- **职责**：处理所有与外部系统的底层通信，包括 HTTP 请求、WebSocket、本地持久化存储以及原生平台交互。
- **核心模块**：
  - **网络层**：`lib/api/v2/`（Retrofit 客户端）以及 `lib/core/network/`。
  - **存储层**：`lib/core/storage/`（Hive 本地存储）。
  - **通道层**：`lib/core/channel/`（与原生平台的交互）。

### 核心配置与全局支持层 (Core/Config Layer)
- **职责**：提供应用运行时的基础配置、路由、主题系统、国际化等全局支撑。
- **代码位置**：
  - **路由**：`lib/config/app_router.dart`。
  - **主题**：`lib/core/theme/`。
  - **国际化**：`lib/core/i18n/`（强制使用 ARB 文件，禁止硬编码）。

## 代码规范
- 使用 `const` 构造函数优化性能
- 使用 `Theme.of(context)` 获取主题色，禁止硬编码颜色
- 支持深色模式，使用 `colorScheme`

## 文件组织
```
lib/
├── core/           # 核心配置、主题、常量
├── data/           # 数据模型、仓库
├── features/       # 功能模块
└── shared/         # 共享组件
```

## 详细规范
- [UI设计规范](ui_rules.md)
- [开发规范](dev_rules.md)
