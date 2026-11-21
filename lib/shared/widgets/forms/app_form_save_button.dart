import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class AppFormSaveButton extends StatelessWidget {
  const AppFormSaveButton({
    super.key,
    required this.onSave,
    required this.isSaving,
    this.label,
  });

  final VoidCallback? onSave;
  final bool isSaving;
  final String? label;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: isSaving ? null : onSave,
        child: isSaving
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: context.l10n.commonLoading,
                ),
              )
            : Text(label ?? context.l10n.commonSave),
      );
}

class AppFormSaveBar extends StatelessWidget {
  const AppFormSaveBar({
    super.key,
    required this.onSave,
    required this.isSaving,
    this.label,
    this.buttonKey,
  });

  final VoidCallback? onSave;
  final bool isSaving;
  final String? label;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth,
          ),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppDesignTokens.spacingLg,
              AppDesignTokens.spacingSm,
              AppDesignTokens.spacingLg,
              AppDesignTokens.spacingLg,
            ),
            child: SizedBox(
              width: double.infinity,
              child: AppFormSaveButton(
                key: buttonKey,
                onSave: onSave,
                isSaving: isSaving,
                label: label,
              ),
            ),
          ),
        ),
      );
}
