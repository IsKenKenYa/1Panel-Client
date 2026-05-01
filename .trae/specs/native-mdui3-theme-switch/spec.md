# Native UI and MDUI3 Theme Switch Spec

## Why
用户希望在所有操作系统上将功能 UI 转换为原生 UI，同时依然共享 API 和 Model 等底层逻辑。更重要的是，为了兼顾习惯和灵活性，需要提供一个能在“原生 UI”和“Flutter MDUI3”之间无缝切换的方案。这要求应用具备一套统一的主题状态管理和渲染切换机制。

## What Changes
- 引入 `ThemeType` 枚举（如 `native`, `md3`），统一作为渲染模式标识。
- 在 `ThemeController` 中增加 `uiRenderMode` 偏好设置的读取与持久化保存（利用 `SharedPreferences`）。
- 改造应用启动逻辑：原生端在启动应用时，先向 Flutter Engine 请求当前的渲染模式。如果为 `native`，则在非 Android 平台上挂载纯原生 UI（如 SwiftUI/AppKit/WinUI 3）；如果为 `md3`，则直接挂载完整的 Flutter 视图树（Material Design 3）。
- 将剩余的业务模块（Apps, Websites, Monitoring 等）数据接口暴露给 MethodChannel。
- 在原生 UI 侧补充实现剩余的业务界面。

## Impact
- Affected specs: 应用架构、状态管理、多端混合启动流程。
- Affected code:
  - `lib/core/theme/theme_controller.dart`
  - `lib/main.dart`
  - 各平台原生壳代码 (`macos/`, `ios/`, `windows/`, `linux/`)。
  - 各平台原生界面模块 (如 `Apps`, `Websites`, `Settings`)。

## ADDED Requirements
### Requirement: 动态渲染模式切换 (Dynamic UI Render Mode Switch)
The system SHALL allow users to switch between Native UI and Flutter MDUI3 on non-Android platforms, retaining the underlying logic.

#### Scenario: Success case
- **WHEN** user selects "MDUI3" in settings and restarts/applies
- **THEN** the app attaches the FlutterViewController and renders the Flutter Material Design 3 widget tree.
- **WHEN** user selects "Native" in settings and restarts/applies
- **THEN** the app uses the native platform UI via channels and leaves Flutter in headless mode.

## MODIFIED Requirements
### Requirement: 主题持久化与启动检测
The system SHALL persist the user's UI preference, and the native host SHALL query this preference immediately upon starting the Flutter engine.