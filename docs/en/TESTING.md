# Testing Guide

Complete guide for testing the 1Panel Open Source App.

---

## Table of Contents

1. [Overview](#overview)
2. [Test Environment Setup](#test-environment-setup)
3. [Running Tests](#running-tests)
4. [Test Structure](#test-structure)
5. [Writing Tests](#writing-tests)
6. [Integration Testing](#integration-testing)
7. [Test Coverage](#test-coverage)
8. [Continuous Integration](#continuous-integration)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This project uses Flutter's built-in testing framework with the following test types:

- **Unit Tests**: Test individual functions, classes, and models
- **Widget Tests**: Test UI components in isolation
- **Integration Tests**: Test complete user flows and API interactions

### Test Statistics

- **Total Test Cases**: 124
- **Pass Rate**: 100%
- **Coverage Areas**:
  - Token Authentication (21 tests)
  - Toolbox API (27 tests)
  - Command API (17 tests)
  - MCP Server API (28 tests)
  - Common Models (31 tests)

---

## Test Environment Setup

### Prerequisites

1. **Flutter SDK** (3.0 or higher)
2. **Dart SDK** (included with Flutter)
3. **1Panel Test Server** (optional, for integration tests)

### Environment Configuration

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Edit `.env` with your test configuration:

```env
# Test API Configuration
TEST_API_KEY=your_test_api_key_here
TEST_BASE_URL=http://your-test-server:8080

# Test Settings
ENABLE_MOCK_TESTS=true
ENABLE_LIVE_TESTS=false
TIMEOUT_SECONDS=30
```

**Important**: Never commit the `.env` file to version control. It's already added to `.gitignore`.

### Test Data

The test suite includes:
- **Mock Data**: Predefined test data for unit tests
- **Test Generators**: Dynamic data generation for edge cases
- **Fixtures**: Sample API responses stored in `test/fixtures/`

---

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/auth/token_auth_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Run Integration Tests

```bash
flutter test integration_test/api_integration_test.dart
```

### Run Tests with Specific Tag

```bash
flutter test --tags "auth"
```

---

## Test Structure

```
test/
├── auth/
│   └── token_auth_test.dart          # Token authentication tests
├── api/
│   ├── toolbox_api_test.dart         # Toolbox API model tests
│   ├── command_api_test.dart         # Command API tests
│   ├── mcp_api_test.dart             # MCP Server API tests
│   └── common_models_test.dart       # Common model tests
├── widgets/                          # Widget tests (future)
├── integration/
│   └── api_integration_test.dart     # Integration tests
├── fixtures/                         # Test data files
├── test_helper.dart                  # Test utilities
└── TEST_REPORT.md                    # Detailed test report
```

---

## Writing Tests

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import '../test_helper.dart';

void main() {
  group('TokenGenerator', () {
    test('should generate valid MD5 token', () {
      // Arrange
      final apiKey = 'test_api_key';
      final timestamp = 1704067200;
      
      // Act
      final token = TokenGenerator.generateToken(
        apiKey: apiKey,
        timestamp: timestamp,
      );
      
      // Assert
      expect(token, isNotNull);
      expect(token.length, equals(32)); // MD5 hash length
    });
  });
}
```

### Widget Test Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ServerCard displays server info', (WidgetTester tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: ServerCard(
          name: 'Test Server',
          url: 'http://test.example.com',
        ),
      ),
    );
    
    // Verify
    expect(find.text('Test Server'), findsOneWidget);
    expect(find.text('http://test.example.com'), findsOneWidget);
  });
}
```

### Integration Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('End-to-End Tests', () {
    testWidgets('Add server and view dashboard', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();
      
      // Add server
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Fill form
      await tester.enterText(
        find.byKey(Key('server_name')),
        'Test Server',
      );
      
      // Submit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // Verify dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

---

## Integration Testing

### API Integration Tests

Integration tests verify the complete API flow:

1. **Authentication Flow**: Token generation and validation
2. **API Endpoints**: Real API calls to test server
3. **Error Handling**: Network errors, timeouts, auth failures
4. **Data Parsing**: Response parsing and model validation

### Running Integration Tests

**With Mock Server**:
```bash
flutter test test/integration/api_integration_test.dart
```

**With Live Server** (requires `.env` configuration):
```bash
ENABLE_LIVE_TESTS=true flutter test test/integration/api_integration_test.dart
```

### Test Server Setup

For live integration tests, you need:

1. A running 1Panel instance
2. Test API key configured
3. IP whitelist including your test machine
4. Test data (containers, websites, databases)

---

## Test Coverage

### Current Coverage Areas

| Module | Tests | Coverage |
|--------|-------|----------|
| Token Authentication | 21 | 100% |
| Toolbox API | 27 | 100% |
| Command API | 17 | 100% |
| MCP Server API | 28 | 100% |
| Common Models | 31 | 100% |

### Coverage Report

Generate HTML coverage report:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Goals

- **Minimum**: 80% line coverage
- **Target**: 90% line coverage
- **Critical Paths**: 100% coverage (auth, API clients)

---

## Continuous Integration

### GitHub Actions

The project includes GitHub Actions workflows for:

1. **Pull Request Tests**: Run all tests on PR
2. **Coverage Reporting**: Upload coverage to Codecov
3. **Integration Tests**: Run with mock server

### Workflow Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

### Pre-commit Hooks

Install pre-commit hooks to run tests before commits:

```bash
dart pub global activate git_hooks
git_hooks install
```

---

## Troubleshooting

### Common Issues

**Tests failing with "Unable to load asset"**:
```bash
flutter pub get
flutter clean
flutter test
```

**Golden file tests failing**:
```bash
flutter test --update-goldens
```

**Integration tests timing out**:
- Increase timeout in `test_helper.dart`
- Check network connectivity
- Verify test server is running

**Coverage not generating**:
```bash
flutter test --coverage --test-randomize-ordering-seed random
```

### Debug Mode

Run tests with verbose output:

```bash
flutter test -v
```

Run specific test with debugging:

```bash
flutter test --start-paused test/auth/token_auth_test.dart
```

---

## Best Practices

### Writing Good Tests

1. **AAA Pattern**: Arrange, Act, Assert
2. **One Concept per Test**: Test one thing at a time
3. **Descriptive Names**: Test names should explain the scenario
4. **Independent Tests**: Tests should not depend on each other
5. **Fast Tests**: Keep unit tests under 100ms

### Test Data Management

- Use `setUp()` and `tearDown()` for test fixtures
- Clean up resources after tests
- Use factories for complex object creation
- Avoid hardcoded values, use constants

### Mocking

Use `mockito` or `mocktail` for mocking:

```dart
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  
  setUp(() {
    mockClient = MockApiClient();
  });
  
  test('should fetch data', () async {
    when(() => mockClient.get(any()))
        .thenAnswer((_) async => Response(data: {'key': 'value'}));
    
    final result = await repository.fetchData();
    
    expect(result.key, equals('value'));
  });
}
```

---

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Dart Test Package](https://pub.dev/packages/test)
- [Mockito for Dart](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

---

*Last updated: 2026-03-30*
