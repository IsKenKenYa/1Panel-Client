# 跨平台 UI 分离与原生壳层改造计划（基于当前分支）

## Summary（摘要）
在**不以 main 分支为准**的前提下，完成“共享数据层、分离 UI 层”的跨平台架构重组：保留并复用 `lib/api/`、`lib/data/`、`lib/core/*`（以及既有可复用的状态/控制器/服务），将 UI 逐步迁移到 `lib/ui/mobile/...` 与 `lib/ui/desktop/{common,macos,windows}/...`。路由保持“语义一致”（沿用 `AppRoutes`），但通过 **平台 + formFactor** 的映射层选择不同平台页面/壳层。macOS/iOS 走“**原生玻璃壳层 + Flutter 内容区**”的混合方案；Windows 走 Fluent/WinUI 风格（优先窗口材质/标题栏等原生能力 + Flutter 内容区）；Linux/Web 复用合适的 Flutter UI（默认 desktop/common）。

## Current State Analysis（现状分析，基于代码库）
### 1) 入口与路由
- 入口 `lib/main.dart`：使用 `MaterialApp(onGenerateRoute: AppRouter.generateRoute, initialRoute: AppRoutes.splash)`，并通过 `DynamicColorBuilder`、`ThemeController`/`AppSettingsController` 管理主题与国际化。
- 路由 `lib/config/app_router.dart`：
  - `AppRoutes` 已提供“语义路由常量”，但 `generateRoute` 直接 new 具体页面，导致 UI 与路由强耦合、导入极多、文件体量偏大（后续容易触发 1000 LOC 上限）。
  - 当前分支中已存在桌面相关壳层/原生桥接的代码，但尚未形成“平台映射层”的统一入口（需要完成）。

### 2) 现有壳层与桌面适配基础
- `lib/features/shell/app_shell_page.dart`：以模块（`ClientModule`）为中心，宽度断点支持 mobile/rail/sidebar，并包含 server gating、pinned modules 等逻辑；移动端体验已较完善（MDUI3）。
- `lib/features/shell/platform/platform_adaptive_shell_page.dart`：已有按平台与断点分流的壳层雏形（macOS/windows/iPad/AndroidPad/web 等 scaffold），但未纳入“语义路由 -> 平台页面”体系。
- macOS 原生侧：`macos/Runner/MainFlutterWindow.swift` 已有窗口外观相关调整；Flutter 侧已有 `MacosAppearanceChannel` + `MacosAppearanceContextModel` 可读取系统外观参数（透明度/模糊等）。

### 3) 主题与动态色现状
- 主题：`lib/core/theme/app_theme.dart` + `ThemeController` 已支持 seedColor、dynamic color 开关（Android Material You），并通过 `DynamicColorBuilder` 注入。
- 约束：UI 代码禁止硬编码文案，必须走 `context.l10n.xxx`；新增文案需同步更新 ARB 并执行 `flutter gen-l10n`。

### 4) 架构规范约束（必须遵守）
- 分层依赖方向：`Presentation -> State -> Service/Repository -> API/Infra`；UI 不得直接调用 `lib/api/v2/`，必须经由 Repository/Service。
- 状态管理默认 Provider。
- 禁止重复造轮子：优先复用现有 controllers/services/widgets（尤其 `features/shell` 相关模块控制器、server gating、pinned modules 等）。

## Assumptions & Decisions（已确认的关键决策）
1) **以当前分支为准**：main 分支落后，不作为基线；桌面适配代码来自 main checkout 的“配置修复”历史，但后续工作以当前分支的结构与实现为主。
2) **原生 UI 路线**：采用“混合方案（推荐）”——macOS/iOS 使用原生玻璃/标题栏/工具栏等“壳层与关键控件”，业务内容区用 Flutter；Windows 采用 Fluent/WinUI 风格（优先原生窗口材质与标题栏，再逐步扩展原生壳层）。
3) **目录骨架**：新增 `lib/ui/mobile` 与 `lib/ui/desktop/{common,macos,windows}` 分层（推荐方案），逐步迁移/封装 UI，不一次性大搬家。
4) **路由策略**：共享 `AppRoutes` 语义常量，但页面实现通过“平台映射层”分流（推荐方案）。
5) **平台覆盖**：除鸿蒙暂不考虑；Flutter 支持的 iOS/iPadOS/Android/Android Tablet/macOS/Windows/Linux/Web 均需适配，其中 Linux/Web 先复用 common 策略。

## Proposed Changes（改造方案：文件级变更清单）
> 说明：以下为“可执行的实现骨架”，每一步都尽量做到可编译、可回滚、低风险渐进迁移；不引入不必要的新状态管理方案；不复制现有业务逻辑。

### A. 新增 UI 分流骨架（核心：把“平台判定”搬到 build() 内）
**目标**：解决 `onGenerateRoute` 无法使用 `MediaQuery` 的问题，让路由生成不做平台/尺寸判断，改为返回一个 Host Widget 由其在 `build()` 内分流。

新增目录与文件（2+ 文件即建子目录，遵守结构规则）：
- `lib/ui/routing/ui_target.dart`
  - 定义：`UiPlatformKind`（mobile/desktopMacos/desktopWindows/desktopLinux/web）、`UiFormFactor`（phone/tablet/desktop）与 `UiTarget`。
- `lib/ui/routing/ui_target_resolver.dart`
  - `UiTargetResolver.resolve(BuildContext context)`：基于 `kIsWeb`、`defaultTargetPlatform`、`MediaQuery.sizeOf(context)` 与既有断点策略输出 `UiTarget`。
  - 断点策略复用当前工程经验（如 shortestSide>=600 判 tablet；width>=960/1024 判大屏），并为 iPadOS vs Android Pad 预留更细粒度策略入口（见后文 D）。
- `lib/ui/routing/route_registry.dart`
  - 建立语义路由注册表：`String routeName -> RouteEntry`。
  - `RouteEntry` 支持 default builder + platform override builders（按 `UiPlatformKind` 覆盖）。
  - 初期只对少数关键路由做平台覆盖（`home` 等），其余默认返回现有页面（从 `lib/features/*`、`lib/pages/*` 等）。
- `lib/ui/routing/ui_route_host.dart`
  - 接收 `RouteSettings`，在 `build()` 内解析 `UiTarget` 并从 `RouteRegistry` 解析出对应页面。
  - 负责统一转场策略（默认 `MaterialPageRoute`；iOS 可按需要引入 `CupertinoPageRoute` 但要保证一致性与可测试性）。

修改文件：
- `lib/config/app_router.dart`
  - 将 `generateRoute` 变薄：保留 `AppRoutes` 常量与少量“纯语义/redirect”逻辑，其余统一返回 `UiRouteHost(settings: settings)`。
  - **约束**：不要在这里直接引入大量平台 UI import；平台页面映射移动到 `lib/ui/routing/*`。
  - 大文件拆分策略：若 `app_router.dart` 逼近/超过 1000 LOC，上述改造完成后进一步把 “route constants / legacy redirects / helpers” 分拆成多个文件（例如 `app_routes.dart`、`legacy_redirects.dart`、`route_args_parsers.dart`），避免超限。

### B. 新增 UI 目录骨架（移动端与桌面端分离入口）
**目标**：移动端保持现有 MDUI3 与交互；桌面端引入全新壳层体系，互不牵制，只共享 VM/Repository/Service。

新增目录：
- `lib/ui/mobile/app/`
  - `mobile_shell_page.dart`：初期可**包装复用** `features/shell/app_shell_page.dart`（减少回归风险），后续再逐步将壳层逻辑拆成“可复用控制器 + 多平台 scaffold”。
- `lib/ui/desktop/common/app/`
  - `desktop_shell_page.dart`：Flutter 桌面通用壳层（侧栏 + 内容区 + 顶部工具区占位）。
  - 初期可复用 `ClientModule` 与 `features/shell/controllers/*` 的模块选择、server gating、pinned modules（避免重复实现）。
- `lib/ui/desktop/macos/app/`
  - `macos_shell_content_page.dart`：Flutter 侧仅渲染“内容区”（让原生负责玻璃壳层）。
  - `macos_shell_bridge.dart`：MethodChannel 封装（复用已有 `MacosAppearanceChannel` 思路/日志方式）。
- `lib/ui/desktop/windows/app/`
  - `windows_shell_content_page.dart`：Flutter 侧内容区。
  - `windows_shell_bridge.dart`：MethodChannel 封装（用于 toolbar/command bar 同步、窗口材质状态同步等）。

路由映射（新增文件）：
- `lib/ui/mobile/routes/mobile_route_builders.dart`
- `lib/ui/desktop/common/routes/desktop_route_builders.dart`
- `lib/ui/desktop/macos/routes/macos_route_builders.dart`
- `lib/ui/desktop/windows/routes/windows_route_builders.dart`
这些 builders 负责把“语义路由”映射到实际页面；初期大多数 builder 直接返回现有 features 页面，只有壳层与少数核心页面做平台差异化实现。

### C. Home/导航分流：语义一致、壳层不同
**目标**：`AppRoutes.home` 在不同平台进入不同壳层；移动端与桌面端导航彻底解耦。

实现方式：
- 在 `RouteRegistry` 中对 `AppRoutes.home` 配置 platform override：
  - `UiPlatformKind.mobile` -> `MobileShellPage`
  - `desktopMacos` -> `MacosShellContentPage`（原生壳层 + Flutter 内容）
  - `desktopWindows` -> `WindowsShellContentPage`（原生窗口材质/壳层 + Flutter 内容）
  - `desktopLinux`/`web` -> `DesktopShellPage`（Flutter 桌面 common 壳层）
- `AppShellPage` 保持作为移动端主壳层的实现来源（短期复用，长期可拆分）。

### D. iPadOS vs Android Pad：交互与信息密度策略更细化
**目标**：不只是外观断点，iPadOS 与 Android Pad 在交互与布局密度上分轨（符合平台习惯）。

新增策略层：
- 在 `UiTarget` 中增加 `platformFamily` 或 `tabletKind`（例如：`TabletKind.ipad`, `TabletKind.androidPad`, `TabletKind.webTablet`），由 `UiTargetResolver` 判定。
- 新增 `lib/ui/mobile/app/tablet/`：
  - `ipad_shell_page.dart`：更接近 iPadOS 的分栏/手势/信息密度（可适度 Cupertino 化，但仍需遵守“不硬编码文案”与整体架构规范）。
  - `android_pad_shell_page.dart`：保持 MDUI3，但引入更明确的大屏三栏与响应式布局策略（见 E）。
> 注：实现上可先在移动端壳层内部做 `tabletKind` 分支，不必第一步就迁移大量页面。

### E. Android Material You 动态色 + 大屏三栏布局
**目标**：Android 继续使用现有完善的 MDUI3，并增强大屏三栏布局（navigation + list + detail），动态色仅在 Android 生效。

改造点（在现有基础上增强，避免重复）：
- 主题：继续使用 `DynamicColorBuilder` + `ThemeController.useDynamicColor`；确保 `AppTheme` 的 dynamic color gating 只对 Android 生效（现状已有 `_supportsMaterialYouPlatform` 思路）。
- UI：在 Android Pad/LargeScreen Shell 中引入三栏布局骨架（例如 `NavigationRail + ListPane + DetailPane`），并为 modules（server/files/apps/...）提供统一的“list-detail host”容器（只做容器，不复制业务逻辑）。
- 交互：保留触控优先；桌面专属能力（右键/快捷键/拖拽）不要强行引入 Android。

### F. 桌面端系统风格：macOS（玻璃）与 Windows（Fluent）细化组件风格
**目标**：不仅导航壳不同，控件风格、间距、hover/focus/pressed、命令栏等也分轨；两端共享 ViewModel/Repository，不共享具体 Widget 树。

macOS 轨道（原生 + Flutter 内容）：
- 原生（macOS）：
  - 扩展 `macos/Runner/MainFlutterWindow.swift`：使用 `NSVisualEffectView` 构建玻璃背景/侧栏容器，并嵌入 FlutterView 作为内容区。
  - Channel 协议：原生壳层触发模块切换/搜索/toolbar action -> Flutter；Flutter route 变化/标题变化 -> 原生。
- Flutter（macOS 内容区）：
  - `MacosShellBridge`：统一 channel 封装、错误兜底、日志（使用 `appLogger.*WithPackage`）。
  - `MacosShellContentPage`：根据来自原生的状态渲染内容区（模块内容可初期复用现有页面）。

Windows 轨道（Fluent/WinUI）：
- 原生（Windows runner）：
  - 设置窗口材质（Mica/Acrylic）、标题栏暗色等 DWM 属性（逐步增强，不一次性做全壳层）。
  - 若后续需要原生 command bar/sidebar，再引入 channel 同步策略，方式与 macOS 类似。
- Flutter（Windows 内容区）：
  - `WindowsShellContentPage`：内容区布局按 Fluent 信息层次与间距系统调整（Flutter 端实现“风格化组件”时，应与移动端组件隔离，避免互相污染）。

Linux/Web：
- 默认复用 `desktop/common`；后续如需要 GNOME/KDE 特化，再新增 `lib/ui/desktop/linux`，但不作为第一阶段目标。

### G. 国际化与文案规范（必须）
**目标**：所有新增 UI 文案使用 `context.l10n.xxx`；新增 key 同步到 `app_zh.arb` 与 `app_en.arb`，并运行 `flutter gen-l10n`。

执行要点：
- 新增壳层、toolbar、sidebar 分组、快捷键提示等文本，均走 l10n。
- 不在 UI 层硬编码字符串（包括按钮 label、tooltip、空态文案）。

### H. 测试与验证（CLI Gate）
**目标**：保证分流逻辑与路由映射可测试，避免回归。

新增/调整测试：
- `test/ui/routing/ui_target_resolver_test.dart`
  - 覆盖：web/ios/ipad/android/androidPad/macos/windows/linux 目标判定（通过注入/可测的 resolver 设计，或对 resolver 提供可替换的 platform/size 输入）。
- `test/ui/routing/route_registry_test.dart`
  - 覆盖：`AppRoutes.home` 在不同 `UiTarget` 下解析到不同 builder；未知 route -> NotFound。
- 若 UI 改动较大：补充 `dart run test_runner.dart ui`（或至少对关键壳层做 widget test）。

本机验证命令（按项目要求）：
- `flutter analyze`
- `dart run test_runner.dart unit`
- UI 相关：`dart run test_runner.dart ui`（或说明原因）

## Step-by-step Implementation（执行步骤，决策完备）
1) **建立 `lib/ui/routing` 基础设施**：`UiTarget`、`UiTargetResolver`、`RouteRegistry`、`UiRouteHost`。
2) **让 `AppRouter.generateRoute` 变薄**：除极少数 legacy redirect 外，统一返回 `UiRouteHost`；把页面选择移出 `lib/config/app_router.dart`。
3) **接入 `AppRoutes.home` 分流**：新增 `MobileShellPage`（初期包装 `AppShellPage`），新增 `DesktopShellPage`（最小可用壳），macOS/windows 内容区页面占位。
4) **平板分轨策略落地**：在移动端壳层中引入 iPadOS vs Android Pad 的 `tabletKind` 分支，形成“信息密度/交互”策略层（先做骨架与容器，不迁移全部页面）。
5) **Android 大屏三栏容器**：新增 list-detail host 容器与导航布局（MDUI3），逐步让核心模块（Server/Files/Settings）在大屏下进入三栏体验。
6) **macOS 原生玻璃壳层第一阶段**：原生实现玻璃背景/侧栏容器 + 嵌入 Flutter 内容区；Flutter 侧建立 channel 协议最小闭环（模块切换/标题同步/外观参数同步）。
7) **Windows Fluent 第一阶段**：原生 runner 设置窗口材质与标题栏属性；Flutter 侧 desktop/windows 内容区使用 Fluent 风格 spacing/hover/focus 状态体系（不复用移动端 widget）。
8) **逐步迁移核心页面实现**：按优先级从 `Server / Files / Settings` 开始，移动端继续复用现有页面，桌面端逐步用 desktop 目录下的独立实现替换默认 builder。
9) **国际化与测试补齐**：补齐 ARB + gen-l10n；补齐 routing/resolver 测试；跑 analyze 与 test_runner gate。

## Verification Checklist（验收清单）
- [ ] `AppRoutes.home` 在 mobile / macOS / Windows / Linux / Web 下进入对应壳层（不崩溃、可导航）。
- [ ] 语义路由常量仍统一使用 `AppRoutes.*`，但页面实现能按平台独立。
- [ ] Android：动态色仅在 Android 生效；Android Pad/大屏三栏布局可用且不影响手机。
- [ ] iPadOS：与 Android Pad 有明确不同的交互与信息密度策略（至少壳层与布局策略不同）。
- [ ] macOS：原生玻璃壳层生效，Flutter 内容区可随模块/路由变化；channel 异常有兜底且日志规范。
- [ ] Windows：窗口材质/标题栏策略生效（或有降级），Flutter 内容区风格与移动端隔离。
- [ ] 不新增 UI 硬编码字符串；新增文案已更新 `app_zh.arb`/`app_en.arb` 并 `flutter gen-l10n`。
- [ ] `flutter analyze` 通过；`dart run test_runner.dart unit` 通过；UI 改动已跑 `ui` 或说明原因。

