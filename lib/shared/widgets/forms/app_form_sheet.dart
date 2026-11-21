import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

/// 详情字段共用可滚动的底部弹层，标题和关闭按钮始终可见。
Future<void> showAppDetailsSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) =>
    showAppFormSheet<void>(
      context,
      title: title,
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: children,
      ),
    );

/// 统一弹层表单壳（M3 Expressive / MDUI3 轨道标准件）。
///
/// 全仓所有底部弹层表单必须经 [showAppFormSheet] 打开，统一：
/// - 圆角/背景/把手：由全局 bottomSheetTheme 承担（radiusXl=28 + drag handle）；
/// - 键盘适配：自动注入 viewInsets.bottom padding；
/// - 标题行：titleLarge + 关闭按钮；
/// - 高度策略：isScrollControlled + maxHeightFactor 约束。
Future<T?> showAppFormSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  double maxHeightFactor = 0.9,
  bool showCloseButton = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    // maxHeightFactor 为屏高比例（0-1]，换算为像素约束。
    constraints: BoxConstraints(
      maxWidth: math.min(640, AdaptiveLayoutSpec.of(context).width),
      maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
    ),
    builder: (sheetContext) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingSm,
                  AppDesignTokens.spacingSm,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: MaterialLocalizations.of(sheetContext)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                  ],
                ),
              ),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      );
    },
  );
}
