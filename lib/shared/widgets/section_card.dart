import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

/// 统一的「内容分组卡」标准组件（MDUI3 轨道）。
///
/// 全仓所有"标题 + 描述 + 内容"的分组卡片必须复用本组件，
/// 禁止在页面内私自定义 `_SectionCard` 变体。
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
  });

  /// 分组标题；为 null 时渲染纯卡片分组（无标题行）。
  final String? title;
  final String? description;
  final Widget? action;
  final Widget child;

  /// 测试定位用 Key（作用于标题文本）。
  final Key? titleKey;

  /// 覆盖卡片内容的内边距（默认无，child 自行控制）。
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title!,
                    key: titleKey,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
        if (description != null) ...[
          if (title != null) const SizedBox(height: AppDesignTokens.spacingXs),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        if (title != null) const SizedBox(height: AppDesignTokens.spacingSm),
        Card(
          clipBehavior: Clip.antiAlias,
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
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

/// 统一的「入口列表分组」标准组件：分组标题 + 描述 + 卡片内紧凑
/// ListTile 列表（icon + title + chevron），视觉与服务器详情页一致。
///
/// 全仓所有模块入口/二级菜单列表必须复用本组件，
/// 禁止使用大卡片网格或私自定义列表变体。
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
              minTileHeight: kMinInteractiveDimension,
              leading: Icon(item.icon),
              title: Text(item.title),
              subtitle: item.subtitle == null ? null : Text(item.subtitle!),
              trailing: item.trailing ??
                  (item.onTap == null
                      ? null
                      : const Icon(Icons.chevron_right_rounded, size: 20)),
              onTap: item.onTap,
            ),
            if (index < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
