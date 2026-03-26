import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';

class SshCertFormSheetWidget extends StatefulWidget {
  const SshCertFormSheetWidget({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialValue,
  });

  final String title;
  final SshCertOperate? initialValue;
  final Future<bool> Function(SshCertOperate request) onSubmit;

  @override
  State<SshCertFormSheetWidget> createState() => _SshCertFormSheetWidgetState();
}

class _SshCertFormSheetWidgetState extends State<SshCertFormSheetWidget> {
  late final TextEditingController _nameController;
  late final TextEditingController _passPhraseController;
  late final TextEditingController _publicKeyController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _descriptionController;
  late String _mode;
  late String _encryptionMode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _passPhraseController = TextEditingController(text: initial?.passPhrase ?? '');
    _publicKeyController = TextEditingController(text: initial?.publicKey ?? '');
    _privateKeyController = TextEditingController(text: initial?.privateKey ?? '');
    _descriptionController = TextEditingController(text: initial?.description ?? '');
    _mode = initial == null ? 'generate' : 'input'; _encryptionMode = initial?.encryptionMode ?? 'ed25519';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passPhraseController.dispose();
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.commonName),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _encryptionMode,
                decoration: InputDecoration(labelText: l10n.sshCertEncryptionModeLabel),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'ed25519', child: Text('ED25519')),
                  DropdownMenuItem(value: 'ecdsa', child: Text('ECDSA')),
                  DropdownMenuItem(value: 'rsa', child: Text('RSA')),
                  DropdownMenuItem(value: 'dsa', child: Text('DSA')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _encryptionMode = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passPhraseController,
                decoration: InputDecoration(labelText: l10n.sshCertPassPhraseLabel),
              ),
              if (widget.initialValue == null) ...<Widget>[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration: InputDecoration(labelText: l10n.sshCertModeLabel),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'generate',
                      child: Text(l10n.sshCertModeGenerate),
                    ),
                    DropdownMenuItem(
                      value: 'input',
                      child: Text(l10n.sshCertModeInput),
                    ),
                    DropdownMenuItem(
                      value: 'import',
                      child: Text(l10n.sshCertModeImport),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _mode = value);
                  },
                ),
              ],
              if (_mode != 'generate') ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  controller: _publicKeyController,
                  minLines: 4,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: InputDecoration(labelText: l10n.sshCertPublicKeyLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _privateKeyController,
                  minLines: 4,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: InputDecoration(labelText: l10n.sshCertPrivateKeyLabel),
                ),
              ],
              if (_mode == 'import') ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: _pickPublicKey,
                      child: Text(l10n.commonUpload),
                    ),
                    OutlinedButton(
                      onPressed: _pickPrivateKey,
                      child: Text(l10n.commonImport),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.commonDescription),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: Text(l10n.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPublicKey() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result?.files.single.bytes case final bytes?) {
      _publicKeyController.text = utf8.decode(bytes);
    }
  }

  Future<void> _pickPrivateKey() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result?.files.single.bytes case final bytes?) {
      _privateKeyController.text = utf8.decode(bytes);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    if (_mode != 'generate' &&
        (_publicKeyController.text.trim().isEmpty ||
            _privateKeyController.text.trim().isEmpty)) {
      return;
    }
    setState(() => _isSaving = true);
    final success = await widget.onSubmit(
      SshCertOperate(
        id: widget.initialValue?.id ?? 0,
        name: _nameController.text.trim(),
        mode: _mode,
        encryptionMode: _encryptionMode,
        passPhrase: _passPhraseController.text.trim(),
        publicKey: _publicKeyController.text.trim(),
        privateKey: _privateKeyController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
    if (!mounted) return; setState(() => _isSaving = false);
    if (success) Navigator.of(context).pop();
  }
}
