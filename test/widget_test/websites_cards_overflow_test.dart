import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/websites/widgets/website_list_item_card_widget.dart';
import 'package:onepanel_client/features/websites/widgets/website_overview_card_widget.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  group('Websites cards overflow guard', () {
    final longDomain =
        '${List.filled(8, 'very-long-subdomain-segment').join('.')}.example.com';
    final longGroup =
        'group-${List.filled(10, 'internationalization').join('-')}';
    final longRemark = List.filled(18, 'remark').join('-');
    final longPath =
        '/var/www/${List.filled(18, 'nested-folder-name').join('/')}/index.html';

    final website = WebsiteInfo(
      id: 10,
      primaryDomain: longDomain,
      type: 'static',
      status: 'running',
      protocol: 'https',
      sitePath: longPath,
      group: longGroup,
      remark: longRemark,
      runtimeName: 'php-${List.filled(5, '8-3-build').join('-')}',
      defaultServer: true,
    );

    for (final variant in kCoreOverflowVariants) {
      testWidgets('list card handles long fields in ${variant.name}',
          (tester) async {
        await pumpOverflowHarness(
          tester,
          variant: variant,
          child: WebsiteListItemCard(
            website: website,
            selectionMode: false,
            selected: false,
            onTap: () {},
            onSelectedChanged: (_) {},
            onAction: (_) {},
          ),
        );

        await expectNoFlutterExceptions(
          tester,
          reason:
              'WebsiteListItemCard raised Flutter exceptions for ${variant.name}',
        );

        final titleFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == longDomain,
        );
        expect(titleFinder, findsOneWidget);
        final titleWidget = tester.widget<Text>(titleFinder);
        expect(titleWidget.maxLines, 1);
        expect(titleWidget.overflow, TextOverflow.ellipsis);

        final subtitleFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.contains(longRemark) ?? false),
        );
        expect(subtitleFinder, findsOneWidget);
        final subtitleWidget = tester.widget<Text>(subtitleFinder);
        expect(subtitleWidget.maxLines, 2);
        expect(subtitleWidget.overflow, TextOverflow.ellipsis);
      });

      testWidgets('overview card handles long fields in ${variant.name}',
          (tester) async {
        await pumpOverflowHarness(
          tester,
          variant: variant,
          child: WebsiteOverviewCard(website: website),
        );

        await expectNoFlutterExceptions(
          tester,
          reason:
              'WebsiteOverviewCard raised Flutter exceptions for ${variant.name}',
        );

        final domainFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == longDomain,
        );
        expect(domainFinder, findsOneWidget);
        final domainWidget = tester.widget<Text>(domainFinder);
        expect(domainWidget.maxLines, 2);
        expect(domainWidget.overflow, TextOverflow.ellipsis);

        final pathFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.contains(longPath) ?? false),
        );
        expect(pathFinder, findsOneWidget);
        final pathWidget = tester.widget<Text>(pathFinder);
        expect(pathWidget.maxLines, 2);
        expect(pathWidget.overflow, TextOverflow.ellipsis);
      });
    }
  });
}
