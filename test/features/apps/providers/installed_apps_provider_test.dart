import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/apps/providers/installed_apps_provider.dart';

class MockAppService extends Mock implements AppService {}

class FakeAppInstalledSearchRequest extends Fake
    implements AppInstalledSearchRequest {}

class FakeAppInstalledIgnoreUpgradeRequest extends Fake
    implements AppInstalledIgnoreUpgradeRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      FakeAppInstalledSearchRequest(),
    );
    registerFallbackValue(
      FakeAppInstalledIgnoreUpgradeRequest(),
    );
  });

  group('InstalledAppsProvider', () {
    late MockAppService appService;
    late InstalledAppsProvider provider;

    setUp(() {
      appService = MockAppService();
      provider = InstalledAppsProvider(appService: appService);
    });

    test('loadInstalledApps loads all pages instead of truncating at 100', () async {
      when(() => appService.searchInstalledApps(any())).thenAnswer((invocation) async {
        final request = invocation.positionalArguments.first as AppInstalledSearchRequest;
        if (request.page == 1) {
          return PageResult(
            items: List.generate(
              100,
              (index) => AppInstallInfo(
                id: index + 1,
                name: 'app-${index + 1}',
                status: 'running',
              ),
            ),
            total: 101,
          );
        }

        return PageResult(
          items: [
            AppInstallInfo(
              id: 101,
              name: 'app-101',
              status: 'stopped',
            ),
          ],
          total: 101,
        );
      });

      await provider.loadInstalledApps();

      expect(provider.installedApps, hasLength(101));
      expect(provider.stats.total, 101);
      expect(provider.stats.running, 100);
      expect(provider.stats.stopped, 1);
      verify(() => appService.searchInstalledApps(any())).called(2);
    });

    test('ignoreUpdate always uses the supported version scope', () async {
      when(() => appService.ignoreAppUpdate(any())).thenAnswer((_) async {});
      when(() => appService.searchInstalledApps(any())).thenAnswer(
        (_) async => PageResult(items: const [], total: 0),
      );

      await provider.ignoreUpdate(42, 'skip this version');

      final request = verify(() => appService.ignoreAppUpdate(captureAny()))
          .captured
          .single as AppInstalledIgnoreUpgradeRequest;
      expect(request.appInstallId, 42);
      expect(request.reason, 'skip this version');
      expect(request.scope, AppIgnoreUpgradeScope.version);
    });
  });
}
