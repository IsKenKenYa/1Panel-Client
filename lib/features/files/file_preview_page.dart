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
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/features/files/file_editor_page.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/providers/file_preview_provider.dart';
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
  late final FilePreviewProvider _provider;
  final ScrollController _textScrollController = ScrollController();
  bool _isPreparingMedia = false;
  bool _scrollListenerAttached = false;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _provider = FilePreviewProvider(
      filePath: widget.filePath,
      fileName: widget.fileName,
      fileSize: widget.fileSize,
      initialLine: widget.initialLine,
    )..addListener(_handlePreviewChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapPreview();
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_handlePreviewChanged);
    _textScrollController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    _provider.dispose();
    super.dispose();
  }

  String? get _content => _provider.content;
  bool get _isLoading => _provider.isLoading;
  String? get _error => _provider.error;
  FileType get _fileType => _provider.fileType;
  String? get _localFilePath => _provider.localFilePath;
  CacheSource? get _cacheSource => _provider.cacheSource;
  List<String> get _pagedLines => _provider.pagedLines;
  bool get _usePagedTextPreview => _provider.usePagedTextPreview;
  bool get _isLoadingMore => _provider.isLoadingMore;
  bool get _hasMoreLines => _provider.hasMoreLines;
  int get _baseLine => _provider.baseLine;
  int? get _highlightLine => _provider.highlightLine;

  Future<void> _bootstrapPreview() async {
    if (!mounted) return;
    final settingsController = context.read<AppSettingsController>();
    await _provider.initialize(
      cacheStrategy: settingsController.cacheStrategy,
      cacheMaxSizeMB: settingsController.cacheMaxSizeMB,
    );
    if (_provider.usePagedTextPreview && !_scrollListenerAttached) {
      _textScrollController.addListener(_onTextScroll);
      _scrollListenerAttached = true;
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

  void _handlePreviewChanged() {
    if (!_provider.awaitingMediaInitialization || _isPreparingMedia) {
      return;
    }
    _prepareMediaControllers();
  }

  Future<void> _prepareMediaControllers() async {
    _isPreparingMedia = true;
    try {
      if (_provider.requiresVideoPlayer) {
        await _initVideoPlayer();
      } else if (_provider.requiresAudioPlayer) {
        await _initAudioPlayer();
      }
      _provider.completeMediaInitialization();
    } catch (e) {
      _provider.failMediaInitialization(e);
    } finally {
      _isPreparingMedia = false;
    }
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
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_preview', '_initVideoPlayer: 初始化失败',
          error: e, stackTrace: stackTrace);
      rethrow;
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
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_preview', '_initAudioPlayer: 初始化失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _loadContent() async {
    await _provider.loadContent();
  }

  Future<void> _loadPreviewWindow({required int initialLine}) async {
    await _provider.loadPreviewWindow(initialLine: initialLine);
  }

  Future<void> _loadMorePreviewLines() async {
    await _provider.loadMorePreviewLines();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ChangeNotifierProvider<FilePreviewProvider>.value(
      value: _provider,
      child: Scaffold(
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
                  ),
                );
              },
              tooltip: l10n.filesPropertiesTitle,
            ),
          ],
        ),
        body: _buildBody(context, l10n, theme),
      ),
    );
  }

  Future<void> _showGoToLineDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller =
        TextEditingController(text: '${_highlightLine ?? _baseLine}');
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
            Text(_error!,
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
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
        return _usePagedTextPreview
            ? _buildTextPreview(context, theme)
            : _buildMarkdownPreview(context, theme);
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
                Icon(Icons.broken_image,
                    size: 48, color: theme.colorScheme.error),
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
            Icon(Icons.video_library_outlined,
                size: 48, color: theme.colorScheme.error),
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

  Widget _buildAudioPreview(
      BuildContext context, ThemeData theme, dynamic l10n) {
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
              max: _audioDuration.inSeconds > 0
                  ? _audioDuration.inSeconds.toDouble()
                  : 1,
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
                    final newPosition =
                        _audioPosition - const Duration(seconds: 10);
                    await _audioPlayer?.seek(
                        newPosition.isNegative ? Duration.zero : newPosition);
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
                  child: Icon(_isAudioPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 32,
                  onPressed: () async {
                    final newPosition =
                        _audioPosition + const Duration(seconds: 10);
                    await _audioPlayer?.seek(newPosition > _audioDuration
                        ? _audioDuration
                        : newPosition);
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
          border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 4)),
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
        appLogger.eWithPackage(
            'file_preview', 'PDF load failed: ${details.error}');
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
          final highlighted =
              _highlightLine != null && lineNo == _highlightLine;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: highlighted
                ? BoxDecoration(
                    color: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.35),
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

    if (name == 'dockerfile' || name.startsWith('dockerfile.')) {
      return 'dockerfile';
    }
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

  Widget _buildUnsupportedPreview(
      BuildContext context, dynamic l10n, ThemeData theme) {
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

typedef FileType = PreviewFileType;
