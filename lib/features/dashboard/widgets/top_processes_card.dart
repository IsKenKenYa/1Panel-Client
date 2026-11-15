import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../data/models/dashboard_models.dart';

class TopProcessesCard extends StatelessWidget {
  final List<ProcessInfo> cpuProcesses;
  final List<ProcessInfo> memoryProcesses;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const TopProcessesCard({
    super.key,
    this.cpuProcesses = const [],
    this.memoryProcesses = const [],
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      title: l10n.dashboardTopProcessesTitle,
      trailing: onRefresh != null
          ? IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: context.l10n.commonRefresh,
              onPressed: isLoading ? null : onRefresh,
            )
          : null,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: l10n.dashboardCpuTab),
                Tab(text: l10n.dashboardMemoryTab),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: TabBarView(
                children: [
                  _ProcessList(
                    processes: cpuProcesses,
                    isLoading: isLoading,
                    type: ProcessSortType.cpu,
                  ),
                  _ProcessList(
                    processes: memoryProcesses,
                    isLoading: isLoading,
                    type: ProcessSortType.memory,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessList extends StatelessWidget {
  final List<ProcessInfo> processes;
  final bool isLoading;
  final ProcessSortType type;

  const _ProcessList({
    required this.processes,
    required this.isLoading,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (processes.isEmpty) {
      return Center(
        child: Text(
          l10n.dashboardNoProcesses,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: processes.length > 5 ? 5 : processes.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final process = processes[index];
        return _ProcessItem(
          process: process,
          type: type,
        );
      },
    );
  }
}

class _ProcessItem extends StatelessWidget {
  final ProcessInfo process;
  final ProcessSortType type;

  const _ProcessItem({
    required this.process,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usage = type == ProcessSortType.cpu
        ? process.cpuPercent
        : process.memoryPercent;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          process.name.isNotEmpty ? process.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        process.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'PID: ${process.pid}',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getUsageColor(context, usage).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${usage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: _getUsageColor(context, usage),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getUsageColor(BuildContext context, double usage) {
    final colorScheme = Theme.of(context).colorScheme;
    if (usage >= 80) return colorScheme.error;
    if (usage >= 50) return colorScheme.tertiary;
    return colorScheme.primary;
  }
}

enum ProcessSortType { cpu, memory }
