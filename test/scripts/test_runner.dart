import 'dart:io';

class TestRunner {
  static const String flutterFallbackPath =
      '/Volumes/FanXiangMac/DevTools/Flutter/flutter/bin/flutter';
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String cyan = '\x1B[36m';

  static void printColor(String message, String color) {
    stdout.writeln('$color$message$reset');
  }

  static void printHeader(String title) {
    stdout.writeln('');
    stdout.writeln('$blue========================================$reset');
    stdout.writeln('$blue$title$reset');
    stdout.writeln('$blue========================================$reset');
    stdout.writeln('');
  }

  static void printSuccess(String message) {
    printColor('✅ $message', green);
  }

  static void printError(String message) {
    printColor('❌ $message', red);
  }

  static void printWarning(String message) {
    printColor('⚠️  $message', yellow);
  }

  static void printInfo(String message) {
    printColor('ℹ️  $message', cyan);
  }

  static Future<int> runCommand(String command, List<String> args) async {
    final result = await Process.run(command, args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    return result.exitCode;
  }

  static Future<String> resolveFlutterCommand() async {
    final configured = Platform.environment['FLUTTER_BIN'];
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    final fallback = File(flutterFallbackPath);
    if (await fallback.exists()) {
      return fallback.path;
    }
    return 'flutter';
  }

  static Future<void> runTests(String testPath, {String? description}) async {
    if (description != null) {
      printHeader(description);
    }

    final flutter = await resolveFlutterCommand();
    final exitCode =
        await runCommand(flutter, ['test', testPath, '--reporter=expanded']);

    if (exitCode == 0) {
      printSuccess('测试通过');
    } else {
      printError('测试失败 (退出码: $exitCode)');
    }
  }

  static String get liveTestTimeout {
    final raw = Platform.environment['LIVE_API_TEST_TIMEOUT'];
    if (raw == null || raw.isEmpty) {
      return '60s';
    }
    return raw;
  }

  static int get liveTestRetries {
    final raw = Platform.environment['LIVE_API_TEST_RETRIES'];
    final retries = int.tryParse(raw ?? '1') ?? 1;
    return retries < 1 ? 1 : retries;
  }

  static bool get liveApiEnabled {
    final raw = Platform.environment['RUN_LIVE_API_TESTS']?.toLowerCase();
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  static Future<void> runLiveTestWithRetry(
    String testPath, {
    String? description,
  }) async {
    if (description != null) {
      printHeader(description);
    }

    final flutter = await resolveFlutterCommand();
    var attempt = 0;
    var success = false;

    while (attempt < liveTestRetries && !success) {
      attempt++;
      if (attempt > 1) {
        printWarning('重试 $attempt/$liveTestRetries: $testPath');
      }

      final exitCode = await runCommand(flutter, [
        'test',
        testPath,
        '--reporter=expanded',
        '--timeout=$liveTestTimeout',
      ]);

      success = exitCode == 0;
      if (!success && attempt < liveTestRetries) {
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }

    if (success) {
      printSuccess('测试通过');
    } else {
      printError('测试失败 (重试后仍未通过)');
    }
  }

  static Future<void> runAllTests() async {
    printHeader('运行全量回归测试');
    final flutter = await resolveFlutterCommand();
    await runCommand(flutter, ['test', '--reporter=expanded']);
  }

  static Future<void> runUnitTests() async {
    printHeader('运行单元测试');
    await runTests('test/api/', description: 'API单元测试');
    await runTests('test/auth/', description: '认证单元测试');
    final phase1ApiFile =
        File('test/api_client/phase1_api_alignment_test.dart');
    if (await phase1ApiFile.exists()) {
      await runTests(
        'test/api_client/phase1_api_alignment_test.dart',
        description: 'Phase 1 API对齐测试',
      );
    }
    final groupServiceDir = Directory('test/features/group/services');
    if (await groupServiceDir.exists()) {
      await runTests(
        'test/features/group/services/',
        description: 'Group Service测试',
      );
    }
    final groupProviderDir = Directory('test/features/group/providers');
    if (await groupProviderDir.exists()) {
      await runTests(
        'test/features/group/providers/',
        description: 'Group Provider测试',
      );
    }
    final commandsProviderDir = Directory('test/features/commands/providers');
    if (await commandsProviderDir.exists()) {
      await runTests(
        'test/features/commands/providers/',
        description: 'Commands Provider测试',
      );
    }
    final hostAssetsProviderDir =
        Directory('test/features/host_assets/providers');
    if (await hostAssetsProviderDir.exists()) {
      await runTests(
        'test/features/host_assets/providers/',
        description: 'Host Assets Provider测试',
      );
    }
    final sshProviderDir = Directory('test/features/ssh/providers');
    if (await sshProviderDir.exists()) {
      await runTests(
        'test/features/ssh/providers/',
        description: 'SSH Provider测试',
      );
    }
    final processProviderDir = Directory('test/features/processes/providers');
    if (await processProviderDir.exists()) {
      await runTests(
        'test/features/processes/providers/',
        description: 'Process Provider测试',
      );
    }
    final cronjobsProviderDir = Directory('test/features/cronjobs/providers');
    if (await cronjobsProviderDir.exists()) {
      await runTests(
        'test/features/cronjobs/providers/',
        description: 'Cronjob Provider测试',
      );
    }
    final filesProviderDir = Directory('test/features/files/providers');
    if (await filesProviderDir.exists()) {
      await runTests(
        'test/features/files/providers/',
        description: 'Files Provider测试',
      );
    }
  }

  static Future<void> runIntegrationTests() async {
    printHeader('运行集成测试');
    if (!liveApiEnabled) {
      printWarning('未开启真实API测试环境，跳过集成测试');
      printInfo('提示: 设置 RUN_LIVE_API_TESTS=true 以运行真实API测试');
      return;
    }

    final apiDir = Directory('test/api_client');
    if (await apiDir.exists()) {
      final files = await apiDir.list().toList();
      final testFiles = files
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('_test.dart') &&
              !f.path.contains('phase1_api_alignment_test.dart'))
          .map((f) => f.path)
          .toList();

      if (testFiles.isEmpty) {
        printInfo('未找到集成测试文件');
        return;
      }

      printInfo('发现 ${testFiles.length} 个集成测试，超时时间: $liveTestTimeout，重试次数: $liveTestRetries');

      for (final testFile in testFiles) {
        final name = testFile.split('/').last;
        await runLiveTestWithRetry(testFile, description: '集成测试: $name');
      }
    }
  }

  static Future<void> runUiTests() async {
    printHeader('运行UI/Widget测试');
    await runTests('test/', description: '所有测试 (包含UI组件测试)');
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    // ignore: avoid_print
    print('''
${TestRunner.cyan}使用方法:${TestRunner.reset}
  dart run test/scripts/test_runner.dart <command>

${TestRunner.cyan}可用命令:${TestRunner.reset}
  ${TestRunner.green}all${TestRunner.reset}         运行全量测试
  ${TestRunner.green}unit${TestRunner.reset}        仅运行单元测试
  ${TestRunner.green}integration${TestRunner.reset} 仅运行集成测试 (需要配置真实环境)
  ${TestRunner.green}ui${TestRunner.reset}          仅运行UI/Widget测试

${TestRunner.cyan}环境变量:${TestRunner.reset}
  FLUTTER_BIN            指定flutter可执行文件路径
  RUN_LIVE_API_TESTS     设为true启用真实API测试 (集成测试需要)
  LIVE_API_TEST_TIMEOUT  API测试超时时间 (默认: 60s)
  LIVE_API_TEST_RETRIES  API测试失败重试次数 (默认: 1)
''');
    exit(1);
  }

  final command = args[0];
  switch (command) {
    case 'all':
      await TestRunner.runAllTests();
      break;
    case 'unit':
      await TestRunner.runUnitTests();
      break;
    case 'integration':
      await TestRunner.runIntegrationTests();
      break;
    case 'ui':
      await TestRunner.runUiTests();
      break;
    default:
      TestRunner.printError('未知的命令: $command');
      exit(1);
  }
}
