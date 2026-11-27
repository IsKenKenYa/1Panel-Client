import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getLinkName(String path) {
    final name = path.split('/').last;
    return '$name.link';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormPanel(
      title: l10n.filesCreateLinkTitle,
      confirmLabel: l10n.commonCreate,
      isSaving: _isLoading,
      onConfirm: _createLink,
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
            isExpanded: true,
            decoration: InputDecoration(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
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
    );
  }

  Future<void> _createLink() async {
    if (_isLoading || _nameController.text.isEmpty) {
      return;
    }

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
        SnackBarUtils.showSuccess(context, context.l10n.commonCreateSuccess);
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
  BuildContext context,
  FilesProvider provider,
  String sourcePath,
) {
  showAdaptiveFormPanel<void>(
    context,
    builder: (context) =>
        CreateLinkDialog(provider: provider, sourcePath: sourcePath),
  );
}
