import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/native_host_launcher.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'KenPanel',
      packageName: 'com.iskenkenya.onepanel',
      version: '0.5.0-alpha.1',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  testWidgets('settings page exposes about and feedback entries',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsController(),
        child: MaterialApp(
          onGenerateRoute: AppRouter.generateRoute,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsPage)));
    expect(find.text(l10n.settingsAppLock), findsOneWidget);
    expect(find.text(l10n.systemSettingsPanelSection), findsNothing);

    await tester.scrollUntilVisible(
      find.text(l10n.settingsAbout),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsFeedbackCenterTitle), findsOneWidget);
    await tester.tap(find.text(l10n.settingsAbout));
    await tester.pumpAndSettle();

    expect(find.text(l10n.aboutPageTitle), findsOneWidget);
  });

  testWidgets('settings page keeps tablet layout bounded', (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsPage));
    final l10n = AppLocalizations.of(context);
    final bodyWidth = tester.getSize(find.byType(ListView)).width;
    expect(bodyWidth, AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth);
    expect(find.text(l10n.settingsFeedbackCenterTitle), findsOneWidget);
    expect(find.text(l10n.settingsAbout), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting native mode without host exe surfaces build hint',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettingsController();
    await settings.updateUIRenderMode(UIRenderMode.md3);
    var hostHandoverCount = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => settings,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: SettingsPage(
            isWindowsHost: true,
            nativeHostLauncher: NativeHostLauncher(
              isWindows: true,
              exists: (_) => false,
              startProcess: (_) async {},
              runnerExeDir: r'C:\repo\build\windows\x64\runner\Debug',
            ),
            onNativeHostLaunched: () => hostHandoverCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interface style'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RadioListTile<UIRenderMode>).first);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('dotnet build'), findsOneWidget);
    expect(hostHandoverCount, 0);
  });

  testWidgets('render mode tile shows fallback status when host is missing',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettingsController()..markNativeHostMissing();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => settings,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('fell back to MDUI3'), findsOneWidget);
  });
}
