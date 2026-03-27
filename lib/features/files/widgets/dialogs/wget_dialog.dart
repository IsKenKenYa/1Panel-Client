import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/models/models.dart';

void showWgetDialog(BuildContext context, FilesProvider provider) {
  appLogger.dWithPackage('wget_dialog', 'showWgetDialog: 打开wget下载对话框');
  final l10n = context.l10n;

  final urlController = TextEditingController();
  final nameController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.filesActionWgetDownload),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: l10n.filesWgetUrl,
                hintText: l10n.filesWgetUrlHint,
                prefixIcon: const Icon(Icons.link),
              ),
              autofocus: true,
              keyboardType: TextInputType.url,
              onChanged: (value) {
                if (nameController.text.isEmpty && value.isNotEmpty) {
                  try {
                    final uri = Uri.parse(value);
                    final pathSegments = uri.pathSegments;
                    if (pathSegments.isNotEmpty) {
                      nameController.text = pathSegments.last;
                    }
                  } catch (_) {}
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.filesTargetPath}: ${provider.data.currentPath}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.filesWgetFilename,
                hintText: l10n.filesWgetFilenameHint,
                prefixIcon: const Icon(Icons.insert_drive_file_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            if (urlController.text.isEmpty || nameController.text.isEmpty)
              return;

            final url = urlController.text.trim();
            final name = nameController.text.trim();

            appLogger.dWithPackage(
                'wget_dialog', 'showWgetDialog: url=$url, name=$name');
            Navigator.pop(dialogContext);

            try {
              await provider.wgetDownload(
                url: url,
                name: name,
              );

              if (context.mounted) {
                final status = provider.data.wgetStatus;
                if (status != null &&
                    status.state == WgetDownloadState.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(status.message ??
                                  l10n.filesWgetSuccess(
                                      status.filePath ?? ''))),
                        ],
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      action: SnackBarAction(
                        label: l10n.commonConfirm,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {},
                      ),
                    ),
                  );
                } else if (status != null &&
                    status.state == WgetDownloadState.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Theme.of(context).colorScheme.onError),
                          const SizedBox(width: 8),
                          Expanded(
                              child:
                                  Text(status.message ?? l10n.filesWgetFailed)),
                        ],
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      action: SnackBarAction(
                        label: l10n.commonConfirm,
                        textColor: Theme.of(context).colorScheme.onError,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: status.message ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.commonCopied),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              }
              appLogger.iWithPackage('wget_dialog', 'showWgetDialog: wget下载完成');
            } catch (e, stackTrace) {
              appLogger.eWithPackage('wget_dialog', 'showWgetDialog: wget下载失败',
                  error: e, stackTrace: stackTrace);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.onError),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.toString())),
                      ],
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    action: SnackBarAction(
                      label: l10n.commonConfirm,
                      textColor: Theme.of(context).colorScheme.onError,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: e.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.commonCopied),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            }
          },
          child: Text(l10n.filesWgetDownload),
        ),
      ],
    ),
  );
}
