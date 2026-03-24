import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'core/test_config_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

/// API客户端测试基类
///
/// 提供测试API客户端的通用功能
abstract class ApiClientTestBase {
  late DioClient client;
  late String baseUrl;
  late String apiKey;

  /// 初始化测试环境
  Future<void> setUpApiClient() async {
    await TestEnvironment.initialize();
    baseUrl = TestEnvironment.baseUrl;
    apiKey = TestEnvironment.apiKey;

    client = DioClient(
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }

  /// 清理资源
  void tearDownApiClient() {
    // DioClient不需要显式关闭
  }

  /// 验证响应成功
  void expectSuccessResponse(dynamic response, {int? expectedCode}) {
    expect(response, isNotNull);
    if (response is Response) {
      expect(response.statusCode, equals(200));
      if (response.data is Map) {
        final data = response.data as Map;
        expect(data['code'], equals(expectedCode ?? 200));
      }
    } else if (response is Map) {
      expect(response['code'], equals(expectedCode ?? 200));
    }
  }

  /// 验证分页响应
  void expectPageResponse(dynamic response) {
    expect(response, isNotNull);
    if (response is Response) {
      expect(response.statusCode, equals(200));
      if (response.data is Map) {
        final data = response.data as Map;
        expect(data['items'], isA<List>());
        expect(data['total'], isA<int>());
      }
    }
  }

  /// 验证数据模型
  void expectValidModel<T>(T? model, {required String modelName}) {
    expect(model, isNotNull, reason: '$modelName should not be null');
    expect(model, isA<T>(), reason: 'Model should be of type $modelName');
  }

  /// 打印测试信息
  void logTestInfo(String testName, {Map<String, dynamic>? params}) {
    debugPrint('\n========================================');
    debugPrint('测试: $testName');
    if (params != null && params.isNotEmpty) {
      debugPrint('参数: ${jsonEncode(params)}');
    }
    debugPrint('========================================');
  }

  /// 打印响应信息
  void logResponseInfo(Response? response) {
    if (response == null) {
      debugPrint('响应: null');
      return;
    }
    debugPrint('状态码: ${response.statusCode}');
    if (response.data != null) {
      final dataStr = response.data.toString();
      if (dataStr.length > 500) {
        debugPrint('响应数据: ${dataStr.substring(0, 500)}...');
      } else {
        debugPrint('响应数据: ${jsonEncode(response.data)}');
      }
    }
    debugPrint('========================================\n');
  }

  /// 跳过条件检查
  String? skipIfNoApiKey() => TestEnvironment.skipNoApiKey();
  String? skipIfNoIntegration() => TestEnvironment.skipIntegration();
  String? skipIfNoDestructive() => TestEnvironment.skipDestructive();
}

/// 测试数据验证工具类
class TestDataValidator {
  /// 验证字符串非空
  static void expectNonEmptyString(String? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    expect(value, isNotEmpty, reason: '${fieldName ?? 'Field'} should not be empty');
  }

  /// 验证正整数
  static void expectPositiveInt(int? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    expect(value, greaterThan(0), reason: '${fieldName ?? 'Field'} should be positive');
  }

  /// 验证非负整数
  static void expectNonNegativeInt(int? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    expect(value, greaterThanOrEqualTo(0), reason: '${fieldName ?? 'Field'} should be non-negative');
  }

  /// 验证百分比（0-100）
  static void expectPercentage(num? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    expect(value, greaterThanOrEqualTo(0), reason: '${fieldName ?? 'Field'} should be >= 0');
    expect(value, lessThanOrEqualTo(100), reason: '${fieldName ?? 'Field'} should be <= 100');
  }

  /// 验证列表非空
  static void expectNonEmptyList(List? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    expect(value, isNotEmpty, reason: '${fieldName ?? 'Field'} should not be empty');
  }

  /// 验证日期时间格式
  static void expectValidDateTime(String? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    expect(() => DateTime.parse(value!), returnsNormally,
        reason: '${fieldName ?? 'Field'} should be a valid datetime');
  }

  /// 验证URL格式
  static void expectValidUrl(String? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    final uri = Uri.tryParse(value!);
    expect(uri, isNotNull, reason: '${fieldName ?? 'Field'} should be a valid URL');
    expect(uri!.hasScheme, isTrue, reason: '${fieldName ?? 'Field'} should have a scheme');
  }

  /// 验证IP地址格式
  static void expectValidIpAddress(String? value, {String? fieldName}) {
    expect(value, isNotNull, reason: '${fieldName ?? 'Field'} should not be null');
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final ipv6Regex = RegExp(r'^[0-9a-fA-F:]+$');
    expect(
      ipv4Regex.hasMatch(value!) || ipv6Regex.hasMatch(value),
      isTrue,
      reason: '${fieldName ?? 'Field'} should be a valid IP address',
    );
  }
}

/// 测试性能计时器
class TestPerformanceTimer {
  final String _name;
  late DateTime _startTime;
  Duration? _duration;

  TestPerformanceTimer(this._name);

  void start() {
    _startTime = DateTime.now();
  }

  void stop() {
    _duration = DateTime.now().difference(_startTime);
  }

  void logResult() {
    if (_duration != null) {
      final ms = _duration!.inMilliseconds;
      final status = ms < 1000 ? '✅' : (ms < 3000 ? '⚠️' : '❌');
      debugPrint('$status $_name: ${ms}ms');
    }
  }

  Duration get duration => _duration ?? Duration.zero;
}

/// 测试结果收集器
class TestResultCollector {
  final List<TestResultItem> _results = [];

  void addSuccess(String testName, Duration duration) {
    _results.add(TestResultItem(
      testName: testName,
      passed: true,
      duration: duration,
    ));
  }

  void addFailure(String testName, String error, Duration duration) {
    _results.add(TestResultItem(
      testName: testName,
      passed: false,
      error: error,
      duration: duration,
    ));
  }

  void addSkipped(String testName, String reason) {
    _results.add(TestResultItem(
      testName: testName,
      passed: true,
      skipped: true,
      error: reason,
      duration: Duration.zero,
    ));
  }

  void printSummary() {
    final passed = _results.where((r) => r.passed && !r.skipped).length;
    final failed = _results.where((r) => !r.passed).length;
    final skipped = _results.where((r) => r.skipped).length;
    final total = _results.length;

    debugPrint('\n');
    debugPrint('╔════════════════════════════════════════════════════════════╗');
    debugPrint('║                    测试结果汇总                            ║');
    debugPrint('╠════════════════════════════════════════════════════════════╣');
    debugPrint('║ 总测试数: $total');
    debugPrint('║ ✅ 通过: $passed');
    debugPrint('║ ❌ 失败: $failed');
    debugPrint('║ ⏭️  跳过: $skipped');
    debugPrint('║ 通过率: ${total > 0 ? (passed / total * 100).toStringAsFixed(1) : 0}%');
    debugPrint('╚════════════════════════════════════════════════════════════╝');

    if (failed > 0) {
      debugPrint('\n失败的测试:');
      for (final result in _results.where((r) => !r.passed)) {
        debugPrint('  ❌ ${result.testName}: ${result.error}');
      }
    }
    debugPrint('\n');
  }

  List<TestResultItem> get results => List.unmodifiable(_results);
}

class TestResultItem {
  final String testName;
  final bool passed;
  final bool skipped;
  final String? error;
  final Duration duration;

  TestResultItem({
    required this.testName,
    required this.passed,
    this.skipped = false,
    this.error,
    required this.duration,
  });
}
