import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

import '../../../core/utils/snackbar_utils.dart';
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
      SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
      return;
    }

    final error = provider.error ?? l10n.commonUnknownError;
    SnackBarUtils.showError(context, l10n.containerOperateFailed(error),
        action: SnackBarAction(
          label: l10n.commonRetry,
          onPressed: () => action(),
        ));
  }

  static Future<void> confirmAndRun(
    BuildContext context,
    ComposeProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonConfirm,
      message: l10n.commonDeleteConfirm,
      confirmLabel: l10n.commonConfirm,
      isDestructive: true,
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
