import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/windows/windows_shell_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('onepanel/windows_bridge');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('WindowsShellBridge', () {
    test('platform gate returns fallback and skips channel calls', () async {
      var invokeCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        invokeCount++;
        return true;
      });

      final bridge = WindowsShellBridge(
        channel: channel,
        isSupportedPlatform: () => false,
      );

      final snapshot = await bridge.getCapabilities();
      expect(snapshot.nativeHostAvailable, isFalse);
      expect(invokeCount, 0);
    });

    test('blocks raw non-whitelisted window command before invoke', () async {
      var invokeCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        invokeCount++;
        return true;
      });

      final bridge = WindowsShellBridge(
        channel: channel,
        isSupportedPlatform: () => true,
      );

      final result = await bridge.performWindowCommandRaw('shutdown_pc');
      expect(result, isFalse);
      expect(invokeCount, 0);
    });

    test('snapshot parser falls back on invalid map values', () {
      final snapshot = WindowsCapabilitySnapshot.fromMap(
        const {
          'nativeHostAvailable': 'yes',
          'windowCommands': 1,
          'toast': null,
          'toastPermissionGranted': 'true',
          'trayPermissionGranted': 0,
        },
      );

      expect(snapshot.nativeHostAvailable, isFalse);
      expect(snapshot.supportsWindowCommands, isFalse);
      expect(snapshot.supportsToast, isFalse);
      expect(snapshot.toastPermissionGranted, isFalse);
      expect(snapshot.trayPermissionGranted, isFalse);
    });

    test('toast permission denied falls back to tray balloon', () async {
      var showToastCalls = 0;
      var trayInitCalls = 0;
      var trayBalloonCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        switch (methodCall.method) {
          case 'getCapabilities':
            return {
              'nativeHostAvailable': true,
              'windowCommands': true,
              'alwaysOnTop': true,
              'systemBackdrop': false,
              'tray': true,
              'jumpList': false,
              'toast': true,
              'fileAssociation': false,
              'toastPermissionGranted': false,
              'trayPermissionGranted': true,
            };
          case 'showToast':
            showToastCalls++;
            return false;
          case 'performTrayCommand':
            final command = (methodCall.arguments as Map)['command'];
            if (command == 'initialize') {
              trayInitCalls++;
            }
            return true;
          case 'showTrayBalloon':
            trayBalloonCalls++;
            return true;
          default:
            return false;
        }
      });

      final bridge = WindowsShellBridge(
        channel: channel,
        isSupportedPlatform: () => true,
      );

      final ok = await bridge.showToast(title: 'title', message: 'message');
      expect(ok, isTrue);
      expect(showToastCalls, 0);
      expect(trayInitCalls, 1);
      expect(trayBalloonCalls, 1);
    });

    test('toast failure uses tray fallback when allowed', () async {
      var showToastCalls = 0;
      var trayBalloonCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        switch (methodCall.method) {
          case 'getCapabilities':
            return {
              'nativeHostAvailable': true,
              'windowCommands': true,
              'alwaysOnTop': true,
              'systemBackdrop': false,
              'tray': true,
              'jumpList': false,
              'toast': true,
              'fileAssociation': false,
              'toastPermissionGranted': true,
              'trayPermissionGranted': true,
            };
          case 'showToast':
            showToastCalls++;
            return false;
          case 'performTrayCommand':
            return true;
          case 'showTrayBalloon':
            trayBalloonCalls++;
            return true;
          default:
            return false;
        }
      });

      final bridge = WindowsShellBridge(
        channel: channel,
        isSupportedPlatform: () => true,
      );

      final ok = await bridge.showToast(
        title: 'fallback',
        message: 'notification',
      );
      expect(ok, isTrue);
      expect(showToastCalls, 1);
      expect(trayBalloonCalls, 1);
    });

    test('window state parser falls back on invalid map values', () {
      final state = WindowsWindowState.fromMap(
        const {
          'isMinimized': 1,
          'isMaximized': 'false',
          'isAlwaysOnTop': null,
          'isVisible': 'yes',
          'systemBackdropMode': 7,
        },
      );

      expect(state.isMinimized, isFalse);
      expect(state.isMaximized, isFalse);
      expect(state.isAlwaysOnTop, isFalse);
      expect(state.isVisible, isFalse);
      expect(state.systemBackdropMode, 'unknown');
    });

    test('window command forwards backdrop payload when provided', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        capturedCall = methodCall;
        return true;
      });

      final bridge = WindowsShellBridge(
        channel: channel,
        isSupportedPlatform: () => true,
      );

      final ok = await bridge.performWindowCommandRaw(
        'set_system_backdrop',
        backdrop: 'acrylic',
      );

      expect(ok, isTrue);
      expect(capturedCall, isNotNull);
      expect(capturedCall!.method, 'performWindowCommand');
      final args = capturedCall!.arguments as Map<dynamic, dynamic>;
      expect(args['command'], 'set_system_backdrop');
      expect(args['backdrop'], 'acrylic');
    });
  });
}
