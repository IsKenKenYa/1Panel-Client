import 'dart:io';

class TestRunner {
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

  static String get flutterCommand {
    final configured = Platform.environment['FLUTTER_BIN'];
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return Platform.isWindows ? 'flutter.bat' : 'flutter';
  }

  static String _fileName(String path) => path.replaceAll('\\', '/').split('/').last;

  static Future<bool> runTests(String testPath, {String? description}) async {
    if (description != null) {
      printHeader(description);
    }

    final exitCode =
        await runCommand(flutterCommand, ['test', testPath, '--reporter=expanded']);

    if (exitCode == 0) {
      printSuccess('测试通过');
      return true;
    }
    printError('测试失败 (退出码: $exitCode)');
    return false;
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

  /// 面板配置写入类套件（设置、快照、SSH、终端）只在破坏性模式下运行，
  /// 避免默认真服务器门禁修改测试主机的面板配置或生成快照。
  static bool get destructiveEnabled {
    final raw = Platform.environment['RUN_DESTRUCTIVE_TESTS']?.toLowerCase();
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  static bool _isPanelConfigLiveSuite(String path) {
    final name = _fileName(path).toLowerCase();
    return name.startsWith('setting') ||
        name.startsWith('snapshot') ||
        name.startsWith('panel_snapshot') ||
        name.startsWith('ssh_api_client') ||
        name.startsWith('terminal_api_client');
  }

  static Future<bool> runLiveTestWithRetry(
    String testPath, {
    String? description,
  }) async {
    if (description != null) {
      printHeader(description);
    }

    var attempt = 0;
    var success = false;

    while (attempt < liveTestRetries && !success) {
      attempt++;
      if (attempt > 1) {
        printWarning('重试 $attempt/$liveTestRetries: $testPath');
      }

      final exitCode = await runCommand(flutterCommand, [
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
    return success;
  }

  static Future<bool> runAllTests({String? moduleFilter}) async {
    printHeader('运行全量回归测试');
    // 按分档串行执行（unit -> ui -> integration），与单档门禁语义一致。
    // 不再使用单条 `flutter test` 全目录并发跑：真服务器套件并发会触发
    // 服务器限流/拦截页造成偶发假失败，且会覆盖分档各自的门控语义。
    var ok = true;

    final unitOk = await runUnitTests(moduleFilter: moduleFilter);
    if (!unitOk) ok = false;

    final uiOk = await runUiTests();
    if (!uiOk) ok = false;

    final integrationOk = await runIntegrationTests(moduleFilter: moduleFilter);
    if (!integrationOk) ok = false;

    if (ok) {
      printSuccess('全量测试通过');
    } else {
      printError('全量测试失败');
    }
    return ok;
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
      final name = _fileName(path).toLowerCase();
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

  /// 查找由单元测试命令负责的纯 Dart 测试。
  static Future<List<String>> _discoverPureDartTests(
    String dirPath, {
    bool recursive = true,
  }) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return const <String>[];
    }
    final pure = <String>[];
    await for (final entity
        in dir.list(recursive: recursive, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('_test.dart')) {
        continue;
      }
      final content = await entity.readAsString();
      if (!content.contains('testWidgets(') &&
          !content.contains('matchesGoldenFile(')) {
        pure.add(entity.path);
      }
    }
    pure.sort();
    return pure;
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

  static Future<bool> runUnitTests({String? moduleFilter}) async {
    printHeader('运行单元测试');
    printHeader('HarmonyOS 设计规范检查');
    final harmonyDesignExitCode = await runCommand(
      Platform.resolvedExecutable,
      ['run', 'test/scripts/check_harmony_design_guards.dart'],
    );
    printHeader('Flutter UI 复用与分层守卫检查');
    final flutterUiGuardExitCode = await runCommand(
      Platform.resolvedExecutable,
      ['run', 'test/scripts/check_flutter_ui_guards.dart'],
    );
    final normalizedFilter = moduleFilter?.toLowerCase();
    var failures = 0;
    if (harmonyDesignExitCode != 0) failures++;
    if (flutterUiGuardExitCode != 0) failures++;

    if (normalizedFilter == null || normalizedFilter.isEmpty) {
      final okApi = await runTests('test/api/', description: 'API单元测试');
      final okAuth = await runTests('test/auth/', description: '认证单元测试');
      if (!okApi) failures++;
      if (!okAuth) failures++;

      // 回归盲区收口：bugfix 回归测试、core 网络层单测、widget_test 中
      // 纯 Dart 断言（非 testWidgets，UI 档扫不到）也纳入 unit 门禁。
      for (final dir in const <String>['test/bugfix/', 'test/core/']) {
        final d = Directory(dir);
        if (!await d.exists()) continue;
        final ok = await runTests(dir, description: '单元测试: $dir');
        if (!ok) failures++;
      }
      final pureDartTests = await _discoverPureDartTests('test/widget_test');
      for (final file in pureDartTests) {
        final name = _fileName(file);
        final ok = await runTests(file, description: '单元测试: $name');
        if (!ok) failures++;
      }
    } else {
      printInfo('已启用模块过滤: $normalizedFilter');
    }

    for (final (module, dir) in const [
      ('panels', 'test/data/panels'),
      ('server', 'test/features/server'),
      ('shell', 'test/features/shell'),
    ]) {
      if (normalizedFilter != null &&
          normalizedFilter.isNotEmpty &&
          normalizedFilter != module) {
        continue;
      }
      for (final file in await _discoverPureDartTests(dir, recursive: false)) {
        final ok = await runTests(file, description: '单元测试: $file');
        if (!ok) failures++;
      }
    }

    final alignmentTests =
        await _discoverAlignmentTests(moduleFilter: normalizedFilter);
    if (alignmentTests.isEmpty) {
      printInfo('未发现匹配的 API 对齐测试');
    } else {
      for (final file in alignmentTests) {
        final name = _fileName(file);
        final ok = await runTests(file, description: 'API对齐测试: $name');
        if (!ok) failures++;
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
        final ok = await runTests(dir, description: 'Feature单测: $label');
        if (!ok) failures++;
      }
    }

    return _reportFailures('单元测试', failures);
  }

  static bool _reportFailures(String label, int failures) {
    if (failures > 0) {
      printError('$label共 $failures 个套件失败');
      return false;
    }
    return true;
  }

  static Future<bool> runIntegrationTests({String? moduleFilter}) async {
    printHeader('运行集成测试');
    if (!liveApiEnabled) {
      printWarning('未开启真实API测试环境，跳过集成测试');
      printInfo('提示: 设置 RUN_LIVE_API_TESTS=true 以运行真实API测试');
      return true;
    }

    final normalizedFilter = moduleFilter?.toLowerCase();
    var failures = 0;

    // test/api_client: 真实 API 契约测试（排除 *_alignment_test.dart 静态套件）。
    final apiDir = Directory('test/api_client');
    if (await apiDir.exists()) {
      final files = await apiDir.list().toList();
      final testFiles = files
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('_test.dart') &&
              !f.path.contains('_alignment_test.dart') &&
              (destructiveEnabled || !_isPanelConfigLiveSuite(f.path)))
          .where((f) => _matchesModuleFilter(f.path, normalizedFilter))
          .map((f) => f.path)
          .toList();

      printInfo(
          '发现 ${testFiles.length} 个 api_client 集成测试，超时时间: $liveTestTimeout，重试次数: $liveTestRetries');
      if (!destructiveEnabled) {
        printWarning('未开启 RUN_DESTRUCTIVE_TESTS，已跳过面板设置/快照/SSH/终端写入套件');
      }

      for (final testFile in testFiles) {
        final name = _fileName(testFile);
        final ok =
            await runLiveTestWithRetry(testFile, description: '集成测试: $name');
        if (!ok) failures++;
      }
    }

    // test/integration/: 模块级真服务器套件（文件内部自带 SkipConditions 门控）。
    final integrationDir = Directory('test/integration');
    if (await integrationDir.exists()) {
      final files = await integrationDir.list().toList();
      final testFiles = files
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .where((f) => _matchesModuleFilter(f.path, normalizedFilter))
          .map((f) => f.path)
          .toList()
        ..sort();

      printInfo('发现 ${testFiles.length} 个 integration 目录测试');

      for (final testFile in testFiles) {
        final name = _fileName(testFile);
        final ok =
            await runLiveTestWithRetry(testFile, description: '集成测试: $name');
        if (!ok) failures++;
      }
    }

    return _reportFailures('集成测试', failures);
  }

  static bool _matchesModuleFilter(String path, String? normalizedFilter) {
    if (normalizedFilter == null || normalizedFilter.isEmpty) {
      return true;
    }
    return _fileName(path).toLowerCase().contains(normalizedFilter);
  }

  static Future<bool> runUiTests() async {
    printHeader('运行UI/Widget测试');
    final uiTests = await _discoverUiTests();
    if (uiTests.isEmpty) {
      printInfo('未发现 UI/Widget 测试文件');
      return true;
    }

    printInfo('发现 ${uiTests.length} 个 UI/Widget 测试文件');

    // 单进程串行跑：一次依赖解析加一次编译，比逐文件起进程快数倍。
    // 并发会引入假失败（用例共享静态状态），因此固定 -j 1。
    printInfo('批量执行（单进程串行）');
    final exitCode = await runCommand(
      flutterCommand,
      ['test', ...uiTests, '--reporter=compact', '-j', '1'],
    );
    if (exitCode == 0) {
      printSuccess('测试通过');
      return true;
    }

    // 失败时逐文件重跑，定位具体套件并保留逐条结果。
    printError('批量执行失败，改为逐文件定位');
    var failures = 0;
    for (final testFile in uiTests) {
      final name = _fileName(testFile);
      final ok = await runTests(testFile, description: 'UI测试: $name');
      if (!ok) failures++;
    }
    return _reportFailures('UI测试', failures);
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

  var ok = false;
  switch (command) {
    case 'all':
      ok = await TestRunner.runAllTests(moduleFilter: moduleFilter);
      break;
    case 'unit':
      ok = await TestRunner.runUnitTests(moduleFilter: moduleFilter);
      break;
    case 'integration':
      ok = await TestRunner.runIntegrationTests(moduleFilter: moduleFilter);
      break;
    case 'ui':
      ok = await TestRunner.runUiTests();
      break;
    default:
      TestRunner.printError('未知的命令: $command');
      exit(1);
  }

  if (!ok) {
    exit(1);
  }
}
