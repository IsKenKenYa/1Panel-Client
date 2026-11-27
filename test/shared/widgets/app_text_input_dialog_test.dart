import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Text('Host')),
      ),
    );
    return tester.element(find.text('Host'));
  }

  testWidgets('showAppTextInputDialog 支持返回文本并在提交中防重', (tester) async {
    final context = await pumpHost(tester);
    final pending = Completer<bool>();
    var submitCount = 0;

    final resultFuture = showAppTextInputDialog(
      context,
      title: 'Change password',
      labelText: 'Password',
      obscureText: true,
      onSubmit: (value) {
        submitCount++;
        expect(value, 'secret123');
        return pending.future;
      },
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  secret123  ');
    final confirm = find.byType(FilledButton);
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pump();

    expect(submitCount, 1);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    pending.complete(true);
    await tester.pumpAndSettle();
    expect(await resultFuture, 'secret123');
  });

  testWidgets('showAppTextInputDialog 在 allowEmpty=false 时忽略空提交', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    var calls = 0;

    final resultFuture = showAppTextInputDialog(
      context,
      title: 'Rename',
      initialValue: '  ',
      onSubmit: (_) async {
        calls++;
        return true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(calls, 0);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(await resultFuture, isNull);
  });
}
