# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 权威规范 / Authoritative Standards

**⚠️ 重要：本文需与 `AGENTS.md` 配合使用**

| 文件 | 内容 | 优先级 |
|------|------|--------|
| [`AGENTS.md`](AGENTS.md) | 硬性规则：架构规范、文件阈值、命名约定、测试门禁 | **最高** |
| `CLAUDE.md` | 流程细则：开发命令、架构概述、项目结构 | 补充 |

CN: 阅读顺序：先 `AGENTS.md` 了解强制规则，再 `CLAUDE.md` 了解项目细节。
EN: Read `AGENTS.md` first for mandatory rules, then `CLAUDE.md` for project details.

## 项目概述 / Project Overview

**1Panel Open** 是一个跨平台 Flutter 移动应用，提供对 1Panel Linux 服务器管理面板的移动访问。

## 1Panel 上游只读与能力基线

- `docs/OpenSource/1Panel/**` 为上游镜像，仅可读取，禁止修改。
- 功能适配必须同时参考：
  - `swagger.json` 契约定义
  - 1Panel Web 前端行为与交互语义
- 目标不是仅“接口可调用”，而是“功能高保真还原 + 客户端价值增强（多机统一管理、MFA 等）”。

### Current Implementation Status
- ✅ **AI Management Module**: Complete (Ollama models, GPU monitoring, domain binding)
- ✅ **Complete API Coverage**: All 34 V2 API modules with 425+ endpoints
- ✅ **Data Models**: 60+ comprehensive model files with JSON serialization
- ✅ **Server Configuration**: Multi-server support with API key authentication
- ✅ **Core Infrastructure**: Logging with IP masking, i18n (EN/ZH), navigation, Material Design 3
- ✅ **Container Management**: Full Docker container and image management
- ✅ **Database Management**: MySQL, PostgreSQL, Redis operations
- ✅ **File Management**: Browse, edit, upload/download, recycle bin, transfer manager
- ✅ **Website Management**: SSL certificates, batch operations, domain management
- 🚧 **Dashboard**: Planned enhancements
- 🚧 **Additional Features**: Continuous improvements

## Development Commands

### Essential Commands
```bash
# Development
flutter pub get              # Install dependencies
flutter run                 # Run app in debug mode
flutter test                # Run all tests
flutter analyze             # Static analysis with linting

# Building
flutter build apk --release # Build Android APK for release
flutter build appbundle     # Build Android App Bundle
flutter build ios --release # Build iOS release (macOS only)

# Code Generation
flutter packages pub run build_runner build  # Generate model serialization files
flutter packages pub run build_runner watch  # Watch for changes and auto-generate
```

### Testing
```bash
flutter test                  # Run all tests
flutter test test/specific_test.dart  # Run specific test file
flutter test --coverage       # Run tests with coverage report
dart run test/scripts/test_runner.dart unit         # Unit tests
dart run test/scripts/test_runner.dart integration  # Integration tests
dart run test/scripts/test_runner.dart ui           # UI/Widget tests
dart run test/scripts/test_runner.dart all          # Full regression
```

## Release Branches & APK CI
- Long-lived branches: `dev`, `main`
- `dev` is the feature aggregation branch
- `main` is the stable release branch
- Current CI/CD scope is Android APK only
- Release is tag-driven, not branch-driven
- Android APK tags:
  - `debug-*` -> internal alpha build from `dev`
  - `beta-*` -> public beta build from `dev`
  - `pre-release-*` -> prerelease build from `dev`
  - `release-*` -> stable release build from `main`

## Architecture Overview

### Core Architecture Pattern
The project follows **Layered Architecture with MVVM** and clean separation of concerns:

```
├── Presentation Layer (UI)
│   ├── Pages (Screens)     # lib/pages/
│   └── Widgets            # lib/shared/widgets/
├── Business Logic Layer (ViewModels/Providers)
│   ├── State Management   # Provider pattern with ChangeNotifier
│   └── Use Cases         # Feature-specific business logic
├── Data Access Layer (Repositories/Services)
│   ├── API Services       # lib/api/v2/ (type-safe with Retrofit)
│   └── Data Models        # lib/data/models/
└── Infrastructure Layer
    ├── Network Client     # Dio-based HTTP client
    ├── Storage           # Secure storage + SharedPreferences
    └── Core Services      # lib/core/services/
```

### Key Technologies
- **Flutter**: 3.16+ with Material Design 3
- **State Management**: Provider pattern (ChangeNotifier)
- **Networking**: Dio + Retrofit for type-safe HTTP clients
- **Storage**: Flutter Secure Storage + SharedPreferences
- **Authentication**: MD5 token generation (`1panel` + API-Key + UnixTimestamp)
- **Internationalization**: Built-in Flutter i18n (English/Chinese)
- **Logging**: Unified logging system with privacy protection (automatic IP masking)

## Cross-Platform UI Governance

### Default UI Baseline
- Non-web target platforms are Android, iOS, iPadOS, macOS, Windows, Linux, and HarmonyOS (target phase)
- Web is out of current adaptation scope
- MDUI3 is a mandatory, always-available baseline across target platforms, not a backup-only mode
- The project allows multiple design systems and multiple theme profiles, but all must be centrally governed
- Shared non-UI layers remain Dart-first: API clients, models, providers, services, repositories, routing contracts, and shared infrastructure must not fork per UI stack

### Native UI Strategy
- **Windows**: Fluent / WinUI3 native track is mandatory
- **iOS / iPadOS / macOS**: SwiftUI native track is mandatory, aligned with Liquid Glass visual direction
- **Android**: Dart-rendered MDUI3 is the default delivery path; native pages require explicit architecture review approval
- **Linux**: current phase delivers with Dart-rendered MDUI3 first; native container capability is a planned community extension path
- **HarmonyOS (target phase)**: reserve resolver/channel/provider placeholders now and plan native milestones while keeping shared business logic in Dart
- Any native UI must not bypass application layering or call API clients directly

### Multi-Theme / Multi-Design-System Direction
- Distinguish:
  - **Design system**: MD3 / Apple-style / Fluent-style
  - **Theme profile**: light, dark, dynamic color, brand seed, future user-selectable styles
- Design-system choice must be centrally governed rather than decided ad hoc per page
- If a new design system is introduced, document target platforms, token mapping, component coverage, and native-exception rationale

### Implementation Guidance
- Follow platform strategy mapping while keeping Dart non-UI layers shared
- Do not duplicate business logic across design systems or UI stacks
- Any native page proposal should define bridge boundary, rollback path, and shared Dart state/service/repository contracts
- The `桌面端适配` branch is a runnable implementation branch for desktop adaptation and may be used as concrete reference material, but it does not redefine the default repository baseline by itself
- Desktop cached modules must stay inside the shared shell host; normal module switches should not push a second shell
- Desktop shell navigation should prefer module switching; only true detail/editor flows should use routed pages
- Cached desktop pages must be gated by `HeroMode`, and FABs in those pages must declare explicit `heroTag`
- Avoid self-referential widget wrapper chains; snapshot wrapped widgets before adding new layers
- Desktop host surfaces should resolve to `surface` / `surfaceContainer*`, not transparent page backgrounds

See `docs/development/cross_platform_ui_governance.md`, `docs/模块适配专属工作流.md`, and `docs/原生UI适配专属工作流.md` for full policy, workflow, and hard-gate details.

### Project Structure Rules (CRITICAL)

#### File Organization Rule
When a functional module has ≥2 files, **MUST** create a dedicated subfolder to avoid mixing different responsibilities in the same folder.

**Example (CORRECT)**:
```
lib/
├── core/
│   ├── auth/
│   │   ├── auth_service.dart
│   │   └── auth_repository.dart
│   └── network/
│       ├── network_service.dart
│       └── network_repository.dart
```

#### File Naming Conventions
- **Pages**: `_page.dart` suffix (e.g., `home_page.dart`)
- **Widgets**: `_widget.dart` suffix (e.g., `user_card_widget.dart`)
- **Services**: `_service.dart` suffix (e.g., `api_service.dart`)
- **Models**: `_model.dart` suffix (e.g., `user_model.dart`)
- **Repositories**: `_repository.dart` suffix (e.g., `user_repository.dart`)
- **All files**: lowercase with underscores (e.g., `server_config_page.dart`)

## Layering & Dependency Rules (Mandatory)
- CN: 依赖方向仅允许 `Presentation -> State -> Service/Repository -> API/Infra`。EN: One-way dependencies only: `Presentation -> State -> Service/Repository -> API/Infra`.
- CN: UI 层禁止直接调用 `lib/api/v2/`。EN: UI must not call `lib/api/v2/` directly.
- CN: 业务逻辑不得写在 Widget `build()` 内。EN: No business logic inside Widget `build()`.

## File Size Thresholds (Strict)
- CN: 所有代码文件（除文档与 Swagger 产物）硬上限为 `1000 LOC`，超过必须拆分后再提交。EN: Hard cap for all code files (excluding docs and Swagger artifacts) is `1000 LOC`; files above this must be split before merge.
- CN: 推荐阈值：普通逻辑文件（Provider/ViewModel/Service/Repository/Model/Utils）建议 ≤ `500 LOC`。EN: Recommended target for general logic files (Provider/ViewModel/Service/Repository/Model/Utils) is `<= 500 LOC`.
- CN: UI 文件允许更大体量（Page/复合 Widget 建议 ≤ `800 LOC`），但同样不得超过 `1000 LOC`。EN: UI files may be larger (Page/composite Widget recommended `<= 800 LOC`), but must still stay within the `1000 LOC` hard cap.
- CN: UI 允许大文件，但“能拆分的组件必须拆分，能复用的组件必须复用”；禁止重复造轮子与复制粘贴组件。EN: UI files can be larger, but splittable parts must be extracted and reusable parts must be reused; avoid duplicate/copied components.
- CN: 单一逻辑/架构文件不得承担 `3` 个及以上功能域（职责上限 `2` 个）。EN: A single logic/architecture file must not own `3+` functional domains (max `2` responsibilities).
- CN: 统计口径为非空非注释行；生成文件 (`*.g.dart`, `*.freezed.dart`) 不计。EN: LOC counts non-empty non-comment lines; generated files are excluded.

## State Management Policy
- CN: 默认 Provider；Bloc 或其他方案需评审通过且在 feature 内隔离使用。EN: Provider by default; Bloc or others require review and must stay isolated within the feature module.

### Current Directory Structure
```
lib/
├── api/v2/              # Type-safe API clients (Retrofit-generated)
├── config/              # App configurations
├── core/                # Core services and utilities
│   ├── config/         # Configuration management
│   ├── i18n/           # Internationalization
│   ├── network/        # Network client setup
│   └── services/       # Core services (logger, etc.)
├── data/               # Data layer
│   ├── models/         # Data models with JSON serialization
│   └── repositories/   # Data repositories
├── features/           # Feature modules (currently AI only)
├── pages/              # UI pages/screens
├── shared/             # Shared components
│   ├── constants/      # App constants
│   └── widgets/        # Reusable widgets
└── main.dart           # App entry point
```

## Critical Development Rules

### Logging System (MANDATORY)
**NEVER** use `print()` or `debugPrint()`. Use the unified logging system:

```dart
import 'core/services/logger/logger_service.dart';

// With explicit package name (RECOMMENDED)
appLogger.dWithPackage('auth.service', '用户登录成功');
appLogger.eWithPackage('network.api', '请求失败', error: e, stackTrace: stackTrace);

// With package prefix in message
appLogger.d('[auth.service] 这是一条调试信息');
```

#### Package Naming Convention
- Use lowercase with dots: `auth.service`, `network.api`, `features.dashboard`
- Correspond to file path: `lib/features/dashboard/` → `[features.dashboard]`
- Default package: `[core.services]` if not specified

#### Log Levels by Build Mode
- **Debug**: All levels (Trace, Debug, Info, Warning, Error, Fatal)
- **Profile**: Info, Warning, Error, Fatal
- **Release**: Warning, Error, Fatal only

#### Privacy Protection
- **Automatic IP Masking**: Public IPs are automatically masked as `***.***.***.***`
- **Private IPs Preserved**: Internal IPs (10.x.x.x, 192.168.x.x, 172.16-31.x.x, 127.x.x.x) remain visible for debugging
- **File Output**: Enabled in all build modes for user feedback
- **Log Configuration**: 
  - No stack traces for normal logs (maxMethodCount: 0)
  - Full stack traces for errors (maxErrorMethodCount: 8)
  - Max file size: 10MB, retention: 30 days, max files: 5

### Code Quality Standards
- **Every commit must**: Compile, pass tests, follow linting rules
- **Analysis**: Run `flutter analyze` before committing
- **Lint rules**: Enabled in `analysis_options.yaml` with `avoid_print: true`
- **Code generation**: Use `build_runner` for JSON serialization and API clients

## Testing Matrix & CLI Gate
- CN: 提交前必须可运行 `flutter analyze`。EN: Must be runnable before commit: `flutter analyze`.
- CN: 必须可运行 `dart run test/scripts/test_runner.dart unit`；涉及 API/网络或数据写入时必须跑 `integration`。EN: Must run `dart run test/scripts/test_runner.dart unit`; for API/network or data writes, must run `integration`.
- CN: UI 改动必须跑 `dart run test/scripts/test_runner.dart ui`。EN: UI changes must run `dart run test/scripts/test_runner.dart ui`.
- CN: 涉及 Windows 原生 UI 改动必须跑 `dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug`。EN: Windows-native UI changes must pass the WinUI3 host build gate.
- CN: 涉及 Apple 原生 UI 改动必须在 macOS/CI 跑 iOS + macOS `xcodebuild` 门禁。EN: Apple-native UI changes must pass iOS and macOS xcodebuild gates in macOS/CI.
- CN: 原生 UI 门禁失败必须阻断推进。EN: Native UI gate failures must block progression.
- CN: 回归基线使用 `dart run test/scripts/test_runner.dart all`。EN: Regression baseline uses `dart run test/scripts/test_runner.dart all`.

## Skills & MCP (agent-memory-mcp)
- CN: 重大架构/约定/踩坑需要 `memory_write` 写入知识库（type: `decision`/`pattern`）。EN: Record key architecture decisions/patterns via `memory_write` (type: `decision`/`pattern`).
- CN: 实施前先 `memory_search` 检索已有决策。EN: Use `memory_search` before implementation.
- CN: 规范变更同步 `AGENTS.md` 与 `CLAUDE.md`。EN: Standards changes must update `AGENTS.md` and `CLAUDE.md`.

### API Integration Pattern
```dart
// Example API client usage
final apiClient = ApiClient();
final response = await apiClient.getApps();
// Use try-catch with proper logging
try {
  final result = await apiClient.someMethod();
  appLogger.iWithPackage('api.client', '操作成功');
} catch (e, stackTrace) {
  appLogger.eWithPackage('api.client', '操作失败', error: e, stackTrace: stackTrace);
  rethrow; // Re-throw for UI handling
}
```

## Authentication System

### Token Generation
API authentication uses MD5 hash: `md5('1panel' + apiKey + unixTimestamp)`

### Multi-Server Support
- Server configurations stored securely
- Support for multiple 1Panel servers
- Default server selection available

## Feature Development Guidelines

### Adding New Features
1. **Create feature folder** under `lib/features/feature_name/`
2. **Follow structure**:
   ```
   features/feature_name/
   ├── data/
   │   ├── models/
   │   └── repositories/
   ├── presentation/
   │   ├── pages/
   │   └── widgets/
   └── domain/
       └── use_cases/
   ```
3. **Add API client** in `lib/api/v2/` if needed
4. **Create state provider** extending ChangeNotifier
5. **Use unified logging** with appropriate package names

### State Management Pattern
```dart
class FeatureProvider extends ChangeNotifier {
  final _repository = FeatureRepository();

  // State variables
  bool _isLoading = false;
  List<FeatureModel> _items = [];

  // Getters
  bool get isLoading => _isLoading;
  List<FeatureModel> get items => _items;

  // Actions
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getItems();
      appLogger.iWithPackage('feature.provider', '数据加载成功');
    } catch (e, stackTrace) {
      appLogger.eWithPackage('feature.provider', '数据加载失败', error: e, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## Testing Guidelines

### Test Structure
```dart
// Unit test example
void main() {
  group('FeatureProvider', () {
    late FeatureProvider provider;
    late MockRepository mockRepository;

    setUp(() {
      mockRepository = MockRepository();
      provider = FeatureProvider(mockRepository);
    });

    test('should load items successfully', () async {
      // Arrange
      final expectedItems = [FeatureModel(id: 1, name: 'Test')];
      when(mockRepository.getItems()).thenAnswer((_) async => expectedItems);

      // Act
      await provider.loadItems();

      // Assert
      expect(provider.items, expectedItems);
      expect(provider.isLoading, false);
    });
  });
}
```

## UI/UX Guidelines

### Material Design 3
- Use Material 3 components and theming
- Follow accessibility guidelines
- Implement responsive design for different screen sizes

### Platform Design Systems
- Flutter MD3 is the default shared delivery path for Android/Linux in the current phase
- Apple-targeted native pages should follow SwiftUI/HIG idioms and Liquid-Glass-aligned system aesthetics
- Windows-targeted native pages should follow WinUI3/Fluent idioms
- Avoid mixing unrelated platform aesthetics inside a single screen without a documented reason

### Desktop Stability Rules
- Desktop shell pages that cache modules with `IndexedStack` must avoid duplicate active Heroes across cached pages
- Use `HeroMode` to disable inactive cached module pages
- Any page with a `FloatingActionButton` that can coexist with other cached pages should use an explicit `heroTag` or intentionally disable hero participation
- Avoid mutable widget re-wrapping patterns that can accidentally create self-referential widget trees

### Internationalization
- All user-facing strings must use `AppLocalizations`
- Support English (en) and Chinese (zh)
- Add new keys to `lib/core/i18n/app_localizations.dart`

## Security Considerations

### Data Storage
- **Sensitive data**: Use `FlutterSecureStorage`
- **Preferences**: Use `SharedPreferences`
- **API keys**: Store securely, never log them

### Network Security
- All API calls use HTTPS
- Custom headers for authentication
- Certificate pinning if needed

## Automated Delivery Loop (Mandatory)

1. Requirement decomposition (scope, dependencies, acceptance criteria)
2. Test case design (unit, integration, UI/interaction, contract deviation)
3. Automated baseline setup (scripts, fixtures, env vars, gates)
4. Feature implementation with layered architecture
5. Unit test execution and fixes
6. Integration test execution and fixes (mandatory for API/network/data write changes)
7. Documentation and baseline updates (module docs, compatibility strategy, analysis artifacts)

Any failed stage must be fixed before proceeding; no failure carry-forward is allowed.

## Common Development Workflows

### Adding New API Endpoint
1. Update API client in `lib/api/v2/`
2. Add data models in `lib/data/models/`
3. Run code generation: `flutter packages pub run build_runner build`
4. Create repository methods
5. Add provider actions
6. Update UI with proper loading/error states

### Debugging Tips
- Use Debug mode for comprehensive logging
- Filter logs by package name: `[feature.provider]`
- Check network logs with Dio interceptors
- Use Flutter Inspector for widget debugging

### Performance Considerations
- Use `const` constructors where possible
- Implement proper image caching with `cached_network_image`
- Use `shimmer` for loading states
- Avoid expensive operations in build methods

## Code Review Checklist
- CN: 分层依赖是否正确，UI 是否直接调用 API。EN: Dependency direction correct; UI not calling API directly.
- CN: 文件是否满足 `500/800` 推荐阈值与 `1000` 硬上限，职责是否超过 2 个功能域。EN: File size meets `500/800` recommended limits and `1000` hard cap; responsibilities do not exceed 2 functional domains.
- CN: 错误处理与日志是否完整且使用 `appLogger`。EN: Error handling and logging complete using `appLogger`.
- CN: 测试是否满足门禁要求（unit/integration/ui）。EN: Test gate satisfied (unit/integration/ui).
- CN: 是否严格遵守 `docs/OpenSource/1Panel/**` 只读策略，并以 Web 行为语义完成功能还原。EN: Confirm upstream readonly policy and web-behavior semantic restoration.
- CN: 新增/变更规范是否同步更新 `AGENTS.md` 与 `CLAUDE.md`。EN: Standards changes synchronized to `AGENTS.md` and `CLAUDE.md`.

## Build and Deployment

### Android
```bash
flutter build apk --release          # Release APK
flutter build appbundle              # App Bundle for Play Store
```

### iOS (macOS only)
```bash
flutter build ios --release          # Release build
```

### Code Signing
- Configure in respective platform folders
- Use environment variables for sensitive keys
- Never commit signing certificates
