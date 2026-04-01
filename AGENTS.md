# Repository Guidelines

## Project Structure & Module Organization
- Source code lives in `lib/`, with major areas under `lib/api/v2/` (Retrofit clients), `lib/core/` (infrastructure/services), `lib/data/` (models and repositories), `lib/features/` (feature modules), `lib/pages/` (screens), and `lib/shared/` (shared widgets/constants).
- Platform targets are in `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and `web/`.
- Tests are in `test/` (unit, widget, integration, and API tests). Coverage output goes to `coverage/`.
- Structure rule: when a functional module reaches 2+ files, create a dedicated subfolder (e.g., `lib/core/auth/`).

## Architecture & Layering (Mandatory)
- CN: 跨平台 UI 策略：Android 与 Android 平板使用 Dart 渲染 MDUI3；其余平台（macOS, iOS, Windows, Linux）默认使用各自平台的原生代码实现真·原生设计语言（如 macOS 液态玻璃），但允许设置切换回 Dart 渲染的 MDUI3。
- CN: 核心架构必须完全由 Dart 实现，并划分为六大核心层（State, Service, Repository, Model, API/Infra, Core/Config）。禁止在原生代码中重写这部分非 UI 逻辑。
- CN: 分层依赖方向仅允许 `Presentation -> State -> Service/Repository -> API/Infra`。EN: One-way dependencies only: `Presentation -> State -> Service/Repository -> API/Infra`.
- CN: UI 层不得直接调用 `lib/api/v2/`，必须经由 Repository/Service。EN: UI must not call `lib/api/v2/` directly; go through Repository/Service.
- CN: 业务逻辑不得写在 Widget `build()` 或原生 UI 控制器内，必须下沉到 Provider/ViewModel 或 Service。EN: No business logic inside `build()` or native UI controllers; move it to Provider/ViewModel or Service.
- CN: 状态管理默认 Provider，其他方案需评审通过。EN: Provider is the default; other patterns require review.

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
- CN: 必须可运行 `dart run test_runner.dart unit`；涉及 API/网络或数据写入时必须跑 `integration`。EN: Must run `dart run test_runner.dart unit`; if touching API/network or data writes, must run `integration`.
- CN: UI 改动必须跑 `dart run test_runner.dart ui` 或说明原因。EN: UI changes must run `dart run test_runner.dart ui` or document why not.
- CN: 回归基线使用 `dart run test_runner.dart all`。EN: Regression baseline uses `dart run test_runner.dart all`.

## Skills & MCP Usage
- CN: 重大架构/约定/踩坑需写入 `agent-memory-mcp`（type: `decision`/`pattern`）。EN: Record key architecture decisions/patterns in `agent-memory-mcp` (type: `decision`/`pattern`).
- CN: 实施前先用 `memory_search` 检索既有决策。EN: Run `memory_search` before implementation to reuse prior decisions.
- CN: 规范变更必须同步更新 `AGENTS.md` 与 `CLAUDE.md`。EN: Any standards change must update `AGENTS.md` and `CLAUDE.md`.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits: `feat(scope): ...`, `fix(scope): ...`, `chore: ...`, `refactor: ...`. Scopes may use module names in English or Chinese.
- Keep PRs small and incremental. For large changes, open an issue first and align on scope.
- PRs should include: summary of changes, test results, and screenshots for UI changes.
- Never include secrets or sensitive data in issues, logs, or screenshots.

## Security & Configuration Notes
- API access uses 1Panel API keys; do not commit keys or tokens.
- When sharing logs or repro steps, redact IPs, usernames, and credentials.
