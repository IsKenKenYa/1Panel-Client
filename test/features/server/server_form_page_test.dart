import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

Future<void> pumpServerFormPage(
  WidgetTester tester, {
  ApiConfig? existing,
  Size size = const Size(800, 1600),
  double textScale = 1,
}) async {
  // 表单为纵向长页，默认 800x600 视口装不下全部字段与底部操作；
  // 固定一个更高的视口，避免滚动后点击坐标漂移。
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ServerFormPage(existing: existing),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations appLocalizations(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(ServerFormPage)));
}

void main() {
  group('ServerFormPage', () {
    testWidgets('large text keeps test and save reachable on a narrow phone', (tester) async {
      await pumpServerFormPage(tester, size: const Size(320, 640), textScale: 2);
      final l10n = appLocalizations(tester);
      final probe = find.widgetWithText(OutlinedButton, l10n.serverFormTest);
      await tester.ensureVisible(probe);
      await tester.pumpAndSettle();
      await tester.tap(probe);
      await tester.pumpAndSettle();
      expect(find.text(l10n.serverFormRequired), findsNWidgets(3));
      expect(find.text(l10n.commonSave).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unavailable adapter cannot edit credentials', (tester) async {
      await pumpServerFormPage(
        tester,
        existing: ApiConfig(
          id: 'external',
          name: 'Lab',
          url: 'https://external.example',
          panelType: 'unregistered',
          apiKey: '',
        ),
      );
      final l10n = appLocalizations(tester);
      expect(find.text(l10n.serverPanelUnavailable('unregistered')), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text(l10n.serverFormTest), findsNothing);
    });

    testWidgets('edited addresses require a new API key', (tester) async {
      final original = ApiConfig(
        id: 'existing-server',
        name: 'Production',
        url: 'https://original.example',
        panelType: ApiConfig.onePanelType,
        apiKey: 'stored-test-key',
        tokenValidity: 8,
      );
      await pumpServerFormPage(tester, existing: original);
      final fields = find.byType(TextFormField);
      final l10n = appLocalizations(tester);
      final form = tester.state<FormState>(find.byType(Form));

      expect(find.text(l10n.serverFormEditTitle), findsOneWidget);
      expect(find.text(l10n.serverFormKeepCredential), findsOneWidget);
      expect(tester.widget<TextFormField>(fields.at(0)).controller!.text, original.name);
      expect(tester.widget<TextFormField>(fields.at(1)).controller!.text, original.url);
      expect(tester.widget<TextFormField>(fields.at(2)).controller!.text, isEmpty);
      expect(tester.widget<TextFormField>(fields.at(3)).controller!.text, '8');
      expect(form.validate(), isTrue);

      await tester.enterText(fields.at(1), 'https://another.example');
      await tester.pump();
      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.text(l10n.serverFormRequired), findsOneWidget);
      expect(find.text(l10n.serverFormKeepCredential), findsNothing);

      await tester.enterText(fields.at(1), original.url);
      await tester.pump();
      expect(form.validate(), isTrue);
      await tester.pump();
      expect(find.text(l10n.serverFormKeepCredential), findsOneWidget);
      expect(tester.widget<TextFormField>(fields.at(2)).controller!.text, isEmpty);
    });

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
      expect(find.text(l10n.commonSave), findsOneWidget);

      final tokenValidityField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(3),
      );
      expect(tokenValidityField.controller?.text, '0');
    });

    testWidgets(
      'shows required field errors when testing without URL and API key',
      (tester) async {
        await pumpServerFormPage(tester);
        final l10n = appLocalizations(tester);

        await tester.enterText(
          find.byType(TextFormField).first,
          'Production',
        );
        final testButton =
            find.widgetWithText(OutlinedButton, l10n.serverFormTest);
        await tester.ensureVisible(testButton);
        await tester.pumpAndSettle();
        await tester.tap(testButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.byType(SnackBar), findsNothing);
        expect(find.text(l10n.serverFormRequired), findsNWidgets(2));
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

      // 分区卡片标题行固定 44dp 后整页内容高度变化，目标可能落在视口外，
      // 点击前必须先确保可见。
      await tester.ensureVisible(switchTileFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchTileFinder);
      await tester.pumpAndSettle();

      expect(
        tester.widget<SwitchListTile>(switchTileFinder).value,
        isTrue,
      );

      await tester.ensureVisible(switchTileFinder);
      await tester.pumpAndSettle();
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

      await tester.tap(find.widgetWithText(FilledButton, l10n.commonSave));
      await tester.pump();

      expect(find.text(l10n.serverFormRequired), findsNWidgets(3));
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
