import 'package:flutter_test/flutter_test.dart';
import 'core/test_config_manager.dart';
import 'core/test_runner.dart';

// 导入所有测试文件
import 'auth/token_auth_test.dart' as token_auth;
import 'api/ai_api_test.dart' as ai_api;
import 'api/toolbox_api_test.dart' as toolbox_api;
import 'api/container_api_test.dart' as container_api;
import 'integration/api_integration_test.dart' as integration;
import 'integration/ai_api_integration_test.dart' as ai_integration;

void main() {
  final runner = TestRunner.instance;

  setUpAll(() async {
    await TestEnvironment.initialize();
    runner.startAllTests();
  });

  tearDownAll(() {
    runner.endAllTests();
  });

  group('Token认证测试', () {
    setUp(() => runner.startSuite('Token认证'));
    tearDown(
        () => runner.endSuite('Token认证', passed: 0, failed: 0, skipped: 0));
    token_auth.main();
  });

  group('AI API单元测试', () {
    setUp(() => runner.startSuite('AI API'));
    tearDown(() => runner.endSuite('AI API', passed: 0, failed: 0, skipped: 0));
    ai_api.main();
  });

  group('Toolbox API单元测试', () {
    setUp(() => runner.startSuite('Toolbox API'));
    tearDown(
        () => runner.endSuite('Toolbox API', passed: 0, failed: 0, skipped: 0));
    toolbox_api.main();
  });

  group('Container API单元测试', () {
    setUp(() => runner.startSuite('Container API'));
    tearDown(() =>
        runner.endSuite('Container API', passed: 0, failed: 0, skipped: 0));
    container_api.main();
  });

  group('API集成测试', () {
    setUp(() => runner.startSuite('API集成'));
    tearDown(() => runner.endSuite('API集成', passed: 0, failed: 0, skipped: 0));
    integration.main();
  });

  group('AI API集成测试', () {
    setUp(() => runner.startSuite('AI API集成'));
    tearDown(
        () => runner.endSuite('AI API集成', passed: 0, failed: 0, skipped: 0));
    ai_integration.main();
  });
}
