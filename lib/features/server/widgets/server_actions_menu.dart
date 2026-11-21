import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

enum _ServerAction { edit, delete }

class ServerActionsMenu extends StatelessWidget {
  const ServerActionsMenu({super.key, this.onEdit, required this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_ServerAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.commonMore,
      itemBuilder: (_) => [
        if (onEdit != null)
          PopupMenuItem(value: _ServerAction.edit, child: Text(l10n.commonEdit)),
        PopupMenuItem(value: _ServerAction.delete, child: Text(l10n.commonDelete)),
      ],
      onSelected: (action) {
        switch (action) {
          case _ServerAction.edit:
            onEdit?.call();
          case _ServerAction.delete:
            onDelete();
        }
      },
    );
  }
}
