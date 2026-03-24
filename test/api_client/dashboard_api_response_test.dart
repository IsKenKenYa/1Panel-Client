import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  late DioClient client;
  late DashboardV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = DashboardV2Api(client);
    }
  });

  group('Dashboard API真实响应测试', () {
    test('获取操作系统信息 - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: getOperatingSystemInfo');
      debugPrint('========================================');

      final response = await api.getOperatingSystemInfo();
      
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('完整响应数据:\n$jsonStr');
      } else {
        debugPrint('响应数据为空');
      }
      debugPrint('========================================\n');
    });

    test('获取仪表板基础指标 - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: getDashboardBase');
      debugPrint('========================================');

      final response = await api.getDashboardBase();
      
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('完整响应数据:\n$jsonStr');
        
        // 检查关键字段
        final data = response.data!;
        debugPrint('\n--- 关键字段检查 ---');
        debugPrint('cpuPercent: ${data['cpuPercent']}');
        debugPrint('memoryPercent: ${data['memoryPercent']}');
        debugPrint('diskPercent: ${data['diskPercent']}');
        debugPrint('cpuLoad1: ${data['cpuLoad1']}');
        debugPrint('cpuLoad5: ${data['cpuLoad5']}');
        debugPrint('cpuLoad15: ${data['cpuLoad15']}');
        debugPrint('memoryUsed: ${data['memoryUsed']}');
        debugPrint('memoryTotal: ${data['memoryTotal']}');
        debugPrint('diskUsed: ${data['diskUsed']}');
        debugPrint('diskTotal: ${data['diskTotal']}');
        debugPrint('uptime: ${data['uptime']}');
        debugPrint('hostname: ${data['hostname']}');
        debugPrint('ipV4Addr: ${data['ipV4Addr']}');
      } else {
        debugPrint('响应数据为空');
      }
      debugPrint('========================================\n');
    });

    test('获取当前指标 - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: getCurrentMetrics');
      debugPrint('========================================');

      final response = await api.getCurrentMetrics();
      
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('完整响应数据:\n$jsonStr');
      } else {
        debugPrint('响应数据为空');
      }
      debugPrint('========================================\n');
    });

    test('获取CPU进程列表 - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: getTopCPUProcesses');
      debugPrint('========================================');

      final response = await api.getTopCPUProcesses();
      
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('完整响应数据:\n$jsonStr');
      } else {
        debugPrint('响应数据为空');
      }
      debugPrint('========================================\n');
    });

    test('获取内存进程列表 - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: getTopMemoryProcesses');
      debugPrint('========================================');

      final response = await api.getTopMemoryProcesses();
      
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('完整响应数据:\n$jsonStr');
      } else {
        debugPrint('响应数据为空');
      }
      debugPrint('========================================\n');
    });

    test('获取当前节点信息 - 打印完整响应', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试: getCurrentNode');
      debugPrint('========================================');

      final response = await api.getCurrentNode();
      
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('响应数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('完整响应数据:\n$jsonStr');
      } else {
        debugPrint('响应数据为空');
      }
      debugPrint('========================================\n');
    });
  });
}
