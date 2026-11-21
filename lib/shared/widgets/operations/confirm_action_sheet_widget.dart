import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

class ConfirmActionSheetWidget extends StatelessWidget {
  const ConfirmActionSheetWidget({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.confirmIcon = Icons.check_circle_outline,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String? confirmLabel;
  final IconData confirmIcon;
  final bool isDestructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    IconData confirmIcon = Icons.check_circle_outline,
    bool isDestructive = false,
  }) async {
    if (!AdaptiveLayoutSpec.of(context).isPhone) {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AppFormDialog(
          title: title,
          content: Text(message),
          confirmLabel: confirmLabel,
          confirmIcon: confirmIcon,
          destructive: isDestructive,
          onConfirm: () async => Navigator.of(dialogContext).pop(true),
        ),
      );
      return result ?? false;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfirmActionSheetWidget(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        confirmIcon: confirmIcon,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final confirmColor =
        isDestructive ? colorScheme.error : colorScheme.primary;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.spacingXl,
          AppDesignTokens.spacingSm,
          AppDesignTokens.spacingXl,
          AppDesignTokens.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spacingXl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: isDestructive
                      ? colorScheme.onError
                      : colorScheme.onPrimary,
                  minimumSize: const Size(0, kMinInteractiveDimension),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(confirmIcon),
                label: Text(confirmLabel ?? l10n.commonConfirm),
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, kMinInteractiveDimension),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
