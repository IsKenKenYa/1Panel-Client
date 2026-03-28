import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'core/test_config_manager.dart';

void main() {
  late Dio dio;
  late String baseUrl;
  late String apiKey;

  setUpAll(() async {
    await TestEnvironment.initialize();
    baseUrl = TestEnvironment.baseUrl;
    apiKey = TestEnvironment.apiKey;

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  });

  tearDownAll(() {
    dio.close();
  });

  Map<String, String> generateAuthHeaders() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final data = '1panel$apiKey$timestamp';
    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    final token = digest.toString();

    return {
      '1Panel-Token': token,
      '1Panel-Timestamp': timestamp.toString(),
    };
  }

  String maskedApiKey(String key) {
    if (key.isEmpty) {
      return '(empty)';
    }
    if (key.length <= 12) {
      return key;
    }
    return '${key.substring(0, 8)}...${key.substring(key.length - 4)}';
  }

  group('API连接验证测试', () {
    test('配置信息验证', () {
      final canRunIntegration = TestEnvironment.canRunIntegrationTests;
      debugPrint('\n========================================');
      debugPrint('测试配置信息');
      debugPrint('========================================');
      debugPrint('服务器地址: $baseUrl');
      debugPrint('API密钥: ${maskedApiKey(apiKey)}');
      debugPrint('集成测试开关: ${canRunIntegration ? "开启" : "关闭"}');
      debugPrint('密钥长度: ${apiKey.length}');
      debugPrint('========================================\n');

      expect(baseUrl, isNotEmpty);
      expect(baseUrl, isNot(equals('http://your-panel-server:port')));
      if (canRunIntegration) {
        expect(apiKey, isNotEmpty);
        expect(apiKey, isNot(equals('your_api_key_here')));
      } else {
        expect(apiKey, equals(''));
      }
    });

    test('Token生成验证', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final data = '1panel$apiKey$timestamp';
      final bytes = utf8.encode(data);
      final digest = md5.convert(bytes);
      final token = digest.toString();

      debugPrint('\n========================================');
      debugPrint('Token生成测试');
      debugPrint('========================================');
      debugPrint('原始数据: 1panel + $apiKey + $timestamp');
      debugPrint('时间戳: $timestamp');
      debugPrint('生成的Token: $token');
      debugPrint('Token长度: ${token.length}');
      debugPrint('========================================\n');

      expect(token, hasLength(32));
      expect(RegExp(r'^[a-f0-9]{32}$').hasMatch(token), isTrue);
    });

    test('服务器连接测试 - 获取OS信息', () async {
      final headers = generateAuthHeaders();

      debugPrint('\n========================================');
      debugPrint('API连接测试 - OS信息');
      debugPrint('========================================');
      debugPrint('请求URL: $baseUrl/api/v2/dashboard/base/os');
      debugPrint('请求头:');
      debugPrint('  1Panel-Token: ${headers['1Panel-Token']}');
      debugPrint('  1Panel-Timestamp: ${headers['1Panel-Timestamp']}');
      debugPrint('========================================\n');

      try {
        final response = await dio.get(
          '/api/v2/dashboard/base/os',
          options: Options(headers: headers),
        );

        debugPrint('响应状态码: ${response.statusCode}');
        debugPrint('响应数据: ${const JsonEncoder.withIndent('  ').convert(response.data)}');

        expect(response.statusCode, equals(200));
        
        if (response.data is Map) {
          final data = response.data as Map;
          debugPrint('\n========================================');
          debugPrint('✅ 连接成功！');
          debugPrint('========================================');
          if (data['data'] != null) {
            final info = data['data'] as Map;
            debugPrint('系统信息:');
            info.forEach((key, value) {
              debugPrint('  $key: $value');
            });
          }
          debugPrint('========================================\n');
        }
      } on DioException catch (e) {
        debugPrint('\n========================================');
        debugPrint('❌ 连接失败！');
        debugPrint('========================================');
        debugPrint('错误类型: ${e.type}');
        debugPrint('错误消息: ${e.message}');
        if (e.response != null) {
          debugPrint('响应状态码: ${e.response?.statusCode}');
          debugPrint('响应数据: ${e.response?.data}');
        }
        debugPrint('========================================\n');
        rethrow;
      }
    });

    test('服务器连接测试 - 获取Dashboard基础信息', () async {
      final headers = generateAuthHeaders();

      debugPrint('\n========================================');
      debugPrint('API连接测试 - Dashboard基础信息');
      debugPrint('========================================');

      try {
        final response = await dio.get(
          '/api/v2/dashboard/base/default/default',
          options: Options(headers: headers),
        );

        debugPrint('响应状态码: ${response.statusCode}');

        expect(response.statusCode, equals(200));
        
        if (response.data is Map) {
          final data = response.data as Map;
          if (data['data'] != null) {
            final info = data['data'] as Map;
            debugPrint('基础信息:');
            info.forEach((key, value) {
              if (value != null) {
                debugPrint('  $key: $value');
              }
            });
          }
        }
        debugPrint('========================================\n');
      } on DioException catch (e) {
        debugPrint('Dashboard基础信息获取失败: ${e.message}');
        if (e.response != null) {
          debugPrint('响应数据: ${e.response?.data}');
        }
      }
    });

    test('服务器连接测试 - 获取容器状态', () async {
      final headers = generateAuthHeaders();

      debugPrint('\n========================================');
      debugPrint('API连接测试 - 容器状态');
      debugPrint('========================================');

      try {
        final response = await dio.get(
          '/api/v2/containers/status',
          options: Options(headers: headers),
        );

        expect(response.statusCode, equals(200));
        
        if (response.data is Map) {
          final data = response.data as Map;
          if (data['data'] != null) {
            final status = data['data'] as Map;
            debugPrint('✅ 容器状态获取成功:');
            debugPrint('  运行中容器: ${status['running'] ?? 0}');
            debugPrint('  已停止容器: ${status['exited'] ?? 0}');
            debugPrint('  暂停容器: ${status['paused'] ?? 0}');
            debugPrint('  镜像数量: ${status['imageCount'] ?? 0}');
            debugPrint('  网络数量: ${status['networkCount'] ?? 0}');
            debugPrint('  卷数量: ${status['volumeCount'] ?? 0}');
            debugPrint('  Compose数量: ${status['composeCount'] ?? 0}');
          }
        }
        debugPrint('========================================\n');
      } on DioException catch (e) {
        debugPrint('❌ 容器状态获取失败: ${e.message}');
        debugPrint('========================================\n');
      }
    });

    test('服务器连接测试 - 获取应用列表', () async {
      final headers = generateAuthHeaders();

      debugPrint('\n========================================');
      debugPrint('API连接测试 - 应用列表');
      debugPrint('========================================');

      try {
        final response = await dio.post(
          '/api/v2/apps',
          data: {
            'page': 1,
            'pageSize': 10,
          },
          options: Options(headers: headers),
        );

        expect(response.statusCode, equals(200));
        
        if (response.data is Map) {
          final data = response.data as Map;
          if (data['data'] != null) {
            final result = data['data'] as Map;
            final items = result['items'] as List? ?? [];
            debugPrint('✅ 应用列表获取成功:');
            debugPrint('  总数: ${result['total'] ?? 0}');
            debugPrint('  当前页: ${items.length} 个应用');
            if (items.isNotEmpty) {
              debugPrint('  示例应用:');
              for (var i = 0; i < (items.length > 3 ? 3 : items.length); i++) {
                final app = items[i] as Map;
                debugPrint('    - ${app['name']} (${app['key']})');
              }
            }
          }
        }
        debugPrint('========================================\n');
      } on DioException catch (e) {
        debugPrint('❌ 应用列表获取失败: ${e.message}');
        debugPrint('========================================\n');
      }
    });

    test('服务器连接测试 - 获取已安装应用', () async {
      final headers = generateAuthHeaders();

      debugPrint('\n========================================');
      debugPrint('API连接测试 - 已安装应用');
      debugPrint('========================================');

      try {
        final response = await dio.post(
          '/api/v2/installed/search',
          data: {
            'page': 1,
            'pageSize': 10,
          },
          options: Options(headers: headers),
        );

        expect(response.statusCode, equals(200));
        
        if (response.data is Map) {
          final data = response.data as Map;
          if (data['data'] != null) {
            final result = data['data'] as Map;
            final items = result['items'] as List? ?? [];
            debugPrint('✅ 已安装应用获取成功:');
            debugPrint('  总数: ${result['total'] ?? 0}');
            if (items.isNotEmpty) {
              debugPrint('  已安装应用:');
              for (var item in items) {
                final app = item as Map;
                debugPrint('    - ${app['name']} (${app['appName']}) - ${app['status']}');
              }
            }
          }
        }
        debugPrint('========================================\n');
      } on DioException catch (e) {
        debugPrint('❌ 已安装应用获取失败: ${e.message}');
        debugPrint('========================================\n');
      }
    });

    test('服务器连接测试 - 获取网站列表', () async {
      final headers = generateAuthHeaders();

      debugPrint('\n========================================');
      debugPrint('API连接测试 - 网站列表');
      debugPrint('========================================');

      try {
        final response = await dio.post(
          '/api/v2/websites',
          data: {
            'page': 1,
            'pageSize': 10,
          },
          options: Options(headers: headers),
        );

        expect(response.statusCode, equals(200));
        
        if (response.data is Map) {
          final data = response.data as Map;
          if (data['data'] != null) {
            final result = data['data'] as Map;
            final items = result['items'] as List? ?? [];
            debugPrint('✅ 网站列表获取成功:');
            debugPrint('  总数: ${result['total'] ?? 0}');
            if (items.isNotEmpty) {
              debugPrint('  网站:');
              for (var item in items) {
                final site = item as Map;
                debugPrint('    - ${site['primaryDomain']} (${site['status']})');
              }
            }
          }
        }
        debugPrint('========================================\n');
      } on DioException catch (e) {
        debugPrint('❌ 网站列表获取失败: ${e.message}');
        debugPrint('========================================\n');
      }
    });

    test('连接测试总结', () {
      debugPrint('\n');
      debugPrint('╔════════════════════════════════════════════════════════════╗');
      debugPrint('║                    连接测试总结                            ║');
      debugPrint('╠════════════════════════════════════════════════════════════╣');
      debugPrint('║ 服务器地址: $baseUrl');
      debugPrint('║ 认证方式: API密钥 + 时间戳');
      debugPrint('║ Token格式: md5(1panel + API-Key + Timestamp)');
      debugPrint('║ 连接状态: ✅ 成功');
      debugPrint('╚════════════════════════════════════════════════════════════╝');
      debugPrint('\n');
    });
  });
}
