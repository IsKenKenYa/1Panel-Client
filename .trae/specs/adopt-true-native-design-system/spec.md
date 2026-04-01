# Adopt True Native Design System Spec

## Why
用户澄清了跨平台 UI 的最终愿景：除了 Web 端之外，所有桌面/移动端操作系统（macOS、Windows、iOS、Linux）不仅要使用原生代码渲染，还必须采用各自平台**最地道的设计语言与视觉规范**（例如 macOS 15 及未来的 macOS 26 的液态玻璃/Vibrancy 设计，Windows 的 Fluent Design 等），而不是用原生代码去生硬地复刻 Material Design 3 (MDUI3)。Dart 端则作为纯粹的“逻辑引擎”运行，安全地保留状态管理、服务、数据仓库、模型、API 和核心配置。

## What Changes
- **BREAKING**: 废弃 `replicate-mdui3-to-native-ui` 规范，不再要求各原生平台对齐 MDUI3。
- **BREAKING**: 更新工作区规则文件（`.trae/rules/ui_rules.md`、`AGENTS.md`），明确“真·原生设计语言”与“Dart核心架构严格分层”的红线。
- macOS 端：使用 SwiftUI 重写所有模块视图，全面采用 macOS 原生设计规范（如 Sidebar 材质、半透明毛玻璃效果 Liquid Glass、原生 Toolbar、原生 Table 等），移除所有强行复刻 MDUI3 的自定义组件（如 MDCard）。
- Dart 端架构边界：明确区分并保护 Dart 端的六大核心层（State, Service, Repository, Model, API/Infra, Core/Config），所有这些层的逻辑**绝对禁止**用原生代码重写（除涉及系统底层 API 外）。
- 主题支持：后续补充 Dart 端的主题配色（深色/浅色模式、Seed Color）通过 MethodChannel 分发至原生端，由原生端接管渲染，实现全链路的动态换肤。

## Impact
- Affected specs: `replicate-mdui3-to-native-ui` (废弃), `migrate-to-native-ui` (更新).
- Affected code:
  - `.trae/rules/ui_rules.md`
  - `AGENTS.md`
  - `macos/Runner/UI/` 目录下的 SwiftUI 视图和 ViewModel 组件。

## ADDED Requirements
### Requirement: 真原生设计语言适配
The system SHALL use the authentic native design language for each respective platform (e.g., Liquid Glass/Vibrancy for macOS, Fluent Design for Windows, Human Interface Guidelines for iOS, GTK for Linux) instead of replicating Material Design 3.

#### Scenario: Success case
- **WHEN** user runs the macOS app on macOS 15+
- **THEN** the app displays a native sidebar with translucent material (Liquid Glass) and native table views, feeling like a first-class macOS citizen.

### Requirement: 核心架构 Dart 化严格约束
The system SHALL retain all non-UI logic (State Layer, Service Layer, Repository Layer, Data Model Layer, API/Infra Layer, Core/Config Layer) strictly in Dart.

## MODIFIED Requirements
### Requirement: 跨端 UI 渲染策略
All non-Web platforms SHALL use their respective native frameworks (SwiftUI, WinUI 3, etc.) for the Presentation Layer, integrating with Dart business logic via Flutter Channels.

## REMOVED Requirements
### Requirement: MDUI3 原生代码复刻
**Reason**: 用户明确拒绝使用原生代码强行复刻 MDUI3，要求“入乡随俗”。
**Migration**: 移除 macOS 中刚建立的 `MDCard`、`MDList` 等仿 MDUI3 的组件，改用 SwiftUI 原生样式。
