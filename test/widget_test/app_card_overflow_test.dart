import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

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

    testWidgets('keeps the title and distinct action in a narrow card',
        (tester) async {
      var rowOpens = 0;
      var installs = 0;
      const title = 'Backup';
      const actionLabel = 'Install application';

      await pumpOverflowHarness(
        tester,
        variant: kCoreOverflowVariants[1],
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 250,
            child: AppCard(
              title: title,
              leading: const Icon(Icons.archive_outlined),
              onTap: () => rowOpens++,
              trailing: FilledButton.tonal(
                onPressed: () => installs++,
                child: const Text(actionLabel),
              ),
            ),
          ),
        ),
      );

      await expectNoFlutterExceptions(tester);
      final card = tester.getRect(find.byType(Card));
      final action = tester.getRect(find.byType(FilledButton));
      expect(card.contains(action.center), isTrue);
      expect(tester.getSize(find.text(title)).width, greaterThan(40));

      await tester.tap(find.text(title));
      await tester.tap(find.text(actionLabel));
      expect(rowOpens, 1);
      expect(installs, 1);
    });

    testWidgets('responds to a mouse and keyboard at phone width',
        (tester) async {
      var opens = 0;

      await pumpOverflowHarness(
        tester,
        variant: kCoreOverflowVariants.first,
        child: Align(
          alignment: Alignment.topCenter,
          child: AppCard(
            title: 'Backups',
            padding: EdgeInsets.zero,
            onTap: () => opens++,
          ),
        ),
      );

      final card = find.byType(Card);
      expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 200));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(card));
      await tester.pumpAndSettle();
      expect(tester.widget<Card>(card).elevation, greaterThan(0));
      await mouse.moveTo(const Offset(1, 200));
      await tester.pumpAndSettle();
      expect(tester.widget<Card>(card).elevation, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(opens, 1);
    });
  });

  testWidgets('entry lists show navigation only for actionable rows',
      (tester) async {
    var opens = 0;
    const activeKey = ValueKey('open-settings');
    const infoKey = ValueKey('version');

    await pumpOverflowHarness(
      tester,
      variant: kCoreOverflowVariants.first,
      child: SectionEntryList(
        title: 'Device',
        items: [
          SectionEntryItem(
            key: activeKey,
            title: 'Settings',
            icon: Icons.settings_outlined,
            onTap: () => opens++,
          ),
          const SectionEntryItem(
            key: infoKey,
            title: 'Version',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );

    final active = find.byKey(activeKey);
    final info = find.byKey(infoKey);
    expect(tester.getSize(active).height, greaterThanOrEqualTo(48));
    expect(tester.widget<ListTile>(active).trailing, isA<Icon>());
    expect(tester.widget<ListTile>(info).trailing, isNull);

    await tester.tap(info);
    expect(opens, 0);
    await tester.tap(active);
    expect(opens, 1);
  });
}
