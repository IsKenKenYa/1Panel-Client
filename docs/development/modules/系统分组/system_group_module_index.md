# 系统分组模块索引

## 模块定位

系统分组在 Phase 1 Week 1 不先做独立顶级页面，而是先沉淀为共享分组底座，优先服务：

- Host Asset
- Command
- Cronjob
- 后续 Website / Backup / SSH 等模块

## 子模块结构

| 子模块 | 端点数 | API客户端 | 说明 |
|--------|--------|-----------|------|
| **Core Group** | 4 | system_group_v2.dart | `/core/groups/*` 创建、更新、删除、查询 |
| **Agent Group** | 4 | system_group_v2.dart | `/groups/*` 创建、更新、删除、查询 |
| **资源关联** | 2 | host_v2.dart / cronjob_v2.dart | 主机与计划任务的分组更新 |

## Week 1 已落地内容

- `SystemGroupV2Api` 对齐 `core/groups` 与 `groups` 双命名空间
- `GroupRepository` / `GroupService` / `GroupOptionsProvider` 闭环完成
- `GroupSelectorSheetWidget` / `GroupEditSheetWidget` 可复用于后续模块表单与筛选
- `GroupService` 增加默认分组排序与缓存失效策略
- 第一阶段仍不提供独立 `group` 顶级页面

## 后续规划方向

### 短期目标
- 在 Host Asset / Command / Cronjob 中复用共享分组底座
- 统一默认分组展示与二次确认删除行为
- 为独立管理页预留 Provider 与路由策略

### 中期目标
- 支持分组批量操作
- 实现分组权限控制
- 添加分组统计报表

### 长期目标
- 支持分组模板
- 实现跨服务器分组
- 提供分组拓扑视图

## 与其他模块的关系

- **应用管理**: 应用资源分组
- **网站管理**: 网站资源分组
- **数据库管理**: 数据库资源分组
- **监控管理**: 按分组聚合监控数据

---

**文档版本**: 1.1
**最后更新**: 2026-03-25
