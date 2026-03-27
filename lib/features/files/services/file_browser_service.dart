import '../../../core/config/api_config.dart';
import '../../../data/models/file_models.dart';
import 'files_api_gateway.dart';

class FileBrowserService {
  FileBrowserService({FilesApiGateway? gateway})
      : _gateway = gateway ?? FilesApiGateway();

  final FilesApiGateway _gateway;

  Future<ApiConfig?> getCurrentServer() => _gateway.getCurrentServer();

  void clearCache() => _gateway.clearCache();

  Future<FileSearchResponse> searchFiles({
    required String path,
    String? search,
    int page = 1,
    int pageSize = 100,
    bool? expand,
    String? sortBy,
    String? sortOrder,
  }) async {
    final api = await _gateway.getApi();
    final response = await api.searchFiles(
      FileSearch(
        path: path,
        search: search,
        page: page,
        pageSize: pageSize,
        expand: expand,
        sortBy: sortBy,
        sortOrder: sortOrder,
      ),
    );
    return response.data!;
  }

  Future<List<FileInfo>> getFiles({
    required String path,
    String? search,
    int page = 1,
    int pageSize = 100,
    bool expand = true,
    String? sortBy,
    String? sortOrder,
    bool? showHidden,
  }) async {
    final api = await _gateway.getApi();
    final response = await api.getFiles(
      FileSearch(
        path: path,
        search: search,
        page: page,
        pageSize: pageSize,
        expand: expand,
        sortBy: sortBy,
        sortOrder: sortOrder,
        showHidden: showHidden,
      ),
    );
    return response.data ?? const <FileInfo>[];
  }

  Future<void> createDirectory(String path) async {
    final api = await _gateway.getApi();
    await api.createDirectory(FileCreate(path: path, isDir: true));
  }

  Future<void> createFile(String path, {String? content}) async {
    final api = await _gateway.getApi();
    await api
        .createFile(FileCreate(path: path, content: content, isDir: false));
  }

  Future<void> deleteFiles(
    List<String> paths, {
    bool? force,
    bool? isDir,
  }) async {
    final api = await _gateway.getApi();
    if (paths.length == 1) {
      await api.deleteFile(
        FileDelete(path: paths.first, isDir: isDir, forceDelete: force),
      );
      return;
    }
    await api.deleteFiles(FileBatchDelete(paths: paths, isDir: isDir));
  }

  Future<void> renameFile(String oldPath, String newPath) async {
    final api = await _gateway.getApi();
    await api.renameFile(FileRename(oldPath: oldPath, newPath: newPath));
  }

  Future<void> moveFiles(List<String> paths, String targetPath) async {
    final api = await _gateway.getApi();
    await api.moveFiles(
      FileMove(paths: paths, targetPath: targetPath, type: 'cut'),
    );
  }

  Future<void> copyFiles(
    List<String> paths,
    String targetPath, {
    String? newName,
  }) async {
    final api = await _gateway.getApi();
    for (final sourcePath in paths) {
      final sourceDir = sourcePath.substring(0, sourcePath.lastIndexOf('/'));
      final sourceName = sourcePath.substring(sourcePath.lastIndexOf('/') + 1);

      var nextName = newName;
      if (sourceDir == targetPath && nextName == null) {
        nextName = _generateCopyName(sourceName);
      }

      await api.moveFiles(
        FileMove(
          paths: <String>[sourcePath],
          targetPath: targetPath,
          type: 'copy',
          name: nextName,
        ),
      );
    }
  }

  Future<String> getFileContent(String path) async {
    final api = await _gateway.getApi();
    final response = await api.getFileContent(path);
    return response.data ?? '';
  }

  Future<void> updateFileContent(String path, String content) async {
    final api = await _gateway.getApi();
    await api.updateFileContent(FileContent(path: path, content: content));
  }

  Future<void> compressFiles({
    required List<String> files,
    required String dst,
    required String name,
    required String type,
    String? secret,
  }) async {
    final api = await _gateway.getApi();
    await api.compressFiles(
      FileCompress(
        files: files,
        dst: dst,
        name: name,
        type: type,
        secret: secret,
      ),
    );
  }

  Future<void> extractFile({
    required String path,
    required String dst,
    required String type,
    String? secret,
  }) async {
    final api = await _gateway.getApi();
    await api.extractFile(
      FileExtract(path: path, dst: dst, type: type, secret: secret),
    );
  }

  Future<void> changeFileMode(String path, int mode, {bool? sub}) async {
    final api = await _gateway.getApi();
    await api.updateFileMode(FileModeChange(path: path, mode: mode, sub: sub));
  }

  Future<void> changeFileOwner(
    String path,
    String user,
    String group, {
    bool? sub,
  }) async {
    final api = await _gateway.getApi();
    await api.updateFileOwner(
      FileOwnerChange(path: path, user: user, group: group, sub: sub),
    );
  }

  Future<void> batchChangeFileRole({
    required List<String> paths,
    int? mode,
    String? user,
    String? group,
    bool? sub,
  }) async {
    final api = await _gateway.getApi();
    await api.batchChangeFileRole(
      FileBatchRoleRequest(
        paths: paths,
        mode: mode,
        user: user,
        group: group,
        sub: sub,
      ),
    );
  }

  Future<FileCheckResult> checkFile(String path) async {
    final api = await _gateway.getApi();
    final response = await api.checkFile(FileCheck(path: path));
    return response.data!;
  }

  Future<FileTree> getFileTree({
    required String path,
    int? maxDepth,
    bool? includeFiles,
    bool? includeHidden,
  }) async {
    final api = await _gateway.getApi();
    final response = await api.getFileTree(
      FileTreeRequest(
        path: path,
        maxDepth: maxDepth,
        includeFiles: includeFiles,
        includeHidden: includeHidden,
      ),
    );
    return response.data!;
  }

  Future<FileSizeInfo> getFileSize(String path, {bool? recursive}) async {
    final api = await _gateway.getApi();
    final response = await api.getFileSize(
      FileSizeRequest(path: path, recursive: recursive),
    );
    return response.data!;
  }

  Future<void> favoriteFile(
    String path, {
    String? name,
    String? description,
  }) async {
    final api = await _gateway.getApi();
    await api.favoriteFile(
        FileFavorite(path: path, name: name, description: description));
  }

  Future<void> unfavoriteFile(String path) async {
    final api = await _gateway.getApi();
    await api.unfavoriteFile(FileUnfavorite(path: path));
  }

  Future<List<FileInfo>> searchFavoriteFiles({
    required String path,
    int page = 1,
    int pageSize = 100,
  }) async {
    final api = await _gateway.getApi();
    final response = await api.searchFavoriteFiles(
      FileSearch(path: path, page: page, pageSize: pageSize),
    );
    return response.data ?? const <FileInfo>[];
  }

  Future<FileDepthSizeInfo> getDepthSize(List<String> paths) async {
    final api = await _gateway.getApi();
    final response = await api.getDepthSize(FileDepthSizeRequest(paths: paths));
    return response.data!;
  }

  Future<List<FileMountInfo>> getMountInfo() async {
    final api = await _gateway.getApi();
    final response = await api.getMountInfo();
    return response.data ?? const <FileMountInfo>[];
  }

  Future<void> createFileLink({
    required String sourcePath,
    required String linkPath,
    required String linkType,
    bool? overwrite,
  }) async {
    final api = await _gateway.getApi();
    await api.createFileLink(
      FileLinkCreate(
        sourcePath: sourcePath,
        linkPath: linkPath,
        linkType: linkType,
        overwrite: overwrite,
      ),
    );
  }

  Future<FileUserGroupResponse> getUserGroup() async {
    final api = await _gateway.getApi();
    final response = await api.getUserGroup();
    return response.data!;
  }

  Future<FileBatchCheckResult> batchCheckFiles(List<String> paths) async {
    final api = await _gateway.getApi();
    final response =
        await api.batchCheckFiles(FileBatchCheckRequest(paths: paths));
    return response.data!;
  }

  Future<void> saveFile(
    String path,
    String content, {
    String? encoding,
    bool? createDir,
  }) async {
    final api = await _gateway.getApi();
    await api.saveFile(
      FileSave(
        path: path,
        content: content,
        encoding: encoding,
        createDir: createDir,
      ),
    );
  }

  Future<String> readFile(
    String path, {
    int? offset,
    int? length,
    String? encoding,
  }) async {
    final api = await _gateway.getApi();
    final response = await api.readFile(
      FileRead(path: path, offset: offset, length: length, encoding: encoding),
    );
    return response.data ?? '';
  }

  Future<void> uploadFile(String path, dynamic file) async {
    final api = await _gateway.getApi();
    await api.uploadFile(path, file);
  }

  String _generateCopyName(String originalName) {
    final lastDot = originalName.lastIndexOf('.');
    final hasExtension = lastDot > 0;
    final baseName =
        hasExtension ? originalName.substring(0, lastDot) : originalName;
    final extension = hasExtension ? originalName.substring(lastDot) : '';
    return '$baseName (1)$extension';
  }
}
