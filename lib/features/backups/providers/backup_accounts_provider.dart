import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';

class BackupAccountsProvider extends ChangeNotifier with AsyncStateNotifier {
  BackupAccountsProvider({
    BackupAccountService? service,
  }) : _service = service ?? BackupAccountService();

  final BackupAccountService _service;

  List<BackupAccountInfo> _items = const <BackupAccountInfo>[];
  String _searchQuery = '';
  String? _selectedType;
  bool _isMutating = false;

  List<BackupAccountInfo> get items => _items;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    setLoading();
    try {
      _items = await _service.searchAccounts(
        keyword: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        type: _selectedType,
      );
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.accounts',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <BackupAccountInfo>[];
      setError(error);
    }
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateTypeFilter(String? value) {
    _selectedType = value;
    notifyListeners();
  }

  Future<BackupCheckResult?> testAccount(BackupAccountInfo account) async {
    return _runMutation(() async {
      final draft = await _service.initializeDraft(
        BackupAccountFormArgs(initialValue: account),
      );
      return _service.testConnection(draft);
    });
  }

  Future<bool> deleteAccount(BackupAccountInfo account) async {
    final result = await _runMutation(() async {
      await _service.deleteAccount(account);
      await load();
      return true;
    });
    return result ?? false;
  }

  Future<bool> refreshToken(BackupAccountInfo account) async {
    final result = await _runMutation(() async {
      await _service.refreshToken(account);
      await load();
      return true;
    });
    return result ?? false;
  }

  Future<List<String>?> loadFiles(BackupAccountInfo account) {
    return _runMutation(() async {
      if (account.id == null) return const <String>[];
      return _service.listFiles(account.id!);
    });
  }

  Future<T?> _runMutation<T>(Future<T> Function() action) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      final result = await action();
      return result;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.accounts',
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
