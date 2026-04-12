import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class TestConfigManager {
  static final TestConfigManager _instance = TestConfigManager._internal();
  static TestConfigManager get instance => _instance;

  Map<String, String> _config = {};
  bool _initialized = false;

  TestConfigManager._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    _config = await _loadConfig();
    _initialized = true;
  }

  Future<Map<String, String>> _loadConfig() async {
    final config = <String, String>{};

    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final content = await envFile.readAsString();
        final lines = content.split('\n');

        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty || line.startsWith('#')) continue;

          final index = line.indexOf('=');
          if (index > 0) {
            final key = line.substring(0, index).trim();
            var value = line.substring(index + 1).trim();
            if (value.startsWith('"') && value.endsWith('"')) {
              value = value.substring(1, value.length - 1);
            } else if (value.startsWith("'") && value.endsWith("'")) {
              value = value.substring(1, value.length - 1);
            } else if (value.startsWith("`") && value.endsWith("`")) {
              value = value.substring(1, value.length - 1);
            }
            config[key] = value;
          }
        }
      } else {
        debugPrint('Warning: .env file not found, using default values');
      }
    } catch (e) {
      debugPrint('Error loading .env file: $e');
    }

    return config;
  }

  String getString(String key, {String defaultValue = ''}) {
    final envOverride = Platform.environment[key];
    if (envOverride != null && envOverride.isNotEmpty) {
      return envOverride;
    }
    return _config[key] ?? defaultValue;
  }

  int getInt(String key, {int defaultValue = 0}) {
    final envOverride = Platform.environment[key];
    if (envOverride != null && envOverride.isNotEmpty) {
      return int.tryParse(envOverride) ?? defaultValue;
    }
    return int.tryParse(_config[key] ?? '') ?? defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final envOverride = Platform.environment[key];
    final value = (envOverride ?? _config[key])?.toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    final envOverride = Platform.environment[key];
    if (envOverride != null && envOverride.isNotEmpty) {
      return double.tryParse(envOverride) ?? defaultValue;
    }
    return double.tryParse(_config[key] ?? '') ?? defaultValue;
  }

  List<String> getStringList(String key,
      {List<String> defaultValue = const []}) {
    final value = Platform.environment[key] ?? _config[key];
    if (value == null || value.isEmpty) return defaultValue;
    return value.split(',').map((e) => e.trim()).toList();
  }

  bool get isInitialized => _initialized;

  Map<String, String> get allConfig => Map.unmodifiable(_config);

  void validate() {
    final requiredKeys = [
      'PANEL_BASE_URL',
      'PANEL_API_KEY',
    ];

    final missingKeys = <String>[];
    for (final key in requiredKeys) {
      if (!_config.containsKey(key) ||
          _config[key]!.isEmpty ||
          _config[key] == 'your_api_key_here') {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      debugPrint(
          'Warning: Missing or invalid configuration for: ${missingKeys.join(', ')}');
    }
  }
}

class TestEnvironment {
  static TestConfigManager? _config;

  static Future<void> initialize() async {
    _config = TestConfigManager.instance;
    await _config!.initialize();
    _config!.validate();
  }

  static TestConfigManager get config {
    if (_config == null) {
      throw StateError(
          'TestEnvironment not initialized. Call TestEnvironment.initialize() first.');
    }
    return _config!;
  }

  static String get baseUrl =>
      config.getString('PANEL_BASE_URL', defaultValue: 'http://localhost:9999');
  static String get apiKey => (runIntegrationTests || runLiveApiTests || true)
      ? config.getString('PANEL_API_KEY')
      : '';
  static String get apiVersion =>
      config.getString('API_VERSION', defaultValue: 'v2');
  static int get tokenValidityMinutes =>
      config.getInt('TOKEN_VALIDITY_MINUTES', defaultValue: 0);

  static String get testDomain =>
      config.getString('TEST_DOMAIN', defaultValue: 'test.example.com');
  static String get testIp =>
      config.getString('TEST_IP', defaultValue: '127.0.0.1');
  static String get testEmail =>
      config.getString('TEST_EMAIL', defaultValue: 'test@example.com');

  static bool get runIntegrationTests =>
      config.getBool('RUN_INTEGRATION_TESTS');
  static bool get runLiveApiTests => config.getBool('RUN_LIVE_API_TESTS');
  static bool get runDestructiveTests =>
      config.getBool('RUN_DESTRUCTIVE_TESTS');
  static bool get runPerformanceTests =>
      config.getBool('RUN_PERFORMANCE_TESTS');
  static int get testTimeout =>
      config.getInt('TEST_TIMEOUT', defaultValue: 30000);

  static String get testLogLevel =>
      config.getString('TEST_LOG_LEVEL', defaultValue: 'info');
  static bool get saveTestLogs => config.getBool('SAVE_TEST_LOGS');
  static String get testLogPath =>
      config.getString('TEST_LOG_PATH', defaultValue: './test_logs');

  static String get testReportPath =>
      config.getString('TEST_REPORT_PATH', defaultValue: './test_reports');
  static bool get generateHtmlReport => config.getBool('GENERATE_HTML_REPORT');
  static bool get generateJsonReport => config.getBool('GENERATE_JSON_REPORT');

  static String? skipIntegration() {
    return runIntegrationTests
        ? null
        : 'Integration tests disabled (set RUN_INTEGRATION_TESTS=true)';
  }

  static String? skipLiveApi() {
    return runLiveApiTests
        ? null
        : 'Live API tests disabled (set RUN_LIVE_API_TESTS=true)';
  }

  static String? skipDestructive() {
    return runDestructiveTests
        ? null
        : 'Destructive tests disabled (set RUN_DESTRUCTIVE_TESTS=true)';
  }

  static String? skipPerformance() {
    return runPerformanceTests
        ? null
        : 'Performance tests disabled (set RUN_PERFORMANCE_TESTS=true)';
  }

  static String? skipNoApiKey() {
    if (_config == null || !_config!.isInitialized) {
      return 'TestEnvironment not initialized';
    }
    if (apiKey.isEmpty || apiKey == 'your_api_key_here') {
      return 'API key not configured (set PANEL_API_KEY in .env)';
    }
    return null;
  }

  static bool get canRunIntegrationTests {
    return runIntegrationTests && skipNoApiKey() == null;
  }

  static bool get canRunLiveApiTests {
    return runLiveApiTests && skipNoApiKey() == null;
  }
}
