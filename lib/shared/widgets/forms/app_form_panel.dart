import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

/// 统一双轨弹层表单壳（M3 Expressive / MDUI3 轨道标准件）。
///
/// 多字段表单必须经 [showAdaptiveFormPanel] 打开：
/// - 桌面端沿用 [AppFormDialog] 居中对话框形态；
/// - 移动端渲染为底部弹层内容形态（标题行 + 可滚动表单 + 底部按钮行），
///   满足拇指区可达与键盘适配。
/// 简单确认对话框继续用 [showAppFormDialog]，无需双轨。
class AppFormPanel extends StatelessWidget {
  const AppFormPanel({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.isSaving = false,
    this.confirmLabel,
    this.confirmButtonKey,
    this.destructive = false,
  });

  final String title;
  final Widget content;
  final Future<void> Function() onConfirm;
  final bool isSaving;
  final String? confirmLabel;
  final Key? confirmButtonKey;

  /// 破坏性操作（删除等）：确认按钮使用 error 色（M3 语义）。
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop(context)) {
      return AppFormDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
        isSaving: isSaving,
        confirmLabel: confirmLabel,
        confirmButtonKey: confirmButtonKey,
        destructive: destructive,
      );
    }

    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: content,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    isSaving ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: confirmButtonKey,
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      )
                    : null,
                onPressed: isSaving ? null : () => onConfirm(),
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(confirmLabel ?? l10n.commonConfirm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 多字段表单双轨入口：桌面居中对话框，移动端底部弹层。
///
/// [builder] 返回 [AppFormPanel]；取消/关闭 pop(null)，确认由表单
/// 内容 pop 结果对象，两条轨道行为一致。
Future<T?> showAdaptiveFormPanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (PlatformUtils.isDesktop(context)) {
    return showDialog<T>(context: context, builder: builder);
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: builder(sheetContext),
    ),
  );
}
