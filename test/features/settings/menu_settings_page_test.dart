import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('menu settings requires selecting a server', (tester) async {
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

    expect(find.byType(NoServerSelectedState), findsOneWidget);
  });
}
