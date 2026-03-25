import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/onboarding/onboarding_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.home:
              return MaterialPageRoute(
                builder: (_) =>
                    const Scaffold(body: Center(child: Text('home'))),
              );
            case AppRoutes.serverConfig:
              return MaterialPageRoute(
                builder: (_) =>
                    const Scaffold(body: Center(child: Text('server-config'))),
              );
            default:
              return MaterialPageRoute(builder: (_) => const OnboardingPage());
          }
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows four onboarding pages and starts with server setup',
      (tester) async {
    await pumpOnboarding(tester);

    expect(
        find.text('Bring your 1Panel servers into one client'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Keep everyday operations close'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Switch faster and read status clearly'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Connect your first server'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('server-config'), findsOneWidget);
  });

  testWidgets('skip leaves onboarding and goes to home', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
