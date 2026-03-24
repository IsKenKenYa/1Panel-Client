import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.onCreateFolder,
    this.onCreateFile,
  });

  final VoidCallback? onCreateFolder;
  final VoidCallback? onCreateFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(l10n.filesEmptyTitle),
          const SizedBox(height: 8),
          Text(l10n.filesEmptyDesc, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onCreateFolder,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.filesActionNewFolder),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onCreateFile,
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.filesActionNewFile),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
