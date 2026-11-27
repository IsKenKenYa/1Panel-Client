import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

void showSortOptionsDialog(BuildContext context) {
  final provider = context.read<FilesProvider>();
  final l10n = context.l10n;
  showAppFormSheet<void>(
    context,
    title: l10n.filesActionSort,
    builder: (sheetContext) => ListTileTheme(
      data: const ListTileThemeData(
        minTileHeight: kMinInteractiveDimension,
        visualDensity: VisualDensity.standard,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(l10n.filesSortByName),
            onTap: () {
              Navigator.pop(sheetContext);
              provider.setSorting('name', 'asc');
            },
          ),
          ListTile(
            title: Text(l10n.filesSortBySize),
            onTap: () {
              Navigator.pop(sheetContext);
              provider.setSorting('size', 'desc');
            },
          ),
          ListTile(
            title: Text(l10n.filesSortByDate),
            onTap: () {
              Navigator.pop(sheetContext);
              provider.setSorting('modifiedAt', 'desc');
            },
          ),
        ],
      ),
    ),
  );
}
