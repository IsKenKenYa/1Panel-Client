# Frontend UI Pages Refactor Spec

## Why
在后端全量 614 个 API 完美对接并实现底层降级保护之后，前端 UI 层面可能依然存在因为旧逻辑、接口数据结构变化导致的渲染问题或交互断层。我们需要推进特定前端 UI 页面（尤其是核心模块：Dashboard、容器、应用、文件、网站等）的深度重构与检查，确保从用户点击到数据返回渲染的完整链路处于完美、高可用状态。

## What Changes
- **全链路页面检查与重构**：逐个遍历各模块的入口 UI，检查 ListView 渲染、详情展示页、模态弹窗（Dialog/BottomSheet）的数据绑定是否安全。
- **状态同步异常修复**：修复在下拉刷新、后台轮询机制中由于空状态（null/empty array）导致的页面白屏。
- **用户交互闭环验证**：确保对每一个列表项的操作（如启动/停止容器，安装应用，编辑文件，刷新指标）不仅发送了 API 请求，UI 还能正确呈现 Loading 和 Success/Error 提示。

## Impact
- Affected specs: 核心业务视图 (`lib/features/*/views/`)
- Affected code:
  - `lib/features/dashboard/views/`
  - `lib/features/containers/views/`
  - `lib/features/apps/views/`
  - `lib/features/files/views/`
  - `lib/features/websites/views/`

## ADDED Requirements
### Requirement: 100% 页面零崩溃 (Zero-Crash UI)
The system SHALL provide 所有的页面，即使接收到残缺或空数组数据，也必须呈现 Empty State 而不是抛出 Widget 渲染错误。

#### Scenario: Success case
- **WHEN** user 打开容器列表，但返回的容器数量为 0 或网络较差
- **THEN** 界面展示带有“暂无容器”的缺省页，且下拉刷新机制可用。

## MODIFIED Requirements
### Requirement: 操作反馈闭环
对于用户的写操作（修改、删除、创建），必须通过 Snackbar、Toast 或内联提示给出成功或失败的反馈。

## REMOVED Requirements
### Requirement: 无限制的大量未处理异常日志
**Reason**: 对业务无益，可能导致终端卡顿。
**Migration**: 统一切换到 `appLogger` 的温和输出和友好的 UI 提示机制。