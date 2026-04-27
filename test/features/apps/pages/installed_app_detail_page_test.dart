import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/app_config_models.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/apps/installed_app_detail_page.dart';
import 'package:onepanel_client/features/apps/providers/installed_apps_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockAppService extends Mock implements AppService {}

void main() {
  late _MockAppService appService;
  late AppInstallInfo appInfo;

  setUp(() {
    appService = _MockAppService();
    appInfo = AppInstallInfo(
      id: 1,
      appId: 2,
      appKey: 'mysql',
      name: 'mysql-demo',
      appName: 'MySQL',
      version: '8.0.0',
      appType: 'app',
      canUpdate: false,
      status: 'running',
    );

    when(() => appService.getAppDetail('2', '8.0.0', 'app')).thenAnswer(
      (_) async => AppItem(
        id: 2,
        name: 'MySQL',
        type: 'app',
        readMe: 'README',
      ),
    );
    when(() => appService.getAppServices('mysql')).thenAnswer(
      (_) async => [
        AppServiceResponse(
          from: 'panel',
          label: 'WebUI',
          value: 'http://localhost',
          status: 'running',
          config: null,
        ),
      ],
    );
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
    when(() => appService.getAppConnInfo('mysql-demo', 'mysql')).thenAnswer(
      (_) async => <String, dynamic>{
        'username': 'root',
        'password': 'secret',
      },
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppService>.value(value: appService),
          ChangeNotifierProvider<InstalledAppsProvider>(
            create: (_) => InstalledAppsProvider(appService: appService),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InstalledAppDetailPage(appInfo: appInfo),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) {
    return AppLocalizations.of(
      tester.element(find.byType(InstalledAppDetailPage)),
    );
  }

  testWidgets('InstalledAppDetailPage shows connection info dialog',
      (tester) async {
    await pumpPage(tester);
    final strings = l10n(tester);

    expect(find.text('MySQL'), findsOneWidget);
    expect(find.text('README'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, strings.appConnInfo));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(strings.appConnInfo), findsWidgets);
    expect(find.textContaining('"username": "root"'), findsOneWidget);
    expect(find.textContaining('"password": "secret"'), findsOneWidget);
    verify(() => appService.getAppConnInfo('mysql-demo', 'mysql')).called(1);
  });
}
