import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanelapp_app/core/config/api_config.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/recent_modules_controller.dart';
import 'package:onepanelapp_app/features/workbench/workbench_page.dart';
import 'package:onepanelapp_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpWorkbench(
    WidgetTester tester, {
    required Size size,
  }) async {
    SharedPreferences.setMockInitialValues({
      'api_configs': jsonEncode([
        ApiConfig(id: 's1', name: 'Demo', url: 'https://demo.test', apiKey: 'key').toJson(),
      ]),
      'current_api_config_id': 's1',
      'client_shell_recent_modules': ['containers', 'files'],
    });

    final currentServer = CurrentServerController();
    final pinned = PinnedModulesController();
    final recent = RecentModulesController();
    await currentServer.load();
    await pinned.load();
    await recent.load();

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(value: currentServer),
          ChangeNotifierProvider<PinnedModulesController>.value(value: pinned),
          ChangeNotifierProvider<RecentModulesController>.value(value: recent),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkbenchPage(onOpenModule: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows recent modules section on compact layout', (tester) async {
    await pumpWorkbench(tester, size: const Size(390, 844));

    expect(find.text('Recent modules'), findsOneWidget);
    expect(find.byKey(const ValueKey('workbench-recent-card')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workbench-recent-card')),
        matching: find.text('Container Management'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders desktop two-column layout', (tester) async {
    await pumpWorkbench(tester, size: const Size(1280, 900));

    expect(find.byKey(const ValueKey('workbench-left-column')), findsOneWidget);
    expect(find.byKey(const ValueKey('workbench-right-column')), findsOneWidget);
  });
}
