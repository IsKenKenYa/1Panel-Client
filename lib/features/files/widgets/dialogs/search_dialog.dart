import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showSearchDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.filesActionSearch),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: context.l10n.filesSearchHint,
          prefixIcon: const Icon(Icons.search),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<FilesProvider>().setSearchQuery(null);
          },
          child: Text(context.l10n.filesSearchClear),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<FilesProvider>().setSearchQuery(controller.text);
            context.read<FilesProvider>().loadFiles();
          },
          child: Text(context.l10n.commonSearch),
        ),
      ],
    ),
  );
}
