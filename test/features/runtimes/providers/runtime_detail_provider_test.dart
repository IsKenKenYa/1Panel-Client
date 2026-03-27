import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_detail_args.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_detail_provider.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';

class _MockRuntimeService extends Mock implements RuntimeService {}

void main() {
  late _MockRuntimeService service;
  late RuntimeDetailProvider provider;

  const detail = RuntimeInfo(
    id: 7,
    name: 'node-main',
    type: 'node',
    resource: 'appstore',
    status: 'Running',
    remark: 'prod',
  );

  setUpAll(() {
    registerFallbackValue(const RuntimeInfo());
  });

  setUp(() {
    service = _MockRuntimeService();
    when(() => service.getRuntimeDetail(any())).thenAnswer((_) async => detail);
    when(() => service.syncRuntimeStatus()).thenAnswer((_) async {});
    when(() => service.operateRuntime(any(), any())).thenAnswer((_) async {});
    when(() => service.updateRuntimeRemark(any(), any()))
        .thenAnswer((_) async {});
    when(() => service.canStart(any())).thenReturn(false);
    when(() => service.canStop(any())).thenReturn(true);
    when(() => service.canRestart(any())).thenReturn(true);
    when(() => service.canEdit(any())).thenReturn(true);
    when(() => service.canOpenAdvanced(any())).thenReturn(true);
    provider = RuntimeDetailProvider(service: service);
  });

  test('initialize loads runtime detail', () async {
    await provider.initialize(const RuntimeDetailArgs(runtimeId: 7));

    expect(provider.runtime?.id, 7);
    expect(provider.runtime?.name, 'node-main');
  });

  test('operate reloads runtime detail', () async {
    await provider.initialize(const RuntimeDetailArgs(runtimeId: 7));

    final result = await provider.operate('restart');

    expect(result, isTrue);
    verify(() => service.operateRuntime(7, 'restart')).called(1);
    verify(() => service.getRuntimeDetail(7)).called(greaterThan(1));
  });

  test('updateRemark saves and reloads runtime detail', () async {
    await provider.initialize(const RuntimeDetailArgs(runtimeId: 7));

    final result = await provider.updateRemark('updated');

    expect(result, isTrue);
    verify(() => service.updateRuntimeRemark(7, 'updated')).called(1);
    verify(() => service.getRuntimeDetail(7)).called(greaterThan(1));
  });
}
