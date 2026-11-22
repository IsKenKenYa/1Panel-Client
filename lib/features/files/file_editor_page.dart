import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/keyboard_utils.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

enum _EditorExitAction { discard, save }

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
  bool _confirmingExit = false;
  String? _error;
  String _encoding = 'utf-8';
  String _originalContent = '';
  final _service = FilesService();

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
    _originalContent = widget.initialContent ?? '';
    _controller = TextEditingController(text: _originalContent);
    _controller.addListener(_onTextChanged);
    _isLoading = widget.initialContent == null;
    if (_isLoading) {
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
    appLogger.dWithPackage(
        'file_editor', '_loadContent: path=${widget.filePath}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content =
          await _service.readFile(widget.filePath, encoding: _encoding);
      appLogger.iWithPackage(
          'file_editor', '_loadContent: 成功加载, 长度=${content.length}');
      if (mounted) {
        _originalContent = content;
        _controller.text = _originalContent;
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_editor', '_loadContent: 加载失败',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _saveContent() async {
    if (_isSaving || !_hasChanges) return false;

    appLogger.dWithPackage(
        'file_editor', '_saveContent: path=${widget.filePath}');
    final savedContent = _controller.text;
    setState(() {
      _isSaving = true;
    });

    try {
      await _service.saveFile(
        widget.filePath,
        savedContent,
        encoding: _encoding,
      );
      appLogger.iWithPackage('file_editor', '_saveContent: 保存成功');
      if (!mounted) return false;
      setState(() {
        _isSaving = false;
        _originalContent = savedContent;
        _hasChanges = _controller.text != savedContent;
      });
      SnackBarUtils.showSuccess(context, context.l10n.commonSaveSuccess);
      return !_hasChanges;
    } catch (e, stackTrace) {
      appLogger.eWithPackage('file_editor', '_saveContent: 保存失败',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        SnackBarUtils.showErrorWithDebugDetails(
          context,
          context.l10n.commonSaveFailed,
          error: e,
          stackTrace: stackTrace,
        );
      }
      return false;
    }
  }

  Future<void> _handlePop(bool didPop, Object? _) async {
    if (didPop || _isSaving || _confirmingExit) return;

    _confirmingExit = true;
    try {
      final l10n = context.l10n;
      final action = await showDialog<_EditorExitAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.filesEditorUnsaved),
          content: Text(widget.fileName),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _EditorExitAction.discard),
              child: Text(l10n.filesEditorDiscardChanges),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _EditorExitAction.save),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      );

      if (!mounted) return;
      final shouldPop = action == _EditorExitAction.discard ||
          (action == _EditorExitAction.save && await _saveContent());
      if (shouldPop && mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } finally {
      _confirmingExit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PopScope<Object?>(
      canPop: !_hasChanges && !_isSaving,
      onPopInvokedWithResult: _handlePop,
      child: _buildShortcutWrapper(
        Scaffold(
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
      ),
    );
  }

  // 桌面端编辑器惯例：Cmd/Ctrl+S 保存；移动端无物理键盘时组合键不会触发。
  Widget _buildShortcutWrapper(Widget child) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        KeyboardUtils.modifierPlus(LogicalKeyboardKey.keyS): _saveShortcut,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }

  void _saveShortcut() {
    if (_hasChanges && !_isSaving) {
      _saveContent();
    }
  }

  Widget _buildEncodingSelector(ThemeData theme, dynamic l10n) {
    return PopupMenuButton<String>(
      enabled: !_isLoading && !_isSaving,
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
      return ModuleErrorStateWidget(
        message: _error,
        onRetry: _loadContent,
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
                contentPadding: AppDesignTokens.cardPadding,
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
      final proceed = await ConfirmActionSheetWidget.show(
        context,
        title: l10n.filesEditorEncoding,
        message: l10n.filesEditorReloadConfirm,
        confirmLabel: l10n.commonConfirm,
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
      icon: const Icon(Icons.refresh_outlined),
      onPressed: _isLoading || _isSaving ? null : _loadContent,
      tooltip: l10n.filesReload,
    );
  }
}
