import 'package:flutter/material.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';

/// 共享信息卡片。
///
/// 桌面端可点击卡片带 hover 反馈（M3 桌面规范：hover 时 elevation 提升 +
/// 边框高亮）；移动端保持静态（无 hover 概念，触摸反馈由 InkWell 水波承载）。
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
    final colorScheme = Theme.of(context).colorScheme;
    final hoverEnabled =
        widget.onTap != null && PlatformUtils.isDesktop(context);
    final hovered = _hovered && hoverEnabled;

    return MouseRegion(
      onEnter: hoverEnabled ? (_) => _setHovered(true) : null,
      onExit: hoverEnabled ? (_) => _setHovered(false) : null,
      child: Card(
        color: widget.backgroundColor ?? colorScheme.surfaceContainerLow,
        elevation: hovered ? 3 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: hovered
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            // Wrap in DefaultTextStyle so callers can pass any
                            // Widget (e.g. Text, Row) and still get uniform styling.
                            DefaultTextStyle(
                              style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ) ??
                                  TextStyle(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              child: widget.subtitle!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 8),
                      widget.trailing!,
                    ],
                  ],
                ),
                if (widget.child != null) ...[
                  const SizedBox(height: 16),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ) ??
                        TextStyle(),
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
