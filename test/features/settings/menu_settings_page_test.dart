import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/settings/menu_settings_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('menu settings route builds page', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CurrentServerController(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: AppRouter.generateRoute,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SizedBox.shrink(),
        ),
      ),
    );

    navigatorKey.currentState!.pushNamed(AppRoutes.menuSettings);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MenuSettingsPage), findsOneWidget);
    expect(find.text('Menu Settings'), findsOneWidget);
  });
}
