import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';
import 'package:onepanelapp_app/features/containers/container_service.dart';
import 'package:onepanelapp_app/features/containers/providers/container_detail_provider.dart';

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

    setUp(() {
      containerService = MockContainerService();
      provider = ContainerDetailProvider(
        container: container,
        service: containerService,
      );
    });

    test('loadAll populates inspect logs and stats', () async {
      when(() => containerService.inspectContainer('c-1')).thenAnswer((_) async => '{}');
      when(() => containerService.getContainerLogs('mysql-demo', tail: '1000'))
          .thenAnswer((_) async => 'line-1');
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

      expect(provider.inspectData, '{}');
      expect(provider.logs, 'line-1');
      expect(provider.stats?.cpuPercent, 10.5);
      expect(provider.inspectError, isNull);
      expect(provider.logsError, isNull);
      expect(provider.statsError, isNull);
    });

    test('loadAll keeps successful sections when logs fail', () async {
      when(() => containerService.inspectContainer('c-1')).thenAnswer((_) async => '{}');
      when(() => containerService.getContainerLogs('mysql-demo', tail: '1000'))
          .thenThrow(Exception('logs failed'));
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

      expect(provider.inspectData, '{}');
      expect(provider.stats, isNotNull);
      expect(provider.logsError, contains('logs failed'));
    });
  });
}
