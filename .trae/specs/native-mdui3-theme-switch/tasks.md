# Tasks
- [x] Task 1: 状态管理与持久化配置
  - [x] SubTask 1.1: 在 `ThemeController` 中引入 `uiRenderMode` (Native / MD3) 状态，并与 `SharedPreferences` 绑定进行持久化。
  - [x] SubTask 1.2: 在 `lib/main.dart` 启动阶段增加 `getUIRenderMode` 的 MethodChannel 回调，以便原生壳能在显示视图前获取配置。
- [x] Task 2: Flutter 与原生层的启动握手
  - [x] SubTask 2.1: 改造 macOS 原生启动逻辑 (`MainFlutterWindow.swift` 和 `MainShellViewController.swift`)：根据引擎返回的 `getUIRenderMode`，决定是将 FlutterView 添加到主窗口，还是继续使用 `MacosServersViewController` 等纯原生界面。
  - [x] SubTask 2.2: 改造 iOS / Windows / Linux 启动逻辑，根据渲染模式挂载对应的视图结构。
- [x] Task 3: 补充剩余功能的原生数据接口
  - [x] SubTask 3.1: 在 `lib/core/channel/native_channel_manager.dart` 中，暴露 Apps, Websites, Monitoring 等模块的数据。
- [x] Task 4: 补充剩余功能的原生界面实现
  - [x] SubTask 4.1: 在 macOS 侧使用 `AppKit` (如 `NSTableView`) 完成 Apps、Websites 列表界面。
  - [x] SubTask 4.2: 在 iOS 侧使用 `SwiftUI` 完成 Apps、Websites 列表界面。
  - [x] SubTask 4.3: 在 Windows/Linux 侧为新加的模块添加基本的列表骨架与数据显示。
- [x] Task 5: 设置界面的主题切换开关
  - [x] SubTask 5.1: 在 Flutter 端的 Settings 页面增加 "UI 渲染模式 (Native / MDUI3)" 切换选项，并提示用户重启应用生效（或实现热切换）。
  - [x] SubTask 5.2: 在 macOS / iOS 等原生端的 Settings 页面实现同样的切换选项与持久化通道写入接口。
- [x] Task 6: 修复缺失的原生 UI 呈现 (Checkpoint 4 失败修复)
  - [x] SubTask 6.1: 在 macOS 的 Sidebar 中添加 Apps、Websites、Monitoring 导航，并实现 `MacosMonitoringViewController`。
  - [x] SubTask 6.2: 在 iOS 的 TabBar 中添加 Monitoring 导航，并实现 `MonitoringView`。
  - [x] SubTask 6.3: 在 Windows 的 listbox 中追加渲染 Apps、Websites、Monitoring 模块数据。
  - [x] SubTask 6.4: 在 Linux 的 tree view 中追加渲染 Apps、Websites、Monitoring 模块数据。

# Task Dependencies
- Task 2 depends on Task 1
- Task 4 depends on Task 3
- Task 5 depends on Task 1 and 2