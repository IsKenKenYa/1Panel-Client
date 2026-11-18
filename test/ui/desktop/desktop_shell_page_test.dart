import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/settings/language_settings_page.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/ui/desktop/macos/app/macos_shell_content_page.dart';
import 'package:onepanel_client/ui/desktop/windows/app/windows_shell_content_page.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/ui/desktop/common/app/desktop_shell_page.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_sidebar.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_top_tool_area.dart';

void main() {
  setUp(() {
    // Pretend we are running on macOS so `inputDeviceKinds` returns
    // `pointer` and the sidebar is rendered in the offscreen-tree
    // (i.e. visible) for the assertions below.
    PlatformCapabilities.setTargetPlatformForTest(TargetPlatform.macOS);
  });

  tearDown(() {
    PlatformCapabilities.setTargetPlatformForTest(null);
  });

  testWidgets('DesktopShellPage renders sidebar + top tool area', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsController()),
          ChangeNotifierProvider(create: (_) => CurrentServerController()),
          ChangeNotifierProvider(create: (_) => PinnedModulesController()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('zh')],
          home: const MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: DesktopShellPage(
              initialIndex: 0,
              initialModuleId: 'settings',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.byType(DesktopTopToolArea), findsOneWidget);
  });

  testWidgets('desktop module navigation reuses the mounted shell',
      (tester) async {
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
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          onGenerateRoute: AppRouter.generateRoute,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SizedBox.shrink(),
        ),
      ),
    );
    navigator.currentState!.pushNamed<void>(
      AppRoutes.home,
      arguments: {'module': 'settings'},
    );
    await tester.pumpAndSettle();
    final shell = find.byWidgetPredicate((widget) =>
        widget is DesktopShellPage ||
        widget is MacosShellContentPage ||
        widget is WindowsShellContentPage);
    final originalShell = tester.state(shell);
    final settings = AppLocalizations.of(tester.element(shell));
    await tester.tap(find.text(settings.settingsLanguage).hitTestable());
    await tester.pumpAndSettle();
    final detail = find.byType(LanguageSettingsPage);
    expect(detail, findsOneWidget);

    openRouteRespectingShell<void>(tester.element(detail), AppRoutes.settings);
    await tester.pumpAndSettle();

    expect(tester.state(shell), same(originalShell));
    expect(detail, findsNothing);
    expect(find.text(settings.settingsLanguage).hitTestable(), findsOneWidget);
  },
      variant: const TargetPlatformVariant({
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }));
}

