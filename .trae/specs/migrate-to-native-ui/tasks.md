# Tasks
- [x] Task 1: 架构核心通信层搭建 (Flutter)
  - [x] SubTask 1.1: 创建 `lib/core/channel/` 目录，封装 `MethodChannel` 与 `EventChannel`，暴露 `Server`、`Files` 等核心逻辑给原生的接口集合。
  - [x] SubTask 1.2: 重构 `main.dart`，根据平台判断是否以 Headless/Engine-only 模式运行（仅 Android 加载 Flutter 视图树，其余平台仅启动引擎）。
- [x] Task 2: 苹果生态原生 UI 骨架搭建 (macOS / iOS)
  - [x] SubTask 2.1: 在 `macos/Runner/` 中引入 SwiftUI/AppKit 骨架，接管 `MainFlutterWindow`，并将 FlutterEngine 作为后台逻辑服务运行。
  - [x] SubTask 2.2: 在 `ios/Runner/` 中引入 SwiftUI 骨架，并建立与 Flutter Engine 的 Channel 通信接口。
- [x] Task 3: Windows 原生 UI 骨架搭建 (Windows)
  - [x] SubTask 3.1: 在 `windows/runner/` 中引入 WinUI 3 框架，接管原有的 Win32 窗口体系。
  - [x] SubTask 3.2: 实现 Windows C++ 层与 Flutter Engine 的 Channel 通信对接与数据解析。
- [x] Task 4: Linux 原生 UI 骨架搭建 (Linux)
  - [x] SubTask 4.1: 在 `linux/` 目录中搭建 GTK 或其他原生 UI 框架，并对接 Flutter Engine 的 Channel。
- [x] Task 5: 业务模块原生 UI 逐步迁移 (一期：Server & Files)
  - [x] SubTask 5.1: 通过 Channel 彻底打通 Server 和 Files 模块的数据交互。
  - [x] SubTask 5.2: 分别在 macOS/iOS/Windows/Linux 原生侧实现各自平台对应的原生 Server 列表与 Files 界面。

- [x] Task 6: 修复 Windows 工程的 WinUI 3 原生界面渲染
  - [x] 移除 Windows 平台默认的 Win32 窗口体系。
  - [x] 引入 WinUI 3（通过 Windows App SDK / XAML Islands）。
  - [x] 实现原生的 WinUI 3 主界面骨架。

- [x] Task 7: 修复 Linux 工程的 GTK 原生界面渲染
  - [x] 扩展 Linux 平台默认的 GTK 窗口体系，添加原生侧边栏或导航骨架。
  - [x] 脱离纯 `FlView` 的全屏覆盖渲染，改为区域嵌入或隐藏式引擎。

- [x] Task 8: 修复各平台 Server 与 Files 模块的原生 UI 呈现数据功能
  - [x] macOS：为 Servers 和 Files 模块实现 `NSTableView` 列表来展示数据。
  - [x] Windows：基于 WinUI 3 实现 Servers 和 Files 模块的列表视图。
  - [x] Linux：基于 GTK 实现 Servers 和 Files 模块的 `GtkTreeView` 或 `GtkListBox`。

# Task Dependencies
- Task 2, 3, 4 depend on Task 1
- Task 5 depends on Task 2, 3, 4
