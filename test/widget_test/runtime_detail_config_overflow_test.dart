import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/widgets/runtime_detail_config_tab_widget.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  group('RuntimeDetailConfigTab overflow guard', () {
    final longImage =
        'registry.example.com/${List.filled(8, 'very-long-runtime-image-segment').join('/')}:stable';
    final longCodeDir =
        '/var/runtime/${List.filled(16, 'deep-directory').join('/')}/src';
    final longPath =
        '/opt/${List.filled(20, 'long-service-path').join('/')}/entrypoint';
    final longContainerName =
        'container-${List.filled(8, 'runtime-instance-node').join('-')}';

    final runtime = RuntimeInfo(
      id: 100,
      name: 'node-runtime',
      type: 'node',
      image: longImage,
      codeDir: longCodeDir,
      path: longPath,
      source: 'custom',
      port: '3000',
      container: longContainerName,
      containerStatus: 'Running',
      params: {
        'HTTP_PROXY':
            'http://${List.filled(8, 'proxy-segment').join('.')}.example.com:8080',
      },
    );

    for (final variant in kCoreOverflowVariants) {
      testWidgets('handles long runtime fields in ${variant.name}',
          (tester) async {
        await pumpOverflowHarness(
          tester,
          variant: variant,
          child: RuntimeDetailConfigTabWidget(runtime: runtime),
        );

        await expectNoFlutterExceptions(
          tester,
          reason:
              'RuntimeDetailConfigTabWidget raised Flutter exceptions for ${variant.name}',
        );

        final imageFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.contains(longImage) ?? false),
        );
        expect(imageFinder, findsOneWidget);
        final imageWidget = tester.widget<Text>(imageFinder);
        expect(imageWidget.maxLines, 2);
        expect(imageWidget.overflow, TextOverflow.ellipsis);

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
