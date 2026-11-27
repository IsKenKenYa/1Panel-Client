import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

/// 统一对话框表单（M3 Expressive / MDUI3 轨道标准件）。
///
/// 全仓所有「AlertDialog 内表单」必须复用本组件（或
/// [showAppFormDialog] helper），统一：
/// - actions 行：取消 TextButton + 确认 FilledButton；
/// - 防重复提交：[isSaving] 为 true 时确认按钮禁用并内嵌 spinner；
/// - 圆角/背景：由全局 dialogTheme 承担（radiusXl=28）。
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.isSaving = false,
    this.confirmLabel,
    this.confirmIcon,
    this.confirmButtonKey,
    this.destructive = false,
  });

  final String title;
  final Widget content;
  final Future<void> Function() onConfirm;
  final bool isSaving;
  final String? confirmLabel;
  final IconData? confirmIcon;
  final Key? confirmButtonKey;

  /// 破坏性操作（删除等）：确认按钮使用 error 色（M3 语义）。
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope<Object?>(
      canPop: !isSaving,
      child: AlertDialog(
        scrollable: true,
        title: Text(title),
        content: content,
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.icon(
            key: confirmButtonKey,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            onPressed: isSaving ? null : onConfirm,
            icon: isSaving || confirmIcon == null ? null : Icon(confirmIcon),
            label: isSaving
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: l10n.commonLoading,
                    ),
                  )
                : Text(confirmLabel ?? l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

/// [AppFormDialog] 的便捷 helper：确认后 pop(true)，取消 pop(false)。
///
/// [onConfirm] 执行期间自动进入防重态（确认/取消按钮禁用 + spinner），
/// 完成后自动 pop(true)；抛异常时保持打开（由调用方 Snackbar 反馈）。
Future<bool> showAppFormDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required Future<void> Function() onConfirm,
  String? confirmLabel,
  Key? confirmButtonKey,
  bool destructive = false,
}) async {
  var saving = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AppFormDialog(
          title: title,
          content: content,
          isSaving: saving,
          confirmLabel: confirmLabel,
          confirmButtonKey: confirmButtonKey,
          destructive: destructive,
          onConfirm: () async {
            if (saving) return;
            setDialogState(() => saving = true);
            try {
              await onConfirm();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            } catch (_) {
              // 保持对话框打开并复位防重态；错误反馈由调用方负责
              // （Snackbar 等）。吞掉异常避免按钮闭包成为未捕获 zone 错误。
              if (dialogContext.mounted) setDialogState(() => saving = false);
            }
          },
        );
      },
    ),
  );
  return result ?? false;
}

/// 单输入字段对话框，内部管理并释放 [TextEditingController]。
///
/// 传 [onSubmit] 时在弹窗内执行提交并显示防重加载状态，返回 `true` 后关闭；
/// 不传 [onSubmit] 时直接返回输入的文本，取消返回 `null`。
Future<String?> showAppTextInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  String initialValue = '',
  String? labelText,
  String? hintText,
  bool obscureText = false,
  int maxLines = 1,
  TextInputType? keyboardType,
  bool autofocus = true,
  bool trim = true,
  bool allowEmpty = false,
  String? confirmLabel,
  Future<bool> Function(String value)? onSubmit,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AppTextInputDialog(
      title: title,
      message: message,
      initialValue: initialValue,
      labelText: labelText,
      hintText: hintText,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autofocus: autofocus,
      trim: trim,
      allowEmpty: allowEmpty,
      confirmLabel: confirmLabel,
      onSubmit: onSubmit,
    ),
  );
}

class _AppTextInputDialog extends StatefulWidget {
  const _AppTextInputDialog({
    required this.title,
    this.message,
    required this.initialValue,
    this.labelText,
    this.hintText,
    required this.obscureText,
    required this.maxLines,
    this.keyboardType,
    required this.autofocus,
    required this.trim,
    required this.allowEmpty,
    this.confirmLabel,
    this.onSubmit,
  });

  final String title;
  final String? message;
  final String initialValue;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool trim;
  final bool allowEmpty;
  final String? confirmLabel;
  final Future<bool> Function(String value)? onSubmit;

  @override
  State<_AppTextInputDialog> createState() => _AppTextInputDialogState();
}

class _AppTextInputDialogState extends State<_AppTextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_saving) return;
    final value = widget.trim ? _controller.text.trim() : _controller.text;
    if (!widget.allowEmpty && value.isEmpty) {
      return;
    }
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      Navigator.of(context).pop(value);
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await onSubmit(value);
      if (ok && mounted) {
        Navigator.of(context).pop(value);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      title: widget.title,
      isSaving: _saving,
      confirmLabel: widget.confirmLabel,
      onConfirm: _handleConfirm,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            keyboardType: widget.keyboardType,
            autofocus: widget.autofocus,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
            ),
            onSubmitted: (_) => _handleConfirm(),
          ),
        ],
      ),
    );
  }
}
