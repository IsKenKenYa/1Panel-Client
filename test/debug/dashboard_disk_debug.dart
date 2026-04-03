import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

/// 调试脚本：测试Dashboard Base API的真实返回数据
/// 用于诊断磁盘信息显示"--"的问题
void main() async {
  // 从.env文件读取配置
  final envFile = File('.env');
  final envVars = <String, String>{};
  
  if (await envFile.exists()) {
    final lines = await envFile.readAsLines();
    for (final line in lines) {
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        envVars[key] = value;
      }
    }
  }

  final baseUrl = envVars['PANEL_BASE_URL'] ?? '';
  final apiKey = envVars['PANEL_API_KEY'] ?? '';

  if (baseUrl.isEmpty || apiKey.isEmpty) {
    print('❌ 错误: 请在.env文件中配置PANEL_BASE_URL和PANEL_API_KEY');
    exit(1);
  }

  print('========================================');
  print('Dashboard Disk 数据调试');
  print('========================================');
  print('服务器: $baseUrl');
  print('API Key: ${apiKey.substring(0, 8)}...');
  print('');

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // 生成认证头
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final token = md5.convert(utf8.encode('1panel$apiKey$timestamp')).toString();

  final headers = {
    '1Panel-Token': token,
    '1Panel-Timestamp': timestamp.toString(),
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  try {
    print('📡 请求: GET /api/v2/dashboard/base/default/default');
    print('');

    final response = await dio.get(
      '/api/v2/dashboard/base/default/default',
      options: Options(headers: headers),
    );

    print('✅ 响应状态: ${response.statusCode}');
    print('');
    print('========================================');
    print('完整响应数据:');
    print('========================================');
    
    final prettyJson = const JsonEncoder.withIndent('  ').convert(response.data);
    print(prettyJson);
    print('');

    // 分析数据结构
    print('========================================');
    print('数据结构分析:');
    print('========================================');

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      print('❌ 响应数据为空');
      return;
    }

    // 检查顶层字段
    print('\n📋 顶层字段:');
    data.keys.forEach((key) {
      final value = data[key];
      final type = value.runtimeType;
      print('  - $key: $type');
    });

    // 获取实际的data字段
    final actualData = data['data'] as Map<String, dynamic>?;
    if (actualData == null) {
      print('\n❌ data 字段不存在');
      return;
    }

    print('\n📋 data 字段内容:');
    actualData.keys.forEach((key) {
      final value = actualData[key];
      final type = value.runtimeType;
      print('  - $key: $type');
    });

    // 检查 currentInfo
    print('\n📋 currentInfo 字段:');
    final currentInfo = actualData['currentInfo'] as Map<String, dynamic>?;
    if (currentInfo != null) {
      currentInfo.keys.forEach((key) {
        final value = currentInfo[key];
        final type = value.runtimeType;
        print('  - $key: $type');
      });

      // 重点检查 diskData
      print('\n🔍 diskData 详细信息:');
      final diskData = currentInfo['diskData'];
      if (diskData == null) {
        print('  ❌ diskData 字段不存在');
      } else if (diskData is! List) {
        print('  ❌ diskData 不是数组类型: ${diskData.runtimeType}');
      } else if (diskData.isEmpty) {
        print('  ⚠️  diskData 是空数组');
      } else {
        print('  ✅ diskData 包含 ${diskData.length} 个磁盘');
        for (var i = 0; i < diskData.length; i++) {
          final disk = diskData[i] as Map<String, dynamic>;
          print('\n  磁盘 #${i + 1}:');
          print('    - device: ${disk['device']}');
          print('    - path: ${disk['path']}');
          print('    - type: ${disk['type']}');
          print('    - total: ${disk['total']} bytes (${_formatBytes(disk['total'] as int?)})');
          print('    - used: ${disk['used']} bytes (${_formatBytes(disk['used'] as int?)})');
          print('    - free: ${disk['free']} bytes (${_formatBytes(disk['free'] as int?)})');
          print('    - usedPercent: ${disk['usedPercent']}%');
        }
      }

      // 检查其他关键指标
      print('\n📊 其他关键指标:');
      print('  - cpuUsedPercent: ${currentInfo['cpuUsedPercent']}');
      print('  - memoryUsedPercent: ${currentInfo['memoryUsedPercent']}');
      print('  - memoryTotal: ${_formatBytes(currentInfo['memoryTotal'] as int?)}');
      print('  - memoryUsed: ${_formatBytes(currentInfo['memoryUsed'] as int?)}');
    } else {
      print('  ❌ currentInfo 字段不存在');
    }

    // 诊断建议
    print('\n========================================');
    print('诊断结果:');
    print('========================================');

    if (currentInfo == null) {
      print('❌ 问题: currentInfo 字段缺失');
      print('   建议: 检查API版本或服务器配置');
    } else {
      final diskData = currentInfo['diskData'];
      if (diskData == null) {
        print('❌ 问题: diskData 字段缺失');
        print('   建议: 服务器可能未返回磁盘数据');
      } else if (diskData is! List) {
        print('❌ 问题: diskData 类型错误');
        print('   实际类型: ${diskData.runtimeType}');
        print('   期望类型: List');
      } else if (diskData.isEmpty) {
        print('⚠️  问题: diskData 为空数组');
        print('   建议: 服务器可能没有可用的磁盘信息');
      } else {
        print('✅ diskData 数据正常');
        print('   磁盘数量: ${diskData.length}');
        print('   代码应该能正确显示磁盘信息');
        print('');
        print('🔍 如果UI仍显示"--"，请检查:');
        print('   1. dashboard_service.dart 中的数据解析逻辑');
        print('   2. ServerDetailHeaderCard 组件的渲染逻辑');
        print('   3. 数据是否正确传递到UI层');
      }
    }
  } catch (e) {
    print('❌ 请求失败: $e');
    if (e is DioException) {
      print('   状态码: ${e.response?.statusCode}');
      print('   响应数据: ${e.response?.data}');
    }
  }
}

String _formatBytes(int? bytes) {
  if (bytes == null) return '--';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
