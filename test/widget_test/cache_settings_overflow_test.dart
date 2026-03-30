import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/pages/settings/cache_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  group('CacheSettingsPage overflow guard', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    for (final variant in kCoreOverflowVariants) {
      testWidgets('stats rows stay stable in ${variant.name}', (tester) async {
        final settingsController = AppSettingsController();

        await pumpOverflowHarness(
          tester,
          variant: variant,
          wrapWithScaffold: false,
          child: ChangeNotifierProvider<AppSettingsController>.value(
            value: settingsController,
            child: const CacheSettingsPage(),
          ),
        );

        await expectNoFlutterExceptions(
          tester,
          reason:
              'CacheSettingsPage raised Flutter exceptions for ${variant.name}',
        );

        final valueFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.contains('MB /') ?? false),
        );
        expect(valueFinder, findsOneWidget);

        final valueWidget = tester.widget<Text>(valueFinder);
        expect(valueWidget.maxLines, 1);
        expect(valueWidget.overflow, TextOverflow.ellipsis);
      });
    }
  });
}
