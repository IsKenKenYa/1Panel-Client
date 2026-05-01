# Changelog

All notable changes to this project will be documented in this file. (本项目的所有重要更改都将记录在此文件中。)

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2026-05-02

### Overview

This release focuses on the desktop adaptation track, native platform wiring, terminal workflow completion, and a broad set of API, model, repository, and UI refinements across the app.

本版本重点围绕桌面端适配、原生平台接入、终端工作流补齐，以及全局 API、模型、仓库与 UI 的广泛改进。

### 概览（中文）

本次发布主要完成了桌面端适配阶段的核心合并：终端工作台与运行会话、Windows 原生桥接能力、平台自适应壳与模块路由、统一 API 响应解析与异常处理，以及文件、数据库、容器、网站、监控、日志、设置和安全模块的交互优化。

这是一个面向 `debug` 通道的预览版本，适合在目标平台上做完整性验证与反馈收集，不建议直接视作生产稳定版。

### Added

#### Terminal Workbench and Transport
- Added terminal runtime models for session state, appearance, and transport coordination.
- Added a terminal workbench provider and service layer to manage long-lived terminal sessions.
- Added WebSocket-based terminal transport, frame codec, and runtime session abstractions.

#### Windows Native Track
- Added a Windows native host bridge and capability whitelist for native channel access.
- Added Windows system tray integration and desktop bridge tests.
- Added Windows capability snapshots and UI bridge support for the native shell.

#### Adaptive Shell and Navigation
- Added a platform-adaptive shell page to route desktop and mobile surfaces through a unified host.
- Added module page factory and shell navigation helpers to keep module switching inside the shell.
- Added desktop/mobile server list split pages and a dedicated server list view model.

#### API Infrastructure
- Added a unified API response parser.
- Added API exception handling helpers and a WebSocket API connector.
- Added API client and repository updates for AI, container, database, file, host, logs, monitoring, security, settings, SSL, toolbox, website, and terminal domains.

#### API 基础设施（中文）
- 新增统一的 API 响应解析器，用于统一处理不同接口的响应结构。
- 新增 API 异常处理辅助能力与 WebSocket API 连接器。
- 扩展 AI、容器、数据库、文件、主机、日志、监控、安全、设置、SSL、工具箱、网站和终端等多个领域的 API 客户端与仓库实现。

#### Theme and Rendering Policy
- Added UI render mode and UI render policy abstractions to centralize rendering decisions.
- Added platform and keyboard utility helpers for desktop-oriented interaction handling.

#### Documentation and Workflow
- Added cross-platform UI governance documentation.
- Added native UI workflow documentation and desktop adaptation workflow documentation.
- Migrated issue templates to GitHub issue form format.

#### 文档与流程（中文）
- 新增跨平台 UI 治理文档，统一不同平台的设计与接入边界。
- 新增原生 UI 工作流文档与桌面端适配工作流文档。
- 将问题模板迁移为 GitHub issue form 格式，提升收集一致性。

### Changed

#### Release Channel and Build Metadata
- Kept the tag-driven release channel model with debug/beta/pre-release/release tag families.
- Continued injecting build metadata for source branch, commit SHA, and build date into release artifacts.

#### 发布通道与构建信息（中文）
- 继续沿用基于 tag 的发布通道模型，分别对应 debug、beta、pre-release 和 release。
- 继续向构建产物注入来源分支、提交 SHA 和构建时间，便于追踪与回溯。

#### App Shell and Server Experience
- Reworked shell navigation to support module switching inside the shared shell host.
- Refined the server selection and server-aware scaffold flow for desktop layouts.
- Split server list presentation into mobile and desktop views for clearer platform-specific UX.

#### 应用壳与服务器体验（中文）
- 重构壳层导航，保证模块切换始终在统一壳内完成。
- 优化服务器选择与服务器感知页面骨架，适配桌面布局。
- 将服务器列表拆分为移动端与桌面端展示，提升不同平台上的可读性与操作效率。

#### AI Module
- Updated AI agent, plugin, setting, and role models to support richer role and plugin metadata handling.
- Updated the AI provider flow and MCP-related provider behavior for the new model structure.

#### AI 模块（中文）
- 更新 AI 代理、插件、设置和角色模型，以支持更丰富的角色与插件元数据。
- 更新 AI Provider 流程与 MCP 相关行为，以适配新的模型结构。

#### Databases Module
- Refined database loading and remote loading flows.
- Improved filtering, display, and Redis-specific page composition.
- Updated database repository and user repository behaviors for the new contract surface.

#### 数据库模块（中文）
- 优化数据库加载与远程加载流程。
- 改进筛选、展示和 Redis 专用页面结构。
- 根据新的接口契约更新数据库仓库与数据库用户仓库行为。

#### Files Module
- Improved file page interaction, contextual menu behavior, and background handling.
- Refined file browser, recycle bin, transfer manager, and preview provider logic.
- Updated file data model handling for downloads and previews.

#### 文件模块（中文）
- 改进文件页面交互、上下文菜单行为和背景处理。
- 优化文件浏览器、回收站、传输管理器和预览 Provider 的逻辑。
- 更新文件数据模型对下载与预览的处理方式。

#### Containers and Orchestration
- Updated container service, provider, and repository interactions to match the expanded API surface.
- Improved compose, image, network, and volume provider flows.

#### 容器与编排（中文）
- 更新容器服务、Provider 与仓库交互，以匹配扩展后的 API 面。
- 改进 Compose、镜像、网络和卷相关 Provider 的流程。

#### Websites, SSL, and Security
- Updated website list, domain management, SSL center, and routing-related providers.
- Improved website certificate, configuration, lifecycle, and security access flows.
- Updated security provider and repository logic for the expanded authentication and verification surface.

#### 网站、SSL 与安全（中文）
- 更新网站列表、域名管理、SSL 中心以及路由相关 Provider。
- 优化网站证书、配置、生命周期和安全访问流程。
- 根据扩展后的认证与校验场景更新安全 Provider 与仓库逻辑。

#### Logs, Monitoring, and Host Tools
- Refined log provider behavior for system logs and task logs.
- Updated monitoring service/provider flows and runtime model support.
- Improved host assets, SSH, toolbox, and command management integration.

#### 日志、监控与主机工具（中文）
- 优化系统日志和任务日志的 Provider 行为。
- 更新监控服务/Provider 流程及运行时模型支持。
- 强化主机资产、SSH、工具箱和命令管理的集成。

#### Settings and System Pages
- Updated backup account, snapshot, terminal settings, system settings, and legal center pages.
- Adjusted settings service/controller behavior to support the new release channel and render policy.

#### 设置与系统页面（中文）
- 更新备份账户、快照、终端设置、系统设置和法律中心页面。
- 调整设置服务/控制器行为，以支持新的发布通道和渲染策略。

#### iOS and macOS Project Configuration
- Updated iOS project dependencies and project settings.
- Refined macOS shell configuration and release entitlement setup.

#### iOS 与 macOS 工程配置（中文）
- 更新 iOS 工程依赖与项目配置。
- 优化 macOS 壳层配置与 Release entitlements 设置。

### Fixed

- Improved API test error handling and logging output for more reliable diagnostics.
- Fixed several desktop UI interaction and layout issues across files, database, website, and shell surfaces.
- Reduced native bridge and channel wiring inconsistencies in the Windows track.
- Improved response parsing consistency across the API layer.

### 修复（中文）

- 改进 API 测试的错误处理与日志输出，提高诊断可靠性。
- 修复文件、数据库、网站和壳层等页面上的若干桌面端交互与布局问题。
- 减少 Windows 原生桥接与通道接线中的不一致问题。
- 提升 API 层响应解析的一致性。

### Security

- Reworked MFA request and response models to keep authentication state consistent and easier to validate.
- Strengthened signing-related release flow assumptions by keeping build metadata and channel mapping explicit.

### 安全（中文）

- 重构 MFA 请求与响应模型，使认证状态更一致、更易验证。
- 通过明确构建元数据与通道映射，强化与签名相关的发布流程假设。

### Performance

- Reduced duplicate parsing and error-handling work in the shared API client layer.
- Split long-lived terminal responsibilities into dedicated transport and session abstractions to reduce coupling.

### 性能（中文）

- 减少共享 API 客户端层重复解析与错误处理的开销。
- 将长期存在的终端职责拆分为独立的传输与会话抽象，降低耦合。

### UI/UX

- Improved desktop shell navigation, module switching, and server-aware layouts.
- Refined file, database, container, website, and dashboard interaction surfaces.
- Adjusted UI composition for more consistent desktop behavior across cached pages and native tracks.

### UI/UX（中文）

- 改进桌面壳层导航、模块切换和服务器感知布局。
- 优化文件、数据库、容器、网站和仪表板的交互层。
- 调整 UI 组合方式，让缓存页面与原生轨道在桌面上的行为更一致。

### Compatibility

- This release remains aligned with the 1Panel V2 API family and the current desktop adaptation track.
- Desktop native features should be validated against the target platform configuration before production use.

### 兼容性（中文）

- 本次发布仍与 1Panel V2 API 家族以及当前桌面端适配轨道保持一致。
- 桌面原生功能在进入生产使用前，应先在目标平台配置下完成验证。

### Known Issues

- iOS, macOS, and Windows release builds may fail if platform signing or local toolchain prerequisites are incomplete.
- Some native UI and bridge features are still evolving and may require platform-specific validation.

### 已知问题（中文）

- 如果平台签名或本地工具链前置条件不完整，iOS、macOS 和 Windows 的 Release 构建可能失败。
- 部分原生 UI 与桥接功能仍在持续演进中，可能需要按平台进行额外验证。

### Upgrade Notes

- Keep service-side and client-side versions aligned when validating API compatibility.
- Re-run login, server switching, terminal, and file-management flows after upgrading because these areas changed the most.
- If you use release automation, ensure the `debug-*` tag is pushed from `dev` so the Android workflow accepts it.

### 升级提示（中文）

- 在验证 API 兼容性时，请保持服务端与客户端版本尽量对齐。
- 升级后建议重新走一遍登录、服务器切换、终端和文件管理流程，因为这些区域变更最多。
- 如果你使用发布自动化，请确保 `debug-*` tag 从 `dev` 推出，这样 Android 工作流才会接受。

### Module Highlights

#### Terminal
- Introduced terminal runtime models, workbench provider, transport layer, and runtime session support.

#### Shell
- Added adaptive shell routing and module page creation helpers.

#### Windows
- Added native host bridge, capability whitelist, and tray integration.

#### Files
- Improved browser, preview, recycle bin, transfer, and contextual menu flows.

#### Databases
- Refined load flows, remote loading, Redis-specific presentation, and related repositories.

#### Websites
- Enhanced domain, SSL, routing, lifecycle, and configuration flows.

#### Logs and Monitoring
- Updated system/task logs and monitoring runtime support.

#### Settings and Security
- Refined system settings, backup accounts, snapshot, terminal settings, and MFA data structures.

#### API and Infrastructure
- Added unified response parsing, exception handling, and WebSocket connector infrastructure.

## [0.5.0-alpha.2+2] - 2026-04-02

### Changed

- Switched Android prerelease automation from branch-triggered builds to tag-driven releases using `debug-*`, `beta-*`, `pre-release-*`, and `release-*`.
- Added build metadata injection for release artifacts, including source branch, commit SHA, and UTC build timestamp.
- Updated About page build information to show release channel, source branch, commit ID, and build date for easier debugging and feedback collection.
- Prepared the `2026-04-02` internal debug release flow on `dev` for local tagging and artifact publishing.

### Fixed

- Wired Android release signing in the Kotlin Gradle script so CI-generated APKs can use the configured upload keystore instead of always falling back to debug signing.

### Docs

- Updated release workflow documentation to reflect the `dev` aggregation branch and tag-based APK publishing strategy.

## [0.5.0-alpha.1+1] - 2026-03-30

### 🎉 Major Milestone: Complete 1Panel V2 API Integration (重大里程碑：完整的 1Panel V2 API 集成)

This release marks the completion of comprehensive 1Panel V2 API integration with **100% coverage** of all documented endpoints across 34 API modules (425+ endpoints). The project has transitioned from initial development to a production-ready state with complete feature implementation.

本版本标志着完整的 1Panel V2 API 集成完成，**100% 覆盖**所有已记录的端点，涵盖 34 个 API 模块（425+ 个端点）。项目已从初始开发阶段过渡到生产就绪状态，具备完整的功能实现。

### Added (新增功能)

#### 🤖 AI Management Module (AI 管理模块) - NEW
- **Ollama Model Management**: Complete lifecycle management for Ollama AI models including installation, updates, and removal
- **GPU Monitoring**: Real-time GPU usage monitoring and statistics for AI workloads
- **AI Agent Configuration**: Browser configuration and AI agent settings management
- **Domain Binding**: Domain name binding for AI services with automatic configuration
- **API Coverage**: 10 endpoints fully implemented (`/ai/ollama/*`, `/ai/gpu/*`, `/ai/domain/*`)

**Ollama 模型管理**：完整的 Ollama AI 模型生命周期管理，包括安装、更新和删除
**GPU 监控**：AI 工作负载的实时 GPU 使用监控和统计
**AI 代理配置**：浏览器配置和 AI 代理设置管理
**域名绑定**：AI 服务的域名绑定，支持自动配置
**API 覆盖**：10 个端点完整实现

#### 🗄️ Database Management Module (数据库管理模块) - ENHANCED
- **Multi-Database Support**: Full support for MySQL/MariaDB, PostgreSQL, and Redis
- **Database Operations**: Create, update, delete, start, stop, and restart operations
- **Backup Management**: Complete backup and restore functionality with scheduling
- **User Management**: Database user creation, permission management, and access control
- **Remote Access**: Remote database connection configuration and management
- **API Coverage**: 34 endpoints (`/databases/*`, `/databases/mysql/*`, `/databases/postgresql/*`, `/databases/redis/*`)

**多数据库支持**：完整支持 MySQL/MariaDB、PostgreSQL 和 Redis
**数据库操作**：创建、更新、删除、启动、停止和重启操作
**备份管理**：完整的备份和恢复功能，支持计划任务
**用户管理**：数据库用户创建、权限管理和访问控制
**远程访问**：远程数据库连接配置和管理
**API 覆盖**：34 个端点

#### 🔥 Firewall Management Module (防火墙管理模块) - ENHANCED
- **Firewall Status**: Real-time firewall status monitoring and control
- **Rule Management**: Create, edit, delete, and reorder firewall rules
- **IP Management**: IP whitelist/blacklist management with batch operations
- **Port Management**: Port forwarding and access control configuration
- **Strategy Management**: Firewall strategy configuration and policy enforcement
- **API Coverage**: 15 endpoints (`/hosts/firewall/*`)

**防火墙状态**：实时防火墙状态监控和控制
**规则管理**：创建、编辑、删除和重新排序防火墙规则
**IP 管理**：IP 白名单/黑名单管理，支持批量操作
**端口管理**：端口转发和访问控制配置
**策略管理**：防火墙策略配置和策略执行
**API 覆盖**：15 个端点

#### 🌐 Website Management Module (网站管理模块) - ENHANCED
- **Website Lifecycle**: Complete website creation, configuration, and management
- **Domain Management**: Domain binding, validation, and batch operations
- **SSL Certificate Management**: Certificate application, renewal, and binding to websites
- **Configuration Center**: Structured configuration management for website settings
- **Routing Rules**: Advanced routing configuration and proxy settings
- **Default Site**: Default website configuration and management
- **Group Management**: Website grouping and organization
- **Batch Operations**: Bulk operations for multiple websites
- **API Coverage**: 65 endpoints (`/websites/*`, `/websites/domains/*`, `/websites/ssl/*`, `/websites/config/*`)

**网站生命周期**：完整的网站创建、配置和管理
**域名管理**：域名绑定、验证和批量操作
**SSL 证书管理**：证书申请、续期和网站绑定
**配置中心**：网站设置的结构化配置管理
**路由规则**：高级路由配置和代理设置
**默认站点**：默认网站配置和管理
**分组管理**：网站分组和组织
**批量操作**：多个网站的批量操作
**API 覆盖**：65 个端点

#### 🔐 Security & Gateway Module (安全与网关模块) - ENHANCED
- **Panel SSL**: Panel SSL certificate management and configuration
- **Website SSL**: Website SSL certificate center with ACME integration
- **OpenResty Management**: OpenResty configuration, modules, and build management
- **HTTPS Configuration**: HTTPS settings and security policy management
- **Certificate Lifecycle**: Complete certificate lifecycle from application to renewal
- **API Coverage**: 25 endpoints (`/settings/ssl/*`, `/websites/ssl/*`, `/openresty/*`)

**面板 SSL**：面板 SSL 证书管理和配置
**网站 SSL**：网站 SSL 证书中心，集成 ACME
**OpenResty 管理**：OpenResty 配置、模块和构建管理
**HTTPS 配置**：HTTPS 设置和安全策略管理
**证书生命周期**：从申请到续期的完整证书生命周期
**API 覆盖**：25 个端点

#### 🐳 Container Orchestration Module (容器编排模块) - ENHANCED
- **Docker Compose**: Compose file management, deployment, and orchestration
- **Image Management**: Image pull, push, build, and registry operations
- **Network Management**: Docker network creation, configuration, and management
- **Volume Management**: Volume creation, mounting, and lifecycle management
- **Container Operations**: Enhanced container lifecycle operations and monitoring
- **API Coverage**: 50+ endpoints (`/containers/*`, `/compose/*`, `/docker/*`)

**Docker Compose**：Compose 文件管理、部署和编排
**镜像管理**：镜像拉取、推送、构建和仓库操作
**网络管理**：Docker 网络创建、配置和管理
**卷管理**：卷创建、挂载和生命周期管理
**容器操作**：增强的容器生命周期操作和监控
**API 覆盖**：50+ 个端点

#### 📁 File Management Module (文件管理模块) - ENHANCED
- **File Browser**: Complete file browsing with search and filtering
- **File Operations**: Create, edit, delete, copy, move, compress, and decompress
- **Upload/Download**: File upload and download with progress tracking
- **Recycle Bin**: Deleted file recovery and permanent deletion
- **Transfer Manager**: Background transfer management with queue and history
- **Favorites**: File and folder bookmarking for quick access
- **Mount Points**: External storage mounting and management
- **File Preview**: Preview support for text, images, and other file types
- **Encoding Conversion**: File encoding conversion functionality
- **Remarks**: File and folder remark/note management
- **API Coverage**: 28 endpoints (`/files/*`)

**文件浏览器**：完整的文件浏览，支持搜索和筛选
**文件操作**：创建、编辑、删除、复制、移动、压缩和解压
**上传/下载**：文件上传和下载，支持进度跟踪
**回收站**：已删除文件恢复和永久删除
**传输管理器**：后台传输管理，支持队列和历史记录
**收藏夹**：文件和文件夹书签，快速访问
**挂载点**：外部存储挂载和管理
**文件预览**：支持文本、图片和其他文件类型预览
**编码转换**：文件编码转换功能
**备注**：文件和文件夹备注/笔记管理
**API 覆盖**：28 个端点

#### ⚙️ Runtime Management Module (运行时管理模块) - NEW
- **Multi-Language Support**: PHP, Node.js, Python, Go, and Java runtime management
- **PHP Extensions**: PHP extension installation, configuration, and management
- **PHP Configuration**: FPM configuration, container settings, and file editing
- **Supervisor**: Process management with Supervisor integration
- **Node Modules**: Node.js module installation and management
- **Node Scripts**: Package.json script execution and management
- **Runtime Operations**: Create, update, delete, start, stop, and sync operations
- **API Coverage**: 24 endpoints (`/runtimes/*`, `/runtimes/php/*`, `/runtimes/node/*`, `/runtimes/supervisor/*`)

**多语言支持**：PHP、Node.js、Python、Go 和 Java 运行时管理
**PHP 扩展**：PHP 扩展安装、配置和管理
**PHP 配置**：FPM 配置、容器设置和文件编辑
**Supervisor**：进程管理，集成 Supervisor
**Node 模块**：Node.js 模块安装和管理
**Node 脚本**：package.json 脚本执行和管理
**运行时操作**：创建、更新、删除、启动、停止和同步操作
**API 覆盖**：24 个端点

#### 💾 Backup Management Module (备份管理模块) - ENHANCED
- **Backup Accounts**: Backup account configuration for local and remote storage
- **Backup Operations**: Manual and scheduled backup operations
- **Backup Records**: Complete backup history and record management
- **Recovery Operations**: File and database recovery from backups
- **Storage Providers**: Support for multiple storage providers (S3, OSS, etc.)
- **API Coverage**: 14 endpoints (`/backups/*`)

**备份账户**：本地和远程存储的备份账户配置
**备份操作**：手动和计划备份操作
**备份记录**：完整的备份历史和记录管理
**恢复操作**：从备份恢复文件和数据库
**存储提供商**：支持多个存储提供商（S3、OSS 等）
**API 覆盖**：14 个端点

#### 📋 Cronjob & Script Management (定时任务与脚本管理) - NEW
- **Cronjob Management**: Create, edit, delete, and execute scheduled tasks
- **Execution Records**: Complete execution history with logs and status
- **Script Library**: Script storage, management, and execution
- **Task Types**: Support for various task types (backup, cleanup, custom scripts)
- **API Coverage**: 12 endpoints (`/cronjobs/*`, `/scripts/*`)

**定时任务管理**：创建、编辑、删除和执行计划任务
**执行记录**：完整的执行历史，包含日志和状态
**脚本库**：脚本存储、管理和执行
**任务类型**：支持各种任务类型（备份、清理、自定义脚本）
**API 覆盖**：12 个端点

#### 📊 Log Management Module (日志管理模块) - NEW
- **System Logs**: System log viewing, search, and filtering
- **Task Logs**: Task execution log details and history
- **Log Center**: Unified log management interface
- **Log Export**: Log export and download functionality
- **API Coverage**: 8 endpoints (`/logs/*`, `/logs/task/*`)

**系统日志**：系统日志查看、搜索和筛选
**任务日志**：任务执行日志详情和历史
**日志中心**：统一的日志管理界面
**日志导出**：日志导出和下载功能
**API 覆盖**：8 个端点

#### 🖥️ Host & Process Management (主机与进程管理) - NEW
- **Host Assets**: Host information and asset management
- **SSH Management**: SSH configuration, certificates, logs, and sessions
- **Process Management**: System process monitoring, control, and details
- **Command Management**: Command execution, history, and management
- **API Coverage**: 25 endpoints (`/hosts/*`, `/ssh/*`, `/processes/*`, `/commands/*`)

**主机资产**：主机信息和资产管理
**SSH 管理**：SSH 配置、证书、日志和会话
**进程管理**：系统进程监控、控制和详情
**命令管理**：命令执行、历史和管理
**API 覆盖**：25 个端点

#### 🛠️ Toolbox Module (工具箱模块) - NEW
- **Device Management**: System device monitoring and management
- **Disk Management**: Disk operations and space management
- **ClamAV**: Antivirus scanning and malware detection
- **Fail2ban**: Intrusion prevention and IP banning
- **FTP Management**: FTP server configuration and management
- **API Coverage**: 18 endpoints (`/toolbox/*`)

**设备管理**：系统设备监控和管理
**磁盘管理**：磁盘操作和空间管理
**ClamAV**：病毒扫描和恶意软件检测
**Fail2ban**：入侵防护和 IP 封禁
**FTP 管理**：FTP 服务器配置和管理
**API 覆盖**：18 个端点

#### 📈 Dashboard & Monitoring (仪表板与监控) - ENHANCED
- **Real-time Monitoring**: CPU, memory, disk, and network I/O monitoring
- **System Overview**: System status and key metrics at a glance
- **Dashboard Memo**: Dashboard memo and note functionality
- **Chart Visualization**: Interactive charts for system metrics
- **API Coverage**: 15 endpoints (`/dashboard/*`, `/monitor/*`)

**实时监控**：CPU、内存、磁盘和网络 I/O 监控
**系统概览**：系统状态和关键指标一览
**仪表盘备忘录**：仪表盘备忘录和笔记功能
**图表可视化**：系统指标的交互式图表
**API 覆盖**：15 个端点

#### 🔧 System Settings Module (系统设置模块) - ENHANCED
- **System Configuration**: Panel settings and system configuration
- **Security Settings**: Security verification and access control
- **Snapshot Management**: System snapshot creation and restoration
- **Update Management**: Panel update and upgrade functionality
- **Passkey Management**: Passkey authentication management
- **Menu Configuration**: Custom menu and navigation settings
- **API Coverage**: 20 endpoints (`/settings/*`, `/core/settings/*`)

**系统配置**：面板设置和系统配置
**安全设置**：安全验证和访问控制
**快照管理**：系统快照创建和恢复
**更新管理**：面板更新和升级功能
**Passkey 管理**：Passkey 认证管理
**菜单配置**：自定义菜单和导航设置
**API 覆盖**：20 个端点

#### 🏗️ Architecture & Infrastructure (架构与基础设施)
- **Complete API Coverage**: 34 API modules with 425+ endpoints fully implemented
- **Strong Type System**: 114 data model files (60+ main models + 54 sub-models) with complete JSON serialization
- **Repository Pattern**: Unified repository layer for all data access
- **Service Layer**: Business logic separation with service layer implementation
- **Provider Pattern**: State management with Provider pattern
- **Layered Architecture**: Strict one-way dependencies (Presentation → State → Service/Repository → API/Infra)
- **Code Quality**: All files follow 1000 LOC hard limit
- **Test Coverage**: Unit tests, integration tests, and UI tests
- **Privacy Protection**: Automatic IP masking in logs
- **Internationalization**: Complete Chinese/English support

**完整 API 覆盖**：34 个 API 模块，425+ 个端点完整实现
**强类型系统**：114 个数据模型文件（60+ 个主模型 + 54 个子模型），完整的 JSON 序列化
**仓储模式**：统一的仓储层用于所有数据访问
**服务层**：业务逻辑分离，实现服务层
**Provider 模式**：使用 Provider 模式进行状态管理
**分层架构**：严格的单向依赖（Presentation → State → Service/Repository → API/Infra）
**代码质量**：所有文件遵循 1000 LOC 硬上限
**测试覆盖**：单元测试、集成测试和 UI 测试
**隐私保护**：日志中自动 IP 脱敏
**国际化**：完整的中英文支持

### Changed (更改)

#### 🎨 UI/UX Improvements (UI/UX 改进)
- **Container Module**: Optimized container card design and statistics view layout
- **Server Details**: Enhanced server details page with improved navigation and module organization
- **File Management**: Improved file browser interface with better search and filtering
- **Website Management**: Restructured website configuration center with tabbed interface
- **Mobile Optimization**: Enhanced mobile-first design with tablet support
- **App Icon**: Updated app icon and branding resources

**容器模块**：优化容器卡片设计和统计视图布局
**服务器详情**：增强服务器详情页面，改进导航和模块组织
**文件管理**：改进文件浏览器界面，更好的搜索和筛选
**网站管理**：重构网站配置中心，采用标签页界面
**移动优化**：增强移动优先设计，支持平板
**应用图标**：更新应用图标和品牌资源

#### ⚡ Performance & Optimization (性能与优化)
- **Settings Module**: Optimized availability check and update logic
- **Code Structure**: Improved code organization and readability
- **Log System**: Enhanced logging system with better formatting and privacy protection
- **File Size Management**: Enforced 1000 LOC limit across all code files
- **Dependency Updates**: Updated all dependencies to latest stable versions

**设置模块**：优化可用性检查和更新逻辑
**代码结构**：改进代码组织和可读性
**日志系统**：增强日志系统，更好的格式化和隐私保护
**文件大小管理**：在所有代码文件中强制执行 1000 LOC 限制
**依赖更新**：更新所有依赖到最新稳定版本

#### 🔄 Refactoring (重构)
- **Dashboard Module**: Refactored dashboard provider with service layer separation
- **Auth Module**: Separated authentication logic into repository, service, and session store
- **File Module**: Split files provider into multiple specialized providers (browser, recycle, transfer, preview)
- **Website Module**: Added repository layer for website, domain, and configuration management
- **Security Module**: Implemented repository pattern for SSL and OpenResty management

**仪表板模块**：重构仪表板 provider，分离服务层
**认证模块**：将认证逻辑分离为仓储、服务和会话存储
**文件模块**：将文件 provider 拆分为多个专用 provider（浏览器、回收站、传输、预览）
**网站模块**：为网站、域名和配置管理添加仓储层
**安全模块**：为 SSL 和 OpenResty 管理实现仓储模式

### Fixed (修复)

#### 🐛 Bug Fixes (Bug 修复)
- **Command Module**: Fixed API contract deviations and parameter validation
- **File Preview**: Fixed size formatting issues in file preview and upload history pages
- **Database Module**: Fixed Redis creation entry and user management operations
- **Firewall Module**: Fixed rule ordering and batch operation issues
- **Website Module**: Fixed domain validation and default site configuration
- **Container Module**: Fixed container statistics and log viewing issues

**命令模块**：修复 API 契约偏差和参数验证
**文件预览**：修复文件预览和上传历史页面的大小格式化问题
**数据库模块**：修复 Redis 创建入口和用户管理操作
**防火墙模块**：修复规则排序和批量操作问题
**网站模块**：修复域名验证和默认站点配置
**容器模块**：修复容器统计和日志查看问题

#### 🔧 Technical Fixes (技术修复)
- **Logging System**: Removed unnecessary stack traces from log output
- **IP Masking**: Implemented automatic public IP masking in all logs
- **File Output**: Enabled log file output for all build modes
- **Route Management**: Unified route constants to avoid string route drift
- **Settings Boundary**: Clarified settings page semantic boundaries (client vs server settings)

**日志系统**：从日志输出中移除不必要的堆栈跟踪
**IP 脱敏**：在所有日志中实现自动公网 IP 脱敏
**文件输出**：为所有构建模式启用日志文件输出
**路由管理**：统一路由常量，避免字符串路由漂移
**设置边界**：明确设置页面语义边界（客户端 vs 服务器设置）

### 📊 Statistics (统计数据)

#### API Implementation (API 实现)
- **Total API Modules**: 34 modules / 34 个模块
- **Total Endpoints**: 425+ endpoints / 425+ 个端点
- **API Coverage**: 100% of documented V2 API / 100% 覆盖已记录的 V2 API
- **Data Models**: 114 model files (60+ main + 54 sub-models) / 114 个模型文件（60+ 个主模型 + 54 个子模型）

#### Code Quality (代码质量)
- **Total UI Pages**: 100+ pages / 100+ 个页面
- **Main Navigation**: 8 modules / 8 个主导航模块
- **Feature Modules**: 22 complete modules / 22 个完整模块
- **Backend Modules**: 12 integrated modules / 12 个集成模块
- **LOC Compliance**: 100% files ≤ 1000 LOC / 100% 文件 ≤ 1000 LOC

#### Testing (测试)
- **Test Types**: Unit, Integration, UI tests / 单元测试、集成测试、UI 测试
- **Test Runner**: Unified test runner with category support / 统一测试运行器，支持分类
- **Gate Checks**: flutter analyze, unit, ui, integration / flutter analyze、单元、UI、集成

### 🎯 Development Status (开发状态)

#### Phase 1 (Complete / 已完成)
- ✅ Group management / 分组管理
- ✅ Host asset + SSH + Process / 主机资产 + SSH + 进程
- ✅ Command management / 命令管理
- ✅ Cronjob + Script library / 定时任务 + 脚本库
- ✅ Backup management / 备份管理
- ✅ Logs + Task log / 日志 + 任务日志
- ✅ Runtime management (including PHP/Node deep features) / 运行时管理（包括 PHP/Node 深度功能）

#### Phase 2 (Complete / 已完成)
- ✅ Database + Firewall / 数据库 + 防火墙
- ✅ Website Core (website + domain + config) / 网站核心（网站 + 域名 + 配置）
- ✅ Security & Gateway (panel SSL + website SSL + OpenResty) / 安全与网关（面板 SSL + 网站 SSL + OpenResty）
- ✅ Orchestration + AI (compose + image + network + volume + AI) / 编排 + AI（compose + 镜像 + 网络 + 卷 + AI）
- ✅ Core Refactor (dashboard + auth + file) / 核心重构（仪表板 + 认证 + 文件）

#### Current Status (当前状态)
- **Project Status**: Production Ready / 生产就绪
- **API Coverage**: 100% Complete / 100% 完成
- **Core Features**: All Implemented / 全部实现
- **Next Phase**: User feedback and continuous optimization / 用户反馈和持续优化

---

## [Unreleased]

### Planned Features (计划功能)
- User experience optimization / 用户体验优化
- Performance improvements for large datasets / 大数据集性能改进
- Offline support and synchronization / 离线支持和同步
- Extended language support / 扩展语言支持
- Community feedback integration / 社区反馈集成

---

*Last updated (最后更新): 2026-04-02*
