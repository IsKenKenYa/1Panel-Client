import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/services/file_recycle_service.dart';

class RecycleBinProvider extends ChangeNotifier with SafeChangeNotifier {
  RecycleBinProvider({FileRecycleService? service})
      : _service = service ?? FileRecycleService();

  final FileRecycleService _service;

  List<RecycleBinItem> _files = const <RecycleBinItem>[];
  List<RecycleBinItem> _filteredFiles = const <RecycleBinItem>[];
  Set<String> _selectedIds = <String>{};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  List<RecycleBinItem> get files => _files;
  List<RecycleBinItem> get filteredFiles => _filteredFiles;
  Set<String> get selectedIds => _selectedIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<RecycleBinItem> get selectedFiles =>
      _files.where((file) => _selectedIds.contains(file.rName)).toList();

  Future<void> initialize() async {
    await _service.ensureServer();
    await loadFiles();
  }

  Future<void> loadFiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final files = await _service.searchRecycleBin(path: '/');
      _files = files.map(_toRecycleBinItem).toList(growable: false);
      _selectedIds = <String>{};
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterFiles(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void toggleSelection(String recycleName) {
    final next = Set<String>.from(_selectedIds);
    if (next.contains(recycleName)) {
      next.remove(recycleName);
    } else {
      next.add(recycleName);
    }
    _selectedIds = next;
    notifyListeners();
  }

  void selectAll() {
    _selectedIds = _filteredFiles.map((file) => file.rName).toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds = <String>{};
    notifyListeners();
  }

  Future<void> restoreSelected() async {
    if (selectedFiles.isEmpty) return;
    final requests = selectedFiles
        .map(
          (file) => RecycleBinReduceRequest(
            rName: file.rName,
            from: file.from,
            name: file.name,
          ),
        )
        .toList(growable: false);
    await _service.restoreFiles(requests);
    await loadFiles();
  }

  Future<void> restoreSingle(RecycleBinItem file) async {
    await _service.restoreFile(
      RecycleBinReduceRequest(
        rName: file.rName,
        from: file.from,
        name: file.name,
      ),
    );
    await loadFiles();
  }

  Future<void> deletePermanentlySelected() async {
    if (selectedFiles.isEmpty) return;
    await _service.deleteRecycleBinFiles(selectedFiles);
    await loadFiles();
  }

  Future<void> deletePermanentlySingle(RecycleBinItem file) async {
    await _service.deleteRecycleBinFiles(<RecycleBinItem>[file]);
    await loadFiles();
  }

  Future<void> clearRecycleBin() async {
    await _service.clearRecycleBin();
    await loadFiles();
  }

  RecycleBinItem _toRecycleBinItem(FileInfo file) {
    return RecycleBinItem(
      sourcePath: file.path,
      name: file.name,
      isDir: file.isDir,
      size: file.size,
      deleteTime: file.modifiedAt,
      rName: file.rName ?? file.gid ?? file.path.split('/').last,
      from: file.from ?? '/',
    );
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredFiles = _files;
      return;
    }
    final keyword = _searchQuery.toLowerCase();
    _filteredFiles = _files.where((file) {
      return file.name.toLowerCase().contains(keyword) ||
          file.sourcePath.toLowerCase().contains(keyword);
    }).toList(growable: false);
  }
}
