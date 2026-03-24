import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';

class FileEditorPage extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String? initialContent;

  const FileEditorPage({
    super.key,
    required this.filePath,
    required this.fileName,
    this.initialContent,
  });

  @override
  State<FileEditorPage> createState() => _FileEditorPageState();
}

class _FileEditorPageState extends State<FileEditorPage> {
  late TextEditingController _controller;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _error;
  String _encoding = 'utf-8';
  String _originalContent = '';
  FilesService? _service;

  static const List<String> _availableEncodings = [
    'utf-8',
    'gbk',
    'gb2312',
    'big5',
    'iso-8859-1',
    'ascii',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    _initService();
  }

  Future<void> _initService() async {
    _service = FilesService();
    await _service!.getCurrentServer();
    
    if (widget.initialContent != null) {
      _originalContent = widget.initialContent!;
      _controller.text = _originalContent;
      setState(() {
        _isLoading = false;
      });
    } else {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != _originalContent;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _loadContent() async {
    appLogger.dWithPackage('file_editor', '_loadContent: path=${widget.filePath}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_service == null) {
        _service = FilesService();
        await _service!.getCurrentServer();
      }
      final content = await _service!.readFile(widget.filePath, encoding: _encoding);
      appLogger.iWithPackage('file_editor', '_loadContent: 成功加载, 长度=${content.length}');
      if (mounted) {
        _originalContent = content;
        _controller.text = _originalContent;
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_editor', '_loadContent: 加载失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveContent() async {
    if (_isSaving) return;

    appLogger.dWithPackage('file_editor', '_saveContent: path=${widget.filePath}');
    setState(() {
      _isSaving = true;
    });

    try {
      if (_service == null) {
        _service = FilesService();
        await _service!.getCurrentServer();
      }
      await _service!.saveFile(widget.filePath, _controller.text, encoding: _encoding);
      appLogger.iWithPackage('file_editor', '_saveContent: 保存成功');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasChanges = false;
          _originalContent = _controller.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.commonSaveSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_editor', '_saveContent: 保存失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        DebugErrorDialog.show(context, context.l10n.commonSaveFailed, e, stackTrace: stackTrace);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonSave),
        content: Text(l10n.filesEditorUnsaved),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await _saveContent();
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fileName,
                overflow: TextOverflow.ellipsis,
              ),
              if (_hasChanges)
                Text(
                  l10n.filesEditorUnsaved,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
          actions: [
            _buildEncodingSelector(theme, l10n),
            _buildMoreActions(theme, l10n),
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              onPressed: _hasChanges && !_isSaving ? _saveContent : null,
              tooltip: l10n.filesEditorSave,
            ),
          ],
        ),
        body: _buildBody(context, l10n, theme),
      ),
    );
  }

  Widget _buildEncodingSelector(ThemeData theme, dynamic l10n) {
    return PopupMenuButton<String>(
      tooltip: l10n.filesEditorEncoding,
      icon: const Icon(Icons.text_fields),
      onSelected: (value) {
        _onEncodingSelected(value);
      },
      itemBuilder: (context) => _availableEncodings.map((encoding) {
        return PopupMenuItem<String>(
          value: encoding,
          child: Row(
            children: [
              if (_encoding == encoding)
                Icon(
                  Icons.check,
                  size: 18,
                  color: theme.colorScheme.primary,
                )
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(encoding.toUpperCase()),
            ],
          ),
        );
      }).toList(),
    );
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

    return Column(
      children: [
        _buildStatusBar(theme, l10n),
        Expanded(
          child: Container(
            color: theme.colorScheme.surfaceContainerLowest,
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: l10n.filesEmptyTitle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(ThemeData theme, dynamic l10n) {
    final lineCount = '\n'.allMatches(_controller.text).length + 1;
    final charCount = _controller.text.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.text_snippet_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$lineCount ${l10n.filesEditorLineNumbers.toLowerCase()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$charCount chars',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _encoding.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onEncodingSelected(String value) async {
    if (value == _encoding) return;
    if (_hasChanges) {
      final l10n = context.l10n;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.filesEditorEncoding),
          content: Text(l10n.filesEditorReloadConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() {
      _encoding = value;
      _hasChanges = false;
    });
    await _loadContent();
  }

  Widget _buildMoreActions(ThemeData theme, dynamic l10n) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _loadContent,
      tooltip: l10n.filesReload,
    );
  }
}
