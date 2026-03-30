part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewItemActions on _FilesViewState {
  Widget _buildFileItem(
    BuildContext context,
    FilesProvider provider,
    FileInfo file,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isSelected = provider.data.isSelected(file.path);
    final isDir = file.isDir;
    final colorScheme = theme.colorScheme;
    final isFavorite = provider.data.isFavorite(file.path);
    final metadata = <String>[
      isDir ? l10n.filesTypeDirectory : _formatFileSize(file.size),
    ];
    final modifiedLabel = _formatModifiedAt(file.modifiedAt);
    if (modifiedLabel != null) {
      metadata.add(modifiedLabel);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDesignTokens.spacingXs),
      color: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          isDir ? Icons.folder_outlined : _getFileIcon(file.name),
          color: isDir
              ? colorScheme.primary
              : _getFileIconColor(file.name, colorScheme),
          size: 32,
        ),
        title: Row(
          children: [
            Expanded(child: Text(file.name)),
            if (isFavorite)
              Icon(Icons.star, size: 18, color: colorScheme.primary),
          ],
        ),
        subtitle: Text(
          metadata.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleFileAction(context, provider, file, value, l10n),
          itemBuilder: (context) => [
            if (isDir)
              PopupMenuItem(value: 'open', child: Text(l10n.filesActionOpen)),
            if (!isDir)
              PopupMenuItem(
                value: 'download',
                child: Text(l10n.filesActionDownload),
              ),
            if (!isDir)
              PopupMenuItem(
                value: 'convert',
                child: Text(l10n.filesEncodingConvert),
              ),
            PopupMenuItem(
              value: 'favorite',
              child: Text(
                isFavorite
                    ? l10n.filesRemoveFromFavorites
                    : l10n.filesAddToFavorites,
              ),
            ),
            PopupMenuItem(value: 'rename', child: Text(l10n.filesActionRename)),
            PopupMenuItem(value: 'copy', child: Text(l10n.filesActionCopy)),
            PopupMenuItem(value: 'move', child: Text(l10n.filesActionMove)),
            if (!isDir && _isCompressedFile(file.name))
              PopupMenuItem(
                value: 'extract',
                child: Text(l10n.filesActionExtract),
              ),
            PopupMenuItem(
              value: 'compress',
              child: Text(l10n.filesActionCompress),
            ),
            PopupMenuItem(
              value: 'permission',
              child: Text(l10n.filesPermissionTitle),
            ),
            PopupMenuItem(
                value: 'link', child: Text(l10n.filesCreateLinkTitle)),
            PopupMenuItem(
              value: 'properties',
              child: Text(l10n.filesPropertiesTitle),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                l10n.filesActionDelete,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ],
        ),
        onLongPress: () => provider.toggleSelection(file.path),
        onTap: () {
          if (provider.data.hasSelection) {
            provider.toggleSelection(file.path);
          } else if (isDir) {
            provider.navigateTo(file.path);
          } else {
            _openFilePreview(context, file);
          }
        },
      ),
    );
  }
}
