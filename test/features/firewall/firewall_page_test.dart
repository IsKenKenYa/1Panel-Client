import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/features/firewall/firewall_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('FirewallPage renders tab shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FirewallPage(),
      ),
    );
    await tester.pump();

    expect(find.text('Firewall'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('IPs'), findsOneWidget);
    expect(find.text('Ports'), findsOneWidget);
  });
}
