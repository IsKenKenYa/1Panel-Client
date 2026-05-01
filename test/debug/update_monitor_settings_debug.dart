import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 测试更新Monitor Settings
/// 
/// 运行方式:
/// ```bash
/// dart test/debug/update_monitor_settings_debug.dart
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

  print('📡 步骤1: 获取当前设置');
  print('=' * 80);

  try {
    final getResponse = await dio.get('/api/v2/hosts/monitor/setting');
    print('✅ 获取成功!');
    print(const JsonEncoder.withIndent('  ').convert(getResponse.data));
    print('');
    
    print('📡 步骤2: 更新DefaultIO设置为 /dev/vda2');
    print('=' * 80);
    
    final updateIOResponse = await dio.post(
      '/api/v2/hosts/monitor/setting/update',
      data: {
        'key': 'DefaultIO',
        'value': '/dev/vda2',
      },
    );
    
    print('✅ 更新IO设置成功!');
    print(const JsonEncoder.withIndent('  ').convert(updateIOResponse.data));
    print('');
    
    print('📡 步骤3: 更新DefaultNetwork设置为 eth0');
    print('=' * 80);
    
    final updateNetworkResponse = await dio.post(
      '/api/v2/hosts/monitor/setting/update',
      data: {
        'key': 'DefaultNetwork',
        'value': 'eth0',
      },
    );
    
    print('✅ 更新网络设置成功!');
    print(const JsonEncoder.withIndent('  ').convert(updateNetworkResponse.data));
    print('');
    
    print('📡 步骤4: 验证设置已更新');
    print('=' * 80);
    
    final verifyResponse = await dio.get('/api/v2/hosts/monitor/setting');
    print('✅ 验证成功!');
    print(const JsonEncoder.withIndent('  ').convert(verifyResponse.data));
    print('');
    
    final verifyData = verifyResponse.data as Map<String, dynamic>;
    final verifySettings = verifyData['data'] as Map<String, dynamic>;
    
    print('📈 更新后的设置:');
    print('   DefaultIO: ${verifySettings['defaultIO']}');
    print('   DefaultNetwork: ${verifySettings['defaultNetwork']}');
    print('');
    
    if (verifySettings['defaultIO'] == '/dev/vda2') {
      print('✅ IO设置已更新');
    } else {
      print('⚠️  IO设置未更新');
    }
    
    if (verifySettings['defaultNetwork'] == 'eth0') {
      print('✅ 网络设置已更新');
    } else {
      print('⚠️  网络设置未更新');
    }
    
    print('');
    print('💡 提示: 设置更新后，需要等待几分钟让1Panel采集新数据');
    print('   然后重新查询Monitor API应该能看到IO和网络的历史数据');
    
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
