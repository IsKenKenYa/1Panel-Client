import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/features/settings/about_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppSettingsController()..load(),
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeController()..load(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);

    if (!kIsWeb) {
      final menuBar = find.byType(PlatformMenuBar);
      final menu =
          tester.widget<PlatformMenuBar>(menuBar).menus.first as PlatformMenu;
      final l10n = AppLocalizations.of(tester.element(menuBar));
      final aboutItem =
          menu.menus.singleWhere((item) => item.label == l10n.aboutPageTitle);
      aboutItem.onSelected!();
      // 路由 push 带页面切换动画，需要等动画结束页面才进入树中。
      await tester.pumpAndSettle();
      final about = tester.element(find.byType(AboutPage));
      expect(ModalRoute.of(about)?.settings.name, AppRoutes.settingsAbout);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 350));
  });
}
