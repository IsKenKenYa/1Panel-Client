import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showRenameDialog(
  BuildContext context,
  FilesProvider provider,
  FileInfo file,
  AppLocalizations l10n,
) {
  appLogger.dWithPackage('rename_dialog', 'showRenameDialog: 打开重命名对话框, file=${file.path}');
  final controller = TextEditingController(text: file.name);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.filesActionRename),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: l10n.filesNameLabel,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            if (controller.text.isEmpty || controller.text == file.name) return;
            appLogger.dWithPackage('rename_dialog', 'showRenameDialog: 用户输入新名称=${controller.text}');
            Navigator.pop(dialogContext);
            try {
              await provider.renameFile(file.path, controller.text);
              appLogger.iWithPackage('rename_dialog', 'showRenameDialog: 重命名成功');
            } catch (e, stackTrace) {
              appLogger.eWithPackage('rename_dialog', 'showRenameDialog: 重命名失败', error: e, stackTrace: stackTrace);
              if (context.mounted) {
                DebugErrorDialog.show(context, l10n.filesRenameFailed, e, stackTrace: stackTrace);
              }
            }
          },
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );
}
