import 'package:flutter/material.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/services/php_runtime_service.dart';

class PhpExtensionsProvider extends ChangeNotifier with AsyncStateNotifier {
  PhpExtensionsProvider({
    PhpRuntimeService? service,
  }) : _service = service ?? PhpRuntimeService();

  final PhpRuntimeService _service;

  int? _runtimeId;
  String _runtimeName = '';
  String _keyword = '';
  PHPExtensionsRes _extensions = const PHPExtensionsRes();
  PageResult<PHPExtensionRecord> _extensionRecords =
      const PageResult<PHPExtensionRecord>(
    items: <PHPExtensionRecord>[],
    total: 0,
  );
  bool _isOperating = false;

  String get runtimeName => _runtimeName;
  String get keyword => _keyword;
  PHPExtensionsRes get extensions => _extensions;
  List<PHPExtensionRecord> get extensionRecords => _extensionRecords.items;
  bool get isOperating => _isOperating;

  List<PHPExtensionSupport> get filteredItems {
    final pattern = _keyword.trim().toLowerCase();
    if (pattern.isEmpty) {
      return _extensions.supportExtensions;
    }
    return _extensions.supportExtensions.where((item) {
      return item.name.toLowerCase().contains(pattern) ||
          (item.description ?? '').toLowerCase().contains(pattern);
    }).toList(growable: false);
  }

  Future<void> initialize(RuntimeManageArgs args) async {
    _runtimeId = args.runtimeId;
    _runtimeName = args.runtimeName ?? '';
    await load();
  }

  void updateKeyword(String value) {
    _keyword = value;
    notifyListeners();
  }

  Future<void> load() async {
    final runtimeId = _runtimeId;
    if (runtimeId == null) {
      setError('runtime.detail.loadFailed');
      return;
    }
    setLoading();
    try {
      _extensions = await _service.loadExtensions(runtimeId);
      await _loadExtensionRecords();
      setSuccess(
        isEmpty:
        _extensions.supportExtensions.isEmpty && _extensionRecords.items.isEmpty,
      );
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_extensions',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _extensions = const PHPExtensionsRes();
      _extensionRecords = const PageResult<PHPExtensionRecord>(
        items: <PHPExtensionRecord>[],
        total: 0,
      );
      setError('runtime.detail.loadFailed');
    }
  }

  Future<bool> createExtensionRecord(
    String name,
    String extensions,
  ) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return false;
    }
    _isOperating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.createExtensionRecord(
        name: trimmedName,
        extensions: extensions,
      );
      await _loadExtensionRecords();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_extensions',
        'create extension record failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.detail.operateFailed', notify: false);
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<bool> updateExtensionRecord(
    PHPExtensionRecord record,
    String extensions,
  ) async {
    if (record.id <= 0) {
      return false;
    }
    _isOperating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.updateExtensionRecord(
        id: record.id,
        extensions: extensions,
      );
      await _loadExtensionRecords();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_extensions',
        'update extension record failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.detail.operateFailed', notify: false);
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExtensionRecord(PHPExtensionRecord record) async {
    if (record.id <= 0) {
      return false;
    }
    _isOperating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.deleteExtensionRecord(record.id);
      await _loadExtensionRecords();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_extensions',
        'delete extension record failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.detail.operateFailed', notify: false);
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<bool> toggleExtension(PHPExtensionSupport item) async {
    final runtimeId = _runtimeId;
    if (runtimeId == null || item.name.trim().isEmpty) {
      return false;
    }
    _isOperating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      if (item.installed) {
        await _service.uninstallExtension(runtimeId, item.name);
      } else {
        await _service.installExtension(runtimeId, item.name);
      }
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.php_extensions',
        'toggle extension failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.detail.operateFailed', notify: false);
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<void> _loadExtensionRecords() async {
    try {
      _extensionRecords = await _service.loadExtensionRecords(
        all: true,
        pageSize: 200,
      );
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        'features.runtimes.providers.php_extensions',
        'load extension records failed: $error\n$stackTrace',
      );
      _extensionRecords = const PageResult<PHPExtensionRecord>(
        items: <PHPExtensionRecord>[],
        total: 0,
      );
    }
  }
}
