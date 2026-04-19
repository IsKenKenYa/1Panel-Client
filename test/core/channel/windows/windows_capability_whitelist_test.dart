import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/windows/windows_capability_whitelist.dart';

void main() {
  group('WindowsCapabilityWhitelist', () {
    test('bridge-owned capability set includes tray and toast', () {
      expect(
        WindowsCapabilityWhitelist.isCapabilityBridgeOwned(
          WindowsNativeCapability.tray,
        ),
        isTrue,
      );
      expect(
        WindowsCapabilityWhitelist.isCapabilityBridgeOwned(
          WindowsNativeCapability.toast,
        ),
        isTrue,
      );
      expect(
        WindowsCapabilityWhitelist.isCapabilityBridgeOwned(
          WindowsNativeCapability.systemBackdrop,
        ),
        isFalse,
      );
    });

    test('rejects non-whitelisted raw window commands', () {
      expect(
        WindowsCapabilityWhitelist.canInvokeRawWindowCommand('unknown_cmd'),
        isFalse,
      );
      expect(
        WindowsCapabilityWhitelist.canInvokeRawWindowCommand('maximize'),
        isTrue,
      );
      expect(
        WindowsCapabilityWhitelist.canInvokeRawWindowCommand(
          'set_system_backdrop',
        ),
        isTrue,
      );
    });

    test('validates system backdrop mode whitelist', () {
      expect(
        WindowsCapabilityWhitelist.canInvokeRawSystemBackdropMode('mica'),
        isTrue,
      );
      expect(
        WindowsCapabilityWhitelist.canInvokeRawSystemBackdropMode('acrylic'),
        isTrue,
      );
      expect(
        WindowsCapabilityWhitelist.canInvokeRawSystemBackdropMode('glassy'),
        isFalse,
      );
    });

    test('rejects non-whitelisted raw tray commands', () {
      expect(
        WindowsCapabilityWhitelist.canInvokeRawTrayCommand('toast_popup'),
        isFalse,
      );
      expect(
        WindowsCapabilityWhitelist.canInvokeRawTrayCommand('initialize'),
        isTrue,
      );
    });
  });
}
