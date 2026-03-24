import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/features/files/file_editor_page.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/file_properties_dialog.dart';

class FilePreviewPage extends StatefulWidget {
  final String filePath;
  final String fileName;
  final int? fileSize;
  final int? initialLine;

  const FilePreviewPage({
    super.key,
    required this.filePath,
    required this.fileName,
    this.fileSize,
    this.initialLine,
  });

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  String? _content;
  bool _isLoading = true;
  String? _error;
  late FileType _fileType;
  FilesService? _service;
  String? _localFilePath;
  CacheSource? _cacheSource;
  
  final FilePreviewCacheManager _cacheManager = FilePreviewCacheManager();

  final ScrollController _textScrollController = ScrollController();
  final List<String> _pagedLines = [];
  bool _usePagedTextPreview = false;
  bool _isLoadingMore = false;
  bool _hasMoreLines = true;
  int _baseLine = 1;
  int? _highlightLine;

  static const int _largeTextThresholdBytes = 1024 * 1024;
  static const int _previewPageSize = 200;
  static const int _previewContextLines = 40;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  static const Set<String> _imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'ico'
  };

  static const Set<String> _videoExtensions = {
    'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp', 'flv', 'wmv'
  };

  static const Set<String> _audioExtensions = {
    'mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', 'wma'
  };

  static const Set<String> _textExtensions = {
    'txt', 'json', 'xml', 'yaml', 'yml', 'html', 'css', 'js', 'ts',
    'dart', 'py', 'java', 'c', 'cpp', 'h', 'hpp', 'sh', 'bash', 'sql',
    'log', 'conf', 'ini', 'env', 'gitignore', 'dockerfile', 'makefile',
    'toml', 'gradle', 'properties', 'vue', 'jsx', 'tsx', 'scss', 'sass',
    'less', 'go', 'rs', 'swift', 'kt', 'scala', 'rb', 'php', 'pl', 'lua',
    'bat', 'ps1', 'psm1', 'psd1', 'vbs', 'cmd', 'awk', 'sed', 'fish',
    'zsh', 'csh', 'tcsh', 'ksh', 'r', 'm', 'mm', 'clj', 'cljs',
    'hs', 'erl', 'ex', 'exs', 'lisp', 'lsp', 'scm', 'rkt', 'nim', 'cr',
    'd', 'f90', 'f95', 'f03', 'for', 'pas', 'pp', 'jl', 'ml', 'mli',
    'elm', 'idr', 'agda', 'coq', 'v', 'sv', 'vhdl', 'verilog', 'tcl',
    'proto', 'graphql', 'gql', 'rego', 'hcl', 'tf', 'tfvars', 'nomad',
    'sls', 'cfg', 'config',
  };

  static const Set<String> _markdownExtensions = {'md', 'markdown'};

  static const Set<String> _pdfExtensions = {'pdf'};

  @override
  void initState() {
    super.initState();
    _fileType = _getFileType(widget.fileName);
    _initService();
  }

  @override
  void dispose() {
    _textScrollController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initService() async {
    _service = FilesService();
    
    if (_fileType == FileType.image || 
        _fileType == FileType.video || 
        _fileType == FileType.pdf || 
        _fileType == FileType.audio) {
      await _downloadAndPreview();
    } else if (_fileType == FileType.text || _fileType == FileType.markdown) {
      final forcePaged = widget.initialLine != null;
      _usePagedTextPreview = forcePaged ||
          (_fileType == FileType.text &&
          (widget.fileSize != null && widget.fileSize! >= _largeTextThresholdBytes));

      if (_usePagedTextPreview) {
        _textScrollController.addListener(_onTextScroll);
        final initialLine = widget.initialLine ?? 1;
        await _loadPreviewWindow(initialLine: initialLine);
      } else {
        await _loadContent();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTextScroll() {
    if (!_usePagedTextPreview || _isLoadingMore || !_hasMoreLines) return;
    final position = _textScrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMorePreviewLines();
    }
  }

  Future<void> _downloadAndPreview() async {
    try {
      appLogger.dWithPackage('file_preview', '_downloadAndPreview: 加载文件 ${widget.filePath}');
      
      _service ??= FilesService();
      
      final settingsController = context.read<AppSettingsController>();
      final cacheStrategy = settingsController.cacheStrategy;
      
      final result = await _cacheManager.loadFile(
        filePath: widget.filePath,
        fileName: widget.fileName,
        strategy: cacheStrategy,
        downloadFn: () async {
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}_${widget.fileName}';
          await _service!.downloadFile(widget.filePath, tempPath);
          final file = File(tempPath);
          final data = await file.readAsBytes();
          await file.delete();
          return data;
        },
      );
      
      if (result == null) {
        throw Exception('加载文件失败');
      }
      
      _cacheSource = result.source;
      
      final tempPath = await _cacheManager.saveToTempFile(result.data, widget.fileName);
      if (tempPath == null) {
        throw Exception('保存临时文件失败');
      }
      _localFilePath = tempPath;
      
      final sourceName = switch (result.source) {
        CacheSource.memory => '内存缓存',
        CacheSource.disk => '硬盘缓存',
        CacheSource.network => '网络下载',
      };
      appLogger.iWithPackage('file_preview', '_downloadAndPreview: 文件已加载 (来源: $sourceName)');
      
      if (_fileType == FileType.video) {
        await _initVideoPlayer();
      } else if (_fileType == FileType.audio) {
        await _initAudioPlayer();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_preview', '_downloadAndPreview: 加载失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  FileType _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (_imageExtensions.contains(ext)) {
      return FileType.image;
    }
    if (_videoExtensions.contains(ext)) {
      return FileType.video;
    }
    if (_audioExtensions.contains(ext)) {
      return FileType.audio;
    }
    if (_markdownExtensions.contains(ext)) {
      return FileType.markdown;
    }
    if (_pdfExtensions.contains(ext)) {
      return FileType.pdf;
    }
    if (_textExtensions.contains(ext) || _isTextFileName(fileName)) {
      return FileType.text;
    }
    return FileType.unknown;
  }

  bool _isTextFileName(String fileName) {
    final name = fileName.toLowerCase();
    const textNames = ['dockerfile', 'makefile', '.gitignore', '.env', 'license', 'readme'];
    for (final textName in textNames) {
      if (name == textName || name.startsWith(textName)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _initVideoPlayer() async {
    try {
      if (_localFilePath == null) {
        throw Exception('Local file path is null');
      }
      
      _videoController = VideoPlayerController.file(File(_localFilePath!));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(errorMessage, textAlign: TextAlign.center),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_preview', '_initVideoPlayer: 初始化失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      if (_localFilePath == null) {
        throw Exception('Local file path is null');
      }
      
      _audioPlayer = AudioPlayer();
      
      await _audioPlayer!.setSource(DeviceFileSource(_localFilePath!));
      _audioDuration = (await _audioPlayer!.getDuration()) ?? Duration.zero;

      _audioPlayer!.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _audioPosition = position;
          });
        }
      });

      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isAudioPlaying = state == PlayerState.playing;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_preview', '_initAudioPlayer: 初始化失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadContent() async {
    appLogger.dWithPackage('file_preview', '_loadContent: path=${widget.filePath}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_service == null) {
        _service = FilesService();
        await _service!.getCurrentServer();
      }
      final content = await _service!.getFileContent(widget.filePath);
      appLogger.iWithPackage('file_preview', '_loadContent: 成功加载, 长度=${content.length}');
      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_preview', '_loadContent: 加载失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPreviewWindow({required int initialLine}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_service == null) {
        _service = FilesService();
        await _service!.getCurrentServer();
      }

      final startLine = (initialLine - _previewContextLines).clamp(1, 1 << 30);
      final text = await _service!.previewFile(
        widget.filePath,
        line: startLine,
        limit: _previewPageSize,
      );
      final lines = text.split('\n');

      if (!mounted) return;
      setState(() {
        _pagedLines
          ..clear()
          ..addAll(lines);
        _baseLine = startLine;
        _highlightLine = initialLine;
        _hasMoreLines = lines.length >= _previewPageSize;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_preview', '_loadPreviewWindow: 加载失败', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePreviewLines() async {
    if (_isLoadingMore || !_hasMoreLines) return;
    setState(() => _isLoadingMore = true);

    try {
      if (_service == null) {
        _service = FilesService();
        await _service!.getCurrentServer();
      }

      final nextLine = _baseLine + _pagedLines.length;
      final text = await _service!.previewFile(
        widget.filePath,
        line: nextLine,
        limit: _previewPageSize,
      );
      final lines = text.isEmpty ? <String>[] : text.split('\n');

      if (!mounted) return;
      setState(() {
        _pagedLines.addAll(lines);
        _hasMoreLines = lines.length >= _previewPageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              overflow: TextOverflow.ellipsis,
            ),
            if (_cacheSource != null)
              Text(
                _getCacheSourceText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (_usePagedTextPreview)
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: l10n.filesGoToLine,
              onPressed: () => _showGoToLineDialog(context),
            ),
          if (_fileType == FileType.text || _fileType == FileType.markdown)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditor(context),
              tooltip: l10n.filesEditFile,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              final provider = context.read<FilesProvider>();
              showFilePropertiesDialog(
                context, 
                provider, 
                FileInfo(
                  name: widget.fileName,
                  path: widget.filePath,
                  type: 'file',
                  size: widget.fileSize ?? 0,
                )
              );
            },
            tooltip: l10n.filesPropertiesTitle,
          ),
        ],
      ),
      body: _buildBody(context, l10n, theme),
    );
  }

  Future<void> _showGoToLineDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: '${_highlightLine ?? _baseLine}');
    final line = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.filesGoToLine),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.filesLineNumber,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                Navigator.pop(context, value);
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );

    if (line == null || line <= 0) return;
    await _loadPreviewWindow(initialLine: line);
    if (_textScrollController.hasClients) {
      _textScrollController.jumpTo(0);
    }
  }
  
  String _getCacheSourceText() {
    return switch (_cacheSource!) {
      CacheSource.memory => '从内存缓存加载',
      CacheSource.disk => '从硬盘缓存加载',
      CacheSource.network => '从网络下载',
    };
  }

  Widget _buildBody(BuildContext context, dynamic l10n, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.filesPreviewError, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadContent,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    switch (_fileType) {
      case FileType.image:
        return _buildImagePreview(context, theme);
      case FileType.video:
        return _buildVideoPreview(context, theme);
      case FileType.audio:
        return _buildAudioPreview(context, theme, l10n);
      case FileType.markdown:
        return _usePagedTextPreview ? _buildTextPreview(context, theme) : _buildMarkdownPreview(context, theme);
      case FileType.pdf:
        return _buildPdfPreview(context, theme);
      case FileType.text:
        return _buildTextPreview(context, theme);
      case FileType.unknown:
        return _buildUnsupportedPreview(context, l10n, theme);
    }
  }

  Widget _buildImagePreview(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isSvg = widget.fileName.toLowerCase().endsWith('.svg');

    if (_localFilePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load image'),
          ],
        ),
      );
    }

    if (isSvg) {
      return Center(
        child: SvgPicture.file(
          File(_localFilePath!),
          placeholderBuilder: (context) => const CircularProgressIndicator(),
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(error.toString()),
              ],
            );
          },
        ),
      );
    }

    return PhotoView(
      imageProvider: FileImage(File(_localFilePath!)),
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          value: event?.expectedTotalBytes != null
              ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
              : null,
        ),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(error.toString()),
          ],
        ),
      ),
      backgroundDecoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.grey[200],
      ),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
    );
  }

  Widget _buildVideoPreview(BuildContext context, ThemeData theme) {
    if (_chewieController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Video player not initialized'),
          ],
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildAudioPreview(BuildContext context, ThemeData theme, dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.music_note,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.fileName,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Slider(
              value: _audioPosition.inSeconds.toDouble(),
              max: _audioDuration.inSeconds > 0 ? _audioDuration.inSeconds.toDouble() : 1,
              onChanged: (value) async {
                await _audioPlayer?.seek(Duration(seconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_audioPosition)),
                  Text(_formatDuration(_audioDuration)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 32,
                  onPressed: () async {
                    final newPosition = _audioPosition - const Duration(seconds: 10);
                    await _audioPlayer?.seek(newPosition.isNegative ? Duration.zero : newPosition);
                  },
                ),
                const SizedBox(width: 16),
                FloatingActionButton.large(
                  onPressed: () async {
                    if (_isAudioPlaying) {
                      await _audioPlayer?.pause();
                    } else {
                      await _audioPlayer?.resume();
                    }
                  },
                  child: Icon(_isAudioPlaying ? Icons.pause : Icons.play_arrow, size: 48),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 32,
                  onPressed: () async {
                    final newPosition = _audioPosition + const Duration(seconds: 10);
                    await _audioPlayer?.seek(newPosition > _audioDuration ? _audioDuration : newPosition);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMarkdownPreview(BuildContext context, ThemeData theme) {
    if (_content == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = theme.brightness == Brightness.dark;

    return Markdown(
      data: _content!,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: theme.textTheme.headlineLarge,
        h2: theme.textTheme.headlineMedium,
        h3: theme.textTheme.headlineSmall,
        p: theme.textTheme.bodyMedium,
        code: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          // 可以添加打开链接的逻辑
        }
      },
    );
  }

  Widget _buildPdfPreview(BuildContext context, ThemeData theme) {
    if (_localFilePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load PDF'),
          ],
        ),
      );
    }

    return SfPdfViewer.file(
      File(_localFilePath!),
      onDocumentLoaded: (details) {
        appLogger.iWithPackage('file_preview', 'PDF loaded successfully');
      },
      onDocumentLoadFailed: (details) {
        appLogger.eWithPackage('file_preview', 'PDF load failed: ${details.error}');
      },
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: true,
    );
  }

  Widget _buildTextPreview(BuildContext context, ThemeData theme) {
    if (_usePagedTextPreview) {
      return ListView.builder(
        controller: _textScrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _pagedLines.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingMore && index == _pagedLines.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final lineNo = _baseLine + index;
          final lineText = _pagedLines[index];
          final highlighted = _highlightLine != null && lineNo == _highlightLine;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: highlighted
                ? BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    '$lineNo',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    lineText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (_content == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final language = _getLanguage(widget.fileName);

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: language != null
            ? HighlightView(
                _content!,
                language: language,
                theme: githubTheme,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              )
            : SelectableText(
                _content!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  String? _getLanguage(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    final name = fileName.toLowerCase();

    if (name == 'dockerfile' || name.startsWith('dockerfile.')) return 'dockerfile';
    if (name == 'makefile') return 'makefile';
    if (name == '.gitignore') return 'gitignore';
    if (name.startsWith('.env')) return 'bash';

    const extToLanguage = {
      'dart': 'dart',
      'js': 'javascript',
      'ts': 'typescript',
      'jsx': 'javascript',
      'tsx': 'typescript',
      'json': 'json',
      'yaml': 'yaml',
      'yml': 'yaml',
      'xml': 'xml',
      'html': 'html',
      'htm': 'html',
      'css': 'css',
      'scss': 'scss',
      'sass': 'sass',
      'less': 'less',
      'py': 'python',
      'java': 'java',
      'c': 'c',
      'cpp': 'cpp',
      'h': 'c',
      'hpp': 'cpp',
      'sh': 'bash',
      'bash': 'bash',
      'sql': 'sql',
      'go': 'go',
      'rs': 'rust',
      'swift': 'swift',
      'kt': 'kotlin',
      'scala': 'scala',
      'rb': 'ruby',
      'php': 'php',
      'pl': 'perl',
      'lua': 'lua',
      'vue': 'vue',
      'toml': 'toml',
      'gradle': 'gradle',
      'properties': 'properties',
      'conf': 'nginx',
      'ini': 'ini',
    };

    return extToLanguage[ext];
  }

  Widget _buildUnsupportedPreview(BuildContext context, dynamic l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.filesPreviewUnsupported,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.fileName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FileEditorPage(
          filePath: widget.filePath,
          fileName: widget.fileName,
          initialContent: _content,
        ),
      ),
    );
  }
}

enum FileType {
  image,
  video,
  audio,
  markdown,
  pdf,
  text,
  unknown,
}
