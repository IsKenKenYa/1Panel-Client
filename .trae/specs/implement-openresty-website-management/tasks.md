# Tasks

* [x] Task 1: 对齐 OpenResty API 客户端并补齐测试

  * [x] SubTask 1.1: 校对 openresty\_v2 端点方法与请求体（以 OpenAPI/模块文档为准）

  * [x] SubTask 1.2: 修正不一致调用并补齐必要模型解析

  * [x] SubTask 1.3: 使用 analyze\_module\_api 提取 openresty API 集合并新增测试覆盖

* [ ] Task 2: 实现站点详情 UI 与状态管理（配置/域名/SSL/伪静态/代理）

  * [ ] SubTask 2.1: 扩展路由与导航：网站列表可进入站点详情

  * [ ] SubTask 2.2: 新增/完善 Website Service/Provider，统一加载、错误与重试

  * [ ] SubTask 2.3: 配置分区：读取与更新站点配置

  * [ ] SubTask 2.4: 域名分区：列表/添加/删除

  * [ ] SubTask 2.5: SSL 分区：查看与更新站点 SSL（含证书选择或上传的最小闭环）

  * [ ] SubTask 2.6: 伪静态与反向代理分区：查看与更新

* [ ] Task 3: 实现 OpenResty 管理基础页面与状态管理

  * [ ] SubTask 3.1: 新增 OpenResty Service/Provider（状态、模块、更新相关）

  * [ ] SubTask 3.2: 实现 OpenResty 状态页与模块信息页（MDUI3 + l10n）

  * [ ] SubTask 3.3: 为更新类操作提供确认交互与结果提示

* [ ] Task 4: 国际化与验证

  * [ ] SubTask 4.1: 补齐新增 UI 文案的中英文 ARB，并生成 l10n

  * [ ] SubTask 4.2: 仅为目标模块补齐 API client 测试（openresty/config/domain/website\_ssl）

  * [ ] SubTask 4.3: 运行相关测试与基础构建验证，修复发现的问题

# Task Dependencies

* Task 2 depends on Task 1

* Task 3 depends on Task 1

* Task 4 depends on Task 2 and Task 3
