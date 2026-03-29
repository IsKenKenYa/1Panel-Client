import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/apps/providers/app_store_provider.dart';

class _MockAppService extends Mock implements AppService {}

class _FakeIgnoreRequest extends Fake
    implements AppInstalledIgnoreUpgradeRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeIgnoreRequest());
  });

  group('AppStoreProvider', () {
    test('loadIgnoredUpdates delegates to service', () async {
      final service = _MockAppService();
      final provider = AppStoreProvider(appService: service);
      final ignored = <AppInstallInfo>[
        AppInstallInfo(id: 1, name: 'mysql', version: '8.0.0'),
      ];

      when(() => service.getIgnoredAppDetails()).thenAnswer((_) async => ignored);

      final result = await provider.loadIgnoredUpdates();

      expect(result, hasLength(1));
      expect(result.first.name, 'mysql');
      verify(() => service.getIgnoredAppDetails()).called(1);
    });

    test('cancelIgnoreUpdate sends request via service', () async {
      final service = _MockAppService();
      final provider = AppStoreProvider(appService: service);

      when(() => service.cancelIgnoreAppUpdate(any()))
          .thenAnswer((_) async {});

      await provider.cancelIgnoreUpdate(88);

      final request = verify(() => service.cancelIgnoreAppUpdate(captureAny()))
          .captured
          .single as AppInstalledIgnoreUpgradeRequest;
      expect(request.appInstallId, 88);
      expect(request.reason, '');
    });
  });
}
