import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/features/firewall/firewall_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeCurrentServerController extends CurrentServerController {
  _FakeCurrentServerController({
    String? currentServerId,
  }) : _currentServerId = currentServerId;

  String? _currentServerId;

  @override
  String? get currentServerId => _currentServerId;

  @override
  bool get hasServer => _currentServerId != null;

  void updateServer(String? serverId) {
    _currentServerId = serverId;
    notifyListeners();
  }
}

void main() {
  testWidgets('FirewallPage renders tab shell when server exists',
      (tester) async {
    final serverController =
        _FakeCurrentServerController(currentServerId: 'server-1');
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentServerController>.value(
        value: serverController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FirewallPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Firewall'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('IPs'), findsOneWidget);
    expect(find.text('Ports'), findsOneWidget);
  });

  testWidgets('FirewallPage responds to server switching', (tester) async {
    final serverController = _FakeCurrentServerController();
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentServerController>.value(
        value: serverController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FirewallPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NoServerSelectedState), findsOneWidget);
    expect(find.text('Firewall'), findsOneWidget);

    serverController.updateServer('server-2');
    await tester.pump();

    expect(find.byType(NoServerSelectedState), findsNothing);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
  });
}
