import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

class WebsiteSslUploadDialog extends StatefulWidget {
  const WebsiteSslUploadDialog({
    super.key,
    required this.onUpload,
    this.includeDescription = false,
  });

  final Future<void> Function(WebsiteSSLUpload request) onUpload;
  final bool includeDescription;

  @override
  State<WebsiteSslUploadDialog> createState() => _WebsiteSslUploadDialogState();
}

class _WebsiteSslUploadDialogState extends State<WebsiteSslUploadDialog> {
  final _certificate = TextEditingController();
  final _privateKey = TextEditingController();
  final _certificatePath = TextEditingController();
  final _privateKeyPath = TextEditingController();
  final _description = TextEditingController();
  String _type = 'paste';
  bool _saving = false;

  @override
  void dispose() {
    _certificate.dispose();
    _privateKey.dispose();
    _certificatePath.dispose();
    _privateKeyPath.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    if (_saving) return;
    final paste = _type == 'paste';
    final description = _description.text.trim();
    final request = WebsiteSSLUpload(
      type: _type,
      certificate: paste ? _certificate.text.trim() : null,
      privateKey: paste ? _privateKey.text.trim() : null,
      certificatePath: paste ? null : _certificatePath.text.trim(),
      privateKeyPath: paste ? null : _privateKeyPath.text.trim(),
      description: description.isEmpty ? null : description,
    );
    setState(() => _saving = true);
    try {
      await widget.onUpload(request);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackBarUtils.showError(context, context.l10n.commonOperationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paste = _type == 'paste';
    return AppFormDialog(
      title: l10n.websitesSslUploadAction,
      isSaving: _saving,
      confirmLabel: l10n.commonUpload,
      onConfirm: _upload,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(
              labelText: l10n.websitesSslUploadTypeLabel,
            ),
            items: [
              DropdownMenuItem(
                value: 'paste',
                child: Text(l10n.websitesSslUploadTypePaste),
              ),
              DropdownMenuItem(
                value: 'local',
                child: Text(l10n.websitesSslUploadTypeLocal),
              ),
            ],
            onChanged: _saving ? null : (value) => setState(() => _type = value!),
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: !_saving,
            controller: paste ? _certificate : _certificatePath,
            maxLines: paste ? 3 : 1,
            decoration: InputDecoration(
              labelText: paste
                  ? l10n.websitesSslCertificateLabel
                  : l10n.websitesSslCertificatePathLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: !_saving,
            controller: paste ? _privateKey : _privateKeyPath,
            maxLines: paste ? 3 : 1,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: paste
                  ? l10n.websitesSslPrivateKeyLabel
                  : l10n.websitesSslPrivateKeyPathLabel,
            ),
          ),
          if (widget.includeDescription) ...[
            const SizedBox(height: 12),
            TextField(
              enabled: !_saving,
              controller: _description,
              decoration: InputDecoration(labelText: l10n.websitesSslDescriptionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
