import 'package:flutter/material.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart' hide ContainerStats;
import 'package:onepanelapp_app/features/containers/containers_provider.dart';
import 'package:onepanelapp_app/features/containers/widgets/container_card.dart';
import 'package:onepanelapp_app/features/containers/widgets/containers_empty_widget.dart';
import 'package:onepanelapp_app/features/containers/widgets/containers_stats_card_widget.dart';

class ContainersTab extends StatelessWidget {
  final List<ContainerInfo> containers;
  final ContainerStats stats;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<bool> Function(String) onStart;
  final Future<bool> Function(String) onStop;
  final Future<bool> Function(String) onRestart;
  final void Function(String) onDelete;
  final void Function(String) onRename;
  final void Function(ContainerInfo) onUpgrade;
  final void Function(ContainerInfo) onCommit;
  final void Function(ContainerInfo) onEdit;
  final void Function(String) onCleanLog;

  const ContainersTab({
    super.key,
    required this.containers,
    required this.stats,
    required this.isLoading,
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
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContainersStatsCard(
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
            const SizedBox(height: 16),
            if (containers.isEmpty && !isLoading)
              ContainersEmptyView(
                icon: Icons.inventory_2_outlined,
                title: l10n.containerEmptyTitle,
                subtitle: l10n.containerEmptyDesc,
              )
            else
              ...containers.map((containerInfo) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                    onTerminal: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.containerDetail,
                        arguments: containerInfo,
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
