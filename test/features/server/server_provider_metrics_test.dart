import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/server_repository.dart';

/// 记录每次指标请求的服务器 id，并按 id 返回各自快照。
class _RecordingServerRepository extends ServerRepository {
  _RecordingServerRepository({
    required this.cards,
    required this.metricsByServer,
  });

  final List<ServerCardViewModel> cards;
  final Map<String, ServerMetricsSnapshot> metricsByServer;
  final List<String> requestedIds = <String>[];

  @override
  Future<List<ServerCardViewModel>> loadServerCards() async => cards;

  @override
  Future<ServerMetricsSnapshot> loadMetricsForConfig(ApiConfig config) async {
    final serverId = config.id;
    requestedIds.add(serverId);
    return metricsByServer[serverId] ?? const ServerMetricsSnapshot();
  }
}

ServerCardViewModel _card(String id, String name) {
  return ServerCardViewModel(
    config: ApiConfig(
      id: id,
      name: name,
      url: 'http://$id.example.com:26314',
      apiKey: 'key-$id',
    ),
    isCurrent: false,
    metrics: const ServerMetricsSnapshot(),
  );
}

void main() {
  group('ServerProvider 服务器列表指标', () {
    test('切换选择只替换相关卡片，目录顺序和其余卡片可复用', () {
      final provider = ServerProvider();
      addTearDown(provider.dispose);
      final configs = [
        for (final id in ['a', 'b', 'c']) _card(id, id).config
      ];
      provider.syncDirectory(configs, 'a');
      final previous = provider.configs;
      final unaffected = provider.cardFor('c');

      provider.syncDirectory(configs, 'b');
      expect(provider.configs, same(previous));
      expect(provider.cardFor('a')!.isCurrent, isFalse);
      expect(provider.cardFor('b')!.isCurrent, isTrue);
      expect(provider.cardFor('c'), same(unaffected));
    });

    test('同一配置共用进行中的刷新，旧配置的排队工作不会更新新卡片', () async {
      final provider = ServerProvider();
      addTearDown(provider.dispose);
      final old = ApiConfig(
          id: 'a',
          name: 'A',
          url: '',
          apiKey: '',
          panelType: 'unregistered',
          revision: '1');
      final next = ApiConfig.fromJson({...old.toJson(), 'revision': '2'});
      provider.syncDirectory([old], 'a');
      final batch = provider.loadMetrics();
      expect(provider.loadMetrics(), same(batch));
      final first = provider.loadMetricsFor('a');
      expect(provider.loadMetricsFor('a'), same(first));
      provider.syncDirectory([next], 'a');
      final second = provider.loadMetricsFor('a');
      expect(second, isNot(same(first)));
      await Future.wait([batch, first, second]);
      expect(provider.cardFor('a')!.config, same(next));
      expect(provider.isLoadingMetrics, isFalse);
    });

    test('每张卡片绑定自己服务器的指标，离线服务器保持未加载', () async {
      // 回归：loadServerMetrics 曾用当前服务器 client 取数，
      // 列表全部卡片显示同一份指标，离线服务器也显示「已加载」。
      final repository = _RecordingServerRepository(
        cards: [_card('online', '在线服务器'), _card('offline', '离线服务器')],
        metricsByServer: {
          'online': const ServerMetricsSnapshot(
            cpuPercent: 21.3,
            memoryPercent: 49.1,
            diskPercent: 73.4,
            load: 0.42,
          ),
        },
      );
      final provider = ServerProvider(repository: repository);
      addTearDown(provider.dispose);

      await provider.load();
      await provider.loadMetrics();

      expect(repository.requestedIds.toSet(), {'online', 'offline'});
      final byId = {
        for (final server in provider.servers) server.config.id: server.metrics,
      };
      expect(byId['online']!.cpuPercent, 21.3);
      expect(byId['online']!.load, 0.42);
      expect(byId['offline']!.cpuPercent, isNull);
      expect(byId['offline']!.memoryPercent, isNull);
      expect(byId['offline']!.load, isNull);
    });

    test('重复刷新保留各自服务器的指标值', () async {
      final repository = _RecordingServerRepository(
        cards: [_card('a', 'A'), _card('b', 'B')],
        metricsByServer: {
          'a': const ServerMetricsSnapshot(cpuPercent: 10),
          'b': const ServerMetricsSnapshot(cpuPercent: 90),
        },
      );
      final provider = ServerProvider(repository: repository);
      addTearDown(provider.dispose);

      await provider.load();
      await provider.loadMetrics();
      await provider.loadMetrics();

      expect(
        provider.servers.map((s) => s.metrics.cpuPercent).toList(),
        [10, 90],
      );
    });
  });
}
