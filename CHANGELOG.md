# Changelog

All notable changes to this project will be documented in this file. (本项目的所有重要更改都将记录在此文件中。)

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0-alpha.1+1] - 2026-03-30

### Added (新增)

#### AI Management (AI 管理模块)
- AI Agent management functionality / AI 代理管理功能
- Browser configuration management / 浏览器配置管理
- Ollama model integration and GPU monitoring (10 endpoints) / Ollama 模型集成和 GPU 监控 (10 个端点)

#### System Settings (系统设置)
- Dashboard memo functionality / 仪表盘备忘录功能
- Passkey management functionality / Passkey 管理功能
- System configuration and snapshot management (15 endpoints) / 系统配置和快照管理 (15 个端点)

#### Toolbox (工具箱)
- ClamAV antivirus scanning management / ClamAV 病毒扫描管理
- Fail2ban intrusion prevention management / Fail2ban 入侵防护管理
- FTP management services / FTP 管理服务

#### Runtime Management (运行时管理)
- PHP extension management / PHP 扩展管理
- Node module management / Node 模块管理
- Supervisor process management / Supervisor 进程管理
- Complete runtime environment management (24 endpoints) / 完整运行环境管理 (24 个端点)

#### Website Management (网站管理)
- Batch operations functionality / 批量操作功能
- SSL account management / SSL 账户管理
- Complete website, domain, SSL, and proxy management (65 endpoints) / 完整的网站、域名、SSL 和代理管理 (65 个端点)

#### Container Management (容器管理)
- Enhanced container functions and UI optimization / 增强容器功能和 UI 优化
- Optimized container cards and statistics views / 容器卡片和统计视图优化
- Complete Docker container and image management (50+ endpoints) / 完整 Docker 容器和镜像管理 (50+ 个端点)

#### File Management (文件管理)
- Recycle bin functionality / 回收站功能
- Transfer manager / 传输管理器
- Comprehensive file operations and transfer functionality (28 endpoints) / 全面文件操作和传输功能 (28 个端点)

#### Server Management (服务器管理)
- Add/delete server functionality / 添加删除功能
- Group center / 分组中心
- Complete host monitoring and system management (18 endpoints) / 完整的主机监控和系统管理 (18 个端点)

#### Database Management (数据库管理)
- Complete database operations (34 endpoints) / 完整的数据库操作 (34 个端点)
- Support for MySQL/MariaDB, PostgreSQL, Redis / 支持 MySQL/MariaDB、PostgreSQL、Redis

#### Backup Management (备份管理)
- Complete backup operations and recovery functionality (14 endpoints) / 完整的备份操作和恢复功能 (14 个端点)

#### Other Additions (其他新增)
- Complete coverage of 425+ API endpoints (34 V2 API modules) / 完整的 425+ API 端点覆盖（34 个 V2 API 模块）
- 60+ comprehensive data model files with JSON serialization / 60+ 个全面的数据模型文件，支持 JSON 序列化
- Four rounds of API verification, confirmed production-ready / 四轮 API 验证，生产就绪状态确认
- Unified logging system with privacy protection (IP masking) / 统一日志系统，具备隐私保护（IP 脱敏）
- All API modules: AI, App, Auth, Backup, Command, Container, Compose, Cronjob, Dashboard, Database, Disk, Docker, File, Firewall, Host, Host Tool, Logs, Monitor, OpenResty, Process, Runtime, Script Library, Setting, Snapshot, SSH, SSL, System Group, Task Log, Terminal, Toolbox, Update, User, Website, Website Group / 所有 API 模块：AI、应用、认证、备份、命令、容器、Compose、定时任务、仪表板、数据库、磁盘、Docker、文件、防火墙、主机、主机工具、日志、监控、OpenResty、进程、运行时、脚本库、设置、快照、SSH、SSL、系统组、任务日志、终端、工具箱、更新、用户、网站、网站组

### Changed (更改)

#### UI Optimization (UI 优化)
- Optimized container card and statistics view design / 优化容器卡片和统计视图 UI 设计
- Optimized server details page and routing management / 优化服务器详情页面和路由管理
- Optimized container module functionality and layout / 优化容器模块功能并优化界面布局
- Updated app icon and related resources / 更新应用图标和相关资源

#### System Optimization (系统优化)
- Optimized availability check and update logic in the settings module / 优化系统设置模块的可用性检查与更新逻辑
- Optimized code structure and readability / 优化代码结构和可读性
- Implemented automatic public IP masking in logs / 实现日志中公网 IP 自动脱敏
- Optimized log output format (removed unnecessary stack traces) / 优化日志输出格式（移除不必要的堆栈跟踪）
- Enabled file output for all build modes / 启用所有构建模式的文件输出

#### Dependency Updates (依赖更新)
- Updated dependencies to the latest versions / 更新依赖库到最新版本
- Updated API coverage documentation / 更新 API 覆盖度文档

### Fixed (修复)

#### Bug Fixes (Bug 修复)
- Fixed API contract deviations in the command module / 修复命令模块 API 契约偏差
- Fixed size formatting issues in file preview and upload history pages / 修复文件预览和上传历史页面的大小格式化

#### Other Fixes (其他修复)
- Various performance optimizations and stability improvements / 各种性能优化和稳定性改进

---

## [Unreleased]

### Planned Features (计划功能)
- Complete dashboard functionality / 完整的仪表盘功能
- More server management functions / 更多服务器管理功能
- Enhanced multi-server management / 多服务器管理增强
- Team collaboration features / 团队协作功能
- Automated task management / 自动化任务管理

---

*Last updated (最后更新): 2026-03-30*
