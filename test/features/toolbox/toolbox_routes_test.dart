import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_disk_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_host_tool_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    return tester.pumpWidget(
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
  }

  testWidgets('磁盘管理路由在选择服务器前显示服务器选择提示', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await pumpApp(tester, navigatorKey);

    navigatorKey.currentState!.pushNamed(AppRoutes.toolboxDisk);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NoServerSelectedState), findsOneWidget);
    expect(find.byType(ToolboxDiskPage), findsNothing);
    expect(find.text('Disk Management'), findsOneWidget);
  });

  testWidgets('主机工具路由在选择服务器前显示服务器选择提示', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await pumpApp(tester, navigatorKey);

    navigatorKey.currentState!.pushNamed(AppRoutes.toolboxHostTool);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NoServerSelectedState), findsOneWidget);
    expect(find.byType(ToolboxHostToolPage), findsNothing);
    expect(find.text('Host Tool'), findsOneWidget);
  });
}
