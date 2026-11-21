import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

export 'package:onepanel_client/shared/widgets/section_card.dart'
    show ExpressiveFilterBar, ExpressiveHint, ExpressiveRow, SectionCard;

/// 兼容别名：等价于 [SectionCard]。
///
/// 新代码直接使用 [SectionCard]；`ExpressiveRow`、`ExpressiveHint`、
/// `ExpressiveFilterBar` 与分区组件同处 `section_card.dart`。
class ExpressiveSection extends StatelessWidget {
  const ExpressiveSection({
    super.key,
    required this.title,
    required this.children,
    this.caption,
    this.actions = const <Widget>[],
    this.isBusy = false,
  });

  final String title;
  final String? caption;
  final List<Widget> actions;
  final bool isBusy;

  /// 分区内的条目，逐项渲染在卡片内并自动插入分隔线。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      description: caption,
      isBusy: isBusy,
      action: actions.isEmpty
          ? null
          : Wrap(alignment: WrapAlignment.end, children: actions),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (index, child) in children.indexed) ...[
            child,
            if (index < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppDesignTokens.spacingLg,
                endIndent: AppDesignTokens.spacingLg,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}
