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

  static const List<String> _uiTestExcludedPrefixes = <String>[
    'test/api/',
    'test/api_client/',
    'test/auth/',
    'test/benchmarks/',
    'test/debug/',
    'test/integration/',
    'test/scripts/',
  ];

  static Future<List<String>> _discoverAlignmentTests(
      {String? moduleFilter}) async {
    final apiClientDir = Directory('test/api_client');
    if (!await apiClientDir.exists()) {
      return const <String>[];
    }

    final normalizedFilter = moduleFilter?.toLowerCase();
    final files = await apiClientDir.list().toList();
    final tests = files
        .whereType<File>()
        .map((f) => f.path)
        .where((path) => path.endsWith('_alignment_test.dart'))
        .where((path) {
      if (normalizedFilter == null || normalizedFilter.isEmpty) {
        return true;
      }
      final name = path.split('/').last.toLowerCase();
      return name.contains(normalizedFilter);
    }).toList()
      ..sort();
    return tests;
  }

  static Future<List<String>> _discoverFeatureUnitDirs(
      {String? moduleFilter}) async {
    final featuresRoot = Directory('test/features');
    if (!await featuresRoot.exists()) {
      return const <String>[];
    }

    final normalizedFilter = moduleFilter?.toLowerCase();
    final unitDirs = <String>[];
    await for (final entity
        in featuresRoot.list(recursive: true, followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final path = entity.path.replaceAll('\\', '/');
      final isUnitDir =
          path.endsWith('/providers') || path.endsWith('/services');
      if (!isUnitDir) {
        continue;
      }
      if (!await _containsTestFiles(entity)) {
        continue;
      }
      if (normalizedFilter != null && normalizedFilter.isNotEmpty) {
        if (!path.toLowerCase().contains('/$normalizedFilter/')) {
          continue;
        }
      }
      unitDirs.add(entity.path);
    }

    unitDirs.sort();
    return unitDirs;
  }

  static Future<List<String>> _discoverUiTests() async {
    final testRoot = Directory('test');
    if (!await testRoot.exists()) {
      return const <String>[];
    }

    final uiTests = <String>[];
    await for (final entity
        in testRoot.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('_test.dart')) {
        continue;
      }

      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (_uiTestExcludedPrefixes.any(normalizedPath.startsWith)) {
        continue;
      }

      final content = await entity.readAsString();
      final isWidgetTest = content.contains('testWidgets(') ||
          content.contains('matchesGoldenFile(');
      if (!isWidgetTest) {
        continue;
      }

      uiTests.add(entity.path);
    }

    uiTests.sort();
    return uiTests;
  }

  static Future<bool> _containsTestFiles(Directory directory) async {
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        return true;
      }
    }
    return false;
  }

  static Future<void> runUnitTests({String? moduleFilter}) async {
    printHeader('运行单元测试');
    final normalizedFilter = moduleFilter?.toLowerCase();

    if (normalizedFilter == null || normalizedFilter.isEmpty) {
      await runTests('test/api/', description: 'API单元测试');
      await runTests('test/auth/', description: '认证单元测试');
    } else {
      printInfo('已启用模块过滤: $normalizedFilter');
    }

    final alignmentTests =
        await _discoverAlignmentTests(moduleFilter: normalizedFilter);
    if (alignmentTests.isEmpty) {
      printInfo('未发现匹配的 API 对齐测试');
    } else {
      for (final file in alignmentTests) {
        final name = file.split('/').last;
        await runTests(file, description: 'API对齐测试: $name');
      }
    }

    final featureUnitDirs =
        await _discoverFeatureUnitDirs(moduleFilter: normalizedFilter);
    if (featureUnitDirs.isEmpty) {
      printInfo('未发现匹配的 feature providers/services 单元测试目录');
    } else {
      for (final dir in featureUnitDirs) {
        final normalizedPath = dir.replaceAll('\\', '/');
        final name = normalizedPath
            .split('/')
            .skipWhile((e) => e != 'features')
            .toList();
        final label = name.isEmpty ? normalizedPath : name.join('/');
        await runTests(dir, description: 'Feature单测: $label');
      }
    }
  }

  static Future<void> runIntegrationTests({String? moduleFilter}) async {
    printHeader('运行集成测试');
    if (!liveApiEnabled) {
      printWarning('未开启真实API测试环境，跳过集成测试');
      printInfo('提示: 设置 RUN_LIVE_API_TESTS=true 以运行真实API测试');
      return;
    }

    final apiDir = Directory('test/api_client');
    if (await apiDir.exists()) {
      final normalizedFilter = moduleFilter?.toLowerCase();
      final files = await apiDir.list().toList();
      final testFiles = files
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('_test.dart') &&
              !f.path.contains('_alignment_test.dart'))
          .where((f) {
            if (normalizedFilter == null || normalizedFilter.isEmpty) {
              return true;
            }
            return f.path
                .split('/')
                .last
                .toLowerCase()
                .contains(normalizedFilter);
          })
          .map((f) => f.path)
          .toList();

      if (testFiles.isEmpty) {
        printInfo('未找到集成测试文件');
        return;
      }

      printInfo(
          '发现 ${testFiles.length} 个集成测试，超时时间: $liveTestTimeout，重试次数: $liveTestRetries');

      for (final testFile in testFiles) {
        final name = testFile.split('/').last;
        await runLiveTestWithRetry(testFile, description: '集成测试: $name');
      }
    }
  }

  static Future<void> runUiTests() async {
    printHeader('运行UI/Widget测试');
    final uiTests = await _discoverUiTests();
    if (uiTests.isEmpty) {
      printInfo('未发现 UI/Widget 测试文件');
      return;
    }

    printInfo('发现 ${uiTests.length} 个 UI/Widget 测试文件');
    for (final testFile in uiTests) {
      final name = testFile.split('/').last;
      await runTests(testFile, description: 'UI测试: $name');
    }
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    // ignore: avoid_print
    print('''
${TestRunner.cyan}使用方法:${TestRunner.reset}
  dart run test/scripts/test_runner.dart <command> [--module=<name>]

${TestRunner.cyan}可用命令:${TestRunner.reset}
  ${TestRunner.green}all${TestRunner.reset}         运行全量测试
  ${TestRunner.green}unit${TestRunner.reset}        仅运行单元测试
  ${TestRunner.green}integration${TestRunner.reset} 仅运行集成测试 (需要配置真实环境)
  ${TestRunner.green}ui${TestRunner.reset}          仅运行UI/Widget测试

${TestRunner.cyan}可选参数:${TestRunner.reset}
  --module=<name>      按模块名过滤 unit/integration 测试（例如: --module=ai）

${TestRunner.cyan}环境变量:${TestRunner.reset}
  FLUTTER_BIN            指定flutter可执行文件路径
  RUN_LIVE_API_TESTS     设为true启用真实API测试 (集成测试需要)
  LIVE_API_TEST_TIMEOUT  API测试超时时间 (默认: 60s)
  LIVE_API_TEST_RETRIES  API测试失败重试次数 (默认: 1)
''');
    exit(1);
  }

  final command = args[0];
  String? moduleFilter;
  for (final arg in args.skip(1)) {
    if (arg.startsWith('--module=')) {
      moduleFilter = arg.substring('--module='.length).trim();
    }
  }

  switch (command) {
    case 'all':
      await TestRunner.runAllTests();
      break;
    case 'unit':
      await TestRunner.runUnitTests(moduleFilter: moduleFilter);
      break;
    case 'integration':
      await TestRunner.runIntegrationTests(moduleFilter: moduleFilter);
      break;
    case 'ui':
      await TestRunner.runUiTests();
      break;
    default:
      TestRunner.printError('未知的命令: $command');
      exit(1);
  }
}
