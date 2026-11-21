import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'panel_presentation.dart';

class PanelCredentialFields extends StatelessWidget {
  const PanelCredentialFields({
    super.key,
    required this.panel,
    required this.apiKeyController,
    required this.onFieldChanged,
    this.enabled = true,
    this.hasStoredApiKey = false,
    this.storedFields = const {},
  });

  final PanelPresentation panel;
  final TextEditingController apiKeyController;
  final void Function(String id, String value) onFieldChanged;
  final bool hasStoredApiKey;
  final bool enabled;
  final Set<String> storedFields;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? requiredValue(String? value) =>
        value == null || value.trim().isEmpty ? l10n.serverFormRequired : null;

    return Column(children: [
      if (panel.usesApiKey)
        TextFormField(
          enabled: enabled,
          controller: apiKeyController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.serverFormApiKey,
            hintText: hasStoredApiKey
                ? l10n.serverFormKeepCredential
                : l10n.serverFormApiKeyHint,
          ),
          validator: hasStoredApiKey ? null : requiredValue,
        ),
      for (final field in panel.fields)
        Padding(
          padding: const EdgeInsets.only(top: AppDesignTokens.spacingLg),
          child: TextFormField(
            enabled: enabled,
            key: ValueKey(field.id),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: field.label(context),
              hintText: storedFields.contains(field.id)
                  ? l10n.serverFormKeepCredential
                  : null,
            ),
            validator: field.isRequired && !storedFields.contains(field.id)
                ? requiredValue
                : null,
            onChanged: (value) => onFieldChanged(field.id, value),
          ),
        ),
    ]);
  }
}
