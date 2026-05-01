# Tasks

- [x] Task 1: 架构骨架搭建与平台壳层入口分离
  - [x] SubTask 1.1: 创建 `lib/ui/mobile`, `lib/ui/desktop/common`, `lib/ui/desktop/macos`, `lib/ui/desktop/windows`, `lib/ui/tablet` 目录结构。
  - [x] SubTask 1.2: 在 `lib/core/` 中实现平台与设备形态检测服务 (`formFactor` & `TargetPlatform`)。
  - [x] SubTask 1.3: 重构 `main.dart` 和路由系统，根据平台检测结果跳转至对应的导航壳层 (Mobile Shell vs Desktop Shell)。
- [x] Task 2: 桌面端与平板端基础导航与主题系统构建
  - [x] SubTask 2.1: 构建 macOS 桌面端专属主题 (`AppTheme` 自适应逻辑) 与导航壳层（侧栏 + 顶部工具栏）。
  - [x] SubTask 2.2: 构建 Windows 桌面端专属主题 (Mica/Acrylic) 与导航壳层（自定义标题栏集成 + 侧栏）。
  - [x] SubTask 2.3: 构建平板端（iPadOS / Android Pad）三栏布局基础框架及 Material You 动态色适配。
- [x] Task 3: 桌面端原生窗口与材质集成
  - [x] SubTask 3.1: 引入并配置 `bitsdojo_window` / `window_manager` 处理自定义窗口和标题栏。
  - [x] SubTask 3.2: 引入 `flutter_acrylic` 等库实现 Windows 云母/亚克力材质及 macOS 液态玻璃/半透明效果，必要时编写 macOS 原生 (Swift) 代码。
  - [x] SubTask 3.3: 引入菜单栏库 (如 `macos_dock_menu`) 并集成系统级菜单及快捷键响应。
- [x] Task 4: 交互模型适配
  - [x] SubTask 4.1: 实现全局与页面级快捷键监听 (Cmd vs Ctrl 差异化)。
  - [x] SubTask 4.2: 为列表和文件管理器添加桌面端右键菜单、拖拽及 Shift/Ctrl 多选支持。
- [x] Task 5: 核心页面迁移与适配（一期目标）
  - [x] SubTask 5.1: 抽离 Server 页面的 UI 与 ViewModel，实现 Mobile/macOS/Windows 差异化 UI。
  - [x] SubTask 5.2: 抽离 Files 页面的 UI 与 ViewModel，实现 Mobile/macOS/Windows 差异化 UI。
  - [x] SubTask 5.3: 抽离 Settings 页面的 UI 与 ViewModel，实现 Mobile/macOS/Windows 差异化 UI。
- [x] Task 6: 修复并完善桌面端快捷键与圆角 UI (Checklist 问题修复)
  - [x] SubTask 6.1: 在 macOS Shell 中添加 `ClipRRect` 修复内容区域圆角，并使用 `CallbackShortcuts` 实现 Cmd 快捷键切换模块。
  - [x] SubTask 6.2: 在 Windows Shell 中添加 `ClipRRect` 修复内容区域圆角，并使用 `CallbackShortcuts` 实现 Ctrl 快捷键切换模块。

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4 depends on Task 2
- Task 5 depends on Task 1, Task 2, and Task 4
