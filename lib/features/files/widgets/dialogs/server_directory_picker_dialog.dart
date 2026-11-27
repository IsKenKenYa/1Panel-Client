import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

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
    return showAdaptiveFormPanel<String>(
      context,
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
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPath = path;
        _entries = files.where((file) => file.isDir).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.commonSelectDirectory,
      onConfirm: () async => Navigator.of(context).pop(_currentPath),
      content: SizedBox(
        width: AdaptiveLayoutSpec.of(context).dialogConstraints.maxWidth,
        height: math.min(420.0, MediaQuery.sizeOf(context).height * 0.6),
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
    final hasParent = _currentPath != '/';
    return ListView.builder(
      itemCount: _entries.length + (hasParent || _entries.isEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasParent && index == 0) {
          return ListTile(
            leading: const Icon(Icons.arrow_upward),
            title: Text(l10n.commonParentDirectory),
            minTileHeight: kMinInteractiveDimension,
            visualDensity: VisualDensity.standard,
            onTap: () => _load(_parentOf(_currentPath)),
          );
        }
        if (_entries.isEmpty) {
          return ListTile(title: Text(l10n.commonNoSubdirectory));
        }
        final entry = _entries[index - (hasParent ? 1 : 0)];
        return ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          minTileHeight: kMinInteractiveDimension,
          visualDensity: VisualDensity.standard,
          onTap: () => _load(entry.path),
        );
      },
    );
  }

  String _parentOf(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      return '/';
    }
    segments.removeLast();
    return segments.isEmpty ? '/' : '/${segments.join('/')}';
  }
}
