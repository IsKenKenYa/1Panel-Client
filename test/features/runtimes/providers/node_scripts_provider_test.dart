import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/node_scripts_provider.dart';
import 'package:onepanel_client/features/runtimes/services/node_runtime_service.dart';

class _MockNodeRuntimeService extends Mock implements NodeRuntimeService {}

void main() {
  late _MockNodeRuntimeService service;
  late NodeScriptsProvider provider;

  setUp(() {
    service = _MockNodeRuntimeService();
    when(() => service.loadScripts(any())).thenAnswer(
      (_) async => const <NodeScriptInfo>[
        NodeScriptInfo(name: 'start', script: 'node index.js'),
      ],
    );
    when(
      () => service.runScript(
        runtimeId: any(named: 'runtimeId'),
        scriptName: any(named: 'scriptName'),
        packageManager: any(named: 'packageManager'),
      ),
    ).thenAnswer(
      (_) async => const NodeScriptExecutionFeedback(
        isSuccess: true,
        status: 'Running',
        attempts: 2,
      ),
    );

    provider = NodeScriptsProvider(service: service);
  });

  test('initialize loads package scripts', () async {
    await provider.initialize(
      const RuntimeManageArgs(
        runtimeId: 11,
        codeDir: '/apps/node',
      ),
    );

    expect(provider.items, hasLength(1));
    expect(provider.items.first.name, 'start');
  });

  test('runScript calls service', () async {
    await provider.initialize(
      const RuntimeManageArgs(
        runtimeId: 11,
        codeDir: '/apps/node',
      ),
    );

    final result = await provider.runScript('start');

    expect(result, isTrue);
    verify(
      () => service.runScript(
        runtimeId: 11,
        scriptName: 'start',
        packageManager: 'npm',
      ),
    ).called(1);
    expect(provider.executionStatus, 'Running');
    expect(provider.lastRunSuccess, isTrue);
    expect(provider.pollAttempts, 2);
  });
}
