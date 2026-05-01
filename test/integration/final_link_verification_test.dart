import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';
import 'package:onepanel_client/features/apps/apps_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';

class MockCurrentServerController extends CurrentServerController {
  bool _hasServer = false;
  bool _isValidConnection = true;
  String? _errorMsg;

  @override
  bool get hasServer => _hasServer;

  void setHasServer(bool value) {
    _hasServer = value;
    notifyListeners();
  }

  void setInvalidConnection(String error) {
    _isValidConnection = false;
    _errorMsg = error;
    notifyListeners();
  }
}

void main() {
  testWidgets('Test blank server config shows unlogged-in guidance', (tester) async {
    final controller = MockCurrentServerController();
    controller.setHasServer(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(value: controller),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: AppsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify NoServerSelectedState is shown
    expect(find.byType(NoServerSelectedState), findsOneWidget);
    expect(find.textContaining('请先选择当前服务器，再进入该模块。'), findsWidgets);
  });
}
