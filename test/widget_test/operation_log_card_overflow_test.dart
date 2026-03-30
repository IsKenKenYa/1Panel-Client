import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/logs_models.dart';
import 'package:onepanel_client/features/logs/widgets/operation_log_card_widget.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  group('OperationLogCard overflow guard', () {
    final longDetail = List.filled(
      20,
      'This operation detail is intentionally verbose to validate overflow handling',
    ).join(' | ');
    final longSource =
        'source-${List.filled(12, 'long-cluster-node-segment').join('-')}';
    final longPath =
        '/api/v2/${List.filled(14, 'very-long-resource-name').join('/')}/detail';

    final item = OperationLogEntry(
      detailEn: longDetail,
      detailZh: longDetail,
      source: longSource,
      method: 'POST',
      path: longPath,
      status: 'success',
      createdAt: '2026-03-30 12:00:00',
    );

    for (final variant in kCoreOverflowVariants) {
      testWidgets('handles long content in ${variant.name}', (tester) async {
        await pumpOverflowHarness(
          tester,
          variant: variant,
          child: OperationLogCardWidget(
            item: item,
            onCopy: () {},
          ),
        );

        await expectNoFlutterExceptions(
          tester,
          reason:
              'OperationLogCardWidget raised Flutter exceptions for ${variant.name}',
        );

        final detailFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == longDetail,
        );
        expect(detailFinder, findsOneWidget);
        final detailWidget = tester.widget<Text>(detailFinder);
        expect(detailWidget.maxLines, 3);
        expect(detailWidget.overflow, TextOverflow.ellipsis);

        final methodPathFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.contains(longPath) ?? false),
        );
        expect(methodPathFinder, findsOneWidget);
        final methodPathWidget = tester.widget<Text>(methodPathFinder);
        expect(methodPathWidget.maxLines, 2);
        expect(methodPathWidget.overflow, TextOverflow.ellipsis);
      });
    }
  });
}
