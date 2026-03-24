import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showSortOptionsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.filesActionSort),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(context.l10n.filesSortByName),
            onTap: () {
              Navigator.pop(context);
              context.read<FilesProvider>().setSorting('name', 'asc');
            },
          ),
          ListTile(
            title: Text(context.l10n.filesSortBySize),
            onTap: () {
              Navigator.pop(context);
              context.read<FilesProvider>().setSorting('size', 'desc');
            },
          ),
          ListTile(
            title: Text(context.l10n.filesSortByDate),
            onTap: () {
              Navigator.pop(context);
              context.read<FilesProvider>().setSorting('modifiedAt', 'desc');
            },
          ),
        ],
      ),
    ),
  );
}
