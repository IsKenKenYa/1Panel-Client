import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:onepanel_client/features/files/services/file_preview_service.dart';

enum PreviewFileType {
  image,
  video,
  audio,
  markdown,
  pdf,
  text,
  unknown,
}

typedef PreviewCacheLoader = Future<CacheResult?> Function({
  required String filePath,
  required String fileName,
  required Future<Uint8List> Function() downloadFn,
  required CacheStrategy strategy,
});

typedef PreviewTempSaver = Future<String?> Function(
  Uint8List data,
  String fileName,
);

class FilePreviewProvider extends ChangeNotifier {
  FilePreviewProvider({
    required this.filePath,
    required this.fileName,
    this.fileSize,
    this.initialLine,
    FilePreviewService? service,
    FilePreviewCacheManager? cacheManager,
    PreviewCacheLoader? cacheLoader,
    PreviewTempSaver? tempSaver,
  })  : _service = service ?? FilePreviewService(),
        _cacheManager = cacheManager ??
            ((cacheLoader == null || tempSaver == null)
                ? FilePreviewCacheManager()
                : null),
        _cacheLoader = cacheLoader,
        _tempSaver = tempSaver;

  final String filePath;
  final String fileName;
  final int? fileSize;
  final int? initialLine;
  final FilePreviewService _service;
  final FilePreviewCacheManager? _cacheManager;
  final PreviewCacheLoader? _cacheLoader;
  final PreviewTempSaver? _tempSaver;

  String? _content;
  bool _isLoading = true;
  String? _error;
  late final PreviewFileType _fileType = _resolveFileType(fileName);
  String? _localFilePath;
  CacheSource? _cacheSource;
  final List<String> _pagedLines = <String>[];
  bool _usePagedTextPreview = false;
  bool _isLoadingMore = false;
  bool _hasMoreLines = true;
  int _baseLine = 1;
  int? _highlightLine;
  bool _awaitingMediaInitialization = false;

  static const int _largeTextThresholdBytes = 1024 * 1024;
  static const int _previewPageSize = 200;
  static const int _previewContextLines = 40;

  static const Set<String> _imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'svg',
    'bmp',
    'ico'
  };
  static const Set<String> _videoExtensions = <String>{
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
    '3gp',
    'flv',
    'wmv'
  };
  static const Set<String> _audioExtensions = <String>{
    'mp3',
    'wav',
    'ogg',
    'm4a',
    'aac',
    'flac',
    'wma'
  };
  static const Set<String> _markdownExtensions = <String>{'md', 'markdown'};
  static const Set<String> _pdfExtensions = <String>{'pdf'};
  static const Set<String> _textExtensions = <String>{
    'txt',
    'json',
    'xml',
    'yaml',
    'yml',
    'html',
    'css',
    'js',
    'ts',
    'dart',
    'py',
    'java',
    'c',
    'cpp',
    'h',
    'hpp',
    'sh',
    'bash',
    'sql',
    'log',
    'conf',
    'ini',
    'env',
    'gitignore',
    'dockerfile',
    'makefile',
    'toml',
    'gradle',
    'properties',
    'vue',
    'jsx',
    'tsx',
    'scss',
    'sass',
    'less',
    'go',
    'rs',
    'swift',
    'kt',
    'scala',
    'rb',
    'php',
    'pl',
    'lua',
    'bat',
    'ps1',
    'psm1',
    'psd1',
    'vbs',
    'cmd',
    'awk',
    'sed',
    'fish',
    'zsh',
    'csh',
    'tcsh',
    'ksh',
    'r',
    'm',
    'mm',
    'clj',
    'cljs',
    'hs',
    'erl',
    'ex',
    'exs',
    'lisp',
    'lsp',
    'scm',
    'rkt',
    'nim',
    'cr',
    'd',
    'f90',
    'f95',
    'f03',
    'for',
    'pas',
    'pp',
    'jl',
    'ml',
    'mli',
    'elm',
    'idr',
    'agda',
    'coq',
    'v',
    'sv',
    'vhdl',
    'verilog',
    'tcl',
    'proto',
    'graphql',
    'gql',
    'rego',
    'hcl',
    'tf',
    'tfvars',
    'nomad',
    'sls',
    'cfg',
    'config',
  };

  String? get content => _content;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PreviewFileType get fileType => _fileType;
  String? get localFilePath => _localFilePath;
  CacheSource? get cacheSource => _cacheSource;
  List<String> get pagedLines => List<String>.unmodifiable(_pagedLines);
  bool get usePagedTextPreview => _usePagedTextPreview;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreLines => _hasMoreLines;
  int get baseLine => _baseLine;
  int? get highlightLine => _highlightLine;
  bool get awaitingMediaInitialization => _awaitingMediaInitialization;
  bool get requiresVideoPlayer =>
      _fileType == PreviewFileType.video && _localFilePath != null;
  bool get requiresAudioPlayer =>
      _fileType == PreviewFileType.audio && _localFilePath != null;

  Future<void> initialize({
    required CacheStrategy cacheStrategy,
    required int cacheMaxSizeMB,
  }) async {
    _cacheManager?.initialize(
      strategy: cacheStrategy,
      maxSizeMB: cacheMaxSizeMB,
    );
    await _service.ensureServer();

    if (_fileType == PreviewFileType.image ||
        _fileType == PreviewFileType.video ||
        _fileType == PreviewFileType.pdf ||
        _fileType == PreviewFileType.audio) {
      await _downloadAndPrepare(cacheStrategy);
      return;
    }

    final forcePaged = initialLine != null;
    _usePagedTextPreview = forcePaged ||
        (_fileType == PreviewFileType.text &&
            (fileSize != null && fileSize! >= _largeTextThresholdBytes));

    if (_usePagedTextPreview) {
      await loadPreviewWindow(initialLine: initialLine ?? 1);
      return;
    }

    await loadContent();
  }

  Future<void> loadContent() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _content = await _service.getFileContent(filePath);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPreviewWindow({required int initialLine}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final startLine = (initialLine - _previewContextLines).clamp(1, 1 << 30);
      final text = await _service.previewFile(
        filePath,
        line: startLine,
        limit: _previewPageSize,
      );
      final lines = text.split('\n');
      _pagedLines
        ..clear()
        ..addAll(lines);
      _baseLine = startLine;
      _highlightLine = initialLine;
      _hasMoreLines = lines.length >= _previewPageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePreviewLines() async {
    if (_isLoadingMore || !_hasMoreLines) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextLine = _baseLine + _pagedLines.length;
      final text = await _service.previewFile(
        filePath,
        line: nextLine,
        limit: _previewPageSize,
      );
      final lines = text.isEmpty ? <String>[] : text.split('\n');
      _pagedLines.addAll(lines);
      _hasMoreLines = lines.length >= _previewPageSize;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void completeMediaInitialization() {
    _awaitingMediaInitialization = false;
    _isLoading = false;
    notifyListeners();
  }

  void failMediaInitialization(Object error) {
    _awaitingMediaInitialization = false;
    _error = error.toString();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _downloadAndPrepare(CacheStrategy strategy) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await (_cacheLoader?.call(
            filePath: filePath,
            fileName: fileName,
            strategy: strategy,
            downloadFn: () async {
              final bytes = await _service.downloadFileBytes(filePath);
              return Uint8List.fromList(bytes);
            },
          ) ??
          _cacheManager!.loadFile(
            filePath: filePath,
            fileName: fileName,
            strategy: strategy,
            downloadFn: () async {
              final bytes = await _service.downloadFileBytes(filePath);
              return Uint8List.fromList(bytes);
            },
          ));

      if (result == null) {
        throw Exception('加载文件失败');
      }

      _cacheSource = result.source;
      _localFilePath = await (_tempSaver?.call(result.data, fileName) ??
          _cacheManager!.saveToTempFile(result.data, fileName));
      if (_localFilePath == null) {
        throw Exception('保存临时文件失败');
      }

      if (_fileType == PreviewFileType.video ||
          _fileType == PreviewFileType.audio) {
        _awaitingMediaInitialization = true;
        notifyListeners();
        return;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!_awaitingMediaInitialization) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  PreviewFileType _resolveFileType(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (_imageExtensions.contains(ext)) return PreviewFileType.image;
    if (_videoExtensions.contains(ext)) return PreviewFileType.video;
    if (_audioExtensions.contains(ext)) return PreviewFileType.audio;
    if (_markdownExtensions.contains(ext)) return PreviewFileType.markdown;
    if (_pdfExtensions.contains(ext)) return PreviewFileType.pdf;
    if (_textExtensions.contains(ext) || _isTextFileName(name)) {
      return PreviewFileType.text;
    }
    return PreviewFileType.unknown;
  }

  bool _isTextFileName(String name) {
    final value = name.toLowerCase();
    const textNames = <String>[
      'dockerfile',
      'makefile',
      '.gitignore',
      '.env',
      'license',
      'readme',
    ];
    return textNames.any((item) => value == item || value.startsWith(item));
  }
}
