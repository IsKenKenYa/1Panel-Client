import '../../../data/models/file_models.dart';
import 'files_api_gateway.dart';

class FileRecycleService {
  FileRecycleService({FilesApiGateway? gateway})
      : _gateway = gateway ?? FilesApiGateway();

  final FilesApiGateway _gateway;

  Future<void> ensureServer() async {
    await _gateway.getCurrentServer();
  }

  Future<FileRecycleStatus> getRecycleBinStatus() async {
    final api = await _gateway.getApi();
    final response = await api.getRecycleBinStatus();
    return response.data!;
  }

  Future<List<FileInfo>> searchRecycleBin({
    required String path,
    int page = 1,
    int pageSize = 100,
  }) async {
    final api = await _gateway.getApi();
    final response = await api.searchRecycleBin(
      FileSearch(path: path, page: page, pageSize: pageSize),
    );
    return response.data ?? const <FileInfo>[];
  }

  Future<void> clearRecycleBin() async {
    final api = await _gateway.getApi();
    await api.clearRecycleBin();
  }

  Future<void> restoreFile(RecycleBinReduceRequest request) async {
    final api = await _gateway.getApi();
    await api.restoreRecycleBinFile(request);
  }

  Future<void> restoreFiles(List<RecycleBinReduceRequest> requests) async {
    final api = await _gateway.getApi();
    for (final request in requests) {
      await api.restoreRecycleBinFile(request);
    }
  }

  Future<void> deleteRecycleBinFiles(List<RecycleBinItem> files) async {
    final api = await _gateway.getApi();
    for (final file in files) {
      final recyclePath = '${file.from}/${file.rName}';
      await api.deleteFile(FileDelete(path: recyclePath, forceDelete: true));
    }
  }
}
