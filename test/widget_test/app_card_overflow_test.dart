import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  group('AppCard overflow guard', () {
    const longTitle =
        'This is a deliberately long title used to validate card title overflow handling across locales and text scales in constrained viewports';
    const longSubtitle =
        'This subtitle is intentionally long and should remain readable while avoiding layout overflow on compact devices and large accessibility font sizes.';

    for (final variant in kCoreOverflowVariants) {
      testWidgets('handles long text in ${variant.name}', (tester) async {
        await pumpOverflowHarness(
          tester,
          variant: variant,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: AppCard(
              title: longTitle,
              subtitle: Text(longSubtitle),
              trailing: Icon(Icons.chevron_right),
              child: Text('Body content'),
            ),
          ),
        );

        await expectNoFlutterExceptions(
          tester,
          reason: 'AppCard raised Flutter exceptions for ${variant.name}',
        );

        final titleFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == longTitle,
        );
        expect(titleFinder, findsOneWidget);

        final titleWidget = tester.widget<Text>(titleFinder);
        expect(titleWidget.maxLines, 1);
        expect(titleWidget.overflow, TextOverflow.ellipsis);
      });
    }
  });
}
