import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/api/v2/monitor_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  late DioClient client;
  late MonitorV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = MonitorV2Api(client);
    }
  });

  group('Monitor API真实响应测试', () {
    test('搜索监控数据(param=all) - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: POST /hosts/monitor/search (param=all)');
      debugPrint('========================================');

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));

      final request = MonitorSearch(
        param: 'all',
        startTime: startTime.toUtc().toIso8601String(),
        endTime: now.toUtc().toIso8601String(),
      );

      debugPrint('请求参数:');
      debugPrint('  param: all');
      debugPrint('  startTime: ${startTime.toUtc().toIso8601String()}');
      debugPrint('  endTime: ${now.toUtc().toIso8601String()}');

      final response = await api.search(request);
      
      debugPrint('\n状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        debugPrint('\n--- 响应结构 ---');
        debugPrint('code: ${response.data!.code}');
        debugPrint('message: ${response.data!.message}');
        debugPrint('data项数: ${response.data!.data?.length ?? 0}');
        
        if (response.data!.data != null) {
          for (var i = 0; i < response.data!.data!.length; i++) {
            final item = response.data!.data![i];
            debugPrint('\n--- 数据项 $i ---');
            debugPrint('  param: ${item.param}');
            debugPrint('  date数量: ${item.date?.length ?? 0}');
            debugPrint('  value数量: ${item.value?.length ?? 0}');
            
            if (item.value != null && item.value!.isNotEmpty) {
              debugPrint('  最后一个value:');
              final lastValue = item.value!.last;
              lastValue.forEach((key, value) {
                debugPrint('    $key: $value');
              });
            }
          }
        }
        
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('\n完整响应数据:\n$jsonStr');
      } else {
        debugPrint('响应数据为空');
      }
      debugPrint('========================================\n');
    });

    test('搜索监控数据(param=base) - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: POST /hosts/monitor/search (param=base)');
      debugPrint('========================================');

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));

      final request = MonitorSearch(
        param: 'base',
        startTime: startTime.toUtc().toIso8601String(),
        endTime: now.toUtc().toIso8601String(),
      );

      final response = await api.search(request);
      
      debugPrint('状态码: ${response.statusCode}');
      
      if (response.data != null) {
        debugPrint('code: ${response.data!.code}');
        debugPrint('data项数: ${response.data!.data?.length ?? 0}');
        
        if (response.data!.data != null && response.data!.data!.isNotEmpty) {
          final item = response.data!.data!.first;
          debugPrint('param: ${item.param}');
          debugPrint('value数量: ${item.value?.length ?? 0}');
          
          if (item.value != null && item.value!.isNotEmpty) {
            debugPrint('\n--- 最后一个value ---');
            final lastValue = item.value!.last;
            lastValue.forEach((key, value) {
              debugPrint('  $key: $value');
            });
          }
        }
        
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('\n完整响应数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('搜索监控数据(param=cpu) - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: POST /hosts/monitor/search (param=cpu)');
      debugPrint('========================================');

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));

      final request = MonitorSearch(
        param: 'cpu',
        startTime: startTime.toUtc().toIso8601String(),
        endTime: now.toUtc().toIso8601String(),
      );

      final response = await api.search(request);
      
      debugPrint('状态码: ${response.statusCode}');
      
      if (response.data != null) {
        debugPrint('code: ${response.data!.code}');
        debugPrint('data项数: ${response.data!.data?.length ?? 0}');
        
        // 打印所有数据项
        for (final item in response.data!.data ?? []) {
          debugPrint('\n--- 数据项 ${item.param} ---');
          debugPrint('date数量: ${item.date?.length ?? 0}');
          debugPrint('value数量: ${item.value?.length ?? 0}');
          
          // 打印date数组内容
          if (item.date != null && item.date!.isNotEmpty) {
            debugPrint('date数组前3个:');
            for (var i = 0; i < item.date!.length && i < 3; i++) {
              debugPrint('  date[$i]: "${item.date![i]}" (类型: ${item.date![i].runtimeType})');
            }
          }
          
          // 打印最后一个value
          if (item.value != null && item.value!.isNotEmpty) {
            final lastVal = item.value!.last;
            if (lastVal is Map) {
              debugPrint('最后一个value keys: ${lastVal.keys.toList()}');
            }
          }
        }
      }
      debugPrint('========================================\n');
    });

    test('搜索监控数据(param=memory) - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: POST /hosts/monitor/search (param=memory)');
      debugPrint('========================================');

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));

      final request = MonitorSearch(
        param: 'memory',
        startTime: startTime.toUtc().toIso8601String(),
        endTime: now.toUtc().toIso8601String(),
      );

      final response = await api.search(request);
      
      debugPrint('状态码: ${response.statusCode}');
      
      if (response.data != null) {
        debugPrint('code: ${response.data!.code}');
        
        if (response.data!.data != null && response.data!.data!.isNotEmpty) {
          final item = response.data!.data!.first;
          debugPrint('param: ${item.param}');
          debugPrint('value数量: ${item.value?.length ?? 0}');
          
          if (item.value != null && item.value!.isNotEmpty) {
            debugPrint('\n--- 最后一个value ---');
            final lastValue = item.value!.last;
            lastValue.forEach((key, value) {
              debugPrint('  $key: $value');
            });
          }
        }
        
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('\n完整响应数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('搜索监控数据(param=io) - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: POST /hosts/monitor/search (param=io)');
      debugPrint('========================================');

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));

      final request = MonitorSearch(
        param: 'io',
        startTime: startTime.toUtc().toIso8601String(),
        endTime: now.toUtc().toIso8601String(),
      );

      final response = await api.search(request);
      
      debugPrint('状态码: ${response.statusCode}');
      
      if (response.data != null) {
        debugPrint('code: ${response.data!.code}');
        
        if (response.data!.data != null && response.data!.data!.isNotEmpty) {
          final item = response.data!.data!.first;
          debugPrint('param: ${item.param}');
          debugPrint('value数量: ${item.value?.length ?? 0}');
          
          if (item.value != null && item.value!.isNotEmpty) {
            debugPrint('\n--- 最后一个value ---');
            final lastValue = item.value!.last;
            lastValue.forEach((key, value) {
              debugPrint('  $key: $value');
            });
          }
        }
        
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('\n完整响应数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('获取监控设置 - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: GET /hosts/monitor/setting');
      debugPrint('========================================');

      // 首先打印原始响应
      final dio = client.dio;
      final rawResponse = await dio.get('/api/v2/hosts/monitor/setting');
      
      debugPrint('\n--- 原始响应 ---');
      debugPrint('状态码: ${rawResponse.statusCode}');
      debugPrint('数据类型: ${rawResponse.data.runtimeType}');
      if (rawResponse.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(rawResponse.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      
      // 测试解析后的数据
      final response = await api.getSetting();
      
      debugPrint('\n--- 解析后数据 ---');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        debugPrint('interval: ${response.data!.interval}');
        debugPrint('retention: ${response.data!.retention}');
        debugPrint('enabled: ${response.data!.enabled}');
        
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('\n完整响应数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });
  });
}
