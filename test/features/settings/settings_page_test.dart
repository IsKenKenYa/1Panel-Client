import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: '1Panel Client',
      packageName: 'com.iskenkenya.onepanel',
      version: '0.5.0-alpha.1',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  testWidgets('settings page exposes about and feedback entries',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('About'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('About 1Panel Client'), findsOneWidget);
  });
}
