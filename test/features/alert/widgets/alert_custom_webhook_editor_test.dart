import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/features/alert/alert_types.dart';
import 'package:onepanel_client/features/alert/widgets/alert_custom_webhook_editor.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.create(
      ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlertCustomWebhookEditor', () {
    testWidgets('renders the URL, preset and body controls', (tester) async {
      final url = TextEditingController(text: 'https://example.com/hook');
      final template = TextEditingController(text: '{"text":"{{title}}"}');
      addTearDown(url.dispose);
      addTearDown(template.dispose);

      await tester.pumpWidget(wrap(
        AlertCustomWebhookEditor(
          preset: 'genericJson',
          bodyType: 'json',
          urlController: url,
          templateController: template,
          headers: const <AlertPairController>[],
          formPairs: const <AlertPairController>[],
          onPresetChanged: (_) {},
          onBodyTypeChanged: (_) {},
          onAddHeader: () {},
          onRemoveHeader: (_) {},
          onAddPair: () {},
          onRemovePair: (_) {},
          onTemplateChanged: () {},
          onUrlChanged: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('https://example.com/hook'), findsOneWidget);
      expect(find.text('Generic JSON'), findsOneWidget);
      expect(find.text('JSON'), findsWidgets);
      expect(find.text('Text'), findsOneWidget);
    });

    testWidgets('shows key-value editors in form body mode', (tester) async {
      final url = TextEditingController();
      final template = TextEditingController();
      final pairs = <AlertPairController>[
        AlertPairController(key: 'alert', value: 'cpu'),
      ];
      addTearDown(url.dispose);
      addTearDown(template.dispose);
      addTearDown(pairs.single.dispose);

      await tester.pumpWidget(wrap(
        AlertCustomWebhookEditor(
          preset: 'custom',
          bodyType: 'form',
          urlController: url,
          templateController: template,
          headers: const <AlertPairController>[],
          formPairs: pairs,
          onPresetChanged: (_) {},
          onBodyTypeChanged: (_) {},
          onAddHeader: () {},
          onRemoveHeader: (_) {},
          onAddPair: () {},
          onRemovePair: (_) {},
          onTemplateChanged: () {},
          onUrlChanged: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('alert'), findsOneWidget);
      expect(find.text('cpu'), findsOneWidget);
    });
  });

  group('AlertPairEditor', () {
    testWidgets('renders one row per pair and forwards removals',
        (tester) async {
      final pairs = <AlertPairController>[
        AlertPairController(key: 'X-Token', value: 'abc'),
        AlertPairController(key: 'X-Trace', value: 'def'),
      ];
      var removed = -1;
      addTearDown(pairs[0].dispose);
      addTearDown(pairs[1].dispose);

      await tester.pumpWidget(wrap(
        AlertPairEditor(
          title: 'Headers',
          pairs: pairs,
          keyLabel: 'Header name',
          valueLabel: 'Header value',
          addLabel: 'Add header',
          onAdd: () {},
          onRemove: (index) => removed = index,
          onChanged: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('X-Token'), findsOneWidget);
      expect(find.text('X-Trace'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();
      expect(removed, 0);
    });

    testWidgets('add button triggers the add callback', (tester) async {
      var added = 0;
      await tester.pumpWidget(wrap(
        AlertPairEditor(
          title: 'Headers',
          pairs: const <AlertPairController>[],
          keyLabel: 'Header name',
          valueLabel: 'Header value',
          addLabel: 'Add header',
          onAdd: () => added++,
          onRemove: (_) {},
          onChanged: () {},
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Add header'));
      await tester.pump();
      expect(added, 1);
    });
  });

  group('AlertWebhookPresets', () {
    test('generic JSON preset carries the documented template variables', () {
      final template = AlertWebhookPresets.template('genericJson');
      expect(template, isNotNull);
      expect(template, contains('{{title}}'));
      expect(template, contains('{{message}}'));
      expect(template, contains('{{type}}'));
      expect(template, contains('{{nodeName}}'));
      expect(template, contains('{{timestamp}}'));
    });

    test('Slack and Discord presets wrap the message in their own field', () {
      expect(AlertWebhookPresets.template('slack'), contains('"text"'));
      expect(AlertWebhookPresets.template('discord'), contains('"content"'));
    });

    test('Teams preset uses the adaptive card envelope', () {
      final template = AlertWebhookPresets.template('teams');
      expect(template, contains('AdaptiveCard'));
      expect(template, contains('application/vnd.microsoft.card.adaptive'));
    });

    test('custom preset leaves the template untouched', () {
      expect(AlertWebhookPresets.template('custom'), isNull);
    });
  });
}
