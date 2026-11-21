import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/panels/panel_presentation.dart';
import 'package:onepanel_client/features/server/widgets/server_metric_badges.dart';
import 'package:onepanel_client/shared/widgets/metric_card.dart';

class ServerDetailHeaderCard extends StatelessWidget {
  const ServerDetailHeaderCard({
    super.key,
    required this.server,
    required this.onRefresh,
  });

  final ServerCardViewModel server;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(server.config.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppDesignTokens.spacingSm),
            Wrap(
              spacing: AppDesignTokens.spacingSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(PanelPresentations.displayName(server.config.panelType)),
                if (server.isCurrent) Chip(label: Text(l10n.serverCurrent)),
              ],
            ),
            Text(
              server.config.url,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            MetricOverviewGrid(
              cpuPercent: server.metrics.cpuPercent,
              memoryPercent: server.metrics.memoryPercent,
              diskPercent: server.metrics.diskPercent,
              load: server.metrics.load,
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppDesignTokens.spacingSm,
                runSpacing: AppDesignTokens.spacingSm,
                children: [
                  ServerConnectionStatus(metrics: server.metrics),
                  FilledButton.tonalIcon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_outlined),
                    label: Text(l10n.serverActionRefresh),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
