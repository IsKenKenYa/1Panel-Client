import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/ui/desktop/common/app/desktop_shell_page.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_sidebar.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_top_tool_area.dart';

void main() {
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
}

