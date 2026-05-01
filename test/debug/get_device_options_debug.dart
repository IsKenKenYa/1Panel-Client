import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 测试获取网络接口和IO设备列表
/// 
/// 运行方式:
/// ```bash
/// dart test/debug/get_device_options_debug.dart
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

  print('📡 测试获取网络接口列表');
  print('=' * 80);

  try {
    final netResponse = await dio.get('/api/v2/hosts/monitor/netoptions');
    print('✅ 请求成功!');
    print('');
    print('📊 网络接口列表:');
    print(const JsonEncoder.withIndent('  ').convert(netResponse.data));
    print('');
    
    if (netResponse.data != null && netResponse.data is Map) {
      final data = netResponse.data as Map<String, dynamic>;
      final interfaces = data['data'] as List?;
      
      if (interfaces != null && interfaces.isNotEmpty) {
        print('✅ 找到 ${interfaces.length} 个网络接口:');
        for (final iface in interfaces) {
          print('   - $iface');
        }
      } else {
        print('⚠️  网络接口列表为空');
      }
    }
  } catch (e) {
    print('❌ 获取网络接口失败:');
    print('   错误: $e');
    if (e is DioException && e.response != null) {
      print('   响应: ${e.response?.data}');
    }
  }

  print('');
  print('📡 测试获取IO设备列表');
  print('=' * 80);

  try {
    final ioResponse = await dio.get('/api/v2/hosts/monitor/iooptions');
    print('✅ 请求成功!');
    print('');
    print('📊 IO设备列表:');
    print(const JsonEncoder.withIndent('  ').convert(ioResponse.data));
    print('');
    
    if (ioResponse.data != null && ioResponse.data is Map) {
      final data = ioResponse.data as Map<String, dynamic>;
      final devices = data['data'] as List?;
      
      if (devices != null && devices.isNotEmpty) {
        print('✅ 找到 ${devices.length} 个IO设备:');
        for (final device in devices) {
          print('   - $device');
        }
      } else {
        print('⚠️  IO设备列表为空');
      }
    }
  } catch (e) {
    print('❌ 获取IO设备失败:');
    print('   错误: $e');
    if (e is DioException && e.response != null) {
      print('   响应: ${e.response?.data}');
    }
  }

  print('');
  print('=' * 80);
  print('测试完成');
}
