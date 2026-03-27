import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/backups/models/backup_record_list_item.dart';
import 'package:onepanel_client/features/backups/services/backup_record_service.dart';

class BackupRecordsProvider extends ChangeNotifier with AsyncStateNotifier {
  BackupRecordsProvider({
    BackupRecordService? service,
  }) : _service = service ?? BackupRecordService();

  final BackupRecordService _service;

  BackupRecordsArgs? _args;
  List<BackupRecordListItem> _items = const <BackupRecordListItem>[];
  String _type = 'app';
  String _name = '';
  String _detailName = '';
  bool _isMutating = false;

  List<BackupRecordListItem> get items => _items;
  String get type => _type;
  String get name => _name;
  String get detailName => _detailName;
  bool get isMutating => _isMutating;
  bool get hasCronjobContext => _args?.cronjobId != null;

  Future<void> initialize(BackupRecordsArgs? args) async {
    _args = args;
    _type = args?.type ?? 'app';
    _name = args?.name ?? '';
    _detailName = args?.detailName ?? '';
    await load();
  }

  Future<void> load() async {
    setLoading();
    try {
      _items = await _service.loadRecords(
        args: _args,
        type: _type,
        name: _name,
        detailName: _detailName,
      );
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.records',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <BackupRecordListItem>[];
      setError(error);
    }
  }

  void updateFilters({
    String? type,
    String? name,
    String? detailName,
  }) {
    _type = type ?? _type;
    _name = name ?? _name;
    _detailName = detailName ?? _detailName;
    notifyListeners();
  }

  Future<FileSaveResult?> download(BackupRecordListItem item) {
    return _runMutation(() => _service.downloadRecord(item.record));
  }

  Future<bool> delete(BackupRecordListItem item) async {
    final result = await _runMutation(() async {
      await _service.deleteRecord(item.record);
      await load();
      return true;
    });
    return result ?? false;
  }

  Future<T?> _runMutation<T>(Future<T> Function() action) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      return await action();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.records',
        'mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
