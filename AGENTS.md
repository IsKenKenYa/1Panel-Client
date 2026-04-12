# Repository Guidelines

## Project Structure & Module Organization
- Source code lives in `lib/`, with major areas under `lib/api/v2/` (Retrofit clients), `lib/core/` (infrastructure/services), `lib/data/` (models and repositories), `lib/features/` (feature modules), `lib/pages/` (screens), and `lib/shared/` (shared widgets/constants).
- Platform targets are in `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and `web/`.
- Tests are in `test/` (unit, widget, integration, and API tests). Coverage output goes to `coverage/`.
- Structure rule: when a functional module reaches 2+ files, create a dedicated subfolder (e.g., `lib/core/auth/`).

## Architecture & Layering (Mandatory)
- CN: 跨平台 UI 策略（非 Web）：所有目标平台（Android, iOS, macOS, Windows, Linux）默认使用各平台原生 UI；可按设置切换到 Dart 渲染的 MDUI3。Web 不在当前适配目标。
- EN: Non-web UI strategy: Android, iOS, macOS, Windows, and Linux default to platform-native UI, with an optional runtime switch to Dart-rendered MDUI3. Web is out of current adaptation scope.
- CN: 鸿蒙（HarmonyOS）及其他未来平台本阶段仅允许在 Dart 侧预留 `UiTarget` / Channel / Provider 占位，不得在原生层承载共享业务核心逻辑。
- EN: For HarmonyOS and future platforms, this phase only allows Dart-side placeholders (`UiTarget`, channel, provider); shared business core logic must remain outside native layers.
- CN: 核心架构必须完全由 Dart 实现，并划分为六大核心层（State, Service, Repository, Model, API/Infra, Core/Config）。禁止在原生代码中重写这部分非 UI 逻辑。
  - **State Layer**: 默认 Provider，负责连接 UI 与业务逻辑，位于 `lib/features/*/providers/`。
  - **Service Layer**: 处理核心业务规则、数据加工，位于 `lib/core/services/` 或各业务模块 `*_service.dart`。
  - **Repository Layer**: 数据单一事实来源，位于 `lib/data/repositories/`，屏蔽数据来源细节。
  - **Model Layer**: 定义实体、请求/响应结构，位于 `lib/data/models/`，配合生成工具使用。
  - **API/Infra Layer**: 处理外部通信、本地持久化与平台交互，位于 `lib/api/v2/`、`lib/core/network/`、`lib/core/storage/`、`lib/core/channel/`。
  - **Core/Config Layer**: 基础配置、路由、主题系统、国际化，位于 `lib/core/` 及其子目录（如 `app_router.dart`、`lib/core/i18n/` 等）。
- CN: 分层依赖方向仅允许 `Presentation -> State -> Service/Repository -> API/Infra`。EN: One-way dependencies only: `Presentation -> State -> Service/Repository -> API/Infra`.
- CN: UI 层不得直接调用 `lib/api/v2/`，必须经由 Repository/Service。EN: UI must not call `lib/api/v2/` directly; go through Repository/Service.
- CN: 业务逻辑不得写在 Widget `build()` 或原生 UI 控制器内，必须下沉到 Provider/ViewModel 或 Service。EN: No business logic inside `build()` or native UI controllers; move it to Provider/ViewModel or Service.
- CN: 状态管理默认 Provider，其他方案需评审通过。EN: Provider is the default; other patterns require review.

## UI Governance (Mandatory)
- CN: 默认 UI 基线（非 Web）为平台原生 UI；MDUI3 作为统一回退渲染层并可由用户切换。EN: The default non-web UI baseline is platform-native UI; MDUI3 is the shared fallback render layer and user-switchable.
- CN: 共享的非 UI 层（API/Model/Provider/Service/Repository/Infra）默认且优先使用 Dart/Flutter 体系实现。EN: Shared non-UI layers (API/Model/Provider/Service/Repository/Infra) must default to and prioritize Dart/Flutter implementations.
- CN: 各平台应优先实现原生 UI 壳层并复用共享 Dart 内容逻辑；当原生壳能力未就绪时，必须显式回退到 MDUI3，并记录回退原因。EN: Each platform should prioritize native UI shells while reusing shared Dart content logic; if native shell capability is not ready, an explicit MDUI3 fallback with a recorded reason is required.
- CN: Apple 平台可使用 SwiftUI 原生页面，Windows 可使用 WinUI3/Fluent，Linux 可使用 GTK/Fluent 风格原生容器。EN: Apple may use SwiftUI-native pages, Windows may use WinUI3/Fluent, and Linux may use GTK/Fluent-style native containers.
- CN: Android 默认采用原生 UI（含 Kotlin/Compose）并保持 MDUI3 可切换回退；禁止出现“原生与 MDUI3 两套业务逻辑”。EN: Android defaults to native UI (including Kotlin/Compose) with switchable MDUI3 fallback; duplicate business logic across native and MDUI3 is forbidden.
- CN: 鸿蒙属于未来平台：本阶段只做路由/通道/Provider 占位，不承诺原生界面交付。EN: HarmonyOS is a future platform: this phase only reserves routing/channel/provider placeholders and does not commit native UI delivery.
- CN: 多设计系统/多主题必须走统一注册与主题控制，不允许页面自行发明独立 UI 体系。EN: Multi-design-system and multi-theme support must go through centralized registration and theme control; pages may not invent standalone UI systems.
- CN: 原生代码主要用于 UI 容器、平台交互与系统能力接入，不得承载共享业务核心逻辑。EN: Native code is primarily for UI containers, platform interaction, and system capabilities, and must not own shared business logic.
- CN: 原生 UI 仍必须遵守 `Presentation -> State -> Service/Repository -> API/Infra`，不得直接跨层访问 API。EN: Native UI must still obey `Presentation -> State -> Service/Repository -> API/Infra` and may not call APIs directly across layers.
- CN: 桌面缓存模块页必须禁用非当前页 Hero；独立详情页或带浮动按钮的页面必须显式设置 `heroTag` 或显式禁用 Hero。EN: Desktop-cached module pages must disable Hero on non-active pages; standalone detail pages or FAB-bearing pages must set an explicit `heroTag` or explicitly disable Hero.
- CN: 禁止用可变 widget 变量形成自引用包装链（例如 `content = GestureDetector(child: content)` 后再在 builder 中引用当前 `content`）。EN: Do not build self-referential widget wrapper chains with mutable widget variables (for example, reassigning `content` and then referencing the current `content` inside a builder).
- CN: 桌面缓存模块页必须由统一壳承载，普通模块切换不得再 `push` 一个完整壳或首页。EN: Desktop cached modules must stay inside the shared shell host; normal module switches must not `push` a second full shell or home page.
- CN: 桌面 `Scaffold` / `AppBar` / `NavigationRail` / 壳内容区默认必须使用 `surface` 或 `surfaceContainer*`，禁止整页透明背景。EN: Desktop `Scaffold` / `AppBar` / `NavigationRail` / shell content areas must default to `surface` or `surfaceContainer*`; full-page transparent backgrounds are forbidden.

## File Size & Split Rules (Strict)
- CN: 所有代码文件（除文档与 Swagger 产物）硬上限为 `1000 LOC`，超过必须拆分后再提交。EN: Hard cap for all code files (excluding docs and Swagger artifacts) is `1000 LOC`; files above this must be split before merge.
- CN: 推荐阈值：普通逻辑文件（Provider/ViewModel/Service/Repository/Model/Utils）建议 ≤ `500 LOC`。EN: Recommended target for general logic files (Provider/ViewModel/Service/Repository/Model/Utils) is `<= 500 LOC`.
- CN: UI 文件允许更大体量（Page/复合 Widget 建议 ≤ `800 LOC`），但同样不得超过 `1000 LOC`。EN: UI files may be larger (Page/composite Widget recommended `<= 800 LOC`), but must still stay within the `1000 LOC` hard cap.
- CN: UI 允许大文件，但“能拆分的组件必须拆分，能复用的组件必须复用”；禁止重复造轮子与复制粘贴组件。EN: UI files can be larger, but splittable parts must be extracted and reusable parts must be reused; avoid duplicate/copied components.
- CN: 单一逻辑/架构文件不得承担 `3` 个及以上功能域（职责上限 `2` 个）。EN: A single logic/architecture file must not own `3+` functional domains (max `2` responsibilities).
- CN: LOC 统计口径为非空非注释行；生成文件 (`*.g.dart`, `*.freezed.dart`) 不计。EN: LOC counts non-empty non-comment lines; generated files (`*.g.dart`, `*.freezed.dart`) are excluded.

## Build, Test, and Development Commands
- `flutter pub get` — install dependencies.
- `flutter run` — run the app in debug mode on a connected device/simulator.
- `flutter analyze` — static analysis using `analysis_options.yaml`.
- `flutter test` — run the full test suite.
- `flutter test test/<file>_test.dart` — run a specific test.
- `flutter test --coverage` — generate coverage in `coverage/`.
- `flutter packages pub run build_runner build` — generate code (models/Retrofit).
- `flutter build apk --release` / `flutter build appbundle` / `flutter build ios --release` — release builds.

## Coding Style & Naming Conventions
- Dart style with 2-space indentation and `flutter_lints` enabled.
- File names are lowercase snake_case.
- Suffix conventions: `_page.dart`, `_widget.dart`, `_service.dart`, `_model.dart`, `_repository.dart`.
- Logging: do not use `print()` or `debugPrint()`. Use `appLogger` from `lib/core/services/logger_service.dart`, preferably `appLogger.*WithPackage('module.name', ...)` with package names aligned to file paths.

## Testing Guidelines
- Tests use Flutter’s `test` framework; file names end with `_test.dart`.
- Group tests by feature under `test/` (e.g., `test/features/`, `test/api/`, `test/widget_test/`).
- Add regression tests for bug fixes and include any new test data in the relevant `test/` subfolder.

## Test Gate (CLI Runnable)
- CN: 提交前必须可运行 `flutter analyze`。EN: Must be runnable before commit: `flutter analyze`.
- CN: 必须可运行 `dart run test/scripts/test_runner.dart unit`；涉及 API/网络或数据写入时必须跑 `integration`。EN: Must run `dart run test/scripts/test_runner.dart unit`; if touching API/network or data writes, must run `integration`.
- CN: UI 改动必须跑 `dart run test/scripts/test_runner.dart ui` 或说明原因。EN: UI changes must run `dart run test/scripts/test_runner.dart ui` or document why not.
- CN: 回归基线使用 `dart run test/scripts/test_runner.dart all`。EN: Regression baseline uses `dart run test/scripts/test_runner.dart all`.

## Skills & MCP Usage
- CN: 重大架构/约定/踩坑需写入 `agent-memory-mcp`（type: `decision`/`pattern`）。EN: Record key architecture decisions/patterns in `agent-memory-mcp` (type: `decision`/`pattern`).
- CN: 实施前先用 `memory_search` 检索既有决策。EN: Run `memory_search` before implementation to reuse prior decisions.
- CN: 规范变更必须同步更新 `AGENTS.md` 与 `CLAUDE.md`。EN: Any standards change must update `AGENTS.md` and `CLAUDE.md`.
- CN: 跨平台 UI / 原生扩展规则变更时，必须同步更新 `docs/development/cross_platform_ui_governance.md`。EN: Changes to cross-platform UI or native-extension rules must also update `docs/development/cross_platform_ui_governance.md`.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits: `feat(scope): ...`, `fix(scope): ...`, `chore: ...`, `refactor: ...`. Scopes may use module names in English or Chinese.
- Keep PRs small and incremental. For large changes, open an issue first and align on scope.
- PRs should include: summary of changes, test results, and screenshots for UI changes.
- Never include secrets or sensitive data in issues, logs, or screenshots.

## Release Branches & CI
- CN: 长期维护分支使用 `dev` 与 `main`；`dev` 聚合 feature 分支，`main` 为正式发布基线。EN: Long-lived branches are `dev` and `main`; `dev` aggregates feature work and `main` is the stable release baseline.
- CN: Android APK 当前使用 tag 驱动发布：`debug-*`、`beta-*`、`pre-release-*`、`release-*`。EN: Android APK releases are tag-driven with `debug-*`, `beta-*`, `pre-release-*`, and `release-*`.
- CN: tag 来源约束为 `debug/beta/pre-release` 必须来自 `dev`，`release` 必须来自 `main`。EN: `debug`, `beta`, and `pre-release` tags must come from `dev`; `release` tags must come from `main`.
- CN: 渠道映射为 `debug -> Alpha`、`beta -> Beta（公开预览）`、`pre-release -> Pre-Release`、`release -> Release`。EN: Channel mapping is `debug -> Alpha`, `beta -> Beta (public preview)`, `pre-release -> Pre-Release`, `release -> Release`.

## Security & Configuration Notes
- API access uses 1Panel API keys; do not commit keys or tokens.
- When sharing logs or repro steps, redact IPs, usernames, and credentials.
