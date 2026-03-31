# 测试指南

1Panel 开源应用测试完整指南。

---

## 目录

1. [概述](#概述)
2. [测试环境设置](#测试环境设置)
3. [运行测试](#运行测试)
4. [测试结构](#测试结构)
5. [编写测试](#编写测试)
6. [集成测试](#集成测试)
7. [测试覆盖率](#测试覆盖率)
8. [持续集成](#持续集成)
9. [故障排除](#故障排除)

---

## 概述

本项目使用 Flutter 内置测试框架，包含以下测试类型：

- **单元测试**：测试单个函数、类和模型
- **组件测试**：单独测试 UI 组件
- **集成测试**：测试完整的用户流程和 API 交互

### 测试统计

- **总测试用例**：124
- **通过率**：100%
- **覆盖区域**：
  - Token 认证（21 个测试）
  - Toolbox API（27 个测试）
  - Command API（17 个测试）
  - MCP Server API（28 个测试）
  - 通用模型（31 个测试）

---

## 测试环境设置

### 前置条件

1. **Flutter SDK**（3.0 或更高版本）
2. **Dart SDK**（随 Flutter 一起提供）
3. **1Panel 测试服务器**（可选，用于集成测试）

### 环境配置

1. 复制示例环境文件：

```bash
cp .env.example .env
```

2. 编辑 `.env` 配置您的测试环境：

```env
# 测试 API 配置
TEST_API_KEY=your_test_api_key_here
TEST_BASE_URL=http://your-test-server:8080

# 测试设置
ENABLE_MOCK_TESTS=true
ENABLE_LIVE_TESTS=false
TIMEOUT_SECONDS=30
```

**重要**：切勿将 `.env` 文件提交到版本控制。它已添加到 `.gitignore`。

### 测试数据

测试套件包含：
- **Mock 数据**：用于单元测试的预定义测试数据
- **测试生成器**：用于边缘情况的动态数据生成
- **Fixtures**：存储在 `test/fixtures/` 中的示例 API 响应

---

## 运行测试

### 运行所有测试

```bash
flutter test
```

### 运行特定测试文件

```bash
flutter test test/auth/token_auth_test.dart
```

### 运行测试并生成覆盖率报告

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 运行集成测试

```bash
flutter test integration_test/api_integration_test.dart
```

### 运行带标签的测试

```bash
flutter test --tags "auth"
```

---

## 测试结构

```
test/
├── auth/
│   └── token_auth_test.dart          # Token 认证测试
├── api/
│   ├── toolbox_api_test.dart         # Toolbox API 模型测试
│   ├── command_api_test.dart         # Command API 测试
│   ├── mcp_api_test.dart             # MCP Server API 测试
│   └── common_models_test.dart       # 通用模型测试
├── widgets/                          # 组件测试（未来）
├── integration/
│   └── api_integration_test.dart     # 集成测试
├── fixtures/                         # 测试数据文件
├── test_helper.dart                  # 测试工具
└── TEST_REPORT.md                    # 详细测试报告
```

---

## 编写测试

### 单元测试示例

```dart
import 'package:flutter_test/flutter_test.dart';
import '../test_helper.dart';

void main() {
  group('TokenGenerator', () {
    test('应该生成有效的 MD5 token', () {
      // 准备
      final apiKey = 'test_api_key';
      final timestamp = 1704067200;
      
      // 执行
      final token = TokenGenerator.generateToken(
        apiKey: apiKey,
        timestamp: timestamp,
      );
      
      // 验证
      expect(token, isNotNull);
      expect(token.length, equals(32)); // MD5 哈希长度
    });
  });
}
```

### 组件测试示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ServerCard 显示服务器信息', (WidgetTester tester) async {
    // 构建组件
    await tester.pumpWidget(
      MaterialApp(
        home: ServerCard(
          name: '测试服务器',
          url: 'http://test.example.com',
        ),
      ),
    );
    
    // 验证
    expect(find.text('测试服务器'), findsOneWidget);
    expect(find.text('http://test.example.com'), findsOneWidget);
  });
}
```

### 集成测试示例

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('端到端测试', () {
    testWidgets('添加服务器并查看仪表板', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      
      // 添加服务器
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // 填写表单
      await tester.enterText(
        find.byKey(Key('server_name')),
        '测试服务器',
      );
      
      // 提交
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      
      // 验证仪表板
      expect(find.text('仪表板'), findsOneWidget);
    });
  });
}
```

---

## 集成测试

### API 集成测试

集成测试验证完整的 API 流程：

1. **认证流程**：Token 生成和验证
2. **API 端点**：对测试服务器的真实 API 调用
3. **错误处理**：网络错误、超时、认证失败
4. **数据解析**：响应解析和模型验证

### 运行集成测试

**使用 Mock 服务器**：
```bash
flutter test test/integration/api_integration_test.dart
```

**使用真实服务器**（需要 `.env` 配置）：
```bash
ENABLE_LIVE_TESTS=true flutter test test/integration/api_integration_test.dart
```

### 测试服务器设置

对于真实集成测试，您需要：

1. 运行中的 1Panel 实例
2. 配置的测试 API 密钥
3. 包含您测试机器 IP 的白名单
4. 测试数据（容器、网站、数据库）

---

## 测试覆盖率

### 当前覆盖区域

| 模块 | 测试数 | 覆盖率 |
|------|--------|--------|
| Token 认证 | 21 | 100% |
| Toolbox API | 27 | 100% |
| Command API | 17 | 100% |
| MCP Server API | 28 | 100% |
| 通用模型 | 31 | 100% |

### 覆盖率报告

生成 HTML 覆盖率报告：

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 覆盖率目标

- **最低**：80% 行覆盖率
- **目标**：90% 行覆盖率
- **关键路径**：100% 覆盖率（认证、API 客户端）

---

## 持续集成

### GitHub Actions

项目包含 GitHub Actions 工作流：

1. **PR 测试**：在 PR 上运行所有测试
2. **覆盖率报告**：上传覆盖率到 Codecov
3. **集成测试**：使用 mock 服务器运行

### 工作流配置

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

### 预提交钩子

安装预提交钩子以在提交前运行测试：

```bash
dart pub global activate git_hooks
git_hooks install
```

---

## 故障排除

### 常见问题

**测试失败并显示"Unable to load asset"**：
```bash
flutter pub get
flutter clean
flutter test
```

**Golden 文件测试失败**：
```bash
flutter test --update-goldens
```

**集成测试超时**：
- 增加 `test_helper.dart` 中的超时时间
- 检查网络连接
- 验证测试服务器是否运行

**覆盖率未生成**：
```bash
flutter test --coverage --test-randomize-ordering-seed random
```

### 调试模式

使用详细输出运行测试：

```bash
flutter test -v
```

运行特定测试并调试：

```bash
flutter test --start-paused test/auth/token_auth_test.dart
```

---

## 最佳实践

### 编写好的测试

1. **AAA 模式**：Arrange（准备）、Act（执行）、Assert（验证）
2. **单一概念**：一次只测试一件事
3. **描述性名称**：测试名称应该解释场景
4. **独立测试**：测试之间不应该相互依赖
5. **快速测试**：保持单元测试在 100ms 以内

### 测试数据管理

- 使用 `setUp()` 和 `tearDown()` 管理测试夹具
- 测试后清理资源
- 使用工厂创建复杂对象
- 避免硬编码值，使用常量

### Mocking

使用 `mockito` 或 `mocktail` 进行 mocking：

```dart
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  
  setUp(() {
    mockClient = MockApiClient();
  });
  
  test('应该获取数据', () async {
    when(() => mockClient.get(any()))
        .thenAnswer((_) async => Response(data: {'key': 'value'}));
    
    final result = await repository.fetchData();
    
    expect(result.key, equals('value'));
  });
}
```

---

## 资源

- [Flutter 测试文档](https://docs.flutter.dev/testing)
- [Dart Test 包](https://pub.dev/packages/test)
- [Dart Mockito](https://pub.dev/packages/mockito)
- [集成测试](https://docs.flutter.dev/testing/integration-tests)

---

*最后更新：2026-03-30*
