import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/module_search_field.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

void showSearchDialog(BuildContext context) {
  final controller = TextEditingController();
  showAppFormDialog(
    context,
    title: context.l10n.filesActionSearch,
    confirmLabel: context.l10n.commonSearch,
    content: ModuleSearchField(
      controller: controller,
      labelText: context.l10n.filesSearchHint,
      suffixIcon: IconButton(
        icon: const Icon(Icons.clear_outlined),
        tooltip: context.l10n.filesSearchClear,
        onPressed: () {
          controller.clear();
          context.read<FilesProvider>().setSearchQuery(null);
        },
      ),
      autofocus: true,
    ),
    onConfirm: () async {
      context.read<FilesProvider>().setSearchQuery(controller.text);
      await context.read<FilesProvider>().loadFiles();
    },
  );
}
