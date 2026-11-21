import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class ModuleEmptyStateWidget extends StatelessWidget {
  const ModuleEmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actions = const [],
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        primary: false,
        padding: AppDesignTokens.pagePadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                ),
                child: SizedBox.square(
                  dimension: 56,
                  child: Icon(
                    icon,
                    size: 28,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: AppDesignTokens.spacingXs),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (actions.isNotEmpty ||
                  (actionLabel != null && onAction != null)) ...[
                const SizedBox(height: AppDesignTokens.spacingMd),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppDesignTokens.spacingSm,
                  runSpacing: AppDesignTokens.spacingSm,
                  children: [
                    if (actionLabel != null && onAction != null)
                      FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.add_outlined),
                        label: Text(actionLabel!),
                      ),
                    ...actions,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
