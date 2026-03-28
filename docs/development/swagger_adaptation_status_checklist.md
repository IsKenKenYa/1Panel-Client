# Swagger 适配状态清单

更新日期: 2026-03-28  
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
  - `待归类`

## 汇总

| 主状态 | 数量 |
| --- | --- |
| 已适配 | 31 |
| 部分适配 | 21 |
| 未适配 | 0 |

## 清单

| Tag | 端点数 | Owner 模块 | 主状态 | 范围标记 | 当前证据 / 备注 |
| --- | --- | --- | --- | --- | --- |
| Website | 54 | `websites` | 已适配 | Phase 2 主范围完成 | 生命周期、详情、默认站点、分组、备注已接入；长尾能力拆到子 tag 或范围边界 |
| System Setting | 43 | `settings` | 部分适配 | 非本阶段硬范围 | 系统、终端、代理、监控、快照、菜单设置均有入口，但不是本阶段硬交付核心 |
| File | 37 | `files` | 已适配 | Phase 2 主范围完成 | `FilesRepository + services + providers + pages` 已收口 |
| App | 30 | `apps` | 部分适配 | 非本阶段硬范围 | 应用商店与已安装应用链路可用，更多运维细项未做收口 |
| Backup Account | 25 | `backups` | 已适配 | Phase 1 已完成 | 账户、记录、恢复主流程已闭环 |
| Runtime | 25 | `runtimes` | 已适配 | Phase 1 已完成 | 通用链路与 PHP/Node/Supervisor 深能力已接入 |
| Container | 19 | `containers` | 已适配 | Phase 1 已完成 | 容器列表、详情、常用操作链路可用 |
| Database Mysql | 14 | `databases` | 已适配 | Phase 2 主范围完成 | list/detail/form/backup/users 主链路可用 |
| Dashboard | 12 | `dashboard` | 已适配 | Phase 2 主范围完成 | repository/service/provider 重构完成 |
| Database | 9 | `databases` | 已适配 | 已批准残留 | 主链路完成，细分状态与更多表单留 Phase 3 |
| Database PostgreSQL | 9 | `databases` | 部分适配 | 已批准残留 | PostgreSQL 细节能力仍低于 MySQL 主链路完成度 |
| Database Redis | 7 | `databases` | 部分适配 | 已批准残留 | Redis 细节配置与写操作仍有缺口 |
| Auth | 5 | `auth` | 已适配 | Phase 2 主范围完成 | 安全存储、service、session store 已接入 |
| Monitor | 5 | `monitoring` | 部分适配 | 非本阶段硬范围 | 监控页可用，但告警和更深监控链路未做本轮收口 |
| Database Common | 3 | `databases` | 部分适配 | 已批准残留 | 通用数据库能力存在，但未做到完整可视化闭环 |
| Cronjob | 16 | `cronjobs` | 已适配 | Phase 1 已完成 | 列表、表单、记录链路已交付 |
| Firewall | 15 | `firewall` | 已适配 | 已批准残留 | `status/rules/ip/ports` 完成；forward/filter advance/chain status 留 Phase 3 |
| SSH | 12 | `ssh` | 已适配 | Phase 1 已完成 | 设置、证书、日志、会话均已接入 |
| Website SSL | 11 | `websites` / `security_gateway` | 已适配 | Phase 2 主范围完成 | 证书中心、站点绑定、HTTPS 策略已接入 |
| AI | 10 | `ai` | 已适配 | Phase 2 主范围完成 | `Ollama / GPU / Domain` 三标签主流程可用 |
| Container Image | 10 | `orchestration` | 已适配 | Phase 2 主范围完成 | 镜像列表、拉取、构建、删除、tag/push 已接入 |
| Host | 10 | `host_assets` | 已适配 | Phase 1 已完成 | 主机资产列表、表单、测试、分组移动已接入 |
| OpenResty | 10 | `openresty` | 已适配 | Phase 2 主范围完成 | status / https / modules / config / build 已接入 |
| Command | 8 | `commands` | 已适配 | Phase 1 已完成 | 列表、导入预览、表单与执行链路可用 |
| Container Docker | 8 | `containers` | 部分适配 | 非本阶段硬范围 | daemon config / repo / template 在容器页存在，但不是本阶段主收口对象 |
| Logs | 4 | `logs` | 已适配 | Phase 1 已完成 | operation / login / system / task 主链路已接入 |
| Container Compose-template | 6 | `containers` | 部分适配 | 范围边界 | 页面存在，但按计划不纳入 Phase 2 主交付 |
| Container Image-repo | 6 | `containers` | 部分适配 | 范围边界 | 页面存在，但按计划不纳入 Phase 2 主交付 |
| Container Compose | 5 | `orchestration` | 已适配 | Phase 2 主范围完成 | 独立编排页已接入 create/detail/operate |
| ScriptLibrary | 5 | `script_library` | 已适配 | Phase 1 已完成 | 列表、查看、同步、输出已接入 |
| Container Network | 4 | `orchestration` | 已适配 | Phase 2 主范围完成 | 网络列表与创建/删除链路已接入 |
| Container Volume | 4 | `orchestration` | 已适配 | Phase 2 主范围完成 | 卷列表与创建/删除链路已接入 |
| Website CA | 7 | `websites` | 部分适配 | 范围边界 | 当前仅有账户汇总入口，完整 CRUD 不在 Phase 2 硬范围 |
| Website Acme | 4 | `websites` | 部分适配 | 范围边界 | 当前仅有账户汇总入口，完整 CRUD 不在 Phase 2 硬范围 |
| Website DNS | 4 | `websites` | 部分适配 | 范围边界 | 当前仅有账户汇总入口，完整 CRUD 不在 Phase 2 硬范围 |
| Website Domain | 4 | `websites` | 部分适配 | Phase 2 主范围完成 | CRUD + 校验已接入，默认域名写操作和批量仍缺 |
| Website Nginx | 4 | `websites` / `openresty` | 已适配 | Phase 2 主范围完成 | 结构化 scope 配置与源码编辑已接入 |
| Website HTTPS | 2 | `websites` | 已适配 | Phase 2 主范围完成 | 站点 HTTPS 策略页已接入 |
| Website PHP | 1 | `websites` | 部分适配 | 非本阶段硬范围 | PHP 版本联动存在，但不是独立完整工作流 |
| TaskLog | 2 | `logs` | 已适配 | Phase 1 已完成 | 已并入日志中心 Task 链路 |
| Process | 2 | `processes` | 已适配 | Phase 1 已完成 | 列表、详情、stop 主链路完成 |
| Clam | 12 | `toolbox` | 部分适配 | 非本阶段硬范围 | 现有页能查看 task/record，但写操作与完整流程未补齐 |
| Device | 12 | `toolbox/device` | 部分适配 | 非本阶段硬范围 | 已并入 `toolbox/device`，不是独立顶级模块 |
| McpServer | 8 | `ai` | 已适配 | 本轮新增闭环 | 新增 `MCP` 标签页，补齐列表、创建、编辑、操作、域名绑定 |
| System Group | 8 | `group` | 部分适配 | 非本阶段硬范围 | 共享分组底座已完成，仍不提供独立顶级页面 |
| FTP | 8 | `toolbox` | 部分适配 | 非本阶段硬范围 | 基础页已接入，但写操作与更多管理链路未补齐 |
| Host tool | 7 | `toolbox` | 已适配 | 本轮新增闭环 | 新增 `toolbox/host-tool`，接入 supervisord 状态、配置、进程与文件操作 |
| Fail2ban | 7 | `toolbox` | 部分适配 | 非本阶段硬范围 | 基础页已接入，但完整写操作验证不齐 |
| Disk Management | 4 | `toolbox` | 已适配 | 本轮新增闭环 | 新增 `toolbox/disk`，接入列表、分区、挂载、卸载 |
| PHP Extensions | 4 | `runtimes` | 已适配 | Phase 1 已完成 | PHP 扩展页与 provider 链路已接入 |
| untagged | 4 | `containers` / `websites` | 部分适配 | 待归类 | 方法已在 client 中实现，但 Swagger 未打 tag，仍需保留独立归类行 |
| Menu Setting | 1 | `settings` | 已适配 | 本轮新增闭环 | 新增菜单设置路由与页面，接入默认菜单读取和保存 |

## untagged 归类附录

| Method | Path | 建议 owner | 说明 |
| --- | --- | --- | --- |
| POST | `/containers/item/stats` | `Container` | 容器统计详情 |
| GET | `/containers/limit` | `Container` | 容器资源限制 |
| GET | `/containers/list/stats` | `Container` | 容器列表统计 |
| GET | `/websites/proxy/config/{id}` | `Website` | `proxy cache` 相关，属于已排除 tail |
