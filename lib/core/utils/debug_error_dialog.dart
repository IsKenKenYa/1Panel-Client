import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'snackbar_utils.dart';

class DebugErrorDialog {
  static void show(BuildContext context, String title, dynamic error,
      {StackTrace? stackTrace}) {
    // Safety guard: never show raw errors to end users even if called from release code paths
    if (!kDebugMode) return;

    final errorMessage = error.toString();
    final stackTraceStr = stackTrace?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('错误信息:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(errorMessage,
                  style: const TextStyle(color: Colors.red)),
              if (stackTraceStr.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('堆栈跟踪:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      stackTraceStr,
                      style: const TextStyle(
                          fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: '$errorMessage\n\n$stackTraceStr'));
              SnackBarUtils.showSuccess(context, '错误信息已复制到剪贴板');
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @Deprecated('Use SnackBarUtils.showErrorWithDebugDetails instead')
  static void showErrorSnackBar(BuildContext context, String message,
      {dynamic error}) {
    SnackBarUtils.showErrorWithDebugDetails(context, message, error: error);
  }
}

extension DebugErrorCatch<T> on Future<T> {
  Future<T?> catchAndShowError(BuildContext context, {String? title}) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      final message = title != null ? '$title: $e' : '操作失败: $e';
      // Debug: surface stack trace via "详情" action; Release: user-friendly message only
      if (kDebugMode) {
        SnackBarUtils.showErrorWithDebugDetails(
          context,
          message,
          error: e,
          stackTrace: stackTrace,
        );
      } else {
        SnackBarUtils.showError(context, message);
      }
      return null;
    }
  }
}
