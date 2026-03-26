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
    final commandApiClientFile =
        File('test/api_client/command_api_client_test.dart');
    if (await commandApiClientFile.exists()) {
      await runTests(
        'test/api_client/command_api_client_test.dart',
        description: 'Command API真实环境测试',
      );
    }
    final hostApiClientFile = File('test/api_client/host_api_client_test.dart');
    if (await hostApiClientFile.exists()) {
      await runTests(
        'test/api_client/host_api_client_test.dart',
        description: 'Host API真实环境测试',
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
    final sshApiClientFile = File('test/api_client/ssh_api_client_test.dart');
    if (await sshApiClientFile.exists()) {
      await runTests(
        'test/api_client/ssh_api_client_test.dart',
        description: 'SSH API真实环境测试',
      );
    }
    final processApiClientFile =
        File('test/api_client/process_api_client_test.dart');
    if (await processApiClientFile.exists()) {
      await runTests(
        'test/api_client/process_api_client_test.dart',
        description: 'Process API真实环境测试',
      );
    }
    final processWsClientTestFile =
        File('test/core/network/process_ws_client_test.dart');
    if (await processWsClientTestFile.exists()) {
      await runTests(
        'test/core/network/process_ws_client_test.dart',
        description: 'Process WebSocket契约测试',
      );
    }
  }

  static Future<void> runIntegrationTests() async {
    printHeader('运行集成测试');
    await runTests('test/integration/', description: 'API集成测试');
  }

  static Future<void> runUiTests() async {
    printHeader('运行UI/Widget测试');
    var hasTests = false;
    final widgetDir = Directory('test/widget_test');
    if (await widgetDir.exists()) {
      hasTests = true;
      await runTests('test/widget_test/', description: 'Widget目录测试');
    }
    final widgetFile = File('test/widget_test.dart');
    if (await widgetFile.exists()) {
      hasTests = true;
      await runTests('test/widget_test.dart', description: 'Widget单文件测试');
    }
    final serverDetailFile =
        File('test/features/server/server_detail_page_test.dart');
    if (await serverDetailFile.exists()) {
      hasTests = true;
      await runTests(
        'test/features/server/server_detail_page_test.dart',
        description: 'Server Detail Widget测试',
      );
    }
    final groupWidgetDir = Directory('test/features/group/widgets');
    if (await groupWidgetDir.exists()) {
      hasTests = true;
      await runTests(
        'test/features/group/widgets/',
        description: 'Group Widget测试',
      );
    }
    final operationsCenterDir = Directory('test/features/operations_center');
    if (await operationsCenterDir.exists()) {
      hasTests = true;
      await runTests(
        'test/features/operations_center/',
        description: 'Operations Center Widget测试',
      );
    }
    final commandsPagesDir = Directory('test/features/commands/pages');
    if (await commandsPagesDir.exists()) {
      hasTests = true;
      await runTests(
        'test/features/commands/pages/',
        description: 'Commands Widget测试',
      );
    }
    final hostAssetsPagesDir = Directory('test/features/host_assets/pages');
    if (await hostAssetsPagesDir.exists()) {
      hasTests = true;
      await runTests(
        'test/features/host_assets/pages/',
        description: 'Host Assets Widget测试',
      );
    }
    final sshPagesDir = Directory('test/features/ssh/pages');
    if (await sshPagesDir.exists()) {
      hasTests = true;
      await runTests(
        'test/features/ssh/pages/',
        description: 'SSH Widget测试',
      );
    }
    final processPagesDir = Directory('test/features/processes/pages');
    if (await processPagesDir.exists()) {
      hasTests = true;
      await runTests(
        'test/features/processes/pages/',
        description: 'Process Widget测试',
      );
    }
    if (!hasTests) {
      printWarning('Widget测试不存在');
    }
  }

  static Future<void> runAuthTests() async {
    printHeader('运行认证测试');
    await runTests('test/auth/', description: 'Token认证测试');
  }

  static Future<void> runAiTests() async {
    printHeader('运行AI API测试');
    await runTests('test/api/ai_api_test.dart', description: 'AI API单元测试');
    await runTests('test/integration/ai_api_integration_test.dart',
        description: 'AI API集成测试');
  }

  static Future<void> runAppTests() async {
    printHeader('运行App API测试');
    await runTests('test/api/app_api_test.dart', description: 'App API单元测试');
  }

  static Future<void> runToolboxTests() async {
    printHeader('运行Toolbox API测试');
    await runTests('test/api/toolbox_api_test.dart',
        description: 'Toolbox API单元测试');
  }

  static Future<void> runContainerTests() async {
    printHeader('运行Container API测试');
    await runTests('test/api/container_api_test.dart',
        description: 'Container API单元测试');
  }

  static Future<void> runDatabaseTests() async {
    printHeader('运行Database API测试');
    final file = File('test/api/database_api_test.dart');
    if (await file.exists()) {
      await runTests('test/api/database_api_test.dart',
          description: 'Database API单元测试');
    } else {
      printWarning('Database API测试文件不存在');
    }
  }

  static Future<void> runWebsiteTests() async {
    printHeader('运行Website API测试');
    final file = File('test/api/website_api_test.dart');
    if (await file.exists()) {
      await runTests('test/api/website_api_test.dart',
          description: 'Website API单元测试');
    } else {
      printWarning('Website API测试文件不存在');
    }
  }

  static Future<void> runCoverageTests() async {
    printHeader('运行测试并生成覆盖率报告');

    printInfo('运行测试并收集覆盖率数据...');
    final flutter = await resolveFlutterCommand();
    final exitCode = await runCommand(
        flutter, ['test', '--coverage', '--reporter=expanded']);

    if (exitCode == 0) {
      final coverageFile = File('coverage/lcov.info');
      if (await coverageFile.exists()) {
        printSuccess('覆盖率数据已生成: coverage/lcov.info');
        stdout.writeln('');
        printInfo('可以使用以下命令查看覆盖率报告:');
        stdout.writeln('  genhtml coverage/lcov.info -o coverage/html');
        stdout.writeln('  open coverage/html/index.html');
      }
    } else {
      printError('测试失败，无法生成覆盖率报告');
    }
  }

  static void printHelp() {
    stdout.writeln('''
1Panel V2 API 测试运行脚本

用法: dart run test_runner.dart [选项]

选项:
  all           运行全量回归测试
  unit          仅运行单元测试
  integration   仅运行集成测试
  ui            仅运行UI/Widget测试
  auth          运行认证测试
  ai            运行AI API测试
  app           运行App API测试
  toolbox       运行Toolbox API测试
  container     运行Container API测试
  database      运行Database API测试
  website       运行Website API测试
  coverage      运行测试并生成覆盖率报告
  help          显示此帮助信息

示例:
  dart run test_runner.dart all          # 运行全量回归测试
  dart run test_runner.dart unit         # 仅运行单元测试
  dart run test_runner.dart ai           # 运行AI API测试
  dart run test_runner.dart ui           # 运行UI/Widget测试

环境变量配置:
  复制 .env.example 为 .env 并填写以下配置:
  - PANEL_BASE_URL: 1Panel服务器地址
  - PANEL_API_KEY: API密钥
  - RUN_INTEGRATION_TESTS: 是否运行集成测试 (true/false)
  - RUN_DESTRUCTIVE_TESTS: 是否运行破坏性测试 (true/false)

注意:
  1Panel OpenAPI 仅支持 API密钥 认证方式
  Token = md5('1panel' + API-Key + UnixTimestamp)
''');
  }

  static Future<bool> checkEnv() async {
    final envFile = File('.env');
    if (!await envFile.exists()) {
      printWarning('.env 文件不存在');
      stdout.writeln('请复制 .env.example 为 .env 并填写配置');
      stdout.writeln('');
      stdout.writeln('  cp .env.example .env');
      stdout.writeln('');

      stdout.write('是否继续运行测试? (y/n): ');
      final input = stdin.readLineSync();
      if (input?.toLowerCase() != 'y') {
        return false;
      }
    }
    return true;
  }
}

Future<void> main(List<String> args) async {
  final option = args.isNotEmpty ? args[0] : 'help';

  // 检查环境配置
  if (option != 'help') {
    if (!await TestRunner.checkEnv()) {
      exit(1);
    }
  }

  switch (option) {
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
    case 'auth':
      await TestRunner.runAuthTests();
      break;
    case 'ai':
      await TestRunner.runAiTests();
      break;
    case 'app':
      await TestRunner.runAppTests();
      break;
    case 'toolbox':
      await TestRunner.runToolboxTests();
      break;
    case 'container':
      await TestRunner.runContainerTests();
      break;
    case 'database':
      await TestRunner.runDatabaseTests();
      break;
    case 'website':
      await TestRunner.runWebsiteTests();
      break;
    case 'coverage':
      await TestRunner.runCoverageTests();
      break;
    case 'help':
    case '--help':
    case '-h':
      TestRunner.printHelp();
      break;
    default:
      TestRunner.printError('未知选项: $option');
      stdout.writeln('');
      TestRunner.printHelp();
      exit(1);
  }
}
