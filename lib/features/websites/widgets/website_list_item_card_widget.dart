import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_models.dart';

class WebsitesEmptyView extends StatelessWidget {
  const WebsitesEmptyView({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language_outlined, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

enum WebsiteListAction { start, stop, restart, delete }

class WebsiteListItemCard extends StatelessWidget {
  const WebsiteListItemCard({
    super.key,
    required this.website,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onSelectedChanged,
    required this.onAction,
  });

  final WebsiteInfo website;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectedChanged;
  final void Function(WebsiteListAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = website.status?.toLowerCase() == 'running';
    final statusText =
        isRunning ? l10n.websitesStatusRunning : l10n.websitesStatusStopped;
    final statusColor =
        isRunning ? colorScheme.tertiary : colorScheme.secondary;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: selectionMode
            ? Checkbox(
                value: selected,
                onChanged: (value) => onSelectedChanged(value ?? false),
              )
            : Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
        title: Text(website.displayDomain ?? l10n.websitesUnknownDomain),
        subtitle: Text(
          '$statusText'
          '${website.type?.isNotEmpty == true ? ' · ${website.type}' : ''}'
          '${website.group?.isNotEmpty == true ? ' · ${website.group}' : ''}'
          '${website.remark?.isNotEmpty == true ? ' · ${website.remark}' : ''}',
        ),
        trailing: selectionMode
            ? null
            : PopupMenuButton<WebsiteListAction>(
                tooltip: l10n.commonMore,
                onSelected: onAction,
                itemBuilder: (_) => [
                  if (!isRunning)
                    PopupMenuItem(
                      value: WebsiteListAction.start,
                      child: Text(l10n.websitesActionStart),
                    ),
                  if (isRunning)
                    PopupMenuItem(
                      value: WebsiteListAction.stop,
                      child: Text(l10n.websitesActionStop),
                    ),
                  if (isRunning)
                    PopupMenuItem(
                      value: WebsiteListAction.restart,
                      child: Text(l10n.websitesActionRestart),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: WebsiteListAction.delete,
                    child: Text(
                      l10n.websitesActionDelete,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
