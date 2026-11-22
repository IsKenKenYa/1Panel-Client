import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';

const Key _probeKey = Key('platform-utils-input-device-probe');

void main() {
  setUp(() {
    // Reset the platform capabilities override so each test starts from
    // a known baseline.
    debugDefaultTargetPlatformOverride = null;
    PlatformCapabilities.setTargetPlatformForTest(null);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    PlatformCapabilities.setTargetPlatformForTest(null);
  });

  group('PlatformUtils.inputDeviceKinds', () {
    testWidgets(
      'returns InputDeviceKind.pointer on a mock desktop target platform',
      (tester) async {
        // Pin the test platform to a desktop host (macOS) so the
        // non-web branch resolves to `isDesktopPlatform == true`.
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        PlatformCapabilities.setTargetPlatformForTest(TargetPlatform.macOS);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SizedBox.shrink(key: _probeKey)),
          ),
        );

        final BuildContext context =
            tester.element(find.byKey(_probeKey));
        expect(
          PlatformUtils.inputDeviceKinds(context),
          InputDeviceKind.pointer,
        );

        // The Flutter test framework asserts foundation debug variables
        // are unset at the end of each test.
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'returns InputDeviceKind.touch on a mock Android target platform',
      (tester) async {
        // Pin the test platform to a mobile host (Android) so the
        // non-web branch resolves to `isDesktopPlatform == false` and
        // falls through to the `touch` default.
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        PlatformCapabilities.setTargetPlatformForTest(TargetPlatform.android);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SizedBox.shrink(key: _probeKey)),
          ),
        );

        final BuildContext context =
            tester.element(find.byKey(_probeKey));
        expect(
          PlatformUtils.inputDeviceKinds(context),
          InputDeviceKind.touch,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'returns InputDeviceKind.pointer on a mock Windows target platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        PlatformCapabilities.setTargetPlatformForTest(TargetPlatform.windows);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SizedBox.shrink(key: _probeKey)),
          ),
        );

        final BuildContext context =
            tester.element(find.byKey(_probeKey));
        expect(
          PlatformUtils.inputDeviceKinds(context),
          InputDeviceKind.pointer,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'returns InputDeviceKind.touch on a mock iOS target platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        PlatformCapabilities.setTargetPlatformForTest(TargetPlatform.iOS);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SizedBox.shrink(key: _probeKey)),
          ),
        );

        final BuildContext context =
            tester.element(find.byKey(_probeKey));
        expect(
          PlatformUtils.inputDeviceKinds(context),
          InputDeviceKind.touch,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    test(
      'on kIsWeb the classification is driven by '
      'MediaQuery.sizeOf(context).width (source-based)',
      () {
        // `kIsWeb` is a compile-time constant and therefore cannot be
        // flipped at runtime in unit tests. The web branch is verified
        // by source inspection: the function must consult
        // `MediaQuery.sizeOf(context).width` against
        // `tabletWidthBreakpoint` to pick between `pointer` and `touch`.
        final source = File(
          'lib/core/utils/platform_utils.dart',
        ).readAsStringSync();

        expect(source.contains('kIsWeb'), isTrue);
        expect(source.contains('MediaQuery.sizeOf(context).width'), isTrue);
        expect(source.contains('tabletWidthBreakpoint'), isTrue);
        expect(
          source.contains(
            'MediaQuery.sizeOf(context).width >= tabletWidthBreakpoint',
          ),
          isTrue,
          reason:
              'web branch must compare the screen width against the '
              'tablet breakpoint to pick InputDeviceKind.pointer',
        );
        // Pointer must be the >= side, touch the < side.
        final pointerSide = source.indexOf(
          'MediaQuery.sizeOf(context).width >= tabletWidthBreakpoint',
        );
        final afterPointer = source.substring(pointerSide);
        expect(afterPointer.contains('InputDeviceKind.pointer'), isTrue);
        expect(afterPointer.contains('InputDeviceKind.touch'), isTrue);
      },
    );

    test(
      'on non-web the classification is driven by isDesktopPlatform',
      () {
        final source = File(
          'lib/core/utils/platform_utils.dart',
        ).readAsStringSync();

        // The non-web branch must check `isDesktopPlatform` for
        // pointer and fall through to `touch` for everything else.
        expect(source.contains('if (isDesktopPlatform)'), isTrue);
        expect(source.contains('return InputDeviceKind.pointer;'), isTrue);
        expect(source.contains('return InputDeviceKind.touch;'), isTrue);
      },
    );
  });
}
