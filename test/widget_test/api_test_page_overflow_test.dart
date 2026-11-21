import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/pages/settings/api_test_page.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiTestPage overflow guard', () {
    final longName =
        'Primary Server ${List.filled(10, 'International-Node').join('-')}';
    final longUrl =
        'https://${List.filled(10, 'very-long-host-segment').join('.')}.example.com/${List.filled(12, 'api-path-segment').join('/')}';
    final apiKey = List.filled(40, 'a').join();

    final config = ApiConfig(
      id: 'server-1',
      name: longName,
      url: longUrl,
      apiKey: apiKey,
    );

    for (final variant in kCoreOverflowVariants) {
      testWidgets('config rows remain stable in ${variant.name}',
          (tester) async {
        await pumpOverflowHarness(
          tester,
          variant: variant,
          wrapWithScaffold: false,
          child: ApiTestView(
            config: config,
            selectedEndpoint: '/api/v2/dashboard/base/os',
            onEndpointChanged: (_) => fail('Unexpected endpoint change'),
            onRefresh: () => fail('Unexpected refresh'),
            onTest: () => fail('Unexpected request'),
          ),
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

  testWidgets('只允许对 1Panel 执行诊断，短密钥保持隐藏', (tester) async {
    final config = ApiConfig(
      id: 'community-1',
      panelType: 'community',
      name: 'Community',
      url: 'https://localhost',
      apiKey: 'secret',
    );
    await pumpOverflowHarness(
      tester,
      variant: kCoreOverflowVariants.first,
      wrapWithScaffold: false,
      child: ApiTestView(
        config: config,
        selectedEndpoint: '/api/v2/dashboard/base/os',
        onEndpointChanged: (_) => fail('Unexpected endpoint change'),
        onRefresh: () => fail('Unexpected refresh'),
        onTest: () => fail('Unexpected request'),
      ),
    );
    final action =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '测试API'));
    expect(action.onPressed, isNull);
    expect(find.textContaining(config.apiKey), findsNothing);
  });
}
