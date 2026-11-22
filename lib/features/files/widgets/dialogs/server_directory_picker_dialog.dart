import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

/// 浏览服务器文件系统并选择目录。
///
/// 编排创建时的手工输入路径容易出错，这里直接列出目录供点选。
class ServerDirectoryPickerDialog extends StatefulWidget {
  const ServerDirectoryPickerDialog({
    super.key,
    required this.filesService,
    this.initialPath = '/',
  });

  final FilesService filesService;
  final String initialPath;

  /// 返回选中的目录路径；用户取消时返回 null。
  static Future<String?> show(
    BuildContext context, {
    required FilesService filesService,
    String initialPath = '/',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ServerDirectoryPickerDialog(
        filesService: filesService,
        initialPath: initialPath,
      ),
    );
  }

  @override
  State<ServerDirectoryPickerDialog> createState() =>
      _ServerDirectoryPickerDialogState();
}

class _ServerDirectoryPickerDialogState
    extends State<ServerDirectoryPickerDialog> {
  late String _currentPath;
  List<FileInfo> _entries = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _load(_currentPath);
  }

  Future<void> _load(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final files = await widget.filesService.getFiles(path: path);
      if (!mounted) return;
      setState(() {
        _currentPath = path;
        _entries = files.where((file) => file.isDir).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.commonSelectDirectory),
      content: SizedBox(
        width: AdaptiveLayoutSpec.of(context).dialogConstraints.maxWidth,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentPath,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_currentPath),
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return ModuleErrorStateWidget(
        message: error,
        onRetry: () => _load(_currentPath),
      );
    }
    return ListView(
      children: [
        if (_currentPath != '/')
          ListTile(
            leading: const Icon(Icons.arrow_upward),
            title: Text(l10n.commonParentDirectory),
            onTap: () => _load(_parentOf(_currentPath)),
          ),
        for (final entry in _entries)
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _load(entry.path),
          ),
        if (_entries.isEmpty && _currentPath == '/')
          ListTile(
            title: Text(l10n.commonNoSubdirectory),
          ),
      ],
    );
  }

  String _parentOf(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/';
    segments.removeLast();
    return segments.isEmpty ? '/' : '/${segments.join('/')}';
  }
}
