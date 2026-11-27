import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';

/// 位于卡片上方的分区标题。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// 统一的「内容分组」标准组件（M3 Expressive 轨道）。
///
/// 结构遵循 M3E 数据分区：标题与辅助说明位于卡片外侧，卡片只承载内容；
/// 卡片使用共享的卡片底色与描边，圆角沿用全局 `radiusLg`。
/// 全仓所有"标题 + 描述 + 内容"的分组必须复用本组件，禁止页面私有变体。
///
/// 若分组内容是一组可点击入口（icon + title + chevron 列表），
/// 请使用 [SectionEntryList]，不要手工拼 ListTile。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.description,
    this.action,
    this.titleKey,
    this.padding,
    this.isBusy = false,
    this.divider = false,
  });

  /// 分组标题；为 null 时渲染纯卡片分组（无标题行）。
  final String? title;
  final String? description;
  final Widget? action;
  final Widget child;

  /// 测试定位用 Key（作用于标题文本）。
  final Key? titleKey;

  /// 卡片内容的内边距；未提供时不额外包裹，由 child 自行控制。
  final EdgeInsetsGeometry? padding;

  /// 加载中：在卡片顶沿显示一条进度，不清空已有内容。
  final bool isBusy;

  /// 是否在内容上方绘制一条与卡片内边距对齐的分隔线（多区块合并时使用）。
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (divider)
          Divider(
            height: 1,
            thickness: 1,
            indent: AppDesignTokens.spacingLg,
            endIndent: AppDesignTokens.spacingLg,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        padding == null ? child : Padding(padding: padding!, child: child),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.start,
              spacing: AppDesignTokens.spacingSm,
              overflowSpacing: AppDesignTokens.spacingXs,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    title!,
                    key: titleKey,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        if (description != null) ...[
          if (title != null) const SizedBox(height: AppDesignTokens.spacingXs),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (title != null) const SizedBox(height: AppDesignTokens.spacingSm),
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: AppTheme.cardSurface(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (isBusy) const LinearProgressIndicator(minHeight: 2),
              content,
            ],
          ),
        ),
      ],
    );
  }
}

/// 分组内的单个入口条目。
class SectionEntryItem {
  const SectionEntryItem({
    this.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.subtitle,
    this.trailing,
  });

  /// 测试定位用 Key（作用于条目 ListTile）。
  final Key? key;

  final String title;
  final String? subtitle;
  final IconData icon;

  /// 为 null 时为纯信息展示条目（不可点击）。
  final VoidCallback? onTap;

  /// 覆盖默认的右箭头（如显示状态徽标）。
  final Widget? trailing;
}

/// 统一的「入口列表分组」标准组件：分组标题 + 描述 + 卡片内入口列表。
///
/// 条目保持 [ListTile] 语义（键盘、语义树与既有测试依赖该类型），
/// 视觉上使用 M3E 的 44dp 图标容器、次级色元数据与描边分隔线。
/// 全仓所有模块入口/二级菜单列表必须复用本组件。
class SectionEntryList extends StatelessWidget {
  const SectionEntryList({
    super.key,
    this.title,
    required this.items,
    this.description,
    this.action,
    this.titleKey,
  });

  /// 分组标题；为 null 时渲染纯卡片分组（无标题行）。
  final String? title;
  final String? description;
  final Widget? action;
  final List<SectionEntryItem> items;

  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      title: title,
      description: description,
      action: action,
      titleKey: titleKey,
      child: Column(
        children: [
          for (final (index, item) in items.indexed) ...[
            ListTile(
              key: item.key,
              minTileHeight: 56,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 20),
              ),
              title: Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: item.subtitle == null
                  ? null
                  : Text(
                      item.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
              trailing: item.trailing ??
                  (item.onTap == null
                      ? null
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        )),
              onTap: item.onTap,
            ),
            if (index < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppDesignTokens.spacingLg,
                endIndent: AppDesignTokens.spacingLg,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

/// 分区内的单条数据（M3 Expressive 数据行）。
///
/// 左侧 40dp 图标容器、中间标题与一行元数据、右侧操作；触控高度不低于
/// 72dp，元数据使用次级色等宽小字号而不是彩色小标签。
class ExpressiveRow extends StatelessWidget {
  const ExpressiveRow({
    super.key,
    required this.title,
    this.leadingIcon,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final IconData? leadingIcon;

  /// 标题下的一行正文，用于描述或路径，最多两行。
  final String? subtitle;

  /// 次级元数据行，等宽小字号，以居中点分隔。
  final List<String>? meta;

  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dimmed = !enabled;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (leadingIcon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dimmed
                    ? scheme.surfaceContainerHighest
                    : scheme.secondaryContainer,
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSm),
              ),
              alignment: Alignment.center,
              child: Icon(
                leadingIcon,
                size: 20,
                color: dimmed
                    ? scheme.onSurfaceVariant
                    : scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: AppDesignTokens.spacingMd),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dimmed ? scheme.onSurfaceVariant : null,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.spacingXs + 2),
                  Text(
                    meta!.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppDesignTokens.spacingSm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: enabled ? onTap : null, child: content);
  }
}

/// 分区内的空态或提示行。
/// 分区内的空态或提示行。
class ExpressiveHint extends StatelessWidget {
  const ExpressiveHint({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.isError = false,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingLg,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: isError ? scheme.error : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDesignTokens.spacingMd),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 过滤用的胶囊选择条，横向可滚动。
///
/// 使用 M3E 的 filter chip 语义：选中态填充主色容器，未选中使用描边。
/// 过滤用的胶囊选择条，横向可滚动。
class ExpressiveFilterBar extends StatelessWidget {
  const ExpressiveFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// 每个选项由标识与显示文案组成。
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, (value, label)) in options.indexed) ...[
            if (index > 0) const SizedBox(width: AppDesignTokens.spacingSm),
            ChoiceChip(
              label: Text(label),
              selected: selected == value,
              showCheckmark: false,
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected == value
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
                  ),
              selectedColor: scheme.secondaryContainer,
              backgroundColor: scheme.surfaceContainerHigh,
              side: BorderSide(
                color: selected == value ? Colors.transparent : scheme.outlineVariant,
              ),
              onSelected: (_) => onSelected(value),
            ),
          ],
        ],
      ),
    );
  }
}

/// 分区内的一组只读属性行，替代每行单独一张卡片的写法。
///
/// 每行只有标签与值，行间以描边分隔；标签使用次级色，值使用正文色。
/// 需要图标、元数据或右侧操作的行请使用 [ExpressiveRow]。
class SectionPropertyList extends StatelessWidget {
  const SectionPropertyList({
    super.key,
    this.title,
    this.description,
    required this.properties,
    this.actions = const <Widget>[],
  });

  final String? title;
  final String? description;
  final List<SectionProperty> properties;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      description: description,
      action: actions.isEmpty
          ? null
          : Wrap(alignment: WrapAlignment.end, children: actions),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (index, property) in properties.indexed) ...[
            property,
            if (index < properties.length - 1)
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

/// [SectionPropertyList] 中的单条属性行。
class SectionProperty extends StatelessWidget {
  const SectionProperty({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;

  /// 值可能为空，此时显示短横线占位。
  final String? value;

  /// 测试定位用 Key（作用于值文本）。
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = value == null || value!.isEmpty ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Text(
            this.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );
          final value = SelectableText(
            text,
            key: valueKey,
            style: theme.textTheme.bodyMedium,
          );
          final minValueWidth = 8 *
              MediaQuery.textScalerOf(context).scale(
                    theme.textTheme.bodyMedium?.fontSize ?? 14,
                  );
          if (!constraints.hasBoundedWidth ||
              constraints.maxWidth < 128 + minValueWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                label,
                const SizedBox(height: AppDesignTokens.spacingXs),
                value,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: math.min(128, constraints.maxWidth * 0.45),
                child: label,
              ),
              const SizedBox(width: AppDesignTokens.spacingMd),
              Expanded(child: value),
            ],
          );
        },
      ),
    );
  }
}
