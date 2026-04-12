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
- 所有的 API 调用及后台轮询机制在“无服务器配置（No API config available）”或“网络拒绝连接（Connection refused）”时，不得抛出致命异常导致应用白屏或引擎崩溃，必须安全降级或提示用户。

## REMOVED Requirements
### Requirement: 无类型的裸 JSON 透传
**Reason**: 容易在后续 UI 层获取字段时产生 Null 指针或类型强转错误。
**Migration**: 强制使用 `ApiResponseParser` 和 `Model.fromJson` 映射为 Dart 强类型对象。