import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/status_label_widget.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/widgets/vm_iso_form.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

/// ISO 分区：状态标签、导入进度与三种来源入口。
class VmIsoTab extends StatelessWidget {
  const VmIsoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<VmProvider>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingMd,
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingSm,
          ),
          child: Row(
            children: <Widget>[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: l10n.commonRefresh,
                onPressed: provider.isMutating ? null : provider.loadIsos,
              ),
              FilledButton.tonalIcon(
                onPressed: () => showVmIsoForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.vmIsoCreateAction),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.isoState.isLoading && provider.isos.isEmpty,
            isEmpty: provider.isos.isEmpty && provider.isoState.error == null,
            errorMessage: provider.isoState.error,
            onRetry: provider.loadIsos,
            emptyTitle: l10n.vmIsoEmptyTitle,
            emptyDescription: l10n.vmIsoEmptyDescription,
            emptyIcon: Icons.album_outlined,
            emptyActionLabel: l10n.vmIsoCreateAction,
            onEmptyAction: () => showVmIsoForm(context),
            child: RefreshIndicator(
              onRefresh: provider.loadIsos,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingSm,
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingXl +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: <Widget>[
                  ExpressiveSection(
                    title: l10n.vmTabIso,
                    isBusy: provider.isos.isEmpty == false &&
                        provider.isMutating,
                    children: <Widget>[
                      for (final iso in provider.isos)
                        _IsoCard(iso: iso, provider: provider),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IsoCard extends StatelessWidget {
  const _IsoCard({required this.iso, required this.provider});

  final VMIsoItem iso;
  final VmProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final meta = <String>[
      if (iso.isExist) _formatBytes(iso.size),
      if (iso.type.isNotEmpty) iso.type,
      if (iso.createdAt.isNotEmpty) iso.createdAt,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iso.isExist
                      ? scheme.secondaryContainer
                      : scheme.errorContainer,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.album_outlined,
                  size: 20,
                  color: iso.isExist
                      ? scheme.onSecondaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            iso.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDesignTokens.spacingSm),
                        _IsoStatusChip(iso: iso),
                      ],
                    ),
                    const SizedBox(height: AppDesignTokens.spacingXs),
                    Text(
                      iso.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        meta.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (iso.error.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        iso.error,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton.icon(
                onPressed: provider.isMutating
                    ? null
                    : () => showVmIsoForm(context, editing: iso),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.vmIsoEditAction),
              ),
              TextButton.icon(
                onPressed: provider.isMutating || !iso.isExist
                    ? null
                    : () => _deleteIso(context, iso),
                icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                label: Text(
                  l10n.vmIsoDeleteAction,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIso(BuildContext context, VMIsoItem iso) async {
    final l10n = context.l10n;
    var deleteFile = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.vmIsoDeleteAction),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(iso.name),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: deleteFile,
                title: Text(l10n.vmIsoDeleteFileLabel),
                onChanged: (value) => setState(() => deleteFile = value ?? false),
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
              child: Text(l10n.vmIsoDeleteAction),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await provider.deleteIso(iso.id, deleteFile: deleteFile);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
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

class _IsoStatusChip extends StatelessWidget {
  const _IsoStatusChip({required this.iso});

  final VMIsoItem iso;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final status = iso.status.trim().toLowerCase();
    String label;
    Color background;
    Color foreground;
    if (!iso.isExist) {
      label = l10n.vmIsoStatusFileMissing;
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else {
      switch (status) {
        case 'ready':
          label = l10n.vmIsoStatusReady;
          background = scheme.primaryContainer;
          foreground = scheme.onPrimaryContainer;
        case 'uploading':
          label = l10n.vmIsoStatusUploading;
          background = scheme.secondaryContainer;
          foreground = scheme.onSecondaryContainer;
        case 'downloading':
          label = l10n.vmIsoStatusDownloading;
          background = scheme.secondaryContainer;
          foreground = scheme.onSecondaryContainer;
        case 'failed':
          label = l10n.vmIsoStatusFailed;
          background = scheme.errorContainer;
          foreground = scheme.onErrorContainer;
        default:
          label = iso.status;
          background = scheme.surfaceContainerHighest;
          foreground = scheme.onSurfaceVariant;
      }
    }
    return StatusLabelWidget(
      label: label,
      color: foreground,
      backgroundColor: background,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      radius: 6,
    );
  }
}
