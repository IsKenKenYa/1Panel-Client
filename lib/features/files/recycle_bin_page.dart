import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecycleBinView();
  }
}

class RecycleBinView extends StatefulWidget {
  const RecycleBinView({super.key});

  @override
  State<RecycleBinView> createState() => _RecycleBinViewState();
}

class _RecycleBinViewState extends State<RecycleBinView> {
  List<RecycleBinItem> _files = [];
  List<RecycleBinItem> _filteredFiles = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  FilesService? _service;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _service = FilesService();
    await _service!.getCurrentServer();
    if (mounted) {
      _loadFiles();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    appLogger.dWithPackage('recycle_bin', '_loadFiles: 开始加载回收站文件');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_service == null) {
        _service = FilesService();
        await _service!.getCurrentServer();
      }
      final files = await _service!.searchRecycleBin(path: '/');
      appLogger.iWithPackage('recycle_bin', '_loadFiles: 成功加载 ${files.length} 个文件');
      if (mounted) {
        setState(() {
          _files = files.map((f) {
            return RecycleBinItem(
              sourcePath: f.path,
              name: f.name,
              isDir: f.isDir,
              size: f.size,
              deleteTime: f.modifiedAt,
              rName: f.rName ?? f.gid ?? f.path.split('/').last,
              from: f.from ?? '/',
            );
          }).toList();
          _filteredFiles = _files;
          _isLoading = false;
          _selectedIds.clear();
        });
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('recycle_bin', '_loadFiles: 加载失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterFiles(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFiles = _files;
      } else {
        _filteredFiles = _files.where((file) {
          return file.name.toLowerCase().contains(query.toLowerCase()) ||
              file.sourcePath.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleSelection(String rName) {
    setState(() {
      if (_selectedIds.contains(rName)) {
        _selectedIds.remove(rName);
      } else {
        _selectedIds.add(rName);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds = _filteredFiles.map((f) => f.rName).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  List<RecycleBinItem> get _selectedFiles {
    return _files.where((f) => _selectedIds.contains(f.rName)).toList();
  }

  Future<void> _restoreSelected() async {
    if (_selectedFiles.isEmpty) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinRestore),
        content: Text(l10n.recycleBinRestoreConfirm(_selectedFiles.length)),
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

    if (confirmed == true && mounted) {
      try {
        final requests = _selectedFiles.map((f) => RecycleBinReduceRequest(
          rName: f.rName,
          from: f.from,
          name: f.name,
        )).toList();
        await _service!.restoreFiles(requests);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recycleBinRestoreSuccess)),
          );
          await _loadFiles();
        }
      } catch (e, stackTrace) {
        if (mounted) {
          DebugErrorDialog.show(context, l10n.recycleBinRestoreFailed, e, stackTrace: stackTrace);
        }
      }
    }
  }

  Future<void> _deletePermanentlySelected() async {
    if (_selectedFiles.isEmpty) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinDeletePermanently),
        content: Text(l10n.recycleBinDeletePermanentlyConfirm(_selectedFiles.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service!.deleteRecycleBinFiles(_selectedFiles);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recycleBinDeletePermanentlySuccess)),
          );
          await _loadFiles();
        }
      } catch (e, stackTrace) {
        if (mounted) {
          DebugErrorDialog.show(context, l10n.recycleBinDeletePermanentlyFailed, e, stackTrace: stackTrace);
        }
      }
    }
  }

  Future<void> _clearRecycleBin() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinClear),
        content: Text(l10n.recycleBinClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service!.clearRecycleBin();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recycleBinClearSuccess)),
          );
          await _loadFiles();
        }
      } catch (e, stackTrace) {
        if (mounted) {
          DebugErrorDialog.show(context, l10n.recycleBinClearFailed, e, stackTrace: stackTrace);
        }
      }
    }
  }

  Future<void> _restoreSingle(RecycleBinItem file) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinRestore),
        content: Text(l10n.recycleBinRestoreSingleConfirm(file.name)),
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

    if (confirmed == true && mounted) {
      try {
        await _service!.restoreFile(RecycleBinReduceRequest(
          rName: file.rName,
          from: file.from,
          name: file.name,
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recycleBinRestoreSuccess)),
          );
          await _loadFiles();
        }
      } catch (e, stackTrace) {
        if (mounted) {
          DebugErrorDialog.show(context, l10n.recycleBinRestoreFailed, e, stackTrace: stackTrace);
        }
      }
    }
  }

  Future<void> _deletePermanentlySingle(RecycleBinItem file) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinDeletePermanently),
        content: Text(l10n.recycleBinDeletePermanentlySingleConfirm(file.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service!.deleteRecycleBinFiles([file]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recycleBinDeletePermanentlySuccess)),
          );
          await _loadFiles();
        }
      } catch (e, stackTrace) {
        if (mounted) {
          DebugErrorDialog.show(context, l10n.recycleBinDeletePermanentlyFailed, e, stackTrace: stackTrace);
        }
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String? _formatDateTime(DateTime? time) {
    if (time == null) return null;
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.filesRecycleBin),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _files.isEmpty ? null : _clearRecycleBin,
            tooltip: l10n.recycleBinClear,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadFiles,
            tooltip: l10n.systemSettingsRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppDesignTokens.pagePadding,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.recycleBinSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterFiles('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterFiles,
            ),
          ),
          Expanded(
            child: _buildBody(context, l10n, theme, colorScheme),
          ),
        ],
      ),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? _buildSelectionBar(context, l10n, theme)
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadFiles,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_filteredFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? l10n.recycleBinEmpty
                  : l10n.recycleBinNoResults,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: ListView.builder(
        padding: AppDesignTokens.pagePadding,
        itemCount: _filteredFiles.length,
        itemBuilder: (context, index) {
          final file = _filteredFiles[index];
          return _buildFileItem(context, file, theme, colorScheme, l10n);
        },
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    RecycleBinItem file,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final isSelected = _selectedIds.contains(file.rName);
    final metadata = <String>[
      file.isDir ? l10n.filesTypeDirectory : _formatFileSize(file.size),
    ];
    final deleteTime = _formatDateTime(file.deleteTime);
    if (deleteTime != null) {
      metadata.add(deleteTime);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDesignTokens.spacingXs),
      color: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          file.isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
          color: file.isDir ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 32,
        ),
        title: Text(file.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metadata.join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${l10n.recycleBinSourcePath}: ${file.sourcePath}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreSingle(file);
                break;
              case 'delete':
                _deletePermanentlySingle(file);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  const Icon(Icons.restore_outlined),
                  const SizedBox(width: 8),
                  Text(l10n.recycleBinRestore),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever_outlined, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    l10n.recycleBinDeletePermanently,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
        onLongPress: () => _toggleSelection(file.rName),
        onTap: () {
          if (_selectedIds.isNotEmpty) {
            _toggleSelection(file.rName);
          }
        },
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('${_selectedIds.length} ${l10n.filesSelected}'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.restore_outlined),
            onPressed: _restoreSelected,
            tooltip: l10n.recycleBinRestore,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: _deletePermanentlySelected,
            tooltip: l10n.recycleBinDeletePermanently,
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAll,
            tooltip: l10n.filesActionSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: _clearSelection,
            tooltip: l10n.filesActionDeselect,
          ),
        ],
      ),
    );
  }
}
