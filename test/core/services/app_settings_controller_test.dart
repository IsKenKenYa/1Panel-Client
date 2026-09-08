import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';

/// B24 回归：冷启动宿主缺失（C++ bootstrap 置 ONEPANEL_FORCE_MD3=1）时，
/// 装配层标记 nativeHostMissing，设置页据此展示「已回退 MDUI3」状态行。
void main() {
  group('AppSettingsController.nativeHostMissing', () {
    test('defaults to false and notifies once when marked', () {
      final controller = AppSettingsController();
      expect(controller.nativeHostMissing, isFalse);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.markNativeHostMissing();
      expect(controller.nativeHostMissing, isTrue);
      expect(notifications, 1);
    });

    test('marking twice with the same value does not re-notify', () {
      final controller = AppSettingsController()..markNativeHostMissing();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.markNativeHostMissing();
      expect(notifications, 0);
    });
  });
}
