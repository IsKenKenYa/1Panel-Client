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

## File Size & Split Rules (Strict)
- CN: 页面文件 ≤ 300 LOC；组件 ≤ 200 LOC；Provider/ViewModel ≤ 300 LOC；Service/Repository ≤ 400 LOC；Model ≤ 200 LOC。EN: Page ≤ 300 LOC; Widget ≤ 200 LOC; Provider/ViewModel ≤ 300 LOC; Service/Repository ≤ 400 LOC; Model ≤ 200 LOC.
- CN: LOC 统计口径为非空非注释行；生成文件 (`*.g.dart`, `*.freezed.dart`) 不计。EN: LOC counts non-empty non-comment lines; generated files (`*.g.dart`, `*.freezed.dart`) are excluded.
- CN: 超出阈值必须拆分为子组件或子模块，并同步调整文件夹结构。EN: If over limit, split into sub-widgets/modules and update folder structure.

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
