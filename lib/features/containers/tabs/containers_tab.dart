import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart'
    hide ContainerStats;
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/features/containers/widgets/container_card.dart';
import 'package:onepanel_client/features/containers/widgets/containers_empty_widget.dart';
import 'package:onepanel_client/features/containers/widgets/containers_stats_card_widget.dart';

class ContainersTab extends StatelessWidget {
  final List<ContainerInfo> containers;
  final ContainerStats stats;
  final bool isLoading;
  final bool showStatsHeader;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String) onStart;
  final Future<void> Function(String) onStop;
  final Future<void> Function(String) onRestart;
  final void Function(String) onDelete;
  final void Function(String) onRename;
  final void Function(ContainerInfo) onUpgrade;
  final void Function(ContainerInfo) onCommit;
  final void Function(ContainerInfo) onEdit;
  final void Function(String) onCleanLog;
  final void Function(ContainerInfo) onTerminal;

  const ContainersTab({
    super.key,
    required this.containers,
    required this.stats,
    required this.isLoading,
    this.showStatsHeader = true,
    required this.onRefresh,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onDelete,
    required this.onRename,
    required this.onUpgrade,
    required this.onCommit,
    required this.onEdit,
    required this.onCleanLog,
    required this.onTerminal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final showEmpty = containers.isEmpty && !isLoading;
    final headerCount = showStatsHeader ? 1 : 0;
    final itemCount =
        showEmpty ? headerCount + 1 : containers.length + headerCount;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showStatsHeader && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ContainersStatsCard(
                title: l10n.containerStatsTitle,
                items: [
                  ContainersStatItem(
                    title: l10n.containerStatsTotal,
                    value: stats.total.toString(),
                    color: colorScheme.primary,
                    icon: Icons.inventory_2,
                  ),
                  ContainersStatItem(
                    title: l10n.containerStatsRunning,
                    value: stats.running.toString(),
                    color: colorScheme.tertiary,
                    icon: Icons.play_circle,
                  ),
                  ContainersStatItem(
                    title: l10n.containerStatsStopped,
                    value: stats.stopped.toString(),
                    color: colorScheme.secondary,
                    icon: Icons.stop_circle,
                  ),
                ],
              ),
            );
          }

          if (showEmpty) {
            return ContainersEmptyView(
              icon: Icons.inventory_2_outlined,
              title: l10n.containerEmptyTitle,
              subtitle: l10n.containerEmptyDesc,
            );
          }

          final containerIndex = index - headerCount;
          final containerInfo = containers[containerIndex];
          return Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12),
            child: ContainerCard(
              container: containerInfo,
              onStart: () => onStart(containerInfo.name),
              onStop: () => onStop(containerInfo.name),
              onRestart: () => onRestart(containerInfo.name),
              onDelete: () => onDelete(containerInfo.name),
              onRename: () => onRename(containerInfo.name),
              onUpgrade: () => onUpgrade(containerInfo),
              onCommit: () => onCommit(containerInfo),
              onEdit: () => onEdit(containerInfo),
              onCleanLog: () => onCleanLog(containerInfo.name),
              onTerminal: () => onTerminal(containerInfo),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.containerDetail,
                  arguments: containerInfo,
                );
              },
              onLogs: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.containerDetail,
                  arguments: containerInfo,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
