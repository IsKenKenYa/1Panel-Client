import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/data/models/file/file_permission.dart';

/// File batch permission modification page.
/// Mirrors frontend's file batch-role/chown operation.
class FilePermissionPage extends StatefulWidget {
  const FilePermissionPage({
    super.key,
    required this.paths,
  });

  final List<String> paths;

  @override
  State<FilePermissionPage> createState() => _FilePermissionPageState();
}

class _FilePermissionPageState extends State<FilePermissionPage> {
  final _modeController = TextEditingController(text: '0644');
  final _ownerController = TextEditingController();
  final _groupController = TextEditingController();
  bool _recursive = true;
  bool _isSaving = false;

  Future<void> _apply() async {
    setState(() => _isSaving = true);
    try {
      final api = FileV2Api(await ApiClientManager.instance.getCurrentClient());
      for (final path in widget.paths) {
        if (_modeController.text.isNotEmpty) {
          await api.changeFileMode(FileModeChange(
            path: path,
            mode: int.tryParse(_modeController.text, radix: 8) ?? 420,
            sub: _recursive,
          ));
        }
        if (_ownerController.text.isNotEmpty || _groupController.text.isNotEmpty) {
          await api.changeFileOwner(FileOwnerChange(
            path: path,
            user: _ownerController.text,
            group: _groupController.text,
            sub: _recursive,
          ));
        }
      }
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, context.l10n.filePermissionUpdated);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonUpdateFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _modeController.dispose();
    _ownerController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(context.l10n.filePermissionTitleWith(widget.paths.length))),
      body: Padding(
        padding: AppDesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _modeController,
              decoration:  InputDecoration(
                labelText: context.l10n.filePermissionMode,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerController,
              decoration:  InputDecoration(
                labelText: context.l10n.filePermissionOwner,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groupController,
              decoration:  InputDecoration(
                labelText: context.l10n.filePermissionGroup,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title:  Text(context.l10n.filePermissionRecursive),
              value: _recursive,
              onChanged: (v) => setState(() => _recursive = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _apply,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label:  Text(context.l10n.filePermissionApply),
            ),
          ],
        ),
      ),
    );
  }
}
