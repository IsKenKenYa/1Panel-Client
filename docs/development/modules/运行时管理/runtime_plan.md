# 运行时管理模块开发计划

## Phase 1 周计划对齐

### Week 7 已完成

- `RuntimesCenterPage`
- `RuntimeDetailPage`
- `RuntimeFormPage`
- `RuntimeRepository`
- `RuntimeService`
- `RuntimesProvider`
- `RuntimeDetailProvider`
- `RuntimeFormProvider`
- route placeholder 替换为真实页面
- runtime API client / provider / widget / route / no-server 回归测试

## Week 7 交付边界

### 已纳入

- 通用 runtime 列表
- 通用 runtime 详情
- 通用 runtime 表单骨架
- `start / stop / restart / sync / remark / delete`
- 语言分类入口

### 明确未纳入

- PHP 扩展管理
- PHP/FPM 深配置
- Node modules
- Node scripts
- 多语言完整创建向导

## 收口标准

- `AppRoutes.runtimes` / `runtimeDetail` / `runtimeForm` 已替换 placeholder
- 页面遵守 `Presentation -> State -> Service/Repository -> API/Infra`
- no-server 场景不提前打 API
- 所有用户可见文本进入 l10n
- `flutter analyze` 通过
- `dart run test_runner.dart unit` 通过
- `dart run test_runner.dart ui` 通过
- 覆盖矩阵与模块文档同步更新

## 剩余风险

- `appstore create` 与 `PHP create` 仍保留到 Week 8
- 删除前依赖检查尚未接入移动端主 UI
- 语言特定深配置仍未开放，不影响当前通用主链路可评审/可测试/可用

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
