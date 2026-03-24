part of 'package:onepanelapp_app/features/files/files_page.dart';

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
      visualDensity: VisualDensity.compact,
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
          color: colorScheme.surfaceContainerLow,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('${provider.data.selectionCount} ${l10n.filesSelected}'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.folder_zip_outlined),
            onPressed: () => showCompressDialog(
              context,
              provider,
              provider.data.selectedFiles.toList(),
              l10n,
            ),
            tooltip: l10n.filesActionCompress,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () => showBatchCopyDialog(context, provider, l10n),
            tooltip: l10n.filesActionCopy,
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            onPressed: () => showBatchMoveDialog(context, provider, l10n),
            tooltip: l10n.filesActionMove,
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () => provider.selectAll(),
            tooltip: l10n.filesActionSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: () => provider.clearSelection(),
            tooltip: l10n.filesActionDeselect,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => showDeleteConfirmDialog(context, provider, l10n),
            tooltip: l10n.filesActionDelete,
          ),
        ],
      ),
    );
  }
}
