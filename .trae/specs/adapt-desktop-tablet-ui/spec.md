# 桌面端与平板端UI深度适配规范 (Desktop & Tablet UI Adaptation Spec)

## Why
目前 1Panel-Client 主要以移动端 UI 为主（MDUI），在桌面端（macOS/Windows/Linux）和平板端（iPadOS/Android Pad）的体验不佳，缺乏对应平台的原生交互质感与布局策略。需要根据不同操作系统特性提供“入乡随俗”的原生体验，同时确保底层数据与网络请求层完全共享，实现一套代码下的多端极致体验。

## What Changes
- 架构重组：新增平台 UI 分层（`lib/ui/mobile`, `lib/ui/desktop/common`, `lib/ui/desktop/macos`, `lib/ui/desktop/windows`），保留 `lib/api`, `lib/data`, `lib/core` 作为共享数据层。
- 入口分流：App 启动时判断 `TargetPlatform` 和 `formFactor`，进入对应的 UI 壳层。
- 导航分离：桌面端建立侧栏 + 内容区 + 顶部工具区导航框架；移动端保持底部导航。
- 桌面端系统风格分轨：
  - **macOS**：实现液态玻璃 (Liquid Glass) 效果，顶部菜单栏，大圆角，支持 Cmd 快捷键，隐藏原生标题栏。可能引入原生代码支持。
  - **Windows**：实现 Fluent Design (WinUI 3)，云母/亚克力材质，标准圆角，集成自定义标题栏，支持 Ctrl 快捷键。
  - **Linux**：复用合适的桌面 UI 组件。
- 平板端细化：
  - **iPadOS**：针对 iPadOS 优化交互和信息密度，适配妙控键盘及手势。
  - **Android Pad**：使用 Material You 动态色与大屏三栏布局。
- 交互模型分离：桌面端增加右键菜单、多选、快捷键、拖拽支持。移动端保持触控优先。

## Impact
- Affected specs: 应用整体架构、导航体系、各核心功能模块 (Server, Files, Settings 等)。
- Affected code:
  - `lib/main.dart` (应用入口)
  - `lib/ui/` (新增)
  - `lib/core/theme/` (主题系统重构)
  - `lib/core/router/` (路由分流逻辑)
  - `macos/`, `windows/` (原生代码适配，窗口控制)

## ADDED Requirements
### Requirement: 平台自适应启动与路由分流
The system SHALL identify the current platform and form factor at startup and route the user to the appropriate UI shell (mobile or desktop).

### Requirement: macOS 原生体验适配
The system SHALL provide a Liquid Glass experience on macOS, including a transparent/translucent window, custom macOS-style dock menu, and native keyboard shortcuts.

### Requirement: Windows Fluent Design 适配
The system SHALL provide a Fluent Design experience on Windows 11, utilizing Mica/Acrylic materials, a custom integrated title bar, and native Windows keyboard shortcuts.

### Requirement: 平板端三栏布局与高信息密度
The system SHALL utilize a 3-column layout on Android Pad and iPadOS to maximize screen real estate and increase information density.

## MODIFIED Requirements
### Requirement: 核心页面的多端呈现
The existing Server, Files, and Settings pages SHALL be refactored to separate the UI layer from the logic/data layer, allowing them to be rendered differently on mobile vs. desktop/tablet.

## REMOVED Requirements
None
