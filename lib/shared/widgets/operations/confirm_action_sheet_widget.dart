import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

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
    final result = await showModalBottomSheet<bool>(
      context: context,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: isDestructive
                    ? colorScheme.onError
                    : colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              icon: Icon(confirmIcon),
              label: Text(confirmLabel ?? l10n.commonConfirm),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
          ),
        ],
      ),
    );
  }
}
