import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

/// 模板分区：列表、删除与磁盘删除选项。
class VmTemplateTab extends StatelessWidget {
  const VmTemplateTab({super.key});

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
                onPressed: provider.isMutating ? null : provider.loadTemplates,
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading:
                provider.templateState.isLoading && provider.templates.isEmpty,
            isEmpty:
                provider.templates.isEmpty &&
                provider.templateState.error == null,
            errorMessage: provider.templateState.error,
            onRetry: provider.loadTemplates,
            emptyTitle: l10n.vmTemplateEmptyTitle,
            emptyDescription: l10n.vmTemplateEmptyDescription,
            emptyIcon: Icons.copy_all_outlined,
            child: RefreshIndicator(
              onRefresh: provider.loadTemplates,
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
                    title: l10n.vmTabTemplates,
                    isBusy: provider.templateState.isLoading,
                    children: <Widget>[
                      for (final template in provider.templates)
                        _TemplateCard(template: template, provider: provider),
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.provider});

  final VMTemplateItem template;
  final VmProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final meta = <String>[
      '${template.cpu} ${l10n.vmOverviewCoresUnit}',
      '${template.memory} MiB',
      _formatBytes(template.diskSize),
      if (template.sourceVM.isNotEmpty) template.sourceVM,
      if (template.storagePool.isNotEmpty) template.storagePool,
    ];
    final statusText = template.isExist
        ? l10n.vmIsoStatusReady
        : l10n.vmIsoStatusFileMissing;
    final statusColor = template.isExist ? scheme.primary : scheme.error;

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
                  color: template.isExist
                      ? scheme.secondaryContainer
                      : scheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.copy_all_outlined,
                  size: 20,
                  color: template.isExist
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
                            template.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDesignTokens.spacingSm),
                        Text(
                          statusText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDesignTokens.spacingXs),
                    Text(
                      meta.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (template.diskPath.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        template.diskPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (template.description.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        template.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingXs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: provider.isMutating
                  ? null
                  : () => _deleteTemplate(context, template),
              icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
              label: Text(
                l10n.vmTemplateDeleteAction,
                style: TextStyle(color: scheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    VMTemplateItem template,
  ) async {
    final l10n = context.l10n;
    var deleteDisk = false;
    final confirmed = await showAppFormDialog(
      context,
      title: l10n.vmTemplateDeleteAction,
      confirmLabel: l10n.vmTemplateDeleteAction,
      destructive: true,
      onConfirm: () async {},
      content: StatefulBuilder(
        builder: (_, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${template.name}\n${template.diskPath}'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: deleteDisk,
              title: Text(l10n.vmTemplateDeleteDiskLabel),
              onChanged: (value) => setState(() => deleteDisk = value ?? false),
            ),
          ],
        ),
      ),
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await provider.deleteTemplate(template.id, deleteDisk: deleteDisk);
      if (!context.mounted) {
        return;
      }
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      SnackBarUtils.showError(context, error.toString());
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '$bytes B';
  }
}
