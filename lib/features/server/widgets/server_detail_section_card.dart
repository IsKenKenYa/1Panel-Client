import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';

class ServerDetailSectionItem {
  const ServerDetailSectionItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class ServerDetailSectionCard extends StatelessWidget {
  const ServerDetailSectionCard({
    super.key,
    required this.title,
    required this.items,
    this.action,
    this.description,
  });

  final String title;
  final String? description;
  final Widget? action;
  final List<ServerDetailSectionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (action != null) action!,
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: AppDesignTokens.spacingXs),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: AppDesignTokens.spacingSm),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                ListTile(
                  leading: Icon(items[index].icon),
                  title: Text(items[index].title),
                  subtitle: items[index].subtitle == null
                      ? null
                      : Text(items[index].subtitle!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: items[index].onTap,
                ),
                if (index < items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
