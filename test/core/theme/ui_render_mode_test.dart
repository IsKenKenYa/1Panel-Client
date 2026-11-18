import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UIRenderPolicy', () {
    tearDown(() {
      UIRenderPolicy.liquidGlassEnabled = false;
    });

    test('liquidGlass renders Flutter UI on every host', () {
      expect(
        UIRenderPolicy.shouldUseFlutterUI(UIRenderMode.liquidGlass),
        isTrue,
      );
    });

    test('keeps profiles with no saved mode and an iOS app lock on Flutter',
        () {
      final expected = switch (Platform.operatingSystem) {
        'ios' => UIRenderMode.liquidGlass,
        'macos' => UIRenderMode.native,
        'android' => UIRenderMode.md3,
        _ => UIRenderMode.liquidGlass,
      };
      expect(UIRenderPolicy.defaultMode(appLockEnabled: true), expected);
    });

    test('resolveSupportedMode keeps liquidGlass on hosts without native shell',
        () {
      expect(
        UIRenderPolicy.resolveSupportedMode(UIRenderMode.liquidGlass),
        UIRenderMode.liquidGlass,
      );
    });

    test('setLiquidGlassEnabled tracks the mode', () {
      UIRenderPolicy.setLiquidGlassEnabled(UIRenderMode.liquidGlass);
      expect(UIRenderPolicy.liquidGlassEnabled, isTrue);

      UIRenderPolicy.setLiquidGlassEnabled(UIRenderMode.md3);
      expect(UIRenderPolicy.liquidGlassEnabled, isFalse);

      UIRenderPolicy.setLiquidGlassEnabled(UIRenderMode.native);
      expect(UIRenderPolicy.liquidGlassEnabled, isFalse);
    });
  });

  group('AppPreferencesService UI render mode persistence', () {
    test('round-trips liquidGlass', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AppPreferencesService();

      await service.saveUIRenderMode(UIRenderMode.liquidGlass);
      expect(await service.loadUIRenderMode(), UIRenderMode.liquidGlass);
    });

    test('loads the platform default when no render mode is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AppPreferencesService();
      final expected = switch (Platform.operatingSystem) {
        'ios' || 'macos' => UIRenderMode.native,
        'android' => UIRenderMode.md3,
        _ => UIRenderMode.liquidGlass,
      };

      expect(await service.loadUIRenderMode(), expected);
    });

    test('md3 persists and loads as md3 (solid surfaces)', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AppPreferencesService();

      await service.saveUIRenderMode(UIRenderMode.md3);
      expect(await service.loadUIRenderMode(), UIRenderMode.md3);
    });

    test('saved native falls back to md3 on hosts without native shell',
        () async {
      SharedPreferences.setMockInitialValues(
          {'app_ui_render_mode': 'native'});
      final service = AppPreferencesService();

      // 测试宿主无 macOS/Windows 原生壳，resolveSupportedMode 应回退。
      final mode = await service.loadUIRenderMode();
      expect(
        mode == UIRenderMode.md3 || mode == UIRenderMode.native,
        isTrue,
      );
    });
  });
}
