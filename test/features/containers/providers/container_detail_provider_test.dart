import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/container_service.dart';
import 'package:onepanel_client/features/containers/providers/container_detail_provider.dart';

class MockContainerService extends Mock implements ContainerService {}

void main() {
  group('ContainerDetailProvider', () {
    late MockContainerService containerService;
    late ContainerDetailProvider provider;

    const container = ContainerInfo(
      id: 'c-1',
      name: 'mysql-demo',
      image: 'mysql:8',
      status: 'running',
      state: 'running',
    );

    /// 构造一次日志流；[follow] 为 false 时流在推送完分片后结束。
    Stream<String> logsStream(
      List<String> chunks, {
      bool follow = true,
      Object? error,
    }) async* {
      for (final chunk in chunks) {
        yield chunk;
      }
      if (error != null) {
        throw error;
      }
      if (!follow) {
        return;
      }
    }

    setUpAll(() {
      registerFallbackValue(<String>[]);
    });

    setUp(() {
      containerService = MockContainerService();
      provider = ContainerDetailProvider(
        container: container,
        service: containerService,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('loadAll populates inspect logs and stats', () async {
      when(() => containerService.inspectContainer('c-1'))
          .thenAnswer((_) async => '{}');
      when(() => containerService.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: '1000',
            follow: any(named: 'follow'),
            timestamps: any(named: 'timestamps'),
          )).thenAnswer(
        (_) => logsStream(<String>['line-1'], follow: false),
      );
      when(() => containerService.getContainerStats('c-1')).thenAnswer(
        (_) async => const ContainerStats(
          cache: 0,
          cpuPercent: 10.5,
          ioRead: 1,
          ioWrite: 2,
          memory: 1024,
          networkRX: 3,
          networkTX: 4,
        ),
      );

      await provider.loadAll();
      await Future<void>.delayed(Duration.zero);

      expect(provider.inspectData, '{}');
      expect(provider.logs, 'line-1');
      expect(provider.stats?.cpuPercent, 10.5);
      expect(provider.inspectError, isNull);
      expect(provider.logsError, isNull);
      expect(provider.statsError, isNull);
    });

    test('loadAll keeps successful sections when logs fail', () async {
      when(() => containerService.inspectContainer('c-1'))
          .thenAnswer((_) async => '{}');
      when(() => containerService.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: '1000',
            follow: any(named: 'follow'),
            timestamps: any(named: 'timestamps'),
          )).thenAnswer(
        (_) => logsStream(
          const <String>[],
          follow: false,
          error: Exception('logs failed'),
        ),
      );
      when(() => containerService.getContainerStats('c-1')).thenAnswer(
        (_) async => const ContainerStats(
          cache: 0,
          cpuPercent: 1,
          ioRead: 1,
          ioWrite: 1,
          memory: 1,
          networkRX: 1,
          networkTX: 1,
        ),
      );

      await provider.loadAll();
      await Future<void>.delayed(Duration.zero);

      expect(provider.inspectData, '{}');
      expect(provider.stats, isNotNull);
      expect(provider.logsError, contains('logs failed'));
    });

    test('follow mode appends every streamed chunk', () async {
      final controller = StreamController<String>();
      when(() => containerService.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: any(named: 'tail'),
            follow: true,
            timestamps: any(named: 'timestamps'),
          )).thenAnswer((_) => controller.stream);

      unawaited(provider.loadLogs(follow: true));
      await Future<void>.delayed(Duration.zero);

      controller.add('a');
      await Future<void>.delayed(Duration.zero);
      controller.add('b');
      await Future<void>.delayed(Duration.zero);

      expect(provider.logs, 'ab');
      expect(provider.followLogs, isTrue);

      await controller.close();
    });

    test('stopFollowing switches to a one-shot replay', () async {
      when(() => containerService.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: '1000',
            follow: false,
            timestamps: any(named: 'timestamps'),
          )).thenAnswer((_) => logsStream(<String>['snapshot'], follow: false));

      await provider.stopFollowing();
      await Future<void>.delayed(Duration.zero);

      expect(provider.followLogs, isFalse);
      expect(provider.logs, 'snapshot');
    });
  });
}
