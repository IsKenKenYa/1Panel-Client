import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showUploadDialog(BuildContext context, FilesProvider provider) {
  appLogger.dWithPackage('upload_dialog', 'showUploadDialog: 打开上传对话框');
  final l10n = context.l10n;

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.filesActionUpload),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.filesTargetPath}: ${provider.data.currentPath}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(l10n.filesActionUpload),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
              );

              if (result != null && result.files.isNotEmpty) {
                final filePaths = result.files
                    .where((f) => f.path != null)
                    .map((f) => f.path!)
                    .toList();

                if (filePaths.isNotEmpty) {
                  appLogger.dWithPackage('upload_dialog',
                      'showUploadDialog: 选择${filePaths.length}个文件');
                  await provider.uploadFiles(filePaths);
                  appLogger.iWithPackage(
                      'upload_dialog', 'showUploadDialog: 上传成功');
                }
              }
            } catch (e, stackTrace) {
              appLogger.eWithPackage('upload_dialog', 'showUploadDialog: 上传失败',
                  error: e, stackTrace: stackTrace);
              if (context.mounted) {
                DebugErrorDialog.show(context, l10n.filesCreateFailed, e,
                    stackTrace: stackTrace);
              }
            }
          },
          child: Text(l10n.filesActionUpload),
        ),
      ],
    ),
  );
}
