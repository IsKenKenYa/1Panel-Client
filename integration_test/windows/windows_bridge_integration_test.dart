import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/core/channel/windows/windows_capability_whitelist.dart';
import 'package:onepanel_client/core/channel/windows/windows_shell_bridge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final isWindows = Platform.isWindows;
  final bridge = WindowsShellBridge(
    isSupportedPlatform: () => Platform.isWindows,
  );

  group('windows bridge integration', () {
    testWidgets(
      'window commands return success and state changes are observable',
      (tester) async {
        final capabilities = await bridge.getCapabilities();
        expect(capabilities.nativeHostAvailable, isTrue);
        expect(capabilities.supportsWindowCommands, isTrue);

        final minimized = await bridge.performWindowCommand(
          WindowsWindowCommand.minimize,
        );
        expect(minimized, isTrue);
        await tester.pump(const Duration(milliseconds: 250));

        final stateAfterMinimize = await bridge.getWindowState();
        expect(stateAfterMinimize.isMinimized, isTrue);

        final restored = await bridge.performWindowCommand(
          WindowsWindowCommand.restore,
        );
        expect(restored, isTrue);
        await tester.pump(const Duration(milliseconds: 250));

        final stateAfterRestore = await bridge.getWindowState();
        expect(stateAfterRestore.isMinimized, isFalse);

        final topMostOn = await bridge.performWindowCommand(
          WindowsWindowCommand.setAlwaysOnTop,
          enabled: true,
        );
        expect(topMostOn, isTrue);
        await tester.pump(const Duration(milliseconds: 150));

        final stateAfterTopMostOn = await bridge.getWindowState();
        expect(stateAfterTopMostOn.isAlwaysOnTop, isTrue);

        final topMostOff = await bridge.performWindowCommand(
          WindowsWindowCommand.setAlwaysOnTop,
          enabled: false,
        );
        expect(topMostOff, isTrue);
      },
      skip: !isWindows,
    );

    testWidgets(
      'toast path falls back to tray when toast permission is disabled',
      (tester) async {
        final permissionsSet = await bridge.setNotificationPermission(
          toastAllowed: false,
          trayAllowed: true,
        );
        expect(permissionsSet, isTrue);

        final toastResult = await bridge.showToast(
          title: 'Bridge Integration',
          message: 'toast fallback check',
        );
        expect(toastResult, isTrue);

        final resetPermissions = await bridge.setNotificationPermission(
          toastAllowed: true,
          trayAllowed: true,
        );
        expect(resetPermissions, isTrue);

        await bridge.performTrayCommand(WindowsTrayCommand.dispose);
      },
      skip: !isWindows,
    );
  });
}
