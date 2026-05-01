import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

Future<void> pumpServerFormPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const ServerFormPage(),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations appLocalizations(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(ServerFormPage)))!;
}

void main() {
  group('ServerFormPage', () {
    testWidgets('renders base form fields and actions', (tester) async {
      await pumpServerFormPage(tester);
      final l10n = appLocalizations(tester);

      expect(find.text(l10n.serverFormTitle), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text(l10n.serverFormName), findsOneWidget);
      expect(find.text(l10n.serverFormUrl), findsOneWidget);
      expect(find.text(l10n.serverFormApiKey), findsOneWidget);
      expect(find.text(l10n.serverTokenValidity), findsOneWidget);
      expect(find.text(l10n.serverFormNameHint), findsOneWidget);
      expect(find.text(l10n.serverFormUrlHint), findsOneWidget);
      expect(find.text(l10n.serverFormApiKeyHint), findsOneWidget);
      expect(find.text(l10n.serverTokenValidityHint), findsOneWidget);
      expect(find.text(l10n.serverFormAllowInsecureTls), findsOneWidget);
      expect(find.text(l10n.serverFormAllowInsecureTlsHint), findsOneWidget);
      expect(find.text(l10n.serverFormTest), findsOneWidget);
      expect(find.text(l10n.serverFormSaveConnect), findsOneWidget);

      final tokenValidityField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(3),
      );
      expect(tokenValidityField.controller?.text, '0');
    });

    testWidgets(
      'shows required snackbar when testing without URL and API key',
      (tester) async {
        await pumpServerFormPage(tester);
        final l10n = appLocalizations(tester);

        await tester.enterText(
          find.byType(TextFormField).first,
          'Production',
        );
        await tester.tap(find.widgetWithText(OutlinedButton, l10n.serverFormTest));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text(l10n.serverFormRequired), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byIcon(Icons.error), findsNothing);
      },
    );

    testWidgets('toggles the allow insecure TLS switch', (tester) async {
      await pumpServerFormPage(tester);

      final switchTileFinder = find.byType(SwitchListTile);

      expect(
        tester.widget<SwitchListTile>(switchTileFinder).value,
        isFalse,
      );

      await tester.tap(switchTileFinder);
      await tester.pumpAndSettle();

      expect(
        tester.widget<SwitchListTile>(switchTileFinder).value,
        isTrue,
      );

      await tester.tap(switchTileFinder);
      await tester.pumpAndSettle();

      expect(
        tester.widget<SwitchListTile>(switchTileFinder).value,
        isFalse,
      );
    });

    testWidgets('shows inline required errors when saving an empty form',
        (tester) async {
      await pumpServerFormPage(tester);
      final l10n = appLocalizations(tester);

      await tester.tap(find.widgetWithText(FilledButton, l10n.serverFormSaveConnect));
      await tester.pump();

      expect(find.text(l10n.serverFormRequired), findsNWidgets(3));
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
