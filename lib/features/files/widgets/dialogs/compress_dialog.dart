import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showCompressDialog(
  BuildContext context,
  FilesProvider provider,
  List<String> files,
  AppLocalizations l10n,
) {
  appLogger.dWithPackage('compress_dialog', 'showCompressDialog: 打开压缩对话框, files=$files');
  final nameController = TextEditingController();
  String type = 'zip';
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.filesActionCompress),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.filesNameLabel,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: InputDecoration(labelText: l10n.filesCompressType),
              items: const [
                DropdownMenuItem(value: 'zip', child: Text('ZIP')),
                DropdownMenuItem(value: 'tar', child: Text('TAR')),
                DropdownMenuItem(value: 'tar.gz', child: Text('TAR.GZ')),
                DropdownMenuItem(value: '7z', child: Text('7Z')),
              ],
              onChanged: (value) {
                setDialogState(() => type = value ?? 'zip');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final name = nameController.text;
              appLogger.dWithPackage('compress_dialog', 'showCompressDialog: 用户输入名称=$name, type=$type');
              Navigator.pop(dialogContext);
              try {
                await provider.compressFiles(files, provider.data.currentPath, name, type);
                appLogger.iWithPackage('compress_dialog', 'showCompressDialog: 压缩成功');
              } catch (e, stackTrace) {
                appLogger.eWithPackage('compress_dialog', 'showCompressDialog: 压缩失败', error: e, stackTrace: stackTrace);
                if (context.mounted) {
                  DebugErrorDialog.show(context, l10n.filesCompressFailed, e, stackTrace: stackTrace);
                }
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    ),
  );
}
