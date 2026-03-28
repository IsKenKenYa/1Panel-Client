import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/php_supervisor_provider.dart';
import 'package:onepanel_client/features/runtimes/services/php_runtime_service.dart';

class _MockPhpRuntimeService extends Mock implements PhpRuntimeService {}

void main() {
  late _MockPhpRuntimeService service;
  late PhpSupervisorProvider provider;

  setUp(() {
    service = _MockPhpRuntimeService();

    when(() => service.loadSupervisorProcesses(any())).thenAnswer(
      (_) async => const <SupervisorProcessInfo>[
        SupervisorProcessInfo(
          name: 'php-fpm',
          command: 'php-fpm -F',
          status: <SupervisorProcessStatus>[
            SupervisorProcessStatus(status: 'RUNNING'),
          ],
        ),
      ],
    );
    when(
      () => service.operateSupervisorProcess(
        runtimeId: any(named: 'runtimeId'),
        name: any(named: 'name'),
        operate: any(named: 'operate'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => service.loadSupervisorFile(
        runtimeId: any(named: 'runtimeId'),
        name: any(named: 'name'),
        file: any(named: 'file'),
      ),
    ).thenAnswer((_) async => '[program:php-fpm]\ncommand=php-fpm -F');

    when(
      () => service.updateSupervisorFile(
        runtimeId: any(named: 'runtimeId'),
        name: any(named: 'name'),
        file: any(named: 'file'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async {});

    provider = PhpSupervisorProvider(service: service);
  });

  test('initialize loads supervisor processes', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));

    expect(provider.items, hasLength(1));
    expect(provider.items.first.name, 'php-fpm');
    expect(provider.processState(provider.items.first), 'RUNNING');
  });

  test('operateProcess calls service and refreshes list', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));

    final result = await provider.operateProcess(
      processName: 'queue-worker',
      operation: 'restart',
    );

    expect(result, isTrue);
    verify(
      () => service.operateSupervisorProcess(
        runtimeId: 7,
        name: 'queue-worker',
        operate: 'restart',
      ),
    ).called(1);
    verify(() => service.loadSupervisorProcesses(7)).called(greaterThan(1));
  });

  test('openFile and saveActiveConfig call service', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));

    final opened = await provider.openFile(
      processName: 'php-fpm',
      fileName: 'config',
    );
    final saved =
        await provider.saveActiveConfig('[program:php-fpm]\nnumprocs=1');

    expect(opened, isTrue);
    expect(saved, isTrue);
    expect(provider.activeFileContent, contains('numprocs=1'));

    verify(
      () => service.loadSupervisorFile(
        runtimeId: 7,
        name: 'php-fpm',
        file: 'config',
      ),
    ).called(1);

    verify(
      () => service.updateSupervisorFile(
        runtimeId: 7,
        name: 'php-fpm',
        file: 'config',
        content: '[program:php-fpm]\nnumprocs=1',
      ),
    ).called(1);
  });
}
