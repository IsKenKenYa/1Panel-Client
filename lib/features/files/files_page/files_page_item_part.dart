part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewItemActions on _FilesViewState {
  Widget _buildFileItem(BuildContext context, FilesProvider provider,
      FileInfo file, ThemeData theme, AppLocalizations l10n,
      {int? index}) {
    final isSelected = provider.data.isSelected(file.path);
    final isDir = file.isDir;
    final colorScheme = theme.colorScheme;
    final isFavorite = provider.data.isFavorite(file.path);
    final metadata = <String>[
      isDir ? l10n.filesTypeDirectory : _formatFileSize(file.size),
    ];
    if (file.permission != null && file.permission!.isNotEmpty) {
      metadata.add(file.permission!);
    }
    if (file.user != null && file.user!.isNotEmpty) {
      metadata.add(file.user!);
    }
    final modifiedLabel = _formatModifiedAt(file.modifiedAt);
    if (modifiedLabel != null) {
      metadata.add(modifiedLabel);
    }

    final isDesktop = PlatformUtils.isDesktop(context);

    Widget content = Card(
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
        trailing: isDesktop
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleFileAction(context, provider, file, value, l10n),
                itemBuilder: (context) =>
                    _buildFileMenu(context, provider, file, l10n),
              ),
        onLongPress: () {
          if (!isDesktop) {
            provider.toggleSelection(file.path);
          }
        },
        onTap: () {
          if (!isDesktop) {
            if (provider.data.hasSelection) {
              provider.toggleSelection(file.path);
            } else if (isDir) {
              provider.navigateTo(file.path);
            } else {
              _openFilePreview(context, file);
            }
          }
        },
      ),
    );

    if (isDesktop) {
      // Add right-click menu and keyboard selection
      final selectableContent = content;
      content = GestureDetector(
        onSecondaryTapDown: (details) {
          if (!isSelected) {
            provider.selectOnly(file.path);
          }
          _showDesktopContextMenu(
              context, details.globalPosition, provider, file, l10n);
        },
        onDoubleTap: () {
          if (isDir) {
            provider.navigateTo(file.path);
          } else {
            _openFilePreview(context, file);
          }
        },
        onTap: () {
          final isShiftPressed = KeyboardUtils.isShiftPressed();
          final isControlPressed = KeyboardUtils.isModifierPressed();

          if (isControlPressed) {
            provider.toggleSelection(file.path);
            if (index != null) provider.setLastSelectedIndex(index);
          } else if (isShiftPressed && index != null) {
            provider.selectRange(index);
          } else {
            provider.selectOnly(file.path);
            if (index != null) provider.setLastSelectedIndex(index);
          }
        },
        child: selectableContent,
      );

      // Add Drag & Drop support
      final draggableContent = content;
      content = LongPressDraggable<List<String>>(
        data: provider.data.hasSelection && isSelected
            ? provider.data.selectedFiles.toList()
            : [file.path],
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDir ? Icons.folder_outlined : _getFileIcon(file.name),
                  color: isDir
                      ? colorScheme.primary
                      : _getFileIconColor(file.name, colorScheme),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.data.hasSelection && isSelected
                      ? '${provider.data.selectionCount} items'
                      : file.name,
                ),
              ],
            ),
          ),
        ),
        child: isDir
            ? DragTarget<List<String>>(
                onWillAcceptWithDetails: (details) {
                  final paths = details.data;
                  return !paths.contains(file.path) &&
                      !paths.any((p) => file.path.startsWith('$p/'));
                },
                onAcceptWithDetails: (details) {
                  final paths = details.data;
                  provider.moveFiles(paths, file.path);
                  provider.clearSelection();
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: candidateData.isNotEmpty
                        ? BoxDecoration(
                            border: Border.all(
                                color: colorScheme.primary, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          )
                        : null,
                    child: draggableContent,
                  );
                },
              )
            : draggableContent,
      );
    }

    return content;
  }

  List<PopupMenuEntry<String>> _buildFileMenu(
    BuildContext context,
    FilesProvider provider,
    FileInfo file,
    AppLocalizations l10n,
  ) {
    final isDir = file.isDir;
    final isFavorite = provider.data.isFavorite(file.path);
    final colorScheme = Theme.of(context).colorScheme;

    return [
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
          isFavorite ? l10n.filesRemoveFromFavorites : l10n.filesAddToFavorites,
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
      PopupMenuItem(value: 'link', child: Text(l10n.filesCreateLinkTitle)),
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
    ];
  }

  Future<void> _showDesktopContextMenu(
    BuildContext context,
    Offset position,
    FilesProvider provider,
    FileInfo file,
    AppLocalizations l10n,
  ) async {
    if (!mounted) return;
    final currentContext = context;
    final value = await showMenu<String>(
      context: currentContext,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: _buildFileMenu(currentContext, provider, file, l10n),
    );
    if (!mounted || !currentContext.mounted) return;
    if (value != null) {
      _handleFileAction(currentContext, provider, file, value, l10n);
    }
  }
}
