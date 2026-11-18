import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  const shortPane = UiOverflowVariant(
    name: 'compact-height-with-large-text',
    locale: Locale('en'),
    size: Size(400, 200),
    textScale: 2,
  );
  const description = 'Check your server connection and network settings.';

  testWidgets('error state keeps retry reachable in a short pane',
      (tester) async {
    var retries = 0;
    await pumpOverflowHarness(
      tester,
      variant: shortPane,
      child: ModuleErrorStateWidget(
        message: description,
        onRetry: () => retries++,
      ),
    );
    await expectNoFlutterExceptions(tester);

    final retry = find.byType(FilledButton);
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    expect(retries, 1);
  });

  testWidgets('empty state keeps its action reachable in a short pane',
      (tester) async {
    var creates = 0;
    await pumpOverflowHarness(
      tester,
      variant: shortPane,
      child: ModuleEmptyStateWidget(
        title: 'No backups',
        description: description,
        actionLabel: 'Create backup',
        onAction: () => creates++,
      ),
    );
    await expectNoFlutterExceptions(tester);

    final create = find.byType(FilledButton);
    await tester.ensureVisible(create);
    await tester.pumpAndSettle();
    await tester.tap(create);
    expect(creates, 1);
  });
}
