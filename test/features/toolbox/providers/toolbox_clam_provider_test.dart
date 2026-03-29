import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_clam_provider.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_clam_service.dart';

class _FakeToolboxClamService extends ToolboxClamService {
  int loadSnapshotCallCount = 0;
  int createTaskCallCount = 0;
  int updateTaskCallCount = 0;
  int deleteTaskCallCount = 0;
  int handleTaskCallCount = 0;
  int operateServiceCallCount = 0;
  int cleanRecordsCallCount = 0;

  int? lastSelectedTaskId;
  List<int>? lastDeletedIds;
  bool? lastDeleteRemoveInfected;
  int? lastHandledTaskId;
  String? lastOperation;
  int? lastCleanTaskId;

  bool failNextMutation = false;

  final List<ClamBaseInfo> _tasks = <ClamBaseInfo>[
    const ClamBaseInfo(id: 1, name: 'daily-scan'),
    const ClamBaseInfo(id: 2, name: 'weekly-scan'),
  ];

  final List<ClamLogInfo> _records = <ClamLogInfo>[
    const ClamLogInfo(id: 10, name: 'record-a', status: 'success'),
  ];

  void _throwIfNeeded() {
    if (failNextMutation) {
      failNextMutation = false;
      throw Exception('mock clam mutation failure');
    }
  }

  @override
  Future<ToolboxClamSnapshot> loadSnapshot({
    int taskPage = 1,
    int taskPageSize = 20,
    int recordPage = 1,
    int recordPageSize = 20,
    int? selectedTaskId,
  }) async {
    loadSnapshotCallCount += 1;
    lastSelectedTaskId = selectedTaskId;
    return ToolboxClamSnapshot(
      tasks: _tasks,
      records: _records,
      selectedTaskId: selectedTaskId ?? _tasks.first.id,
    );
  }

  @override
  Future<void> createTask(ClamCreate request) async {
    _throwIfNeeded();
    createTaskCallCount += 1;
  }

  @override
  Future<void> updateTask(ClamUpdate request) async {
    _throwIfNeeded();
    updateTaskCallCount += 1;
  }

  @override
  Future<void> deleteTasks({
    required List<int> ids,
    bool removeInfected = false,
  }) async {
    _throwIfNeeded();
    deleteTaskCallCount += 1;
    lastDeletedIds = ids;
    lastDeleteRemoveInfected = removeInfected;
  }

  @override
  Future<void> handleTask(int id) async {
    _throwIfNeeded();
    handleTaskCallCount += 1;
    lastHandledTaskId = id;
  }

  @override
  Future<void> operateService(String operation) async {
    _throwIfNeeded();
    operateServiceCallCount += 1;
    lastOperation = operation;
  }

  @override
  Future<void> cleanRecords(int taskId) async {
    _throwIfNeeded();
    cleanRecordsCallCount += 1;
    lastCleanTaskId = taskId;
  }
}

void main() {
  test('ToolboxClamProvider load populates snapshot state', () async {
    final service = _FakeToolboxClamService();
    final provider = ToolboxClamProvider(service: service);

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.tasks, hasLength(2));
    expect(provider.records, hasLength(1));
    expect(provider.selectedTaskId, 1);
    expect(service.loadSnapshotCallCount, 1);
  });

  test('ToolboxClamProvider selectTask reloads with target id', () async {
    final service = _FakeToolboxClamService();
    final provider = ToolboxClamProvider(service: service);

    await provider.load();
    await provider.selectTask(2);

    expect(provider.selectedTaskId, 2);
    expect(service.lastSelectedTaskId, 2);
    expect(service.loadSnapshotCallCount, 2);
  });

  test('ToolboxClamProvider createTask triggers mutation and refresh', () async {
    final service = _FakeToolboxClamService();
    final provider = ToolboxClamProvider(service: service);
    await provider.load();

    final ok = await provider.createTask(
      const ClamCreate(name: 'nightly-scan'),
    );

    expect(ok, isTrue);
    expect(provider.error, isNull);
    expect(service.createTaskCallCount, 1);
    expect(service.loadSnapshotCallCount, 2);
  });

  test('ToolboxClamProvider deleteTask forwards removeInfected option',
      () async {
    final service = _FakeToolboxClamService();
    final provider = ToolboxClamProvider(service: service);

    final ok = await provider.deleteTask(2, removeInfected: true);

    expect(ok, isTrue);
    expect(service.deleteTaskCallCount, 1);
    expect(service.lastDeletedIds, <int>[2]);
    expect(service.lastDeleteRemoveInfected, isTrue);
  });

  test('ToolboxClamProvider mutation failure exposes error', () async {
    final service = _FakeToolboxClamService();
    final provider = ToolboxClamProvider(service: service);
    service.failNextMutation = true;

    final ok = await provider.operateService('restart');

    expect(ok, isFalse);
    expect(provider.error, contains('mock clam mutation failure'));
    expect(service.operateServiceCallCount, 0);
  });
}
