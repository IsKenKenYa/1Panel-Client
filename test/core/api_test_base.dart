import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_config_manager.dart';

abstract class ApiTestBase {
  late Dio dio;
  late String baseUrl;
  late String apiKey;

  Future<void> setUpAll() async {
    await TestEnvironment.initialize();
    baseUrl = TestEnvironment.baseUrl;
    apiKey = TestEnvironment.apiKey;

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(milliseconds: TestEnvironment.testTimeout),
      receiveTimeout: Duration(milliseconds: TestEnvironment.testTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  void tearDownAll() {
    dio.close();
  }

  Map<String, String> generateAuthHeaders() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final token = _generateToken(apiKey, timestamp);

    return {
      '1Panel-Token': token,
      '1Panel-Timestamp': timestamp.toString(),
    };
  }

  String _generateToken(String apiKey, int timestamp) {
    final data = '1panel$apiKey$timestamp';
    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<Response> authenticatedGet(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final headers = generateAuthHeaders();
    return await dio.get(path,
        queryParameters: queryParameters, options: Options(headers: headers));
  }

  Future<Response> authenticatedPost(String path, {dynamic data}) async {
    final headers = generateAuthHeaders();
    return await dio.post(path, data: data, options: Options(headers: headers));
  }

  Future<Response> authenticatedPut(String path, {dynamic data}) async {
    final headers = generateAuthHeaders();
    return await dio.put(path, data: data, options: Options(headers: headers));
  }

  Future<Response> authenticatedDelete(String path, {dynamic data}) async {
    final headers = generateAuthHeaders();
    return await dio.delete(path,
        data: data, options: Options(headers: headers));
  }

  void expectSuccess(Response response) {
    expect(response.statusCode, equals(200));
    if (response.data is Map) {
      final data = response.data as Map;
      expect(data['code'], equals(200));
    }
  }

  void expectPageResult(Response response) {
    expect(response.statusCode, equals(200));
    final data = response.data as Map;
    expect(data['code'], equals(200));
    expect(data['data'], isNotNull);
    expect(data['data']['items'], isA<List>());
    expect(data['data']['total'], isA<int>());
  }

  String? skipIfNoApiKey() {
    return TestEnvironment.skipNoApiKey();
  }

  String? skipIfNoIntegration() {
    return TestEnvironment.skipIntegration();
  }

  String? skipIfNoDestructive() {
    return TestEnvironment.skipDestructive();
  }
}

class TestDataFactory {
  static final _random = Random();

  static String randomString(int length,
      {String chars = 'abcdefghijklmnopqrstuvwxyz0123456789'}) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  static int randomInt(int min, int max) {
    return min + _random.nextInt(max - min);
  }

  static String randomEmail() {
    return 'test_${randomString(8)}@example.com';
  }

  static String randomDomain() {
    return 'test-${randomString(8)}.example.com';
  }

  static String randomIp() {
    return '${randomInt(1, 256)}.${randomInt(0, 256)}.${randomInt(0, 256)}.${randomInt(1, 256)}';
  }

  static String randomPort() {
    return randomInt(1024, 65535).toString();
  }

  static String randomHostname() {
    return 'host-${randomString(6)}';
  }

  static String randomContainerName() {
    return 'container-${randomString(8)}';
  }

  static String randomAppName() {
    return 'app-${randomString(6)}';
  }

  static String randomDbName() {
    return 'db_${randomString(8)}';
  }

  static String randomUsername() {
    return 'user_${randomString(6)}';
  }

  static String randomApiKey() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return randomString(32, chars: chars);
  }
}

class ApiTestGroup {
  final String name;
  final String description;
  final List<ApiTestCase> testCases;

  ApiTestGroup({
    required this.name,
    required this.description,
    required this.testCases,
  });
}

class ApiTestCase {
  final String name;
  final String method;
  final String path;
  final dynamic requestBody;
  final Map<String, dynamic>? queryParams;
  final int expectedStatusCode;
  final dynamic expectedResponse;
  final bool requiresAuth;
  final bool isDestructive;
  final String? skipReason;

  ApiTestCase({
    required this.name,
    required this.method,
    required this.path,
    this.requestBody,
    this.queryParams,
    this.expectedStatusCode = 200,
    this.expectedResponse,
    this.requiresAuth = true,
    this.isDestructive = false,
    this.skipReason,
  });
}

class TestReport {
  final String testName;
  final DateTime startTime;
  final DateTime endTime;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int skippedTests;
  final List<TestResult> results;

  TestReport({
    required this.testName,
    required this.startTime,
    required this.endTime,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.skippedTests,
    required this.results,
  });

  Duration get duration => endTime.difference(startTime);

  double get passRate => totalTests > 0 ? (passedTests / totalTests) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration.inMilliseconds,
      'totalTests': totalTests,
      'passedTests': passedTests,
      'failedTests': failedTests,
      'skippedTests': skippedTests,
      'passRate': passRate.toStringAsFixed(2),
      'results': results.map((r) => r.toJson()).toList(),
    };
  }

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# $testName 测试报告');
    buffer.writeln();
    buffer.writeln('## 概要');
    buffer.writeln();
    buffer.writeln('| 指标 | 值 |');
    buffer.writeln('|------|------|');
    buffer.writeln('| 开始时间 | ${startTime.toIso8601String()} |');
    buffer.writeln('| 结束时间 | ${endTime.toIso8601String()} |');
    buffer.writeln('| 持续时间 | ${duration.inSeconds}秒 |');
    buffer.writeln('| 总测试数 | $totalTests |');
    buffer.writeln('| 通过数 | $passedTests |');
    buffer.writeln('| 失败数 | $failedTests |');
    buffer.writeln('| 跳过数 | $skippedTests |');
    buffer.writeln('| 通过率 | ${passRate.toStringAsFixed(2)}% |');
    buffer.writeln();
    buffer.writeln('## 测试结果详情');
    buffer.writeln();
    buffer.writeln('| 测试名称 | 状态 | 耗时(ms) | 错误信息 |');
    buffer.writeln('|----------|------|----------|----------|');

    for (final result in results) {
      final status =
          result.passed ? '✅ 通过' : (result.skipped ? '⏭️ 跳过' : '❌ 失败');
      buffer.writeln(
          '| ${result.name} | $status | ${result.duration.inMilliseconds} | ${result.error ?? '-'} |');
    }

    return buffer.toString();
  }
}

class TestResult {
  final String name;
  final bool passed;
  final bool skipped;
  final String? error;
  final Duration duration;

  TestResult({
    required this.name,
    required this.passed,
    this.skipped = false,
    this.error,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'passed': passed,
      'skipped': skipped,
      'error': error,
      'duration': duration.inMilliseconds,
    };
  }
}

class TestTimer {
  late DateTime _startTime;
  late DateTime _endTime;

  void start() {
    _startTime = DateTime.now();
  }

  void stop() {
    _endTime = DateTime.now();
  }

  Duration get duration => _endTime.difference(_startTime);
}
