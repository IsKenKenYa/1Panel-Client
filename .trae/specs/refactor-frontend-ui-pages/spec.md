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

# 全量 614 API 端点完美覆盖与可用性深度检查 Spec

## Why
目前客户端已经成功封装并覆盖了 1Panel 后端全量的 614 个 API 端点。但“端点覆盖”仅仅是基础，我们需要深度验证这些端点的请求载荷（Payload）、返回模型（Response Model）的映射是否完美无瑕，同时确保我们已适配的核心功能模块（Dashboard、文件、应用、容器、主机等）在真实调用时不会因契约偏差、泛型丢失、或解析错误而导致功能不可用。目标是达到 100% 完美覆盖，功能处于完全可用状态。

## What Changes
- **API 载荷与实体模型深度审计**：消除由于 JSON 解析泛型丢失导致的 `dynamic` 或强转异常问题。
- **状态管理层（Provider/ViewModel）安全加固**：捕获由于异常返回、无配置环境导致的未处理异常，保障 UI 不崩溃。
- **核心模块可用性全面验证**：涵盖 Dashboard 数据大盘、主机、应用商店、容器管理、备份等模块的全链路调用。
- **请求方法与参数合规性校验**：确认 GET、POST 的 Query 参数与 Body 参数严格遵守 Swagger 定义。

## Impact
- Affected specs: 核心 API 客户端模块 (`lib/api/v2/`), 数据模型 (`lib/data/models/`), 状态管理层 (`lib/core/channel/`, `lib/features/`, `macos/Runner/UI/`)
- Affected code:
  - `lib/api/v2/*_v2.dart`
  - `lib/data/models/*.dart`
  - 各个业务模块的 ViewModel 和 Repository。

## ADDED Requirements
### Requirement: 100% API 契约严谨性
The system SHALL provide 强类型的数据解析，禁止在有具体业务实体定义的情况下返回 `dynamic`。

#### Scenario: Success case
- **WHEN** 客户端向 `/dashboard/current/top/cpu` 发起请求
- **THEN** 必须通过 `ProcessInfo.fromJson` 精确返回 `List<ProcessInfo>` 对象，而不是 `Response<dynamic>`。

## MODIFIED Requirements
### Requirement: 异常状态下的安全降级
所有的 API 调用及后台轮询机制在“无服务器配置（No API config available）”或“网络拒绝连接（Connection refused）”时，不得抛出致命异常导致应用白屏或引擎崩溃，必须安全降级或提示用户。

## REMOVED Requirements
### Requirement: 无类型的裸 JSON 透传
**Reason**: 容易在后续 UI 层获取字段时产生 Null 指针或类型强转错误。
**Migration**: 强制使用 `ApiResponseParser` 和 `Model.fromJson` 映射为 Dart 强类型对象。