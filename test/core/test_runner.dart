import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_config_manager.dart';

class TestRunner {
  static final TestRunner _instance = TestRunner._internal();
  static TestRunner get instance => _instance;

  final List<TestSuiteResult> _results = [];
  DateTime? _startTime;
  DateTime? _endTime;

  TestRunner._internal();

  void startSuite(String suiteName) {
    debugPrint('\n========================================');
    debugPrint('开始测试套件: $suiteName');
    debugPrint('========================================\n');
  }

  void endSuite(String suiteName,
      {required int passed, required int failed, required int skipped}) {
    final result = TestSuiteResult(
      suiteName: suiteName,
      passed: passed,
      failed: failed,
      skipped: skipped,
      timestamp: DateTime.now(),
    );
    _results.add(result);

    debugPrint('\n----------------------------------------');
    debugPrint('测试套件完成: $suiteName');
    debugPrint('通过: $passed, 失败: $failed, 跳过: $skipped');
    debugPrint('----------------------------------------\n');
  }

  void startAllTests() {
    _startTime = DateTime.now();
    _results.clear();
    debugPrint('\n╔════════════════════════════════════════╗');
    debugPrint('║     1Panel V2 API 测试开始            ║');
    debugPrint('╚════════════════════════════════════════╝\n');
    debugPrint('测试环境配置:');
    debugPrint('  服务器: ${TestEnvironment.baseUrl}');
    debugPrint('  API版本: ${TestEnvironment.apiVersion}');
    debugPrint('  集成测试: ${TestEnvironment.runIntegrationTests ? '启用' : '禁用'}');
    debugPrint('  破坏性测试: ${TestEnvironment.runDestructiveTests ? '启用' : '禁用'}');
    debugPrint('');
  }

  void endAllTests() {
    _endTime = DateTime.now();
    _generateReport();
  }

  void _generateReport() {
    final totalPassed = _results.fold(0, (sum, r) => sum + r.passed);
    final totalFailed = _results.fold(0, (sum, r) => sum + r.failed);
    final totalSkipped = _results.fold(0, (sum, r) => sum + r.skipped);
    final totalTests = totalPassed + totalFailed + totalSkipped;

    debugPrint('\n╔════════════════════════════════════════╗');
    debugPrint('║     1Panel V2 API 测试报告            ║');
    debugPrint('╚════════════════════════════════════════╝\n');

    debugPrint('测试概要:');
    debugPrint('  开始时间: ${_startTime?.toIso8601String() ?? 'N/A'}');
    debugPrint('  结束时间: ${_endTime?.toIso8601String() ?? 'N/A'}');
    final duration = _startTime != null && _endTime != null
        ? _endTime!.difference(_startTime!)
        : Duration.zero;
    debugPrint('  持续时间: ${duration.inSeconds}秒');
    debugPrint('');
    debugPrint('测试统计:');
    debugPrint('  总测试数: $totalTests');
    debugPrint('  ✅ 通过: $totalPassed');
    debugPrint('  ❌ 失败: $totalFailed');
    debugPrint('  ⏭️  跳过: $totalSkipped');
    debugPrint(
        '  通过率: ${totalTests > 0 ? (totalPassed / totalTests * 100).toStringAsFixed(2) : 0}%');
    debugPrint('');

    debugPrint('各模块测试结果:');
    for (final result in _results) {
      final status =
          result.failed > 0 ? '❌' : (result.skipped > 0 ? '⚠️' : '✅');
      debugPrint(
          '  $status ${result.suiteName}: ${result.passed}/${result.passed + result.failed + result.skipped}');
    }
    debugPrint('');

    _saveReport(totalTests, totalPassed, totalFailed, totalSkipped, duration);
  }

  Future<void> _saveReport(
      int total, int passed, int failed, int skipped, Duration duration) async {
    if (!TestEnvironment.saveTestLogs) return;

    try {
      final reportDir = Directory(TestEnvironment.testReportPath);
      if (!reportDir.existsSync()) {
        reportDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final reportFile = File('${reportDir.path}/test_report_$timestamp.md');

      final buffer = StringBuffer();
      buffer.writeln('# 1Panel V2 API 测试报告');
      buffer.writeln();
      buffer.writeln('## 测试概要');
      buffer.writeln();
      buffer.writeln('| 指标 | 值 |');
      buffer.writeln('|------|------|');
      buffer.writeln('| 开始时间 | ${_startTime?.toIso8601String() ?? 'N/A'} |');
      buffer.writeln('| 结束时间 | ${_endTime?.toIso8601String() ?? 'N/A'} |');
      buffer.writeln('| 持续时间 | ${duration.inSeconds}秒 |');
      buffer.writeln('| 总测试数 | $total |');
      buffer.writeln('| 通过数 | $passed |');
      buffer.writeln('| 失败数 | $failed |');
      buffer.writeln('| 跳过数 | $skipped |');
      buffer.writeln(
          '| 通过率 | ${total > 0 ? (passed / total * 100).toStringAsFixed(2) : 0}% |');
      buffer.writeln();
      buffer.writeln('## 测试环境');
      buffer.writeln();
      buffer.writeln('| 配置项 | 值 |');
      buffer.writeln('|--------|------|');
      buffer.writeln('| 服务器URL | ${TestEnvironment.baseUrl} |');
      buffer.writeln('| API版本 | ${TestEnvironment.apiVersion} |');
      buffer.writeln(
          '| 集成测试 | ${TestEnvironment.runIntegrationTests ? '启用' : '禁用'} |');
      buffer.writeln(
          '| 破坏性测试 | ${TestEnvironment.runDestructiveTests ? '启用' : '禁用'} |');
      buffer.writeln();
      buffer.writeln('## 各模块测试结果');
      buffer.writeln();
      buffer.writeln('| 模块 | 通过 | 失败 | 跳过 | 状态 |');
      buffer.writeln('|------|------|------|------|------|');

      for (final result in _results) {
        final status = result.failed > 0
            ? '❌ 失败'
            : (result.skipped > 0 ? '⚠️ 部分跳过' : '✅ 通过');
        buffer.writeln(
            '| ${result.suiteName} | ${result.passed} | ${result.failed} | ${result.skipped} | $status |');
      }

      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln('*报告生成时间: ${DateTime.now().toIso8601String()}*');

      await reportFile.writeAsString(buffer.toString());
      debugPrint('测试报告已保存到: ${reportFile.path}');
    } catch (e) {
      debugPrint('保存测试报告失败: $e');
    }
  }

  List<TestSuiteResult> get results => List.unmodifiable(_results);
}

class TestSuiteResult {
  final String suiteName;
  final int passed;
  final int failed;
  final int skipped;
  final DateTime timestamp;

  TestSuiteResult({
    required this.suiteName,
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.timestamp,
  });

  int get total => passed + failed + skipped;
  double get passRate => total > 0 ? (passed / total) * 100 : 0;
}

class TestLogger {
  static void info(String message) {
    debugPrint('[INFO] $message');
  }

  static void success(String message) {
    debugPrint('[SUCCESS] ✅ $message');
  }

  static void error(String message) {
    debugPrint('[ERROR] ❌ $message');
  }

  static void warning(String message) {
    debugPrint('[WARNING] ⚠️ $message');
  }

  static void skip(String message) {
    debugPrint('[SKIP] ⏭️ $message');
  }

  static void testStart(String testName) {
    debugPrint('  ▶ $testName');
  }

  static void testPass(String testName) {
    debugPrint('    ✅ 通过: $testName');
  }

  static void testFail(String testName, String error) {
    debugPrint('    ❌ 失败: $testName');
    debugPrint('       错误: $error');
  }

  static void testSkip(String testName, String reason) {
    debugPrint('    ⏭️ 跳过: $testName ($reason)');
  }
}

class ApiTestRegistry {
  static final ApiTestRegistry _instance = ApiTestRegistry._internal();
  static ApiTestRegistry get instance => _instance;

  final Map<String, ApiTestDefinition> _tests = {};

  ApiTestRegistry._internal();

  void register(ApiTestDefinition test) {
    _tests[test.id] = test;
  }

  ApiTestDefinition? get(String id) => _tests[id];

  List<ApiTestDefinition> getAll() => _tests.values.toList();

  List<ApiTestDefinition> getByModule(String module) {
    return _tests.values.where((t) => t.module == module).toList();
  }

  List<ApiTestDefinition> getByTag(String tag) {
    return _tests.values.where((t) => t.tags.contains(tag)).toList();
  }

  int get totalTests => _tests.length;
}

class ApiTestDefinition {
  final String id;
  final String name;
  final String module;
  final String description;
  final String method;
  final String path;
  final List<String> tags;
  final bool requiresAuth;
  final bool isDestructive;
  final bool isIntegration;

  const ApiTestDefinition({
    required this.id,
    required this.name,
    required this.module,
    required this.description,
    required this.method,
    required this.path,
    this.tags = const [],
    this.requiresAuth = true,
    this.isDestructive = false,
    this.isIntegration = false,
  });
}
