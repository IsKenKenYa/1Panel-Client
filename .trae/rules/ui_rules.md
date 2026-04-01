# UI设计规范

## Material Design 3 (MDUI3) 规范

### 核心原则
- **一致性**: 所有UI组件必须遵循Material Design 3设计语言
- **动态色彩**: 使用MDUI3的动态色彩系统(Material You)
- **圆角设计**: 卡片16dp，按钮全圆角
- **阴影层级**: 使用MDUI3的elevation系统

### 组件规范

| 组件类型 | 规范要求 |
|---------|---------|
| 卡片 | `Card` 或 `Card.filled`，圆角 16dp |
| 按钮 | `FilledButton`、`OutlinedButton`、`TextButton` |
| 输入框 | `TextField` + `OutlineInputBorder` |
| 导航 | `NavigationBar`(底部) / `NavigationRail`(侧边) |
| 对话框 | `AlertDialog` 配合 MDUI3 样式 |

### 主题配置
```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  ),
);
```

## 平台适配与渲染策略

### Android 与 Android 平板
- **渲染方案**：完全使用 Dart 代码渲染 Material Design 3 (MDUI3) 规范。
- **视觉特性**：支持动态取色(Dynamic Colors)，适配 Android 12+ 视觉特性。

### 其他平台 (macOS, iOS, Windows, Linux)
- **渲染方案**：默认必须使用各自平台的**原生代码**实现原生系统的原生 UI 和**原汁原味的交互逻辑**（例如 macOS 的 SwiftUI、Windows 的 Fluent Design）。禁止使用原生代码去强行复刻 MDUI3。
- **Dart 架构边界**：Dart 端仅作为“核心逻辑引擎”，保留状态管理层 (State)、服务层 (Service)、数据仓库层 (Repository)、模型层 (Model)、API 层和配置层。所有网络请求与数据拼装安全地复用 Dart。
- **UI 模式切换**：支持通过设置切换为“用 Dart 代码渲染的 MDUI3 界面”，以给用户统一的视觉风格。但在“原生 UI 模式”下，必须彻底遵循系统原生规范。

### macOS 平台细节
- **适配策略**：目前先规划和完成 macOS，主要针对 **macOS 26** 进行适配，稍微适配 macOS 15（至少需要可以打开）。
- 必须使用液态玻璃 (Liquid Glass / Vibrancy) 材质、原生侧边栏 (Sidebar) 和原生表格 (Table) 效果。
- SwiftUI 视图通过 MethodChannel/EventChannel 订阅 Dart 端的业务状态与主题配置（如实现深浅色模式跟随）。

### iOS平台细节
- 使用 SwiftUI 实现原生界面。
- 遵循 iOS Human Interface Guidelines。
- 支持 iOS 原生滑动手势。

## 设计资源
- [Material Design 3 官方文档](https://m3.material.io/)
- [Flutter Material 3 指南](https://docs.flutter.dev/ui/design/material)
- [Material 3 Expressive (2025)](https://material.io/blog/material-3-expressive)
