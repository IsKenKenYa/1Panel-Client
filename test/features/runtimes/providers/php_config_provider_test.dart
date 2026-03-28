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
    when(() => service.saveConfig(any())).thenAnswer((_) async {});
    provider = PhpConfigProvider(service: service);
  });

  test('initialize loads php config and fpm status', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));

    expect(provider.uploadMaxSize, '64M');
    expect(provider.maxExecutionTime, '120');
    expect(provider.fpmStatus, hasLength(1));
  });

  test('save calls service with update request', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 7));
    provider.updateUploadMaxSize('128M');

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.saveConfig(any())).called(1);
  });
}
