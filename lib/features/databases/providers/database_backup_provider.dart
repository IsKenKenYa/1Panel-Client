import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart' as backup;
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/services/database_backup_service.dart';

class DatabaseBackupState {
  const DatabaseBackupState({
    this.page = const PageResult<backup.BackupRecord>(items: [], total: 0),
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final PageResult<backup.BackupRecord> page;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  List<backup.BackupRecord> get items => page.items;
}

class DatabaseBackupProvider extends ChangeNotifier {
  DatabaseBackupProvider({
    required this.item,
    DatabaseBackupService? service,
  }) : _service = service ?? DatabaseBackupService();

  final DatabaseListItem item;
  final DatabaseBackupService _service;

  DatabaseBackupState _state = const DatabaseBackupState();
  DatabaseBackupState get state => _state;

  Future<void> load({
    int page = 1,
    int pageSize = 20,
  }) async {
    _state = DatabaseBackupState(
      page: _state.page,
      isLoading: true,
    );
    notifyListeners();
    try {
      final nextPage = await _service.loadRecords(
        item,
        page: page,
        pageSize: pageSize,
      );
      _state = DatabaseBackupState(
        page: nextPage,
        isLoading: false,
      );
    } catch (e) {
      _state = DatabaseBackupState(
        page: _state.page,
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> refresh() => load(
        page: _state.page.page,
        pageSize: _state.page.pageSize,
      );

  Future<bool> createBackup({String? secret}) async {
    return _runMutation(() async {
      await _service.createBackup(item, secret: secret);
      await refresh();
    });
  }

  Future<bool> restoreBackup(
    backup.BackupRecord record, {
    String? secret,
  }) async {
    return _runMutation(() async {
      await _service.restoreBackup(item, record, secret: secret);
      await refresh();
    });
  }

  Future<bool> deleteBackupRecord(backup.BackupRecord record) async {
    final id = record.id;
    if (id == null) {
      return false;
    }
    return _runMutation(() async {
      await _service.deleteBackupRecord(id);
      await refresh();
    });
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _state = DatabaseBackupState(
      page: _state.page,
      isLoading: false,
      isSubmitting: true,
    );
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _state = DatabaseBackupState(
        page: _state.page,
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
      return false;
    } finally {
      if (_state.isSubmitting) {
        _state = DatabaseBackupState(
          page: _state.page,
          isLoading: false,
        );
        notifyListeners();
      }
    }
  }
}
