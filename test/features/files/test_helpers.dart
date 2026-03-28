import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/models/models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

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

  Future<void> createDirectory(String name) async {}

  Future<void> createFile(String name, {String? content}) async {}

  Future<void> renameFile(String oldPath, String newName) async {}

  Future<void> moveFile(String sourcePath, String targetPath) async {}

  Future<void> copyFile(String sourcePath, String targetPath) async {}

  Future<void> extractFile(String path, String dst, String type,
      {String? secret}) async {}

  Future<void> compressFiles(
      List<String> files, String dst, String name, String type,
      {String? secret}) async {}

  Future<void> deleteSelected() async {}

  Future<void> deleteFile(String path) async {}

  Future<void> moveSelected(String targetPath) async {}

  Future<void> copySelected(String targetPath) async {}

  void setSearchQuery(String? query) {
    _mockData = _mockData.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setSorting(String? sortBy, String? sortOrder) {
    _mockData = _mockData.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    notifyListeners();
  }

  Future<void> loadFiles({String? path}) async {}

  Future<void> wgetDownload(
      {required String url,
      required String name,
      bool? ignoreCertificate}) async {}

  Future<void> uploadFiles(List<String> filePaths) async {}

  Future<FilePermission> getFilePermission(String path) async {
    return FilePermission(
      path: path,
      permission: '755',
      user: 'root',
      group: 'root',
    );
  }

  Future<FileUserGroupResponse> getUserGroup() async {
    return const FileUserGroupResponse(
      users: [
        FileUserGroup(user: 'root', group: 'root'),
        FileUserGroup(user: 'www-data', group: 'www-data'),
      ],
      groups: ['root', 'www-data', 'users'],
    );
  }

  Future<void> changeFileMode(String path, int mode, {bool? sub}) async {}

  Future<void> changeFileOwner(String path, String user, String group,
      {bool? sub}) async {}

  Future<void> addToFavorites(FileInfo file) async {}

  Future<void> removeFromFavorites(String path) async {}

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

  void selectAll() {
    final allPaths = _mockData.files.map((f) => f.path).toSet();
    _mockData = _mockData.copyWith(selectedFiles: allPaths);
    notifyListeners();
  }

  void clearSelection() {
    _mockData = _mockData.copyWith(selectedFiles: {});
    notifyListeners();
  }

  Future<void> refresh() async {}
}
