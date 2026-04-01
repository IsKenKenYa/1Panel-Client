# Migrate to Native UI Spec

## Why
为了在非 Android 平台上实现最极致、最符合各操作系统“入乡随俗”特性的原生体验，除了保留 Android 的 Flutter UI 外，其余操作系统（macOS、iOS、Windows、Linux）将彻底放弃 Flutter 渲染的 UI 层，转而使用各自平台的原生技术（如 SwiftUI、WinUI 3、GTK 等）重写 UI。Flutter 在这些非 Android 平台上将“降级”为核心逻辑引擎（Core Logic Engine），仅负责数据获取、网络请求、本地存储、状态管理等非 UI 业务逻辑。我们不适配 Web 端。

## What Changes
- **BREAKING**: 非 Android 平台的 UI 渲染将由 Flutter 切换为纯原生代码。
- Flutter 端新增跨平台通信层（MethodChannel/EventChannel），将核心业务逻辑（API 请求、数据模型、业务状态）暴露给原生 UI 调用。
- 改造 `main.dart`，在非 Android 平台支持 Headless（无视图）模式或纯通信模式启动。
- 各平台的原生工程（`macos/`, `ios/`, `windows/`, `linux/`）引入各自的原生 UI 框架并彻底接管视图控制权，仅将 Flutter 作为后台引擎服务运行。

## Impact
- Affected specs: 应用整体架构、渲染机制、跨端通信方案。
- Affected code:
  - `lib/main.dart` 及底层逻辑暴露层
  - `macos/Runner/` (使用 SwiftUI/AppKit 重写)
  - `ios/Runner/` (使用 SwiftUI 重写)
  - `windows/runner/` (使用 WinUI 3 重写)
  - `linux/linux/` (使用 GTK 或 Qt 重写)

## ADDED Requirements
### Requirement: 跨端逻辑引擎层 (Flutter Core Engine)
The system SHALL expose all business logic (data fetching, state changes) via Platform Channels for native UI consumption on non-Android platforms.

### Requirement: 原生 UI 接管 (Native UI Takeover)
The system SHALL use SwiftUI/AppKit for Apple platforms, WinUI 3 for Windows, and native frameworks for Linux to render the UI, completely bypassing the Flutter widget tree.

## MODIFIED Requirements
### Requirement: 路由与视图分发
Flutter 内部的路由和 UI 组件将仅在 Android 平台生效。其余平台原生应用在启动 Flutter Engine 后，不附加 FlutterViewController/FlutterView，而是挂载纯原生 View。

## REMOVED Requirements
### Requirement: 桌面端与非 Android 平板端 Flutter UI 适配
**Reason**: 彻底转向原生 UI，原有的基于 Flutter 的桌面端与平板端 UI 适配（如 `lib/ui/desktop/`、`lib/ui/tablet/` 等，非 Android 部分）将被废弃。
**Migration**: 逻辑抽离至 Channel 层，UI 逻辑完全交由原生工程实现。