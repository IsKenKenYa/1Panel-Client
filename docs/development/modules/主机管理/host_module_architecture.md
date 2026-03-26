# 主机管理模块架构设计

## 模块目标

- Week 2 交付主机资产管理 MVP，入口固定为 `ServerDetailPage -> OperationsCenterPage -> Hosts`。
- 范围只包含主机资产 CRUD、连接测试、分组移动，不混入监控、SSH、Process。
- 所有业务逻辑下沉到 Provider / Service / Repository，页面不直接依赖 `lib/api/v2/`。

## API 真值

1. `POST /core/hosts`：创建主机，body 为 `HostOperate`
2. `POST /core/hosts/update`：更新主机，body 为 `HostOperate`
3. `POST /core/hosts/del`：删除主机，body 为 `ids`
4. `POST /core/hosts/search`：主列表搜索接口，使用 `HostSearchRequest`
5. `POST /core/hosts/info`：详情回填接口，body 为 `{ id }`
6. `POST /core/hosts/tree`：保留给后续 host 选择联动或树形选择器
7. `POST /core/hosts/test/byid/:id`：按已保存主机 ID 测试连接
8. `POST /core/hosts/test/byinfo`：按表单输入即时测试连接
9. `POST /core/hosts/update/group`：更新单条主机分组

## 请求体与模型

- `HostOperate`
  - `id?, name, groupID, addr, port, user, authMode, password, privateKey, passPhrase, rememberPassword, description`
- `HostConnTest`
  - `addr, port, user, authMode, password, privateKey, passPhrase`
- `HostSearchRequest`
  - `page, pageSize, groupID, info`
- `HostGroupChange`
  - `id, groupID`
- `HostTreeNode / HostTreeChild`
  - 树形节点模型，已从 `host_asset_models.dart` 拆到 `host_tree_models.dart`

## 分层职责

- `HostAssetRepository`
  - 与 `HostV2Api` 对接
  - 在发请求前统一对 `password` 与 `privateKey` 做 Base64 编码
- `HostAssetService`
  - 封装 `resolveDefaultGroupId`
  - 封装 `fromHostInfo`
  - 封装测试、删除、分组更新等业务调用
- `HostAssetsProvider`
  - 管理搜索、分组、选择态、列表四态、会话内 `last test status`
- `HostAssetFormProvider`
  - 管理表单草稿、认证切换、即时测试、保存按钮启用条件
- 页面层
  - `HostAssetsPage`：卡片式列表，支持编辑、测试、删除、移动分组、批量删除
  - `HostAssetFormPage`：基础信息、认证方式、连接验证三段结构

## Week 2 主链路

| 场景 | 说明 |
|------|------|
| 列表 | 搜索 + 分组筛选 + 刷新，卡片字段为 `name / addr / user / port / authMode / group / lastTestStatus` |
| 表单 | 基础信息、认证方式、连接验证三段结构 |
| 连接测试 | 连接字段变化后立即清空验证状态，必须重新测试成功才允许保存 |
| 分组移动 | 复用共享 `GroupSelectorSheetWidget`，提交 `HostGroupChange` |

## 约束与取舍

- Week 2 不实现监控图表
- Week 2 不实现 SSH / Process 页面
- `last test status` 为 Provider 会话内状态，不伪造服务端持久状态
- `/core/hosts/tree` 已对齐，但当前页面不依赖它渲染主列表

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
