import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.selectionCount,
    this.onCompress,
    this.onCopy,
    this.onMove,
    this.onSelectAll,
    this.onDeselect,
    this.onDelete,
  })  : _isRecycleBin = false,
        onRestore = null;

  const SelectionBar.recycleBin({
    super.key,
    required this.selectionCount,
    required this.onRestore,
    required VoidCallback onDeletePermanently,
    required this.onSelectAll,
    required this.onDeselect,
  })  : _isRecycleBin = true,
        onDelete = onDeletePermanently,
        onCompress = null,
        onCopy = null,
        onMove = null;

  final int selectionCount;
  final bool _isRecycleBin;
  final VoidCallback? onRestore;
  final VoidCallback? onCompress;
  final VoidCallback? onCopy;
  final VoidCallback? onMove;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

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
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(_isRecycleBin
                ? '$selectionCount ${l10n.filesSelected}'
                : l10n.filesSelectedCount(selectionCount)),
            Wrap(
              children: [
                if (_isRecycleBin) ...[
                  IconButton(
                    icon: const Icon(Icons.restore_outlined),
                    onPressed: onRestore,
                    tooltip: l10n.recycleBinRestore,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_outlined),
                    onPressed: onDelete,
                    tooltip: l10n.recycleBinDeletePermanently,
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.folder_zip_outlined),
                    onPressed: onCompress,
                    tooltip: l10n.filesActionCompress,
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: onCopy,
                    tooltip: l10n.filesActionCopy,
                  ),
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_outline),
                    onPressed: onMove,
                    tooltip: l10n.filesActionMove,
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: onSelectAll,
                  tooltip: l10n.filesActionSelectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.deselect),
                  onPressed: onDeselect,
                  tooltip: l10n.filesActionDeselect,
                ),
                if (!_isRecycleBin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: l10n.filesActionDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
