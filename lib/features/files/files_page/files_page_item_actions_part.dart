part of 'package:onepanel_client/features/files/files_page.dart';

extension _FilesViewItemOpeners on _FilesViewState {
  void _handleFileAction(
    BuildContext context,
    FilesProvider provider,
    FileInfo file,
    String action,
    AppLocalizations l10n,
  ) {
    switch (action) {
      case 'open':
        if (file.isDir) provider.navigateTo(file.path);
        break;
      case 'download':
        _startDownload(context, provider, file, l10n);
        break;
      case 'convert':
        _showConvertDialog(context, provider, file, l10n);
        break;
      case 'preview':
        _openFilePreview(context, file);
        break;
      case 'edit':
        _openFileEditor(context, file);
        break;
      case 'favorite':
        _toggleFavorite(context, provider, file, l10n);
        break;
      case 'rename':
        showRenameDialog(context, provider, file, l10n);
        break;
      case 'copy':
        showCopyDialog(context, provider, file, l10n);
        break;
      case 'move':
        showMoveDialog(context, provider, file, l10n);
        break;
      case 'extract':
        showExtractDialog(context, provider, file, l10n);
        break;
      case 'compress':
        showCompressDialog(context, provider, [file.path], l10n);
        break;
      case 'permission':
        showPermissionDialog(context, provider, file, l10n);
        break;
      case 'properties':
        showFilePropertiesDialog(context, provider, file);
        break;
      case 'link':
        showCreateLinkDialog(context, provider, file.path);
        break;
      case 'delete':
        provider.toggleSelection(file.path);
        showDeleteConfirmDialog(context, provider, l10n);
        break;
    }
  }

  void _openFilePreview(BuildContext context, FileInfo file) {
    appLogger.dWithPackage('files_page', '_openFilePreview: 打开预览 ${file.path}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilePreviewPage(
          filePath: file.path,
          fileName: file.name,
          fileSize: file.size,
        ),
      ),
    );
  }

  void _openFileEditor(BuildContext context, FileInfo file) {
    appLogger.dWithPackage('files_page', '_openFileEditor: 打开编辑器 ${file.path}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileEditorPage(
          filePath: file.path,
          fileName: file.name,
        ),
      ),
    );
  }

  Future<void> _showConvertDialog(
    BuildContext context,
    FilesProvider provider,
    FileInfo file,
    AppLocalizations l10n,
  ) async {
    final outputPathController = TextEditingController(
      text: provider.data.currentPath,
    );
    final outputFormatController = TextEditingController();
    var backupSource = true;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(l10n.filesEncodingConvert),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: outputPathController,
                      decoration: InputDecoration(labelText: l10n.filesPath),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: outputFormatController,
                      decoration:
                          InputDecoration(labelText: l10n.filesEncodingTo),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: backupSource,
                      onChanged: (value) {
                        setDialogState(() {
                          backupSource = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.filesEncodingBackup),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.commonConfirm),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || !context.mounted) {
        return;
      }

      final outputFormat = outputFormatController.text.trim();
      if (outputFormat.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonEmpty)),
        );
        return;
      }

      try {
        await provider.convertFile(
          file,
          outputFormat: outputFormat,
          outputPath: outputPathController.text.trim(),
          deleteSource: !backupSource,
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesEncodingConvertDone)),
        );
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filesEncodingConvertFailed)),
        );
      }
    } finally {
      outputPathController.dispose();
      outputFormatController.dispose();
    }
  }
}
