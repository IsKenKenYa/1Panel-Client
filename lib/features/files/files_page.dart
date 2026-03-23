import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/file_models.dart';
import 'package:onepanelapp_app/features/files/files_provider.dart';
import 'package:onepanelapp_app/features/files/file_preview_page.dart';
import 'package:onepanelapp_app/features/files/file_editor_page.dart';
import 'package:onepanelapp_app/features/files/favorites_page.dart';
import 'package:onepanelapp_app/features/files/recycle_bin_page.dart';
import 'package:onepanelapp_app/features/files/upload_history_page.dart';
import 'package:onepanelapp_app/features/files/mounts_page.dart';
import 'package:onepanelapp_app/features/files/transfer_manager_page.dart';
import 'package:onepanelapp_app/core/utils/debug_error_dialog.dart';
import 'package:onepanelapp_app/core/services/logger/logger_service.dart';
import 'package:onepanelapp_app/core/services/transfer/transfer_manager.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/permission_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/create_directory_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/create_file_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/rename_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/move_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/copy_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/extract_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/compress_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/delete_confirm_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/batch_move_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/batch_copy_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/upload_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/wget_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/search_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/sort_options_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/file_properties_dialog.dart';
import 'package:onepanelapp_app/features/files/widgets/dialogs/create_link_dialog.dart';

export 'models/models.dart' show WgetDownloadState;

class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = FilesProvider();
        provider.loadServer();
        provider.loadFiles();
        return provider;
      },
      child: const FilesView(),
    );
  }
}

class FilesView extends StatefulWidget {
  const FilesView({super.key});

  @override
  State<FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FilesProvider>().loadServer().then((_) {
          if (mounted) {
            context.read<FilesProvider>().loadFiles();
            context.read<FilesProvider>().loadFavorites();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null,
        title: Consumer<FilesProvider>(
          builder: (context, provider, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.filesPageTitle,
                overflow: TextOverflow.ellipsis,
              ),
              if (provider.data.currentServer != null)
                Text(
                  provider.data.currentServer!.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => showSearchDialog(context),
              tooltip: l10n.filesActionSearch,
            ),
          _buildServerSelector(context),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<FilesProvider>().refresh(),
            tooltip: l10n.systemSettingsRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Consumer<FilesProvider>(
        builder: (context, provider, _) {
          if (provider.data.isLoading && provider.data.files.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.data.error != null) {
            return _buildContentScaffold(
              context,
              provider,
              theme,
              l10n,
              child: _buildErrorState(context, provider, theme),
            );
          }

          if (provider.data.files.isEmpty) {
            return _buildContentScaffold(
              context,
              provider,
              theme,
              l10n,
              child: _buildEmptyState(context, l10n, theme),
            );
          }

          return _buildFileList(context, provider, theme, l10n);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.filesActionNew),
      ),
      bottomNavigationBar: Consumer<FilesProvider>(
        builder: (context, provider, _) {
          if (!provider.data.hasSelection) {
            return const SizedBox.shrink();
          }
          return _buildSelectionBar(context, provider, l10n);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FilesProvider provider, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(provider.data.error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => provider.loadFiles(),
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final provider = context.read<FilesProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(l10n.filesEmptyTitle),
          const SizedBox(height: 8),
          Text(l10n.filesEmptyDesc, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => showCreateDirectoryDialog(context, provider),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.filesActionNewFolder),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => showCreateFileDialog(context, provider),
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.filesActionNewFile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, FilesProvider provider, ThemeData theme, AppLocalizations l10n) {
    return _buildContentScaffold(
      context,
      provider,
      theme,
      l10n,
      child: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: ListView.builder(
          padding: AppDesignTokens.pagePadding,
          itemCount: provider.data.files.length,
          itemBuilder: (context, index) {
            final file = provider.data.files[index];
            return _buildFileItem(context, provider, file, theme, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildContentScaffold(
    BuildContext context,
    FilesProvider provider,
    ThemeData theme,
    AppLocalizations l10n, {
    required Widget child,
  }) {
    return _buildResponsiveBody(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPathBreadcrumb(context, provider, theme, l10n),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildResponsiveBody(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;
        final maxWidth = isWide ? 760.0 : double.infinity;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildPathBreadcrumb(BuildContext context, FilesProvider provider, ThemeData theme, AppLocalizations l10n) {
    final segments = provider.data.currentPath.split('/');
    segments.removeWhere((s) => s.isEmpty);

    final colorScheme = theme.colorScheme;
    final buttonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      foregroundColor: colorScheme.onSurface,
    );
    final breadcrumbTextStyle = theme.textTheme.labelLarge;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingSm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => provider.navigateTo('/'),
                    style: buttonStyle,
                    icon: Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    label: Text(l10n.filesRoot, style: breadcrumbTextStyle),
                  ),
                  for (int i = 0; i < segments.length; i++) ...[
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    TextButton(
                      onPressed: () {
                        final path = '/${segments.sublist(0, i + 1).join('/')}';
                        provider.navigateTo(path);
                      },
                      style: buttonStyle,
                      child: Text(segments[i], style: breadcrumbTextStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, FilesProvider provider, FileInfo file, ThemeData theme, AppLocalizations l10n) {
    final isSelected = provider.data.isSelected(file.path);
    final isDir = file.isDir;
    final colorScheme = theme.colorScheme;
    final isFavorite = provider.data.isFavorite(file.path);
    final metadata = <String>[
      isDir ? l10n.filesTypeDirectory : _formatFileSize(file.size),
    ];
    final modifiedLabel = _formatModifiedAt(file.modifiedAt);
    if (modifiedLabel != null) {
      metadata.add(modifiedLabel);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDesignTokens.spacingXs),
      color: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          isDir ? Icons.folder_outlined : _getFileIcon(file.name),
          color: isDir ? colorScheme.primary : _getFileIconColor(file.name, colorScheme),
          size: 32,
        ),
        title: Row(
          children: [
            Expanded(child: Text(file.name)),
            if (isFavorite)
              Icon(
                Icons.star,
                size: 18,
                color: colorScheme.primary,
              ),
          ],
        ),
        subtitle: Text(
          metadata.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFileAction(context, provider, file, value, l10n),
          itemBuilder: (context) => [
            if (isDir)
              PopupMenuItem(value: 'open', child: Text(l10n.filesActionOpen)),
            if (!isDir)
              PopupMenuItem(value: 'download', child: Text(l10n.filesActionDownload)),
            PopupMenuItem(
              value: 'favorite',
              child: Text(isFavorite ? l10n.filesRemoveFromFavorites : l10n.filesAddToFavorites),
            ),
            PopupMenuItem(value: 'rename', child: Text(l10n.filesActionRename)),
            PopupMenuItem(value: 'copy', child: Text(l10n.filesActionCopy)),
            PopupMenuItem(value: 'move', child: Text(l10n.filesActionMove)),
            if (!isDir && _isCompressedFile(file.name))
              PopupMenuItem(value: 'extract', child: Text(l10n.filesActionExtract)),
            PopupMenuItem(value: 'compress', child: Text(l10n.filesActionCompress)),
            PopupMenuItem(value: 'permission', child: Text(l10n.filesPermissionTitle)),
            PopupMenuItem(value: 'link', child: Text(l10n.filesCreateLinkTitle)),
            PopupMenuItem(value: 'properties', child: Text(l10n.filesPropertiesTitle)),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                l10n.filesActionDelete,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ],
        ),
        onLongPress: () => provider.toggleSelection(file.path),
        onTap: () {
          if (provider.data.hasSelection) {
            provider.toggleSelection(file.path);
          } else if (isDir) {
            provider.navigateTo(file.path);
          } else {
            _openFilePreview(context, file);
          }
        },
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context, FilesProvider provider, AppLocalizations l10n) {
    final theme = Theme.of(context);
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
          Text('${provider.data.selectionCount} ${l10n.filesSelected}'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.folder_zip_outlined),
            onPressed: () => showCompressDialog(context, provider, provider.data.selectedFiles.toList(), l10n),
            tooltip: l10n.filesActionCompress,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () => showBatchCopyDialog(context, provider, l10n),
            tooltip: l10n.filesActionCopy,
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            onPressed: () => showBatchMoveDialog(context, provider, l10n),
            tooltip: l10n.filesActionMove,
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () => provider.selectAll(),
            tooltip: l10n.filesActionSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: () => provider.clearSelection(),
            tooltip: l10n.filesActionDeselect,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => showDeleteConfirmDialog(context, provider, l10n),
            tooltip: l10n.filesActionDelete,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file_outlined;
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
      case 'rar':
        return Icons.folder_zip_outlined;
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'swift':
      case 'kt':
        return Icons.code_outlined;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
        return Icons.data_object_outlined;
      case 'md':
      case 'txt':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileIconColor(String fileName, ColorScheme colorScheme) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return colorScheme.error;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return colorScheme.primary;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return colorScheme.tertiary;
      case 'mp3':
      case 'wav':
      case 'flac':
        return colorScheme.secondary;
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
      case 'rar':
        return colorScheme.tertiaryContainer;
      case 'dart':
        return colorScheme.primary;
      case 'js':
      case 'ts':
        return colorScheme.secondary;
      case 'py':
        return colorScheme.tertiary;
      case 'json':
      case 'yaml':
      case 'yml':
        return colorScheme.secondaryContainer;
      default:
        return colorScheme.onSurfaceVariant;
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

  String? _formatModifiedAt(DateTime? time) {
    if (time == null) return null;
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  bool _isCompressedFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['zip', 'tar', 'gz', 'bz2', 'xz', '7z', 'rar'].contains(ext);
  }

  void _handleFileAction(BuildContext context, FilesProvider provider, FileInfo file, String action, AppLocalizations l10n) {
    switch (action) {
      case 'open':
        if (file.isDir) provider.navigateTo(file.path);
        break;
      case 'download':
        _startDownload(context, provider, file, l10n);
        break;
      case 'preview':
        _openFilePreview(context, file);
        break;
      case 'edit':
        _openFileEditor(context, file);
        break;
      case 'favorite':
        _toggleFavorite(context, provider, file, l10n);
        break;
      case 'rename':
        showRenameDialog(context, provider, file, l10n);
        break;
      case 'copy':
        showCopyDialog(context, provider, file, l10n);
        break;
      case 'move':
        showMoveDialog(context, provider, file, l10n);
        break;
      case 'extract':
        showExtractDialog(context, provider, file, l10n);
        break;
      case 'compress':
        showCompressDialog(context, provider, [file.path], l10n);
        break;
      case 'permission':
        showPermissionDialog(context, provider, file, l10n);
        break;
      case 'properties':
        showFilePropertiesDialog(context, provider, file);
        break;
      case 'link':
        showCreateLinkDialog(context, provider, file.path);
        break;
      case 'delete':
        provider.toggleSelection(file.path);
        showDeleteConfirmDialog(context, provider, l10n);
        break;
    }
  }

  void _openFilePreview(BuildContext context, FileInfo file) {
    appLogger.dWithPackage('files_page', '_openFilePreview: 打开预览 ${file.path}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilePreviewPage(
          filePath: file.path,
          fileName: file.name,
          fileSize: file.size,
        ),
      ),
    );
  }

  void _openFileEditor(BuildContext context, FileInfo file) {
    appLogger.dWithPackage('files_page', '_openFileEditor: 打开编辑器 ${file.path}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileEditorPage(
          filePath: file.path,
          fileName: file.name,
        ),
      ),
    );
  }

  void _startDownload(BuildContext context, FilesProvider provider, FileInfo file, AppLocalizations l10n) {
    appLogger.dWithPackage('files_page', '_startDownload: 开始下载 ${file.name}');
    
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            if (provider.data.isDownloading) {
              final progress = (provider.data.downloadProgress * 100).toInt();
              return Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.filesDownloadProgress(progress)),
                  ),
                ],
              );
            }
            return Text(l10n.filesDownloadSuccess);
          },
        ),
        duration: const Duration(seconds: 30),
        action: SnackBarAction(
          label: l10n.commonCancel,
          onPressed: () {
            provider.cancelDownload();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    provider.downloadFile(file).then((savePath) {
      if (savePath != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.filesDownloadSuccess),
            action: SnackBarAction(
              label: l10n.commonConfirm,
              onPressed: () {},
            ),
          ),
        );
      }
    }).catchError((e, stackTrace) async {
      appLogger.eWithPackage('files_page', '_startDownload: 下载失败', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final errorMsg = e.toString();
        if (errorMsg.contains('cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.filesDownloadCancelled)),
          );
        } else if (errorMsg.contains('storage_permission_denied')) {
          final isPermanentlyDenied = await provider.isStoragePermissionPermanentlyDenied();
          if (isPermanentlyDenied && context.mounted) {
            _showPermissionSettingsDialog(context, l10n);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('存储权限被拒绝，无法下载文件'),
                action: SnackBarAction(
                  label: '设置',
                  onPressed: () => _showPermissionSettingsDialog(context, l10n),
                ),
              ),
            );
          }
        } else {
          DebugErrorDialog.show(context, l10n.filesDownloadFailed, e, stackTrace: stackTrace);
        }
      }
    });
  }

  void _showPermissionSettingsDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('存储权限'),
        content: const Text('请在设置中授予存储权限以保存下载文件'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Permission.storage.request().then((_) {
                Permission.manageExternalStorage.request();
              });
            },
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, FilesProvider provider, FileInfo file, AppLocalizations l10n) async {
    appLogger.dWithPackage('files_page', '_toggleFavorite: path=${file.path}');
    
    final isFavorite = provider.data.isFavorite(file.path);
    
    if (isFavorite) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesFavoritesAdded)),
        );
      }
      return;
    }
    
    try {
      await provider.addToFavorites(file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesFavoritesAdded)),
        );
      }
    } on DioException catch (e) {
      appLogger.eWithPackage('files_page', '_toggleFavorite: 失败', error: e);
      if (context.mounted) {
        final errorMsg = e.response?.data?.toString() ?? e.message ?? '';
        if (errorMsg.contains('已收藏') || errorMsg.contains('already')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.filesFavoritesAdded)),
          );
        } else {
          DebugErrorDialog.show(context, l10n.filesFavoritesLoadFailed, e);
        }
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_page', '_toggleFavorite: 失败', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('已收藏') || errorMsg.contains('already')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.filesFavoritesAdded)),
          );
        } else {
          DebugErrorDialog.show(context, l10n.filesFavoritesLoadFailed, e, stackTrace: stackTrace);
        }
      }
    }
  }

  void _showCreateOptions(BuildContext context) {
    final provider = context.read<FilesProvider>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(context.l10n.filesActionNewFolder),
              onTap: () {
                Navigator.pop(sheetContext);
                showCreateDirectoryDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(context.l10n.filesActionNewFile),
              onTap: () {
                Navigator.pop(sheetContext);
                showCreateFileDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(context.l10n.filesActionUpload),
              onTap: () {
                Navigator.pop(sheetContext);
                showUploadDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(context.l10n.filesActionWgetDownload),
              onTap: () {
                Navigator.pop(sheetContext);
                showWgetDialog(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }



  void _showMoreOptions(BuildContext context) {
    final provider = context.read<FilesProvider>();
    final transferManager = context.read<TransferManager>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.swap_vert),
                  if (transferManager.activeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(sheetContext).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${transferManager.activeCount}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(sheetContext).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(sheetContext.l10n.transferManagerTitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _openTransferManager(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(sheetContext.l10n.filesFavorites),
              onTap: () {
                Navigator.pop(sheetContext);
                _openFavorites(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: Text(sheetContext.l10n.filesActionSort),
              onTap: () {
                Navigator.pop(sheetContext);
                showSortOptionsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(sheetContext.l10n.filesActionSearch),
              onTap: () {
                Navigator.pop(sheetContext);
                showSearchDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(sheetContext.l10n.filesUploadHistory),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const UploadHistoryPage(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(sheetContext.l10n.filesMounts),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const MountsPage(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(sheetContext.l10n.filesRecycleBin),
              onTap: () {
                Navigator.pop(sheetContext);
                _openRecycleBin(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openTransferManager(BuildContext context) {
    appLogger.dWithPackage('files_page', '_openTransferManager: 打开传输管理器页面');
    final provider = context.read<FilesProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: const TransferManagerPage(),
        ),
      ),
    );
  }

  void _openFavorites(BuildContext context, FilesProvider provider) async {
    appLogger.dWithPackage('files_page', '_openFavorites: 打开收藏夹页面');
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: const FavoritesPage(),
        ),
      ),
    );

    if (result != null && mounted) {
      appLogger.dWithPackage('files_page', '_openFavorites: 导航到路径=$result');
      provider.navigateTo(result);
    }
  }

  void _openRecycleBin(BuildContext context) {
    appLogger.dWithPackage('files_page', '_openRecycleBin: 打开回收站页面');
    final provider = context.read<FilesProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: const RecycleBinPage(),
        ),
      ),
    );
  }

  Widget _buildServerSelector(BuildContext context) {
    return Consumer<FilesProvider>(
      builder: (context, provider, _) {
        return ServerSwitcherAction(
          onChanged: () async {
            provider.onServerChanged();
          },
        );
      },
    );
  }
}
