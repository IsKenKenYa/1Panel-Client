import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/features/onboarding/onboarding_page.dart';
import 'package:onepanel_client/features/settings/language_settings_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/main.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: '1Panel Client',
      packageName: 'com.iskenkenya.onepanel',
      version: '0.5.0-alpha.1',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  for (final completed in [true, false]) {
    testWidgets('设置链接经过启动检查后恢复，已完成引导为 $completed', (tester) async {
      if (completed) await OnboardingService().completeOnboarding();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => CurrentServerController()),
          ChangeNotifierProvider(create: (_) => PinnedModulesController()),
        ],
        child: const MyApp(initialSettings: AppRoutes.settingsLanguage),
      ));
      final splash = tester.element(find.byType(SplashPage));
      final l10n = AppLocalizations.of(splash);
      expect(ModalRoute.of(splash)?.settings.name, AppRoutes.settingsLanguage);
      expect(find.byType(LanguageSettingsPage), findsNothing);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 250));
      final dialog = find.byKey(const Key('testing-warning-dialog'));
      expect(dialog, findsOneWidget);
      final consent = find.byType(CheckboxListTile);
      await tester.ensureVisible(consent);
      await tester.tap(consent);
      await tester.pump();
      await tester.tap(
        find.descendant(of: dialog, matching: find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();
      if (!completed) {
        final guide = tester.element(find.byType(OnboardingPage));
        expect(ModalRoute.of(guide)?.settings.name, AppRoutes.settingsLanguage);
        await tester.tap(find.text(l10n.onboardingSkip));
        await tester.pumpAndSettle();
      }
      final language = tester.element(find.byType(LanguageSettingsPage));
      expect(ModalRoute.of(language)?.settings.name, AppRoutes.settingsLanguage);
    });
  }

  testWidgets('testing warning dialog uses tablet-friendly width',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashPage(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 100));

    final dialog = find.byKey(const Key('testing-warning-dialog'));
    expect(dialog, findsOneWidget);
    expect(tester.getRect(dialog).width, greaterThan(500));
  });
}
