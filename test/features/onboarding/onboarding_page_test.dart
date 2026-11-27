import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/onboarding/onboarding_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    Size? size,
    double textScale = 1,
  }) async {
    if (size != null) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
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

  testWidgets('shows four multi-panel onboarding pages and starts setup', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingPage)),
    );

    expect(find.text(l10n.onboardingTitle1), findsOneWidget);
    expect(find.text('1Panel'), findsOneWidget);
    expect(find.text('DPanel'), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingTitle2), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingTitle3), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingTitle4), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pumpAndSettle();

    expect(find.text('server-config'), findsOneWidget);
  });

  testWidgets('skip leaves onboarding and goes to home', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('adapts cleanly to narrow short screen with 2x text scale', (
    tester,
  ) async {
    await pumpOnboarding(tester, size: const Size(360, 560), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Next').hitTestable(), findsOneWidget);
  });
}
