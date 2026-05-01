import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';
import 'package:onepanel_client/ui/routing/ui_target_resolver.dart';

void main() {
  group('UiTargetResolver.resolveForTest', () {
    test('android phone -> mobile phone', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: false,
        platform: TargetPlatform.android,
        shortestSide: 390,
        width: 390,
      );
      expect(target.platformKind, UiPlatformKind.mobile);
      expect(target.formFactor, UiFormFactor.phone);
      expect(target.tabletKind, TabletKind.none);
    });

    test('android pad -> mobile tablet androidPad', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: false,
        platform: TargetPlatform.android,
        shortestSide: 800,
        width: 1200,
      );
      expect(target.platformKind, UiPlatformKind.mobile);
      expect(target.formFactor, UiFormFactor.tablet);
      expect(target.tabletKind, TabletKind.androidPad);
    });

    test('iPadOS -> mobile tablet ipad', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: false,
        platform: TargetPlatform.iOS,
        shortestSide: 820,
        width: 1180,
      );
      expect(target.platformKind, UiPlatformKind.mobile);
      expect(target.formFactor, UiFormFactor.tablet);
      expect(target.tabletKind, TabletKind.ipad);
    });

    test('macOS -> desktopMacos desktop', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: false,
        platform: TargetPlatform.macOS,
        shortestSide: 900,
        width: 1440,
      );
      expect(target.platformKind, UiPlatformKind.desktopMacos);
      expect(target.formFactor, UiFormFactor.desktop);
      expect(target.tabletKind, TabletKind.none);
    });

    test('web wide -> web desktop', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: true,
        platform: TargetPlatform.android,
        shortestSide: 900,
        width: 1300,
      );
      expect(target.platformKind, UiPlatformKind.web);
      expect(target.formFactor, UiFormFactor.desktop);
    });
  });
}

