import 'package:flutter/material.dart';
import 'package:onepanelapp_app/data/models/file_models.dart';
import 'package:onepanelapp_app/features/files/models/models.dart';
import 'package:onepanelapp_app/features/files/files_provider.dart';

/// Mock FilesProvider for testing
class MockFilesProvider extends FilesProvider {
  FilesData _mockData = const FilesData(
    currentPath: '/home',
    selectedFiles: {'/home/test.txt', '/home/test2.txt'},
  );

  @override
  FilesData get data => _mockData;

  void setMockData(FilesData data) {
    _mockData = data;
    notifyListeners();
  }

  @override
  Future<void> createDirectory(String name) async {}

  @override
  Future<void> createFile(String name, {String? content}) async {}

  @override
  Future<void> renameFile(String oldPath, String newName) async {}

  @override
  Future<void> moveFile(String sourcePath, String targetPath) async {}

  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {}

  @override
  Future<void> extractFile(String path, String dst, String type, {String? secret}) async {}

  @override
  Future<void> compressFiles(List<String> files, String dst, String name, String type, {String? secret}) async {}

  @override
  Future<void> deleteSelected() async {}

  @override
  Future<void> deleteFile(String path) async {}

  @override
  Future<void> moveSelected(String targetPath) async {}

  @override
  Future<void> copySelected(String targetPath) async {}

  @override
  void setSearchQuery(String? query) {
    _mockData = _mockData.copyWith(searchQuery: query);
    notifyListeners();
  }

  @override
  void setSorting(String? sortBy, String? sortOrder) {
    _mockData = _mockData.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    notifyListeners();
  }

  @override
  Future<void> loadFiles({String? path}) async {}

  @override
  Future<void> wgetDownload({required String url, required String name, bool? ignoreCertificate}) async {}

  @override
  Future<void> uploadFiles(List<String> filePaths) async {}

  @override
  Future<FilePermission> getFilePermission(String path) async {
    return FilePermission(
      path: path,
      permission: '755',
      user: 'root',
      group: 'root',
    );
  }

  @override
  Future<FileUserGroupResponse> getUserGroup() async {
    return const FileUserGroupResponse(
      users: [
        FileUserGroup(user: 'root', group: 'root'),
        FileUserGroup(user: 'www-data', group: 'www-data'),
      ],
      groups: ['root', 'www-data', 'users'],
    );
  }

  @override
  Future<void> changeFileMode(String path, int mode, {bool? sub}) async {}

  @override
  Future<void> changeFileOwner(String path, String user, String group, {bool? sub}) async {}

  @override
  Future<void> addToFavorites(FileInfo file) async {}

  @override
  Future<void> removeFromFavorites(String path) async {}

  @override
  void toggleSelection(String path) {
    final newSelection = Set<String>.from(_mockData.selectedFiles);
    if (newSelection.contains(path)) {
      newSelection.remove(path);
    } else {
      newSelection.add(path);
    }
    _mockData = _mockData.copyWith(selectedFiles: newSelection);
    notifyListeners();
  }

  @override
  void selectAll() {
    final allPaths = _mockData.files.map((f) => f.path).toSet();
    _mockData = _mockData.copyWith(selectedFiles: allPaths);
    notifyListeners();
  }

  @override
  void clearSelection() {
    _mockData = _mockData.copyWith(selectedFiles: {});
    notifyListeners();
  }

  @override
  Future<void> refresh() async {}
}
