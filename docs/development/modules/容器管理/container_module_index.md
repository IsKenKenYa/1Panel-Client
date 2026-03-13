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

## 适配检查结果（基于 1Panel V2 swagger.json，2026-03-13）

**OpenAPI 缺失（swagger 有）**
- `POST` /containers/compose/env
- `POST` /containers/files/content
- `POST` /containers/files/del
- `POST` /containers/files/download
- `POST` /containers/files/search
- `POST` /containers/files/size
- `POST` /containers/files/upload

**OpenAPI 多余（swagger 无）**
- `POST` /containers/command

**客户端缺失（swagger 有）**
- `GET` /runtimes/php/container/{id}
- `POST` /runtimes/php/container/update

**客户端多余（swagger 无）**
- （无）

说明:
- `/containers/compose/*`、`/containers/docker/*`、`/containers/files/*`、`/containers/daemonjson/*` 等已在客户端实现（Compose 相关集中在 `ComposeV2Api`）。
- `/runtimes/php/container/*` 仍待运行时模块补齐。 

## 后续规划
- 容器终端功能实现
- 容器性能监控图表
- 容器编排功能
- 容器模板管理
