import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../i18n/l10n_x.dart';
import '../network/network_exceptions.dart';

/// Centralised error-to-user-message translation.
///
/// This is the seam between typed infrastructure exceptions (DioException,
/// NetworkException subtypes) and user-facing display text. Providers should
/// call [userFacingMessage] instead of `e.toString()` so typed error
/// information is preserved and translated consistently (architecture review
/// candidate ⑭ -- the "e.toString() flattening" root cause).
class ErrorMessageUtils {
  const ErrorMessageUtils._();

  /// Translates [error] to a user-facing message string.
  ///
  /// When [error] is a [DioException] or [NetworkException] subtype, a
  /// type-appropriate default message is returned (without hard-coded UI
  /// text -- callers can still l10n-override if needed). For other errors,
  /// the [toString] output is cleaned of common prefix noise.
  static String normalize(Object error) {
    // DioException: translate by type so the UI never sees raw Dio internals.
    if (error is DioException) {
      return _normalizeDioException(error);
    }

    // NetworkException subtypes: use the message field directly (it already
    // carries a human-readable summary from dio_client._convertException).
    if (error is NetworkException) {
      return error.message.trim();
    }

    final message = error.toString().trim();
    if (message.isEmpty) {
      return message;
    }

    const prefixes = <String>[
      'Exception: ',
      'NetworkException: ',
    ];
    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        return message.substring(prefix.length).trim();
      }
    }
    return message;
  }

  /// Returns a user-facing message capped at [maxLength] characters.
  static String userFacingMessage(
    Object error, {
    int maxLength = 120,
  }) {
    final normalized = normalize(error);
    if (normalized.isEmpty) {
      return normalized;
    }
    return truncateForToast(normalized, maxLength: maxLength);
  }

  /// 展示层文案本地化：把错误事实（含客户端拼接前缀与上游原始描述）翻译为
  /// 当前语言的用户文案。
  ///
  /// 分层约定：Provider/Repository 记录的错误保持事实原样（含上游 message），
  /// 展示层（SnackBarUtils / ModuleErrorStateWidget 等持有 BuildContext 的
  /// 位置）在渲染前经本方法翻译。映射按稳定性递减：客户端前缀状态码族 →
  /// 已知上游稳定文案 → 剥离技术前缀后回退原文。
  static String localizeMessage(String message, AppLocalizations l10n) {
    var core = message.trim();
    if (core.isEmpty) {
      return core;
    }

    // 客户端拼接的技术前缀 → 状态码族文案（状态码编号不进用户文案）。
    if (core.startsWith('服务器错误(')) {
      return truncateForToast(l10n.commonErrorServer);
    }
    if (core.startsWith('HTTP错误(')) {
      return truncateForToast(l10n.commonErrorBadRequest);
    }
    if (core.startsWith('网络连接失败') ||
        _looksLikeConnectionFailure(core)) {
      return truncateForToast(l10n.commonErrorNetwork);
    }
    if (core.startsWith('请求失败: ')) {
      core = core.substring('请求失败: '.length).trim();
    }
    if (core.startsWith('服务错误: ')) {
      core = core.substring('服务错误: '.length).trim();
    }

    return truncateForToast(_translateKnownUpstream(core, l10n));
  }

  /// 宿主尚未装载 AppLocalizations（测试或极早期启动）时回退原文截断，
  /// 错误展示组件自身绝不能成为崩溃源。
  static String localizeForContext(String message, BuildContext context) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (l10n == null) {
      return truncateForToast(message);
    }
    return localizeMessage(message, l10n);
  }

  static bool _looksLikeConnectionFailure(String message) {    const markers = <String>[
      'Connection timed out',
      'Connection refused',
      'Connection reset',
      'Network is unreachable',
      'timed out',
      'Failed host lookup',
    ];
    return markers.any(message.contains);
  }

  /// 上游固定稳定文案 → i18n。仅收录上游源码中确定不变的描述，
  /// 不做模糊猜测；未收录的回退原文（日志中保留完整事实）。
  static String _translateKnownUpstream(String message, AppLocalizations l10n) {
    final known = <String, String Function(AppLocalizations)>{
      'GPU history requires a device': (l10n) => l10n.monitorGpuUnavailable,
      '此文件不支持预览': (l10n) => l10n.filePreviewUnsupported,
      '此文件不支持在线编辑': (l10n) => l10n.filePreviewUnsupported,
    };
    final direct = known[message];
    if (direct != null) {
      return direct(l10n);
    }
    for (final entry in known.entries) {
      if (message.contains(entry.key)) {
        return entry.value(l10n);
      }
    }
    return message;
  }

  /// 120 chars fits a single-line SnackBar on most phones without wrapping.
  static String truncateForToast(
    String message, {
    int maxLength = 120,
  }) {
    final trimmed = message.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    // Use ellipsis character (…) rather than "..." to save 2 chars and match typographic norms
    return '${trimmed.substring(0, maxLength - 1)}…';
  }

  static String _normalizeDioException(DioException error) {
    // Extract the server-provided message when available; otherwise fall
    // back to a type-based summary. This prevents the UI from seeing raw
    // "DioException [bad response]: ..." strings.
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final serverMessage = responseData['message'];
      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        return serverMessage.trim();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out';
      case DioExceptionType.connectionError:
        return 'Network connection failed';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) return 'Unauthorized';
        if (statusCode == 403) return 'Forbidden';
        if (statusCode == 404) return 'Not found';
        if (statusCode != null && statusCode >= 500) {
          return 'Server error ($statusCode)';
        }
        return 'Request failed ($statusCode)';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.badCertificate:
        return 'Certificate error';
      case DioExceptionType.unknown:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unknown network error';
    }
  }
}

