# 1Panel V2 功能需求跟踪矩阵

## 概览

- **API端点总数**: 546
- **标签数**: 52
- **数据模型数**: 471
- **优先级分类**: P0 (核心), P1 (高价值), P2 (工具类)

## Phase 2 增量进展（2026-03-27）

- **S2-1（Database + Firewall）**: 主链路维持可用，延续 Repository/Service/Provider/Page 闭环。
- **S2-2（Website Core）**: 站点生命周期、详情、默认站点、分组、备注与域名主流程维持可用。
- **S2-3（Security & Gateway）**: `panel ssl + website ssl + openresty` 按统一收口标准推进，风险提示、差异预览、回滚入口与 i18n 一致性继续对齐。
- **S2-3 本轮收口结果**: Website SSL Center 完成 provider 全量筛选项与健康状态文案国际化对齐；OpenResty/Panel TLS 维持本地化闭环。
- **S2-4（Orchestration + AI）启动结果**:
	- Orchestration：新增 `repository + service`，compose/image/network/volume 四个 provider 完成去 API 直连改造。
	- AI：provider 完成去 API 直连改造（改为依赖 repository），新增 `AppRoutes.ai`，并接入 Shell 模块与服务器详情入口。
- **门禁执行结果**:
	- `flutter analyze`：通过（No issues found）
	- `dart run test_runner.dart unit`：通过
	- `dart run test_runner.dart ui`：通过
	- `dart run test_runner.dart integration`：通过（部分用例按环境开关跳过，见测试输出说明）
- **下一步**: 继续 S2-4 主链路对齐（Compose/Image/Network/Volume 细节交互与 AI 三主流程深化），并补针对新分层的回归测试。

## 优先级定义

| 优先级 | 定义 | 包含模块 |
|--------|------|----------|
| **P0** | 核心业务链路与主流程依赖 | Auth, Dashboard, App, Container, Website, File, System Setting, Database系列, Runtime, Monitor, Backup Account |
| **P1** | 高价值扩展与运维能力 | OpenResty, SSL, SSH, Logs, Task, Script, 容器细分能力, AI, Cronjob, Firewall |
| **P2** | 工具类或低频能力 | Device, Clam, Fail2ban, FTP, Disk Management, Menu Setting, System Group, McpServer |

## 模块实现状态矩阵

### P0 优先级模块 (核心功能)

| 模块 | 端点数 | API客户端 | 数据模型 | 测试覆盖 | UI集成 | 状态 | 备注 |
|-------|---------|-----------|----------|----------|---------|------|------|
| **Website** | 54 | ✅ website_v2.dart | ✅ website_models.dart | ✅ 已测试 | 🟡 部分 | lifecycle/detail/default/group/remark/create-edit 已接入，SSL/OpenResty 深化留给后续 |
| **System Setting** | 43 | ✅ setting_v2.dart | ✅ setting_models.dart | ✅ 已测试 | 🟡 部分 | MFA功能已实现 |
| **File** | 37 | ✅ file_v2.dart | ✅ file_models.dart | ✅ 已测试 | 🟡 部分 | 上传/下载/编辑流程待扩展 |
| **App** | 30 | ✅ app_v2.dart | ✅ app_models.dart | ✅ 已测试 | 🟡 部分 | 应用商店与安装流程待补齐 |
| **Backup Account** | 25 | ✅ backup_account_v2.dart | ✅ backup_account_models.dart | ⚠️ 待测试 | 🔴 待集成 | 备份策略与恢复流程待扩展 |
| **Runtime** | 25 | ✅ runtime_v2.dart | ✅ runtime_models.dart | ⚠️ 待测试 | 🔴 待集成 | 运行时管理页面待建设 |
| **Container** | 19 | ✅ container_v2.dart | ✅ container_models.dart | ✅ 已测试 | 🟡 部分 | 需要补齐网络/卷/镜像管理 |
| **Database Mysql** | 14 | ✅ database_v2.dart | ✅ database_models.dart | ✅ 已测试 | 🟡 部分 | 列表/详情/backup/user 主链路已接入，细分能力待扩展 |
| **Dashboard** | 12 | ✅ dashboard_v2.dart | ✅ monitoring_models.dart | ✅ 已测试 | ✅ 已集成 | 关注核心指标展示 |
| **Database** | 9 | ✅ database_v2.dart | ✅ database_models.dart | ✅ 已测试 | 🟡 部分 | list/detail/form/backup/users 闭环已成型，remote/redis 细节待继续打磨 |
| **Database PostgreSQL** | 9 | ✅ database_v2.dart | ✅ database_models.dart | ⚠️ 待测试 | 🟡 部分 | PostgreSQL特定功能待细化 |
| **Database Redis** | 7 | ✅ database_v2.dart | ✅ database_models.dart | ⚠️ 待测试 | 🟡 部分 | Redis特定功能待细化 |
| **Database Common** | 3 | ✅ database_v2.dart | ✅ database_models.dart | ⚠️ 待测试 | 🟡 部分 | 通用数据库操作 |
| **Auth** | 5 | ✅ auth_v2.dart | ✅ user_models.dart | ✅ 已测试 | ✅ 已集成 | 认证链路完整 |
| **Monitor** | 5 | ✅ monitor_v2.dart | ✅ monitoring_models.dart | ⚠️ 待测试 | 🟡 部分 | 性能图表与告警待扩展 |

### P1 优先级模块 (高价值扩展)

| 模块 | 端点数 | API客户端 | 数据模型 | 测试覆盖 | UI集成 | 状态 | 备注 |
|-------|---------|-----------|----------|----------|---------|------|------|
| **Cronjob** | 16 | ✅ cronjob_v2.dart | ✅ cronjob_models.dart | ⚠️ 待测试 | 🔴 待集成 | 计划任务管理 |
| **Firewall** | 15 | ✅ firewall_v2.dart | ✅ firewall_models.dart | ✅ 已测试 | 🟡 部分 | status/rules/ip/ports/search/batch 已接入，advanced chain 待补 |
| **SSH** | 12 | ✅ terminal_v2.dart | ✅ terminal_models.dart | ⚠️ 待测试 | 🔴 待集成 | SSH会话/日志待扩展 |
| **Website SSL** | 11 | ✅ ssl_v2.dart | ✅ ssl_models.dart | ⚠️ 待测试 | 🟡 部分 | 证书与域名细分功能待扩展 |
| **AI** | 10 | ✅ ai_v2.dart | ✅ ai_models.dart | ✅ 已测试 | 🟡 部分 | GPU/XPU监控与域名绑定 |
| **Container Image** | 10 | ✅ container_v2.dart | ✅ container_models.dart | ⚠️ 待测试 | 🟡 部分 | 镜像管理功能 |
| **Host** | 10 | ✅ host_v2.dart | ✅ host_models.dart | ⚠️ 待测试 | 🔴 待集成 | 主机管理 |
| **OpenResty** | 10 | ✅ openresty_v2.dart | ✅ openresty_models.dart | ✅ 已文档 | 🟡 部分 | 配置与状态页待建设 |
| **Command** | 8 | ✅ command_v2.dart | ✅ tool_models.dart | ✅ 已测试 | 🟡 部分 | 快捷命令 |
| **Container Docker** | 8 | ✅ docker_v2.dart | ✅ docker_models.dart | ✅ 已测试 | 🟡 部分 | Docker守护进程管理 |
| **Logs** | 4 | ✅ logs_v2.dart | ✅ logs_models.dart | ⚠️ 待测试 | 🟡 部分 | 日志管理、清理、导出 |
| **Container Compose-template** | 6 | ✅ container_compose_v2.dart | ✅ container_models.dart | ⚠️ 待测试 | 🔴 待集成 | Compose模板管理 |
| **Container Image-repo** | 6 | ✅ docker_v2.dart | ✅ docker_models.dart | ⚠️ 待测试 | 🔴 待集成 | 镜像仓库管理 |
| **Container Compose** | 5 | ✅ container_compose_v2.dart | ✅ container_models.dart | ⚠️ 待测试 | 🔴 待集成 | Docker Compose管理 |
| **ScriptLibrary** | 5 | ✅ command_v2.dart | ✅ tool_models.dart | ⚠️ 待测试 | 🔴 待集成 | 脚本库管理 |
| **Container Network** | 4 | ✅ container_v2.dart | ✅ container_models.dart | ⚠️ 待测试 | 🔴 待集成 | 网络管理 |
| **Container Volume** | 4 | ✅ container_v2.dart | ✅ container_models.dart | ⚠️ 待测试 | 🔴 待集成 | 卷管理 |
| **Website CA** | 7 | ✅ ssl_v2.dart | ✅ ssl_models.dart | ⚠️ 待测试 | 🔴 待集成 | CA证书管理 |
| **Website Acme** | 4 | ✅ ssl_v2.dart | ✅ ssl_models.dart | ⚠️ 待测试 | 🔴 待集成 | ACME证书申请 |
| **Website DNS** | 4 | ✅ website_v2.dart | ✅ website_models.dart | ⚠️ 待测试 | 🔴 待集成 | DNS管理 |
| **Website Domain** | 4 | ✅ website_v2.dart | ✅ website_models.dart | ✅ 已测试 | 🟡 部分 | CRUD + 本地校验已接入，默认域名写操作/批量仍缺 |
| **Website Nginx** | 4 | ✅ openresty_v2.dart | ✅ openresty_models.dart | ⚠️ 待测试 | 🔴 待集成 | Nginx配置 |
| **Website HTTPS** | 2 | ✅ ssl_v2.dart | ✅ ssl_models.dart | ⚠️ 待测试 | 🔴 待集成 | HTTPS配置 |
| **Website PHP** | 1 | ✅ openresty_v2.dart | ✅ openresty_models.dart | ⚠️ 待测试 | 🔴 待集成 | PHP配置 |
| **TaskLog** | 2 | ✅ task_log_v2.dart | ✅ task_log_models.dart | ⚠️ 待测试 | 🔴 待集成 | 任务日志 |
| **Process** | 2 | ✅ process_v2.dart | ✅ process_models.dart | ⚠️ 待测试 | 🔴 待集成 | 进程管理 |

### P2 优先级模块 (工具类)

| 模块 | 端点数 | API客户端 | 数据模型 | 测试覆盖 | UI集成 | 状态 | 备注 |
|-------|---------|-----------|----------|----------|---------|------|------|
| **Clam** | 12 | ✅ toolbox_v2.dart | ✅ toolbox_models.dart | ✅ 已测试 | 🔴 待集成 | 病毒扫描 |
| **Device** | 12 | ✅ host_v2.dart | ✅ host_models.dart | ⚠️ 待测试 | 🔴 待集成 | 设备管理 |
| **McpServer** | 8 | ✅ ai_v2.dart | ✅ mcp_models.dart | ✅ 已测试 | 🔴 待集成 | MCP服务器管理 |
| **System Group** | 8 | ✅ system_group_v2.dart | ✅ system_group_models.dart | ⚠️ 待测试 | 🔴 待集成 | 系统分组 |
| **FTP** | 8 | ✅ toolbox_v2.dart | ✅ toolbox_models.dart | ⚠️ 待测试 | 🔴 待集成 | FTP管理 |
| **Host tool** | 7 | ✅ toolbox_v2.dart | ✅ toolbox_models.dart | ⚠️ 待测试 | 🔴 待集成 | 主机工具 |
| **Fail2ban** | 7 | ✅ toolbox_v2.dart | ✅ toolbox_models.dart | ⚠️ 待测试 | 🔴 待集成 | 入侵防护 |
| **Disk Management** | 4 | ✅ toolbox_v2.dart | ✅ toolbox_models.dart | ⚠️ 待测试 | 🔴 待集成 | 磁盘管理 |
| **PHP Extensions** | 4 | ✅ openresty_v2.dart | ✅ openresty_models.dart | ⚠️ 待测试 | 🔴 待集成 | PHP扩展 |
| **untagged** | 4 | - | - | - | 🔴 待集成 | 未分类端点 |
| **Menu Setting** | 1 | ✅ setting_v2.dart | ✅ setting_models.dart | ⚠️ 待测试 | 🔴 待集成 | 菜单设置 |

## 实现状态统计

### 按优先级统计

| 优先级 | 模块数 | 端点数 | API客户端完成 | 测试覆盖 | UI集成完成 |
|--------|--------|---------|--------------|----------|-------------|
| **P0** | 15 | 247 | 100% (15/15) | 73% (11/15) | 33% (5/15) |
| **P1** | 26 | 239 | 100% (26/26) | 23% (6/26) | 8% (2/26) |
| **P2** | 11 | 60 | 91% (10/11) | 27% (3/11) | 0% (0/11) |
| **总计** | 52 | 546 | 98% (51/52) | 40% (21/52) | 13% (7/52) |

### 按实现维度统计

| 维度 | 完成度 | 说明 |
|------|--------|------|
| **API客户端实现** | 98% | 51/52个模块有API客户端，仅untagged模块缺失 |
| **数据模型定义** | 100% | 所有模块都有对应的数据模型 |
| **单元测试覆盖** | 40% | 21/52个模块有测试文件 |
| **UI页面集成** | 13% | 7/52个模块有完整的UI页面 |
| **端到端测试** | 0% | 尚未建立端到端测试体系 |

## 关键差距识别

### 1. API客户端层面
- ✅ **已解决**: 98%的模块都有API客户端
- ⚠️ **待完善**: untagged模块的4个端点需要归类
- ⚠️ **待验证**: 所有API客户端需要与OpenAPI规范进行端点级对齐

### 2. 测试覆盖层面
- 🔴 **严重不足**: 仅40%的模块有测试文件
- 🔴 **P1模块测试缺失**: 73%的P1模块缺乏测试
- 🔴 **P2模块测试缺失**: 73%的P2模块缺乏测试
- 🟡 **P0模块测试较好**: 73%的P0模块有测试

### 3. UI集成层面
- 🔴 **严重不足**: 仅13%的模块有完整UI页面
- 🔴 **P0模块UI缺失**: 67%的P0核心模块UI待建设
- 🔴 **P1模块UI缺失**: 92%的P1模块UI待建设
- 🔴 **P2模块UI缺失**: 100%的P2模块UI待建设

### 4. 功能完整性层面
- 🟡 **核心功能部分实现**: Dashboard、Auth、部分Container/App/Website/File功能已实现
- 🔴 **高级功能缺失**: 大部分P1和P2模块的UI和交互流程未实现
- 🔴 **边界情况处理**: 需要补充异常流程和错误处理机制
- 🔴 **离线功能**: 离线缓存和同步机制未完整实现

## 优先级行动计划

### 第一阶段：P0核心功能完善 (2-3周)
1. **Dashboard模块**: 完善系统监控图表和告警功能
2. **File模块**: 补充文件上传/下载/编辑完整流程
3. **App模块**: 完善应用商店浏览和安装流程
4. **Container模块**: 补充网络/卷/镜像管理功能
5. **Website模块**: 补充SSL和域名细分功能
6. **Backup Account模块**: 实现备份策略和恢复流程
7. **Runtime模块**: 建设运行时管理页面
8. **测试覆盖**: 为所有P0模块补充单元测试

### 第二阶段：P1高价值功能实现 (4-6周)
1. **OpenResty模块**: 实现配置和状态页面
2. **SSL模块**: 完善证书管理UI
3. **SSH模块**: 实现SSH会话和日志查看
4. **Cronjob模块**: 实现计划任务管理
5. **Firewall模块**: 实现规则管理页面
6. **Logs模块**: 实现日志管理和导出
7. **AI模块**: 完善GPU/XPU监控和域名绑定
8. **容器细分功能**: 实现Compose、网络、卷、镜像仓库管理

### 第三阶段：P2工具类功能实现 (2-3周)
1. **工具箱模块**: 实现ClamAV、Fail2ban、FTP等工具
2. **设备管理**: 实现设备监控和管理
3. **系统分组**: 实现分组管理功能
4. **测试覆盖**: 为所有P1和P2模块补充测试

### 第四阶段：架构优化和测试体系建设 (持续)
1. **Flutter架构优化**: 确保符合MVVM和SOLID原则
2. **端到端测试**: 建立完整的E2E测试体系
3. **性能优化**: 优化关键操作响应时间<200ms
4. **文档完善**: 更新所有技术文档和用户手册
5. **持续集成**: 建立CI/CD流程和自动化测试

## 质量保障措施

### 1. 代码质量
- 遵循Flutter和Dart最佳实践
- 使用静态代码分析工具
- 进行代码审查，至少2名资深开发者认可
- 确保代码覆盖率≥80%

### 2. 测试策略
- 单元测试：覆盖所有数据模型和业务逻辑
- 集成测试：覆盖API调用和数据流
- 端到端测试：覆盖关键用户流程
- 性能测试：确保关键操作<200ms

### 3. 文档标准
- API文档：与OpenAPI规范保持一致
- 用户手册：包含操作指南和FAQ
- 技术文档：包含架构设计和实现细节
- 更新机制：确保文档与代码同步

### 4. 安全要求
- 敏感数据加密存储
- HTTPS通信
- 认证令牌安全处理
- 输入验证和防注入
- 权限控制和审计日志

## 成功指标

### 技术指标
- API客户端覆盖率: 100%
- 单元测试覆盖率: ≥80%
- 端到端测试覆盖率: ≥60%
- 关键操作响应时间: <200ms
- 应用崩溃率: <0.1%

### 功能指标
- P0模块UI完成度: 100%
- P1模块UI完成度: ≥80%
- P2模块UI完成度: ≥50%
- 核心功能实现率: 100%
- 功能测试通过率: 100%

### 用户体验指标
- 用户满意度: ≥4.5/5
- 应用商店评分: ≥4.5/5
- 日活跃用户增长率: ≥10%/月
- 用户留存率: ≥60%

---

**文档版本**: 1.0
**最后更新**: 2026-03-27
**维护者**: Open1Panel开发团队
