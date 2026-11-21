import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';

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
    final l10n = context.l10n;
    return ModuleEmptyStateWidget(
      icon: Icons.folder_open_outlined,
      title: l10n.filesEmptyTitle,
      description: l10n.filesEmptyDesc,
      actions: [
        FilledButton.icon(
          onPressed: onCreateFolder,
          icon: const Icon(Icons.create_new_folder_outlined),
          label: Text(l10n.filesActionNewFolder),
        ),
        OutlinedButton.icon(
          onPressed: onCreateFile,
          icon: const Icon(Icons.note_add_outlined),
          label: Text(l10n.filesActionNewFile),
        ),
      ],
    );
  }
}
