import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

import 'path_selector_dialog.dart';

enum FileOperation { copy, move, createFile, createDirectory }

void showFileOperationDialog(
  BuildContext context,
  FilesProvider provider,
  FileOperation operation, {
  FileInfo? file,
}) {
  final l10n = context.l10n;
  final errorLabel = switch (operation) {
    FileOperation.copy => l10n.filesCopyFailed,
    FileOperation.move => l10n.filesMoveFailed,
    _ => l10n.filesCreateFailed,
  };
  void onError(Object error, StackTrace stack) {
    appLogger.eWithPackage(
      'files.dialog',
      errorLabel,
      error: error,
      stackTrace: stack,
    );
    if (context.mounted) {
      SnackBarUtils.showErrorWithDebugDetails(
        context,
        errorLabel,
        error: error,
        stackTrace: stack,
      );
    }
  }

  if (operation == FileOperation.createFile ||
      operation == FileOperation.createDirectory) {
    final createFile = operation == FileOperation.createFile;
    showAppTextInputDialog(
      context,
      title: createFile ? l10n.filesActionNewFile : l10n.filesActionNewFolder,
      labelText: l10n.filesNameLabel,
      hintText: l10n.filesNameHint,
      confirmLabel: l10n.commonCreate,
      onSubmit: (name) async {
        try {
          await (createFile
              ? provider.createFile(name)
              : provider.createDirectory(name));
          return true;
        } catch (error, stack) {
          onError(error, stack);
          return false;
        }
      },
    );
    return;
  }

  showAdaptiveFormPanel<bool>(
    context,
    builder: (_) => _FileOperationDialog(
      operation: operation,
      provider: provider,
      file: file,
      onError: onError,
    ),
  );
}

class _FileOperationDialog extends StatefulWidget {
  const _FileOperationDialog({
    required this.operation,
    required this.provider,
    required this.file,
    required this.onError,
  });

  final FileOperation operation;
  final FilesProvider provider;
  final FileInfo? file;
  final void Function(Object, StackTrace) onError;

  @override
  State<_FileOperationDialog> createState() => _FileOperationDialogState();
}

class _FileOperationDialogState extends State<_FileOperationDialog> {
  late final TextEditingController _input;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.provider.data.currentPath);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _pickPath() async {
    final path = await showPathSelectorDialog(
      context,
      widget.provider,
      _input.text,
      context.l10n,
    );
    if (mounted && path != null) {
      _input.text = path;
    }
  }

  Future<void> _submit() async {
    final input = _input.text;
    if (_saving) {
      return;
    }
    final provider = widget.provider;
    final file = widget.file;
    final copy = widget.operation == FileOperation.copy;
    final onError = widget.onError;
    final batch = file == null;
    setState(() => _saving = true);
    if (batch) {
      Navigator.of(context).pop(true);
    }
    try {
      if (file == null) {
        await (copy
            ? provider.copySelected(input)
            : provider.moveSelected(input));
      } else {
        await (copy
            ? provider.copyFile(file.path, input)
            : provider.moveFile(file.path, input));
      }
      if (mounted && !batch) {
        Navigator.of(context).pop(true);
      }
    } catch (error, stack) {
      onError(error, stack);
      if (mounted && !batch) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final file = widget.file;
    return AppFormPanel(
      title: widget.operation == FileOperation.copy
          ? l10n.filesActionCopy
          : l10n.filesActionMove,
      isSaving: _saving,
      onConfirm: _submit,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file == null
                ? '${l10n.filesSelected}: ${widget.provider.data.selectionCount}'
                : '${l10n.filesNameLabel}: ${file.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            decoration: InputDecoration(
              labelText: l10n.filesTargetPath,
              prefixIcon: const Icon(Icons.folder_outlined),
              suffixIcon: file == null
                  ? null
                  : IconButton(
                      tooltip: l10n.filesSelectPath,
                      icon: const Icon(Icons.folder_open),
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(
                          kMinInteractiveDimension,
                        ),
                        visualDensity: VisualDensity.standard,
                      ),
                      onPressed: _saving ? null : _pickPath,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
