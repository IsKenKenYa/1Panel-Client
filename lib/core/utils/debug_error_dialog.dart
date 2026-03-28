import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DebugErrorDialog {
  static void show(BuildContext context, String title, dynamic error,
      {StackTrace? stackTrace}) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('错误信息已复制到剪贴板')),
              );
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

  static void showErrorSnackBar(BuildContext context, String message,
      {dynamic error}) {
    if (!kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        action: SnackBarAction(
          label: '详情',
          onPressed: () => show(context, message, error),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

extension DebugErrorCatch<T> on Future<T> {
  Future<T?> catchAndShowError(BuildContext context, {String? title}) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        DebugErrorDialog.show(context, title ?? '操作失败', e,
            stackTrace: stackTrace);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(title != null ? '$title: $e' : '操作失败: $e')),
        );
      }
      return null;
    }
  }
}
