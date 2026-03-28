import '../../../data/models/file_models.dart';
import '../../../data/repositories/files_repository.dart';

class FilePreviewService {
  FilePreviewService({FilesRepository? repository})
      : _repository = repository ?? FilesRepository();

  final FilesRepository _repository;

  Future<void> ensureServer() async {
    await _repository.getCurrentServer();
  }

  Future<String> getFileContent(String path) async {
    final api = await _repository.getApi();
    final response = await api.getFileContent(path);
    return response.data ?? '';
  }

  Future<String> previewFile(
    String path, {
    int? line,
    int? limit,
  }) async {
    final api = await _repository.getApi();
    final response = await api.previewFile(
      FilePreviewRequest(path: path, line: line, limit: limit),
    );
    return response.data ?? '';
  }

  Future<void> saveFile(
    String path,
    String content, {
    String? encoding,
    bool? createDir,
  }) async {
    final api = await _repository.getApi();
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
    final api = await _repository.getApi();
    final response = await api.readFile(
      FileRead(path: path, offset: offset, length: length, encoding: encoding),
    );
    return response.data ?? '';
  }

  Future<List<int>> downloadFileBytes(String path) async {
    final api = await _repository.getApi();
    final response = await api.downloadFile(path);
    return response.data ?? const <int>[];
  }
}
