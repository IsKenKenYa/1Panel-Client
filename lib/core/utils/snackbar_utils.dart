import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../theme/app_design_tokens.dart';
import 'debug_error_dialog.dart';
import 'error_message_utils.dart';
import 'platform_utils.dart';

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
        foregroundColor: Colors.black,
        action: action);
  }

  static void showError(BuildContext context, String message,
      {SnackBarAction? action}) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(context,
        message: ErrorMessageUtils.localizeForContext(message, context),
        icon: Icons.error_outline,
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        action: action,
        duration: const Duration(seconds: 5));
  }

  static void showWarning(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(context,
        message: ErrorMessageUtils.localizeForContext(message, context),
        icon: Icons.warning_amber_outlined,
        backgroundColor: AppDesignTokens.warning,
        foregroundColor: Colors.black,
        action: action);
  }

  static void showInfo(BuildContext context, String message,
      {SnackBarAction? action}) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(context,
        message: ErrorMessageUtils.localizeForContext(message, context),
        icon: Icons.info_outlined,
        backgroundColor: colorScheme.inverseSurface,
        foregroundColor: colorScheme.onInverseSurface,
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final label = retryLabel ?? l10n?.commonRetry ?? '重试';
    final colorScheme = Theme.of(context).colorScheme;

    _show(context,
        message: displayMessage,
        icon: Icons.error_outline,
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        duration: const Duration(seconds: 5),
        detailsButton: details != null && kDebugMode
            ? TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: colorScheme.onError),
                onPressed: () => DebugErrorDialog.show(
                  context,
                  displayMessage,
                  details,
                  stackTrace: stackTrace,
                ),
                child: Text(l10n?.commonDetails ?? '详情'),
              )
            : null,
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
    final colorScheme = Theme.of(context).colorScheme;
    _show(context,
        message: displayMessage,
        icon: Icons.error_outline,
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: Localizations.of<AppLocalizations>(context, AppLocalizations)
                  ?.commonDetails ??
              '详情',
          onPressed: () => DebugErrorDialog.show(context, displayMessage, error,
              stackTrace: stackTrace),
        ));
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    SnackBarAction? action,
    Widget? detailsButton,
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

    final messageText = Text(message, style: TextStyle(color: foregroundColor));
    final theme = Theme.of(context);
    final actionFontSize = theme.textTheme.labelLarge?.fontSize ?? 14.0;
    final scaledActionFontSize =
        MediaQuery.textScalerOf(context).scale(actionFontSize);
    // SnackBar 的默认横排操作按钮无法按照放大后的字号换行。
    final moveCloseButton = action != null &&
        scaledActionFontSize > actionFontSize &&
        MediaQuery.sizeOf(context).width < PlatformUtils.mobileWidthBreakpoint;
    final inlineActions = [
      if (detailsButton != null) detailsButton,
      if (moveCloseButton)
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.close),
            color: foregroundColor,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(
              reason: SnackBarClosedReason.dismiss,
            ),
          ),
        ),
    ];
    // Clear before showing to prevent multiple toasts stacking
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: inlineActions.isEmpty
                  ? messageText
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [messageText, Wrap(children: inlineActions)],
                    ),
            ),
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
        showCloseIcon: !moveCloseButton,
        closeIconColor: foregroundColor,
        actionOverflowThreshold: moveCloseButton ? 0 : null,
        action: action == null
            ? null
            : SnackBarAction(
                key: action.key,
                label: action.label,
                onPressed: action.onPressed,
                textColor: action.textColor ?? foregroundColor,
                disabledTextColor: action.disabledTextColor,
                backgroundColor: action.backgroundColor,
                disabledBackgroundColor: action.disabledBackgroundColor,
              ),
        // Default 4s for info/success; callers override to 5s for errors (more read time)
        duration: effectiveDuration,
      ));
  }
}
