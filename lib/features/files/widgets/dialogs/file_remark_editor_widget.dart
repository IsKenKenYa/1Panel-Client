import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

class FileRemarkEditorWidget extends StatefulWidget {
  const FileRemarkEditorWidget({
    super.key,
    required this.provider,
    required this.file,
  });

  final FilesProvider provider;
  final FileInfo file;

  @override
  State<FileRemarkEditorWidget> createState() => _FileRemarkEditorWidgetState();
}

class _FileRemarkEditorWidgetState extends State<FileRemarkEditorWidget> {
  final TextEditingController _remarkController = TextEditingController();
  bool _isRemarkLoading = false;
  bool _isRemarkSaving = false;
  String? _remarkError;

  @override
  void initState() {
    super.initState();
    _loadRemark();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadRemark() async {
    setState(() {
      _isRemarkLoading = true;
      _remarkError = null;
    });

    try {
      final remarks =
          await widget.provider.loadFileRemarks(<String>[widget.file.path]);
      _remarkController.text =
          remarks[widget.file.path] ?? widget.file.remark ?? '';
    } catch (e) {
      _remarkError = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isRemarkLoading = false;
        });
      }
    }
  }

  Future<void> _saveRemark() async {
    setState(() {
      _isRemarkSaving = true;
      _remarkError = null;
    });

    try {
      await widget.provider.updateFileRemark(
        widget.file.path,
        _remarkController.text,
        refreshAfterSave: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonSaveSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _remarkError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonSaveFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRemarkSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.runtimeFieldRemark,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (_isRemarkLoading)
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextField(
            controller: _remarkController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.runtimeFieldRemark,
            ),
          ),
        if (_remarkError != null) ...[
          const SizedBox(height: 8),
          Text(
            _remarkError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _isRemarkSaving ? null : _saveRemark,
            child: _isRemarkSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonSave),
          ),
        ),
      ],
    );
  }
}
