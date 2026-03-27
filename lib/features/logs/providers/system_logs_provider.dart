import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/logs/models/system_log_viewer_args.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

enum SystemLogSource { agent, core }

class SystemLogsProvider extends ChangeNotifier {
  SystemLogsProvider({
    LogsService? service,
  }) : _service = service ?? LogsService();

  final LogsService _service;

  List<String> _files = const <String>[];
  bool _filesLoading = false;
  String? _filesError;
  String? _selectedFile;
  SystemLogSource _source = SystemLogSource.agent;
  bool _watchEnabled = false;

  bool _contentLoading = false;
  String? _contentError;
  String _content = '';
  String _contentPath = '';

  List<String> get files => _files;
  bool get filesLoading => _filesLoading;
  String? get filesError => _filesError;
  bool get filesEmpty =>
      !_filesLoading && _filesError == null && _files.isEmpty;
  String? get selectedFile => _selectedFile;
  SystemLogSource get source => _source;
  bool get watchEnabled => _watchEnabled;

  bool get contentLoading => _contentLoading;
  String? get contentError => _contentError;
  String get content => _content;
  String get contentPath => _contentPath;
  bool get hasSelectedFile =>
      _selectedFile != null && _selectedFile!.isNotEmpty;

  Future<void> initialize([SystemLogViewerArgs? args]) async {
    _source = args?.useCoreLogs == true
        ? SystemLogSource.core
        : SystemLogSource.agent;
    await loadFiles(initialFileName: args?.initialFileName, loadContent: true);
  }

  Future<void> loadFiles({
    String? initialFileName,
    bool loadContent = false,
  }) async {
    _filesLoading = true;
    _filesError = null;
    notifyListeners();
    try {
      _files = await _service.loadSystemLogFiles();
      if (_files.isEmpty) {
        _selectedFile = null;
        _content = '';
        _contentPath = '';
      } else {
        _selectedFile = _resolveSelectedFile(initialFileName);
        if (loadContent && hasSelectedFile) {
          await loadSelectedFile();
        }
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.system_logs',
        'loadFiles failed',
        error: error,
        stackTrace: stackTrace,
      );
      _files = const <String>[];
      _selectedFile = null;
      _content = '';
      _contentPath = '';
      _filesError = 'logs.system.filesLoadFailed';
    } finally {
      _filesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSelectedFile({bool latest = true}) async {
    final file = _selectedFile;
    if (file == null || file.isEmpty) return;

    _contentLoading = true;
    _contentError = null;
    notifyListeners();
    try {
      final result = await _service.loadSystemLogContent(
        fileName: file,
        useCoreLogs: _source == SystemLogSource.core,
        latest: latest,
      );
      _content = result.lines.join('\n');
      _contentPath = result.path;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.system_logs',
        'loadSelectedFile failed',
        error: error,
        stackTrace: stackTrace,
      );
      _content = '';
      _contentPath = '';
      _contentError = 'logs.system.contentLoadFailed';
    } finally {
      _contentLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectFile(String fileName) async {
    _selectedFile = fileName;
    notifyListeners();
    await loadSelectedFile();
  }

  Future<void> updateSource(SystemLogSource source) async {
    _source = source;
    notifyListeners();
    if (hasSelectedFile) {
      await loadSelectedFile();
    }
  }

  void updateWatchEnabled(bool value) {
    _watchEnabled = value;
    notifyListeners();
  }

  String _resolveSelectedFile(String? initialFileName) {
    if (initialFileName != null && _files.contains(initialFileName)) {
      return initialFileName;
    }
    final currentFile = _selectedFile;
    if (currentFile != null && _files.contains(currentFile)) {
      return currentFile;
    }
    return _files.first;
  }
}
