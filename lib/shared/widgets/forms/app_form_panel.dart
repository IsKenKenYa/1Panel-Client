import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

/// 统一双轨弹层表单壳（M3 Expressive / MDUI3 轨道标准件）。
///
/// 多字段表单必须经 [showAdaptiveFormPanel] 打开：
/// - 中等和宽内容区使用 [AppFormDialog] 居中展示。
/// - 窄内容区使用可滚动的底部弹层，操作随可用宽度换行。
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
    if (ModalRoute.of(context) is DialogRoute<Object?>) {
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: content,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: AppDesignTokens.spacingSm,
              overflowSpacing: AppDesignTokens.spacingSm,
              children: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  key: confirmButtonKey,
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        )
                      : null,
                  onPressed: isSaving ? null : onConfirm,
                  child: isSaving
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
          ),
        ],
      ),
    );
  }
}

/// 根据打开表单时可用的内容宽度选择对话框或底部弹层。
///
/// [builder] 返回 [AppFormPanel]；取消/关闭 pop(null)，确认由表单
/// 内容 pop 结果对象，两条轨道行为一致。
Future<T?> showAdaptiveFormPanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (!AdaptiveLayoutSpec.of(context).isPhone) {
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
      child: SafeArea(top: false, child: builder(sheetContext)),
    ),
  );
}
