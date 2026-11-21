import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';

void main() {
  group('AdaptiveLayoutSpec', () {
    test('tablet layout returns bounded widths and dialog constraints', () {
      const spec = AdaptiveLayoutSpec(
        target: UiTarget(
          platformKind: UiPlatformKind.harmony,
          formFactor: UiFormFactor.tablet,
          tabletKind: TabletKind.harmonyPad,
        ),
        size: Size(1280, 800),
      );

      expect(spec.isTablet, isTrue);
      expect(spec.contentMaxWidth, 1040);
      expect(spec.dialogConstraints.maxWidth, 720);
      expect(spec.filesBodyMaxWidth, 980);
      expect(spec.useTabletSplitScaffold, isTrue);
    });

    test('phone layout keeps content fluid and compact dialog insets', () {
      const spec = AdaptiveLayoutSpec(
        target: UiTarget(
          platformKind: UiPlatformKind.mobile,
          formFactor: UiFormFactor.phone,
        ),
        size: Size(393, 852),
      );

      expect(spec.isPhone, isTrue);
      expect(spec.contentMaxWidth, 393);
      expect(spec.dialogConstraints.maxWidth, 361);
      expect(spec.dialogInsetPadding,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24));
    });

    testWidgets('constrained content uses its own width inside a wide window',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      late AdaptiveLayoutSpec spec;
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveWidthContainer(
            maxWidth: 480,
            child: Builder(builder: (context) {
              spec = AdaptiveLayoutSpec.of(context);
              expect(MediaQuery.sizeOf(context).width, 1280);
              return const SizedBox.expand();
            }),
          ),
        ),
      );
      expect(spec.width, 480);
      expect(spec.isPhone, isTrue);
      expect(spec.dialogConstraints.maxWidth, 448);
      expect(spec.target.usesDesktopShell, isTrue);
    }, variant: const TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.macOS,
    }));
  });
}
