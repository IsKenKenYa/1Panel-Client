import '../../../api/v2/file_v2.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../data/models/file_models.dart';
import '../../../data/repositories/files_repository.dart';

class FilePreviewService {
  FilePreviewService({FilesRepository? repository})
      : _repository = repository ?? FilesRepository();

  final FilesRepository _repository;
  FileV2Api? _previewApi;
  late final String cacheConnectionId;

  Future<FileV2Api> _api() async {
    return _previewApi ?? await _repository.getApi();
  }

  Future<void> ensureServer() async {
    if (_previewApi != null) return;
    final server = await _repository.getCurrentServer() ??
        (throw const NetworkConnectionException('未配置服务器连接'));
    if (_previewApi != null) return;
    _previewApi = _repository.getApiForConfig(server);
    cacheConnectionId = server.credentialId;
  }

  Future<String> getFileContent(String path) async {
    final api = await _api();
    final response = await api.getFileContent(path);
    return response.data ?? '';
  }

  Future<String> previewFile(
    String path, {
    int? line,
    int? limit,
  }) async {
    final api = await _api();
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
    final api = await _api();
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
    final api = await _api();
    final response = await api.readFile(
      FileRead(path: path, offset: offset, length: length, encoding: encoding),
    );
    return response.data ?? '';
  }

  Future<List<int>> downloadFileBytes(String path) async {
    final api = await _api();
    final response = await api.downloadFile(path);
    return response.data ?? const <int>[];
  }
}
