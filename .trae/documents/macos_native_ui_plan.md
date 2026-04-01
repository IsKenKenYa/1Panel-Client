# macOS 原生 UI 层详细规划 (macOS Native UI Layer Plan)

## 1. 概述 (Summary)
根据 `migrate-to-native-ui` 和 `replicate-mdui3-to-native-ui` 规范，macOS 端将彻底剥离 Flutter UI，采用纯原生技术栈重写。
结合当前现状与确认的意图，**macOS 的原生 UI 层将从当前的 AppKit (NSTableView/NSViewController) 迁移到 SwiftUI**。
核心原则：**极简 UI 层**。SwiftUI 仅负责界面渲染、MDUI3 视觉还原和用户交互收集；所有的网络请求、数据模型、业务状态管理、主题状态均保留在 Dart 端，通过 `FlutterMethodChannel` / `FlutterEventChannel` 桥接。

## 2. 当前状态分析 (Current State Analysis)
- **UI 框架**：目前使用纯 AppKit（如 `NSTableView`, `NSStackView`）构建。
- **代码组织**：所有的模块 UI（Servers, Files, Apps 等）和主侧边栏均堆砌在 `macos/Runner/MainShellViewController.swift` 中，单文件超过 800 行，缺乏可维护性。
- **视觉体验**：目前仅实现了最基础的数据联通，没有 MDUI3（Material Design 3）的视觉层级（如圆角卡片、阴影、动态取色等），不支持主题动态切换。
- **架构分离**：虽然数据通过 Channel 获取，但没有明确的 ViewModel 隔离层，视图代码与 Channel 调用耦合。

## 3. 架构设计与职责划分 (Architecture & Responsibilities)
为了保证“仅 UI 在原生，业务在 Dart，且支持主题切换”，架构设计如下：

### 3.1 SwiftUI + ViewModel (Proxy) 模式
- **View (SwiftUI)**：纯声明式 UI，负责构建 MDUI3 风格的界面。
- **ViewModel (ObservableObject)**：作为数据的搬运工（Proxy）。不包含业务逻辑，仅负责调用 `ChannelManager` 发送请求给 Dart，并将 Dart 返回的 Dictionary/JSON 转换为 Swift Struct 供 View 渲染。

### 3.2 主题与多语言桥接 (Theme & I18n Bridge)
- **ThemeManager (Swift)**：监听 Dart 端发出的主题变更事件（浅色/深色模式、Seed Color、MDUI3 颜色令牌），并将其转化为 SwiftUI 的 `Environment` 或全局 `Color` 扩展，使得 SwiftUI 组件能实时响应 Flutter 端的主题切换。
- **TranslationsManager (Swift)**：复用现有的多语言通道，在 SwiftUI 中通过自定义修饰符或方法获取本地化字符串。

## 4. 文件结构拆分规划 (Proposed File Structure)
在 `macos/Runner/` 下新建 `UI/` 目录，彻底打散原有的单文件结构：

```text
macos/Runner/
├── UI/
│   ├── Core/                         # 核心桥接层
│   │   ├── ChannelManager.swift      # 统一管理 FlutterMethodChannel
│   │   ├── ThemeManager.swift        # 监听 Dart 主题变更并提供 SwiftUI 颜色令牌
│   │   └── TranslationsManager.swift # 现有的多语言管理器（迁移至此）
│   ├── Components/                   # MDUI3 风格的可复用 SwiftUI 组件
│   │   ├── MDCard.swift              # MDUI3 卡片 (16dp 圆角, 对应 Elevation)
│   │   ├── MDButton.swift            # MDUI3 按钮 (Filled, Outlined, Text)
│   │   └── MDTextField.swift         # MDUI3 输入框
│   ├── Modules/                      # 按业务模块划分的 View 与 ViewModel
│   │   ├── Shell/
│   │   │   ├── MainShellView.swift   # 替代 NSSplitViewController 的主界面
│   │   │   └── SidebarView.swift     # 左侧导航栏
│   │   ├── Servers/
│   │   │   ├── ServersView.swift
│   │   │   └── ServersViewModel.swift
│   │   ├── Files/
│   │   │   ├── FilesView.swift
│   │   │   └── FilesViewModel.swift
│   │   ├── Apps/
│   │   │   └── ... (View & ViewModel)
│   │   ├── Websites/
│   │   │   └── ... (View & ViewModel)
│   │   ├── Monitoring/
│   │   │   └── ... (View & ViewModel)
│   │   ├── Containers/
│   │   │   └── ... (View & ViewModel)
│   │   └── Settings/
│   │       └── ... (View & ViewModel)
├── MainShellViewController.swift     # 将被大幅精简，仅作为 NSHostingController 的容器
└── AppDelegate.swift
```

## 5. 详细实施步骤 (Implementation Steps)

### 第一阶段：基础设施与桥接层建设 (Infrastructure & Bridge)
1. **建立 ChannelManager**：创建一个单例管理与 Flutter 的通信，封装 `invokeMethod`，提供基于 async/await 或 completion handler 的接口。
2. **实现 ThemeManager**：
   - 在 Dart 端（如 `native_channel_manager.dart`）增加向 macOS 发送当前主题配色数据（JSON 格式，包含 primary, surface, background 等 MD3 颜色）的逻辑。
   - 在 macOS 端解析这些颜色并生成 SwiftUI 可用的 `Color` 对象。
3. **入口改造**：修改 `MainShellViewController`，使用 `NSHostingController` 将根视图替换为 `MainShellView` (SwiftUI)。

### 第二阶段：MDUI3 组件库封装 (MDUI3 Components)
1. 使用 SwiftUI 实现基础的 Material Design 3 组件：
   - **MDCard**：支持不同的 Material 3 填充模式（Elevated, Filled, Outlined），默认 16pt 圆角。
   - **MDList / MDListItem**：对齐 MD3 的列表视觉规范，支持图标和多行文本。
   - 结合 `ThemeManager` 确保这些组件的颜色能够动态响应主题切换。

### 第三阶段：业务模块迁移 (Module Migration)
针对每一个子模块（Servers, Files, Apps, Websites, Monitoring, Containers, Settings），执行以下重构：
1. **创建 ViewModel**：例如 `FilesViewModel`，内部暴露 `@Published var files: [FileModel] = []`，通过 `ChannelManager` 请求 Dart 端的 `getFiles` 方法更新数据。
2. **创建 View**：使用 SwiftUI 编写界面，绑定 ViewModel。使用刚刚封装的 `MDCard` 和 `MDList` 展示数据。
3. **销毁旧代码**：每完成一个模块，就从旧的 `MainShellViewController.swift` 中删除对应的 AppKit 类（如 `MacosFilesViewController`）。

### 第四阶段：收尾与体验优化 (Polish & Optimization)
1. 确保侧边栏 (`SidebarView`) 的交互体验与 macOS 原生习惯（如半透明材质 `Material.sidebar`）结合，同时保留项目要求的视觉层级。
2. 测试主题切换链路：在 Dart 端切换主题后，验证 macOS 原生 UI 是否能无缝跟随变色。
3. 彻底移除旧的 `MainShellViewController.swift` 中残留的 AppKit UI 代码。

## 6. 假设与约束 (Assumptions & Constraints)
- **Dart 侧准备**：假设 Dart 端已具备提供所有业务数据和主题数据的 Channel 接口；如果缺少（如主题色透传接口），需要在本计划实施时同步在 Dart 侧补充。
- **系统版本**：由于现有项目已经限制 `if #available(macOS 11.0, *)`，SwiftUI 迁移将以此为基础基线。部分高级 SwiftUI API 可能需要做 macOS 11 的兼容处理。