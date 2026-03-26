import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

class GroupEditSheetWidget extends StatefulWidget {
  const GroupEditSheetWidget({
    super.key,
    required this.title,
    this.initialName,
    this.canDelete = false,
    required this.onSave,
    this.onDelete,
  });

  final String title;
  final String? initialName;
  final bool canDelete;
  final Future<void> Function(String name) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<GroupEditSheetWidget> createState() => _GroupEditSheetWidgetState();
}

class _GroupEditSheetWidgetState extends State<GroupEditSheetWidget> {
  late final TextEditingController _controller;
  bool _submitting = false;
  String? _validationError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !_submitting,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.commonName,
              hintText: l10n.operationsGroupNameHint,
              errorText: _validationError,
            ),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 8),
            Text(
              _submitError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _save,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ),
          if (widget.canDelete && widget.onDelete != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _submitting ? null : _delete,
                child: Text(
                  l10n.commonDelete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _validationError = context.l10n.operationsGroupNameHint;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _validationError = null;
      _submitError = null;
    });
    try {
      await widget.onSave(name);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = error.toString();
      });
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.operationsGroupDeleteConfirmTitle,
      message: l10n.operationsGroupDeleteConfirmMessage(
        _controller.text.trim().isEmpty
            ? l10n.operationsGroupDefaultLabel
            : _controller.text.trim(),
      ),
      confirmLabel: l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed || widget.onDelete == null) {
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await widget.onDelete!();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = error.toString();
      });
    }
  }
}
