import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/panels/panel_presentation.dart';
import 'package:onepanel_client/features/server/widgets/server_actions_menu.dart';
import 'package:onepanel_client/features/server/widgets/server_metric_badges.dart';

class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ServerCardViewModel data;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final panelType = data.config.panelType;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppDesignTokens.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: data.isCurrent
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    foregroundColor: data.isCurrent
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    child: const Icon(Icons.dns_outlined),
                  ),
                  const SizedBox(width: AppDesignTokens.spacingMd),
                  Expanded(
                    child: Text(data.config.name,
                        style: theme.textTheme.titleMedium),
                  ),
                  ServerActionsMenu(
                    onEdit: PanelPresentations.entries.containsKey(panelType)
                        ? onEdit
                        : null,
                    onDelete: onDelete,
                  ),
                ],
              ),
              Wrap(
                spacing: AppDesignTokens.spacingSm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (data.isCurrent) Chip(label: Text(l10n.serverCurrent)),
                  Text(
                    '${PanelPresentations.displayName(panelType)} · ${l10n.serverIpLabel}: ${_extractHost(data.config.url)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              ServerMetricBadges(metrics: data.metrics),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Wrap(
                spacing: AppDesignTokens.spacingMd,
                runSpacing: AppDesignTokens.spacingXs,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ServerConnectionStatus(metrics: data.metrics),
                  Text(
                    l10n.serverOpenDetail,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractHost(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : url;
  }
}
