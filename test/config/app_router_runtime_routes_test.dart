import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_detail_args.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  Future<void> pumpRouterApp(WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentServerController>.value(
        value: _NoServerCurrentServerController(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: Text('home')),
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pushNamed(
      AppRoutes.runtimeDetail,
      arguments: const RuntimeDetailArgs(runtimeId: 7),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Runtime'), findsWidgets);

    navigatorKey.currentState!.pushNamed(
      AppRoutes.runtimeForm,
      arguments: const RuntimeFormArgs(initialType: 'node'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Runtime'), findsWidgets);

    const deepArgs = RuntimeManageArgs(
      runtimeId: 7,
      runtimeName: 'node-main',
      runtimeKind: 'node',
      codeDir: '/apps/node',
      packageManager: 'npm',
    );

    navigatorKey.currentState!.pushNamed(
      AppRoutes.phpExtensions,
      arguments: deepArgs,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('PHP Extensions'), findsWidgets);

    navigatorKey.currentState!.pushNamed(
      AppRoutes.phpConfig,
      arguments: deepArgs,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('PHP Config'), findsWidgets);

    navigatorKey.currentState!.pushNamed(
      AppRoutes.phpSupervisor,
      arguments: deepArgs,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Supervisor'), findsWidgets);

    navigatorKey.currentState!.pushNamed(
      AppRoutes.nodeModules,
      arguments: deepArgs,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Node Modules'), findsWidgets);

    navigatorKey.currentState!.pushNamed(
      AppRoutes.nodeScripts,
      arguments: deepArgs,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Node Scripts'), findsWidgets);
  }

  testWidgets('AppRouter builds runtime detail and form routes',
      (tester) async {
    await pumpRouterApp(tester);
  });
}
