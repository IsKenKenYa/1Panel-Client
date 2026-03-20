# 容器管理模块索引

## 模块定位
Open1PanelApp 的容器管理模块负责Docker容器的生命周期管理、镜像管理、网络管理、卷管理、容器日志查看与资源监控，提供移动端友好的容器管理体验。

## 子模块结构
- 架构设计: docs/development/modules/容器管理/container_module_architecture.md
- 页面设计: docs/development/modules/容器管理/container_pages.md
- API设计: docs/development/modules/容器管理/container_api.md
- 数据设计: docs/development/modules/容器管理/container_data.md
- 开发计划: docs/development/modules/容器管理/container_plan.md
- 运维手册: docs/development/modules/容器管理/container_ops.md
- 用户手册: docs/development/modules/容器管理/container_user_manual.md
- FAQ: docs/development/modules/容器管理/container_faq.md

## 适配检查结果（基于 1Panel V2 OpenAPI.json，2026-03-20）

**OpenAPI 缺失（swagger 有，客户端已兼容）**
- `POST` /containers/compose/env
- `POST` /containers/files/content
- `POST` /containers/files/del
- `POST` /containers/files/download
- `POST` /containers/files/search
- `POST` /containers/files/size
- `POST` /containers/files/upload

**OpenAPI 已覆盖且客户端已实现**
- `POST` /containers/command

**客户端缺失（OpenAPI 有）**
- `GET` /runtimes/php/container/:id
- `POST` /runtimes/php/container/update

**客户端多余（OpenAPI 无）**
- （无）

说明:
- `/containers/compose/*`、`/containers/docker/*`、`/containers/files/*`、`/containers/daemonjson/*` 等已在客户端实现，Compose 相关集中在 `ComposeV2Api`。
- 创建容器主入口已从 legacy route 切换为真实页面 `ContainerCreatePage`。
- 容器列表已改为惰性列表，局部加载失败按 tab 隔离，不再用单一错误状态污染整页。
- 容器详情已改为通过 `ContainerDetailProvider` 管理 inspect/logs/stats；未实现的终端入口已从详情页移除。
- `/runtimes/php/container/*` 仍由运行时模块补齐，不再作为容器主页适配阻断项。

## 后续规划
- 容器终端功能实现
- 容器性能监控图表增强
- 容器编排能力继续下沉到独立模块
