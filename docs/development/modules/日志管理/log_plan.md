# 日志管理模块开发计划

## Phase 1 周计划对齐

### Week 6 已完成

- `LogsCenterPage`
- `SystemLogViewerPage`
- `TaskLogDetailPage`
- `LogsRepository`
- `TaskLogRepository`
- `LogsService`
- `LogsProvider`
- `SystemLogsProvider`
- `TaskLogsProvider`
- route placeholder 替换为真实页面
- API client tests / provider tests / widget tests / no-server 回归

## Week 6 交付边界

### 已纳入

- 操作日志列表
- 登录日志列表
- 任务日志列表
- 系统日志文件列表
- 任务日志详情
- 系统日志正文查看
- `files/read` 按行读取适配

### 明确未纳入

- website logs
- ssh logs
- log clean UI
- export UI
- runtime / toolbox / Phase 2 范围

## 收口标准

- `AppRoutes.logs` / `AppRoutes.systemLogViewer` / `AppRoutes.taskLogDetail` 已替换 placeholder
- 页面遵守 `Presentation -> State -> Service/Repository -> API/Infra`
- no-server 场景不提前打 API
- 所有用户可见文本进入 l10n
- `flutter analyze` 通过
- `dart run test_runner.dart unit` 通过
- `dart run test_runner.dart ui` 通过
- 覆盖矩阵与模块文档同步更新

## 剩余风险

- `website` / `ssh` 日志尚未并入日志中心
- `clean logs` / `export logs` 的 destructive 成功流仍未进入移动端主 UI
- 大文件/长日志的高级 tail 策略仍可继续优化，但不影响当前 MVP 可用性

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
