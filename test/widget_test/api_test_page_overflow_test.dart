import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/pages/settings/api_test_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  group('ApiTestPage overflow guard', () {
    final longName =
        'Primary Server ${List.filled(10, 'International-Node').join('-')}';
    final longUrl =
        'https://${List.filled(10, 'very-long-host-segment').join('.')}.example.com/${List.filled(12, 'api-path-segment').join('/')}';
    final apiKey = List.filled(40, 'a').join();

    setUp(() {
      final config = {
        'id': 'server-1',
        'name': longName,
        'url': longUrl,
        'apiKey': apiKey,
        'tokenValidity': 0,
        'allowInsecureTls': false,
        'isDefault': true,
        'lastUsed': DateTime(2026, 3, 30).toIso8601String(),
      };

      SharedPreferences.setMockInitialValues({
        'api_configs': jsonEncode([config]),
        'current_api_config_id': 'server-1',
      });
    });

    for (final variant in kCoreOverflowVariants) {
      testWidgets('config rows remain stable in ${variant.name}',
          (tester) async {
        await pumpOverflowHarness(
          tester,
          variant: variant,
          wrapWithScaffold: false,
          child: const ApiTestPage(),
        );

        await expectNoFlutterExceptions(
          tester,
          reason: 'ApiTestPage raised Flutter exceptions for ${variant.name}',
        );

        final nameFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.contains(longName) ?? false),
        );
        expect(nameFinder, findsOneWidget);
        final nameWidget = tester.widget<Text>(nameFinder);
        expect(nameWidget.maxLines, 2);
        expect(nameWidget.overflow, TextOverflow.ellipsis);

        final urlFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.contains(longUrl) ?? false),
        );
        expect(urlFinder, findsOneWidget);
        final urlWidget = tester.widget<Text>(urlFinder);
        expect(urlWidget.maxLines, 2);
        expect(urlWidget.overflow, TextOverflow.ellipsis);
      });
    }
  });
}
