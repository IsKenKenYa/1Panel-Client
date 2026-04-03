import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 测试Monitor API的IO和Network数据
/// 
/// 运行方式:
/// ```bash
/// dart test/debug/monitor_io_network_debug.dart
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

  final now = DateTime.now();
  final startTime = now.subtract(const Duration(hours: 1));

  print('📡 测试 Monitor API - 获取IO和Network数据');
  print('=' * 80);
  print('时间范围: ${startTime.toIso8601String()} -> ${now.toIso8601String()}');
  print('');

  try {
    final response = await dio.post(
      '/api/v2/hosts/monitor/search',
      data: {
        'param': 'all',
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
      },
    );

    print('✅ 请求成功!');
    print('');

    if (response.data != null && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final dataList = data['data'] as List?;

      if (dataList != null) {
        print('📊 返回的param类型:');
        for (final item in dataList) {
          if (item is Map<String, dynamic>) {
            final param = item['param'] as String?;
            final values = item['value'] as List?;
            print('   - $param: ${values?.length ?? 0} 个数据点');
          }
        }
        print('');

        // 查找IO数据
        print('🔍 检查IO数据:');
        print('-' * 80);
        final ioItem = dataList.firstWhere(
          (e) => (e as Map)['param'] == 'io',
          orElse: () => null,
        );

        if (ioItem != null) {
          final ioMap = ioItem as Map<String, dynamic>;
          final ioValues = ioMap['value'] as List?;
          print('✅ 找到IO数据，共 ${ioValues?.length ?? 0} 个数据点');
          
          if (ioValues != null && ioValues.isNotEmpty) {
            print('');
            print('第一个数据点的字段:');
            final firstValue = ioValues.first as Map<String, dynamic>;
            for (final key in firstValue.keys) {
              print('   - $key: ${firstValue[key]}');
            }
            
            print('');
            print('最后一个数据点的字段:');
            final lastValue = ioValues.last as Map<String, dynamic>;
            for (final key in lastValue.keys) {
              print('   - $key: ${lastValue[key]}');
            }
          } else {
            print('⚠️  IO数据为空');
          }
        } else {
          print('❌ 未找到IO数据 (param=io)');
        }

        print('');
        print('🔍 检查Network数据:');
        print('-' * 80);
        final networkItem = dataList.firstWhere(
          (e) => (e as Map)['param'] == 'network',
          orElse: () => null,
        );

        if (networkItem != null) {
          final networkMap = networkItem as Map<String, dynamic>;
          final networkValues = networkMap['value'] as List?;
          print('✅ 找到Network数据，共 ${networkValues?.length ?? 0} 个数据点');
          
          if (networkValues != null && networkValues.isNotEmpty) {
            print('');
            print('第一个数据点的字段:');
            final firstValue = networkValues.first as Map<String, dynamic>;
            for (final key in firstValue.keys) {
              print('   - $key: ${firstValue[key]}');
            }
            
            print('');
            print('最后一个数据点的字段:');
            final lastValue = networkValues.last as Map<String, dynamic>;
            for (final key in lastValue.keys) {
              print('   - $key: ${lastValue[key]}');
            }
          } else {
            print('⚠️  Network数据为空');
          }
        } else {
          print('❌ 未找到Network数据 (param=network)');
        }

        // 检查base数据中是否包含IO和网络字段
        print('');
        print('🔍 检查Base数据中的IO和Network字段:');
        print('-' * 80);
        final baseItem = dataList.firstWhere(
          (e) => (e as Map)['param'] == 'base',
          orElse: () => null,
        );

        if (baseItem != null) {
          final baseMap = baseItem as Map<String, dynamic>;
          final baseValues = baseMap['value'] as List?;
          print('✅ 找到Base数据，共 ${baseValues?.length ?? 0} 个数据点');
          
          if (baseValues != null && baseValues.isNotEmpty) {
            print('');
            print('第一个数据点的所有字段:');
            final firstValue = baseValues.first as Map<String, dynamic>;
            for (final key in firstValue.keys) {
              final value = firstValue[key];
              if (value is num) {
                print('   - $key: $value');
              } else {
                print('   - $key: ${value.runtimeType}');
              }
            }
            
            // 检查是否有IO相关字段
            print('');
            print('IO相关字段:');
            final ioFields = ['disk', 'diskRead', 'diskWrite', 'ioRead', 'ioWrite', 
                             'ioReadBytes', 'ioWriteBytes', 'ioCount'];
            for (final field in ioFields) {
              if (firstValue.containsKey(field)) {
                print('   ✅ $field: ${firstValue[field]}');
              }
            }
            
            // 检查是否有网络相关字段
            print('');
            print('网络相关字段:');
            final networkFields = ['networkIn', 'networkOut', 'up', 'down',
                                  'netBytesSent', 'netBytesRecv'];
            for (final field in networkFields) {
              if (firstValue.containsKey(field)) {
                print('   ✅ $field: ${firstValue[field]}');
              }
            }
          }
        } else {
          print('❌ 未找到Base数据');
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
  print('=' * 80);
  print('测试完成');
}
