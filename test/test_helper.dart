import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

/// 测试配置类
class TestConfig {
  static late final Map<String, String> _env;
  static bool _initialized = false;

  /// 初始化测试配置
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final content = await envFile.readAsString();
        _env = _parseEnv(content);
      } else {
        _env = {};
        debugPrint('Warning: .env file not found, using default values');
      }
      _initialized = true;
    } catch (e) {
      _env = {};
      debugPrint('Error loading .env file: $e');
      _initialized = true;
    }
  }

  /// 解析环境变量文件
  static Map<String, String> _parseEnv(String content) {
    final env = <String, String>{};
    final lines = content.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final index = line.indexOf('=');
      if (index > 0) {
        final key = line.substring(0, index).trim();
        final value = line.substring(index + 1).trim();
        env[key] = value;
      }
    }

    return env;
  }

  /// 获取配置值
  static String get(String key, {String defaultValue = ''}) {
    return _env[key] ?? defaultValue;
  }

  /// 获取布尔配置值
  static bool getBool(String key, {bool defaultValue = false}) {
    final value = _env[key]?.toLowerCase();
    return value == 'true' || value == '1';
  }

  /// 获取整数配置值
  static int getInt(String key, {int defaultValue = 0}) {
    return int.tryParse(_env[key] ?? '') ?? defaultValue;
  }

  // 快捷访问常用配置
  static String get baseUrl =>
      get('PANEL_BASE_URL', defaultValue: 'http://localhost:8080');
  static String get apiKey => get('PANEL_API_KEY');
  static String get apiVersion => get('API_VERSION', defaultValue: 'v2');
  static String get testDomain =>
      get('TEST_DOMAIN', defaultValue: 'test.example.com');
  static String get testIp => get('TEST_IP', defaultValue: '127.0.0.1');
  static String get testEmail =>
      get('TEST_EMAIL', defaultValue: 'test@example.com');
  static bool get runIntegrationTests => getBool('RUN_INTEGRATION_TESTS');
  static bool get runDestructiveTests => getBool('RUN_DESTRUCTIVE_TESTS');
  static int get testTimeout => getInt('TEST_TIMEOUT', defaultValue: 30000);
  static int get tokenValidityMinutes =>
      getInt('TOKEN_VALIDITY_MINUTES', defaultValue: 0);
}

/// Token生成器
class TokenGenerator {
  /// 生成1Panel认证Token
  ///
  /// Token格式: md5('1panel' + API-Key + UnixTimestamp)
  static String generateToken(String apiKey, int timestamp) {
    final data = '1panel$apiKey$timestamp';
    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 生成当前时间的Token
  static Map<String, String> generateAuthHeaders(String apiKey) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final token = generateToken(apiKey, timestamp);

    return {
      '1Panel-Token': token,
      '1Panel-Timestamp': timestamp.toString(),
    };
  }

  /// 验证Token格式
  static bool validateTokenFormat(String token) {
    if (token.isEmpty || token.length != 32) return false;
    return RegExp(r'^[a-f0-9]{32}$').hasMatch(token);
  }
}

/// 测试数据生成器
class TestDataGenerator {
  static final _random = Random();

  /// 生成随机字符串
  static String randomString(int length,
      {String chars = 'abcdefghijklmnopqrstuvwxyz0123456789'}) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  /// 生成随机整数
  static int randomInt(int min, int max) {
    return min + _random.nextInt(max - min);
  }

  /// 生成测试用的域名
  static String generateTestDomain() {
    return 'test-${randomString(8)}.example.com';
  }

  /// 生成测试用的邮箱
  static String generateTestEmail() {
    return 'test-${randomString(8)}@example.com';
  }

  /// 生成测试用的IP地址
  static String generateTestIp() {
    return '${randomInt(1, 256)}.${randomInt(0, 256)}.${randomInt(0, 256)}.${randomInt(1, 256)}';
  }

  /// 生成测试用的主机名
  static String generateTestHostname() {
    return 'host-${randomString(6)}';
  }
}

/// API测试客户端
class TestApiClient {
  late final DioClient _client;
  final String baseUrl;
  final String apiKey;

  TestApiClient({
    required this.baseUrl,
    required this.apiKey,
  }) {
    _client = DioClient(
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }

  DioClient get client => _client;

  /// 发送带认证的请求
  Future<Response> authenticatedGet(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final headers = TokenGenerator.generateAuthHeaders(apiKey);
    return await _client.get(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
  }

  /// 发送带认证的POST请求
  Future<Response> authenticatedPost(String path, {dynamic data}) async {
    final headers = TokenGenerator.generateAuthHeaders(apiKey);
    return await _client.post(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }

  /// 发送带认证的DELETE请求
  Future<Response> authenticatedDelete(String path, {dynamic data}) async {
    final headers = TokenGenerator.generateAuthHeaders(apiKey);
    return await _client.delete(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }

  /// 关闭客户端
  void dispose() {
    // DioClient不需要显式关闭
  }
}

/// 测试匹配器
class TestMatchers {
  /// 验证响应成功
  static Matcher isSuccess() {
    return predicate<Response>(
      (response) => response.statusCode == 200 || response.statusCode == 201,
      'is successful response',
    );
  }

  /// 验证响应状态码
  static Matcher hasStatusCode(int statusCode) {
    return predicate<Response>(
      (response) => response.statusCode == statusCode,
      'has status code $statusCode',
    );
  }

  /// 验证响应包含数据
  static Matcher hasData() {
    return predicate<Response>(
      (response) => response.data != null,
      'has data',
    );
  }

  /// 验证响应数据是列表
  static Matcher hasListData() {
    return predicate<Response>(
      (response) => response.data is List,
      'has list data',
    );
  }

  /// 验证响应数据是Map
  static Matcher hasMapData() {
    return predicate<Response>(
      (response) => response.data is Map<String, dynamic>,
      'has map data',
    );
  }
}

/// 测试分组标记
class TestGroups {
  static const String unit = 'unit';
  static const String integration = 'integration';
  static const String destructive = 'destructive';
  static const String auth = 'auth';
  static const String toolbox = 'toolbox';
  static const String command = 'command';
  static const String mcp = 'mcp';
}

/// 跳过测试的条件函数
class SkipConditions {
  /// 跳过集成测试
  static String? skipIntegration() {
    return TestConfig.runIntegrationTests ? null : 'Integration tests disabled';
  }

  /// 跳过破坏性测试
  static String? skipDestructive() {
    return TestConfig.runDestructiveTests ? null : 'Destructive tests disabled';
  }

  /// 跳过缺少API密钥的测试
  static String? skipNoApiKey() {
    return TestConfig.apiKey.isNotEmpty &&
            TestConfig.apiKey != 'your_api_key_here'
        ? null
        : 'API key not configured';
  }
}

/// 初始化测试环境
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await TestConfig.initialize();
}

/// 清理测试环境
Future<void> teardownTestEnvironment() async {
  // 清理临时文件等
  final logDir =
      Directory(TestConfig.get('TEST_LOG_PATH', defaultValue: './test_logs'));
  if (logDir.existsSync()) {
    // 保留最近7天的日志
    final now = DateTime.now();
    await for (final file in logDir.list()) {
      if (file is File) {
        final stat = await file.stat();
        if (now.difference(stat.modified).inDays > 7) {
          await file.delete();
        }
      }
    }
  }
}
