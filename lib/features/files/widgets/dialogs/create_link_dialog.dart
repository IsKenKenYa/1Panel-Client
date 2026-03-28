import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

class CreateLinkDialog extends StatefulWidget {
  final FilesProvider provider;
  final String sourcePath;

  const CreateLinkDialog({
    super.key,
    required this.provider,
    required this.sourcePath,
  });

  @override
  State<CreateLinkDialog> createState() => _CreateLinkDialogState();
}

class _CreateLinkDialogState extends State<CreateLinkDialog> {
  final _nameController = TextEditingController();
  String _linkType = 'symbolic'; // symbolic or hard
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = _getLinkName(widget.sourcePath);
  }

  String _getLinkName(String path) {
    final name = path.split('/').last;
    return '$name.link';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.filesCreateLinkTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.filesLinkNameLabel,
              errorText: _error,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _linkType,
            decoration: InputDecoration(
              labelText: l10n.filesLinkTypeLabel,
            ),
            items: [
              DropdownMenuItem(
                value: 'symbolic',
                child: Text(l10n.filesLinkTypeSymbolic),
              ),
              DropdownMenuItem(
                value: 'hard',
                child: Text(l10n.filesLinkTypeHard),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _linkType = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createLink,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.commonCreate),
        ),
      ],
    );
  }

  Future<void> _createLink() async {
    if (_nameController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final linkPath =
          '${widget.provider.data.currentPath}/${_nameController.text}';
      await widget.provider.createFileLink(
        sourcePath: widget.sourcePath,
        linkPath: linkPath,
        linkType: _linkType,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.commonCreateSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
}

void showCreateLinkDialog(
    BuildContext context, FilesProvider provider, String sourcePath) {
  showDialog(
    context: context,
    builder: (context) => CreateLinkDialog(
      provider: provider,
      sourcePath: sourcePath,
    ),
  );
}
