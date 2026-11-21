import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class AlertConfigurationRow extends StatelessWidget {
  const AlertConfigurationRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.isMutating,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.description,
    this.titleLines = 2,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? description;
  final int titleLines;
  final bool enabled;
  final bool isMutating;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: titleLines,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingXs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: isMutating ? null : onToggle),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppDesignTokens.spacingXs + 2),
            Text(
              description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppDesignTokens.spacingXs),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isMutating ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(context.l10n.commonEdit),
              ),
              TextButton.icon(
                onPressed: isMutating ? null : onDelete,
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(context.l10n.commonDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
