import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class PhpBasicConfigSectionWidget extends StatelessWidget {
  const PhpBasicConfigSectionWidget({
    super.key,
    required this.uploadMaxSizeController,
    required this.maxExecutionTimeController,
    required this.disableFunctionsController,
    required this.onUploadMaxSizeChanged,
    required this.onMaxExecutionTimeChanged,
    required this.onDisableFunctionsChanged,
    required this.onSave,
    required this.isSaving,
  });

  final TextEditingController uploadMaxSizeController;
  final TextEditingController maxExecutionTimeController;
  final TextEditingController disableFunctionsController;
  final ValueChanged<String> onUploadMaxSizeChanged;
  final ValueChanged<String> onMaxExecutionTimeChanged;
  final ValueChanged<String> onDisableFunctionsChanged;
  final Future<void> Function() onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TextFormField(
          controller: uploadMaxSizeController,
          onChanged: onUploadMaxSizeChanged,
          decoration: InputDecoration(
            labelText: l10n.runtimeFieldSource,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: maxExecutionTimeController,
          onChanged: onMaxExecutionTimeChanged,
          decoration: InputDecoration(
            labelText: l10n.runtimeFieldExecScript,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: disableFunctionsController,
          onChanged: onDisableFunctionsChanged,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.runtimeFieldParams,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}
