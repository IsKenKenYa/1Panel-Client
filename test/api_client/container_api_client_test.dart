import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';
import 'package:onepanelapp_app/api/v2/container_v2.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';
import 'package:onepanelapp_app/data/models/common_models.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';

void main() {
  late DioClient client;
  late ContainerV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = ContainerV2Api(client);
    }
  });

  group('Container API客户端测试', () {
    test('配置验证 - API密钥已配置', () {
      debugPrint('\n========================================');
      debugPrint('Container API测试配置');
      debugPrint('========================================');
      debugPrint('服务器地址: ${TestEnvironment.baseUrl}');
      debugPrint('API密钥: ${hasApiKey ? "已配置" : "未配置"}');
      debugPrint('========================================\n');
      
      expect(hasApiKey, equals(TestEnvironment.canRunIntegrationTests));
    });

    group('getContainerStatus - 获取容器状态统计', () {
      test('应该成功获取容器状态统计', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getContainerStatus();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<ContainerStatus>());

        final status = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 容器状态统计测试成功');
        debugPrint('========================================');
        debugPrint('运行中: ${status.running}');
        debugPrint('已停止: ${status.exited}');
        debugPrint('已暂停: ${status.paused}');
        debugPrint('总数: ${status.all}');
        debugPrint('镜像数量: ${status.imageCount}');
        debugPrint('网络数量: ${status.networkCount}');
        debugPrint('卷数量: ${status.volumeCount}');
        debugPrint('Compose数量: ${status.composeCount}');
        debugPrint('========================================\n');

        TestDataValidator.expectNonNegativeInt(status.running, fieldName: 'running');
        TestDataValidator.expectNonNegativeInt(status.exited, fieldName: 'exited');
        TestDataValidator.expectNonNegativeInt(status.all, fieldName: 'all');
      });
    });

    group('searchContainers - 搜索容器列表', () {
      test('应该成功获取容器列表', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final request = PageContainer(page: 1, pageSize: 10);
        final response = await api.searchContainers(request);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<PageResult<ContainerInfo>>());

        final result = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 容器列表测试成功');
        debugPrint('========================================');
        debugPrint('总数: ${result.total}');
        debugPrint('当前页: ${result.items.length} 个容器');

        if (result.items.isNotEmpty) {
          debugPrint('\n容器列表:');
          for (var i = 0; i < (result.items.length > 5 ? 5 : result.items.length); i++) {
            final container = result.items[i];
            debugPrint('  - ${container.name} (${container.status})');
          }
        }
        debugPrint('========================================\n');
      });
    });

    group('listContainerStats - 获取容器统计列表', () {
      test('应该成功获取容器统计列表', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.listContainerStats();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<List<ContainerListStats>>());

        final stats = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 容器统计列表测试成功');
        debugPrint('========================================');
        debugPrint('统计数量: ${stats.length}');
        debugPrint('========================================\n');
      });
    });

    group('getImageOptions - 获取镜像选项', () {
      test('应该成功获取镜像选项', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getImageOptions();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<List<Map<String, dynamic>>>());

        debugPrint('\n========================================');
        debugPrint('✅ 镜像选项测试成功');
        debugPrint('========================================');
        debugPrint('选项数量: ${response.data!.length}');
        debugPrint('========================================\n');
      });
    });

    group('getAllImages - 获取所有镜像', () {
      test('应该成功获取所有镜像', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getAllImages();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<List<Map<String, dynamic>>>());

        final images = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 镜像列表测试成功');
        debugPrint('========================================');
        debugPrint('镜像数量: ${images.length}');
        if (images.isNotEmpty) {
          debugPrint('\n镜像列表:');
          for (var i = 0; i < (images.length > 5 ? 5 : images.length); i++) {
            final image = images[i];
            debugPrint('  - ${image['repoTags'] ?? image['id']}');
          }
        }
        debugPrint('========================================\n');
      });
    });

    group('getNetworkOptions - 获取网络选项', () {
      test('应该成功获取网络选项', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getNetworkOptions();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        debugPrint('\n========================================');
        debugPrint('✅ 网络选项测试成功');
        debugPrint('========================================');
        debugPrint('选项数量: ${response.data!.length}');
        debugPrint('========================================\n');
      });
    });

    group('searchNetworks - 搜索网络列表', () {
      test('应该成功获取网络列表', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final request = SearchWithPage(page: 1, pageSize: 10);
        final response = await api.searchNetworks(request);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<PageResult<Map<String, dynamic>>>());

        final result = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 网络列表测试成功');
        debugPrint('========================================');
        debugPrint('总数: ${result.total}');
        if (result.items.isNotEmpty) {
          debugPrint('网络列表:');
          for (var item in result.items) {
            debugPrint('  - ${item['name']} (${item['driver']})');
          }
        }
        debugPrint('========================================\n');
      });
    });

    group('getVolumeOptions - 获取卷选项', () {
      test('应该成功获取卷选项', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getVolumeOptions();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        debugPrint('\n========================================');
        debugPrint('✅ 卷选项测试成功');
        debugPrint('========================================');
        debugPrint('选项数量: ${response.data!.length}');
        debugPrint('========================================\n');
      });
    });

    group('searchVolumes - 搜索卷列表', () {
      test('应该成功获取卷列表', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final request = SearchWithPage(page: 1, pageSize: 10);
        final response = await api.searchVolumes(request);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<PageResult<Map<String, dynamic>>>());

        final result = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 卷列表测试成功');
        debugPrint('========================================');
        debugPrint('总数: ${result.total}');
        debugPrint('========================================\n');
      });
    });
  });

  group('Container API性能测试', () {
    test('getContainerStatus响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getContainerStatus');
      timer.start();
      await api.getContainerStatus();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });

    test('searchContainers响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('searchContainers');
      timer.start();
      await api.searchContainers(PageContainer(page: 1, pageSize: 10));
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });

    test('getAllImages响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getAllImages');
      timer.start();
      await api.getAllImages();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });
}
