import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/php_config_provider.dart';
import 'package:onepanel_client/features/runtimes/services/php_runtime_service.dart';

class _MockPhpRuntimeService extends Mock implements PhpRuntimeService {}

void main() {
  late _MockPhpRuntimeService service;
  late PhpConfigProvider provider;

  setUpAll(() {
    registerFallbackValue(const PHPConfigUpdate(id: 1, scope: 'php'));
    registerFallbackValue(const PHPContainerConfig(id: 1));
  });

  setUp(() {
    service = _MockPhpRuntimeService();
    when(() => service.loadConfig(any())).thenAnswer(
      (_) async => const PHPConfig(
        disableFunctions: <String>['exec'],
        uploadMaxSize: '64M',
        maxExecutionTime: '120',
      ),
    );
    when(() => service.loadFpmStatus(any())).thenAnswer(
      (_) async => const <FpmStatusItem>[
        FpmStatusItem(key: 'active', value: 2),
      ],
    );
    when(() => service.loadFpmConfig(any())).thenAnswer(
      (invocation) async => PHPFpmConfig(
        id: invocation.positionalArguments.first as int,
        params: const <String, String>{
          'pm': 'dynamic',
          'pm.max_children': '50',
        },
      ),
    );
    when(() => service.loadContainerConfig(any())).thenAnswer(
      (invocation) async => PHPContainerConfig(
        id: invocation.positionalArguments.first as int,
        containerName: 'php-84',
      ),
    );
    when(
      () => service.loadConfigFile(
        runtimeId: any(named: 'runtimeId'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (invocation) async {
        final type = invocation.namedArguments[#type] as String;
        return PHPConfigFileContent(
          path: '/etc/php/$type.conf',
          content: '[$type]\nkey=value',
        );
      },
    );
    when(() => service.saveConfig(any())).thenAnswer((_) async {});
    when(
      () => service.saveFpmConfig(
        runtimeId: any(named: 'runtimeId'),
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) async {});
    when(() => service.saveContainerConfig(any())).thenAnswer((_) async {});
    when(
      () => service.saveConfigFile(
        runtimeId: any(named: 'runtimeId'),
        type: any(named: 'type'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async {});
    provider = PhpConfigProvider(service: service);
  });

  test('initialize loads php config and fpm status', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));

    expect(provider.uploadMaxSize, '64M');
    expect(provider.maxExecutionTime, '120');
    expect(provider.fpmStatus, hasLength(1));
    expect(provider.fpmConfig.params['pm'], 'dynamic');
    expect(provider.containerConfig.containerName, 'php-84');
    expect(provider.phpFilePath, '/etc/php/php.conf');
    expect(provider.fpmFilePath, '/etc/php/fpm.conf');
  });

  test('save calls service with update request', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));
    provider.updateUploadMaxSize('128M');

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.saveConfig(any())).called(1);
  });

  test('saveFpmConfig calls service with runtime id and params', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));
    provider.updateFpmParam('pm.max_children', '120');

    final result = await provider.saveFpmConfig();

    expect(result, isTrue);
    verify(
      () => service.saveFpmConfig(
        runtimeId: 7,
        params: any(named: 'params'),
      ),
    ).called(1);
  });

  test('savePhpFile calls service with php type', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));
    provider.updatePhpFileContent('new php content');

    final result = await provider.savePhpFile();

    expect(result, isTrue);
    verify(
      () => service.saveConfigFile(
        runtimeId: 7,
        type: PhpConfigProvider.phpFileType,
        content: 'new php content',
      ),
    ).called(1);
  });

  test('saveContainerConfig calls service with updated container name',
      () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));
    provider.updateContainerName('php-main');

    final result = await provider.saveContainerConfig();

    expect(result, isTrue);
    verify(() => service.saveContainerConfig(any())).called(1);
  });
}
