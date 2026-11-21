import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/platform/services/ohos_platform_channel.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OHOS picker fix - regression coverage', () {
    const channel = MethodChannel(OhosPlatformChannel.channelName);

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'picker-on path routes through pickAndSaveBytesByKind (document kind)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'app_use_file_picker_for_file_operations': true,
        });

        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'pickAndSaveBytesByKind') {
            return <String, Object?>{
              'uri': 'content://com.example/documents/abc/logs.txt',
              'displayName': 'logs.txt',
              'kind': 'pickerUri',
            };
          }
          return null;
        });

        final service = PlatformFileService(
          capabilities: PlatformCapabilities.resolveForTest(
            isWeb: false,
            targetPlatform: TargetPlatform.android,
            operatingSystem: 'ohos',
          ),
          ohosChannel: const OhosPlatformChannel(channel: channel),
        );

        final outcome = await service.saveBytesStructured(
          fileName: 'logs.txt',
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          mimeType: 'text/plain',
        );

        expect(outcome.uri, 'content://com.example/documents/abc/logs.txt');
        expect(outcome.displayName, 'logs.txt');
        expect(outcome.kind, SaveLocationKind.pickerUri);
        expect(calls.single.method, 'pickAndSaveBytesByKind');
        expect(calls.single.arguments['mimeKind'], 'document');
        expect(calls.single.arguments['fileName'], 'logs.txt');
      },
    );

    test('picker cancel returns a cancelled outcome, not an error', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_use_file_picker_for_file_operations': true,
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'pickAndSaveBytesByKind') {
          return null; // user pressed Cancel in DocumentViewPicker
        }
        return null;
      });

      final service = PlatformFileService(
        capabilities: PlatformCapabilities.resolveForTest(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
          operatingSystem: 'ohos',
        ),
        ohosChannel: const OhosPlatformChannel(channel: channel),
      );

      final outcome = await service.saveBytesStructured(
        fileName: 'logs.txt',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'text/plain',
      );

      expect(outcome.isCancelled, isTrue);
      expect(outcome.kind, SaveLocationKind.other);
    });

    test('picker-off path writes to public Downloads category', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_use_file_picker_for_file_operations': false,
      });

      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'saveBytesToPublicDownload') {
          return <String, Object?>{
            'uri':
                '/data/storage/el2/base/files/exports/logs/logs_20260603.txt',
            'displayName': 'logs_20260603.txt',
            'kind': 'publicDownloadDir',
            'category': 'logs',
          };
        }
        return null;
      });

      final service = PlatformFileService(
        capabilities: PlatformCapabilities.resolveForTest(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
          operatingSystem: 'ohos',
        ),
        ohosChannel: const OhosPlatformChannel(channel: channel),
      );

      final outcome = await service.saveBytesStructured(
        fileName: 'logs_20260603.txt',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'text/plain',
        category: 'logs',
      );

      expect(calls.single.method, 'saveBytesToPublicDownload');
      expect(calls.single.arguments['category'], 'logs');
      expect(outcome.kind, SaveLocationKind.publicDownloadDir);
      expect(outcome.uri, contains('/exports/logs/'));
    });

    test('image MIME routes to image_video picker kind', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_use_file_picker_for_file_operations': true,
      });

      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'pickAndSaveBytesByKind') {
          return <String, Object?>{
            'uri': 'content://media/external/images/42',
            'displayName': 'IMG_20260603.png',
            'kind': 'pickerUri',
          };
        }
        return null;
      });

      final service = PlatformFileService(
        capabilities: PlatformCapabilities.resolveForTest(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
          operatingSystem: 'ohos',
        ),
        ohosChannel: const OhosPlatformChannel(channel: channel),
      );

      await service.saveBytesStructured(
        fileName: 'IMG_20260603.png',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'image/png',
      );

      expect(calls.single.arguments['mimeKind'], 'image_video');
    });

    test('audio MIME routes to audio picker kind', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_use_file_picker_for_file_operations': true,
      });

      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'pickAndSaveBytesByKind') {
          return <String, Object?>{
            'uri': 'content://media/external/audio/42',
            'displayName': 'recording.m4a',
            'kind': 'pickerUri',
          };
        }
        return null;
      });

      final service = PlatformFileService(
        capabilities: PlatformCapabilities.resolveForTest(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
          operatingSystem: 'ohos',
        ),
        ohosChannel: const OhosPlatformChannel(channel: channel),
      );

      await service.saveBytesStructured(
        fileName: 'recording.m4a',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'audio/mp4',
      );

      expect(calls.single.arguments['mimeKind'], 'audio');
    });

    test(
      'native picker failure surfaces private fallback (no silent success)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'app_use_file_picker_for_file_operations': true,
        });

        final tempDir = await Directory.systemTemp.createTemp(
          'onepanel_picker_fallback_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          // OHOS picker throws — used to silently fall back to private dir
          // without telling the user. The new behavior still falls back,
          // but flags `privateFallbackUsed` so the UI can warn.
          throw PlatformException(code: 'ohos_platform_error');
        });

        final service = PlatformFileService(
          capabilities: PlatformCapabilities.resolveForTest(
            isWeb: false,
            targetPlatform: TargetPlatform.android,
            operatingSystem: 'ohos',
          ),
          ohosChannel: const OhosPlatformChannel(channel: channel),
          fallbackDirectoryResolver: () async => tempDir,
        );

        final outcome = await service.saveBytesStructured(
          fileName: 'logs.txt',
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          mimeType: 'text/plain',
        );

        expect(outcome.privateFallbackUsed, isTrue);
        expect(outcome.kind, SaveLocationKind.privateFallback);
        expect(outcome.uri, isNotEmpty);
      },
    );

    test('AppPreferencesService defaults to picker-on when unset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = AppPreferencesService();
      final value = await prefs.loadUseFilePickerForFileOperations();
      expect(value, isTrue);
    });

    test('AppPreferencesService persists picker toggle off', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = AppPreferencesService();
      await prefs.saveUseFilePickerForFileOperations(false);
      // Re-read to verify the write went through.
      final value = await prefs.loadUseFilePickerForFileOperations();
      expect(value, isFalse);
    });

    test('picker URI is opened through openUri (not openPath)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'openUri') return true;
        if (call.method == 'openPath') return true;
        return null;
      });

      final service = PlatformFileService(
        capabilities: PlatformCapabilities.resolveForTest(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
          operatingSystem: 'ohos',
        ),
        ohosChannel: const OhosPlatformChannel(channel: channel),
      );

      final outcome = SaveOutcome(
        uri: 'content://com.example/documents/abc/logs.txt',
        displayName: 'logs.txt',
        kind: SaveLocationKind.pickerUri,
      );

      final opened = await service.openSaveOutcome(outcome);
      expect(opened, isTrue);
      expect(calls.single.method, 'openUri');
      expect(calls.single.arguments['uri'],
          'content://com.example/documents/abc/logs.txt');
    });

    test('filesystem path fallback uses openPath not openUri', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'openPath') return true;
        return null;
      });

      final service = PlatformFileService(
        capabilities: PlatformCapabilities.resolveForTest(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
          operatingSystem: 'ohos',
        ),
        ohosChannel: const OhosPlatformChannel(channel: channel),
      );

      final outcome = SaveOutcome(
        uri: '/data/storage/el2/base/files/exports/logs/logs.txt',
        displayName: 'logs.txt',
        kind: SaveLocationKind.publicDownloadDir,
      );

      final opened = await service.openSaveOutcome(outcome);
      expect(opened, isTrue);
      expect(calls.single.method, 'openPath');
    });
  });
}
