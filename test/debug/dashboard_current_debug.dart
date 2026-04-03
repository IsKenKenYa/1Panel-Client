import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 测试Dashboard Current API
/// 
/// 运行方式:
/// ```bash
/// dart test/debug/dashboard_current_debug.dart
/// ```
void main() async {
  // 从.env文件读取配置
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ 错误: .env文件不存在');
    exit(1);
  }

  final envContent = await envFile.readAsString();
  final envLines = envContent.split('\n');
  
  String baseUrl = '';
  String apiKey = '';
  
  for (final line in envLines) {
    if (line.startsWith('PANEL_BASE_URL=')) {
      baseUrl = line.substring('PANEL_BASE_URL='.length).trim();
    } else if (line.startsWith('PANEL_API_KEY=')) {
      apiKey = line.substring('PANEL_API_KEY='.length).trim();
    }
  }

  if (baseUrl.isEmpty || apiKey.isEmpty) {
    print('❌ 错误: 请在.env文件中配置PANEL_BASE_URL和PANEL_API_KEY');
    exit(1);
  }

  if (baseUrl.isEmpty || apiKey.isEmpty) {
    print('❌ 错误: 请在.env文件中配置PANEL_BASE_URL和PANEL_API_KEY');
    exit(1);
  }

  print('🔧 配置信息:');
  print('   Base URL: $baseUrl');
  print('   API Key: ${apiKey.substring(0, 8)}...');
  print('');

  // 创建Dio客户端
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 添加拦截器生成Token
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final token = md5
          .convert(utf8.encode('1panel$apiKey$timestamp'))
          .toString();

      options.headers['1Panel-Token'] = token;
      options.headers['1Panel-Timestamp'] = timestamp.toString();

      return handler.next(options);
    },
  ));

  print('📡 测试 Dashboard Current API');
  print('=' * 60);

  try {
    final response = await dio.get('/api/v2/dashboard/current/default/default');

    print('✅ 请求成功!');
    print('');
    print('📊 响应数据:');
    print(const JsonEncoder.withIndent('  ').convert(response.data));
    print('');

    // 解析数据
    if (response.data != null && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>?;

      if (payload != null) {
        print('📈 解析结果:');
        print('   CPU: ${payload['cpuUsedPercent']}%');
        print('   内存: ${payload['memoryUsedPercent']}%');
        
        // 解析磁盘数据
        final diskDataList = payload['diskData'] as List?;
        if (diskDataList != null && diskDataList.isNotEmpty) {
          final firstDisk = diskDataList.first as Map<String, dynamic>?;
          print('   磁盘: ${firstDisk?['usedPercent']}%');
        } else {
          print('   磁盘: null (diskData为空)');
        }
        
        print('   负载1: ${payload['load1']}');
        print('   负载5: ${payload['load5']}');
        print('   负载15: ${payload['load15']}');
        print('   内存已用: ${payload['memoryUsed']} bytes');
        print('   内存总量: ${payload['memoryTotal']} bytes');
        print('   运行时间: ${payload['uptime']} seconds');
        print('');
        
        // 检查IO数据
        print('IO数据:');
        print('   ioReadBytes: ${payload['ioReadBytes']}');
        print('   ioWriteBytes: ${payload['ioWriteBytes']}');
        print('   ioCount: ${payload['ioCount']}');
        print('   ioReadTime: ${payload['ioReadTime']}');
        print('   ioWriteTime: ${payload['ioWriteTime']}');
        print('');
        
        // 检查网络数据
        print('网络数据:');
        print('   netBytesSent: ${payload['netBytesSent']}');
        print('   netBytesRecv: ${payload['netBytesRecv']}');
        print('');

        // 检查是否有null值
        double? diskPercent;
        if (diskDataList != null && diskDataList.isNotEmpty) {
          final firstDisk = diskDataList.first as Map<String, dynamic>?;
          diskPercent = (firstDisk?['usedPercent'] as num?)?.toDouble();
        }
            
        final hasNullValues = payload['cpuUsedPercent'] == null ||
            payload['memoryUsedPercent'] == null ||
            diskPercent == null ||
            payload['load1'] == null;

        if (hasNullValues) {
          print('⚠️  警告: 某些字段为null，可能导致UI显示"--"');
        } else {
          print('✅ 所有关键字段都有值');
        }
        
        // 检查IO和网络数据是否都为0
        final ioAllZero = payload['ioReadBytes'] == 0 && 
                         payload['ioWriteBytes'] == 0;
        final networkAllZero = payload['netBytesSent'] == 0 && 
                              payload['netBytesRecv'] == 0;
        
        if (ioAllZero) {
          print('⚠️  IO数据全为0，可能未启用IO监控');
        }
        if (networkAllZero) {
          print('⚠️  网络数据全为0，可能未启用网络监控');
        }
      } else {
        print('❌ 错误: data字段为null');
      }
    } else {
      print('❌ 错误: 响应数据格式不正确');
    }
  } catch (e, stackTrace) {
    print('❌ 请求失败:');
    print('   错误: $e');
    print('');
    print('堆栈跟踪:');
    print(stackTrace);
  }

  print('');
  print('=' * 60);
  print('测试完成');
}
