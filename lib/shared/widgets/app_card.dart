import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

/// 共享信息卡片（M3 Expressive 轨道），支持鼠标、键盘和触控操作。
///
/// 圆角沿用全局 `radiusLg`，底色 `surfaceContainerLow`，悬停时描边转主色
/// 并抬升一级阴影；标题使用 `titleMedium/w600`，副标题与正文降为次级色。
class AppCard extends StatefulWidget {
  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.child,
    this.trailing,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isClickable = widget.onTap != null;
    final hovered = isClickable && _hovered;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      side: BorderSide(
        color: hovered
            ? colorScheme.primary.withValues(alpha: 0.4)
            : colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
    );

    return Card(
      color: widget.backgroundColor ?? colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      elevation: hovered ? 3 : 0,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onHover: isClickable ? _setHovered : null,
        customBorder: shape,
        focusColor: colorScheme.primary.withValues(alpha: 0.16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isClickable ? kMinInteractiveDimension : 0,
          ),
          child: Padding(
            padding: widget.padding ?? AppDesignTokens.cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: widget.child == null
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: AppDesignTokens.spacingSm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: AppDesignTokens.spacingXs),
                              DefaultTextStyle.merge(
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                child: widget.subtitle!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.trailing != null) ...[
                        const SizedBox(width: AppDesignTokens.spacingSm),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth / 2,
                          ),
                          child: widget.trailing!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.child != null) ...[
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    child: widget.child!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    setState(() => _hovered = value);
  }
}
