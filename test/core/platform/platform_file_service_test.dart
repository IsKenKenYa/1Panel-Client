import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/platform/services/ohos_platform_channel.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformFileService', () {
    const channel = MethodChannel(OhosPlatformChannel.channelName);

    setUp(() {
      // Default to picker-on so OHOS routes through the kind-aware picker
      // channel, matching the post-fix behavior.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_use_file_picker_for_file_operations': true,
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('uses OHOS native picker channel before falling back', () async {
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

      final path = await service.saveBytes(
        fileName: 'logs.txt',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'text/plain',
      );

      expect(path, 'content://com.example/documents/abc/logs.txt');
      expect(calls.single.method, 'pickAndSaveBytesByKind');
      expect(calls.single.arguments['fileName'], 'logs.txt');
    });

    test(
      'falls back to app export directory when every OHOS save channel fails',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'onepanel_platform_file_service_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        // The mock throws on every call. The new flow tries the picker
        // first, then the public download channel, then the Dart-side
        // fallback. The test verifies the final fallback path is used
        // and the file is written.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'native_save_failed');
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

        final path = await service.saveBytes(
          fileName: 'a/b:logs.txt',
          bytes: Uint8List.fromList(<int>[4, 5, 6]),
        );

        expect(path, endsWith('a_b_logs.txt'));
        expect(await File(path).readAsBytes(), <int>[4, 5, 6]);
      },
    );

    test('openFile throws FileSystemException when file does not exist',
        () async {
      final service = PlatformFileService(
        capabilities: PlatformCapabilities.resolveForTest(
          isWeb: false,
          targetPlatform: TargetPlatform.android,
          operatingSystem: 'ohos',
        ),
        ohosChannel: const OhosPlatformChannel(channel: channel),
      );

      expect(
        () => service.openFile('/nonexistent/path/file.txt'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('openFile delegates to OHOS openPath on OHOS platform', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'onepanel_open_file_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final tempFile = File('${tempDir.path}/test.txt');
      await tempFile.writeAsString('test content');

      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'openPath') {
          return true;
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

      await service.openFile(tempFile.path);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'openPath');
      expect(calls.single.arguments['path'], tempFile.path);
    });
  });
}
