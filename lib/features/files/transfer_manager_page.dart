import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/transfer/transfer_task.dart';
import 'package:onepanel_client/core/services/transfer/transfer_manager.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/providers/transfer_manager_provider.dart';
import 'package:onepanel_client/features/files/upload_history_page.dart';

class TransferManagerPage extends StatefulWidget {
  const TransferManagerPage({super.key});

  @override
  State<TransferManagerPage> createState() => _TransferManagerPageState();
}

class _TransferManagerPageState extends State<TransferManagerPage> {
  late final TransferManagerProvider _provider = TransferManagerProvider()
    ..initialize();

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ChangeNotifierProvider<TransferManagerProvider>.value(
      value: _provider,
      child: Consumer<TransferManagerProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.transferManagerTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: context.read<FilesProvider>(),
                          child: const UploadHistoryPage(),
                        ),
                      ),
                    );
                  },
                  tooltip: l10n.filesUploadHistory,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.loadTasks,
                  tooltip: l10n.commonRefresh,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _showClearDialog(context, provider),
                  tooltip: l10n.transferClearCompleted,
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 840;
                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildDownloadsPane(
                                context,
                                l10n,
                                theme,
                                provider,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildUploadsPane(context, l10n, theme),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: SegmentedButton<TransferChannel>(
                              segments: [
                                ButtonSegment<TransferChannel>(
                                  value: TransferChannel.downloads,
                                  icon: const Icon(Icons.download),
                                  label: Text(l10n.transferDownloads),
                                ),
                                ButtonSegment<TransferChannel>(
                                  value: TransferChannel.uploads,
                                  icon: const Icon(Icons.upload),
                                  label: Text(l10n.transferUploads),
                                ),
                              ],
                              selected: {provider.channel},
                              onSelectionChanged: (value) {
                                provider.setChannel(value.first);
                              },
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child:
                                  provider.channel == TransferChannel.downloads
                                      ? _buildDownloadsPane(
                                          context,
                                          l10n,
                                          theme,
                                          provider,
                                        )
                                      : _buildUploadsPane(context, l10n, theme),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDownloadsPane(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    TransferManagerProvider provider,
  ) {
    final active = provider.getActiveDownloads();
    final completed = provider.getCompletedDownloads();

    if (active.isEmpty && completed.isEmpty) {
      return _EmptyState(text: l10n.transferEmpty);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (active.isNotEmpty) ...[
          _SectionHeader(text: l10n.transferTabActive),
          const SizedBox(height: 8),
          for (final task in active)
            _DownloadTaskTile(
              task: task,
              onRefresh: provider.loadTasks,
            ),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          _SectionHeader(text: l10n.transferTabCompleted),
          const SizedBox(height: 8),
          for (final task in completed)
            _DownloadTaskTile(
              task: task,
              onRefresh: provider.loadTasks,
            ),
        ],
      ],
    );
  }

  Widget _buildUploadsPane(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Consumer<TransferManager>(
      builder: (context, manager, _) {
        final active = manager.activeTasks;
        final pending = manager.pendingTasks;

        if (active.isEmpty && pending.isEmpty) {
          return _EmptyState(text: l10n.transferEmpty);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            if (active.isNotEmpty) ...[
              _SectionHeader(text: l10n.transferTabActive),
              const SizedBox(height: 8),
              for (final task in active) _UploadTaskTile(task: task),
              const SizedBox(height: 16),
            ],
            if (pending.isNotEmpty) ...[
              _SectionHeader(text: l10n.transferTabPending),
              const SizedBox(height: 8),
              for (final task in pending) _UploadTaskTile(task: task),
            ],
          ],
        );
      },
    );
  }

  void _showClearDialog(
    BuildContext context,
    TransferManagerProvider provider,
  ) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transferClearTitle),
        content: Text(l10n.transferClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              await provider.clearCompletedDownloads();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTaskTile extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onRefresh;

  const _DownloadTaskTile({
    required this.task,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final displayStatus = _getDisplayStatus(task);

    return Card.filled(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: _getStatusColor(displayStatus, theme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.filename ?? l10n.systemSettingsUnknown,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.savedDir.split('/').last,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context, theme),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (task.progress / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  _getStatusColor(displayStatus, theme),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${task.progress}%',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  _getStatusText(displayStatus, l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(displayStatus, theme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(context, displayStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ThemeData theme) {
    final displayStatus = _getDisplayStatus(task);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(displayStatus, theme).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(displayStatus, context.l10n),
        style: theme.textTheme.labelSmall?.copyWith(
          color: _getStatusColor(displayStatus, theme),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    DownloadTaskStatus displayStatus,
  ) {
    final manager = TransferManager();
    final l10n = context.l10n;
    final buttons = <Widget>[];

    switch (displayStatus) {
      case DownloadTaskStatus.running:
        buttons.addAll([
          OutlinedButton.icon(
            icon: const Icon(Icons.pause),
            label: Text(l10n.transferPause),
            onPressed: () async {
              await manager.pauseDownloadTask(task.taskId);
              onRefresh();
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.transferCancel),
            onPressed: () async {
              await manager.cancelDownloadTask(task.taskId);
              onRefresh();
            },
          ),
        ]);
        break;
      case DownloadTaskStatus.paused:
        buttons.addAll([
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.transferResume),
            onPressed: () async {
              await manager.resumeDownloadTask(task.taskId);
              onRefresh();
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.transferCancel),
            onPressed: () async {
              await manager.cancelDownloadTask(task.taskId);
              onRefresh();
            },
          ),
        ]);
        break;
      case DownloadTaskStatus.failed:
        buttons.addAll([
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRetry),
            onPressed: () async {
              final result = await manager.retryDownloadTaskWithNewAuth(task);
              if (!context.mounted) return;
              switch (result) {
                case RetryDownloadTaskWithNewAuthResult.recreated:
                  onRefresh();
                  break;
                case RetryDownloadTaskWithNewAuthResult.fileAlreadyDownloaded:
                  _showFloatingSnackBar(
                    context,
                    l10n.transferFileAlreadyDownloaded,
                  );
                  onRefresh();
                  break;
                case RetryDownloadTaskWithNewAuthResult.failed:
                  break;
              }
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete),
            label: Text(l10n.commonDelete),
            onPressed: () async {
              await manager.deleteDownloadTask(task.taskId);
              onRefresh();
            },
          ),
        ]);
        break;
      case DownloadTaskStatus.complete:
        buttons.addAll([
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.transferOpenFile),
            onPressed: () => _openDownloadedFile(context),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.more_horiz),
            label: Text(l10n.commonMore),
            onPressed: () => _showMoreActions(context),
          ),
        ]);
        break;
      case DownloadTaskStatus.canceled:
      case DownloadTaskStatus.undefined:
        buttons.add(
          TextButton.icon(
            icon: const Icon(Icons.delete),
            label: Text(l10n.commonDelete),
            onPressed: () async {
              await manager.deleteDownloadTask(task.taskId);
              onRefresh();
            },
          ),
        );
        break;
      case DownloadTaskStatus.enqueued:
        buttons.add(
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.transferCancel),
            onPressed: () async {
              await manager.cancelDownloadTask(task.taskId);
              onRefresh();
            },
          ),
        );
        break;
    }

    return buttons;
  }

  DownloadTaskStatus _getDisplayStatus(DownloadTask task) {
    if (task.status == DownloadTaskStatus.failed && task.progress == 100) {
      return DownloadTaskStatus.complete;
    }
    return task.status;
  }

  String _resolveFileName() {
    final fromTask = task.filename;
    if (fromTask != null && fromTask.trim().isNotEmpty) return fromTask.trim();

    final uri = Uri.tryParse(task.url);
    final rawPath = uri?.queryParameters['path'];
    if (rawPath == null || rawPath.isEmpty) return '';

    final decoded = Uri.decodeComponent(rawPath);
    final lastSlash = decoded.lastIndexOf('/');
    if (lastSlash < 0) return decoded;
    return decoded.substring(lastSlash + 1);
  }

  Future<void> _openDownloadedFile(BuildContext context) async {
    final l10n = context.l10n;
    final fileName = _resolveFileName();
    final filePath =
        fileName.isEmpty ? task.savedDir : '${task.savedDir}/$fileName';
    final file = File(filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        _showFloatingSnackBar(
          context,
          l10n.transferFileNotFound,
          actionLabel: l10n.transferCopyPath,
          onAction: () => _copyToClipboard(context, filePath),
        );
      }
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (task.status == DownloadTaskStatus.complete) {
          final ok = await FlutterDownloader.open(taskId: task.taskId);
          if (ok == true) return;
        }

        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done && context.mounted) {
          _showFloatingSnackBar(
            context,
            l10n.transferOpenFileError,
            actionLabel: l10n.transferCopyPath,
            onAction: () => _copyToClipboard(context, filePath),
          );
        }
        return;
      }

      await FileSaveService().openFileLocation(filePath);
      if (context.mounted) {
        _showFloatingSnackBar(context, l10n.transferFileLocationOpened);
      }
    } catch (_) {
      if (context.mounted) {
        _showFloatingSnackBar(
          context,
          l10n.transferOpenFileError,
          actionLabel: l10n.transferCopyPath,
          onAction: () => _copyToClipboard(context, filePath),
        );
      }
    }
  }

  Future<void> _showMoreActions(BuildContext context) async {
    final l10n = context.l10n;
    final fileName = _resolveFileName();
    final filePath =
        fileName.isEmpty ? task.savedDir : '${task.savedDir}/$fileName';
    final dirPath = task.savedDir;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l10n.transferOpenFile),
                onTap: () async {
                  Navigator.pop(context);
                  await _openDownloadedFile(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(l10n.transferOpenDownloadsFolder),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await FileSaveService().openDownloadsDirectory();
                  if (!context.mounted) return;
                  if (!ok) {
                    _showFloatingSnackBar(
                      context,
                      l10n.transferOpenFileError,
                      actionLabel: l10n.transferCopyDirectoryPath,
                      onAction: () => _copyToClipboard(context, dirPath),
                    );
                    return;
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.transferCopyPath),
                onTap: () async {
                  Navigator.pop(context);
                  _copyToClipboard(context, filePath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.commonDelete),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () async {
                  Navigator.pop(context);
                  await TransferManager().deleteDownloadTask(task.taskId);
                  onRefresh();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    _showFloatingSnackBar(context, context.l10n.commonCopied);
  }

  Color _getStatusColor(DownloadTaskStatus status, ThemeData theme) {
    switch (status) {
      case DownloadTaskStatus.running:
      case DownloadTaskStatus.enqueued:
        return theme.colorScheme.primary;
      case DownloadTaskStatus.paused:
        return theme.colorScheme.tertiary;
      case DownloadTaskStatus.complete:
        return theme.colorScheme.secondary;
      case DownloadTaskStatus.failed:
        return theme.colorScheme.error;
      case DownloadTaskStatus.canceled:
      case DownloadTaskStatus.undefined:
        return theme.colorScheme.outline;
    }
  }

  String _getStatusText(DownloadTaskStatus status, AppLocalizations l10n) {
    switch (status) {
      case DownloadTaskStatus.running:
        return l10n.transferStatusRunning;
      case DownloadTaskStatus.paused:
        return l10n.transferStatusPaused;
      case DownloadTaskStatus.complete:
        return l10n.transferStatusCompleted;
      case DownloadTaskStatus.failed:
        return l10n.transferStatusFailed;
      case DownloadTaskStatus.canceled:
        return l10n.transferStatusCancelled;
      case DownloadTaskStatus.enqueued:
        return l10n.transferStatusPending;
      case DownloadTaskStatus.undefined:
        return l10n.transferStatusFailed;
    }
  }
}

class _UploadTaskTile extends StatelessWidget {
  final TransferTask task;

  const _UploadTaskTile({
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card.filled(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: _getStatusColor(task.status, theme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.fileName ?? task.path.split('/').last,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSize(task.totalSize),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context, theme),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: task.progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  _getStatusColor(task.status, theme),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  task.progressPercent,
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  _getStatusText(task.status, l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(task.status, theme),
                  ),
                ),
              ],
            ),
            if (task.error != null) ...[
              const SizedBox(height: 8),
              Text(
                task.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(task.status, theme).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(task.status, context.l10n),
        style: theme.textTheme.labelSmall?.copyWith(
          color: _getStatusColor(task.status, theme),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final manager = context.read<TransferManager>();
    final l10n = context.l10n;
    final buttons = <Widget>[];

    switch (task.status) {
      case TransferStatus.running:
        buttons.addAll([
          OutlinedButton.icon(
            icon: const Icon(Icons.pause),
            label: Text(l10n.transferPause),
            onPressed: () => manager.pauseTask(task.id),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.transferCancel),
            onPressed: () => manager.cancelUploadTask(task.id),
          ),
        ]);
        break;
      case TransferStatus.paused:
      case TransferStatus.failed:
        buttons.addAll([
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.transferResume),
            onPressed: () => manager.resumeTask(task.id),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.transferCancel),
            onPressed: () => manager.cancelUploadTask(task.id),
          ),
        ]);
        break;
      case TransferStatus.pending:
        buttons.add(
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.transferCancel),
            onPressed: () => manager.cancelUploadTask(task.id),
          ),
        );
        break;
      case TransferStatus.completed:
      case TransferStatus.cancelled:
        break;
    }

    return buttons;
  }

  Color _getStatusColor(TransferStatus status, ThemeData theme) {
    switch (status) {
      case TransferStatus.running:
        return theme.colorScheme.primary;
      case TransferStatus.paused:
        return theme.colorScheme.tertiary;
      case TransferStatus.completed:
        return theme.colorScheme.secondary;
      case TransferStatus.failed:
        return theme.colorScheme.error;
      case TransferStatus.cancelled:
        return theme.colorScheme.outline;
      case TransferStatus.pending:
        return theme.colorScheme.secondary;
    }
  }

  String _getStatusText(TransferStatus status, AppLocalizations l10n) {
    switch (status) {
      case TransferStatus.running:
        return l10n.transferStatusRunning;
      case TransferStatus.paused:
        return l10n.transferStatusPaused;
      case TransferStatus.completed:
        return l10n.transferStatusCompleted;
      case TransferStatus.failed:
        return l10n.transferStatusFailed;
      case TransferStatus.cancelled:
        return l10n.transferStatusCancelled;
      case TransferStatus.pending:
        return l10n.transferStatusPending;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

void _showFloatingSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: theme.colorScheme.inverseSurface,
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            )
          : null,
    ),
  );
}
