import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/app_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import '../core/test_config_manager.dart';

/// 调试脚本：获取应用详情的真实返回体
/// 
/// 用途：
/// 1. 查看服务端实际返回的数据结构
/// 2. 分析 docker-compose.yml 获取失败的原因
/// 3. 记录契约偏差
void main() {
  late AppV2Api api;
  late TestConfigManager config;

  setUpAll(() async {
    config = TestConfigManager();
    await config.initialize();

    if (!config.hasApiKey) {
      print('⚠️  未配置 API Key，跳过测试');
      return;
    }

    final client = DioClient(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      allowInsecureTls: true,
    );
    api = AppV2Api(client);
  });

  test('Debug: Get App Detail - 查看真实返回体', () async {
    if (!config.hasApiKey) {
      print('⚠️  未配置 API Key，跳过测试');
      return;
    }

    try {
      // 测试参数：从日志中看到的请求
      // GET /api/v2/apps/detail/135/latest/runtime
      final appId = '135';
      final version = 'latest';
      final type = 'runtime';

      print('\n📋 请求参数:');
      print('   appId: $appId');
      print('   version: $version');
      print('   type: $type');
      print('   URL: /api/v2/apps/detail/$appId/$version/$type');

      final detail = await api.getAppDetail(appId, version, type);

      print('\n✅ 请求成功！');
      print('\n📦 返回数据:');
      print('   ID: ${detail.id}');
      print('   Name: ${detail.name}');
      print('   Key: ${detail.key}');
      print('   Type: ${detail.type}');
      print('   Version: ${detail.versions?.join(", ")}');
      print('   DownloadUrl: ${detail.downloadUrl ?? "(null)"}');
      print('   DockerCompose: ${detail.dockerCompose != null ? "(${detail.dockerCompose!.length} chars)" : "(null)"}');

      print('\n📄 完整 JSON:');
      print(detail.toJson());
    } catch (e) {
      print('\n❌ 请求失败:');
      print('   错误类型: ${e.runtimeType}');
      print('   错误信息: $e');

      // 尝试提取更多信息
      if (e.toString().contains('docker-compose.yml')) {
        print('\n🔍 分析:');
        print('   这是 docker-compose.yml 获取失败的错误');
        print('   可能原因:');
        print('   1. 应用的 DownloadUrl 字段为空');
        print('   2. 应用的 DockerCompose 字段为空');
        print('   3. 服务端尝试构造 URL 时失败');
      }

      if (e.toString().contains('unexpected end of JSON input')) {
        print('\n🔍 分析:');
        print('   这是 JSON 解析失败的错误');
        print('   可能原因:');
        print('   1. 服务端返回的 docker-compose.yml 内容不是有效的 JSON');
        print('   2. 服务端在解析 docker-compose.yml 时出错');
      }

      rethrow;
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('Debug: List Apps - 查看应用列表', () async {
    if (!config.hasApiKey) {
      print('⚠️  未配置 API Key，跳过测试');
      return;
    }

    try {
      final apps = await api.searchApps(
        AppSearchRequest(
          page: 1,
          pageSize: 10,
          type: 'runtime',
        ),
      );

      print('\n✅ 获取应用列表成功！');
      print('   总数: ${apps.total}');
      print('   当前页: ${apps.items.length} 个应用');

      for (var app in apps.items) {
        print('\n📦 应用: ${app.name}');
        print('   ID: ${app.id}');
        print('   Key: ${app.key}');
        print('   Type: ${app.type}');
        print('   Versions: ${app.versions?.join(", ")}');
      }
    } catch (e) {
      print('\n❌ 请求失败: $e');
      rethrow;
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
