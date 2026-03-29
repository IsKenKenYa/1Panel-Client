# Swagger 适配状态清单

更新日期: 2026-03-29  
规范源: `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`

## 口径

- 本清单是当前唯一的 Swagger tag 级适配状态真值。
- 统计单位为 `51` 个具名 tag 加 `1` 个 `untagged` 行，共 `52` 行。
- 主状态定义:
  - `已适配`: 当前代码具备 route 或页面入口，以及 `Provider + Service/Repository + API` 主链路闭环。
  - `部分适配`: 已有部分实现，但 UI、写操作、范围边界能力或顶级入口仍不完整。
  - `未适配`: 当前代码没有形成可用闭环。
- 第二轴范围标记定义:
  - `Phase 1 已完成`
  - `Phase 2 主范围完成`
  - `已批准残留`
  - `范围边界`
  - `非本阶段硬范围`
  - `本轮新增闭环`
  - `已归类附录`
  - `待归类`
- 文档一致性校验脚本: `python3 scripts/validate_swagger_adaptation_docs.py`
- 本次自动回刷冻结基线: `52 已适配 / 0 部分适配 / 0 未适配`

## 汇总

| 主状态 | 数量 |
| --- | --- |
| 已适配 | 52 |
| 部分适配 | 0 |
| 未适配 | 0 |

## 清单

| Tag | 端点数 | Owner 模块 | 主状态 | 范围标记 | 当前证据 / 备注 |
| --- | --- | --- | --- | --- | --- |
| Website | 54 | `websites` | 已适配 | Phase 2 主范围完成 | 生命周期、详情、默认站点、分组、备注已接入；长尾能力拆到子 tag 或范围边界 |
| System Setting | 43 | `settings` | 已适配 | 本轮新增闭环 | `SystemSettingsPage -> SettingsProvider -> SettingsService -> SettingRepository -> setting_v2` 已补应用商店配置、SSH 连接、网络接口、终端设置与快照常用操作读写；新增 `settings_provider_test.dart`、`system_settings_page_test.dart` |
| File | 37 | `files` | 已适配 | Phase 2 主范围完成 | `FilesRepository + services + providers + pages` 已收口 |
| App | 30 | `apps` | 已适配 | 本轮新增闭环 | `AppsPage -> InstalledAppsProvider/AppStoreProvider -> AppService -> AppRepository -> app_v2` 主链路闭环；忽略升级/取消忽略、配置更新、端口变更、同步触发均经 Provider 暴露并带结果提示；新增 `app_store_provider_test.dart`、`app_store_page_test.dart` |
| Backup Account | 25 | `backups` | 已适配 | Phase 1 已完成 | 账户、记录、恢复主流程已闭环 |
| Runtime | 25 | `runtimes` | 已适配 | Phase 1 已完成 | 通用链路与 PHP/Node/Supervisor 深能力已接入 |
| Container | 19 | `containers` | 已适配 | Phase 1 已完成 | 容器列表、详情、常用操作链路可用 |
| Database Mysql | 14 | `databases` | 已适配 | Phase 2 主范围完成 | list/detail/form/backup/users 主链路可用 |
| Dashboard | 12 | `dashboard` | 已适配 | Phase 2 主范围完成 | repository/service/provider 重构完成 |
| Database | 9 | `databases` | 已适配 | 已批准残留 | 主链路完成，细分状态与更多表单留 Phase 3 |
| Database PostgreSQL | 9 | `databases` | 已适配 | 本轮新增闭环 | `DatabaseUsersPage/Provider` 已覆盖 bindUser 与 updatePrivileges 写链路并提供页面反馈；新增 `database_users_provider_test.dart` 与 `database_pages_test.dart`（PostgreSQL 用户权限交互） |
| Database Redis | 7 | `databases` | 已适配 | 本轮新增闭环 | `DatabaseRedisPage -> DatabaseDetailProvider -> DatabasesService -> DatabaseRepository -> database_v2` 已补配置/持久化写入与成功失败反馈；新增 `database_detail_provider_test.dart`、`database_pages_test.dart` |
| Auth | 5 | `auth` | 已适配 | Phase 2 主范围完成 | 安全存储、service、session store 已接入 |
| Monitor | 5 | `monitoring` | 已适配 | 本轮新增闭环 | `MonitoringPage -> MonitoringProvider -> MonitoringService -> MonitorRepository (+ MonitorLocalDataSource)` 已补 GPU 刷新策略（开关+间隔）可控，设置保存后即时影响轮询行为；新增 `monitoring_provider_test.dart`、`monitoring_page_test.dart` |
| Database Common | 3 | `databases` | 已适配 | 本轮新增闭环 | 通用详情写操作（描述/改密/绑定）统一反馈链路已闭环，失败路径回退可见；新增 `database_detail_provider_test.dart` 写入失败覆盖 |
| Cronjob | 16 | `cronjobs` | 已适配 | Phase 1 已完成 | 列表、表单、记录链路已交付 |
| Firewall | 15 | `firewall` | 已适配 | 已批准残留 | `status/rules/ip/ports` 完成；forward/filter advance/chain status 留 Phase 3 |
| SSH | 12 | `ssh` | 已适配 | Phase 1 已完成 | 设置、证书、日志、会话均已接入 |
| Website SSL | 11 | `websites` / `security_gateway` | 已适配 | Phase 2 主范围完成 | 证书中心、站点绑定、HTTPS 策略已接入 |
| AI | 10 | `ai` | 已适配 | Phase 2 主范围完成 | `Ollama / GPU / Domain / MCP` 四标签主流程可用 |
| Container Image | 10 | `orchestration` | 已适配 | Phase 2 主范围完成 | 镜像列表、拉取、构建、删除、tag/push 已接入 |
| Host | 10 | `host_assets` | 已适配 | Phase 1 已完成 | 主机资产列表、表单、测试、分组移动已接入 |
| OpenResty | 10 | `openresty` | 已适配 | Phase 2 主范围完成 | status / https / modules / config / build 已接入 |
| Command | 8 | `commands` | 已适配 | Phase 1 已完成 | 列表、导入预览、表单与执行链路可用 |
| Container Docker | 8 | `containers` | 已适配 | 本轮新增闭环 | `ContainersProvider + ContainerService + container_v2` 已形成 daemon config / repo / template 读写闭环；补充 `containers_provider_test.dart` daemon 写回回归 |
| Logs | 4 | `logs` | 已适配 | Phase 1 已完成 | operation / login / system / task 主链路已接入 |
| Container Compose-template | 6 | `containers` | 已适配 | 本轮新增闭环 | `TemplatesTab + TemplateCreateDialog` 已接入 create/update/delete；补充 `containers_provider_test.dart` 模板 CRUD 回归 |
| Container Image-repo | 6 | `containers` | 已适配 | 本轮新增闭环 | `ReposTab + RepoCreateDialog` 已接入 create/update/delete；补充 `containers_provider_test.dart` 仓库 CRUD 回归 |
| Container Compose | 5 | `orchestration` | 已适配 | Phase 2 主范围完成 | 独立编排页已接入 create/detail/operate |
| ScriptLibrary | 5 | `script_library` | 已适配 | Phase 1 已完成 | 列表、查看、同步、输出已接入 |
| Container Network | 4 | `orchestration` | 已适配 | Phase 2 主范围完成 | 网络列表与创建/删除链路已接入 |
| Container Volume | 4 | `orchestration` | 已适配 | Phase 2 主范围完成 | 卷列表与创建/删除链路已接入 |
| Website CA | 7 | `websites` | 已适配 | 本轮新增闭环 | `WebsiteSslAccountsPage/Provider` 已补齐 CA 创建/删除、签发、续签、下载；`website_ssl_accounts_provider_test.dart` 与 `website_ssl_accounts_page_test.dart` 覆盖关键流程 |
| Website Acme | 4 | `websites` | 已适配 | 本轮新增闭环 | `WebsiteSslAccountsPage/Provider` 已补齐 ACME 创建/更新/删除及失败提示回填；provider/page 测试已覆盖 |
| Website DNS | 4 | `websites` | 已适配 | 本轮新增闭环 | `WebsiteSslAccountsPage/Provider` 已补齐 DNS 账户创建/更新/删除与授权参数提交流程；provider/page 测试已覆盖 |
| Website Domain | 4 | `websites` | 已适配 | Phase 2 主范围完成 | CRUD、校验与批量导入已接入；默认域名能力归属 `Website` 主链路，不再作为该 tag 阻断项 |
| Website Nginx | 4 | `websites` / `openresty` | 已适配 | Phase 2 主范围完成 | 结构化 scope 配置与源码编辑已接入 |
| Website HTTPS | 2 | `websites` | 已适配 | Phase 2 主范围完成 | 站点 HTTPS 策略页已接入 |
| Website PHP | 1 | `websites` | 已适配 | 本轮新增闭环 | 配置中心已挂接 PHP 入口；`WebsiteConfigProvider/Page` 已补当前版本读取、runtime 列表选择、切换提交与失败提示；新增 `website_config_provider_test.dart`、`website_config_page_test.dart` |
| TaskLog | 2 | `logs` | 已适配 | Phase 1 已完成 | 已并入日志中心 Task 链路 |
| Process | 2 | `processes` | 已适配 | Phase 1 已完成 | 列表、详情、stop 主链路完成 |
| Clam | 12 | `toolbox` | 已适配 | 本轮新增闭环 | `ToolboxClamPage -> ToolboxClamProvider -> ToolboxClamService -> ToolboxRepository -> toolbox_v2` 已补任务 CRUD、handle/operate、记录清理与分页；新增 `toolbox_clam_provider_test.dart` |
| Device | 12 | `toolbox/device` | 已适配 | 本轮新增闭环 | `ToolboxDevicePage -> ToolboxDeviceProvider -> ToolboxDeviceService -> ToolboxRepository -> toolbox_v2` 已补配置编辑、DNS 校验、改密、swap 更新；新增 `toolbox_device_provider_test.dart` |
| McpServer | 8 | `ai` | 已适配 | 本轮新增闭环 | 新增 `MCP` 标签页，补齐列表、创建、编辑、操作、域名绑定 |
| System Group | 8 | `group` | 已适配 | 本轮新增闭环 | 新增分组中心页，支持 core / agent 命名空间下的独立查询与 CRUD |
| FTP | 8 | `toolbox` | 已适配 | 本轮新增闭环 | `ToolboxFtpPage -> ToolboxFtpProvider -> ToolboxFtpService -> ToolboxRepository -> toolbox_v2` 已补用户 CRUD、服务操作、搜索与分页；新增 `toolbox_ftp_provider_test.dart` |
| Host tool | 7 | `toolbox` | 已适配 | 本轮新增闭环 | 新增 `toolbox/host-tool`，接入 supervisord 状态、配置、进程与文件操作 |
| Fail2ban | 7 | `toolbox` | 已适配 | 本轮新增闭环 | `ToolboxFail2banPage -> ToolboxFail2banProvider -> ToolboxFail2banService -> ToolboxRepository -> toolbox_v2` 已补配置更新、enable/disable、start/stop/restart 与 sshd 操作；新增 `toolbox_fail2ban_provider_test.dart` |
| Disk Management | 4 | `toolbox` | 已适配 | 本轮新增闭环 | 新增 `toolbox/disk`，接入列表、分区、挂载、卸载 |
| PHP Extensions | 4 | `runtimes` | 已适配 | Phase 1 已完成 | PHP 扩展页与 provider 链路已接入 |
| untagged | 4 | `containers` / `websites` | 已适配 | 已归类附录 | 4 个接口均已完成 API 与调用落点归类：`ContainerService` 使用 `/containers/item/stats`，`container_v2` 提供 `limit/list stats`，`website_v2` 提供 `proxy config` |
| Menu Setting | 1 | `settings` | 已适配 | 本轮新增闭环 | 新增菜单设置路由与页面，接入默认菜单读取和保存 |

## untagged 归类附录

| Method | Path | 建议 owner | 说明 |
| --- | --- | --- | --- |
| POST | `/containers/item/stats` | `Container` | 容器统计详情 |
| GET | `/containers/limit` | `Container` | 容器资源限制 |
| GET | `/containers/list/stats` | `Container` | 容器列表统计 |
| GET | `/websites/proxy/config/{id}` | `Website` | `proxy cache` 相关，属于已排除 tail |
