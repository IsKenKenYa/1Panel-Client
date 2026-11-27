import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/apps/installed_app_detail_page.dart';
import 'package:onepanel_client/features/apps/providers/installed_apps_provider.dart';
import 'package:onepanel_client/features/apps/widgets/installed_app_card.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  final installation = AppInstallInfo(
    appName: 'Service',
    name: 'service-instance',
  );

  testWidgets('已安装应用卡片打开的详情沿用列表 Provider', (tester) async {
    final service = AppService();
    final installedApps = InstalledAppsProvider(appService: service);
    addTearDown(installedApps.dispose);

    await tester.pumpWidget(
      Provider<AppService>.value(
        value: service,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: AppRouter.generateRoute,
          home: ChangeNotifierProvider.value(
            value: installedApps,
            child: Scaffold(
              body: InstalledAppCard(
                app: installation,
                onStart: () {},
                onStop: () {},
                onRestart: () {},
                onUninstall: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service'));
    await tester.pumpAndSettle();

    final appBar = find.descendant(
      of: find.byType(InstalledAppDetailPage),
      matching: find.byType(AppBar),
    );
    expect(appBar, findsOneWidget);
    expect(tester.element(appBar).read<InstalledAppsProvider>(),
        same(installedApps));
  });

  testWidgets('已安装应用的独立详情入口提供操作所需的 Provider', (tester) async {
    await tester.pumpWidget(
      Provider<AppService>(
        create: (_) => AppService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InstalledAppDetailPage(appInfo: installation),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.element(find.byType(AppBar)).read<InstalledAppsProvider>(),
        isA<InstalledAppsProvider>());
  });

  testWidgets('桌面关闭连接信息弹框时保留应用详情', (tester) async {
    await tester.pumpWidget(
      Provider<AppService>(
        create: (_) => AppService(),
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InstalledAppDetailPage(
                        appInfo: installation,
                      ),
                    ),
                  ),
                  child: const Text('Service'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Service'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(InstalledAppDetailPage)),
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.appConnInfo));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.commonClose));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(InstalledAppDetailPage), findsOneWidget);
  });
}
