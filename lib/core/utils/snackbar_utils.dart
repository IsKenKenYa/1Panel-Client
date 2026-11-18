import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../theme/app_design_tokens.dart';
import 'debug_error_dialog.dart';
import 'error_message_utils.dart';

class SnackBarUtils {
  const SnackBarUtils._();

  /// 内容级去重：记录当前展示中的 SnackBar 内容与展示截止时间。
  ///
  /// 背景（真机走查 P2-4）：多个 keep-alive 页面在轮询失败时会对同一错误
  /// 反复 clearSnackBars + showSnackBar，导致计时不断重置、错误 Toast 跨页
  /// "永驻"数十分钟。同内容在展示期内重复触发时直接跳过，保持原有计时。
  static String? _currentContentKey;
  static DateTime _currentContentExpiresAt =
      DateTime.fromMillisecondsSinceEpoch(0);

  static void showSuccess(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(context,
        message: message,
        icon: Icons.check_circle_outline,
        backgroundColor: AppDesignTokens.success,
        action: action);
  }

  static void showError(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(context,
        message: ErrorMessageUtils.localizeForContext(message, context),
        icon: Icons.error_outline,
        backgroundColor: Theme.of(context).colorScheme.error,
        action: action,
        duration: const Duration(seconds: 5));
  }

  static void showWarning(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(context,
        message: ErrorMessageUtils.localizeForContext(message, context),
        icon: Icons.warning_amber_outlined,
        backgroundColor: AppDesignTokens.warning,
        action: action);
  }

  static void showInfo(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(context,
        message: ErrorMessageUtils.localizeForContext(message, context),
        icon: Icons.info_outlined,
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        action: action);
  }

  static void showErrorWithRetry(
    BuildContext context,
    String message,
    VoidCallback onRetry, {
    Object? details,
    StackTrace? stackTrace,
    String? retryLabel,
  }) {
    final displayMessage =
        ErrorMessageUtils.localizeForContext(message, context);
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    final label = retryLabel ?? l10n?.commonRetry ?? '重试';

    if (details != null && kDebugMode) {
      _show(context,
          message: displayMessage,
          icon: Icons.error_outline,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
          trailing: TextButton(
            onPressed: () => DebugErrorDialog.show(
              context,
              displayMessage,
              details,
              stackTrace: stackTrace,
            ),
            child: Text(
                Localizations.of<AppLocalizations>(context, AppLocalizations)
                        ?.commonDetails ??
                    '详情',
                style: const TextStyle(color: Colors.white)),
          ),
          action: SnackBarAction(label: label, onPressed: onRetry));
      return;
    }

    _show(context,
        message: displayMessage,
        icon: Icons.error_outline,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: label, onPressed: onRetry));
  }

  static void showErrorWithDebugDetails(
    BuildContext context,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final displayMessage =
        ErrorMessageUtils.localizeForContext(message, context);
    if (!kDebugMode) {
      showError(context, displayMessage);
      return;
    }
    _show(context,
        message: displayMessage,
        icon: Icons.error_outline,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: Localizations.of<AppLocalizations>(
                      context, AppLocalizations)
                  ?.commonDetails ??
              '详情',
          onPressed: () =>
              DebugErrorDialog.show(context, displayMessage, error,
                  stackTrace: stackTrace),
        ));
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    SnackBarAction? action,
    Widget? trailing,
    Duration? duration,
  }) {
    final effectiveDuration = duration ?? const Duration(seconds: 4);

    // 同内容 Toast 仍在展示期内时跳过，避免重置计时（内容级去重）。
    final now = DateTime.now();
    final contentKey = '$icon|$message';
    if (_currentContentKey == contentKey &&
        now.isBefore(_currentContentExpiresAt)) {
      return;
    }
    _currentContentKey = contentKey;
    _currentContentExpiresAt = now.add(effectiveDuration);

    // Clear before showing to prevent multiple toasts stacking
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            if (trailing != null) trailing,
          ],
        ),
        backgroundColor: backgroundColor,
        // Floating keeps the toast above bottom nav / FAB; margin-bottom 16 matches FAB spacing
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // Explicit close button so users can dismiss long-duration error toasts immediately
        showCloseIcon: true,
        action: action,
        // Default 4s for info/success; callers override to 5s for errors (more read time)
        duration: effectiveDuration,
      ));
  }
}
