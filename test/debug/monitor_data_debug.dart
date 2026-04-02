import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

/// 监控数据调试脚本
/// 用于测试真实API响应并诊断数据为空的问题
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await TestEnvironment.initialize();

  final hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
      TestEnvironment.apiKey != 'your_api_key_here';

  if (!hasApiKey) {
    print('⚠️  API密钥未配置，请在.env文件中设置PANEL_API_KEY');
    return;
  }

  final client = DioClient(
    baseUrl: TestEnvironment.baseUrl,
    apiKey: TestEnvironment.apiKey,
  );

  print('\n========================================');
  print('监控数据调试 - 测试真实API响应');
  print('========================================');
  print('Base URL: ${TestEnvironment.baseUrl}');
  print('========================================\n');

  final now = DateTime.now();
  final startTime = now.subtract(const Duration(hours: 1));

  // 测试1: param=all
  print('\n--- 测试1: param=all ---');
  try {
    final response = await client.post(
      '/api/v2/hosts/monitor/search',
      data: {
        'param': 'all',
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
      },
    );

    print('状态码: ${response.statusCode}');
    if (response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final dataList = data['data'] as List?;
      print('data项数: ${dataList?.length ?? 0}');

      if (dataList != null) {
        for (var item in dataList) {
          final itemMap = item as Map<String, dynamic>;
          final param = itemMap['param'];
          final values = itemMap['value'] as List?;
          print('\n  param: $param');
          print('  value数量: ${values?.length ?? 0}');

          if (values != null && values.isNotEmpty) {
            final lastValue = values.last as Map<String, dynamic>;
            print('  最后一个value的字段:');
            lastValue.forEach((key, value) {
              print('    $key: $value (${value.runtimeType})');
            });
          }
        }
      }

      print('\n完整响应:');
      print(const JsonEncoder.withIndent('  ').convert(response.data));
    }
  } catch (e, stack) {
    print('❌ 错误: $e');
    print('堆栈: $stack');
  }

  // 测试2: param=base
  print('\n\n--- 测试2: param=base ---');
  try {
    final response = await client.post(
      '/api/v2/hosts/monitor/search',
      data: {
        'param': 'base',
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
      },
    );

    print('状态码: ${response.statusCode}');
    if (response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final dataList = data['data'] as List?;

      if (dataList != null && dataList.isNotEmpty) {
        final item = dataList.first as Map<String, dynamic>;
        final values = item['value'] as List?;

        if (values != null && values.isNotEmpty) {
          final lastValue = values.last as Map<String, dynamic>;
          print('\n最后一个value的所有字段:');
          lastValue.forEach((key, value) {
            print('  $key: $value');
          });
        }
      }
    }
  } catch (e) {
    print('❌ 错误: $e');
  }

  // 测试3: param=io
  print('\n\n--- 测试3: param=io ---');
  try {
    final response = await client.post(
      '/api/v2/hosts/monitor/search',
      data: {
        'param': 'io',
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
      },
    );

    print('状态码: ${response.statusCode}');
    if (response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final dataList = data['data'] as List?;

      if (dataList != null && dataList.isNotEmpty) {
        final item = dataList.first as Map<String, dynamic>;
        final values = item['value'] as List?;

        print('value数量: ${values?.length ?? 0}');
        if (values != null && values.isNotEmpty) {
          final lastValue = values.last as Map<String, dynamic>;
          print('\n最后一个value的所有字段:');
          lastValue.forEach((key, value) {
            print('  $key: $value');
          });
        } else {
          print('⚠️  value为空或null');
        }
      } else {
        print('⚠️  data为空或null');
      }

      print('\n完整响应:');
      print(const JsonEncoder.withIndent('  ').convert(response.data));
    }
  } catch (e) {
    print('❌ 错误: $e');
  }

  // 测试4: param=network
  print('\n\n--- 测试4: param=network ---');
  try {
    final response = await client.post(
      '/api/v2/hosts/monitor/search',
      data: {
        'param': 'network',
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
      },
    );

    print('状态码: ${response.statusCode}');
    if (response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final dataList = data['data'] as List?;

      if (dataList != null && dataList.isNotEmpty) {
        final item = dataList.first as Map<String, dynamic>;
        final values = item['value'] as List?;

        print('value数量: ${values?.length ?? 0}');
        if (values != null && values.isNotEmpty) {
          final lastValue = values.last as Map<String, dynamic>;
          print('\n最后一个value的所有字段:');
          lastValue.forEach((key, value) {
            print('  $key: $value');
          });
        } else {
          print('⚠️  value为空或null');
        }
      } else {
        print('⚠️  data为空或null');
      }

      print('\n完整响应:');
      print(const JsonEncoder.withIndent('  ').convert(response.data));
    }
  } catch (e) {
    print('❌ 错误: $e');
  }

  print('\n========================================');
  print('调试完成');
  print('========================================\n');
}
