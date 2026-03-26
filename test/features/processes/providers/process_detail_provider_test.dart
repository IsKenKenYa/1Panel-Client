import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/process_detail_models.dart';
import 'package:onepanel_client/features/processes/providers/process_detail_provider.dart';
import 'package:onepanel_client/features/processes/services/process_service.dart';

class _MockProcessService extends Mock implements ProcessService {}

void main() {
  late _MockProcessService service;
  late ProcessDetailProvider provider;

  const detail = ProcessDetail(
    pid: 1,
    name: 'sshd',
    parentPid: 0,
    username: 'root',
    status: 'running',
    startTime: 'now',
    numThreads: 1,
    numConnections: 1,
    diskRead: '0B',
    diskWrite: '0B',
    cmdLine: 'sshd',
    rss: '1M',
    pss: '1M',
    uss: '1M',
    swap: '0B',
    shared: '0B',
    vms: '1M',
    hwm: '1M',
    data: '0B',
    stack: '0B',
    locked: '0B',
    text: '0B',
    dirty: '0B',
    envs: <String>[],
    openFiles: <ProcessOpenFile>[],
    connections: <ProcessConnection>[],
  );

  setUp(() {
    service = _MockProcessService();
    when(() => service.loadDetail(any())).thenAnswer((_) async => detail);
    when(() => service.stopProcess(any())).thenAnswer((_) async {});
    provider = ProcessDetailProvider(service: service);
  });

  test('load fetches detail', () async {
    await provider.load(1);

    expect(provider.detail?.name, 'sshd');
  });

  test('stopProcess returns false when detail still exists', () async {
    await provider.load(1);

    final shouldPop = await provider.stopProcess();

    expect(shouldPop, isFalse);
  });
}
