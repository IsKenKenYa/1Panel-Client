import '../../../data/models/file_models.dart';
import '../../../data/repositories/files_repository.dart';

class FileRecycleService {
  FileRecycleService({FilesRepository? repository})
      : _repository = repository ?? FilesRepository();

  final FilesRepository _repository;

  Future<void> ensureServer() async {
    await _repository.getCurrentServer();
  }

  Future<FileRecycleStatus> getRecycleBinStatus() async {
    final api = await _repository.getApi();
    final response = await api.getRecycleBinStatus();
    return response.data ?? const FileRecycleStatus(fileCount: 0, totalSize: 0);
  }

  Future<List<FileInfo>> searchRecycleBin({
    required String path,
    int page = 1,
    int pageSize = 100,
  }) async {
    final api = await _repository.getApi();
    final response = await api.searchRecycleBin(
      FileSearch(path: path, page: page, pageSize: pageSize),
    );
    return response.data ?? const <FileInfo>[];
  }

  Future<void> clearRecycleBin() async {
    final api = await _repository.getApi();
    await api.clearRecycleBin();
  }

  Future<void> restoreFile(RecycleBinReduceRequest request) async {
    final api = await _repository.getApi();
    await api.restoreRecycleBinFile(request);
  }

  Future<void> restoreFiles(List<RecycleBinReduceRequest> requests) async {
    final api = await _repository.getApi();
    for (final request in requests) {
      await api.restoreRecycleBinFile(request);
    }
  }

  Future<void> deleteRecycleBinFiles(List<RecycleBinItem> files) async {
    final api = await _repository.getApi();
    for (final file in files) {
      final recyclePath = '${file.from}/${file.rName}';
      await api.deleteFile(FileDelete(path: recyclePath, forceDelete: true));
    }
  }
}
