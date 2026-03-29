import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/command_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/commands/services/command_service.dart';

class CommandsProvider extends ChangeNotifier with AsyncStateNotifier {
  CommandsProvider({
    CommandService? service,
  }) : _service = service ?? CommandService();

  final CommandService _service;

  List<CommandInfo> _commands = const <CommandInfo>[];
  List<GroupInfo> _groups = const <GroupInfo>[];
  final Set<int> _selectedIds = <int>{};
  final Set<int> _selectedPreviewIds = <int>{};
  List<CommandInfo> _importPreviewItems = const <CommandInfo>[];
  String _searchQuery = '';
  int? _selectedGroupId;
  bool _isDeleting = false;
  bool _isExporting = false;
  bool _isImporting = false;

  List<CommandInfo> get commands => _commands;
  List<GroupInfo> get groups => _groups;
  Set<int> get selectedIds => Set<int>.unmodifiable(_selectedIds);
  Set<int> get selectedPreviewIds => Set<int>.unmodifiable(_selectedPreviewIds);
  List<CommandInfo> get importPreviewItems => _importPreviewItems;
  String get searchQuery => _searchQuery;
  int? get selectedGroupId => _selectedGroupId;
  bool get isDeleting => _isDeleting;
  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  bool get hasSelection => _selectedIds.isNotEmpty;
  bool get hasImportPreview => _importPreviewItems.isNotEmpty;

  Future<void> load({bool forceRefresh = false}) async {
    setLoading();
    try {
      _groups = await _service.loadGroups(forceRefresh: forceRefresh);
      final result = await _service.searchCommands(
        CommandSearchRequest(
          info: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
          groupID: _selectedGroupId,
        ),
      );
      _commands = result.items;
      _selectedIds.clear();
      setSuccess(isEmpty: _commands.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.commands.providers.commands',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _commands = const <CommandInfo>[];
      setError(error);
    }
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateGroupFilter(int? groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  Future<void> deleteCommand(CommandInfo item) async {
    final id = item.id;
    if (id == null) {
      return;
    }
    await _deleteByIds(<int>[id]);
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    await _deleteByIds(_selectedIds.toList(growable: false));
  }

  Future<FileSaveResult?> exportAllCommands() async {
    _isExporting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      return await _service.exportCommandsCsv();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.commands.providers.commands',
        'exportAllCommands failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> loadImportPreview({
    required Uint8List bytes,
    required String fileName,
  }) async {
    _isImporting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      final rawPreview = await _service.parseImportPreviewCsv(
        bytes: bytes,
        fileName: fileName,
      );
      _importPreviewItems = rawPreview.asMap().entries.map((entry) {
        final item = entry.value;
        return CommandInfo(
          id: item.id ?? -(entry.key + 1),
          name: item.name,
          type: item.type,
          command: item.command,
          groupID: item.groupID,
          groupBelong: item.groupBelong,
        );
      }).toList(growable: false);
      _selectedPreviewIds
        ..clear()
        ..addAll(
          _importPreviewItems
              .where((item) => item.id != null)
              .map((item) => item.id!)
              .toList(growable: false),
        );
      setSuccess(
        isEmpty: _commands.isEmpty,
        notify: false,
      );
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.commands.providers.commands',
        'loadImportPreview failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  void clearImportPreview() {
    _importPreviewItems = const <CommandInfo>[];
    _selectedPreviewIds.clear();
    notifyListeners();
  }

  void togglePreviewSelection(int? id) {
    if (id == null) {
      return;
    }
    if (_selectedPreviewIds.contains(id)) {
      _selectedPreviewIds.remove(id);
    } else {
      _selectedPreviewIds.add(id);
    }
    notifyListeners();
  }

  void selectAllPreview() {
    _selectedPreviewIds
      ..clear()
      ..addAll(
        _importPreviewItems
            .where((item) => item.id != null)
            .map((item) => item.id!)
            .toList(growable: false),
      );
    notifyListeners();
  }

  void applyGroupToPreview(int groupId) {
    final target = _groups.firstWhere(
      (group) => group.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );
    _importPreviewItems = _service.applyGroupToPreview(
      previewItems: _importPreviewItems,
      group: target,
    );
    notifyListeners();
  }

  Future<bool> importSelectedPreview() async {
    if (_selectedPreviewIds.isEmpty) {
      return false;
    }

    _isImporting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      final items = _importPreviewItems
          .where((item) =>
              item.id != null && _selectedPreviewIds.contains(item.id))
          .map(_service.toOperate)
          .toList(growable: false);
      await _service.importCommands(items);
      clearImportPreview();
      await load(forceRefresh: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.commands.providers.commands',
        'importSelectedPreview failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> _deleteByIds(List<int> ids) async {
    _isDeleting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.deleteCommands(ids);
      await load(forceRefresh: true);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.commands.providers.commands',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
