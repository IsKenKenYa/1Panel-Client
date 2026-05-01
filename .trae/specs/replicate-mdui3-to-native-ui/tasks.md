# Tasks

- [x] Task 1: Flutter 端支撑能力建设 (多语言透传与通道补全)
  - [x] SubTask 1.1: 在 `NativeChannelManager` 中新增 `getTranslations` 方法，返回当前语言环境下的全量键值对（用于修复 `nav_servers` 等占位符）。
  - [x] SubTask 1.2: 根据需要补充 Containers 等其余模块的数据获取通道方法，确保原生 UI 能拉取到全模块的渲染数据。

- [x] Task 2: macOS 原生 UI 详细复制 (AppKit)
  - [x] SubTask 2.1: 在 macOS 启动时拉取并缓存多语言字典，修复 `MacosSidebarViewController` 中的显示问题。
  - [x] SubTask 2.2: 优化 `MacosServersViewController` 和 `MacosFilesViewController`，应用 macOS 原生的边距、圆角、分割线等视觉效果，对齐 MD3 数据密度。
  - [x] SubTask 2.3: 完成 Apps, Websites, Monitoring, Containers, Settings 模块的界面细节复制。

- [x] Task 3: iOS 原生 UI 详细复制 (SwiftUI)
  - [x] SubTask 3.1: 桥接多语言数据，修复 `TabView` 中的标签名称。
  - [x] SubTask 3.2: 使用 SwiftUI 完善 Servers 和 Files 模块的列表卡片 (Card/ListRow) 样式，对齐移动端 MD3 设计。
  - [x] SubTask 3.3: 完成其余模块 (Apps, Websites, Monitoring, Containers, Settings) 的 UI 细化。

- [x] Task 4: Windows 原生 UI 详细复制
  - [x] SubTask 4.1: 建立 C++ 侧的多语言字典缓存机制，替换侧边栏/列表头部的占位符。
  - [x] SubTask 4.2: 将 Win32 的简陋 ListBox 升级为包含多列、具备更好样式的原生控件（或 WinUI 3 XAML Islands），并填充 Servers 与 Files 模块的数据展示。
  - [x] SubTask 4.3: 铺开至 Apps, Websites, Monitoring, Containers, Settings 模块。

- [x] Task 5: Linux 原生 UI 详细复制 (GTK)
  - [x] SubTask 5.1: 建立 C++ (GTK) 侧的多语言字典，替换 UI 文本。
  - [x] SubTask 5.2: 优化 `GtkTreeView` 的列布局和边距，使其接近原生桌面应用标准，完善 Servers 与 Files 模块。
  - [x] SubTask 5.3: 铺开至 Apps, Websites, Monitoring, Containers, Settings 模块。

# Task Dependencies
- Task 2, 3, 4, 5 depend on Task 1 (需要获取到正确的多语言字典和完整数据)
- Task 2, 3, 4, 5 可以并行进行。