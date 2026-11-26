import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/channel/harmony_ui_bridge.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/platform/services/ohos_channel_names.dart';
import 'package:onepanel_client/core/platform/services/ohos_download_service.dart';
import 'package:onepanel_client/core/platform/services/ohos_platform_channel.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment('PLATFORM_CHECK_PHASE', defaultValue: 'auto');
  const platform = OhosPlatformChannel();
  const downloads = MethodChannel(OhosChannelNames.ohosDownload);

  if (phase == 'presentation') {
    testWidgets('鸿蒙前后台保留当前界面模式并遵循应用锁', (tester) async {
      NativeChannelManager.init();
      final navigator = GlobalKey<NavigatorState>();
      var requiresUnlock = false;
      final bridge = HarmonyUIBridge(
        navigatorKey: navigator,
        refreshSettings: () async {},
        requiresUnlock: (_) => requiresUnlock,
      );
      addTearDown(bridge.dispose);

      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [bridge],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(),
        ),
      ));
      unawaited(navigator.currentState!.pushReplacementNamed<void, void>(
        AppRoutes.home,
      ));
      await tester.pumpAndSettle();
      bridge.updatePresentation(
        mode: UIRenderMode.native,
        locale: null,
        themeMode: ThemeMode.system,
      );
      bridge.setGateVisible(true);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.resumed,
      ]) {
        bridge.didChangeAppLifecycleState(state);
        expect(bridge.isNativeVisible, isTrue, reason: state.name);
      }

      bridge.didChangeAppLifecycleState(AppLifecycleState.paused);
      requiresUnlock = true;
      bridge.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(bridge.isNativeVisible, isFalse);
      requiresUnlock = false;
      bridge.setGateVisible(true);
      expect(bridge.isNativeVisible, isTrue);

      bridge.updatePresentation(
        mode: UIRenderMode.md3,
        locale: null,
        themeMode: ThemeMode.system,
      );
      bridge.setGateVisible(true);
      bridge.didChangeAppLifecycleState(AppLifecycleState.paused);
      bridge.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(bridge.isNativeVisible, isFalse);
      await tester.pump();
    });
    return;
  }

  testWidgets('鸿蒙文件保存与下载生命周期（$phase）', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('HarmonyOS 平台功能验证'))),
    ));
    final runtime = await platform.getRuntimeInfo();
    final files = runtime['appFilesDir'] as String;
    final directory = await Directory(p.join(files, 'harmony_platform_lifecycle_test'))
        .create(recursive: true);
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final body = Uint8List.fromList(List<int>.generate(8192, (index) => index % 251));
    if (phase == 'interactive') {
      debugPrint('验证保存选择器取消');
      expect(await platform.pickAndSaveBytes(
        fileName: 'kenpanel-platform-test.txt',
        bytes: body,
        mimeType: 'text/plain',
      ), isNull);

      debugPrint('验证保存选择器确认');
      final saved = await platform.pickAndSaveBytes(
        fileName: 'kenpanel-platform-test.txt',
        bytes: body,
        mimeType: 'text/plain',
      );
      expect(saved?.kind, SaveLocationKind.pickerUri);

      debugPrint('验证文件选择器取消');
      final files = PlatformFileService();
      expect(await files.pickFiles(), isEmpty);

      debugPrint('验证选择已保存文件和内容');
      final selected = await files.selectFiles(
        allowedExtensions: ['txt'],
        withData: true,
      );
      final file = selected!.files.single;
      addTearDown(() => File(file.path!).parent.delete(recursive: true));
      expect(file.name, 'kenpanel-platform-test.txt');
      expect(file.bytes, orderedEquals(body));

      debugPrint('验证目录选择器取消');
      expect(await platform.pickSaveDirectory(), isNull);
    }
    if (phase == 'interactive' || phase == 'download_picker') {
      debugPrint('验证下载选择器取消');
      expect(await platform.downloadFile(
        url: 'http://127.0.0.1:9/cancelled-selection',
        savedDir: directory.path,
        fileName: 'kenpanel-platform-download-test.txt',
        usePicker: true,
      ), isNull);
      expect(await directory.list().isEmpty, isTrue);
    }
    if (phase == 'picker_cancel' || phase == 'picker_save') {
      final outcome = await platform.pickAndSaveBytesByKind(
        fileName: 'kenpanel-platform-test.txt',
        bytes: body,
        mimeKind: 'document',
        mimeType: 'text/plain',
      );
      if (phase == 'picker_cancel') {
        expect(outcome, isNull);
      } else {
        expect(outcome, isNotNull);
        expect(outcome!.uri, isNotEmpty);
        expect(await platform.openUri(outcome.uri), isTrue);
      }
      return;
    }
    if (phase == 'directory_cancel' || phase == 'directory_select') {
      final chosen = await platform.pickSaveDirectory();
      if (phase == 'directory_cancel') {
        expect(chosen, isNull);
      } else {
        expect(chosen, isNotNull);
        expect(chosen, isNotEmpty);
      }
      return;
    }
    if (phase == 'download_picker_cancel') {
      final task = await platform.downloadFile(
        url: 'http://127.0.0.1:9/cancelled-selection',
        savedDir: directory.path,
        fileName: 'kenpanel-platform-download-test.txt',
        usePicker: true,
      );
      expect(task, isNull);
      expect(await directory.list().isEmpty, isTrue);
      return;
    }
    expect(phase, anyOf('auto', 'interactive', 'download_picker', 'background'));

    final savedPath = await platform.saveBytes(
      fileName: 'kenpanel-platform-test.txt',
      bytes: body,
      mimeType: 'text/plain',
    );
    final savedFile = File(savedPath);
    addTearDown(() async {
      if (await savedFile.exists()) await savedFile.delete();
    });
    expect(await savedFile.readAsBytes(), orderedEquals(body));
    final outcome = await platform.saveBytesToPublicDownload(
      fileName: 'kenpanel-platform-download-test.txt',
      bytes: body,
      category: 'files',
      subDir: 'harmony_platform_lifecycle_test',
    );
    final exported = File(outcome.uri);
    addTearDown(() async {
      if (await exported.exists()) await exported.delete();
      final parent = exported.parent;
      if (await parent.exists() && await parent.list().isEmpty) {
        await parent.delete();
      }
    });
    expect(await exported.readAsBytes(), orderedEquals(body));

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final serverRequests = <String>[];
    final serverErrors = <Object>[];
    server.listen((request) {
      serverRequests.add(request.uri.path);
      unawaited(_serveDownload(request, body).catchError((Object error) {
        if (error is! SocketException && error is! HttpException) {
          serverErrors.add(error);
        }
      }));
    });
    final service = OhosDownloadService.defaultChannels(PlatformFileService());
    final events = <OhosDownloadProgress>[];
    final subscription = service.onProgress.listen(events.add);
    addTearDown(() async {
      await subscription.cancel();
      service.dispose();
    });
    final tasks = <String>[];
    addTearDown(() async {
      final existing = await service.listTasks();
      for (final task in existing.where((task) => tasks.contains(task.id))) {
        await service.delete(task.id);
      }
    });

    Future<String> enqueue(String name, String path) async {
      final task = await platform.downloadFile(
        url: 'http://127.0.0.1:${server.port}/$path',
        savedDir: directory.path,
        fileName: name,
        headers: const {'X-KenPanel-Platform-Test': 'real-download'},
        usePicker: false,
      );
      expect(task, isNotNull);
      tasks.add(task!);
      return task;
    }

    final completed = await enqueue('completed.bin', 'complete');
    await _waitForTask(downloads, completed,
        (task) => task['status'] == 'completed');
    final completedPath = await service.saveDownloadedFile(completed);
    expect(completedPath, p.join(directory.path, 'completed.bin'));
    expect(await File(completedPath!).readAsBytes(), orderedEquals(body));
    final listed = (await service.listTasks()).singleWhere((task) => task.id == completed);
    expect(listed.status, 'completed');
    expect(listed.progress, 100);
    await service.delete(completed);
    expect((await service.listTasks()).any((task) => task.id == completed), isFalse);
    expect(await File(completedPath).exists(), isTrue);

    final paused = await enqueue('paused.bin', 'slow');
    await _waitForTask(downloads, paused,
        (task) => (task['bytesReceived'] as int) > 0);
    await service.pause(paused);
    final pausedState = await _waitForTask(downloads, paused,
        (task) => task['status'] == 'paused');
    final pausedBytes = pausedState['bytesReceived'];
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final stillPaused = await downloads.invokeMapMethod<String, Object?>(
      'getProgress', {'taskId': paused},
    );
    expect(stillPaused!['status'], 'paused');
    expect(stillPaused['bytesReceived'], pausedBytes);
    await service.resume(paused);
    await _waitForTask(downloads, paused,
        (task) => task['status'] == 'completed');
    final pauseResult = await File(p.join(directory.path, 'paused.bin')).readAsBytes();
    expect(pauseResult.length, body.length * 256);
    final expectedDownload = List<int>.generate(
      body.length * 256,
      (index) => body[index % body.length],
    );
    expect(pauseResult, orderedEquals(expectedDownload));

    final cancelled = await enqueue('cancelled.bin', 'slow');
    await _waitForTask(downloads, cancelled,
        (task) => (task['bytesReceived'] as int) > 0);
    await service.cancel(cancelled);
    expect((await service.listTasks()).any((task) => task.id == cancelled), isFalse);
    expect(await File(p.join(directory.path, 'cancelled.bin')).exists(), isFalse);

    final deleted = await enqueue('deleted.bin', 'slow');
    await _waitForTask(downloads, deleted,
        (task) => (task['bytesReceived'] as int) > 0);
    await service.delete(deleted);
    expect((await service.listTasks()).any((task) => task.id == deleted), isFalse);
    expect(await File(p.join(directory.path, 'deleted.bin')).exists(), isFalse);
    final failed = await enqueue('failed.bin', 'missing');
    await _waitForTask(downloads, failed, (task) => task['status'] == 'failed');
    expect(await service.saveDownloadedFile(failed), isNull);
    expect(events.any((event) => event.taskId == paused && event.status == 'paused'), isTrue);
    expect(events.any((event) => event.taskId == completed && event.status == 'completed'), isTrue);
    expect(serverRequests, contains('/complete'));
    expect(serverErrors, isEmpty);

    if (phase == 'interactive' || phase == 'download_picker') {
      debugPrint('验证选择下载保存位置');
      final pickedDownload = await platform.downloadFile(
        url: 'http://127.0.0.1:${server.port}/complete',
        savedDir: directory.path,
        fileName: 'kenpanel-platform-download-test.txt',
        headers: const {'X-KenPanel-Platform-Test': 'real-download'},
        usePicker: true,
      );
      tasks.add(pickedDownload!);
      await _waitForTask(downloads, pickedDownload,
          (task) => task['status'] == 'completed');
      expect(Uri.parse((await service.saveDownloadedFile(pickedDownload))!).hasScheme,
          isTrue);

      debugPrint('验证选择已下载文件和内容');
      final selectedPath = await PlatformFileService().pickFile();
      final file = File(selectedPath!);
      addTearDown(() => file.parent.delete(recursive: true));
      expect(p.basename(file.path), 'kenpanel-platform-download-test.txt');
      expect(await file.readAsBytes(), orderedEquals(body));
    }

    if (phase == 'background') {
      final background = await enqueue('background.bin', 'background');
      await _waitForTask(downloads, background,
          (task) => (task['bytesReceived'] as int) > 0);
      debugPrint('验证下载期间切换至系统桌面');
      await _waitForTask(downloads, background,
          (task) => task['status'] == 'completed');
      expect(await File(p.join(directory.path, 'background.bin')).readAsBytes(),
          orderedEquals(expectedDownload));
      debugPrint('后台下载输出已核对');
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}

Future<Map<String, Object?>> _waitForTask(
  MethodChannel channel,
  String taskId,
  bool Function(Map<String, Object?> task) ready,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (DateTime.now().isBefore(deadline)) {
    final task = await channel.invokeMapMethod<String, Object?>(
      'getProgress', {'taskId': taskId},
    );
    if (task == null) throw StateError('下载任务不存在：$taskId');
    if (ready(task)) return task;
    if (task['status'] == 'failed') throw StateError('下载任务失败：$taskId');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw TimeoutException('下载任务未达到预期状态', const Duration(seconds: 60));
}

Future<void> _serveDownload(HttpRequest request, Uint8List bytes) async {
  if (request.headers.value('X-KenPanel-Platform-Test') != 'real-download') {
    request.response.statusCode = HttpStatus.unauthorized;
    await request.response.close();
    return;
  }
  if (request.uri.path == '/missing') {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
    return;
  }
  request.response.headers.contentType = ContentType.binary;
  final background = request.uri.path == '/background';
  final slow = background || request.uri.path == '/slow';
  final count = slow ? 256 : 1;
  request.response.contentLength = bytes.length * count;
  for (var index = 0; index < count; index++) {
    request.response.add(bytes);
    await request.response.flush();
    if (background && index == 0) {
      await Future<void>.delayed(const Duration(seconds: 20));
    }
    if (slow) await Future<void>.delayed(const Duration(milliseconds: 30));
  }
  await request.response.close();
}
