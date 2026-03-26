# 系统分组模块架构设计

## 模块目标

- 在 Phase 1 Week 1 先完成共享分组底座
- 保证依赖方向为 `Presentation -> State -> Service -> Repository -> API`
- 为 Host Asset / Command / Cronjob 提供统一分组选择与编辑能力
- 在不引入独立顶级页面的前提下，沉淀缓存、默认分组和错误处理规则

## 功能完整性清单

Week 1 以 `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json` 与上游源码共同校对，当前高置信分组端点为：

### 分组管理
1. `POST /core/groups`
2. `POST /core/groups/search`
3. `POST /core/groups/update`
4. `POST /core/groups/del`
5. `POST /groups`
6. `POST /groups/search`
7. `POST /groups/update`
8. `POST /groups/del`

### 关联更新
9. `POST /core/hosts/update/group`
10. `POST /cronjobs/group/update`

## 业务流程与交互验证

### 分组选择流程
- 业务页面打开 `GroupSelectorSheetWidget`
- `GroupOptionsProvider` 读取指定 `type`
- `GroupService` 命中缓存则直接返回，否则走 `GroupRepository`
- 用户选择分组后由页面自身持有 `groupID`

### 分组编辑流程
- 在选择器内打开 `GroupEditSheetWidget`
- 保存时走 `GroupOptionsProvider -> GroupService -> GroupRepository -> SystemGroupV2Api`
- 成功后强制刷新当前 `type` 分组缓存
- 删除统一使用底部确认 Sheet

## 关键边界与异常

### 查询异常
- 指定 `type` 没有任何分组时返回空态
- API 返回错误时统一走 Provider 错态与重试
- 默认分组名称缺失时在 UI 层降级展示为“默认分组”

## 模块分层与职责

### Presentation
- `GroupSelectorSheetWidget`
- `GroupEditSheetWidget`

### State
- `GroupOptionsProvider`

### Service
- `GroupService`
  - 分组缓存
  - 默认分组优先排序
  - 写操作后的缓存失效

### Repository
- `GroupRepository`
  - 核心分组与 agent 分组双命名空间访问
  - 请求体组装
  - API 调用聚合

### API
- `SystemGroupV2Api`

## 数据流

1. UI Sheet 触发动作
2. Provider 更新可观察状态
3. Service 处理缓存与刷新策略
4. Repository 调用 `SystemGroupV2Api`
5. API 响应映射为 `GroupInfo`
6. Provider 刷新列表并回写 UI

## 与现有实现的差距

- 独立分组管理页仍未进入 Phase 1
- Website/Backup 等后续模块还未开始复用共享分组底座
- 分组资源统计仍待后续阶段补齐

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |

---

**文档版本**: 1.1
**最后更新**: 2026-03-25
