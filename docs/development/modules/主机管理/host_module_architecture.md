# 主机管理模块架构设计

## 模块目标

- 提供主机资产管理与连接验证能力
- 为 Phase 1 Week 2 的 `HostAssetsPage` 与 `HostAssetFormPage` 做准备
- 分组底座由 Week 1 的 `GroupSelectorSheetWidget` 统一承接

## 当前 API 真值

### 主机资产
1. `POST /core/hosts`
2. `POST /core/hosts/update`
3. `POST /core/hosts/del`
4. `POST /core/hosts/search`
5. `POST /core/hosts/info`
6. `POST /core/hosts/tree`
7. `POST /core/hosts/test/byid/:id`
8. `POST /core/hosts/test/byinfo`
9. `POST /core/hosts/update/group`

### 不在 Host Asset CRUD 范围内

- `/hosts/monitor/*` 属于监控链路，不应继续混在 `host_v2.dart` 的主机资产闭环中

## 请求体口径

- 主机创建/更新以 `addr / port / user / authMode / password / privateKey / passPhrase / rememberPassword / groupID / description` 为准
- 详情拉取不走 `GET /core/hosts/{id}`，而是 `POST /core/hosts/info`，body 为 `{ id }`
- 更新不走 `/{id}/update`，而是统一 `POST /core/hosts/update`

## 分层设计

- `HostAssetRepository`
  - 对接 `host_v2.dart`
  - 封装 CRUD、测试连接、分组更新与树形选项
- `HostAssetService`
  - 处理表单验证、连接测试和列表刷新
- `HostAssetsProvider`
  - 列表态
- `HostAssetFormProvider`
  - 表单态与测试连接态

## Week 2 落地重点

- 主机列表卡片：`addr / user / port / auth mode / group / test status`
- 表单分段：基础信息、认证方式、连接验证
- 所有主机分组选择统一复用 Week 1 group 底座

---

**文档版本**: 1.1
**最后更新**: 2026-03-26
