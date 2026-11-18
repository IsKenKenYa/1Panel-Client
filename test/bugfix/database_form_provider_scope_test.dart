import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_form_page.dart';
import 'package:onepanel_client/features/databases/databases_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_scaffold.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('数据库创建保存调用当前表单的 Provider', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DatabaseFormPage(initialScope: DatabaseScope.remote),
      ),
    );
    await tester.pumpAndSettle();

    final formContext = tester.element(find.byType(AppFormScaffold));
    final l10n = AppLocalizations.of(formContext);
    final provider = formContext.read<DatabaseFormProvider>();
    final fieldValues = <String, String>{
      l10n.commonName: 'reporting',
      l10n.databaseEngineLabel: 'mysql',
      l10n.databaseAddressLabel: 'localhost',
      l10n.databasePortLabel: '3306',
      l10n.databaseUsernameLabel: 'reporting',
      l10n.databasePasswordLabel: 'reporting',
    };
    for (final field in fieldValues.entries) {
      final input = find.widgetWithText(TextFormField, field.key);
      await tester.ensureVisible(input);
      await tester.enterText(input, field.value);
      await tester.pump();
    }

    var submitted = false;
    provider.addListener(() {
      if (provider.isSubmitting) submitted = true;
    });
    await tester.tap(find.widgetWithText(FilledButton, l10n.commonSave));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(submitted, isTrue);
    expect(find.byType(DatabaseFormPage), findsOneWidget);
  });
}
