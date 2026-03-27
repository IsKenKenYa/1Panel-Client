import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/providers/recycle_bin_provider.dart';
import 'package:provider/provider.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecycleBinProvider()..initialize(),
      child: const _RecycleBinView(),
    );
  }
}

class _RecycleBinView extends StatefulWidget {
  const _RecycleBinView();

  @override
  State<_RecycleBinView> createState() => _RecycleBinViewState();
}

class _RecycleBinViewState extends State<_RecycleBinView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<RecycleBinProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.filesRecycleBin),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: provider.files.isEmpty
                    ? null
                    : () => _confirmClearRecycleBin(context, provider),
                tooltip: l10n.recycleBinClear,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: provider.loadFiles,
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
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.filterFiles('');
                            },
                          )
                        : null,
                  ),
                  onChanged: provider.filterFiles,
                ),
              ),
              Expanded(
                child: _buildBody(
                  context,
                  provider,
                  l10n,
                  theme,
                  colorScheme,
                ),
              ),
            ],
          ),
          bottomNavigationBar: provider.selectedIds.isNotEmpty
              ? _buildSelectionBar(context, provider, l10n, theme)
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecycleBinProvider provider,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(provider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: provider.loadFiles,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (provider.filteredFiles.isEmpty) {
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
              provider.searchQuery.isEmpty
                  ? l10n.recycleBinEmpty
                  : l10n.recycleBinNoResults,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadFiles,
      child: ListView.builder(
        padding: AppDesignTokens.pagePadding,
        itemCount: provider.filteredFiles.length,
        itemBuilder: (context, index) {
          final file = provider.filteredFiles[index];
          return _buildFileItem(
            context,
            provider,
            file,
            theme,
            colorScheme,
            l10n,
          );
        },
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    RecycleBinProvider provider,
    RecycleBinItem file,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final isSelected = provider.selectedIds.contains(file.rName);
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
          color:
              file.isDir ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
          onSelected: (value) async {
            switch (value) {
              case 'restore':
                await _confirmRestoreSingle(context, provider, file);
              case 'delete':
                await _confirmDeleteSingle(context, provider, file);
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
            const PopupMenuDivider(),
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
        onLongPress: () => provider.toggleSelection(file.rName),
        onTap: () {
          if (provider.selectedIds.isNotEmpty) {
            provider.toggleSelection(file.rName);
          }
        },
      ),
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    RecycleBinProvider provider,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
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
          Text('${provider.selectedIds.length} ${l10n.filesSelected}'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.restore_outlined),
            onPressed: () => _confirmRestoreSelected(context, provider),
            tooltip: l10n.recycleBinRestore,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: () => _confirmDeleteSelected(context, provider),
            tooltip: l10n.recycleBinDeletePermanently,
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: provider.selectAll,
            tooltip: l10n.filesActionSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: provider.clearSelection,
            tooltip: l10n.filesActionDeselect,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestoreSelected(
    BuildContext context,
    RecycleBinProvider provider,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinRestore),
        content:
            Text(l10n.recycleBinRestoreConfirm(provider.selectedFiles.length)),
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

    if (confirmed == true && context.mounted) {
      try {
        await provider.restoreSelected();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recycleBinRestoreSuccess)),
        );
      } catch (e, stackTrace) {
        if (!context.mounted) return;
        DebugErrorDialog.show(
          context,
          l10n.recycleBinRestoreFailed,
          e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    RecycleBinProvider provider,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinDeletePermanently),
        content: Text(
          l10n.recycleBinDeletePermanentlyConfirm(
              provider.selectedFiles.length),
        ),
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

    if (confirmed == true && context.mounted) {
      try {
        await provider.deletePermanentlySelected();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recycleBinDeletePermanentlySuccess)),
        );
      } catch (e, stackTrace) {
        if (!context.mounted) return;
        DebugErrorDialog.show(
          context,
          l10n.recycleBinDeletePermanentlyFailed,
          e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _confirmRestoreSingle(
    BuildContext context,
    RecycleBinProvider provider,
    RecycleBinItem file,
  ) async {
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

    if (confirmed == true && context.mounted) {
      try {
        await provider.restoreSingle(file);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recycleBinRestoreSuccess)),
        );
      } catch (e, stackTrace) {
        if (!context.mounted) return;
        DebugErrorDialog.show(
          context,
          l10n.recycleBinRestoreFailed,
          e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _confirmDeleteSingle(
    BuildContext context,
    RecycleBinProvider provider,
    RecycleBinItem file,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recycleBinDeletePermanently),
        content: Text(
          l10n.recycleBinDeletePermanentlySingleConfirm(file.name),
        ),
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

    if (confirmed == true && context.mounted) {
      try {
        await provider.deletePermanentlySingle(file);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recycleBinDeletePermanentlySuccess)),
        );
      } catch (e, stackTrace) {
        if (!context.mounted) return;
        DebugErrorDialog.show(
          context,
          l10n.recycleBinDeletePermanentlyFailed,
          e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _confirmClearRecycleBin(
    BuildContext context,
    RecycleBinProvider provider,
  ) async {
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

    if (confirmed == true && context.mounted) {
      try {
        await provider.clearRecycleBin();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recycleBinClearSuccess)),
        );
      } catch (e, stackTrace) {
        if (!context.mounted) return;
        DebugErrorDialog.show(
          context,
          l10n.recycleBinClearFailed,
          e,
          stackTrace: stackTrace,
        );
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
}
