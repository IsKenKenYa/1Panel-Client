import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import '../../core/i18n/l10n_x.dart';
import '../shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/page_visibility_listener.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'widgets/widgets.dart';
import 'dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final provider = context.select((DashboardProvider state) => state);
    return ServerAwarePageScaffold(
      title: l10n.dashboardTitle,
      actions: [
        // 自动刷新设置
        PopupMenuButton<Duration>(
          icon: const Icon(Icons.timer),
          tooltip: l10n.dashboardRefreshInterval,
          onSelected: (duration) {
            context.read<DashboardProvider>().setRefreshInterval(duration);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: Duration(seconds: 3),
              child: Text(l10n.dashboardInterval3s),
            ),
            PopupMenuItem(
              value: Duration(seconds: 5),
              child: Text(l10n.dashboardInterval5s),
            ),
            PopupMenuItem(
              value: Duration(seconds: 10),
              child: Text(l10n.dashboardInterval10s),
            ),
            PopupMenuItem(
              value: Duration(seconds: 30),
              child: Text(l10n.dashboardInterval30s),
            ),
            PopupMenuItem(
              value: Duration(minutes: 1),
              child: Text(l10n.dashboardInterval1m),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: l10n.commonRefresh,
          onPressed: () => context.read<DashboardProvider>().refresh(),
        ),
      ],
      body: PageVisibilityListener(
        key: ObjectKey(provider),
        onChanged: (visible) => provider.setPageVisible(this, visible),
        child: const _DashboardBody(),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final (status, error) = context.select((DashboardProvider provider) =>
        (provider.status, provider.errorMessage));
    switch (status) {
      case DashboardStatus.initial:
      case DashboardStatus.loading:
        return const DashboardLoadingView();
      case DashboardStatus.error:
        return ModuleErrorStateWidget(
          message: error,
          onRetry: context.read<DashboardProvider>().refresh,
        );
      case DashboardStatus.loaded:
        return PartialErrorToastListener(
          errorMessage: error,
          hasCachedData: PageVisibilityListener.routeIsVisible(context),
          onRetry: context.read<DashboardProvider>().refresh,
          child: const _DashboardContent(),
        );
    }
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    return RefreshIndicator(
      onRefresh: context.read<DashboardProvider>().refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: spec.pagePadding,
        child: AdaptiveWidthContainer(
          maxWidth: spec.dashboardMaxWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const main = _DashboardMetrics();
              final shortcuts = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const QuickActionsCard(),
                  const SizedBox(height: 16),
                  Builder(
                      builder: (context) => ActivityCard(
                            activities: context
                                .select((DashboardProvider p) => p.activities),
                          )),
                ],
              );
              if (constraints.maxWidth < 840) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [main, const SizedBox(height: 16), shortcuts],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 2, child: main),
                  const SizedBox(width: 16),
                  Expanded(child: shortcuts),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(builder: (context) {
          context.select((DashboardProvider p) => (
                p.data.cpuPercent,
                p.data.memoryPercent,
                p.data.diskPercent,
                p.data.load,
              ));
          return HealthOverviewGrid(
              data: context.read<DashboardProvider>().data);
        }),
        const SizedBox(height: 16),
        Builder(builder: (context) {
          context.select((DashboardProvider p) => (
                p.data.systemInfo,
                p.data.uptimeSeconds,
                p.data.uptime,
                p.data.lastUpdated,
              ));
          return ServerInfoCard(data: context.read<DashboardProvider>().data);
        }),
        const SizedBox(height: 16),
        Builder(builder: (context) {
          final (cpu, memory, loading) =
              context.select((DashboardProvider p) => (
                    p.data.topCpuProcesses,
                    p.data.topMemoryProcesses,
                    p.isLoadingTopProcesses &&
                        p.data.topCpuProcesses.isEmpty &&
                        p.data.topMemoryProcesses.isEmpty,
                  ));
          return TopProcessesCard(
            cpuProcesses: cpu,
            memoryProcesses: memory,
            isLoading: loading,
            onRefresh: context.read<DashboardProvider>().loadTopProcesses,
          );
        }),
      ],
    );
  }
}
