import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/script_library/providers/script_library_provider.dart';
import 'package:onepanel_client/features/script_library/services/script_library_service.dart';

class _MockScriptLibraryService extends Mock implements ScriptLibraryService {}

void main() {
  late _MockScriptLibraryService service;
  late ScriptLibraryProvider provider;
  late StreamController<String> outputController;
  late StreamController<bool> stateController;

  final groups = <GroupInfo>[
    const GroupInfo(id: 1, name: 'Default', type: 'script', isDefault: true),
  ];
  final scripts = <ScriptLibraryInfo>[
    ScriptLibraryInfo(
      id: 1,
      name: 'cleanup',
      isInteractive: false,
      label: '',
      script: 'echo cleanup',
      groupList: const <int>[1],
      groupBelong: const <String>['Default'],
      isSystem: false,
      description: 'cleanup job',
      createdAt: DateTime.parse('2026-03-27T00:00:00Z'),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const ScriptLibraryQuery());
  });

  setUp(() {
    outputController = StreamController<String>.broadcast();
    stateController = StreamController<bool>.broadcast();
    service = _MockScriptLibraryService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.searchScripts(any())).thenAnswer(
      (_) async => PageResult<ScriptLibraryInfo>(
        items: scripts,
        total: scripts.length,
      ),
    );
    when(() => service.syncScripts()).thenAnswer(
      (_) async => const ScriptSyncState(taskId: 'task-1', isRunning: true),
    );
    when(() => service.deleteScripts(any())).thenAnswer((_) async {});
    when(() => service.watchRunOutput())
        .thenAnswer((_) => outputController.stream);
    when(() => service.watchRunState())
        .thenAnswer((_) => stateController.stream);
    when(() => service.startRun(any())).thenAnswer((_) async {});
    when(() => service.stopRun()).thenAnswer((_) async {});
    provider = ScriptLibraryProvider(service: service);
  });

  tearDown(() async {
    await outputController.close();
    await stateController.close();
  });

  test('load sets scripts and groups', () async {
    await provider.load();

    expect(provider.items, hasLength(1));
    expect(provider.groups, hasLength(1));
  });

  test('syncScripts calls service and reloads', () async {
    await provider.load();
    clearInteractions(service);
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.searchScripts(any())).thenAnswer(
      (_) async => PageResult<ScriptLibraryInfo>(
        items: scripts,
        total: scripts.length,
      ),
    );

    final result = await provider.syncScripts();

    expect(result, isTrue);
    verify(() => service.syncScripts()).called(1);
    verify(() => service.searchScripts(any())).called(1);
  });

  test('startRun collects output and stops when websocket closes', () async {
    await provider.startRun(scripts.first);
    stateController.add(true);
    outputController.add('hello');
    stateController.add(false);
    await Future<void>.delayed(Duration.zero);

    expect(provider.runOutput, 'hello');
    expect(provider.isRunning, isFalse);
  });
}
