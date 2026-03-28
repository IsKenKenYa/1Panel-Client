import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';

class ComposeCardActions {
  static Future<void> runAction(
    BuildContext context,
    ComposeProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final success = await action();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerOperateSuccess)),
      );
      return;
    }

    final error = provider.error ?? l10n.commonUnknownError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.containerOperateFailed(error)),
        action: SnackBarAction(
          label: l10n.commonRetry,
          onPressed: () {
            action();
          },
        ),
      ),
    );
  }

  static Future<void> confirmAndRun(
    BuildContext context,
    ComposeProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonConfirm),
        content: Text(l10n.commonDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await runAction(context, provider, action);
    }
  }

  static Color statusColor(String? status, ColorScheme colorScheme) {
    final value = (status ?? '').toLowerCase();
    if (value.contains('running')) return colorScheme.primary;
    if (value.contains('exited') || value.contains('stopped')) {
      return colorScheme.error;
    }
    return colorScheme.outline;
  }
}
