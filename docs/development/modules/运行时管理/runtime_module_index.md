# 运行时管理模块索引

## 当前范围

- Phase 1 Week 7 只做运行时通用链路 MVP。
- 当前移动端覆盖：
  - runtime 列表
  - runtime 详情
  - runtime 基础表单骨架
  - 通用 `start / stop / restart / sync / remark / delete`
  - 多语言分类入口：`PHP / Node / Java / Go / Python / .NET`
- 明确不在本轮范围：
  - PHP 深配置
  - PHP extensions
  - Node modules / scripts
  - supervisor 深化能力

## 当前交付状态

- Week 7 已完成：
  - `RuntimesCenterPage`
  - `RuntimeDetailPage`
  - `RuntimeFormPage`
  - `RuntimeRepository`
  - `RuntimeService`
  - `RuntimesProvider`
  - `RuntimeDetailProvider`
  - `RuntimeFormProvider`
- 关键实现口径：
  - 入口继续从 `OperationsCenterPage` 进入
  - `AppRoutes.runtimes` / `runtimeDetail` / `runtimeForm` 已替换 placeholder
  - `task/toolbox/Phase 2` 范围不混入 runtime 通用链路

## 当前代码落点

- API：
  - `lib/api/v2/runtime_v2.dart`
- Repository：
  - `lib/data/repositories/runtime_repository.dart`
- Service：
  - `lib/features/runtimes/services/runtime_service.dart`
- Provider：
  - `lib/features/runtimes/providers/`
- 页面：
  - `lib/features/runtimes/pages/`

## 已知取舍

- create/edit 表单当前只保证通用字段骨架和共享保存链路。
- `appstore create` 与 `PHP create` 保留到 Week 8 的专用向导/深表单。
- 详情页 `Config / Advanced` 先展示通用字段和统计，不展开语言特定编辑器。

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
