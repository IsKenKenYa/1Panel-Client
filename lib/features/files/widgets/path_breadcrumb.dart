import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class PathBreadcrumb extends StatelessWidget {
  const PathBreadcrumb({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  final String currentPath;
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final segments = currentPath.split('/');
    segments.removeWhere((s) => s.isEmpty);

    final buttonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      foregroundColor: colorScheme.onSurface,
    );
    final breadcrumbTextStyle = theme.textTheme.labelLarge;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingSm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => onNavigate('/'),
                    style: buttonStyle,
                    icon: Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    label: Text(l10n.filesRoot, style: breadcrumbTextStyle),
                  ),
                  for (int i = 0; i < segments.length; i++) ...[
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    TextButton(
                      onPressed: () {
                        final path = '/${segments.sublist(0, i + 1).join('/')}';
                        onNavigate(path);
                      },
                      style: buttonStyle,
                      child: Text(segments[i], style: breadcrumbTextStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
