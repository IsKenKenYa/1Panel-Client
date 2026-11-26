part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewNavigation on _FilesViewState {
  Widget _buildPathBreadcrumb(
    BuildContext context,
    FilesProvider provider,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final segments = provider.data.currentPath.split('/');
    segments.removeWhere((s) => s.isEmpty);

    final colorScheme = theme.colorScheme;
    final buttonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      visualDensity: AdaptiveLayoutSpec.of(context).adaptiveDensity,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      foregroundColor: colorScheme.onSurface,
    );

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
          color: colorScheme.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => provider.navigateTo('/'),
                    style: buttonStyle,
                    icon: Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    label:
                        Text(l10n.filesRoot, style: theme.textTheme.labelLarge),
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
                        provider.navigateTo(path);
                      },
                      style: buttonStyle,
                      child:
                          Text(segments[i], style: theme.textTheme.labelLarge),
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

  Widget _buildSelectionBar(
    BuildContext context,
    FilesProvider provider,
    AppLocalizations l10n,
  ) {
    return SelectionBar(
      selectionCount: provider.data.selectionCount,
      onCompress: () => showCompressDialog(
        context,
        provider,
        provider.data.selectedFiles.toList(),
        l10n,
      ),
      onCopy: () => showFileOperationDialog(context, provider, FileOperation.copy),
      onMove: () => showFileOperationDialog(context, provider, FileOperation.move),
      onSelectAll: provider.selectAll,
      onDeselect: provider.clearSelection,
      onDelete: () => showDeleteConfirmDialog(context, provider, l10n),
    );
  }
}
