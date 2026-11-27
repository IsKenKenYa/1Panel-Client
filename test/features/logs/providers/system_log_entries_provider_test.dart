import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/system_log_models.dart';
import 'package:onepanel_client/features/logs/providers/system_log_entries_provider.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

class _MockLogsService extends Mock implements LogsService {}

void main() {
  late _MockLogsService service;
  late SystemLogEntriesProvider provider;

  SystemLogPage page({
    required List<SystemLogEntry> items,
    required bool hasMore,
    String? nextCursor,
  }) {
    return SystemLogPage(items: items, hasMore: hasMore, nextCursor: nextCursor);
  }

  SystemLogEntry entry(String message) =>
      SystemLogEntry(time: '2026-11-26 10:00:00', message: message);

  setUpAll(() {
    registerFallbackValue(const SystemLogSearch());
  });

  setUp(() {
    service = _MockLogsService();
    when(() => service.loadSystemLogStatus()).thenAnswer(
      (_) async => const SystemLogStatus(
        source: SystemLogSourceKind.journalctl,
        keywordFilterSupported: true,
      ),
    );
    when(() => service.loadRunningServices())
        .thenAnswer((_) async => <String>['1panel-core']);
    when(() => service.readSystemLogs(any())).thenAnswer(
      (_) async => page(
        items: <SystemLogEntry>[entry('first page')],
        hasMore: true,
        nextCursor: 'c2',
      ),
    );
    provider = SystemLogEntriesProvider(service: service);
  });

  test('初始化加载状态、服务与第一页条目', () async {
    await provider.initialize();

    expect(provider.status?.source, SystemLogSourceKind.journalctl);
    expect(provider.canFilterByKeyword, isTrue);
    expect(provider.services, <String>['1panel-core']);
    expect(provider.entries.single.message, 'first page');
    expect(provider.canGoPrevious, isFalse);
    expect(provider.canGoNext, isTrue);
  });

  test('下一页使用上一页返回的游标', () async {
    await provider.initialize();
    final captured = <SystemLogSearch>[];
    when(() => service.readSystemLogs(any())).thenAnswer((invocation) async {
      final request = invocation.positionalArguments.single as SystemLogSearch;
      captured.add(request);
      return page(items: <SystemLogEntry>[entry('second page')], hasMore: false);
    });

    await provider.loadNextPage();

    expect(captured.single.cursor, 'c2');
    expect(provider.entries.single.message, 'second page');
    expect(provider.canGoNext, isFalse);
    expect(provider.canGoPrevious, isTrue);
  });

  test('回到上一页复用首屏游标，不重复请求同一游标', () async {
    await provider.initialize();
    final captured = <String?>[];
    when(() => service.readSystemLogs(any())).thenAnswer((invocation) async {
      final request = invocation.positionalArguments.single as SystemLogSearch;
      captured.add(request.cursor);
      return page(items: <SystemLogEntry>[entry('page')], hasMore: true,
          nextCursor: 'c2');
    });

    await provider.loadNextPage();
    await provider.loadPreviousPage();

    expect(captured.first, 'c2');
    expect(captured.last ?? '', isEmpty);
    expect(provider.canGoPrevious, isFalse);
  });

  test('关键字不可用时仍把关键字原样提交，由界面负责禁用', () async {
    when(() => service.loadSystemLogStatus()).thenAnswer(
      (_) async => const SystemLogStatus(
        source: SystemLogSourceKind.file,
      ),
    );
    await provider.initialize();
    expect(provider.canFilterByKeyword, isFalse);
  });

  test('服务端失败时记录错误并清空条目', () async {
    when(() => service.readSystemLogs(any())).thenThrow(Exception('boom'));
    await provider.initialize();

    expect(provider.errorMessage, 'logs.system.entriesLoadFailed');
    expect(provider.entries, isEmpty);
    expect(provider.loading, isFalse);
  });

  test('筛选变更后从第一页重新查询并清空游标', () async {
    await provider.initialize();
    final captured = <SystemLogSearch>[];
    when(() => service.readSystemLogs(any())).thenAnswer((invocation) async {
      captured.add(invocation.positionalArguments.single as SystemLogSearch);
      return page(
        items: <SystemLogEntry>[entry('filtered')],
        hasMore: false,
      );
    });

    await provider.applyFilters(priority: 'err', service: '1panel-core');

    expect(captured.single.priority, 'err');
    expect(captured.single.service, '1panel-core');
    expect(captured.single.cursor ?? '', isEmpty);
    expect(provider.canGoPrevious, isFalse);
  });
}
