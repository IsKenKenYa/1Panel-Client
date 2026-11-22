import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_save_button.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';

class PhpFpmSectionWidget extends StatelessWidget {
  const PhpFpmSectionWidget({
    super.key,
    required this.modeController,
    required this.maxChildrenController,
    required this.startServersController,
    required this.minSpareServersController,
    required this.maxSpareServersController,
    required this.onModeChanged,
    required this.onMaxChildrenChanged,
    required this.onStartServersChanged,
    required this.onMinSpareServersChanged,
    required this.onMaxSpareServersChanged,
    required this.status,
    required this.onSave,
    required this.isSaving,
  });

  final TextEditingController modeController;
  final TextEditingController maxChildrenController;
  final TextEditingController startServersController;
  final TextEditingController minSpareServersController;
  final TextEditingController maxSpareServersController;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onMaxChildrenChanged;
  final ValueChanged<String> onStartServersChanged;
  final ValueChanged<String> onMinSpareServersChanged;
  final ValueChanged<String> onMaxSpareServersChanged;
  final List<FpmStatusItem> status;
  final Future<void> Function() onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: AppDesignTokens.cardPadding,
      children: <Widget>[
        Text(
          l10n.runtimePhpFpmConfigTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: modeController,
          onChanged: onModeChanged,
          decoration: InputDecoration(labelText: l10n.runtimePhpFpmMode),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: maxChildrenController,
          onChanged: onMaxChildrenChanged,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.runtimePhpFpmMaxChildren),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: startServersController,
          onChanged: onStartServersChanged,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: l10n.runtimePhpFpmStartServers),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: minSpareServersController,
          onChanged: onMinSpareServersChanged,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.runtimePhpFpmMinSpareServers,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: maxSpareServersController,
          onChanged: onMaxSpareServersChanged,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.runtimePhpFpmMaxSpareServers,
          ),
        ),
        const SizedBox(height: 16),
        AppFormSaveButton(onSave: onSave, isSaving: isSaving),
        const SizedBox(height: 24),
        Text(
          '${l10n.runtimeTypePhp} ${l10n.runtimeFieldStatus}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (status.isEmpty)
          Text(l10n.runtimeEmptyDescription)
        else
          ...status.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(item.key),
              subtitle: Text('${item.value ?? '-'}'),
            ),
          ),
      ],
    );
  }
}
