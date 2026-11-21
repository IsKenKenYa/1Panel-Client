import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class DatabaseTileContent extends StatelessWidget {
  const DatabaseTileContent.metric({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : _action = false;

  const DatabaseTileContent.action({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : _action = true;

  final IconData icon;
  final String title;
  final String subtitle;
  final bool _action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.onSecondaryContainer, size: 20),
        ),
        const SizedBox(width: AppDesignTokens.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _action
                    ? null
                    : theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
              ),
              SizedBox(height: _action ? 2 : AppDesignTokens.spacingXs),
              Text(
                subtitle,
                style: _action
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )
                    : theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
        if (_action) const Icon(Icons.chevron_right),
      ],
    );
  }
}
