import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/php_extensions_provider.dart';
import 'package:onepanel_client/features/runtimes/services/php_runtime_service.dart';

class _MockPhpRuntimeService extends Mock implements PhpRuntimeService {}

void main() {
  late _MockPhpRuntimeService service;
  late PhpExtensionsProvider provider;

  setUp(() {
    service = _MockPhpRuntimeService();
    when(() => service.loadExtensions(any())).thenAnswer(
      (_) async => const PHPExtensionsRes(
        extensions: <String>['redis'],
        supportExtensions: <PHPExtensionSupport>[
          PHPExtensionSupport(name: 'redis', installed: false),
        ],
      ),
    );
    when(() => service.installExtension(any(), any(), taskId: any(named: 'taskId')))
        .thenAnswer((_) async {});
    when(() => service.uninstallExtension(any(), any(), taskId: any(named: 'taskId')))
        .thenAnswer((_) async {});

    provider = PhpExtensionsProvider(service: service);
  });

  test('initialize loads php extensions', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 9));

    expect(provider.extensions.supportExtensions, hasLength(1));
    expect(provider.filteredItems.first.name, 'redis');
  });

  test('toggleExtension installs extension when not installed', () async {
    await provider.initialize(const RuntimeManageArgs(runtimeId: 9));

    final result = await provider.toggleExtension(
      const PHPExtensionSupport(name: 'redis', installed: false),
    );

    expect(result, isTrue);
    verify(() => service.installExtension(9, 'redis', taskId: any(named: 'taskId'))).called(1);
  });
}
