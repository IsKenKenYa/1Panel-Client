import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:onepanel_client/features/processes/providers/processes_provider.dart';
import 'package:onepanel_client/features/processes/services/process_service.dart';

class _MockProcessService extends Mock implements ProcessService {}

void main() {
  late _MockProcessService service;
  late ProcessesProvider provider;
  late StreamController<List<ProcessSummary>> controller;

  setUpAll(() {
    registerFallbackValue(const ProcessListQuery());
  });

  setUp(() {
    controller = StreamController<List<ProcessSummary>>.broadcast();
    service = _MockProcessService();
    when(() => service.watchProcesses()).thenAnswer((_) => controller.stream);
    when(() => service.connectProcesses(any())).thenAnswer((_) async {});
    when(() => service.loadListening()).thenAnswer(
      (_) async => const <ListeningProcess>[
        ListeningProcess(pid: 1, protocol: 1, name: 'sshd', ports: <int>[22]),
      ],
    );
    when(() => service.closeProcesses()).thenAnswer((_) async {});
    when(() => service.stopProcess(any())).thenAnswer((_) async {});
    when(() => service.mergeListeningData(any(), any()))
        .thenAnswer((invocation) {
      final items = invocation.positionalArguments[0] as List<ProcessSummary>;
      return items
          .map((item) => item.copyWith(listeningPorts: const <int>[22]))
          .toList(growable: false);
    });
    provider = ProcessesProvider(service: service);
  });

  tearDown(() async {
    await controller.close();
  });

  test('load merges process stream with listening ports', () async {
    await provider.load();
    controller.add(const <ProcessSummary>[
      ProcessSummary(
        pid: 1,
        name: 'sshd',
        parentPid: 0,
        username: 'root',
        status: 'running',
        startTime: 'now',
        numThreads: 1,
        numConnections: 1,
        cpuPercent: '1%',
        cpuValue: 1,
        memoryText: '10M',
        memoryValue: 10,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.items.single.listeningPorts, <int>[22]);
  });
}
