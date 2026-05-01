# Replicate MDUI3 to Native UI Spec

## Why
当前通过 MethodChannel 搭建的原生 UI 骨架仅实现了基础的数据联通，UI 表现极其简陋（如侧边栏多语言失效显示 `nav_servers`，列表缺乏样式），导致原生 UI 模式处于不可用状态。为了让“原生 UI 模式”达到生产可用级别，需要详细复制当前 MDUI3（Material Design 3）的 UI 交互链路和视觉层级到四个平台（macOS, iOS, Windows, Linux）的原生代码中。

## What Changes
- **多语言透传**：通过 MethodChannel 将 Flutter 端的 i18n 多语言字典透传给各原生平台，修复侧边栏等位置的文本显示。
- **全平台同步铺开**：在 macOS (AppKit)、iOS (SwiftUI)、Windows (Win32/WinUI)、Linux (GTK) 四个平台上，同步推进所有模块（Servers, Files, Apps, Websites, Monitoring, Containers, Settings）的 UI 详细复制。
- **UI 逻辑迁移**：仅将与 UI 强相关的逻辑（如列表渲染、导航切换、弹窗交互）迁移到原生代码中。
- **复用核心逻辑**：坚决保留并复用 Dart 侧的 `lib/api/`, `lib/data/`, `lib/core/network`, `lib/core/services` 等核心模块，仅通过 Channel 桥接 UI 所需的数据和操作。

## Impact
- Affected specs: 原生壳层 UI (macOS, iOS, Windows, Linux)，跨端通道定义。
- Affected code:
  - `lib/core/channel/native_channel_manager.dart` (增加获取多语言等支撑接口)
  - `macos/Runner/` (AppKit 视图细化)
  - `ios/Runner/` (SwiftUI 视图细化)
  - `windows/runner/` (Windows 视图细化)
  - `linux/runner/` (GTK 视图细化)

## ADDED Requirements
### Requirement: 多语言桥接 (I18n Bridge)
The system SHALL provide a MethodChannel endpoint for native hosts to request translated strings using keys like `nav_servers`.

### Requirement: 原生 UI 视觉对齐 (Native UI Visual Alignment)
The system SHALL replicate the visual hierarchy, layout, and user flows of the MDUI3 Flutter implementation within the native UI frameworks of each platform, across all modules.

#### Scenario: Success case
- **WHEN** user opens the app in Native mode
- **THEN** the sidebar displays translated strings (e.g., "服务器" instead of `nav_servers`), and the content area displays a polished, native-styled list mirroring the MDUI3 layout.

## MODIFIED Requirements
### Requirement: 核心逻辑复用边界
All network requests, data modeling, and business logic SHALL remain in Dart. Native code SHALL ONLY handle view presentation and user input collection.