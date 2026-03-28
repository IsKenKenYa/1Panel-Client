import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';

class ConfigDiffPreviewCard extends StatelessWidget {
  const ConfigDiffPreviewCard({
    super.key,
    required this.title,
    required this.items,
    this.onApply,
    this.onDiscard,
    this.applyLabel = 'Apply changes',
    this.discardLabel = 'Discard',
  });

  final String title;
  final List<ConfigDiffItem> items;
  final VoidCallback? onApply;
  final VoidCallback? onDiscard;
  final String applyLabel;
  final String discardLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            for (final item in items) ...[
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppDesignTokens.spacingXs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDesignTokens.spacingSm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                ),
                child: Text(
                  '- ${item.currentValue}\n+ ${item.nextValue}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
            ],
            if (onApply != null || onDiscard != null)
              Row(
                children: [
                  if (onDiscard != null)
                    TextButton(
                      onPressed: onDiscard,
                      child: Text(discardLabel),
                    ),
                  if (onApply != null)
                    FilledButton(
                      onPressed: onApply,
                      child: Text(applyLabel),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
