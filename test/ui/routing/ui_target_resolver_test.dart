import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/config/app_route_entries.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';
import 'package:onepanel_client/ui/routing/ui_target_resolver.dart';

void main() {
  group('UiTargetResolver.resolveForTest', () {
    test('android phone -> mobile phone', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: false,
        platform: TargetPlatform.android,
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
        width: 1200,
      );
      expect(target.platformKind, UiPlatformKind.mobile);
      expect(target.formFactor, UiFormFactor.tablet);
      expect(target.tabletKind, TabletKind.androidPad);
    });

    test('harmony pad -> harmony tablet harmonyPad', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: false,
        platform: TargetPlatform.android,
        width: 1200,
        isOhos: true,
      );
      expect(target.platformKind, UiPlatformKind.harmony);
      expect(target.formFactor, UiFormFactor.tablet);
      expect(target.tabletKind, TabletKind.harmonyPad);
    });

    test('iPadOS -> mobile tablet ipad', () {
      final target = UiTargetResolver.resolveForTest(
        isWeb: false,
        platform: TargetPlatform.iOS,
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
        width: 1300,
      );
      expect(target.platformKind, UiPlatformKind.web);
      expect(target.formFactor, UiFormFactor.desktop);
    });

    test('compact web links resolve through the same module navigator', () {
      final routes = buildRouteRegistryEntries();
      final web = UiTargetResolver.resolveForTest(
        isWeb: true, platform: TargetPlatform.android, width: 390,
      );
      expect(web.isPhone, isTrue);
      expect(web.usesDesktopShell, isTrue);
      final phone = UiTargetResolver.resolveForTest(
        isWeb: false, platform: TargetPlatform.android, width: 390,
      );
      for (final name in [
        AppRoutes.settingsLanguage,
        AppRoutes.settingsTheme,
        AppRoutes.settingsStorage,
        AppRoutes.settingsAppLock,
        AppRoutes.settingsAbout,
        ...AppRoutes.panelSettings,
      ]) {
        final route = routes[name]!;
        expect(route.resolve(web), same(route.desktopShellBuilder));
        expect(route.resolve(web, useDefault: true), same(route.defaultBuilder));
        expect(route.resolve(phone), same(route.defaultBuilder));
      }
    });

    test('desktop hosts keep their shell across workspace widths', () {
      for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
        for (final (width, expected) in [
          (599.0, UiFormFactor.phone),
          (600.0, UiFormFactor.tablet),
          (1023.0, UiFormFactor.tablet),
          (1024.0, UiFormFactor.desktop),
        ]) {
          final target = UiTargetResolver.resolveForTest(
            isWeb: false, platform: platform, width: width,
          );
          expect(target.formFactor, expected);
          expect(target.usesDesktopShell, isTrue);
        }
      }
    });
  });
}
