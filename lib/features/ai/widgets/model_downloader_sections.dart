import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/model_downloader_models.dart';
import 'package:onepanel_client/features/ai/providers/model_downloader_provider.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 推荐模型分区。
class ModelFeaturedSection extends StatelessWidget {
  const ModelFeaturedSection({super.key, required this.provider});

  final ModelDownloaderProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final families = provider.featured.families;
    final items = provider.featured.items;

    return ExpressiveSection(
      title: l10n.modelDownloaderFeaturedSectionTitle,
      isBusy: provider.featuredLoading,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.sync_outlined),
          tooltip: l10n.modelDownloaderFeaturedSyncAction,
          onPressed: provider.isMutating ? null : () => _syncFeatured(context),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: l10n.commonRefresh,
          onPressed: provider.featuredLoading
              ? null
              : () => provider.loadFeatured(family: provider.featuredFamily),
        ),
      ],
      children: <Widget>[
        if (families.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.spacingLg,
              AppDesignTokens.spacingMd,
              AppDesignTokens.spacingLg,
              AppDesignTokens.spacingSm,
            ),
            child: ExpressiveFilterBar(
              options: <(String, String)>[
                ('all', l10n.alertRuleFilterAllTypes),
                for (final family in families) (family, family),
              ],
              selected: provider.featuredFamily ?? 'all',
              onSelected: (value) => provider.loadFeatured(
                family: value == null || value == 'all' ? null : value,
              ),
            ),
          ),
        if (items.isEmpty)
          ExpressiveHint(
            message: provider.featuredError ??
                l10n.modelDownloaderFeaturedEmptyTitle,
            isError: provider.featuredError != null,
            icon: Icons.widgets_outlined,
          )
        else
          for (final model in items)
            _FeaturedModelRow(model: model, provider: provider),
      ],
    );
  }

  Future<void> _syncFeatured(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await provider.syncFeatured();
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}

class _FeaturedModelRow extends StatelessWidget {
  const _FeaturedModelRow({required this.model, required this.provider});

  final FeaturedModel model;
  final ModelDownloaderProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final description =
        model.description[Localizations.localeOf(context).languageCode] ??
            model.description.values.firstOrNull ??
            '';
    final meta = <String>[
      if (model.family.isNotEmpty) model.family,
      if (model.backboneParams.isNotEmpty) model.backboneParams,
      if (model.weightGB > 0) '${model.weightGB.toStringAsFixed(1)} GB',
      if (model.sources.isNotEmpty) model.sources.join(' / ').toUpperCase(),
    ];

    return ExpressiveRow(
      title: model.repoID.isEmpty ? model.key : model.repoID,
      leadingIcon: Icons.memory_outlined,
      subtitle: description,
      meta: meta,
      trailing: IconButton(
        icon: const Icon(Icons.download_outlined),
        tooltip: l10n.modelDownloaderDownloadAction,
        onPressed: provider.isMutating ? null : () => _download(context),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await provider.downloadFeatured(model);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.modelDownloaderDownloadStarted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}

/// 市场搜索分区。
class ModelSearchSection extends StatefulWidget {
  const ModelSearchSection({super.key, required this.provider});

  final ModelDownloaderProvider provider;

  @override
  State<ModelSearchSection> createState() => _ModelSearchSectionState();
}

class _ModelSearchSectionState extends State<ModelSearchSection> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = widget.provider;
    final results = provider.searchResults;

    return ExpressiveSection(
      title: l10n.modelDownloaderSearchSectionTitle,
      isBusy: provider.searchLoading,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: l10n.modelDownloaderSearchAction,
          onPressed: () => _submit(),
        ),
      ],
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingMd,
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: l10n.modelDownloaderSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: l10n.modelDownloaderSearchAction,
                    onPressed: _submit,
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              ExpressiveFilterBar(
                options: <(String, String)>[
                  ('hf', l10n.modelDownloaderSearchSourceHf),
                  ('modelscope', l10n.modelDownloaderSearchSourceModelScope),
                ],
                selected: provider.searchSource,
                onSelected: (value) {
                  if (value == null) return;
                  provider.setSearchSource(value);
                },
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              ExpressiveFilterBar(
                options: <(String, String)>[
                  ('trending', l10n.modelDownloaderSortTrending),
                  ('downloads', l10n.modelDownloaderSortDownloads),
                  ('likes', l10n.modelDownloaderSortLikes),
                ],
                selected: provider.searchSort,
                onSelected: (value) {
                  if (value == null) return;
                  provider.setSearchSort(value);
                },
              ),
            ],
          ),
        ),
        if (results.isEmpty)
          ExpressiveHint(
            message: provider.searchError ?? l10n.commonEmpty,
            isError: provider.searchError != null,
            icon: Icons.travel_explore_outlined,
          )
        else
          for (final item in results)
            _MarketModelRow(
              item: item,
              source: provider.searchSource,
              provider: provider,
            ),
      ],
    );
  }

  void _submit() {
    widget.provider.search(
      source: widget.provider.searchSource,
      query: _queryController.text.trim(),
    );
  }
}

class _MarketModelRow extends StatelessWidget {
  const _MarketModelRow({
    required this.item,
    required this.source,
    required this.provider,
  });

  final ModelItem item;
  final String source;
  final ModelDownloaderProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meta = <String>[
      if (item.sizeFormatted.isNotEmpty) item.sizeFormatted,
      '${l10n.modelDownloaderDownloadCountLabel} ${item.downloads}',
      '${l10n.modelDownloaderLikeCountLabel} ${item.likes}',
    ];

    return ExpressiveRow(
      title: item.repoID.isEmpty ? item.name : item.repoID,
      leadingIcon: Icons.storefront_outlined,
      subtitle: item.name.isEmpty ? null : item.name,
      meta: meta,
      trailing: IconButton(
        icon: const Icon(Icons.download_outlined),
        tooltip: l10n.modelDownloaderDownloadAction,
        onPressed: provider.isMutating ? null : () => _download(context),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await provider.downloadModel(repoID: item.repoID, source: source);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.modelDownloaderDownloadStarted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}

/// 下载任务分区。
class ModelTasksSection extends StatelessWidget {
  const ModelTasksSection({super.key, required this.provider});

  final ModelDownloaderProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tasks = provider.tasks;
    return ExpressiveSection(
      title: l10n.modelDownloaderTasksSectionTitle,
      isBusy: provider.taskLoading,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: l10n.commonRefresh,
          onPressed: provider.taskLoading ? null : provider.loadTasks,
        ),
      ],
      children: <Widget>[
        if (tasks.isEmpty)
          ExpressiveHint(
            message: provider.taskError ??
                l10n.modelDownloaderTaskEmptyTitle,
            isError: provider.taskError != null,
            icon: Icons.download_outlined,
          )
        else
          for (final task in tasks) _TaskRow(task: task, provider: provider),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.provider});

  final ModelDownloadTaskItem task;
  final ModelDownloaderProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final progress =
        (task.progress > 1 ? task.progress / 100 : task.progress)
            .clamp(0.0, 1.0);
    final name = task.modelName.isEmpty ? task.repoID : task.modelName;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _statusIcon(task.status),
                size: 20,
                color: _statusColor(task.status, scheme),
              ),
              const SizedBox(width: AppDesignTokens.spacingMd),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingSm),
              Text(
                _statusLabel(l10n, task.status),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _statusColor(task.status, scheme),
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%  ·  '
                  '${_formatBytes(task.downloadedSize)} / '
                  '${_formatBytes(task.totalSize)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                ),
              ),
              if (task.canCancel)
                TextButton(
                  onPressed: provider.isMutating ? null : () => _cancel(context),
                  child: Text(l10n.modelDownloaderTaskCancelAction),
                ),
              if (task.canRetry)
                TextButton(
                  onPressed: provider.isMutating ? null : () => _retry(context),
                  child: Text(l10n.modelDownloaderTaskRetryAction),
                ),
              if (task.canRemoveRecord)
                TextButton(
                  onPressed:
                      provider.isMutating ? null : () => _remove(context),
                  child: Text(l10n.modelDownloaderTaskRemoveAction),
                ),
            ],
          ),
          if (task.errorMessage != null && task.errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                task.errorMessage!,
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final l10n = context.l10n;
    final name = task.modelName.isEmpty ? task.repoID : task.modelName;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.modelDownloaderTaskCancelAction,
      message: l10n.modelDownloaderTaskCancelConfirm(name),
      confirmLabel: l10n.modelDownloaderTaskCancelAction,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.cancelTask(task.id);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }

  Future<void> _retry(BuildContext context) async {
    final l10n = context.l10n;
    final name = task.modelName.isEmpty ? task.repoID : task.modelName;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.modelDownloaderTaskRetryAction,
      message: l10n.modelDownloaderTaskRetryConfirm(name),
      confirmLabel: l10n.modelDownloaderTaskRetryAction,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.retryTask(task.id);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }

  Future<void> _remove(BuildContext context) async {
    final l10n = context.l10n;
    final name = task.modelName.isEmpty ? task.repoID : task.modelName;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.modelDownloaderTaskRemoveAction,
      message: l10n.modelDownloaderTaskRemoveConfirm(name),
      confirmLabel: l10n.modelDownloaderTaskRemoveAction,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.removeTask(task.id);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'running':
      case 'Running':
        return Icons.downloading;
      case 'completed':
      case 'Completed':
        return Icons.check_circle_outline;
      case 'failed':
      case 'Failed':
        return Icons.error_outline;
      case 'cancelled':
      case 'Cancelled':
        return Icons.block_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  static String _statusLabel(l10n, String status) {
    switch (status) {
      case 'running':
      case 'Running':
        return l10n.modelDownloaderTaskStatusRunning;
      case 'completed':
      case 'Completed':
        return l10n.modelDownloaderTaskStatusCompleted;
      case 'failed':
      case 'Failed':
        return l10n.modelDownloaderTaskStatusFailed;
      case 'cancelled':
      case 'Cancelled':
        return l10n.modelDownloaderTaskStatusCancelled;
      case 'waiting':
      case 'Waiting':
        return l10n.modelDownloaderTaskStatusWaiting;
      default:
        return status;
    }
  }

  static Color _statusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'failed':
      case 'Failed':
        return scheme.error;
      case 'completed':
      case 'Completed':
        return scheme.primary;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '$bytes B';
  }
}

/// 本地模型分区。
class ModelLocalSection extends StatelessWidget {
  const ModelLocalSection({super.key, required this.provider});

  final ModelDownloaderProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final models = provider.localModels;
    return ExpressiveSection(
      title: l10n.modelDownloaderLocalSectionTitle,
      isBusy: provider.localLoading,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: l10n.commonRefresh,
          onPressed: provider.localLoading ? null : provider.loadLocalModels,
        ),
      ],
      children: <Widget>[
        if (models.isEmpty)
          ExpressiveHint(
            message: provider.localError ??
                l10n.modelDownloaderLocalEmptyTitle,
            isError: provider.localError != null,
            icon: Icons.folder_open_outlined,
          )
        else
          for (final model in models)
            _LocalModelRow(model: model, provider: provider),
      ],
    );
  }
}

class _LocalModelRow extends StatelessWidget {
  const _LocalModelRow({required this.model, required this.provider});

  final LocalModelItem model;
  final ModelDownloaderProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (model.sizeFormatted.isNotEmpty) model.sizeFormatted,
      if (model.source.isNotEmpty) model.source,
      if (model.revision.isNotEmpty) model.revision,
      if (model.createdAt.isNotEmpty) model.createdAt,
    ];

    return ExpressiveRow(
      title: model.name.isEmpty ? model.repoID : model.name,
      leadingIcon: Icons.inventory_2_outlined,
      subtitle: model.path,
      meta: meta,
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: scheme.error),
        tooltip: l10n.modelDownloaderLocalDeleteAction,
        onPressed: provider.isMutating ? null : () => _delete(context),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    var withFile = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.modelDownloaderLocalDeleteAction),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.modelDownloaderLocalDeleteConfirm(
                  model.name.isEmpty ? model.repoID : model.name)),
              const SizedBox(height: AppDesignTokens.spacingSm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: withFile,
                title: Text(l10n.modelDownloaderLocalDeleteFileLabel),
                onChanged: (value) => setState(() => withFile = value ?? true),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.modelDownloaderLocalDeleteAction),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await provider.deleteLocalModel(
        model.name.isEmpty ? model.repoID : model.name,
        downloadType: model.downloadType.isEmpty ? null : model.downloadType,
        withFile: withFile,
      );
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}
