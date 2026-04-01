# Tasks
- [x] Task 1: 更新全局规则与指南: 修改 `.trae/rules/ui_rules.md` 和 `AGENTS.md`，写入真原生设计原则（如 macOS 液态玻璃）与 Dart 架构六层职责分离约束。
- [x] Task 2: 移除并重构 macOS 组件层: 删除 macOS 工程中仿造 MDUI3 的 UI 组件（如 `MDCard.swift`, `MDList.swift` 等）。
- [x] Task 3: 适配 macOS 真原生视觉 (Shell): 优化 `MainShellView` 和 `SidebarView`，使用 macOS 的 `List(selection:)` 配合 `NavigationSplitView` 或相应的原生边栏材质，实现液态玻璃（Liquid Glass）效果。
- [x] Task 4: 适配 macOS 真原生视觉 (模块页): 将 Servers、Files、Apps、Websites、Monitoring、Containers、Settings 等业务模块视图，使用原生的 `Table` 或原生 `List` 进行重构，彻底拥抱 macOS 15+ 的设计规范。

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 3]
