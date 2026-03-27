import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/providers/runtimes_provider.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';

class _MockRuntimeService extends Mock implements RuntimeService {}

void main() {
  late _MockRuntimeService service;
  late RuntimesProvider provider;

  const item = RuntimeInfo(
    id: 1,
    name: 'php-main',
    type: 'php',
    resource: 'appstore',
    status: 'Running',
    version: '8.2',
  );

  setUpAll(() {
    registerFallbackValue(const RuntimeInfo());
  });

  setUp(() {
    service = _MockRuntimeService();
    when(
      () => service.searchRuntimes(
        type: any(named: 'type'),
        name: any(named: 'name'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => const PageResult<RuntimeInfo>(
        items: <RuntimeInfo>[item],
        total: 1,
      ),
    );
    when(() => service.syncRuntimeStatus()).thenAnswer((_) async {});
    when(() => service.operateRuntime(any(), any())).thenAnswer((_) async {});
    when(() => service.deleteRuntime(any())).thenAnswer((_) async {});
    when(() => service.canStart(any())).thenReturn(false);
    when(() => service.canStop(any())).thenReturn(true);
    when(() => service.canRestart(any())).thenReturn(true);
    when(() => service.canEdit(any())).thenReturn(true);
    provider = RuntimesProvider(service: service);
  });

  test('load fetches runtime list', () async {
    await provider.load();

    expect(provider.items, hasLength(1));
    expect(provider.items.first.name, 'php-main');
  });

  test('syncStatus calls service and reloads list', () async {
    await provider.syncStatus();

    verify(() => service.syncRuntimeStatus()).called(1);
    verify(
      () => service.searchRuntimes(
        type: 'php',
        name: '',
        status: '',
      ),
    ).called(1);
  });

  test('operate calls service and reloads list', () async {
    await provider.operate(item, 'restart');

    verify(() => service.operateRuntime(1, 'restart')).called(1);
    verify(
      () => service.searchRuntimes(
        type: 'php',
        name: '',
        status: '',
      ),
    ).called(1);
  });

  test('updateType changes current category', () {
    provider.updateType('node');

    expect(provider.selectedType, 'node');
  });
}
