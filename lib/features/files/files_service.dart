import '../../data/models/file_models.dart';
import '../../core/config/api_config.dart';
import '../../data/repositories/files_repository.dart';
import 'services/file_browser_service.dart';
import 'services/file_preview_service.dart';
import 'services/file_recycle_service.dart';
import 'services/file_transfer_service.dart';

class FilesService {
  FilesService({
    FilesRepository? repository,
    FileBrowserService? browserService,
    FileRecycleService? recycleService,
    FileTransferService? transferService,
    FilePreviewService? previewService,
  }) {
    _repository = repository ?? FilesRepository();
    _browser = browserService ?? FileBrowserService(repository: _repository);
    _recycle = recycleService ?? FileRecycleService(repository: _repository);
    _transfer = transferService ?? FileTransferService(repository: _repository);
    _preview = previewService ?? FilePreviewService(repository: _repository);
  }

  late final FilesRepository _repository;
  late final FileBrowserService _browser;
  late final FileRecycleService _recycle;
  late final FileTransferService _transfer;
  late final FilePreviewService _preview;

  void clearCache() {
    _repository.clearCache();
  }

  Future<ApiConfig?> getCurrentServer() async {
    return _browser.getCurrentServer();
  }

  Future<FileSearchResponse> searchFiles({
    required String path,
    String? search,
    int page = 1,
    int pageSize = 100,
    bool? expand,
    String? sortBy,
    String? sortOrder,
  }) async {
    return _browser.searchFiles(
      path: path,
      search: search,
      page: page,
      pageSize: pageSize,
      expand: expand,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
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
    return _browser.getFiles(
      path: path,
      search: search,
      page: page,
      pageSize: pageSize,
      expand: expand,
      sortBy: sortBy,
      sortOrder: sortOrder,
      showHidden: showHidden,
    );
  }

  Future<void> createDirectory(String path) async {
    await _browser.createDirectory(path);
  }

  Future<void> createFile(String path, {String? content}) async {
    await _browser.createFile(path, content: content);
  }

  Future<void> deleteFiles(List<String> paths,
      {bool? force, bool? isDir}) async {
    await _browser.deleteFiles(paths, force: force, isDir: isDir);
  }

  Future<void> renameFile(String oldPath, String newPath) async {
    await _browser.renameFile(oldPath, newPath);
  }

  Future<void> moveFiles(List<String> paths, String targetPath) async {
    await _browser.moveFiles(paths, targetPath);
  }

  Future<void> copyFiles(List<String> paths, String targetPath,
      {String? newName}) async {
    await _browser.copyFiles(paths, targetPath, newName: newName);
  }

  Future<String> getFileContent(String path) async {
    return _browser.getFileContent(path);
  }

  Future<void> updateFileContent(String path, String content) async {
    await _browser.updateFileContent(path, content);
  }

  Future<void> compressFiles({
    required List<String> files,
    required String dst,
    required String name,
    required String type,
    String? secret,
  }) async {
    await _browser.compressFiles(
      files: files,
      dst: dst,
      name: name,
      type: type,
      secret: secret,
    );
  }

  Future<void> extractFile({
    required String path,
    required String dst,
    required String type,
    String? secret,
  }) async {
    await _browser.extractFile(
      path: path,
      dst: dst,
      type: type,
      secret: secret,
    );
  }

  Future<void> changeFileMode(String path, int mode, {bool? sub}) async {
    await _browser.changeFileMode(path, mode, sub: sub);
  }

  Future<void> changeFileOwner(String path, String user, String group,
      {bool? sub}) async {
    await _browser.changeFileOwner(path, user, group, sub: sub);
  }

  Future<void> batchChangeFileRole({
    required List<String> paths,
    int? mode,
    String? user,
    String? group,
    bool? sub,
  }) async {
    await _browser.batchChangeFileRole(
      paths: paths,
      mode: mode,
      user: user,
      group: group,
      sub: sub,
    );
  }

  Future<FileCheckResult> checkFile(String path) async {
    return _browser.checkFile(path);
  }

  Future<FileTree> getFileTree({
    required String path,
    int? maxDepth,
    bool? includeFiles,
    bool? includeHidden,
  }) async {
    return _browser.getFileTree(
      path: path,
      maxDepth: maxDepth,
      includeFiles: includeFiles,
      includeHidden: includeHidden,
    );
  }

  Future<FileSizeInfo> getFileSize(String path, {bool? recursive}) async {
    return _browser.getFileSize(path, recursive: recursive);
  }

  Future<void> favoriteFile(String path,
      {String? name, String? description}) async {
    await _browser.favoriteFile(path, name: name, description: description);
  }

  Future<void> unfavoriteFile(String path) async {
    await _browser.unfavoriteFile(path);
  }

  Future<List<FileInfo>> searchFavoriteFiles({
    required String path,
    int page = 1,
    int pageSize = 100,
  }) async {
    return _browser.searchFavoriteFiles(
        path: path, page: page, pageSize: pageSize);
  }

  Future<FileRecycleStatus> getRecycleBinStatus() async {
    return _recycle.getRecycleBinStatus();
  }

  Future<List<FileInfo>> searchRecycleBin({
    required String path,
    int page = 1,
    int pageSize = 100,
  }) async {
    return _recycle.searchRecycleBin(
        path: path, page: page, pageSize: pageSize);
  }

  Future<void> clearRecycleBin() async {
    await _recycle.clearRecycleBin();
  }

  Future<void> restoreFile(RecycleBinReduceRequest request) async {
    await _recycle.restoreFile(request);
  }

  Future<void> restoreFiles(List<RecycleBinReduceRequest> requests) async {
    await _recycle.restoreFiles(requests);
  }

  Future<void> deleteRecycleBinFiles(List<RecycleBinItem> files) async {
    await _recycle.deleteRecycleBinFiles(files);
  }

  Future<FileWgetResult> wgetDownload({
    required String url,
    required String path,
    required String name,
    bool? ignoreCertificate,
  }) async {
    return _transfer.wgetDownload(
      url: url,
      path: path,
      name: name,
      ignoreCertificate: ignoreCertificate,
    );
  }

  Future<List<FileInfo>> searchUploadedFiles({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    return _transfer.searchUploadedFiles(
      page: page,
      pageSize: pageSize,
      search: search,
    );
  }

  Future<FileDepthSizeInfo> getDepthSize(List<String> paths) async {
    return _browser.getDepthSize(paths);
  }

  Future<List<FileMountInfo>> getMountInfo() async {
    return _browser.getMountInfo();
  }

  Future<void> createFileLink({
    required String sourcePath,
    required String linkPath,
    required String linkType,
    bool? overwrite,
  }) async {
    await _browser.createFileLink(
      sourcePath: sourcePath,
      linkPath: linkPath,
      linkType: linkType,
      overwrite: overwrite,
    );
  }

  Future<void> convertFiles({
    required List<FileMediaConvertItem> files,
    required String outputPath,
    bool deleteSource = false,
    String? taskId,
  }) async {
    await _browser.convertFiles(
      files: files,
      outputPath: outputPath,
      deleteSource: deleteSource,
      taskId: taskId,
    );
  }

  Future<Map<String, String>> getFileRemarks(List<String> paths) async {
    return _browser.getFileRemarks(paths);
  }

  Future<void> setFileRemark(String path, String remark) async {
    await _browser.setFileRemark(path, remark);
  }

  Future<String> previewFile(String path, {int? line, int? limit}) async {
    return _preview.previewFile(path, line: line, limit: limit);
  }

  Future<FileUserGroupResponse> getUserGroup() async {
    return _browser.getUserGroup();
  }

  Future<FileBatchCheckResult> batchCheckFiles(List<String> paths) async {
    return _browser.batchCheckFiles(paths);
  }

  Future<void> saveFile(String path, String content,
      {String? encoding, bool? createDir}) async {
    await _preview.saveFile(path, content,
        encoding: encoding, createDir: createDir);
  }

  Future<String> readFile(String path,
      {int? offset, int? length, String? encoding}) async {
    return _preview.readFile(path,
        offset: offset, length: length, encoding: encoding);
  }

  Future<void> downloadFile(String path, String savePath) async {
    await _transfer.downloadFile(path, savePath);
  }

  Future<String> downloadFileToDevice(
    String filePath,
    String fileName, {
    Function(int received, int total)? onProgress,
  }) async {
    return _transfer.downloadFileToDevice(
      filePath,
      fileName,
      onProgress: onProgress,
    );
  }

  void cancelDownload() {
    _transfer.cancelDownload();
  }

  Future<bool> checkAndRequestStoragePermission() async {
    return _transfer.checkAndRequestStoragePermission();
  }

  Future<bool> isStoragePermissionPermanentlyDenied() async {
    return _transfer.isStoragePermissionPermanentlyDenied();
  }

  Future<void> uploadFile(String path, dynamic file) async {
    await _browser.uploadFile(path, file);
  }
}
