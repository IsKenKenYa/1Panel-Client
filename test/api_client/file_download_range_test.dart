import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/file_models.dart';

/// 测试 /files/download API 是否支持 Range 头
void main() {
  late DioClient client;
  late FileV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    await TestConfigManager.instance.initialize();
    final baseUrl = TestConfigManager.instance.getString('PANEL_BASE_URL', defaultValue: 'http://localhost:9999');
    final apiKey = TestConfigManager.instance.getString('PANEL_API_KEY');
    hasApiKey = TestEnvironment.canRunIntegrationTests &&
        apiKey.isNotEmpty &&
        apiKey != 'your_api_key_here';

    if (hasApiKey) {
      client = DioClient(
        baseUrl: baseUrl,
        apiKey: apiKey,
      );
      api = FileV2Api(client);
    }
  });

  group('文件下载 API Range 头支持测试', () {
    test('配置验证 - API密钥已配置', () {
      final baseUrl = TestConfigManager.instance.getString('PANEL_BASE_URL', defaultValue: 'http://localhost:9999');
      debugPrint('\n========================================');
      debugPrint('文件下载 API Range 头测试配置');
      debugPrint('========================================');
      debugPrint('服务器地址: $baseUrl');
      debugPrint('API密钥: ${hasApiKey ? "已配置" : "未配置"}');
      debugPrint('========================================\n');

      expect(
        hasApiKey,
        equals(
          TestEnvironment.canRunIntegrationTests,
        ),
      );
    });

    test('获取测试文件列表', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      // 尝试多个目录查找文件
      final pathsToTry = ['/', '/home', '/root', '/var', '/tmp', '/opt'];
      List<FileInfo>? files;
      String? foundPath;

      for (final path in pathsToTry) {
        try {
          final request = FileSearch(path: path);
          final response = await api.getFiles(request);
          if (response.statusCode == 200 && response.data != null && response.data!.isNotEmpty) {
            final nonDirs = response.data!.where((f) => !f.isDir && f.size > 0).toList();
            if (nonDirs.isNotEmpty) {
              files = response.data;
              foundPath = path;
              break;
            }
          }
        } catch (e) {
          // 继续尝试下一个目录
        }
      }

      if (files == null || foundPath == null) {
        debugPrint('⚠️  跳过测试: 没有找到包含文件的目录');
        return;
      }

      expect(files, isNotNull);
      expect(files, isA<List<FileInfo>>());

      debugPrint('\n========================================');
      debugPrint('✅ 获取文件列表成功');
      debugPrint('========================================');
      debugPrint('目录: $foundPath');
      debugPrint('文件数量: ${files.length}');

      // 找一个文件用于测试
      final nonDirFiles = files.where((f) => !f.isDir && f.size > 0 && f.size < 100 * 1024 * 1024).toList();
      if (nonDirFiles.isNotEmpty) {
        final testFile = nonDirFiles.first;
        debugPrint('\n测试文件: ${testFile.name}');
        debugPrint('文件大小: ${testFile.size} bytes');
        debugPrint('文件路径: ${testFile.path}');
      }
      debugPrint('========================================\n');
    });

    test('测试 Range 头请求 - 前1024字节', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      // 尝试多个目录查找文件
      final pathsToTry = ['/', '/home', '/root', '/var', '/tmp', '/opt'];
      FileInfo? testFile;

      for (final path in pathsToTry) {
        try {
          final request = FileSearch(path: path);
          final response = await api.getFiles(request);
          if (response.statusCode == 200 && response.data != null) {
            final files = response.data!.where((f) => !f.isDir && f.size > 1024).toList();
            if (files.isNotEmpty) {
              testFile = files.first;
              break;
            }
          }
        } catch (e) {
          // 继续尝试下一个目录
        }
      }

      if (testFile == null) {
        debugPrint('⚠️  跳过测试: 没有找到合适的测试文件');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试 Range 头请求');
      debugPrint('========================================');
      debugPrint('测试文件: ${testFile.name}');
      debugPrint('文件大小: ${testFile.size} bytes');

      // 使用 Dio 直接发送带 Range 头的请求
      final dio = client.dio;

      try {
        final response = await dio.get(
          '/files/download',
          queryParameters: {'path': testFile.path},
          options: Options(
            headers: {
              'Range': 'bytes=0-1023',
            },
            responseType: ResponseType.bytes,
          ),
        );

        debugPrint('响应状态码: ${response.statusCode}');
        debugPrint('响应头: ${response.headers.map}');

        // 检查是否支持 Range
        if (response.statusCode == 206) {
          debugPrint('✅ 服务器支持 Range 头，返回 206 Partial Content');
          
          // 检查 Content-Range 头
          final contentRange = response.headers.value('content-range');
          if (contentRange != null) {
            debugPrint('Content-Range: $contentRange');
          }
          
          // 检查 Accept-Ranges 头
          final acceptRanges = response.headers.value('accept-ranges');
          if (acceptRanges != null) {
            debugPrint('Accept-Ranges: $acceptRanges');
          }
          
          // 检查返回的数据大小
          final data = response.data as List<int>;
          debugPrint('返回数据大小: ${data.length} bytes');
          
          expect(data.length, lessThanOrEqualTo(1024));
        } else if (response.statusCode == 200) {
          debugPrint('⚠️  服务器返回 200，可能不支持 Range 头');
          debugPrint('服务器可能忽略了 Range 头，返回完整文件');
        } else {
          debugPrint('❌ 意外的状态码: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ 请求失败: $e');
        if (e is DioException) {
          debugPrint('响应状态码: ${e.response?.statusCode}');
          debugPrint('响应数据: ${e.response?.data}');
        }
      }

      debugPrint('========================================\n');
    });

    test('测试 Range 头请求 - 从文件末尾开始（416 场景）', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      // 尝试多个目录查找文件
      final pathsToTry = ['/', '/home', '/root', '/var', '/tmp', '/opt'];
      FileInfo? testFile;

      for (final path in pathsToTry) {
        try {
          final request = FileSearch(path: path);
          final response = await api.getFiles(request);
          if (response.statusCode == 200 && response.data != null) {
            final files = response.data!.where((f) => !f.isDir && f.size > 0).toList();
            if (files.isNotEmpty) {
              testFile = files.first;
              break;
            }
          }
        } catch (e) {
          // 继续尝试下一个目录
        }
      }

      if (testFile == null) {
        debugPrint('⚠️  跳过测试: 没有找到合适的测试文件');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('测试 Range 头请求 - 从文件末尾开始（416 场景）');
      debugPrint('========================================');
      debugPrint('测试文件: ${testFile.name}');
      debugPrint('文件大小: ${testFile.size} bytes');

      final dio = client.dio;

      try {
        // 请求从文件末尾开始（这是日志中导致 416 的场景）
        final response = await dio.get(
          '/files/download',
          queryParameters: {'path': testFile.path},
          options: Options(
            headers: {
              'Range': 'bytes=${testFile.size}-',
            },
            responseType: ResponseType.bytes,
          ),
        );

        debugPrint('响应状态码: ${response.statusCode}');
        debugPrint('⚠️  预期返回 416，但返回 ${response.statusCode}');
      } catch (e) {
        if (e is DioException) {
          debugPrint('响应状态码: ${e.response?.statusCode}');
          if (e.response?.statusCode == 416) {
            debugPrint('✅ 服务器正确返回 416 Range Not Satisfiable');
            debugPrint('这是日志中出现的错误场景：文件已完全下载，flutter_downloader 尝试断点续传');
          } else {
            debugPrint('❌ 意外的错误: ${e.message}');
          }
        } else {
          debugPrint('❌ 请求失败: $e');
        }
      }

      debugPrint('========================================\n');
    });

    test('结论 - API Range 头支持情况', () {
      debugPrint('\n========================================');
      debugPrint('测试结论');
      debugPrint('========================================');
      debugPrint('根据 1Panel 源码分析:');
      debugPrint('/files/download API 使用 http.ServeContent');
      debugPrint('Go 标准库 http.ServeContent 自动支持 Range 头');
      debugPrint('');
      debugPrint('预期行为:');
      debugPrint('1. Range 请求有效范围 -> 返回 206 Partial Content');
      debugPrint('2. Range 请求超出范围 -> 返回 416 Range Not Satisfiable');
      debugPrint('3. 无 Range 头 -> 返回 200 OK (完整文件)');
      debugPrint('');
      debugPrint('日志分析:');
      debugPrint('日志显示 Range: bytes=123998417- 返回 416');
      debugPrint('这是因为文件已完全下载（123998417 bytes）');
      debugPrint('flutter_downloader 尝试从文件末尾续传，服务器返回 416');
      debugPrint('');
      debugPrint('解决方案:');
      debugPrint('方案1: 下载前删除已存在的文件（当前实现）');
      debugPrint('方案2: 使用外部存储目录，让用户可以直接访问文件');
      debugPrint('========================================\n');
    });
  });
}
