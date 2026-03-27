# 脚本库管理模块索引

## 模块定位

脚本库管理是 Phase 1 Week 4 与 Cronjob 一起交付的运维中心能力。当前范围只覆盖列表主链路，不包含 create/edit。

## 文档清单

- 架构设计：`docs/development/modules/脚本库管理/script_library_module_architecture.md`
- 关联模块：`docs/development/modules/计划任务管理/cronjob_module_architecture.md`

## 当前代码落点

- API：`lib/api/v2/script_library_v2.dart`
- Infra：`lib/core/network/script_run_ws_client.dart`
- Repository：`lib/data/repositories/script_library_repository.dart`
- Service：`lib/features/script_library/services/script_library_service.dart`
- Provider：`lib/features/script_library/providers/script_library_provider.dart`
- 页面：`lib/features/script_library/pages/script_library_page.dart`

## 后续规划

- 后续周评估 create/edit
- 如终端能力成熟，再评估把只读 run viewer 升级为完整交互终端

---

**文档版本**: 1.0
**最后更新**: 2026-03-27
