import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 测试Monitor Settings API
/// 
/// 运行方式:
/// ```bash
/// dart test/debug/monitor_settings_debug.dart
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

  print('📡 测试 Monitor Settings API');
  print('=' * 80);

  try {
    final response = await dio.get('/api/v2/hosts/monitor/setting');

    print('✅ 请求成功!');
    print('');
    print('📊 当前监控设置:');
    print(const JsonEncoder.withIndent('  ').convert(response.data));
    print('');

    if (response.data != null && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>?;

      if (payload != null) {
        print('📈 解析结果:');
        print('   监控状态: ${payload['monitorStatus']}');
        print('   监控间隔: ${payload['monitorInterval']}');
        print('   保留天数: ${payload['monitorStoreDays']}');
        print('   默认IO: ${payload['defaultIO']}');
        print('   默认网络: ${payload['defaultNetwork']}');
        print('');

        // 检查IO和网络是否启用
        final ioEnabled = payload['defaultIO'] != null && 
                         payload['defaultIO'] != '' &&
                         payload['defaultIO'] != 'all';
        final networkEnabled = payload['defaultNetwork'] != null && 
                              payload['defaultNetwork'] != '' &&
                              payload['defaultNetwork'] != 'all';

        if (!ioEnabled) {
          print('⚠️  IO监控未配置或使用默认值');
          print('   建议: 设置 DefaultIO 为具体的磁盘设备（如 /dev/vda2）');
        } else {
          print('✅ IO监控已配置: ${payload['defaultIO']}');
        }

        if (!networkEnabled) {
          print('⚠️  网络监控未配置或使用默认值');
          print('   建议: 设置 DefaultNetwork 为具体的网络接口（如 eth0）');
        } else {
          print('✅ 网络监控已配置: ${payload['defaultNetwork']}');
        }
      }
    }
  } catch (e, stackTrace) {
    print('❌ 请求失败:');
    print('   错误: $e');
    print('');
    print('堆栈跟踪:');
    print(stackTrace);
  }

  print('');
  print('=' * 80);
  print('测试完成');
}
