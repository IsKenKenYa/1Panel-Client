import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/widgets/server_card.dart';
import 'package:onepanel_client/features/shell/widgets/shell_list_bottom_padding.dart';

/// 按滚动区域的可用宽度和字号排列卡片，每行高度由内容决定。
class ServerCardSliver extends StatelessWidget {
  const ServerCardSliver({
    super.key,
    required this.servers,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    this.firstCardKey,
  });

  final List<ApiConfig> servers;
  final ValueChanged<ApiConfig> onOpen;
  final ValueChanged<ApiConfig> onEdit;
  final ValueChanged<ApiConfig> onDelete;
  final Key? firstCardKey;

  Widget _card(int index) {
    final id = servers[index].id;
    return IndexedSemantics(
      index: index,
      child: Selector<ServerProvider, ServerCardViewModel?>(
        key: ValueKey(id),
        selector: (_, provider) => provider.cardFor(id),
        builder: (context, item, _) {
          if (item == null) return const SizedBox.shrink();
          return ServerCard(
            key: index == 0 ? firstCardKey : null,
            data: item,
            onTap: () => onOpen(item.config),
            onEdit: () => onEdit(item.config),
            onDelete: () => onDelete(item.config),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    const gap = AppDesignTokens.spacingLg;
    final minCardWidth = 300 * MediaQuery.textScalerOf(context).scale(16) / 16;
    // 滚动距离也会改变 SliverConstraints，同一列数沿用已有的列表委托。
    final layouts = <int, Widget>{};
    return SliverPadding(
      padding: spec.pagePadding.copyWith(
        top: 0,
        bottom:
            AppDesignTokens.spacingXl + shellListBottomPadding(context).bottom,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns =
              ((constraints.crossAxisExtent + gap) / (minCardWidth + gap))
                  .floor()
                  .clamp(1, 4)
                  .toInt();
          return layouts.putIfAbsent(
              columns,
              () => SliverList.builder(
                    itemCount: (servers.length + columns - 1) ~/ columns,
                    addSemanticIndexes: false,
                    itemBuilder: (context, row) {
                      final start = row * columns;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: gap),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var col = 0; col < columns; col++) ...[
                              if (col != 0) const SizedBox(width: gap),
                              Expanded(
                                child: start + col < servers.length
                                    ? _card(start + col)
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ));
        },
      ),
    );
  }
}
