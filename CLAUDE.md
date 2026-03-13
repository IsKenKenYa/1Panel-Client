# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**1Panel Open** is a cross-platform Flutter mobile application that provides mobile access to the 1Panel Linux server management panel. The app serves as a mobile interface for managing server applications, containers, websites, files, and AI features through a modern, responsive UI.

## Authoritative Standards

CN: 权威规范以 `AGENTS.md`（硬性规则）与 `CLAUDE.md`（流程与细则）为准。EN: Authoritative standards live in `AGENTS.md` (hard rules) and `CLAUDE.md` (process/details).

### Current Implementation Status
- ✅ **AI Management Module**: Complete (Ollama models, GPU monitoring, domain binding)
- ✅ **Server Configuration**: Multi-server support with API key authentication
- ✅ **Core Infrastructure**: Logging, i18n (EN/ZH), navigation, Material Design 3
- 🚧 **Dashboard**: Planned
- 🚧 **Application/Container/File Management**: UI stubs ready

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
dart run test_runner.dart unit         # Unit tests
dart run test_runner.dart integration  # Integration tests
dart run test_runner.dart ui           # UI/Widget tests
dart run test_runner.dart all          # Full regression
```

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
- CN: 页面文件 ≤ 300 LOC；组件 ≤ 200 LOC；Provider/ViewModel ≤ 300 LOC；Service/Repository ≤ 400 LOC；Model ≤ 200 LOC。EN: Page ≤ 300 LOC; Widget ≤ 200 LOC; Provider/ViewModel ≤ 300 LOC; Service/Repository ≤ 400 LOC; Model ≤ 200 LOC.
- CN: 统计口径为非空非注释行；生成文件 (`*.g.dart`, `*.freezed.dart`) 不计。EN: LOC counts non-empty non-comment lines; generated files are excluded.
- CN: 超出阈值必须拆分为子组件或子模块并调整目录。EN: If over limit, split into sub-widgets/modules and adjust directories.

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
import 'core/services/logger_service.dart';

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

### Code Quality Standards
- **Every commit must**: Compile, pass tests, follow linting rules
- **Analysis**: Run `flutter analyze` before committing
- **Lint rules**: Enabled in `analysis_options.yaml` with `avoid_print: true`
- **Code generation**: Use `build_runner` for JSON serialization and API clients

## Testing Matrix & CLI Gate
- CN: 提交前必须可运行 `flutter analyze`。EN: Must be runnable before commit: `flutter analyze`.
- CN: 必须可运行 `dart run test_runner.dart unit`；涉及 API/网络或数据写入时必须跑 `integration`。EN: Must run `dart run test_runner.dart unit`; for API/network or data writes, must run `integration`.
- CN: UI 改动必须跑 `dart run test_runner.dart ui` 或说明原因。EN: UI changes must run `dart run test_runner.dart ui` or document why not.
- CN: 回归基线使用 `dart run test_runner.dart all`。EN: Regression baseline uses `dart run test_runner.dart all`.

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
- CN: 文件是否超出 LOC 阈值，是否需要拆分。EN: File size within LOC thresholds or split appropriately.
- CN: 错误处理与日志是否完整且使用 `appLogger`。EN: Error handling and logging complete using `appLogger`.
- CN: 测试是否满足门禁要求（unit/integration/ui）。EN: Test gate satisfied (unit/integration/ui).
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
