// 容器模块端到端集成测试（真服务器联调）。
//
// 用途：验证容器列表读取、安全容器的详情/重启闭环、以及自建网络夹具的
// 创建-搜索-删除全流程。
//
// 危险面边界：
// - 列表与状态为纯读操作。
// - 重启操作只针对列表中第一个"安全容器"：名称含 `3xui` 或 `hysteria`
//   （大小写不敏感）、以及由应用商店或编排管理的容器一律排除；仅当该容器原本
//   处于 running 状态时才重启，并轮询确认其回到 running；否则只做读断言、不重启。
// - 网络夹具仅创建/删除名称带 `onepanel-e2e-net-` 前缀 + 6位随机后缀的自有网络，
//   不触碰任何现有网络/容器/卷，不调用任何面板基础配置修改接口。
import 'package:flutter_test/flutter_test.dart';
import '../test_helper.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';

Future<void> main() async {
  // 注意：真服务器集成测试禁止使用 TestWidgetsFlutterBinding（会劫持 HttpClient，
  // 所有请求返回假 400）。TestConfig.initialize() 仅读取 .env，无需绑定层。
  await TestConfig.initialize();

  late final TestApiClient apiClient;
  late final ContainerV2Api containerApi;

  final hasApiKey = SkipConditions.skipNoApiKey() == null;
  if (hasApiKey) {
    apiClient = TestApiClient(
      baseUrl: TestConfig.baseUrl,
      apiKey: TestConfig.apiKey,
    );
    containerApi = ContainerV2Api(apiClient.client);
  }

  /// 代理类/敏感容器（按名称匹配，大小写不敏感），一律排除在操作之外。
  bool isProtectedContainer(String name) {
    final lower = name.toLowerCase();
    return lower.contains('3xui') || lower.contains('hysteria');
  }

  tearDownAll(() async {
    if (hasApiKey) apiClient.dispose();
    await teardownTestEnvironment();
  });

  group('容器列表读集成测试', () {
    test(
      '应该能够搜索容器分页列表',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final response = await containerApi.searchContainers(
          const PageContainer(page: 1, pageSize: 10),
        );

        expect(response.statusCode, 200);
        expect(response.data, isA<PageResult<ContainerInfo>>());
      },
    );

    test(
      '应该能够获取容器全量列表',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final response = await containerApi.listContainers();

        expect(response.statusCode, 200);
        expect(response.data, isA<List<ContainerInfo>>());
      },
    );

    test(
      '应该能够获取容器状态统计',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final response = await containerApi.getContainerStatus();

        expect(response.statusCode, 200);
        expect(response.data, isA<ContainerStatus>());
      },
    );
  });

  group('容器安全操作集成测试', () {
    test(
      '应该能够查询安全容器详情并在running状态下重启恢复',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final listResponse = await containerApi.listContainers();
        expect(listResponse.statusCode, 200);
        final containers = listResponse.data ?? [];

        final safeContainers = containers
            .where((c) =>
                !isProtectedContainer(c.name) &&
                !c.isFromApp &&
                !c.isFromCompose)
            .toList();
        if (safeContainers.isEmpty) {
          // ignore: avoid_print
          print('[soft-skip] 未发现可安全操作的容器，跳过容器操作测试');
          return;
        }

        final target = safeContainers.first;
        // 详情读断言
        final statsResponse = await containerApi.getContainerItemStats(
          OperationWithName(name: target.name),
        );
        expect(statsResponse.statusCode, 200);
        expect(statsResponse.data, isA<ContainerItemStats>());

        // 仅对原本处于 running 状态的容器执行重启，重启后轮询确认恢复。
        if (target.state.toLowerCase() != 'running') {
          // ignore: avoid_print
          print('[soft] 容器 ${target.name} 当前状态为 ${target.state}，'
              '仅做读断言不执行重启');
          return;
        }

        final restartResponse = await containerApi.operateContainer(
          ContainerOperation(
            names: [target.name],
            operation: ContainerOperationType.restart.value,
          ),
        );
        expect(restartResponse.statusCode, 200);

        var recovered = false;
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(const Duration(seconds: 3));
          final pollResponse = await containerApi.listContainers();
          final polled = pollResponse.data
              ?.where((c) => c.name == target.name)
              .toList();
          if (polled != null &&
              polled.isNotEmpty &&
              polled.first.state.toLowerCase() == 'running') {
            recovered = true;
            break;
          }
        }
        expect(recovered, isTrue,
            reason: '容器 ${target.name} 重启后30秒内应恢复为 running');
      },
    );
  });

  group('容器网络夹具集成测试', () {
    test(
      '应该能够创建-搜索-删除测试网络',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final netName =
            'onepanel-e2e-net-${TestDataGenerator.randomString(6)}';

        Future<void> cleanup() async {
          // 主路径：deleteNetwork(BatchDelete)，需要从搜索结果提取数字 id。
          var deleted = false;
          try {
            final search = await containerApi.searchNetworks(
              const SearchWithPage(page: 1, pageSize: 100, info: ''),
            );
            final ids = <int>[];
            for (final item in search.data?.items ?? const <Map<String, dynamic>>[]) {
              if (item['name']?.toString() != netName) continue;
              final rawId = item['id'];
              final id = rawId is int
                  ? rawId
                  : int.tryParse(rawId?.toString() ?? '');
              if (id != null) ids.add(id);
            }
            if (ids.isNotEmpty) {
              final response =
                  await containerApi.deleteNetwork(BatchDelete(ids: ids));
              deleted = response.statusCode == 200;
            }
          } catch (e) {
            // ignore: avoid_print
            print('deleteNetwork(BatchDelete) 清理失败: $netName -> $e');
          }
          // 兜底路径：真实端点 /containers/network/del 期望 {names: [...]}。
          if (!deleted) {
            try {
              final response = await apiClient.authenticatedPost(
                '/api/v2/containers/network/del',
                data: <String, dynamic>{
                  'names': <String>[netName]
                },
              );
              deleted = response.statusCode == 200;
            } catch (e) {
              // ignore: avoid_print
              print('清理测试网络失败（忽略）: $netName -> $e');
            }
          }
        }

        try {
          final createResponse = await containerApi.createNetwork(
            NetworkCreate(name: netName, driver: 'bridge'),
          );
          expect(createResponse.statusCode, 200);

          final searchResponse = await containerApi.searchNetworks(
            SearchWithPage(page: 1, pageSize: 100, info: netName),
          );
          expect(searchResponse.statusCode, 200);
          final matched = searchResponse.data?.items
                  .where((item) => item['name']?.toString() == netName)
                  .toList() ??
              [];
          if (matched.isEmpty) {
            // info 过滤可能不被支持，回退到全量搜索再过滤。
            final fullSearch = await containerApi.searchNetworks(
              const SearchWithPage(page: 1, pageSize: 100),
            );
            expect(
              fullSearch.data!.items
                  .any((item) => item['name']?.toString() == netName),
              isTrue,
              reason: '创建的测试网络 $netName 应出现在搜索结果中',
            );
          } else {
            expect(matched, isNotEmpty);
          }
        } finally {
          await cleanup();
        }
      },
    );
  });
}
