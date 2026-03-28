import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/app_config_models.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/apps/providers/installed_app_detail_provider.dart';
import 'package:onepanel_client/features/containers/container_service.dart';

class MockAppService extends Mock implements AppService {}

class MockContainerService extends Mock implements ContainerService {}

void main() {
  group('InstalledAppDetailProvider', () {
    late MockAppService appService;
    late MockContainerService containerService;

    final appInfo = AppInstallInfo(
      id: 1,
      appId: 2,
      appKey: 'mysql',
      name: 'mysql-demo',
      appName: 'MySQL',
      version: '8.0.0',
      appType: 'app',
      canUpdate: true,
      container: 'mysql-demo',
    );

    setUp(() {
      appService = MockAppService();
      containerService = MockContainerService();
    });

    test('refresh keeps partial data and exposes section-level errors',
        () async {
      when(() => appService.getAppDetail('2', '8.0.0', 'app')).thenThrow(
        Exception('detail failed'),
      );
      when(() => appService.getAppServices('mysql')).thenAnswer(
        (_) async => [
          AppServiceResponse(
            config: null,
            from: 'panel',
            label: 'WebUI',
            status: 'running',
            value: 'http://localhost',
          ),
        ],
      );
      when(() => appService.getAppInstallParams('1')).thenThrow(
        Exception('config failed'),
      );
      when(() => appService.getAppUpdateVersions('1')).thenAnswer(
        (_) async => [
          AppVersion(version: '8.0.1'),
        ],
      );

      final provider = InstalledAppDetailProvider(
        appService: appService,
        containerService: containerService,
      );

      await provider.initialize(appInfo: appInfo);

      expect(provider.appInfo?.id, 1);
      expect(provider.error, isNull);
      expect(provider.storeDetailError, contains('detail failed'));
      expect(provider.configError, contains('config failed'));
      expect(provider.services, hasLength(1));
      expect(provider.updateVersions, hasLength(1));
    });

    test('findInstalledContainer matches names with leading slash', () async {
      when(() => appService.getAppDetail('2', '8.0.0', 'app')).thenAnswer(
        (_) async => AppItem(id: 2, name: 'MySQL', type: 'app'),
      );
      when(() => appService.getAppServices('mysql'))
          .thenAnswer((_) async => const []);
      when(() => appService.getAppInstallParams('1')).thenAnswer(
        (_) async => AppConfig(
          params: const [],
          cpuQuota: 0,
          memoryLimit: 0,
          memoryUnit: 'MB',
          containerName: 'mysql-demo',
          allowPort: false,
          dockerCompose: '',
          type: 'app',
          webUI: '',
        ),
      );
      when(() => appService.getAppUpdateVersions('1'))
          .thenAnswer((_) async => const []);
      when(() => containerService.listContainers()).thenAnswer(
        (_) async => const [
          ContainerInfo(
            id: 'c-1',
            name: '/mysql-demo',
            image: 'mysql:8',
            status: 'running',
            state: 'running',
          ),
        ],
      );

      final provider = InstalledAppDetailProvider(
        appService: appService,
        containerService: containerService,
      );

      await provider.initialize(appInfo: appInfo);
      final container = await provider.findInstalledContainer();

      expect(container?.id, 'c-1');
    });
  });
}
