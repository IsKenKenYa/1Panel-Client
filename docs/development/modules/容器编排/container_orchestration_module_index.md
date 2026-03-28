# 容器编排模块索引

## 模块定位

容器编排模块是Open1PanelApp的P1高价值扩展模块，提供Docker容器的高级编排能力，包括Compose管理、网络管理、卷管理、镜像仓库等，是容器管理模块的重要扩展。

## S2-0 基线（2026-03-26）

- 当前状态：
  当前已有 `route / page / provider` 家族骨架，但 `compose / image / network / volume` 仍缺少 `repository / service`，且 provider 直接依赖 API。
- 阶段 2 hard scope：
  `compose / image / network / volume`
- tail only：
  `image repo / compose template`
- 文档缺口：
  当前仅有家族级文档和 `compose_api_analysis.*`，缺少 `image / network / volume` 的独立 API 基线文档。

## 子模块结构

| 子模块 | 端点数 | API客户端 | 说明 |
|--------|--------|-----------|------|
| **Docker管理** | 8 | docker_v2.dart | Docker服务配置和管理 |
| **Compose编排** | 11 | container_compose_v2.dart | Compose项目管理和模板 |
| **网络管理** | 4 | container_v2.dart | 容器网络创建和管理 |
| **卷管理** | 4 | container_v2.dart | 数据卷创建和管理 |
| **镜像仓库** | 6 | docker_v2.dart | 镜像仓库配置管理 |

## 后续规划方向

### 短期目标
- 完善Compose项目管理
- 实现网络和卷管理
- 添加镜像仓库配置

### 中期目标
- 支持Compose模板库
- 实现多节点编排
- 添加资源限制配置

### 长期目标
- 支持Kubernetes编排
- 实现服务网格
- 提供容器云平台能力

## 与其他模块的关系

- **容器管理**: 基础容器操作
- **应用管理**: 应用容器化部署
- **监控管理**: 容器资源监控
- **日志管理**: 容器日志收集

---

**文档版本**: 1.0
**最后更新**: 2026-02-14
