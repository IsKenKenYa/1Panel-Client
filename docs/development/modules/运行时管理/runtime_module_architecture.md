# 运行时管理模块架构设计

## 模块定位

- 运行时管理是 Phase 1 Week 7 的核心模块之一。
- 信息架构上采用一个运行时中心页 + 详情页 + 基础表单页：
  - `RuntimesCenterPage`
  - `RuntimeDetailPage`
  - `RuntimeFormPage`
- 顶部统一按语言分类：
  - `PHP`
  - `Node`
  - `Java`
  - `Go`
  - `Python`
  - `.NET`

## Source of Truth

- Web API：`docs/OpenSource/1Panel/frontend/src/api/modules/runtime.ts`
- Web interface：`docs/OpenSource/1Panel/frontend/src/api/interface/runtime.ts`
- Web 页面：`docs/OpenSource/1Panel/frontend/src/views/website/runtime/`
- 本地客户端：`lib/api/v2/runtime_v2.dart`
- 本地模型：`lib/data/models/runtime_models.dart`

## Week 7 已落地接口

### 通用链路

- `POST /runtimes/search`
- `GET /runtimes/{id}`
- `POST /runtimes`
- `POST /runtimes/update`
- `POST /runtimes/del`
- `POST /runtimes/operate`
- `POST /runtimes/sync`
- `POST /runtimes/remark`

### Week 8 预留

- `GET /runtimes/php/:id/extensions`
- `GET /runtimes/php/config/:id`
- `POST /runtimes/php/config`
- `GET /runtimes/php/fpm/status/:id`
- `POST /runtimes/node/package`
- `POST /runtimes/node/modules`

## 当前移动端结构

### 路由

- `AppRoutes.runtimes`
- `AppRoutes.runtimeDetail`
- `AppRoutes.runtimeForm`

### 分层落点

- Repository
  - `RuntimeRepository`
- Service
  - `RuntimeService`
- Provider
  - `RuntimesProvider`
  - `RuntimeDetailProvider`
  - `RuntimeFormProvider`
- Presentation
  - `RuntimesCenterPage`
  - `RuntimeDetailPage`
  - `RuntimeFormPage`

## 页面职责

### RuntimesCenterPage

- 顶部语言分类切换
- 搜索 + 状态过滤
- 列表卡片展示
- 通用操作：
  - `start`
  - `stop`
  - `restart`
  - `delete`
  - `sync`
- 进入详情页 / 表单页

### RuntimeDetailPage

- 三段结构：
  - `Overview`
  - `Config`
  - `Advanced`
- Overview：
  - 类型、状态、版本、资源、创建时间
  - `start / stop / restart`
- Config：
  - image / codeDir / path / source / port / container / params
- Advanced：
  - remark 编辑
  - 高级配置统计
  - Week 8 深能力提示

### RuntimeFormPage

- 三段结构：
  - `Basic`
  - `Runtime`
  - `Advanced`
- Basic：
  - name / type / resource / version
- Runtime：
  - image / codeDir / port / source / hostIp / containerName / execScript
  - node 额外有 `packageManager`
- Advanced：
  - remark
  - rebuild
  - 高级配置统计

## 关键边界

- `RuntimeCreate` / `RuntimeUpdate` 已按通用真实字段对齐：
  - `appDetailId`
  - `appId`
  - `type`
  - `resource`
  - `image`
  - `version`
  - `source`
  - `codeDir`
  - `port`
  - `remark`
  - `params`
- `RuntimeService` 负责：
  - 语言分类排序
  - 通用字段默认值
  - status 操作可用性
  - draft -> request 映射
- no-server 场景下：
  - `RuntimesCenterPage`
  - `RuntimeDetailPage`
  - `RuntimeFormPage`
  均不提前打 API

## 已知取舍

- `appstore create` 和 `PHP create` 暂保留 Week 8 专用向导
- `Config / Advanced` 当前只做通用字段与统计展示，不内嵌 PHP/Node 深编辑器
- 删除前依赖检查接口本轮未接主 UI，先保留直接删除确认流

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
