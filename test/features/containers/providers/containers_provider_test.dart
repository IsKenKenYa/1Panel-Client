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
    late List<ContainerRepo> currentRepos;
    late List<ContainerTemplate> currentTemplates;
    late String currentDaemonJson;

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
      currentRepos = const <ContainerRepo>[];
      currentTemplates = const <ContainerTemplate>[];
      currentDaemonJson = '{}';

      when(() => service.listContainers())
          .thenAnswer((_) async => currentContainers);
      when(() => service.listImages())
          .thenAnswer((_) async => const <ContainerImage>[]);
        when(() => service.listRepos()).thenAnswer((_) async => currentRepos);
        when(() => service.listTemplates())
          .thenAnswer((_) async => currentTemplates);
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
          composeTemplateCount: currentTemplates.length,
          repoCount: currentRepos.length,
        ),
      );
      when(() => service.getDaemonJson()).thenAnswer((_) async => currentDaemonJson);
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

    test('repo mutations refresh list via provider chain', () async {
      const createRequest = ContainerRepoOperate(
        name: 'dockerhub',
        downloadUrl: 'https://registry.example.com',
      );
      const updateRequest = ContainerRepoOperate(
        id: 1,
        name: 'dockerhub-mirror',
        downloadUrl: 'https://mirror.example.com',
      );

      when(() => service.createRepo(createRequest)).thenAnswer((_) async {
        currentRepos = const <ContainerRepo>[
          ContainerRepo(
            id: 1,
            name: 'dockerhub',
            downloadUrl: 'https://registry.example.com',
            createdAt: '2026-03-29T00:00:00Z',
            updatedAt: '2026-03-29T00:00:00Z',
          ),
        ];
      });
      when(() => service.updateRepo(updateRequest)).thenAnswer((_) async {
        currentRepos = const <ContainerRepo>[
          ContainerRepo(
            id: 1,
            name: 'dockerhub-mirror',
            downloadUrl: 'https://mirror.example.com',
            createdAt: '2026-03-29T00:00:00Z',
            updatedAt: '2026-03-29T01:00:00Z',
          ),
        ];
      });
      when(() => service.deleteRepo(const <int>[1])).thenAnswer((_) async {
        currentRepos = const <ContainerRepo>[];
      });

      expect(await provider.createRepo(createRequest), isTrue);
      expect(provider.data.repos, hasLength(1));
      expect(provider.data.repos.first.name, 'dockerhub');

      expect(await provider.updateRepo(updateRequest), isTrue);
      expect(provider.data.repos, hasLength(1));
      expect(provider.data.repos.first.name, 'dockerhub-mirror');

      expect(await provider.deleteRepo(const <int>[1]), isTrue);
      expect(provider.data.repos, isEmpty);

      verify(() => service.createRepo(createRequest)).called(1);
      verify(() => service.updateRepo(updateRequest)).called(1);
      verify(() => service.deleteRepo(const <int>[1])).called(1);
    });

    test('template mutations refresh list via provider chain', () async {
      const createRequest = ContainerTemplateOperate(
        name: 'wordpress-template',
        description: 'wordpress stack',
        content: 'services:\n  app: wordpress',
      );
      const updateRequest = ContainerTemplateOperate(
        id: 9,
        name: 'wordpress-template-v2',
        description: 'wordpress stack v2',
        content: 'services:\n  app: wordpress:latest',
      );

      when(() => service.createTemplate(createRequest)).thenAnswer((_) async {
        currentTemplates = const <ContainerTemplate>[
          ContainerTemplate(
            id: 9,
            name: 'wordpress-template',
            description: 'wordpress stack',
            content: 'services:\n  app: wordpress',
            createdAt: '2026-03-29T00:00:00Z',
            updatedAt: '2026-03-29T00:00:00Z',
          ),
        ];
      });
      when(() => service.updateTemplate(updateRequest)).thenAnswer((_) async {
        currentTemplates = const <ContainerTemplate>[
          ContainerTemplate(
            id: 9,
            name: 'wordpress-template-v2',
            description: 'wordpress stack v2',
            content: 'services:\n  app: wordpress:latest',
            createdAt: '2026-03-29T00:00:00Z',
            updatedAt: '2026-03-29T01:00:00Z',
          ),
        ];
      });
      when(() => service.deleteTemplate(const <int>[9])).thenAnswer((_) async {
        currentTemplates = const <ContainerTemplate>[];
      });

      expect(await provider.createTemplate(createRequest), isTrue);
      expect(provider.data.templates, hasLength(1));
      expect(provider.data.templates.first.name, 'wordpress-template');

      expect(await provider.updateTemplate(updateRequest), isTrue);
      expect(provider.data.templates, hasLength(1));
      expect(provider.data.templates.first.name, 'wordpress-template-v2');

      expect(await provider.deleteTemplate(const <int>[9]), isTrue);
      expect(provider.data.templates, isEmpty);

      verify(() => service.createTemplate(createRequest)).called(1);
      verify(() => service.updateTemplate(updateRequest)).called(1);
      verify(() => service.deleteTemplate(const <int>[9])).called(1);
    });

    test('updateDaemonJson writes and reloads config', () async {
      const updatedConfig = '{"debug":true}';
      when(() => service.updateDaemonJson(updatedConfig)).thenAnswer((_) async {
        currentDaemonJson = updatedConfig;
      });

      expect(await provider.updateDaemonJson(updatedConfig), isTrue);
      expect(provider.data.daemonJson, updatedConfig);

      verify(() => service.updateDaemonJson(updatedConfig)).called(1);
      verify(() => service.getDaemonJson()).called(1);
    });
  });
}
