# Repository Guidelines

## Project Structure & Module Organization
- Source code lives in `lib/`, with major areas under `lib/api/v2/` (Retrofit clients), `lib/core/` (infrastructure/services), `lib/data/` (models and repositories), `lib/features/` (feature modules), `lib/pages/` (screens), and `lib/shared/` (shared widgets/constants).
- Platform targets are in `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and `web/`.
- Tests are in `test/` (unit, widget, integration, and API tests). Coverage output goes to `coverage/`.
- Structure rule: when a functional module reaches 2+ files, create a dedicated subfolder (e.g., `lib/core/auth/`).

## Architecture & Layering (Mandatory)
- CN: 分层依赖方向仅允许 `Presentation -> State -> Service/Repository -> API/Infra`。EN: One-way dependencies only: `Presentation -> State -> Service/Repository -> API/Infra`.
- CN: UI 层不得直接调用 `lib/api/v2/`，必须经由 Repository/Service。EN: UI must not call `lib/api/v2/` directly; go through Repository/Service.
- CN: 业务逻辑不得写在 Widget `build()` 内，必须下沉到 Provider/ViewModel 或 Service。EN: No business logic inside `build()`; move it to Provider/ViewModel or Service.
- CN: 状态管理默认 Provider，其他方案需评审通过。EN: Provider is the default; other patterns require review.

## UI Governance (Mandatory)
- CN: 默认 UI 基线为 Flutter/Dart 实现的 Material Design 3。EN: The default UI baseline is Flutter/Dart with Material Design 3.
- CN: 共享的非 UI 层（API/Model/Provider/Service/Repository/Infra）默认且优先使用 Dart/Flutter 体系实现。EN: Shared non-UI layers (API/Model/Provider/Service/Repository/Infra) must default to and prioritize Dart/Flutter implementations.
- CN: 多平台共享页面优先使用 Flutter 实现；只有在平台体验、系统能力或性能收益明确时，才允许原生 UI 例外。EN: Shared multi-platform screens should default to Flutter; native UI exceptions are allowed only when platform UX, system capability, or performance gains are clear.
- CN: Apple 平台允许 SwiftUI 风格原生页面，Windows 平台允许 WinUI3/Fluent 风格原生页面。EN: Apple platforms may use SwiftUI-native pages, and Windows may use WinUI3/Fluent-native pages.
- CN: Android 默认不需要为 MD3 重写原生 UI；Kotlin/Compose 仅作为例外能力。EN: Android must not be rewritten natively just to replicate MD3; Kotlin/Compose is exception-only.
- CN: 多设计系统/多主题必须走统一注册与主题控制，不允许页面自行发明独立 UI 体系。EN: Multi-design-system and multi-theme support must go through centralized registration and theme control; pages may not invent standalone UI systems.
- CN: 原生代码主要用于 UI 容器、平台交互与系统能力接入，不得承载共享业务核心逻辑。EN: Native code is primarily for UI containers, platform interaction, and system capabilities, and must not own shared business logic.
- CN: 原生 UI 仍必须遵守 `Presentation -> State -> Service/Repository -> API/Infra`，不得直接跨层访问 API。EN: Native UI must still obey `Presentation -> State -> Service/Repository -> API/Infra` and may not call APIs directly across layers.

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
