import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/settings/language_settings_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/ui/desktop/macos/app/macos_shell_content_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings and Servers open in the existing desktop shell',
      (tester) async {
    final runId = DateTime.now().microsecondsSinceEpoch;
    SharedPreferences.setPrefix('desktop_module_navigation_test.$runId.');
    final preferences = await SharedPreferences.getInstance();
    addTearDown(preferences.clear);
    final onboarding = OnboardingService();
    await onboarding.completeCoach(OnboardingService.coachServerAddKey);
    await onboarding.completeCoach(OnboardingService.coachServerCardKey);

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsController()),
          ChangeNotifierProvider(create: (_) => CurrentServerController()),
          ChangeNotifierProvider(create: (_) => PinnedModulesController()),
          ChangeNotifierProvider(create: (_) => ServerProvider()),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          onGenerateRoute: AppRouter.generateRoute,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );

    final settingsPage = find.byType(SettingsPage);
    final l10n = AppLocalizations.of(tester.element(settingsPage));
    final serverManagement = find.text(l10n.settingsServerManagement);
    await tester.scrollUntilVisible(
      serverManagement,
      200,
      scrollable: find.descendant(
        of: settingsPage,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(serverManagement.hitTestable());
    await tester.pumpAndSettle();
    final shell = find.byType(MacosShellContentPage);
    final originalShell = tester.state(shell);
    final serverList = find.byType(ServerListPage).hitTestable();
    expect(serverList, findsOneWidget);
    final originalServers = tester.state(serverList);

    await tester.tap(find.byTooltip(l10n.settingsPageTitle));
    await tester.pumpAndSettle();
    final languageEntry = find.text(l10n.settingsLanguage);
    await tester.ensureVisible(languageEntry);
    await tester.tap(languageEntry);
    await tester.pumpAndSettle();
    final language = find.byType(LanguageSettingsPage).hitTestable();
    expect(language, findsOneWidget);

    await tester.tap(find.text(l10n.serverActionSwitch).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.serverPageTitle));
    await tester.pumpAndSettle();
    expect(tester.state(shell), same(originalShell));
    expect(tester.state(serverList), same(originalServers));

    await tester.tap(find.byTooltip(l10n.settingsPageTitle));
    await tester.pumpAndSettle();
    expect(language, findsOneWidget);
    findShellContentNavigator(tester.element(language))!.pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      serverManagement,
      200,
      scrollable: find.descendant(
        of: settingsPage,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(serverManagement.hitTestable());
    await tester.pumpAndSettle();
    expect(tester.state(shell), same(originalShell));
    expect(tester.state(serverList), same(originalServers));
  });
}
