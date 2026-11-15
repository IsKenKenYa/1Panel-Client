import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/files_service.dart';

class FileRemarkEditorWidget extends StatefulWidget {
  const FileRemarkEditorWidget({
    super.key,
    this.provider,
    required this.file,
  });

  /// 文件列表页传入以在保存后刷新列表；预览页等脱离 FilesProvider
  /// 作用域的入口传 null，备注读写直接走 [FilesService]。
  final FilesProvider? provider;
  final FileInfo file;

  @override
  State<FileRemarkEditorWidget> createState() => _FileRemarkEditorWidgetState();
}

class _FileRemarkEditorWidgetState extends State<FileRemarkEditorWidget> {
  final TextEditingController _remarkController = TextEditingController();
  bool _isRemarkLoading = false;
  bool _isRemarkSaving = false;
  String? _remarkError;
  FilesService? _standaloneService;

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

  Future<Map<String, String>> _loadRemarks() async {
    final provider = widget.provider;
    if (provider != null) {
      return provider.loadFileRemarks(<String>[widget.file.path]);
    }
    _standaloneService ??= FilesService();
    await _standaloneService!.getCurrentServer();
    return _standaloneService!.getFileRemarks(<String>[widget.file.path]);
  }

  Future<void> _loadRemark() async {
    setState(() {
      _isRemarkLoading = true;
      _remarkError = null;
    });

    try {
      final remarks = await _loadRemarks();
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
      final provider = widget.provider;
      if (provider != null) {
        await provider.updateFileRemark(
          widget.file.path,
          _remarkController.text,
          refreshAfterSave: false,
        );
      } else {
        _standaloneService ??= FilesService();
        await _standaloneService!.getCurrentServer();
        await _standaloneService!
            .setFileRemark(widget.file.path, _remarkController.text);
      }
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, context.l10n.commonSaveSuccess);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _remarkError = e.toString();
      });
      SnackBarUtils.showError(context, context.l10n.commonSaveFailed);
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
