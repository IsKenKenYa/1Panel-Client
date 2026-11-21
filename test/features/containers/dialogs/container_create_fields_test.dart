import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/containers/dialogs/container_form_fields.dart';
import 'package:onepanel_client/features/containers/dialogs/network_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/volume_create_dialog.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';

void main() {
  for (final (dialog, initialDriver, driver) in [
    (const NetworkCreateDialog(), 'bridge', 'host'),
    (const VolumeCreateDialog(), 'local', 'local'),
  ]) {
    testWidgets('${dialog.runtimeType} returns the entered name and driver',
        (tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await showAdaptiveFormPanel<Map<String, dynamic>>(
                  context,
                  builder: (_) => dialog,
                );
              },
              child: const Text('Open'),
            );
          }),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final name = find.byType(ContainerNameField);
      final l10n = tester.element(name).l10n;
      final submit = find.text(l10n.commonCreate).last;
      await tester.tap(submit);
      await tester.pump();
      expect(find.text(l10n.serverFormRequired), findsOneWidget);
      await tester.enterText(
        find.descendant(of: name, matching: find.byType(TextField)),
        'project',
      );
      if (driver != initialDriver) {
        await tester.tap(find.text(initialDriver));
        await tester.pumpAndSettle();
        await tester.tap(find.text(driver).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(result?['name'], 'project');
      expect(result?['driver'], driver);
    });
  }
}
