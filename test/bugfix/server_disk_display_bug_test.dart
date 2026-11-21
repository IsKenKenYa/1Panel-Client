import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:onepanel_client/data/panels/one_panel_adapter.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/panels/panel_registry.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/server_repository.dart';

import '../core/test_config_manager.dart';

Future<void> main() async {
  await TestEnvironment.initialize();
  final hasPanelUrl =
      TestEnvironment.config.getString('PANEL_BASE_URL').trim().isNotEmpty;
  final skipReason = TestEnvironment.skipLiveApi() ??
      TestEnvironment.skipNoApiKey() ??
      (hasPanelUrl ? null : '请配置 PANEL_BASE_URL');

  test(
    '列表和详情共用 1Panel 指标与健康请求，较早的配置结果不会更新新卡片',
    () async {
      final previousLevel = Logger.level;
      Logger.level = Level.off;
      addTearDown(() => Logger.level = previousLevel);

      final source = TestEnvironment.apiConfig;
      final saved = ApiConfig.fromJson({...source.toJson(), 'revision': '1'},
          apiKey: source.apiKey);
      final metadata = ApiConfig.fromJson(saved.toJson());
      final registry = PanelRegistry([const OnePanelAdapter()]);
      addTearDown(registry.clear);
      final session = registry.sessionFor(saved) as OnePanelSession;
      final requests = <String>[];
      final nextRead = Completer<void>();
      session.client.dio.interceptors
          .add(InterceptorsWrapper(onRequest: (options, handler) {
        requests.add(options.path);
        if (requests.length == 3) nextRead.complete();
        handler.next(options);
      }));
      final provider =
          ServerProvider(repository: ServerRepository(registry: registry));
      addTearDown(provider.dispose);
      provider.syncDirectory([metadata], metadata.id);
      await Future.wait(
          [provider.loadMetrics(), provider.loadMetricsFor(metadata.id)]);
      expect(
          requests,
          unorderedEquals([
            '/api/v2/health/check',
            '/api/v2/dashboard/current/default/default'
          ]));
      final metrics = provider.cardFor(metadata.id)!.metrics;
      expect(metrics.isReachable, isTrue, reason: '面板健康检查应当成功');
      expect(metrics.latencyMs, allOf(isNotNull, greaterThanOrEqualTo(0)));
      expect(metrics.diskPercent, allOf(isNotNull, inInclusiveRange(0, 100)));
      final oldRead = provider.loadMetricsFor(metadata.id);
      await nextRead.future.timeout(const Duration(seconds: 10));
      final edited =
          ApiConfig.fromJson({...metadata.toJson(), 'revision': '2'});
      provider.syncDirectory([edited], edited.id);
      await oldRead;
      expect(provider.cardFor(edited.id)!.metrics.isReachable, isNull);
    },
    skip: skipReason,
  );

  test('多连接刷新最多同时读取四台，列表隐藏后只启动可见详情的等待请求', () async {
    final source = TestEnvironment.apiConfig;
    final registry = PanelRegistry([const OnePanelAdapter()]);
    addTearDown(registry.clear);
    final provider =
        ServerProvider(repository: ServerRepository(registry: registry));
    addTearDown(provider.dispose);
    final started = <String>{};
    final active = <String>{};
    final firstFour = Completer<void>();
    var peak = 0;
    final configs = <ApiConfig>[];
    for (var i = 0; i < 6; i++) {
      // 使用独立连接访问已配置的测试面板，计数器只观察真实请求。
      final saved = ApiConfig.fromJson(
        {...source.toJson(), 'id': 'refresh-$i', 'revision': '1'},
        apiKey: source.apiKey,
      );
      final session = registry.sessionFor(saved) as OnePanelSession;
      var responses = 0;
      session.client.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          started.add(saved.id);
          active.add(saved.id);
          if (active.length > peak) peak = active.length;
          if (started.length == 4 && !firstFour.isCompleted) {
            firstFour.complete();
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (++responses == 2) active.remove(saved.id);
          handler.next(response);
        },
      ));
      configs.add(ApiConfig.fromJson(saved.toJson()));
    }
    provider.syncDirectory(configs, configs.first.id);
    final list = Object();
    final detail = Object();
    provider.setPageVisible(list, true);
    await firstFour.future.timeout(const Duration(seconds: 10));
    provider.setPageVisible(detail, true, serverId: configs.last.id);
    provider.setPageVisible(list, false);
    await Future.wait([
      for (final config in [...configs.take(4), configs.last])
        provider.loadMetricsFor(config.id),
    ]);
    provider.setPageVisible(detail, false);
    expect(peak, 4);
    expect(started, {
      for (final config in [...configs.take(4), configs.last]) config.id
    });
  }, skip: skipReason);
}
