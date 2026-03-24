import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showCreateDirectoryDialog(BuildContext context, FilesProvider provider) {
  appLogger.dWithPackage('create_directory_dialog', 'showCreateDirectoryDialog: 打开创建文件夹对话框');
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.filesActionNewFolder),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: context.l10n.filesNameLabel,
          hintText: context.l10n.filesNameHint,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            if (controller.text.isEmpty) return;
            appLogger.dWithPackage('create_directory_dialog', 'showCreateDirectoryDialog: 用户输入名称=${controller.text}');
            Navigator.pop(dialogContext);
            try {
              await provider.createDirectory(controller.text);
              appLogger.iWithPackage('create_directory_dialog', 'showCreateDirectoryDialog: 创建成功');
            } catch (e, stackTrace) {
              appLogger.eWithPackage('create_directory_dialog', 'showCreateDirectoryDialog: 创建失败', error: e, stackTrace: stackTrace);
              if (context.mounted) {
                DebugErrorDialog.show(context, context.l10n.filesCreateFailed, e, stackTrace: stackTrace);
              }
            }
          },
          child: Text(context.l10n.commonCreate),
        ),
      ],
    ),
  );
}
