import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_models.dart';

class WebsiteOverviewCard extends StatelessWidget {
  const WebsiteOverviewCard({
    super.key,
    required this.website,
  });

  final WebsiteInfo? website;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final status = website?.status ?? '-';
    final isRunning = status.toLowerCase() == 'running';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    website?.displayDomain ?? l10n.websitesUnknownDomain,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? colorScheme.tertiaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isRunning
                        ? l10n.websitesStatusRunning
                        : l10n.websitesStatusStopped,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isRunning
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailLine(
              context,
              '${l10n.websitesTypeLabel}: ${website?.type ?? '-'}',
            ),
            if (website?.proxy?.isNotEmpty == true)
              _buildDetailLine(
                context,
                '${l10n.websitesProxyAddressLabel}: ${website?.proxy}',
              ),
            if (website?.proxyType?.isNotEmpty == true)
              _buildDetailLine(
                context,
                '${l10n.websitesProxyTypeLabel}: ${website?.proxyType}',
              ),
            if (website?.dbType?.isNotEmpty == true)
              _buildDetailLine(
                context,
                '${l10n.websitesBasicConfigDatabaseTitle}: ${website?.dbType}',
              ),
            _buildDetailLine(
              context,
              '${l10n.websitesProtocolLabel}: ${website?.protocol ?? '-'}',
            ),
            if (website?.sslStatus?.isNotEmpty == true)
              _buildDetailLine(
                context,
                '${l10n.websitesSslStatusLabel}: ${website?.sslStatus}',
              ),
            if (website?.sslExpireDate?.isNotEmpty == true)
              _buildDetailLine(
                context,
                '${l10n.websitesSslExpireLabel}: ${website?.sslExpireDate}',
              ),
            _buildDetailLine(
              context,
              '${l10n.websitesSitePathLabel}: ${website?.sitePath ?? '-'}',
            ),
            _buildDetailLine(
              context,
              '${l10n.websitesGroupLabel}: ${website?.group ?? '-'}',
            ),
            _buildDetailLine(
              context,
              '${l10n.websitesRemarkLabel}: ${website?.remark ?? '-'}',
            ),
            _buildDetailLine(
              context,
              '${l10n.websitesRuntimeLabel}: ${website?.runtimeName ?? website?.runtimeTypeName ?? '-'}',
            ),
            _buildDetailLine(
              context,
              '${l10n.websitesDefaultServerLabel}: ${(website?.defaultServer ?? false) ? l10n.commonYes : l10n.commonNo}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailLine(BuildContext context, String value) {
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class WebsiteActionCard extends StatelessWidget {
  const WebsiteActionCard({
    super.key,
    required this.website,
    required this.onOperate,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final WebsiteInfo? website;
  final Future<void> Function(String action) onOperate;
  final VoidCallback onEdit;
  final Future<void> Function() onSetDefault;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRunning = website?.status?.toLowerCase() == 'running';
    final isDefault = website?.defaultServer ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.websitesDetailActionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isRunning ? null : () => onOperate('start'),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.websitesActionStart),
                ),
                FilledButton.icon(
                  onPressed: isRunning ? () => onOperate('stop') : null,
                  icon: const Icon(Icons.stop),
                  label: Text(l10n.websitesActionStop),
                ),
                OutlinedButton.icon(
                  onPressed: isRunning ? () => onOperate('restart') : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.websitesActionRestart),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.commonEdit),
                ),
                OutlinedButton.icon(
                  onPressed: isDefault ? null : onSetDefault,
                  icon: const Icon(Icons.star_outline),
                  label: Text(l10n.websitesSetDefaultAction),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.commonDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
