import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/container_extension_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/container_service.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';

class MockContainerService extends Mock implements ContainerService {}

void main() {
  group('ContainersProvider', () {
    late MockContainerService service;
    late ContainersProvider provider;
    late List<ContainerInfo> currentContainers;

    setUp(() {
      service = MockContainerService();
      provider = ContainersProvider(service: service);
      currentContainers = const [
        ContainerInfo(
          id: 'old-1',
          name: '1Panel-redis',
          image: 'redis:7',
          status: 'running',
          state: 'running',
        ),
      ];

      when(() => service.listContainers())
          .thenAnswer((_) async => currentContainers);
      when(() => service.listImages())
          .thenAnswer((_) async => const <ContainerImage>[]);
      when(() => service.listRepos())
          .thenAnswer((_) async => const <ContainerRepo>[]);
      when(() => service.listTemplates())
          .thenAnswer((_) async => const <ContainerTemplate>[]);
      when(() => service.getContainerStatus()).thenAnswer(
        (_) async => ContainerStatus(
          all: currentContainers.length,
          running:
              currentContainers.where((item) => item.state == 'running').length,
          paused: 0,
          exited: 0,
          created: 0,
          dead: 0,
          removing: 0,
          restarting: 0,
          containerCount: currentContainers.length,
          imageCount: 0,
          imageSize: 0,
          networkCount: 0,
          volumeCount: 0,
          composeCount: 0,
          composeTemplateCount: 0,
          repoCount: 0,
        ),
      );
      when(() => service.getDaemonJson()).thenAnswer((_) async => '{}');
      when(() => service.resetForServerChange()).thenReturn(null);
    });

    test('onServerChanged replaces stale containers with the new server data',
        () async {
      await provider.loadAll();
      expect(provider.data.containers.map((item) => item.name),
          contains('1Panel-redis'));

      currentContainers = const [
        ContainerInfo(
          id: 'new-1',
          name: 'mysql-prod',
          image: 'mysql:8',
          status: 'running',
          state: 'running',
        ),
      ];

      await provider.onServerChanged();

      expect(provider.data.containers, hasLength(1));
      expect(provider.data.containers.first.name, 'mysql-prod');
      expect(provider.data.containers.map((item) => item.name),
          isNot(contains('1Panel-redis')));
      verify(() => service.resetForServerChange()).called(1);
    });

    test('loadContainers clears stale entries when refresh fails', () async {
      await provider.loadAll();
      expect(provider.data.containers, isNotEmpty);

      when(() => service.listContainers())
          .thenThrow(Exception('server changed'));

      await provider.loadContainers();

      expect(provider.data.containers, isEmpty);
      expect(provider.containersState.error, contains('加载容器失败'));
    });
  });
}
