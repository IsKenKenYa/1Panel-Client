import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:onepanel_client/features/settings/about_page.dart';
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

  testWidgets('about page shows preview info and feedback entry',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const AboutPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About 1Panel Client'), findsOneWidget);
    expect(find.text('Experimental'), findsWidgets);
    expect(find.text('0.5.0-alpha.1 (42)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open Preview Releases'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Open Preview Releases'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open GitHub Issues'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Open GitHub Issues'), findsOneWidget);
    expect(find.text('https://github.com/IsKenKenYa/1Panel-Client.git'),
        findsOneWidget);
  });
}
