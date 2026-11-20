import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/container_service.dart';
import 'package:onepanel_client/features/containers/providers/container_detail_provider.dart';

class MockContainerService extends Mock implements ContainerService {}

void main() {
  group('ContainerDetailProvider behavior', () {
    late MockContainerService service;
    late ContainerDetailProvider provider;

    const container = ContainerInfo(
      id: 'c-1',
      name: 'mysql-demo',
      image: 'mysql:8',
      status: 'running',
      state: 'running',
    );

    setUpAll(() {
      registerFallbackValue(<String>[]);
    });

    setUp(() {
      service = MockContainerService();
      provider = ContainerDetailProvider(
        container: container,
        service: service,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('loadLogs passes custom tail to the log stream', () async {
      when(() => service.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: '50',
            follow: any(named: 'follow'),
            timestamps: any(named: 'timestamps'),
          )).thenAnswer(
        (_) => Stream<String>.fromIterable(<String>['short log']),
      );

      await provider.loadLogs(tail: '50', follow: false);
      await Future<void>.delayed(Duration.zero);

      expect(provider.logs, 'short log');
      verify(() => service.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: '50',
            follow: false,
            timestamps: any(named: 'timestamps'),
          )).called(1);
    });

    test('logs loading flag clears once the first frame arrives', () async {
      final controller = StreamController<String>();
      when(() => service.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: any(named: 'tail'),
            follow: any(named: 'follow'),
            timestamps: any(named: 'timestamps'),
          )).thenAnswer((_) => controller.stream);

      unawaited(provider.loadLogs());
      await Future<void>.delayed(Duration.zero);
      expect(provider.logsLoading, isTrue);
      expect(provider.logsError, isNull);

      controller.add('done');
      await Future<void>.delayed(Duration.zero);

      expect(provider.logsLoading, isFalse);
      expect(provider.logs, 'done');

      await controller.close();
    });

    test('failed inspect recovers on retry', () async {
      when(() => service.inspectContainer('c-1'))
          .thenThrow(Exception('inspect failed'));

      await provider.loadInspect();
      expect(provider.inspectError, contains('inspect failed'));
      expect(provider.inspectData, isNull);
      expect(provider.inspectLoading, isFalse);

      when(() => service.inspectContainer('c-1'))
          .thenAnswer((_) async => '{"Id":"c-1"}');
      await provider.loadInspect();

      expect(provider.inspectError, isNull);
      expect(provider.inspectData, '{"Id":"c-1"}');
    });

    test('inspect failure keeps previous inspect data', () async {
      when(() => service.inspectContainer('c-1'))
          .thenAnswer((_) async => 'first payload');
      await provider.loadInspect();
      expect(provider.inspectData, 'first payload');

      when(() => service.inspectContainer('c-1'))
          .thenThrow(Exception('refresh failed'));
      await provider.loadInspect();

      expect(provider.inspectData, 'first payload');
      expect(provider.inspectError, contains('refresh failed'));
    });

    test('loadStats network exception surfaces its own message', () async {
      when(() => service.getContainerStats('c-1')).thenThrow(
        const NetworkConnectionException('stats timeout'),
      );

      await provider.loadStats();

      expect(provider.statsError, 'stats timeout');
      expect(provider.stats, isNull);
      expect(provider.statsLoading, isFalse);
    });

    test('failed stats recovers on retry', () async {
      when(() => service.getContainerStats('c-1'))
          .thenThrow(Exception('stats failed'));
      await provider.loadStats();
      expect(provider.statsError, contains('stats failed'));

      when(() => service.getContainerStats('c-1')).thenAnswer(
        (_) async => const ContainerStats(
          cache: 0,
          cpuPercent: 3.5,
          ioRead: 1,
          ioWrite: 1,
          memory: 512,
          networkRX: 1,
          networkTX: 1,
        ),
      );
      await provider.loadStats();

      expect(provider.statsError, isNull);
      expect(provider.stats?.cpuPercent, 3.5);
    });

    test('loadAll recovers every section after a full failure', () async {
      when(() => service.inspectContainer('c-1'))
          .thenThrow(Exception('inspect failed'));
      when(() => service.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: any(named: 'tail'),
            follow: any(named: 'follow'),
            timestamps: any(named: 'timestamps'),
          )).thenAnswer((_) => Stream<String>.error(Exception('logs failed')));
      when(() => service.getContainerStats('c-1'))
          .thenThrow(Exception('stats failed'));

      await provider.loadAll();
      await Future<void>.delayed(Duration.zero);
      expect(provider.inspectError, isNotNull);
      expect(provider.logsError, isNotNull);
      expect(provider.statsError, isNotNull);

      when(() => service.inspectContainer('c-1'))
          .thenAnswer((_) async => '{}');
      when(() => service.streamContainerLogs(
            'mysql-demo',
            since: any(named: 'since'),
            tail: any(named: 'tail'),
            follow: any(named: 'follow'),
            timestamps: any(named: 'timestamps'),
          )).thenAnswer((_) => Stream<String>.fromIterable(<String>['line-1']));
      when(() => service.getContainerStats('c-1')).thenAnswer(
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

      expect(provider.inspectError, isNull);
      expect(provider.logsError, isNull);
      expect(provider.statsError, isNull);
      expect(provider.inspectData, '{}');
      expect(provider.logs, 'line-1');
      expect(provider.stats, isNotNull);
    });
  });
}
