# 命令管理模块开发计划

> 2026-03-27 更新：脚本库已在 Phase 1 Week 4 拆到独立模块，本计划后续仅跟踪命令管理本身。

## 当前状态

- Week 2 命令管理 MVP 已交付
- `CommandsPage` / `CommandFormPage` 可评审、可测试
- 真实环境 API client tests、Provider tests、Widget tests 已补齐

## 后续计划

### M0: 契约真值收口（阻断项）

- 完成 `tree/list` 契约真值判定与证据矩阵。
- 客户端保持严格 `POST`（不做 `GET` 回退）。
- 同步 API -> Repository -> Service -> Provider -> Page/Widget -> 测试 -> 文档 全链路。
- 产出上游 issue + 本仓 issue 并回填编号。

**Issue 回填位**:

- 上游 issue：`1Panel-dev/1Panel#12363`
- 本仓 issue：`IsKenKenYa/1Panel-Client#6`

### M1: 命令主链路维护
- 命令列表与搜索
- 导入/导出闭环维护
- 分组与批量删除维护

### M2: 与终端能力协同
- 评估“发送到终端”交接点
- 不在当前周引入独立终端产品边界

### M3: 历史能力
- 若后续需求确认，再新增命令历史页
- 补历史搜索与清理策略

## 风险与取舍

- 命令模块不再承接脚本库页面与脚本运行 UX
- `command_v2.dart` 中旧脚本 helper 后续可继续清理，但当前不作为 Week 4 评审阻塞

## 验收标准

- 契约偏差 issue 已登记并回填编号
- 命令模块链路对账表全部通过
- `flutter analyze` 通过
- `dart run test_runner.dart unit` 通过
- `dart run test_runner.dart ui` 通过
- 命令导入/导出主链路可回归

---

**文档版本**: 2.0
**最后更新**: 2026-03-27
