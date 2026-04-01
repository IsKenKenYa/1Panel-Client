# macOS 原生 UI 原汁原味体验增强计划 (True Native Experience Plan)

## 1. 概述 (Summary)
在之前的重构中，我们已经移除了仿 MDUI3 的组件，并用 SwiftUI 重写了 macOS 端。但用户的目标更进一步：**我们需要的是使用原生代码实现原生系统的原生UI和原汁原味的交互逻辑**，而不仅仅是换成 SwiftUI 语法。特别是需要针对 macOS 15 以及未来的 macOS 26 的**液态玻璃（Liquid Glass / Vibrancy）设计、原生交互逻辑、结构布局**进行深度适配。
同时，保留通过切换设置来展示 Dart MDUI3 界面的能力，并且确保底层数据逻辑全部复用 Dart 层。

## 2. 当前状态与差距分析 (Current State Analysis)
- **壳层架构 (MainShellView)**：当前使用了旧的 `NavigationView`，而 macOS 原生推荐使用 `NavigationSplitView` 来构建结构化、拥有标准交互（折叠侧边栏）和正确层级的应用窗口。
- **列表与表格 (Views)**：虽然目前使用了 `Table` 和 `List`，但缺乏 macOS 典型的工具栏（Toolbar）、搜索框（Search）、详情区（Detail Pane）等经典左右或三段式结构交互。很多列表直接堆砌在大标题下，没有遵循 macOS Human Interface Guidelines。
- **视觉特效 (Liquid Glass)**：虽然加了 `VisualEffectView`，但应用层级不够深入，部分视图仍然被不透明的底色遮挡，或者缺乏典型的 macOS 毛玻璃透底效果。

## 3. 拟定更改 (Proposed Changes)

### 3.1 采用 `NavigationSplitView` 替换 `NavigationView`
- 修改 `MainShellView`，使用支持 macOS 13+ 且能在未来系统（如 macOS 26）上表现最佳的 `NavigationSplitView`。
- 在侧边栏和详情区合理运用 `.navigationTitle` 和 `.toolbar` 修饰符，以便生成原汁原味的 macOS 标题栏。

### 3.2 深度适配“液态玻璃”与系统材质
- 移除手动硬编码的 `.background(Color)`。
- 确保所有的主要容器视图背景都使用适当的 `NSVisualEffectView.Material`：
  - 侧边栏使用 `.sidebar`。
  - 内容区背景使用 `.contentBackground` 配合 `.underWindowBackground`。
  - 卡片/面板区使用 `.headerView` 或 `.popover` 等半透明材质。
- 让窗口标题栏与内容区自然融合（`window.titlebarAppearsTransparent = true` 已经存在，需配合 SwiftUI 的 `edgesIgnoringSafeArea(.top)` 等属性实现沉浸式窗口）。

### 3.3 原汁原味的 macOS 交互组件 (Toolbar & Actions)
- 为 `ServersView`, `FilesView`, `AppsView` 等模块引入典型的 macOS 原生结构。
- 将顶部大字标题（`Text("Servers").font(.largeTitle)`）替换为标准的系统导航标题（`.navigationTitle`）。
- 将操作按钮放入原生的 `.toolbar` 区域。
- `Table` 控件默认会铺满屏幕，这非常符合 macOS 原生文件管理器（Finder）或活动监视器（Activity Monitor）的交互逻辑。我们将去除多余的外边距（padding）。

## 4. 实施步骤与涉及文件

1. **`MainShellView.swift` & `SidebarView.swift`**
   - 替换为 `NavigationSplitView(sidebar:detail:)`。
   - 配置侧边栏的选择逻辑以控制 Detail 视图。
2. **各业务模块视图 (`ServersView.swift`, `FilesView.swift`, etc.)**
   - 移除自定义的 `Text(xxx).font(.largeTitle)` 标题，改为 `.navigationTitle(xxx)`。
   - 让 `Table` 组件填满可用空间。
   - 移除不必要的 `VStack` 和多余的 `padding`，使用户体验更像 macOS 原生应用。
   - `MonitoringView` 中的卡片使用系统的 `.groupBoxStyle` 或带有原生毛玻璃的面板，排版更加紧凑。
3. **兼容性**
   - 在所有的改动中，确保代码能编译在目标 `macOS 11.0` 及其上版本。由于 `NavigationSplitView` 需要 macOS 13.0+，我们需要做版本兼容：对 macOS 13+ 使用 `NavigationSplitView`，对 macOS 11/12 回退到改进的 `NavigationView`。

## 5. 验证标准 (Verification)
- 编译并运行 macOS 目标。
- 侧边栏与系统设置应用类似，支持折叠与拉伸，具有强烈的毛玻璃特效（Liquid Glass）。
- 点击左侧项目后，右侧详情区的标题栏自然呈现选中的模块名称。
- 各个列表（Table）铺满内容区域，交互上完全等同于 Finder 的列表模式。